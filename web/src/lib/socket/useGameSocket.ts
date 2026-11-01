"use client";

import { useEffect, useState, useCallback, useRef } from "react";
import { getGameSocket } from "./socketClient";
import type { Socket } from "socket.io-client";

export interface PlayerProfile {
  id: string;
  name: string;
  color: string;
  resumeToken?: string;
}

export interface PrivateRoleInfo {
  role: "normal" | "imposter";
  word?: string;
  category: string;
}

// Global singleton state shared across all Next.js route transitions
let sharedIsConnected = false;
let sharedProfile: PlayerProfile | null = null;
let sharedRoomState: any | null = null;
let sharedPrivateRole: PrivateRoleInfo | null = null;
let sharedAccusationResult: any | null = null;
let sharedError: string | null = null;
let isSocketInitialized = false;

const stateListeners = new Set<() => void>();

function notifyStateChange() {
  stateListeners.forEach((listener) => {
    try {
      listener();
    } catch (_) {}
  });
}

function initGlobalSocketListeners(s: Socket) {
  if (isSocketInitialized) return;
  isSocketInitialized = true;

  function doHello() {
    const savedName = localStorage.getItem("sus_name") || "Sneaky Fox";
    const savedColor = localStorage.getItem("sus_color") || "#9a0f28";
    const resumeToken = localStorage.getItem("sus_resume_token") || undefined;

    s.emit(
      "session:hello",
      { name: savedName, color: savedColor, resumeToken },
      (res: any) => {
        if (res?.ok && res.data) {
          sharedProfile = {
            id: res.data.playerId,
            name: savedName,
            color: savedColor,
            resumeToken: res.data.resumeToken,
          };
          if (res.data.resumeToken) {
            localStorage.setItem("sus_resume_token", res.data.resumeToken);
          }
          if (res.data.playerId) {
            localStorage.setItem("sus_player_id", res.data.playerId);
          }
          notifyStateChange();
        }
      }
    );
  }

  s.on("connect", () => {
    sharedIsConnected = true;
    sharedError = null;
    notifyStateChange();
    doHello();
  });

  s.on("disconnect", () => {
    sharedIsConnected = false;
    notifyStateChange();
  });

  s.on("connect_error", (err: Error) => {
    console.warn("Socket connect error:", err.message);
  });

  s.on("room:state", (state: any) => {
    sharedRoomState = state;
    notifyStateChange();
  });

  s.on("game:role", (roleData: PrivateRoleInfo) => {
    sharedPrivateRole = roleData;
    notifyStateChange();
  });

  s.on("game:accusation", (result: any) => {
    sharedAccusationResult = result;
    notifyStateChange();
  });

  s.on("accuse:result", (result: any) => {
    sharedAccusationResult = result;
    notifyStateChange();
  });

  s.on("game:clue", (clue: any) => {
    if (sharedRoomState) {
      const existingClues = sharedRoomState.clues || [];
      sharedRoomState = {
        ...sharedRoomState,
        clues: [...existingClues, clue],
      };
      notifyStateChange();
    }
  });

  s.on("game:turn", (turn: any) => {
    if (sharedRoomState) {
      sharedRoomState = {
        ...sharedRoomState,
        currentTurn: turn,
      };
      notifyStateChange();
    }
  });

  s.on("game:ended", (ended: any) => {
    if (sharedRoomState) {
      sharedRoomState = {
        ...sharedRoomState,
        phase: "ended",
        ended,
      };
      notifyStateChange();
    }
  });

  s.on("game:error", (err: any) => {
    sharedError = err?.message || "An unexpected game error occurred.";
    notifyStateChange();
  });

  if (s.connected) {
    sharedIsConnected = true;
    doHello();
  } else {
    s.connect();
  }
}

