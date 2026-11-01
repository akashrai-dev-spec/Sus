import argon2 from "argon2";
import { v4 as uuidv4 } from "uuid";
import { config } from "../config.js";
import { GameEngine } from "../game/gameEngine.js";
import { GamePlayer, GameSettings, GameState } from "../game/types.js";
import { logger } from "../util/logger.js";
import { pickSecretWord } from "../words/wordBank.js";

export interface SessionInfo {
  playerId: string;
  name: string;
  color: string;
  resumeToken: string;
  socketId: string;
  roomId?: string;
}

export interface Room {
  id: string;
  name: string;
  pin: string;
  pinHash: string;
  settings: GameSettings;
  hostId: string;
  players: (GamePlayer & { resumeToken: string; socketId: string })[];
  gameState?: GameState;
  emptyTimer?: NodeJS.Timeout;
  disconnectTimers: Map<string, NodeJS.Timeout>;
  bannedTokens: Set<string>;
  bannedPlayerIds: Set<string>;
}

export function ensureUniqueName(existingNames: string[], requestedName: string): string {
  const clean = requestedName.trim() || "Player";
  const lowerExisting = new Set(existingNames.map((n) => n.trim().toLowerCase()));
  if (!lowerExisting.has(clean.toLowerCase())) {
    return clean;
  }

  const match = clean.match(/^(.*?)\s+(\d+)$/);
  let base = clean;
  let counter = 2;
  if (match) {
    base = match[1];
    counter = parseInt(match[2], 10) + 1;
  }

  while (lowerExisting.has(`${base.toLowerCase()} ${counter}`)) {
    counter++;
  }
  return `${base} ${counter}`;
}

export class RoomManager {
  private rooms = new Map<string, Room>();
  private sessions = new Map<string, SessionInfo>(); // key: resumeToken
  private socketToToken = new Map<string, string>(); // socketId -> resumeToken

  registerSession(params: {
    socketId: string;
    name: string;
    color: string;
    resumeToken?: string;
  }): SessionInfo {
    const { socketId, name, color, resumeToken } = params;

    if (resumeToken && this.sessions.has(resumeToken)) {
      const existing = this.sessions.get(resumeToken)!;
      if (existing.socketId && existing.socketId !== socketId) {
        this.socketToToken.delete(existing.socketId);
      }
      existing.socketId = socketId;
      existing.name = name || existing.name;
      existing.color = color || existing.color;
      this.socketToToken.set(socketId, resumeToken);

      // Reconnect player in their room if they belong to one
      if (existing.roomId) {
        const room = this.rooms.get(existing.roomId);
        if (room) {
          this.reconnectPlayer(room, existing.playerId, socketId);
        }
      } else {
        // Defensive scan: check if any room contains this player
        for (const room of this.rooms.values()) {
          const p = room.players.find((pl) => pl.id === existing.playerId);
          if (p) {
            existing.roomId = room.id;
            this.reconnectPlayer(room, existing.playerId, socketId);
            break;
          }
        }
      }

      return existing;
    }

    const token = uuidv4();
    const playerId = `p-${uuidv4().substring(0, 8)}`;
    const session: SessionInfo = {
      playerId,
      name,
      color,
      resumeToken: token,
      socketId,
    };
    this.sessions.set(token, session);
    this.socketToToken.set(socketId, token);
    return session;
  }

  getSessionBySocket(socketId: string): SessionInfo | undefined {
    const token = this.socketToToken.get(socketId);
    if (!token) return undefined;
    return this.sessions.get(token);
  }

  getSessionByPlayerId(playerId: string): SessionInfo | undefined {
    for (const session of this.sessions.values()) {
      if (session.playerId === playerId) {
        return session;
      }
    }
    return undefined;
  }

  reconnectPlayer(room: Room, playerId: string, socketId: string): boolean {
    const player = room.players.find((p) => p.id === playerId);
    if (!player) return false;

    player.socketId = socketId;
    player.isConnected = true;

    const timer = room.disconnectTimers.get(playerId);
    if (timer) {
      clearTimeout(timer);
      room.disconnectTimers.delete(playerId);
    }

    if (room.gameState) {
      const gp = room.gameState.players.find((p) => p.id === playerId);
      if (gp) {
        gp.isConnected = true;
      }
    }
    return true;
  }

