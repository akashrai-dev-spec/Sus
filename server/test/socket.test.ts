import http from "http";
import { AddressInfo } from "net";
import { Server } from "socket.io";
import { io as Client, Socket as ClientSocket } from "socket.io-client";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { RoomManager } from "../src/rooms/roomManager.js";
import { registerSocketHandlers } from "../src/socket/handlers.js";

describe("Socket.IO Server Integration Tests", () => {
  let httpServer: http.Server;
  let ioServer: Server;
  let serverPort: number;
  let roomManager: RoomManager;

  beforeAll(async () => {
    httpServer = http.createServer();
    ioServer = new Server(httpServer);
    const gameNamespace = ioServer.of("/game");
    roomManager = new RoomManager();
    registerSocketHandlers(gameNamespace, roomManager);

    await new Promise<void>((resolve) => {
      httpServer.listen(0, () => {
        serverPort = (httpServer.address() as AddressInfo).port;
        resolve();
      });
    });
  });

  afterAll(async () => {
    ioServer.close();
    await new Promise<void>((resolve) => httpServer.close(() => resolve()));
  });

  function createClient(): ClientSocket {
    return Client(`http://localhost:${serverPort}/game`, {
      auth: { protocolVersion: "1.0.0" },
      transports: ["websocket"],
      forceNew: true,
    });
  }

  it("handles session:hello, room:create and room:join with valid PIN", async () => {
    const host = createClient();
    const guest = createClient();

    try {
      // 1. Host session
      const hostHello = await new Promise<any>((resolve) => {
        host.emit("session:hello", { name: "Host Player", color: "#9A0F28" }, resolve);
      });
      expect(hostHello.ok).toBe(true);
      expect(hostHello.data.playerId).toBeDefined();

      // 2. Guest session
      const guestHello = await new Promise<any>((resolve) => {
        guest.emit("session:hello", { name: "Guest Player", color: "#1D4ED8" }, resolve);
      });
      expect(guestHello.ok).toBe(true);

      // 3. Create room
      const createRes = await new Promise<any>((resolve) => {
        host.emit(
          "rooms:create",
          {
            name: "Test Room",
            pin: "1234",
            settings: {
              maxPlayers: 4,
              imposters: 1,
              rounds: 2,
              guessAttempts: 1,
              category: "Objects & Food",
            },
          },
          resolve,
        );
      });
      expect(createRes.ok).toBe(true);
      expect(createRes.data.pin).toBe("1234");
      const roomId = createRes.data.id;

      // 4. Guest joins room
      const joinRes = await new Promise<any>((resolve) => {
        guest.emit("rooms:join", { roomId, pin: "1234" }, resolve);
      });
      expect(joinRes.ok).toBe(true);
      expect(joinRes.data.pin).toBe("1234");
      expect(joinRes.data.players.length).toBe(2);

      // 5. Another guest joins with identical name as host ("Host Player") -> should be disambiguated to "Host Player 2"
      const duplicateGuest = createClient();
      await new Promise<any>((resolve) => {
        duplicateGuest.emit("session:hello", { name: "Host Player", color: "#4D7C0F" }, resolve);
      });
      const dupJoinRes = await new Promise<any>((resolve) => {
        duplicateGuest.emit("rooms:join", { roomId, pin: "1234" }, resolve);
      });
      expect(dupJoinRes.ok).toBe(true);
      expect(dupJoinRes.data.players.some((p: any) => p.name === "Host Player 2")).toBe(true);
      duplicateGuest.disconnect();
    } finally {
      host.disconnect();
      guest.disconnect();
    }
  });

  it("rejects wrong PIN and enforces rate limit after 5 attempts", async () => {
    const host = createClient();
    const attacker = createClient();

    try {
      await new Promise<any>((resolve) => {
        host.emit("session:hello", { name: "Host", color: "#9A0F28" }, resolve);
      });
      await new Promise<any>((resolve) => {
        attacker.emit("session:hello", { name: "Attacker", color: "#9A0F28" }, resolve);
      });

      const createRes = await new Promise<any>((resolve) => {
        host.emit(
          "rooms:create",
          {
            name: "Pin Protection",
            pin: "7777",
            settings: {
              maxPlayers: 4,
              imposters: 1,
              rounds: 2,
              guessAttempts: 1,
              category: "Objects & Food",
            },
          },
          resolve,
        );
      });
      const roomId = createRes.data.id;

      // 5 wrong PIN attempts
      for (let i = 0; i < 5; i++) {
        const attempt = await new Promise<any>((resolve) => {
          attacker.emit("rooms:join", { roomId, pin: "0000" }, resolve);
        });
        expect(attempt.ok).toBe(false);
        expect(attempt.code).toBe("WRONG_PIN");
      }

      // 6th attempt -> RATE_LIMITED!
      const blockedAttempt = await new Promise<any>((resolve) => {
        attacker.emit("rooms:join", { roomId, pin: "0000" }, resolve);
      });
      expect(blockedAttempt.ok).toBe(false);
      expect(blockedAttempt.code).toBe("RATE_LIMITED");
    } finally {
      host.disconnect();
      attacker.disconnect();
    }
  });

  it("CRITICAL ANTI-CHEAT: proves an imposter socket NEVER receives the secret word", async () => {
    const p1 = createClient();
    const p2 = createClient();
    const p3 = createClient();

    try {
      await new Promise<any>((r) => p1.emit("session:hello", { name: "P1", color: "#9A0F28" }, r));
      await new Promise<any>((r) => p2.emit("session:hello", { name: "P2", color: "#9A0F28" }, r));
      await new Promise<any>((r) => p3.emit("session:hello", { name: "P3", color: "#9A0F28" }, r));

      const createRes = await new Promise<any>((r) => {
        p1.emit(
          "rooms:create",
          {
            name: "No Leak Room",
            pin: "9999",
            settings: {
              maxPlayers: 3,
              imposters: 1,
              rounds: 2,
              guessAttempts: 1,
              category: "Animals",
            },
          },
          r,
        );
      });
      const roomId = createRes.data.id;

      await new Promise<any>((r) => p2.emit("rooms:join", { roomId, pin: "9999" }, r));
      await new Promise<any>((r) => p3.emit("rooms:join", { roomId, pin: "9999" }, r));

      const roleEvents: Record<string, any> = {};

      p1.on("game:role", (data) => (roleEvents.p1 = data));
      p2.on("game:role", (data) => (roleEvents.p2 = data));
      p3.on("game:role", (data) => (roleEvents.p3 = data));

      // Start game
      const startRes = await new Promise<any>((r) => p1.emit("game:start", {}, r));
      expect(startRes.ok).toBe(true);

      // Wait a moment for role delivery
      await new Promise((r) => setTimeout(r, 200));

      const clients = [roleEvents.p1, roleEvents.p2, roleEvents.p3];
      const imposterEvent = clients.find((e) => e?.role === "imposter");
      const normalEvent = clients.find((e) => e?.role === "normal");

      expect(imposterEvent).toBeDefined();
      expect(normalEvent).toBeDefined();

      // STRICT CHECK: The imposter event must NOT contain the 'word' property!
      expect(imposterEvent.word).toBeUndefined();
      expect(imposterEvent.category).toBeDefined();

      // Normal event DOES contain the word
      expect(normalEvent.word).toBeDefined();
      expect(typeof normalEvent.word).toBe("string");
    } finally {
      p1.disconnect();
      p2.disconnect();
      p3.disconnect();
    }
  });

  it("handles host migration when host leaves room", async () => {
    const host = createClient();
    const guest = createClient();

    try {
      await new Promise<any>((r) =>
        host.emit("session:hello", { name: "Host Migration 1", color: "#9A0F28" }, r),
      );
      const guestHello = await new Promise<any>((r) =>
        guest.emit("session:hello", { name: "Guest Migration 2", color: "#1D4ED8" }, r),
      );

      const createRes = await new Promise<any>((r) => {
        host.emit(
          "rooms:create",
          {
            name: "Migration Room",
            pin: "1111",
            settings: {
              maxPlayers: 4,
              imposters: 1,
              rounds: 2,
              guessAttempts: 1,
              category: "Places",
            },
          },
          r,
        );
      });
      const roomId = createRes.data.id;

      await new Promise<any>((r) => guest.emit("rooms:join", { roomId, pin: "1111" }, r));

      // Host leaves
      await new Promise<any>((r) => host.emit("rooms:leave", {}, r));

      // Fetch state or check room host
      const room = roomManager.getRoom(roomId);
      expect(room).toBeDefined();
      expect(room!.hostId).toBe(guestHello.data.playerId);
    } finally {
      host.disconnect();
      guest.disconnect();
    }
  });

  it("allows host to kick and ban players, and prevents banned player from rejoining", async () => {
    const host = createClient();
    const guest = createClient();

    try {
      await new Promise<any>((r) =>
        host.emit("session:hello", { name: "Host Boss", color: "#9A0F28" }, r),
      );
      const guestHello = await new Promise<any>((r) =>
        guest.emit("session:hello", { name: "Troll Player", color: "#1D4ED8" }, r),
      );

      const createRes = await new Promise<any>((r) => {
        host.emit(
          "rooms:create",
          {
            name: "Kick Test Room",
            pin: "2222",
            settings: {
              maxPlayers: 4,
              imposters: 1,
              rounds: 2,
              guessAttempts: 1,
              category: "General",
            },
          },
          r,
        );
      });
      const roomId = createRes.data.id;
      const guestId = guestHello.data.playerId;

      await new Promise<any>((r) => guest.emit("rooms:join", { roomId, pin: "2222" }, r));

      // Host bans guest
      const banRes = await new Promise<any>((r) => {
        host.emit("room:banPlayer", { targetId: guestId }, r);
      });
      expect(banRes.ok).toBe(true);

      // Guest tries to rejoin
      const rejoinRes = await new Promise<any>((r) => {
        guest.emit("rooms:join", { roomId, pin: "2222" }, r);
      });
      expect(rejoinRes.ok).toBe(false);
      expect(rejoinRes.code).toBe("BANNED");
    } finally {
      host.disconnect();
      guest.disconnect();
    }
  });

  it("aborts active game and returns to lobby when players fall below 3", async () => {
    const p1 = createClient();
    const p2 = createClient();
    const p3 = createClient();

    try {
      await new Promise<any>((r) => p1.emit("session:hello", { name: "P1", color: "#9A0F28" }, r));
      await new Promise<any>((r) => p2.emit("session:hello", { name: "P2", color: "#1D4ED8" }, r));
      await new Promise<any>((r) => p3.emit("session:hello", { name: "P3", color: "#047857" }, r));

      const createRes = await new Promise<any>((r) => {
        p1.emit(
          "rooms:create",
          {
            name: "Underflow Room",
            pin: "3333",
            settings: {
              maxPlayers: 3,
              imposters: 1,
              rounds: 2,
              guessAttempts: 1,
              category: "Objects & Food",
            },
          },
          r,
        );
      });
      const roomId = createRes.data.id;

      await new Promise<any>((r) => p2.emit("rooms:join", { roomId, pin: "3333" }, r));
      await new Promise<any>((r) => p3.emit("rooms:join", { roomId, pin: "3333" }, r));

      // Host starts game
      const startRes = await new Promise<any>((r) => p1.emit("game:start", {}, r));
      expect(startRes.ok).toBe(true);

      const room = roomManager.getRoom(roomId);
      expect(room?.gameState).toBeDefined();

      // P3 leaves mid-game (dropping player count to 2 < 3)
      await new Promise<any>((r) => p3.emit("rooms:leave", {}, r));

      // Game state should be aborted back to lobby
      expect(room?.gameState).toBeUndefined();
      const pubState = roomManager.getPublicRoomState(room!);
      expect(pubState.phase).toBe("lobby");

      // New player can now join because room is in lobby!
      const p4 = createClient();
      await new Promise<any>((r) => p4.emit("session:hello", { name: "P4", color: "#F59E0B" }, r));
      const joinRes = await new Promise<any>((r) => p4.emit("rooms:join", { roomId, pin: "3333" }, r));
      expect(joinRes.ok).toBe(true);
      p4.disconnect();
    } finally {
      p1.disconnect();
      p2.disconnect();
      p3.disconnect();
    }
  });
});
