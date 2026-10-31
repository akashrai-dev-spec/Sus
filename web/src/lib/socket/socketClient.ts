import { io, Socket } from "socket.io-client";

let socket: Socket | null = null;

export function getGameSocket(): Socket {
  if (!socket) {
    const serverUrl =
      process.env.NEXT_PUBLIC_SERVER_URL ||
      (typeof window !== "undefined"
        ? `${window.location.protocol}//${window.location.hostname}:3000`
        : "http://localhost:3000");

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
