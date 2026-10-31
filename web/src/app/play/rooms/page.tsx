"use client";

import { useEffect, useState, useCallback } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { ArrowLeft, Lock, Plus, Users, RefreshCw, AlertCircle } from "lucide-react";
import { useGameSocket } from "@/lib/socket/useGameSocket";
import { sounds } from "@/lib/audio/soundEffects";

interface RoomSummary {
  id: string;
  name: string;
  playerCount: number;
  maxPlayers: number;
  hasPin: boolean;
}

export default function RoomsPage() {
  const router = useRouter();
  const { isConnected, listRooms, joinRoom, error, clearError } = useGameSocket();

  const [rooms, setRooms] = useState<RoomSummary[]>([]);
  const [loading, setLoading] = useState(true);
  const [selectedRoom, setSelectedRoom] = useState<RoomSummary | null>(null);
  const [pin, setPin] = useState("");
  const [joining, setJoining] = useState(false);
  const [joinError, setJoinError] = useState<string | null>(null);

  const fetchRooms = useCallback(async () => {
    setLoading(true);
    try {
      const data = await listRooms();
      setRooms(data);
    } catch (_) {}
    setLoading(false);
  }, [listRooms]);

  useEffect(() => {
    if (isConnected) {
      fetchRooms();
    }
  }, [isConnected, fetchRooms]);

  const handleJoin = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!selectedRoom || pin.length !== 4) return;

    setJoining(true);
    setJoinError(null);
    sounds.playTick();

    try {
      await joinRoom(selectedRoom.id, pin);
      sounds.playSuccess();
      router.push(`/play/online/${selectedRoom.id}`);
    } catch (err: any) {
      sounds.playFailure();
      setJoinError(err.message || "Invalid PIN or room is full.");
      setJoining(false);
    }
  };

  return (
    <div className="mx-auto max-w-2xl w-full px-4 sm:px-6 py-10 flex-1">
      {/* Header */}
      <div className="flex items-center justify-between mb-8">
        <Link
          href="/play/mode"
          onClick={() => sounds.playTick()}
          className="inline-flex items-center gap-2 text-sm font-semibold text-mute hover:text-bone transition-colors"
        >
          <ArrowLeft className="w-4 h-4" />
          <span>Back</span>
        </Link>
        <div className="flex items-center gap-3">
          <button
            onClick={() => {
              sounds.playTick();
              fetchRooms();
            }}
            className="flex items-center gap-1.5 text-xs text-mute hover:text-bone px-3 py-1.5 rounded-lg bg-panel border border-line button-press"
          >
            <RefreshCw className={`w-3.5 h-3.5 ${loading ? "animate-spin" : ""}`} />
            <span>Refresh</span>
          </button>
          <Link
            href="/play/create"
            onClick={() => sounds.playTick()}
            className="flex items-center gap-1.5 text-xs font-bold text-white bg-crimson hover:bg-crimson-bright px-3.5 py-1.5 rounded-lg button-press shadow-sm shadow-crimson/30"
          >
            <Plus className="w-3.5 h-3.5" />
            <span>Create Room</span>
          </Link>
        </div>
      </div>

      <div className="mb-6">
        <h1 className="text-3xl font-extrabold text-white tracking-tight">Open Rooms</h1>
        <p className="text-mute text-sm mt-1">
          Every game is secured with a 4-digit PIN. Select a room to enter.
        </p>
      </div>

      {/* Connection notice if server offline */}
      {!isConnected && (
        <div className="rounded-xl bg-amber-950/40 border border-amber-600/40 p-4 mb-6 flex items-start gap-3 text-amber-200 text-sm">
          <AlertCircle className="w-5 h-5 text-amber-400 shrink-0 mt-0.5" />
          <div>
            <p className="font-bold">Connecting to game server...</p>
            <p className="text-xs text-amber-300/80 mt-0.5">
              Ensure the server is running on port 3000 or hosted on Render. You can also play
              offline via Local Pass & Play.
            </p>
          </div>
        </div>
      )}

      {/* Room list */}
      <div className="space-y-3">
        {loading ? (
          <div className="text-center py-12 text-mute text-sm">
            <RefreshCw className="w-6 h-6 animate-spin mx-auto mb-2 text-crimson" />
            Loading live rooms...
          </div>
        ) : rooms.length === 0 ? (
          <div className="rounded-2xl bg-panel/60 border border-line p-10 text-center">
            <Users className="w-10 h-10 text-mute mx-auto mb-3 opacity-40" />
            <h3 className="font-bold text-bone text-lg mb-1">No open rooms right now</h3>
            <p className="text-mute text-sm max-w-sm mx-auto mb-6">
              Be the first to host! Create a room and share your 4-digit PIN with friends.
            </p>
            <Link
              href="/play/create"
              onClick={() => sounds.playTick()}
              className="inline-flex items-center gap-2 rounded-xl bg-crimson px-5 py-2.5 text-sm font-bold text-white hover:bg-crimson-bright transition-all button-press"
            >
              <Plus className="w-4 h-4" />
              <span>Create New Room</span>
            </Link>
          </div>
        ) : (
          rooms.map((room) => {
            const isFull = room.playerCount >= room.maxPlayers;
            return (
              <button
                key={room.id}
                disabled={isFull}
                onClick={() => {
                  sounds.playTick();
                  setSelectedRoom(room);
                  setPin("");
                  setJoinError(null);
                }}
                className={`w-full flex items-center justify-between p-4 rounded-xl bg-panel border-1.5 transition-all text-left ${
                  isFull
                    ? "opacity-50 border-line cursor-not-allowed"
                    : "border-line hover:border-crimson hover:bg-panel-dark button-press"
                }`}
              >
                <div className="flex items-center gap-3.5">
                  <div className="h-10 w-10 rounded-lg bg-white/5 border border-white/10 flex items-center justify-center text-amber-400">
                    <Lock className="w-4 h-4" />
                  </div>
                  <div>
                    <h4 className="font-bold text-bone text-base">{room.name}</h4>
                    <span className="text-xs text-mute">Requires 4-digit PIN</span>
                  </div>
                </div>
                <div className="flex items-center gap-2">
                  <span
                    className={`text-xs px-2.5 py-1 rounded-full font-bold ${
                      isFull
                        ? "bg-red-950 text-red-400 border border-red-800/40"
                        : "bg-white/10 text-bone"
                    }`}
                  >
                    {room.playerCount} / {room.maxPlayers} {isFull ? "Full" : ""}
                  </span>
                </div>
              </button>
            );
          })
        )}
      </div>

      {/* PIN Unlock Modal */}
      {selectedRoom && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/80 backdrop-blur-sm p-4">
          <div className="w-full max-w-sm rounded-2xl bg-panel-dark p-6 border-2 border-crimson shadow-2xl animate-in fade-in zoom-in-95 duration-150">
            <h3 className="text-xl font-bold text-white mb-1">Enter Room PIN</h3>
            <p className="text-xs text-mute mb-5">
              Enter the 4-digit PIN for <b className="text-bone">{selectedRoom.name}</b>
            </p>

            <form onSubmit={handleJoin} className="space-y-4">
              <input
                type="text"
                pattern="[0-9]*"
                inputMode="numeric"
                maxLength={4}
                autoFocus
                placeholder="0000"
                value={pin}
                onChange={(e) => setPin(e.target.value.replace(/[^0-9]/g, ""))}
                className="w-full text-center tracking-[0.5em] text-3xl font-extrabold py-3 rounded-xl bg-ink border-2 border-line text-white focus:border-crimson focus:outline-none"
              />

              {joinError && (
                <p className="text-xs text-red-400 text-center font-semibold">{joinError}</p>
              )}

              <div className="flex gap-2.5 pt-2">
                <button
                  type="button"
                  onClick={() => {
                    sounds.playTick();
                    setSelectedRoom(null);
                  }}
                  className="flex-1 py-3 rounded-xl bg-panel border border-line text-sm font-bold text-mute hover:text-bone button-press"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  disabled={pin.length !== 4 || joining}
                  className="flex-1 py-3 rounded-xl bg-crimson text-sm font-bold text-white hover:bg-crimson-bright transition-all disabled:opacity-40 button-press shadow-md shadow-crimson/30"
                >
                  {joining ? "Joining..." : "Enter Room"}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