  updateProfile(socketId: string, name: string, color: string): SessionInfo | undefined {
    const session = this.getSessionBySocket(socketId);
    if (!session) return undefined;

    let targetName = name.trim() || session.name;
    session.color = color;

    if (session.roomId) {
      const room = this.rooms.get(session.roomId);
      if (room) {
        const otherNames = room.players
          .filter((pl) => pl.id !== session.playerId)
          .map((pl) => pl.name);
        targetName = ensureUniqueName(otherNames, targetName);

        const p = room.players.find((pl) => pl.id === session.playerId);
        if (p) {
          p.name = targetName;
          p.color = color;
        }
        if (room.gameState) {
          const gp = room.gameState.players.find((pl) => pl.id === session.playerId);
          if (gp) {
            gp.name = targetName;
            gp.color = color;
          }
        }
      }
    }
    session.name = targetName;
    return session;
  }

  listPublicRooms(): { id: string; name: string; count: number; max: number; locked: boolean }[] {
    const list: { id: string; name: string; count: number; max: number; locked: boolean }[] = [];
    for (const room of this.rooms.values()) {
      list.push({
        id: room.id,
        name: room.name,
        count: room.players.filter((p) => p.isConnected !== false).length,
        max: room.settings.maxPlayers,
        locked: true,
      });
    }
    return list;
  }

  isRoomNameTaken(name: string): boolean {
    const target = name.trim().toLowerCase();
    if (!target) return false;
    for (const room of this.rooms.values()) {
      if (room.name.trim().toLowerCase() === target) {
        return true;
      }
    }
    return false;
  }

  suggestUniqueRoomName(requestedName?: string): string {
    const base = requestedName?.trim() || "Sus Party";
    const existingNames = Array.from(this.rooms.values()).map((r) => r.name);
    return ensureUniqueName(existingNames, base);
  }

  async createRoom(
    session: SessionInfo,
    params: { name: string; pin: string; settings: GameSettings },
  ): Promise<Room> {
    const requestedName = params.name.trim() || `${session.name}'s room`;

    if (this.isRoomNameTaken(requestedName)) {
      const suggestedName = this.suggestUniqueRoomName(requestedName);
      const err = new Error("ROOM_NAME_TAKEN");
      (err as any).code = "ROOM_NAME_TAKEN";
      (err as any).suggestedName = suggestedName;
      throw err;
    }

    const pinHash = await argon2.hash(params.pin);
    const roomId = `room-${uuidv4().substring(0, 8)}`;

    const hostPlayer: GamePlayer & { resumeToken: string; socketId: string } = {
      id: session.playerId,
      name: session.name,
      color: session.color,
      isAlive: true,
      isHost: true,
      usedAccusation: false,
      remainingGuesses: params.settings.guessAttempts,
      isReady: false,
      isConnected: true,
      resumeToken: session.resumeToken,
      socketId: session.socketId,
    };

    const room: Room = {
      id: roomId,
      name: requestedName,
      pin: params.pin,
      pinHash,
      settings: params.settings,
      hostId: session.playerId,
      players: [hostPlayer],
      disconnectTimers: new Map(),
      bannedTokens: new Set(),
      bannedPlayerIds: new Set(),
    };

    this.rooms.set(roomId, room);
    session.roomId = roomId;
    logger.info({ roomId, hostId: session.playerId }, "Room created");
    return room;
  }

  getRoom(roomId: string): Room | undefined {
    return this.rooms.get(roomId);
  }

  async verifyPin(room: Room, pin: string): Promise<boolean> {
    try {
      return await argon2.verify(room.pinHash, pin);
    } catch {
      return false;
    }
  }

