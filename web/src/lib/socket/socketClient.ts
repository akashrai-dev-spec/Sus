import { io, Socket } from "socket.io-client";

let socket: Socket | null = null;

export function getGameSocket(): Socket {
  if (!socket) {
    let serverUrl: string;

    const customStoredUrl =
      typeof window !== "undefined"
        ? localStorage.getItem("sus_server_url")
        : null;

    const envUrl =
      process.env.NEXT_PUBLIC_SERVER_URL ||
      process.env.NEXT_PUBLIC_SOCKET_URL;

    const configuredUrl = customStoredUrl || envUrl;

    if (configuredUrl) {
      serverUrl =
        configuredUrl.startsWith("http://") || configuredUrl.startsWith("https://")
          ? configuredUrl
          : `https://${configuredUrl}`;
    } else if (typeof window !== "undefined") {
      const hostname = window.location.hostname;
      // In local dev, connect to local backend port 3000
      if (hostname === "localhost" || hostname === "127.0.0.1") {
        serverUrl = "http://localhost:3000";
      } else if (hostname.endsWith(".onrender.com")) {
        // On Render, frontend and backend are separate services; route to live server
        serverUrl = "https://sus-server-t5te.onrender.com";
      } else {
        // Unified origin (e.g. Vercel multi-service routing)
        serverUrl = window.location.origin;
      }
    } else {
      // Server-side (using Vercel service binding SERVER_URL if available)
      serverUrl = process.env.SERVER_URL || "https://sus-server-t5te.onrender.com";
    }

    // Clean any trailing slashes
    serverUrl = serverUrl.replace(/\/+$/, "");

    socket = io(`${serverUrl}/game`, {
      transports: ["websocket", "polling"],
      autoConnect: false,
      reconnectionAttempts: 10,
      reconnectionDelay: 1000,
      timeout: 10000,
    });
  }
  return socket;
}
