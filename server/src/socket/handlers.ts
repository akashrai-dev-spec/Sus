import { Namespace, Socket } from "socket.io";
import { config } from "../config.js";
import { GameEngine } from "../game/gameEngine.js";
import { Room, RoomManager } from "../rooms/roomManager.js";
import { logger } from "../util/logger.js";
import { RateLimiter } from "../util/rateLimiter.js";
import {
  accuseSubmitSchema,
  gameSettingsSchema,
  imposterGuessSchema,
  profileUpdateSchema,
  roomsCreateSchema,
  roomsJoinSchema,
  sessionHelloSchema,
  turnClueSchema,
} from "./schemas.js";

type AckCallback = (response: { ok: boolean; data?: any; code?: string; message?: string }) => void;

function safeAck(ack: AckCallback | undefined, ok: boolean, payload?: any): void {
  if (typeof ack !== "function") return;
  if (ok) {
    ack({ ok: true, data: payload });
  } else {
    ack({
      ok: false,
      code: payload?.code || "ERROR",
      message: payload?.message || "An unexpected error occurred.",
    });
  }
}

export function registerSocketHandlers(io: Namespace, roomManager: RoomManager): void {
  // 5 wrong PIN attempts per minute per socket
  const pinRateLimiter = new RateLimiter(5, 60000);

  io.use((socket, next) => {
    const auth = socket.handshake.auth;
    if (auth?.protocolVersion && auth.protocolVersion !== config.protocolVersion) {
      return next(new Error("ERR_PROTOCOL_MISMATCH"));
    }
    next();
  });

  io.on("connection", (socket: Socket) => {
    logger.debug({ socketId: socket.id }, "Client connected to /game");

    // 1. session:hello
    socket.on("session:hello", (rawPayload, ack: AckCallback) => {
      const parsed = sessionHelloSchema.safeParse(rawPayload);
      if (!parsed.success) {
        return safeAck(ack, false, {
          code: "VALIDATION_FAILED",
          message: parsed.error.issues[0]?.message || "Invalid payload",
        });
      }

      const session = roomManager.registerSession({
        socketId: socket.id,
        name: parsed.data.name,
        color: parsed.data.color,
        resumeToken: parsed.data.resumeToken,
      });

      // If already in a room, re-join socket room and restore role
      if (session.roomId) {
        const room = roomManager.getRoom(session.roomId);
        if (room) {
          socket.join(room.id);
          sendPrivateRole(socket, room, session.playerId);
          io.to(room.id).emit("room:state", roomManager.getPublicRoomState(room));
        }
      }

      safeAck(ack, true, {
        playerId: session.playerId,
        resumeToken: session.resumeToken,
        roomId: session.roomId,
      });
    });

    // 2. rooms:list
    socket.on("rooms:list", (_, ack: AckCallback) => {
      const list = roomManager.listPublicRooms();
      safeAck(ack, true, list);
    });

    // 3. rooms:create
    socket.on("rooms:create", async (rawPayload, ack: AckCallback) => {
      const session = roomManager.getSessionBySocket(socket.id);
      if (!session) {
        return safeAck(ack, false, {
          code: "UNAUTHENTICATED",
          message: "Please complete session:hello first.",
        });
      }

      const parsed = roomsCreateSchema.safeParse(rawPayload);
      if (!parsed.success) {
        return safeAck(ack, false, {
          code: "VALIDATION_FAILED",
          message: parsed.error.issues[0]?.message || "Invalid payload",
        });
      }

      try {
        const room = await roomManager.createRoom(session, {
          name: parsed.data.name,
          pin: parsed.data.pin,
          settings: parsed.data.settings,
        });

        socket.join(room.id);
        const state = roomManager.getPublicRoomState(room);
        safeAck(ack, true, state);
        io.to(room.id).emit("room:state", state);
      } catch (err: any) {
        safeAck(ack, false, { code: "CREATE_FAILED", message: err.message });
      }
    });

    // 4. rooms:join
    socket.on("rooms:join", async (rawPayload, ack: AckCallback) => {
      const session = roomManager.getSessionBySocket(socket.id);
      if (!session) {
        return safeAck(ack, false, {
          code: "UNAUTHENTICATED",
          message: "Please complete session:hello first.",
        });
      }

      const parsed = roomsJoinSchema.safeParse(rawPayload);
      if (!parsed.success) {
        return safeAck(ack, false, {
          code: "VALIDATION_FAILED",
          message: parsed.error.issues[0]?.message || "Invalid payload",
        });
      }

      const rateCheck = pinRateLimiter.check(socket.id);
      if (!rateCheck.allowed) {
        return safeAck(ack, false, {
          code: "RATE_LIMITED",
          message: `Too many wrong PIN attempts. Cooldown ${Math.ceil((rateCheck.retryAfterMs || 0) / 1000)}s.`,
        });
      }

      const room = roomManager.getRoom(parsed.data.roomId);
      if (!room) {
        return safeAck(ack, false, { code: "NOT_FOUND", message: "Room not found." });
      }

      const pinValid = await roomManager.verifyPin(room, parsed.data.pin);
      if (!pinValid) {
        return safeAck(ack, false, { code: "WRONG_PIN", message: "Wrong PIN. Try again." });
      }

      pinRateLimiter.reset(socket.id);

      try {
        roomManager.joinRoom(session, room);
        socket.join(room.id);

        const state = roomManager.getPublicRoomState(room);
        safeAck(ack, true, state);

        io.to(room.id).emit("room:state", state);
        socket.to(room.id).emit("room:playerJoined", {
          id: session.playerId,
          name: session.name,
          color: session.color,
        });

        if (room.gameState) {
          sendPrivateRole(socket, room, session.playerId);
        }
      } catch (err: any) {
        safeAck(ack, false, { code: err.message || "JOIN_FAILED", message: err.message });
      }
    });

    // 5. rooms:leave
    socket.on("rooms:leave", (_, ack: AckCallback) => {
      const session = roomManager.getSessionBySocket(socket.id);
      if (!session || !session.roomId) {
        return safeAck(ack, true);
      }

      const roomId = session.roomId;
      const { room, leftPlayerId } = roomManager.leaveRoom(socket.id);
      socket.leave(roomId);

      if (room && leftPlayerId) {
        io.to(room.id).emit("room:playerLeft", { playerId: leftPlayerId });
        io.to(room.id).emit("room:state", roomManager.getPublicRoomState(room));
      }
      safeAck(ack, true);
    });

    // 6. room:updateSettings
    socket.on("room:updateSettings", (rawSettings, ack: AckCallback) => {
      const session = roomManager.getSessionBySocket(socket.id);
      if (!session?.roomId) {
        return safeAck(ack, false, { code: "NOT_IN_ROOM", message: "Not in a room." });
      }

      const room = roomManager.getRoom(session.roomId);
      if (!room || room.hostId !== session.playerId) {
        return safeAck(ack, false, { code: "HOST_ONLY", message: "Only the host can modify settings." });
      }

      const parsed = gameSettingsSchema.safeParse(rawSettings);
      if (!parsed.success) {
        return safeAck(ack, false, { code: "VALIDATION_FAILED", message: "Invalid settings." });
      }

      room.settings = parsed.data;
      const state = roomManager.getPublicRoomState(room);
      safeAck(ack, true, state);
      io.to(room.id).emit("room:state", state);
    });

    // 7. game:start
    socket.on("game:start", (_, ack: AckCallback) => {
      const session = roomManager.getSessionBySocket(socket.id);
      if (!session?.roomId) {
        return safeAck(ack, false, { code: "NOT_IN_ROOM", message: "Not in a room." });
      }

      const room = roomManager.getRoom(session.roomId);
      if (!room || room.hostId !== session.playerId) {
        return safeAck(ack, false, { code: "HOST_ONLY", message: "Only the host can start the game." });
      }

      try {
        const { secretWord, category } = roomManager.startRoomGame(room);

        // Disseminate private roles safely
        for (const p of room.players) {
          const clientSocket = io.sockets.get(p.socketId);
          if (clientSocket) {
            const role = room.gameState!.players.find((gp) => gp.id === p.id)?.role;
            if (role === "imposter") {
              clientSocket.emit("game:role", {
                role: "imposter",
                category,
              });
            } else {
              clientSocket.emit("game:role", {
                role: "normal",
                word: secretWord,
                category,
              });
            }
          }
        }

        const state = roomManager.getPublicRoomState(room);
        safeAck(ack, true, state);
        io.to(room.id).emit("room:state", state);
      } catch (err: any) {
        safeAck(ack, false, { code: err.message || "START_FAILED", message: err.message });
      }
    });

    // 8. game:ready
    socket.on("game:ready", (_, ack: AckCallback) => {
      const session = roomManager.getSessionBySocket(socket.id);
      if (!session?.roomId) return safeAck(ack, false, { code: "NOT_IN_ROOM", message: "Not in room." });

      const room = roomManager.getRoom(session.roomId);
      if (!room?.gameState) return safeAck(ack, false, { code: "NO_GAME", message: "No active game." });

      try {
        room.gameState = GameEngine.markPlayerReady(room.gameState, session.playerId);
        const state = roomManager.getPublicRoomState(room);
        safeAck(ack, true, state);
        io.to(room.id).emit("room:state", state);

        if (room.gameState.currentPhase.name === "discussion") {
          io.to(room.id).emit("game:turn", {
            speakerId: GameEngine.getCurrentSpeakerId(room.gameState),
            round: room.gameState.currentPhase.round,
            turnIndex: room.gameState.currentPhase.turnIndex,
          });
        }
      } catch (err: any) {
        safeAck(ack, false, { code: err.code || "READY_FAILED", message: err.message });
      }
    });

    // 9. turn:clue
    socket.on("turn:clue", (rawPayload, ack: AckCallback) => {
      const session = roomManager.getSessionBySocket(socket.id);
      if (!session?.roomId) return safeAck(ack, false, { code: "NOT_IN_ROOM", message: "Not in room." });

      const room = roomManager.getRoom(session.roomId);
      if (!room?.gameState) return safeAck(ack, false, { code: "NO_GAME", message: "No active game." });

      const parsed = turnClueSchema.safeParse(rawPayload);
      if (!parsed.success) {
        return safeAck(ack, false, {
          code: "VALIDATION_FAILED",
          message: parsed.error.issues[0]?.message || "Invalid clue.",
        });
      }

      try {
        room.gameState = GameEngine.submitClue(room.gameState, {
          playerId: session.playerId,
          text: parsed.data.text,
        });

        const latestClue = room.gameState.clues[room.gameState.clues.length - 1];
        io.to(room.id).emit("game:clue", latestClue);

        const state = roomManager.getPublicRoomState(room);
        safeAck(ack, true, state);
        io.to(room.id).emit("room:state", state);

        if (room.gameState.currentPhase.name === "discussion") {
          io.to(room.id).emit("game:turn", {
            speakerId: GameEngine.getCurrentSpeakerId(room.gameState),
            round: room.gameState.currentPhase.round,
            turnIndex: room.gameState.currentPhase.turnIndex,
          });
        }
      } catch (err: any) {
        safeAck(ack, false, { code: err.code || "CLUE_FAILED", message: err.message });
      }
    });

    // 10. accuse:submit
    socket.on("accuse:submit", (rawPayload, ack: AckCallback) => {
      const session = roomManager.getSessionBySocket(socket.id);
      if (!session?.roomId) return safeAck(ack, false, { code: "NOT_IN_ROOM", message: "Not in room." });

      const room = roomManager.getRoom(session.roomId);
      if (!room?.gameState) return safeAck(ack, false, { code: "NO_GAME", message: "No active game." });

      const parsed = accuseSubmitSchema.safeParse(rawPayload);
      if (!parsed.success) {
        return safeAck(ack, false, { code: "VALIDATION_FAILED", message: "Invalid target." });
      }

      try {
        room.gameState = GameEngine.submitAccusation(room.gameState, {
          accuserId: session.playerId,
          targetId: parsed.data.targetId,
        });

        // Resolve accusation
        room.gameState = GameEngine.resolveAccusation(room.gameState);
        const result = room.gameState.lastAccusationResult!;

        io.to(room.id).emit("game:accusation", result);

        if (room.gameState.currentPhase.name === "ended") {
          const ended = room.gameState.currentPhase;
          const allRoles: Record<string, string> = {};
          for (const gp of room.gameState.players) {
            allRoles[gp.id] = gp.role || "normal";
          }
          io.to(room.id).emit("game:ended", {
            winner: ended.winner,
            reason: ended.reason,
            secretWord: ended.secretWord,
            category: ended.category,
            allRoles,
          });
        }

        const state = roomManager.getPublicRoomState(room);
        safeAck(ack, true, state);
        io.to(room.id).emit("room:state", state);
      } catch (err: any) {
        safeAck(ack, false, { code: err.code || "ACCUSE_FAILED", message: err.message });
      }
    });

    // 11. imposter:guess
    socket.on("imposter:guess", (rawPayload, ack: AckCallback) => {
      const session = roomManager.getSessionBySocket(socket.id);
      if (!session?.roomId) return safeAck(ack, false, { code: "NOT_IN_ROOM", message: "Not in room." });

      const room = roomManager.getRoom(session.roomId);
      if (!room?.gameState) return safeAck(ack, false, { code: "NO_GAME", message: "No active game." });

      const parsed = imposterGuessSchema.safeParse(rawPayload);
      if (!parsed.success) {
        return safeAck(ack, false, { code: "VALIDATION_FAILED", message: "Invalid guess." });
      }

      try {
        const prevPhase = room.gameState.currentPhase.name;
        room.gameState = GameEngine.imposterGuess(room.gameState, {
          playerId: session.playerId,
          word: parsed.data.word,
        });

        if (room.gameState.currentPhase.name === "ended") {
          const ended = room.gameState.currentPhase;
          const allRoles: Record<string, string> = {};
          for (const gp of room.gameState.players) {
            allRoles[gp.id] = gp.role || "normal";
          }
          io.to(room.id).emit("game:ended", {
            winner: ended.winner,
            reason: ended.reason,
            secretWord: ended.secretWord,
            category: ended.category,
            allRoles,
          });
        }

        const state = roomManager.getPublicRoomState(room);
        const correct = room.gameState.currentPhase.name === "ended" && prevPhase !== "ended";
        safeAck(ack, true, { correct, state });
        io.to(room.id).emit("room:state", state);
      } catch (err: any) {
        safeAck(ack, false, { code: err.code || "GUESS_FAILED", message: err.message });
      }
    });

    // 12. profile:update
    socket.on("profile:update", (rawPayload, ack: AckCallback) => {
      const parsed = profileUpdateSchema.safeParse(rawPayload);
      if (!parsed.success) {
        return safeAck(ack, false, { code: "VALIDATION_FAILED", message: "Invalid profile." });
      }

      const updated = roomManager.updateProfile(socket.id, parsed.data.name, parsed.data.color);
      if (!updated) {
        return safeAck(ack, false, { code: "NOT_FOUND", message: "Session not found." });
      }

      if (updated.roomId) {
        const room = roomManager.getRoom(updated.roomId);
        if (room) {
          io.to(room.id).emit("room:state", roomManager.getPublicRoomState(room));
        }
      }

      safeAck(ack, true, { name: updated.name, color: updated.color });
    });

    // Disconnect
    socket.on("disconnect", () => {
      const { room, playerId } = roomManager.handleDisconnect(socket.id, (expiredRoom, pId) => {
        logger.info({ roomId: expiredRoom.id, playerId: pId }, "Disconnect grace expired");
        io.to(expiredRoom.id).emit("room:playerLeft", { playerId: pId });
        io.to(expiredRoom.id).emit("room:state", roomManager.getPublicRoomState(expiredRoom));
      });

      if (room && playerId) {
        io.to(room.id).emit("room:playerDisconnected", { playerId });
        io.to(room.id).emit("room:state", roomManager.getPublicRoomState(room));
      }
    });
  });

  function sendPrivateRole(socket: Socket, room: Room, playerId: string): void {
    if (!room.gameState) return;
    const player = room.gameState.players.find((p) => p.id === playerId);
    if (!player) return;

    if (player.role === "imposter") {
      socket.emit("game:role", {
        role: "imposter",
        category: room.gameState.category,
      });
    } else {
      socket.emit("game:role", {
        role: "normal",
        word: room.gameState.secretWord,
        category: room.gameState.category,
      });
    }
  }
}