  joinRoom(session: SessionInfo, room: Room): void {
    if (session.roomId && session.roomId !== room.id) {
      this.leaveRoom(session.socketId);
    }

    if (room.emptyTimer) {
      clearTimeout(room.emptyTimer);
      room.emptyTimer = undefined;
    }

    if (room.bannedPlayerIds.has(session.playerId) || room.bannedTokens.has(session.resumeToken)) {
      throw new Error("PLAYER_BANNED");
    }

    const existingIndex = room.players.findIndex(
      (p) => p.id === session.playerId || (Boolean(session.resumeToken) && p.resumeToken === session.resumeToken),
    );
    if (existingIndex !== -1) {
      // Reconnection
      const p = room.players[existingIndex];
      p.socketId = session.socketId;
      p.isConnected = true;
      p.name = session.name || p.name;
      session.playerId = p.id;
      const timer = room.disconnectTimers.get(p.id);
      if (timer) {
        clearTimeout(timer);
        room.disconnectTimers.delete(p.id);
      }
    } else {
      // Check if there is an inactive/disconnected player with the exact same name
      const disconnectedSameName = room.players.find(
        (p) => p.isConnected === false && p.name.trim().toLowerCase() === session.name.trim().toLowerCase(),
      );
      if (disconnectedSameName) {
        disconnectedSameName.socketId = session.socketId;
        disconnectedSameName.isConnected = true;
        disconnectedSameName.resumeToken = session.resumeToken;
        session.playerId = disconnectedSameName.id;
        const timer = room.disconnectTimers.get(disconnectedSameName.id);
        if (timer) {
          clearTimeout(timer);
          room.disconnectTimers.delete(disconnectedSameName.id);
        }
      } else {
        // If room is full, prune any disconnected player in lobby so active players can enter
        if (room.players.length >= room.settings.maxPlayers) {
          const disconnectedIndex = room.players.findIndex((p) => p.isConnected === false);
          if (disconnectedIndex !== -1 && (!room.gameState || room.gameState.currentPhase.name === "lobby")) {
            const stale = room.players.splice(disconnectedIndex, 1)[0];
            const t = room.disconnectTimers.get(stale.id);
            if (t) {
              clearTimeout(t);
              room.disconnectTimers.delete(stale.id);
            }
          } else {
            throw new Error("ROOM_FULL");
          }
        }

        if (room.gameState && room.gameState.currentPhase.name !== "lobby") {
          throw new Error("GAME_ALREADY_IN_PROGRESS");
        }

        // Ensure every player in the room has a distinct, unique name
        const existingNames = room.players.map((p) => p.name);
        const uniqueName = ensureUniqueName(existingNames, session.name);
        session.name = uniqueName;

        const newPlayer: GamePlayer & { resumeToken: string; socketId: string } = {
          id: session.playerId,
          name: uniqueName,
          color: session.color,
          isAlive: true,
          isHost: room.players.length === 0,
          usedAccusation: false,
          remainingGuesses: room.settings.guessAttempts,
          isReady: false,
          isConnected: true,
          resumeToken: session.resumeToken,
          socketId: session.socketId,
        };
        room.players.push(newPlayer);
      }
    }

    session.roomId = room.id;
  }

  leaveRoom(socketId: string): { room?: Room; leftPlayerId?: string; newHostId?: string } {
    const session = this.getSessionBySocket(socketId);
    if (!session || !session.roomId) return {};

    const room = this.rooms.get(session.roomId);
    if (!room) {
      session.roomId = undefined;
      return {};
    }

    const leftPlayerId = session.playerId;
    const timer = room.disconnectTimers.get(leftPlayerId);
    if (timer) {
      clearTimeout(timer);
      room.disconnectTimers.delete(leftPlayerId);
    }
    room.players = room.players.filter((p) => p.id !== leftPlayerId);
    session.roomId = undefined;

    let newHostId: string | undefined;
    if (room.hostId === leftPlayerId) {
      const nextHost = room.players.find((p) => p.isConnected !== false);
      if (nextHost) {
        nextHost.isHost = true;
        room.hostId = nextHost.id;
        newHostId = nextHost.id;
      }
    }

    if (room.players.length === 0) {
      if (room.emptyTimer) {
        clearTimeout(room.emptyTimer);
      }
      room.emptyTimer = setTimeout(() => {
        for (const t of room.disconnectTimers.values()) {
          clearTimeout(t);
        }
        room.disconnectTimers.clear();
        for (const sess of this.sessions.values()) {
          if (sess.roomId === room.id) {
            sess.roomId = undefined;
          }
        }
        this.rooms.delete(room.id);
        logger.info({ roomId: room.id }, "Empty room cleaned up");
      }, config.emptyRoomRetentionMs);
    }

    return { room, leftPlayerId, newHostId };
  }

