import http from "http";
import { Server } from "socket.io";
import { config } from "./config.js";
import { RoomManager } from "./rooms/roomManager.js";
import { registerSocketHandlers } from "./socket/handlers.js";
import { logger } from "./util/logger.js";

const server = http.createServer((req, res) => {
  if (req.url === "/health" || req.url === "/api/health") {
    res.writeHead(200, { "Content-Type": "application/json" });
    res.end(JSON.stringify({ status: "ok", version: config.protocolVersion }));
    return;
  }
  res.writeHead(404);
  res.end();
});

const io = new Server(server, {
  cors: {
    origin: config.corsOrigin,
    methods: ["GET", "POST"],
  },
  pingInterval: 10000,
  pingTimeout: 5000,
  maxHttpBufferSize: 1e6, // 1MB payload limit
});

const gameNamespace = io.of("/game");
const roomManager = new RoomManager();

registerSocketHandlers(gameNamespace, roomManager);

server.listen(config.port, () => {
  logger.info(
    { port: config.port, protocol: config.protocolVersion },
    "Sus server listening",
  );
});

function handleShutdown(signal: string): void {
  logger.info({ signal }, "Gracefully shutting down");
  io.close(() => {
    server.close(() => {
      logger.info("Server closed successfully");
      process.exit(0);
    });
  });
}

process.on("SIGINT", () => handleShutdown("SIGINT"));
process.on("SIGTERM", () => handleShutdown("SIGTERM"));