export function useGameSocket() {
  const [, setTick] = useState(0);
  const socketRef = useRef<Socket | null>(null);

  useEffect(() => {
    const s = getGameSocket();
    socketRef.current = s;
    initGlobalSocketListeners(s);

    const onStateChange = () => setTick((prev) => prev + 1);
    stateListeners.add(onStateChange);

    return () => {
      stateListeners.delete(onStateChange);
    };
  }, []);

  const updateProfile = useCallback((name: string, color: string) => {
    const s = socketRef.current || getGameSocket();
    localStorage.setItem("sus_name", name);
    localStorage.setItem("sus_color", color);

    s.emit("profile:update", { name, color }, (res: any) => {
      if (res?.ok) {
        sharedProfile = {
          id: res.data.id || sharedProfile?.id || "",
          name: res.data.name,
          color: res.data.color,
          resumeToken: sharedProfile?.resumeToken,
        };
        notifyStateChange();
      }
    });
  }, []);

  const syncRoom = useCallback(async (roomId?: string): Promise<any> => {
    const s = socketRef.current || getGameSocket();
    return new Promise((resolve, reject) => {
      s.emit("room:sync", { roomId }, (res: any) => {
        if (res?.ok && res.data) {
          sharedRoomState = res.data;
          notifyStateChange();
          resolve(res.data);
        } else {
          const errMsg = res?.message || res?.error?.message || res?.code || "Failed to sync room";
          reject(new Error(errMsg));
        }
      });
    });
  }, []);

  const listRooms = useCallback(async (): Promise<any[]> => {
    const s = socketRef.current || getGameSocket();
    return new Promise((resolve) => {
      s.emit("rooms:list", {}, (res: any) => {
        if (res?.ok) resolve(res.data);
        else resolve([]);
      });
    });
  }, []);

  const createRoom = useCallback(
    async (name: string, pin: string, settings: any): Promise<any> => {
      const s = socketRef.current || getGameSocket();
      return new Promise((resolve, reject) => {
        s.emit("rooms:create", { name, pin, settings }, (res: any) => {
          if (res?.ok) {
            sharedRoomState = res.data;
            notifyStateChange();
            resolve(res.data);
          } else {
            const errMsg = res?.message || res?.error?.message || res?.code || "Failed to create room";
            reject(new Error(errMsg));
          }
        });
      });
    },
    []
  );

  const joinRoom = useCallback(async (roomId: string, pin: string): Promise<any> => {
    const s = socketRef.current || getGameSocket();
    return new Promise((resolve, reject) => {
      s.emit("rooms:join", { roomId, pin }, (res: any) => {
        if (res?.ok) {
          sharedRoomState = res.data;
          notifyStateChange();
          resolve(res.data);
        } else {
          const errMsg = res?.message || res?.error?.message || res?.code || "Failed to join room";
          reject(new Error(errMsg));
        }
      });
    });
  }, []);

  const leaveRoom = useCallback(() => {
    const s = socketRef.current || getGameSocket();
    s.emit("rooms:leave", {}, () => {
      sharedRoomState = null;
      sharedPrivateRole = null;
      sharedAccusationResult = null;
      notifyStateChange();
    });
  }, []);

  const startGame = useCallback(async () => {
    const s = socketRef.current || getGameSocket();
    return new Promise((resolve, reject) => {
      s.emit("game:start", {}, (res: any) => {
        if (res?.ok) resolve(res.data);
        else reject(new Error(res?.message || res?.error?.message || res?.code || "Failed to start game"));
      });
    });
  }, []);

  const setReady = useCallback(async () => {
    const s = socketRef.current || getGameSocket();
    return new Promise((resolve, reject) => {
      s.emit("game:ready", {}, (res: any) => {
        if (res?.ok) resolve(res.data);
        else reject(new Error(res?.message || res?.error?.message || res?.code || "Failed to mark ready"));
      });
    });
  }, []);

  const submitClue = useCallback(async (text: string) => {
    const s = socketRef.current || getGameSocket();
    return new Promise((resolve, reject) => {
      s.emit("turn:clue", { text }, (res: any) => {
        if (res?.ok) resolve(res.data);
        else reject(new Error(res?.message || res?.error?.message || res?.code || "Failed to submit clue"));
      });
    });
  }, []);

  const startAccusation = useCallback(async (targetId: string) => {
    const s = socketRef.current || getGameSocket();
    return new Promise((resolve, reject) => {
      s.emit("accuse:submit", { targetId }, (res: any) => {
        if (res?.ok) resolve(res.data);
        else reject(new Error(res?.message || res?.error?.message || res?.code || "Failed to accuse"));
      });
    });
  }, []);

  const resolveAccusation = useCallback(async () => {
    const s = socketRef.current || getGameSocket();
    s.emit("accuse:resolve", {});
  }, []);

  const submitImposterGuess = useCallback(async (word: string) => {
    const s = socketRef.current || getGameSocket();
    return new Promise((resolve, reject) => {
      s.emit("imposter:guess", { word }, (res: any) => {
        if (res?.ok) resolve(res.data);
        else reject(new Error(res?.message || res?.error?.message || res?.code || "Failed to submit guess"));
      });
    });
  }, []);

  return {
    socket: socketRef.current,
    isConnected: sharedIsConnected,
    profile: sharedProfile,
    roomState: sharedRoomState,
    privateRole: sharedPrivateRole,
    accusationResult: sharedAccusationResult,
    error: sharedError,
    clearError: () => {
      sharedError = null;
      notifyStateChange();
    },
    clearAccusationResult: () => {
      sharedAccusationResult = null;
      notifyStateChange();
    },
    updateProfile,
    syncRoom,
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