  removeDisconnectedPlayer(room: Room, playerId: string): { newHostId?: string; wasAborted: boolean } {
    const timer = room.disconnectTimers.get(playerId);
    if (timer) {
      clearTimeout(timer);
      room.disconnectTimers.delete(playerId);
    }
    room.players = room.players.filter((p) => p.id !== playerId);

    let newHostId: string | undefined;
    if (room.hostId === playerId) {
      const nextHost = room.players.find((p) => p.isConnected !== false);
      if (nextHost) {
        nextHost.isHost = true;
        room.hostId = nextHost.id;
        newHostId = nextHost.id;
      }
    }

    if (room.players.length === 0) {
      if (room.emptyTimer) {
        clearTimeout(room.emptyTimer);
      }
      room.emptyTimer = setTimeout(() => {
        for (const t of room.disconnectTimers.values()) {
          clearTimeout(t);
        }
        room.disconnectTimers.clear();
        for (const sess of this.sessions.values()) {
          if (sess.roomId === room.id) {
            sess.roomId = undefined;
          }
        }
        this.rooms.delete(room.id);
        logger.info({ roomId: room.id }, "Empty room cleaned up");
      }, config.emptyRoomRetentionMs);
    }

    const wasAborted = this.checkAndAbortGameIfUnderflow(room);
    return { newHostId, wasAborted };
  }

  kickPlayer(
    room: Room,
    targetPlayerId: string,
  ): { targetSocketId?: string; leftPlayerId: string } | null {
    const target = room.players.find((p) => p.id === targetPlayerId);
    if (!target) return null;

    const targetSocketId = target.socketId;
    const leftPlayerId = target.id;

    const timer = room.disconnectTimers.get(targetPlayerId);
    if (timer) {
      clearTimeout(timer);
      room.disconnectTimers.delete(targetPlayerId);
    }

    room.players = room.players.filter((p) => p.id !== targetPlayerId);

    const targetSession = this.sessions.get(target.resumeToken);
    if (targetSession) {
      targetSession.roomId = undefined;
    }

    return { targetSocketId, leftPlayerId };
  }

  banPlayer(
    room: Room,
    targetPlayerId: string,
  ): { targetSocketId?: string; leftPlayerId: string } | null {
    const target = room.players.find((p) => p.id === targetPlayerId);
    if (!target) return null;

    room.bannedPlayerIds.add(target.id);
    room.bannedTokens.add(target.resumeToken);

    return this.kickPlayer(room, targetPlayerId);
  }

  checkAndAbortGameIfUnderflow(room: Room): boolean {
    if (!room.gameState || room.gameState.currentPhase.name === "ended") {
      return false;
    }

    if (room.players.length < 3) {
      room.gameState = undefined;
      for (const p of room.players) {
        p.isReady = false;
        p.usedAccusation = false;
        p.isAlive = true;
      }
      return true;
    }
    return false;
  }

