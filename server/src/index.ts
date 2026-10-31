import http from "http";
import { Server } from "socket.io";
import { config } from "./config.js";
import { RoomManager } from "./rooms/roomManager.js";
import { registerSocketHandlers } from "./socket/handlers.js";
import { logger } from "./util/logger.js";

const server = http.createServer((req, res) => {
  res.setHeader("Access-Control-Allow-Origin", "*");
  res.setHeader("Access-Control-Allow-Methods", "GET, POST, OPTIONS");
  res.setHeader("Access-Control-Allow-Headers", "Content-Type");

  if (req.method === "OPTIONS") {
    res.writeHead(204);
    res.end();
    return;
  }

  if (req.url === "/health" || req.url === "/api/health") {
    res.writeHead(200, { "Content-Type": "application/json" });
    res.end(JSON.stringify({ status: "ok", version: config.protocolVersion }));
    return;
  }

  if (req.url === "/" || req.url === "") {
    res.writeHead(200, { "Content-Type": "text/html; charset=utf-8" });
    res.end(`<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Sus Multiplayer Server</title>
  <style>
    * { box-sizing: border-box; }
    body {
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
      background: #09090b;
      color: #fafafa;
      display: flex;
      align-items: center;
      justify-content: center;
      min-height: 100vh;
      margin: 0;
      padding: 1.5rem;
    }
    .card {
      background: #18181b;
      border: 1px solid #27272a;
      border-radius: 1rem;
      padding: 2.5rem;
      max-width: 480px;
      width: 100%;
      text-align: center;
      box-shadow: 0 20px 40px rgba(0,0,0,0.6);
    }
    .badge {
      display: inline-flex;
      align-items: center;
      gap: 0.5rem;
      background: rgba(34, 197, 94, 0.15);
      color: #4ade80;
      border: 1px solid rgba(34, 197, 94, 0.3);
      padding: 0.35rem 0.85rem;
      border-radius: 9999px;
      font-size: 0.875rem;
      font-weight: 600;
      margin-bottom: 1.5rem;
    }
    .dot {
      width: 8px;
      height: 8px;
      background: #22c55e;
      border-radius: 50%;
      box-shadow: 0 0 10px #22c55e;
    }
    h1 {
      font-size: 1.75rem;
      font-weight: 700;
      margin: 0 0 0.5rem 0;
      letter-spacing: -0.025em;
    }
    p {
      color: #a1a1aa;
      font-size: 0.95rem;
      line-height: 1.5;
      margin: 0 0 1.5rem 0;
    }
    .stats {
      background: #09090b;
      border: 1px solid #27272a;
      border-radius: 0.75rem;
      padding: 1rem 1.25rem;
      text-align: left;
      font-family: ui-monospace, SFMono-Regular, Menlo, monospace;
      font-size: 0.85rem;
      color: #e4e4e7;
      margin-bottom: 1.5rem;
    }
    .stat-row {
      display: flex;
      justify-content: space-between;
      padding: 0.35rem 0;
      border-bottom: 1px solid #1f1f23;
    }
    .stat-row:last-child {
      border-bottom: none;
    }
    .stat-label {
      color: #71717a;
    }
    .link {
      color: #e11d48;
      text-decoration: none;
      font-weight: 500;
    }
    .link:hover {
      text-decoration: underline;
    }
  </style>
</head>
<body>
  <div class="card">
    <div class="badge"><div class="dot"></div> Server Online & Healthy</div>
    <h1>Sus Multiplayer Server</h1>
    <p>Authoritative low-latency Socket.IO game engine for Sus.</p>
    <div class="stats">
      <div class="stat-row"><span class="stat-label">HTTP Status</span><span>200 OK</span></div>
      <div class="stat-row"><span class="stat-label">Protocol</span><span>v${config.protocolVersion}</span></div>
      <div class="stat-row"><span class="stat-label">Socket Namespace</span><span>/game</span></div>
      <div class="stat-row"><span class="stat-label">Health Endpoint</span><a class="link" href="/health">/health</a></div>
    </div>
    <p style="font-size: 0.8rem; color: #71717a; margin-bottom: 0;">Connect web clients to this origin using the Socket.IO client library.</p>
  </div>
</body>
</html>`);
    return;
  }

  res.writeHead(404, { "Content-Type": "application/json" });
  res.end(JSON.stringify({ error: "Not Found", message: "Use /health or /game namespace" }));
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
