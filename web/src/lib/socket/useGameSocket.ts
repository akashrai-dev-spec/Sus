"use client";

import { useEffect, useState, useCallback, useRef } from "react";
import { getGameSocket } from "./socketClient";
import type { Socket } from "socket.io-client";

export interface PlayerProfile {
  id: string;
  name: string;
  color: string;
}

export interface PrivateRoleInfo {
  role: "normal" | "imposter";
  word?: string;
  category: string;
}

export function useGameSocket() {
  const [isConnected, setIsConnected] = useState(false);
  const [profile, setProfile] = useState<PlayerProfile | null>(null);
  const [roomState, setRoomState] = useState<any | null>(null);
  const [privateRole, setPrivateRole] = useState<PrivateRoleInfo | null>(null);
  const [accusationResult, setAccusationResult] = useState<any | null>(null);
  const [error, setError] = useState<string | null>(null);

  const socketRef = useRef<Socket | null>(null);

  // Initialize and connect socket
  useEffect(() => {
    const s = getGameSocket();
    socketRef.current = s;

    if (!s.connected) {
      s.connect();
    }

    function onConnect() {
      setIsConnected(true);
      setError(null);

      // Auto-hello with cached profile or defaults
      const savedName = localStorage.getItem("sus_name") || "Sneaky Fox";
      const savedColor = localStorage.getItem("sus_color") || "#9a0f28";

      s.emit(
        "session:hello",
        { name: savedName, color: savedColor },
        (res: any) => {
          if (res?.ok) {
            setProfile(res.data);
          }
        }
      );
    }

    function onDisconnect() {
      setIsConnected(false);
    }

    function onRoomState(state: any) {
      setRoomState(state);
    }

    function onGameRole(roleData: PrivateRoleInfo) {
      setPrivateRole(roleData);
    }

    function onAccuseResult(result: any) {
      setAccusationResult(result);
    }

    function onGameError(err: any) {
      setError(err?.message || "An unexpected game error occurred.");
    }

    function onConnectError(err: Error) {
      console.warn("Socket connect error:", err.message);
    }

    s.on("connect", onConnect);
    s.on("disconnect", onDisconnect);
    s.on("connect_error", onConnectError);
    s.on("room:state", onRoomState);
    s.on("game:role", onGameRole);
    s.on("accuse:result", onAccuseResult);
    s.on("game:error", onGameError);

    if (s.connected) {
      setIsConnected(true);
    }

    return () => {
      s.off("connect", onConnect);
      s.off("disconnect", onDisconnect);
      s.off("connect_error", onConnectError);
      s.off("room:state", onRoomState);
      s.off("game:role", onGameRole);
      s.off("accuse:result", onAccuseResult);
      s.off("game:error", onGameError);
    };
  }, []);

  const updateProfile = useCallback((name: string, color: string) => {
    const s = socketRef.current;
    if (!s) return;
    localStorage.setItem("sus_name", name);
    localStorage.setItem("sus_color", color);

    s.emit("profile:update", { name, color }, (res: any) => {
      if (res?.ok) {
        setProfile(res.data);
      }
    });
  }, []);

  const listRooms = useCallback(async (): Promise<any[]> => {
    const s = socketRef.current;
    if (!s) return [];
    return new Promise((resolve) => {
      s.emit("rooms:list", {}, (res: any) => {
        if (res?.ok) resolve(res.data);
        else resolve([]);
      });
    });
  }, []);

  const createRoom = useCallback(
    async (name: string, pin: string, settings: any): Promise<any> => {
      const s = socketRef.current;
      if (!s) throw new Error("Socket disconnected");
      return new Promise((resolve, reject) => {
        s.emit("rooms:create", { name, pin, settings }, (res: any) => {
          if (res?.ok) {
            setRoomState(res.data);
            resolve(res.data);
          } else {
            reject(new Error(res?.error?.message || "Failed to create room"));
          }
        });
      });
    },
    []
  );

  const joinRoom = useCallback(async (roomId: string, pin: string): Promise<any> => {
    const s = socketRef.current;
    if (!s) throw new Error("Socket disconnected");
    return new Promise((resolve, reject) => {
      s.emit("rooms:join", { roomId, pin }, (res: any) => {
        if (res?.ok) {
          setRoomState(res.data);
          resolve(res.data);
        } else {
          reject(new Error(res?.error?.message || "Failed to join room"));
        }
      });
    });
  }, []);

  const leaveRoom = useCallback(() => {
    const s = socketRef.current;
    if (!s) return;
    s.emit("rooms:leave", {}, () => {
      setRoomState(null);
      setPrivateRole(null);
      setAccusationResult(null);
    });
  }, []);

  const startGame = useCallback(async () => {
    const s = socketRef.current;
    if (!s) return;
    return new Promise((resolve, reject) => {
      s.emit("game:start", {}, (res: any) => {
        if (res?.ok) resolve(res.data);
        else reject(new Error(res?.error?.message || "Failed to start game"));
      });
    });
  }, []);

  const setReady = useCallback(async () => {
    const s = socketRef.current;
    if (!s) return;
    s.emit("game:ready", {});
  }, []);

  const submitClue = useCallback(async (text: string) => {
    const s = socketRef.current;
    if (!s) return;
    return new Promise((resolve, reject) => {
      s.emit("turn:clue", { text }, (res: any) => {
        if (res?.ok) resolve(res.data);
        else reject(new Error(res?.error?.message || "Failed to submit clue"));
      });
    });
  }, []);

  const startAccusation = useCallback(async (targetId: string) => {
    const s = socketRef.current;
    if (!s) return;
    return new Promise((resolve, reject) => {
      s.emit("accuse:submit", { targetId }, (res: any) => {
        if (res?.ok) resolve(res.data);
        else reject(new Error(res?.error?.message || "Failed to accuse"));
      });
    });
  }, []);

  const resolveAccusation = useCallback(async () => {
    const s = socketRef.current;
    if (!s) return;
    s.emit("accuse:resolve", {});
  }, []);

  const submitImposterGuess = useCallback(async (word: string) => {
    const s = socketRef.current;
    if (!s) return;
    return new Promise((resolve, reject) => {
      s.emit("imposter:guess", { word }, (res: any) => {
        if (res?.ok) resolve(res.data);
        else reject(new Error(res?.error?.message || "Failed to submit guess"));
      });
    });
  }, []);

  return {
    socket: socketRef.current,
    isConnected,
    profile,
    roomState,
    privateRole,
    accusationResult,
    error,
    clearError: () => setError(null),
    clearAccusationResult: () => setAccusationResult(null),
    updateProfile,
    listRooms,
    createRoom,
    joinRoom,
    leaveRoom,
    startGame,
    setReady,
    submitClue,
    startAccusation,
    resolveAccusation,
    submitImposterGuess,
  };
}