  handleDisconnect(
    socketId: string,
    onGraceExpired: (room: Room, playerId: string) => void,
  ): { room?: Room; playerId?: string } {
    const session = this.getSessionBySocket(socketId);
    if (!session || !session.roomId) {
      this.socketToToken.delete(socketId);
      return {};
    }

    // If the session has already moved to a new socket, this disconnect event is stale.
    if (session.socketId !== socketId) {
      this.socketToToken.delete(socketId);
      return {};
    }

    const room = this.rooms.get(session.roomId);
    if (!room) {
      this.socketToToken.delete(socketId);
      return {};
    }

    const player = room.players.find((p) => p.id === session.playerId);
    if (!player) {
      this.socketToToken.delete(socketId);
      return {};
    }

    player.isConnected = false;
    if (room.gameState) {
      const gp = room.gameState.players.find((p) => p.id === session.playerId);
      if (gp) {
        gp.isConnected = false;
      }
    }

    // Clear any previous timer before starting a fresh one
    const prevTimer = room.disconnectTimers.get(player.id);
    if (prevTimer) {
      clearTimeout(prevTimer);
      room.disconnectTimers.delete(player.id);
    }

    // In the lobby, remove disconnected players quickly (1s debounce) so room player counts stay accurate.
    // Mid-game, allow the full grace period so brief cellular/wifi handoffs do not kill the game.
    const isLobby = !room.gameState || room.gameState.currentPhase.name === "lobby";
    const graceMs = isLobby ? 1000 : config.disconnectGracePeriodMs;

    // Start grace timer
    const timer = setTimeout(() => {
      onGraceExpired(room, player.id);
    }, graceMs);

    room.disconnectTimers.set(player.id, timer);
    return { room, playerId: player.id };
  }

  getPublicRoomState(room: Room): Record<string, any> {
    const isEnded = room.gameState?.currentPhase.name === "ended";
    const phaseName = room.gameState ? room.gameState.currentPhase.name : "lobby";

    return {
      id: room.id,
      name: room.name,
      pin: room.pin,
      max: room.settings.maxPlayers,
      hostId: room.hostId,
      players: room.players.map((p) => {
        const gp = room.gameState?.players.find((g) => g.id === p.id);
        const isRevealed =
          isEnded ||
          (room.gameState?.lastAccusationResult?.targetId === p.id &&
            room.gameState?.lastAccusationResult.outcome === "caught");
        return {
          id: p.id,
          name: p.name,
          color: p.color,
          isHost: p.id === room.hostId,
          isAlive: gp ? gp.isAlive : p.isAlive,
          isConnected: p.isConnected !== false,
          isReady: gp ? gp.isReady : p.isReady,
          usedAccusation: gp ? gp.usedAccusation : p.usedAccusation,
          // STRICT SECURITY: Never leak role unless ended or publicly revealed!
          role: isRevealed ? gp?.role : undefined,
        };
      }),
      settings: room.settings,
      phase: phaseName,
      currentTurn:
        room.gameState && room.gameState.currentPhase.name === "discussion"
          ? {
              speakerId: GameEngine.getCurrentSpeakerId(room.gameState),
              round: room.gameState.currentPhase.round,
              turnIndex: room.gameState.currentPhase.turnIndex,
            }
          : undefined,
      clues: room.gameState?.clues || [],
      lastAccusation: room.gameState?.lastAccusationResult,
      isFinalVote:
        room.gameState?.currentPhase.name === "finalVote" ||
        (room.gameState?.currentPhase.name === "accusationPending" &&
          room.gameState.currentPhase.isFinalVote),
      ended:
        isEnded && room.gameState?.currentPhase.name === "ended"
          ? {
              winner: room.gameState.currentPhase.winner,
              reason: room.gameState.currentPhase.reason,
              secretWord: room.gameState.currentPhase.secretWord,
              category: room.gameState.currentPhase.category,
            }
          : undefined,
    };
  }

  startRoomGame(room: Room): { room: Room; secretWord: string; category: string } {
    if (room.players.length < 3) {
      throw new Error("MIN_PLAYERS_NOT_MET");
    }

    const { category, word } = pickSecretWord(
      room.settings.category,
      room.settings.customWord,
      room.settings.customCategory
    );

    const gamePlayers: GamePlayer[] = room.players.map((p) => ({
      id: p.id,
      name: p.name,
      color: p.color,
      isAlive: true,
      isHost: p.id === room.hostId,
      usedAccusation: false,
      remainingGuesses: room.settings.guessAttempts,
      isReady: false,
      isConnected: p.isConnected !== false,
    }));

    const state = GameEngine.startGame({
      players: gamePlayers,
      settings: room.settings,
      secretWord: word,
      category,
    });

    room.gameState = state;
    return { room, secretWord: word, category };
  }
}
