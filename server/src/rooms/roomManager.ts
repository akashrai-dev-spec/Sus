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
}

export function ensureUniqueName(existingNames: string[], requestedName: string): string {
  const clean = requestedName.trim() || "Player";
  const lowerExisting = new Set(existingNames.map((n) => n.trim().toLowerCase()));
  if (!lowerExisting.has(clean.toLowerCase())) {
    return clean;
  }

  let counter = 2;
  while (lowerExisting.has(`${clean.toLowerCase()} ${counter}`)) {
    counter++;
  }
  return `${clean} ${counter}`;
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
      existing.socketId = socketId;
      existing.name = name || existing.name;
      existing.color = color || existing.color;
      this.socketToToken.set(socketId, resumeToken);
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

  async createRoom(
    session: SessionInfo,
    params: { name: string; pin: string; settings: GameSettings },
  ): Promise<Room> {
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
      name: params.name.trim() || `${session.name}'s room`,
      pin: params.pin,
      pinHash,
      settings: params.settings,
      hostId: session.playerId,
      players: [hostPlayer],
      disconnectTimers: new Map(),
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

    const existingIndex = room.players.findIndex((p) => p.id === session.playerId);
    if (existingIndex !== -1) {
      // Reconnection
      const p = room.players[existingIndex];
      p.socketId = session.socketId;
      p.isConnected = true;
      const timer = room.disconnectTimers.get(session.playerId);
      if (timer) {
        clearTimeout(timer);
        room.disconnectTimers.delete(session.playerId);
      }
    } else {
      if (room.players.length >= room.settings.maxPlayers) {
        throw new Error("ROOM_FULL");
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
      room.emptyTimer = setTimeout(() => {
        this.rooms.delete(room.id);
        logger.info({ roomId: room.id }, "Empty room cleaned up");
      }, config.emptyRoomRetentionMs);
    }

    return { room, leftPlayerId, newHostId };
  }

  handleDisconnect(
    socketId: string,
    onGraceExpired: (room: Room, playerId: string) => void,
  ): { room?: Room; playerId?: string } {
    const session = this.getSessionBySocket(socketId);
    if (!session || !session.roomId) return {};

    const room = this.rooms.get(session.roomId);
    if (!room) return {};

    const player = room.players.find((p) => p.id === session.playerId);
    if (!player) return {};

    player.isConnected = false;

    // Start 60-second grace timer
    const timer = setTimeout(() => {
      onGraceExpired(room, player.id);
    }, config.disconnectGracePeriodMs);

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
