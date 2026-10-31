import { io, Socket } from "socket.io-client";

let socket: Socket | null = null;

export function getGameSocket(): Socket {
  if (!socket) {
    let serverUrl: string;

    if (process.env.NEXT_PUBLIC_SERVER_URL) {
      serverUrl = process.env.NEXT_PUBLIC_SERVER_URL;
    } else if (typeof window !== "undefined") {
      // In standalone local dev (port 3001), connect to backend port 3000
      if (window.location.port === "3001") {
        serverUrl = `${window.location.protocol}//${window.location.hostname}:3000`;
      } else {
        // Unified origin (e.g. Vercel multi-service routing)
        serverUrl = window.location.origin;
      }
    } else {
      // Server-side (using Vercel service binding SERVER_URL if available)
      serverUrl = process.env.SERVER_URL || "http://localhost:3000";
    }

    socket = io(`${serverUrl}/game`, {
      transports: ["websocket", "polling"],
      autoConnect: false,
      reconnectionAttempts: 5,
      reconnectionDelay: 1000,
      timeout: 10000,
    });
  }
  return socket;
}
