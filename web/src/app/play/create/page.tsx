"use client";

import { useState, useEffect } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { ArrowLeft, RefreshCw, Sparkles, ChevronDown, AlertCircle } from "lucide-react";
import { useGameSocket } from "@/lib/socket/useGameSocket";
import { getCategories } from "@/lib/engine/wordBank";
import { sounds } from "@/lib/audio/soundEffects";

export default function CreateGamePage() {
  const router = useRouter();
  const { createRoom, listRooms, suggestRoomName, profile } = useGameSocket();

  const [mode, setMode] = useState<"Online" | "Local">("Online");
  const [roomName, setRoomName] = useState("Sus Party");
  const [existingRoomNames, setExistingRoomNames] = useState<string[]>([]);
  const [pin, setPin] = useState(() => Math.floor(1000 + Math.random() * 9000).toString());
  const [maxPlayers, setMaxPlayers] = useState(6);
  const [imposters, setImposters] = useState(1);
  const [rounds, setRounds] = useState(2);
  const [isCustomRounds, setIsCustomRounds] = useState(false);
  const [guessAttempts, setGuessAttempts] = useState(1);
  const [category, setCategory] = useState("Random");
  const [customWord, setCustomWord] = useState("");
  const [customCategory, setCustomCategory] = useState("");
  const [submitting, setSubmitting] = useState(false);
  const [errorMsg, setErrorMsg] = useState<string | null>(null);

  // Load existing rooms on mount to guarantee initial room name is never taken
  useEffect(() => {
    let mounted = true;
    const checkRoomAvailability = async () => {
      try {
        const rooms = await listRooms();
        if (!mounted) return;
        const names = rooms
          .map((r: any) => (r.name || "").trim().toLowerCase())
          .filter(Boolean);
        setExistingRoomNames(names);

        const base = profile?.name ? `${profile.name}'s Room` : "Sus Party";
        if (names.includes(base.toLowerCase()) || names.includes("sus party")) {
          const suggested = await suggestRoomName(base);
          if (mounted && suggested) {
            setRoomName(suggested);
          }
        } else {
          setRoomName(base);
        }
      } catch (_) {}
    };
    checkRoomAvailability();
    return () => {
      mounted = false;
    };
  }, [listRooms, suggestRoomName, profile?.name]);

  // Local player names
  const [localPlayers, setLocalPlayers] = useState<string[]>([
    "Player 1",
    "Player 2",
    "Player 3",
  ]);

  const currentPlayerCount = mode === "Online" ? maxPlayers : localPlayers.length;
  const maxAllowedImposters = Math.max(1, Math.min(3, Math.floor((currentPlayerCount - 1) / 2)));

  const handlePlayerCountChange = (newCount: number) => {
    setMaxPlayers(newCount);
    const newMaxImp = Math.max(1, Math.min(3, Math.floor((newCount - 1) / 2)));
    if (imposters > newMaxImp) {
      setImposters(newMaxImp);
    }
  };

  const addLocalPlayer = () => {
    if (localPlayers.length >= 12) return;
    const updated = [...localPlayers, `Player ${localPlayers.length + 1}`];
    setLocalPlayers(updated);
    sounds.playTick();
  };

  const removeLocalPlayer = (index: number) => {
    if (localPlayers.length <= 3) return;
    const updated = localPlayers.filter((_, i) => i !== index);
    setLocalPlayers(updated);
    const newMaxImp = Math.max(1, Math.min(3, Math.floor((updated.length - 1) / 2)));
    if (imposters > newMaxImp) {
      setImposters(newMaxImp);
    }
    sounds.playTick();
  };

  const categories = getCategories();

  const handleCreate = async (e: React.FormEvent) => {
    e.preventDefault();
    sounds.playTick();
    setSubmitting(true);
    setErrorMsg(null);

    if (category === "Custom" && !customWord.trim()) {
      setErrorMsg("Please enter a custom secret word.");
      setSubmitting(false);
      return;
    }

    if (mode === "Local") {
      // Store draft in localStorage and navigate to local game
      const localDraft = {
        players: localPlayers,
        settings: {
          imposters,
          rounds,
          guessAttempts,
          category,
          customWord: customWord.trim(),
          customCategory: customCategory.trim(),
        },
      };
      localStorage.setItem("sus_local_draft", JSON.stringify(localDraft));
      sounds.playSuccess();
      router.push("/play/local");
      return;
    }

    try {
      const room = await createRoom(roomName, pin, {
        maxPlayers,
        imposters,
        rounds,
        guessAttempts,
        category,
        customWord: customWord.trim() || undefined,
        customCategory: customCategory.trim() || undefined,
      });
      sounds.playSuccess();
      router.push(`/play/online/${room.id}`);
    } catch (err: any) {
      sounds.playFailure();
      if (err.code === "ROOM_NAME_TAKEN" || err.message?.includes("already occupied")) {
        const unique = err.suggestedName || (await suggestRoomName(roomName));
        setRoomName(unique);
        setErrorMsg(
          `"${roomName}" is already occupied. We updated it to "${unique}". Click Create Game to proceed.`
        );
      } else {
        setErrorMsg(err.message || "Failed to create room.");
      }
      setSubmitting(false);
    }
  };

  return (
    <div className="mx-auto max-w-xl w-full px-4 sm:px-6 py-10 flex-1">
      {/* Header */}
      <Link
        href="/play/mode"
        onClick={() => sounds.playTick()}
        className="inline-flex items-center gap-2 text-sm font-semibold text-mute hover:text-bone transition-colors mb-6"
      >
        <ArrowLeft className="w-4 h-4" />
        <span>Back to Modes</span>
      </Link>

      <div className="mb-6">
        <h1 className="text-3xl font-black text-white tracking-tight">Create a Game</h1>
        <p className="text-mute text-sm mt-1">Set the game rules and start deduction.</p>
      </div>

      <form onSubmit={handleCreate} className="space-y-6">
        {/* Game Mode Selector */}
        <div>
          <label className="text-xs font-bold uppercase tracking-wider text-mute block mb-2">
            Game Type
          </label>
          <div className="grid grid-cols-2 gap-2 p-1 rounded-xl bg-panel border border-line">
            {(["Online", "Local"] as const).map((m) => (
              <button
                key={m}
                type="button"
                onClick={() => {
                  sounds.playTick();
                  setMode(m);
                }}
                className={`py-2.5 rounded-lg text-sm font-bold transition-all button-press ${
                  mode === m
                    ? "bg-crimson text-white shadow-md shadow-crimson/30"
                    : "text-mute hover:text-bone"
                }`}
              >
                {m === "Online" ? "Online Multiplayer" : "Local Pass & Play"}
              </button>
            ))}
          </div>
          <p className="text-xs text-mute mt-1.5">
            {mode === "Online"
              ? "Host on the server. Friends join with the 4-digit PIN from their phones or laptops."
              : "Single device pass-and-play. Hand the screen around privately; no server required."}
          </p>
        </div>

        {/* Online-specific Fields */}
        {mode === "Online" ? (
          <>
            <div>
              <div className="flex items-center justify-between mb-2">
                <label className="text-xs font-bold uppercase tracking-wider text-mute block">
                  Room Name
                </label>
                <button
                  type="button"
                  onClick={async () => {
                    sounds.playTick();
                    const suggested = await suggestRoomName(roomName);
                    setRoomName(suggested);
                  }}
                  className="flex items-center gap-1 text-xs text-crimson-bright hover:underline font-semibold"
                >
                  <RefreshCw className="w-3 h-3" />
                  <span>Suggest Name</span>
                </button>
              </div>
              <input
                type="text"
                maxLength={25}
                value={roomName}
                onChange={(e) => {
                  setRoomName(e.target.value);
                  setErrorMsg(null);
                }}
                className={`w-full px-4 py-3 rounded-xl bg-panel border-1.5 font-medium focus:outline-none ${
                  existingRoomNames.includes(roomName.trim().toLowerCase())
                    ? "border-amber-500/60 text-amber-200"
                    : "border-line text-white focus:border-crimson"
                }`}
                placeholder="Room Name"
              />
              {existingRoomNames.includes(roomName.trim().toLowerCase()) && (
                <div className="mt-2 p-2.5 rounded-lg bg-amber-500/10 border border-amber-500/30 flex items-center justify-between text-xs text-amber-300">
                  <span className="flex items-center gap-1.5">
                    <AlertCircle className="w-3.5 h-3.5 shrink-0 text-amber-400" />
                    <span>This name is currently occupied by another room.</span>
                  </span>
                  <button
                    type="button"
                    onClick={async () => {
                      sounds.playTick();
                      const unique = await suggestRoomName(roomName);
                      setRoomName(unique);
                    }}
                    className="ml-2 font-bold underline hover:text-white shrink-0"
                  >
                    Use available name
                  </button>
                </div>
              )}
            </div>

            <div>
              <div className="flex items-center justify-between mb-2">
                <label className="text-xs font-bold uppercase tracking-wider text-mute block">
                  4-Digit PIN
                </label>
                <button
                  type="button"
                  onClick={() => {
                    sounds.playTick();
                    setPin(Math.floor(1000 + Math.random() * 9000).toString());
                  }}
                  className="flex items-center gap-1 text-xs text-crimson-bright hover:underline font-semibold"
                >
                  <RefreshCw className="w-3 h-3" />
                  <span>Randomize PIN</span>
                </button>
              </div>
              <input
                type="text"
                pattern="[0-9]*"
                maxLength={4}
                value={pin}
                onChange={(e) => setPin(e.target.value.replace(/[^0-9]/g, ""))}
                className="w-full text-center tracking-[0.5em] text-2xl font-black py-3 rounded-xl bg-panel border-1.5 border-line text-white focus:border-crimson focus:outline-none"
              />
            </div>

            <div>
              <div className="flex justify-between items-center mb-2">
                <label className="text-xs font-bold uppercase tracking-wider text-mute">
                  Max Players: <b className="text-bone">{maxPlayers}</b>
                </label>
                <span className="text-xs text-mute">(min 3, max 12)</span>
              </div>
              <input
                type="range"
                min={3}
                max={12}
                value={maxPlayers}
                onChange={(e) => handlePlayerCountChange(parseInt(e.target.value, 10))}
                className="w-full accent-crimson cursor-pointer h-2 bg-line rounded-lg"
              />
            </div>
          </>
        ) : (
          /* Local Mode Fields */
          <div>
            <label className="text-xs font-bold uppercase tracking-wider text-mute block mb-2">
              Players ({localPlayers.length} / 12)
            </label>
            <div className="space-y-2 mb-3">
              {localPlayers.map((name, idx) => (
                <div key={idx} className="flex gap-2">
                  <input
                    type="text"
                    value={name}
                    maxLength={16}
                    onChange={(e) => {
                      const updated = [...localPlayers];
                      updated[idx] = e.target.value;
                      setLocalPlayers(updated);
                    }}
                    placeholder={`Player ${idx + 1}`}
                    className="flex-1 px-4 py-2.5 rounded-xl bg-panel border-1.5 border-line text-white font-medium focus:border-crimson focus:outline-none text-sm"
                  />
                  {localPlayers.length > 3 && (
                    <button
                      type="button"
                      onClick={() => removeLocalPlayer(idx)}
                      className="px-3 rounded-xl bg-panel border border-line text-mute hover:text-white"
                    >
                      ✕
                    </button>
                  )}
                </div>
              ))}
            </div>
            {localPlayers.length < 12 && (
              <button
                type="button"
                onClick={addLocalPlayer}
                className="w-full py-2.5 rounded-xl border border-dashed border-line text-sm font-bold text-mute hover:text-bone hover:border-crimson transition-all"
              >
                + Add Player
              </button>
            )}
          </div>
        )}

        {/* Dynamic Imposter Count Selector */}
        <div>
          <label className="text-xs font-bold uppercase tracking-wider text-mute block mb-2">
            Imposters
          </label>
          <div className="flex gap-2">
            {Array.from({ length: maxAllowedImposters }, (_, i) => i + 1).map((val) => (
              <button
                key={val}
                type="button"
                onClick={() => {
                  sounds.playTick();
                  setImposters(val);
                }}
                className={`flex-1 py-3 rounded-xl text-sm font-bold border-1.5 transition-all button-press ${
                  imposters === val
                    ? "bg-crimson border-crimson text-white shadow-md shadow-crimson/30"
                    : "bg-panel border-line text-bone hover:border-white/20"
                }`}
              >
                {val}
              </button>
            ))}
          </div>
          {maxAllowedImposters < 3 && (
            <p className="text-[11px] text-mute mt-1.5">
              {maxAllowedImposters === 1
                ? `Only 1 imposter allowed for ${currentPlayerCount} players (requires 5+ players for 2)`
                : `Up to 2 imposters allowed for ${currentPlayerCount} players (requires 7+ players for 3)`}
            </p>
          )}
        </div>

        {/* Discussion Rounds with Custom Up to 10 */}
        <div>
          <label className="text-xs font-bold uppercase tracking-wider text-mute block mb-2">
            Discussion Rounds
          </label>
          <div className="grid grid-cols-4 gap-2">
            {[1, 2, 3].map((val) => (
              <button
                key={val}
                type="button"
                onClick={() => {
                  sounds.playTick();
                  setIsCustomRounds(false);
                  setRounds(val);
                }}
                className={`py-3 rounded-xl text-sm font-bold border-1.5 transition-all button-press ${
                  !isCustomRounds && rounds === val
                    ? "bg-crimson border-crimson text-white shadow-md shadow-crimson/30"
                    : "bg-panel border-line text-bone hover:border-white/20"
                }`}
              >
                {val}
              </button>
            ))}
            <button
              type="button"
              onClick={() => {
                sounds.playTick();
                setIsCustomRounds(true);
                if (rounds <= 3) setRounds(4);
              }}
              className={`py-3 rounded-xl text-sm font-bold border-1.5 transition-all button-press ${
                isCustomRounds
                  ? "bg-crimson border-crimson text-white shadow-md shadow-crimson/30"
                  : "bg-panel border-line text-bone hover:border-white/20"
              }`}
            >
              {isCustomRounds ? `Custom (${rounds})` : "Custom"}
            </button>
          </div>

          {/* Expanded custom rounds slider */}
          {isCustomRounds && (
            <div className="mt-3 p-4 rounded-xl bg-panel border-2 border-crimson animate-in fade-in duration-150">
              <div className="flex items-center justify-between mb-3">
                <span className="text-xs font-bold uppercase tracking-wider text-bone">
                  Custom Rounds
                </span>
                <span className="text-xs font-black px-2.5 py-1 rounded-md bg-crimson/30 text-crimson-bright border border-crimson">
                  {rounds} {rounds === 1 ? "round" : "rounds"}
                </span>
              </div>
              <div className="flex items-center gap-3">
                <button
                  type="button"
                  disabled={rounds <= 1}
                  onClick={() => {
                    sounds.playTick();
                    setRounds(Math.max(1, rounds - 1));
                  }}
                  className="h-8 w-8 rounded-lg bg-panel-dark border border-line font-black text-bone hover:border-crimson disabled:opacity-30 button-press"
                >
                  -
                </button>
                <input
                  type="range"
                  min={1}
                  max={10}
                  value={rounds}
                  onChange={(e) => setRounds(parseInt(e.target.value, 10))}
                  className="flex-1 accent-crimson cursor-pointer h-2 bg-line rounded-lg"
                />
                <button
                  type="button"
                  disabled={rounds >= 10}
                  onClick={() => {
                    sounds.playTick();
                    setRounds(Math.min(10, rounds + 1));
                  }}
                  className="h-8 w-8 rounded-lg bg-panel-dark border border-line font-black text-bone hover:border-crimson disabled:opacity-30 button-press"
                >
                  +
                </button>
              </div>
              <p className="text-[11px] text-mute text-center mt-2">
                Discussion rounds can be set between 1 and 10 (maximum 10).
              </p>
            </div>
          )}
        </div>

        {/* Guess Attempts */}
        <div>
          <label className="text-xs font-bold uppercase tracking-wider text-mute block mb-2">
            Guess Attempts for Imposter
          </label>
          <div className="flex gap-2">
            {[1, 2].map((val) => (
              <button
                key={val}
                type="button"
                onClick={() => {
                  sounds.playTick();
                  setGuessAttempts(val);
                }}
                className={`flex-1 py-3 rounded-xl text-sm font-bold border-1.5 transition-all button-press ${
                  guessAttempts === val
                    ? "bg-crimson border-crimson text-white shadow-md shadow-crimson/30"
                    : "bg-panel border-line text-bone hover:border-white/20"
                }`}
              >
                {val}
              </button>
            ))}
          </div>
        </div>

        {/* Secret Word Category */}
        <div>
          <label className="text-xs font-bold uppercase tracking-wider text-mute block mb-2">
            Secret Word Category
          </label>
          <div className="relative">
            <select
              value={category}
              onChange={(e) => {
                sounds.playTick();
                setCategory(e.target.value);
              }}
              className="w-full px-4 py-3 rounded-xl bg-panel border-1.5 border-line text-bone font-medium focus:border-crimson focus:outline-none appearance-none cursor-pointer"
            >
              {categories.map((c) => (
                <option key={c} value={c} className="bg-panel-dark text-bone">
                  {c === "Custom" ? "Custom (type your own secret word)" : c}
                </option>
              ))}
            </select>
            <ChevronDown className="w-5 h-5 text-mute absolute right-3.5 top-3.5 pointer-events-none" />
          </div>

          {/* Custom Word Fields */}
          {category === "Custom" && (
            <div className="mt-3 space-y-3 p-4 rounded-xl bg-panel border border-crimson/50 animate-in fade-in duration-150">
              <div>
                <label className="text-xs font-bold text-bone block mb-1">
                  Custom Secret Word *
                </label>
                <input
                  type="text"
                  maxLength={30}
                  value={customWord}
                  onChange={(e) => setCustomWord(e.target.value)}
                  placeholder="e.g. Everest, Pizza, Pikachu"
                  className="w-full px-4 py-2.5 rounded-lg bg-ink border border-line text-white font-medium focus:border-crimson focus:outline-none text-sm"
                />
              </div>
              <div>
                <label className="text-xs font-bold text-bone block mb-1">
                  Custom Category Hint (Optional)
                </label>
                <input
                  type="text"
                  maxLength={30}
                  value={customCategory}
                  onChange={(e) => setCustomCategory(e.target.value)}
                  placeholder="e.g. Mountains, Food, Characters"
                  className="w-full px-4 py-2.5 rounded-lg bg-ink border border-line text-white font-medium focus:border-crimson focus:outline-none text-sm"
                />
              </div>
            </div>
          )}
        </div>

        {/* Error Notice */}
        {errorMsg && (
          <div className="rounded-xl bg-red-950/40 border border-red-500/40 p-3 text-red-300 text-xs text-center font-bold">
            {errorMsg}
          </div>
        )}

        {/* Submit Button */}
        <button
          type="submit"
          disabled={submitting}
          className="w-full py-4 rounded-2xl bg-crimson text-white font-extrabold text-lg shadow-xl shadow-crimson/30 hover:bg-crimson-bright hover:shadow-crimson/50 transition-all button-press disabled:opacity-40"
        >
          {submitting
            ? "Creating..."
            : mode === "Online"
            ? "Create Room ›››"
            : "Start Pass & Play ›››"}
        </button>
      </form>
    </div>
  );
}
