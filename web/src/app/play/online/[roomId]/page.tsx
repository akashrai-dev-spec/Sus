"use client";

import { useEffect, useState, useRef } from "react";
import Link from "next/link";
import { useParams, useRouter } from "next/navigation";
import {
  ArrowLeft,
  Users,
  Lock,
  Eye,
  Shield,
  Send,
  RotateCcw,
  Volume2,
  VolumeX,
  AlertTriangle,
  Play,
  CheckCircle,
} from "lucide-react";
import { useGameSocket } from "@/lib/socket/useGameSocket";
import { sounds } from "@/lib/audio/soundEffects";

export default function OnlineGameRoomPage() {
  const params = useParams();
  const router = useRouter();
  const roomId = params?.roomId as string;

  const {
    isConnected,
    profile,
    roomState,
    syncRoom,
    privateRole,
    accusationResult,
    error,
    clearError,
    clearAccusationResult,
    startGame,
    setReady,
    submitClue,
    startAccusation,
    resolveAccusation,
    submitImposterGuess,
    leaveRoom,
  } = useGameSocket();

  const [clueInput, setClueInput] = useState("");
  const [submittingClue, setSubmittingClue] = useState(false);
  const [isRevealed, setIsRevealed] = useState(false);
  const [soundOn, setSoundOn] = useState(true);
  const [syncFailed, setSyncFailed] = useState(false);

  // Accusation modal
  const [accuseModalOpen, setAccuseModalOpen] = useState(false);
  const [accusedId, setAccusedId] = useState("");

  // Imposter guess modal
  const [guessModalOpen, setGuessModalOpen] = useState(false);
  const [guessWord, setGuessWord] = useState("");

  const chatBottomRef = useRef<HTMLDivElement>(null);

  // Automatic room state synchronization
  useEffect(() => {
    let timer: NodeJS.Timeout;
    if (isConnected && roomId && (!roomState || roomState.id !== roomId)) {
      syncRoom(roomId).catch((err) => {
        console.warn("Failed to sync room state:", err.message);
        if (err.message.toLowerCase().includes("not found") || err.message.toLowerCase().includes("closed")) {
          setSyncFailed(true);
        }
      });
      timer = setTimeout(() => {
        if (!roomState || roomState.id !== roomId) {
          setSyncFailed(true);
        }
      }, 5000);
    }
    return () => clearTimeout(timer);
  }, [isConnected, roomId, roomState, syncRoom]);

  useEffect(() => {
    chatBottomRef.current?.scrollIntoView({ behavior: "smooth" });
  }, [roomState?.clues?.length]);

  if (!isConnected || !roomState) {
    return (
      <div className="flex-1 flex flex-col items-center justify-center p-6 text-center">
        {!syncFailed ? (
          <>
            <div className="h-8 w-8 rounded-full border-2 border-crimson border-t-transparent animate-spin mb-4" />
            <h2 className="text-xl font-bold text-white mb-1">Connecting to Room...</h2>
            <p className="text-xs text-mute mb-6">Synchronizing game state with server.</p>
          </>
        ) : (
          <>
            <div className="h-10 w-10 rounded-full bg-crimson/20 border border-crimson/40 flex items-center justify-center text-crimson-bright font-bold mb-4">
              !
            </div>
            <h2 className="text-xl font-bold text-white mb-1">Room Not Found or Closed</h2>
            <p className="text-xs text-mute mb-6 max-w-xs">
              Unable to reach this room. It may have expired, or the PIN may be required.
            </p>
          </>
        )}
        <Link
          href="/play/rooms"
          className="text-xs font-bold text-crimson-bright hover:underline"
        >
          Return to Room Browser
        </Link>
      </div>
    );
  }

  const phaseName = roomState.phase || "lobby";
  const isPlaying = phaseName !== "lobby";

  const players = (roomState.players || []) as any[];
  const settings = (roomState.settings || {}) as any;
  const clues = (roomState.clues || []) as any[];

  const myPlayerId =
    profile?.id ||
    players.find((p: any) => p.name === profile?.name)?.id ||
    "";
  const myPlayer = players.find(
    (p: any) => (myPlayerId && p.id === myPlayerId) || p.name === profile?.name
  );
  const isHost = Boolean(
    roomState.hostId &&
      (roomState.hostId === myPlayerId ||
        roomState.hostId === profile?.id ||
        players.some((p: any) => p.id === roomState.hostId && p.name === profile?.name))
  );

  const currentTurn = roomState.currentTurn;
  const currentSpeakerId = currentTurn?.speakerId;
  const currentSpeaker = players.find((p: any) => p.id === currentSpeakerId);

  const isAlive = myPlayer ? myPlayer.isAlive !== false : true;
  const isMyTurn = Boolean(
    currentSpeakerId &&
      (currentSpeakerId === myPlayerId || (myPlayer && currentSpeakerId === myPlayer.id)) &&
      isAlive
  );

  const category = privateRole?.category || settings.category || "General";
  const secretWord = roomState.ended?.secretWord || privateRole?.word || "Secret";
  const currentRound = currentTurn?.round || 1;
  const totalRounds = settings.rounds || 2;
  const isFinalVote = Boolean(roomState.isFinalVote || phaseName === "finalVote");
  const lastAccusation = accusationResult || roomState.lastAccusation;

  const handleStartGame = async () => {
    sounds.playTick();
    try {
      await startGame();
      sounds.playSuccess();
    } catch (_) {}
  };

  const handleSendClue = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!clueInput.trim() || submittingClue) return;
    setSubmittingClue(true);
    sounds.playTick();

    try {
      await submitClue(clueInput.trim());
      setClueInput("");
    } catch (err: any) {
      sounds.playFailure();
    }
    setSubmittingClue(false);
  };

  const handleAccuse = async () => {
    if (!accusedId) return;
    sounds.playAccusationAlert();
    try {
      await startAccusation(accusedId);
      setAccuseModalOpen(false);
    } catch (_) {}
  };

  const handleGuess = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!guessWord.trim()) return;
    sounds.playTick();
    try {
      await submitImposterGuess(guessWord.trim());
      setGuessModalOpen(false);
      setGuessWord("");
    } catch (_) {}
  };

  return (
    <div className="mx-auto max-w-2xl w-full px-4 sm:px-6 py-8 flex-1 flex flex-col">
      {/* Top Header */}
      <div className="flex items-center justify-between mb-6">
        <button
          onClick={() => {
            sounds.playTick();
            leaveRoom();
            router.push("/play/rooms");
          }}
          className="inline-flex items-center gap-2 text-sm font-semibold text-mute hover:text-bone"
        >
          <ArrowLeft className="w-4 h-4" />
          <span>Leave Room</span>
        </button>

        <div className="flex items-center gap-3">
          <div className="flex items-center gap-1.5 px-3 py-1 rounded-full bg-panel border border-line text-xs font-bold text-bone">
            <Lock className="w-3.5 h-3.5 text-amber-400" />
            <span>PIN: {roomState.pin}</span>
          </div>
          <button
            onClick={() => {
              const enabled = sounds.toggleSound();
              setSoundOn(enabled);
            }}
            className="p-1.5 rounded-lg bg-panel border border-line text-mute hover:text-bone"
          >
            {soundOn ? <Volume2 className="w-4 h-4" /> : <VolumeX className="w-4 h-4" />}
          </button>
        </div>
      </div>

      {/* LOBBY VIEW (WAITING FOR PLAYERS) */}
      {!isPlaying && (
        <div className="flex-1 flex flex-col justify-between py-4">
          <div>
            <div className="text-center mb-8">
              <span className="text-xs uppercase font-extrabold tracking-widest text-crimson-bright">
                Multiplayer Lobby
              </span>
              <h1 className="text-3xl sm:text-4xl font-black text-white mt-1">
                {roomState.name}
              </h1>
              <p className="text-sm text-mute mt-1.5">
                Share the 4-digit PIN <b>{roomState.pin}</b> with friends to join.
              </p>
            </div>

            {/* Room Settings Chips */}
            <div className="flex flex-wrap items-center justify-center gap-2 mb-8">
              <span className="px-3 py-1 rounded-full bg-panel border border-line text-xs font-semibold text-mute">
                {roomState.settings?.imposters} Imposter
                {roomState.settings?.imposters > 1 ? "s" : ""}
              </span>
              <span className="px-3 py-1 rounded-full bg-panel border border-line text-xs font-semibold text-mute">
                {roomState.settings?.rounds} Discussion Rounds
              </span>
              <span className="px-3 py-1 rounded-full bg-panel border border-line text-xs font-semibold text-mute">
                Category: {roomState.settings?.category}
              </span>
            </div>

            {/* Players in Lobby */}
            <div className="space-y-2 mb-8 max-w-lg mx-auto">
              <div className="flex items-center justify-between text-xs font-bold uppercase tracking-wider text-mute px-1">
                <span>
                  Connected Players ({roomState.players?.length || 0} /{" "}
                  {roomState.settings?.maxPlayers || 6})
                </span>
                <span>{roomState.players?.length < 3 ? "Need 3 to start" : "Ready"}</span>
              </div>
              {roomState.players?.map((p: any) => {
                const isUserHost = p.id === roomState.hostId;
                const isMe = p.id === profile?.id;
                return (
                  <div
                    key={p.id}
                    className="flex items-center justify-between p-3.5 rounded-xl bg-panel border border-line"
                  >
                    <div className="flex items-center gap-3">
                      <div
                        className="h-8 w-8 rounded-full flex items-center justify-center font-extrabold text-white text-xs"
                        style={{ backgroundColor: p.color || "#9a0f28" }}
                      >
                        {p.name[0]}
                      </div>
                      <span className="font-bold text-sm text-bone">
                        {p.name} {isMe ? "(You)" : ""}
                      </span>
                    </div>
                    {isUserHost && (
                      <span className="text-[11px] px-2.5 py-0.5 rounded-full bg-crimson/30 border border-crimson text-crimson-bright font-extrabold">
                        Host
                      </span>
                    )}
                  </div>
                );
              })}
            </div>
          </div>

          <div className="pt-4 max-w-lg mx-auto w-full">
            {isHost ? (
              <button
                disabled={roomState.players?.length < 3}
                onClick={handleStartGame}
                className="w-full py-4 rounded-2xl bg-crimson hover:bg-crimson-bright text-white font-extrabold text-lg shadow-xl shadow-crimson/30 transition-all button-press disabled:opacity-40"
              >
                {roomState.players?.length < 3
                  ? `Need ${3 - roomState.players.length} More Player${
                      3 - roomState.players.length > 1 ? "s" : ""
                    } to Start`
                  : "Start Match ›››"}
              </button>
            ) : (
              <div className="rounded-xl bg-panel p-4 text-center border border-line text-sm text-mute">
                Waiting for the host (<b className="text-bone">
                  {roomState.players?.find((p: any) => p.id === roomState.hostId)?.name}
                </b>) to start the match...
              </div>
            )}
          </div>
        </div>
      )}

      {/* IN-GAME VIEW */}
      {isPlaying && (
        <div className="flex-1 flex flex-col justify-between py-2">
          {/* Phase: Role Reveal */}
          {phaseName === "roleReveal" && (
            <div className="flex-1 flex flex-col justify-between py-4 animate-in fade-in">
              <div className="text-center mb-6">
                <span className="text-xs uppercase font-extrabold tracking-widest text-crimson-bright">
                  Secret Role Assignment
                </span>
                <h2 className="text-3xl font-black text-white mt-1">Check Your Identity</h2>
                <p className="text-xs text-mute mt-1">Press and hold the card to reveal.</p>
              </div>

              {/* Hold to reveal card */}
              <div
                onMouseDown={() => {
                  sounds.playReveal();
                  setIsRevealed(true);
                }}
                onMouseUp={() => setIsRevealed(false)}
                onMouseLeave={() => setIsRevealed(false)}
                onTouchStart={() => {
                  sounds.playReveal();
                  setIsRevealed(true);
                }}
                onTouchEnd={() => setIsRevealed(false)}
                className={`w-full min-h-[260px] rounded-3xl p-8 flex flex-col items-center justify-center text-center cursor-pointer select-none transition-all duration-200 border-2 ${
                  isRevealed
                    ? privateRole?.role === "imposter"
                      ? "bg-crimson border-crimson-bright shadow-2xl shadow-crimson/50"
                      : "bg-panel-dark border-white/40 shadow-2xl"
                    : "bg-panel border-dashed border-line hover:border-crimson"
                }`}
              >
                {isRevealed ? (
                  privateRole?.role === "imposter" ? (
                    <div className="animate-in fade-in duration-100">
                      <span className="text-xs uppercase tracking-widest font-black text-white/80 block mb-1">
                        You are the
                      </span>
                      <h2 className="text-4xl font-black text-white tracking-wide mb-3">
                        IMPOSTER
                      </h2>
                      <p className="text-sm text-white/90 font-medium max-w-xs">
                        Category: <b>{category}</b>. Bluff your way through and deduce the
                        secret word!
                      </p>
                    </div>
                  ) : (
                    <div className="animate-in fade-in duration-100">
                      <span className="text-xs uppercase tracking-widest font-black text-mute block mb-1">
                        Secret Word
                      </span>
                      <h2 className="text-4xl font-black text-white tracking-wide mb-3">
                        {secretWord}
                      </h2>
                      <p className="text-sm text-mute font-medium max-w-xs">
                        Category: <b>{category}</b>. Describe it subtly without saying the
                        word!
                      </p>
                    </div>
                  )
                ) : (
                  <div className="flex flex-col items-center gap-3">
                    <div className="h-12 w-12 rounded-full bg-white/5 border border-white/10 flex items-center justify-center text-mute">
                      <Eye className="w-6 h-6" />
                    </div>
                    <span className="text-lg font-bold text-bone">
                      Press & Hold to Reveal Role
                    </span>
                    <span className="text-xs text-mute">Release to hide immediately</span>
                  </div>
                )}
              </div>

              <div className="pt-6">
                <button
                  onClick={() => {
                    sounds.playTick();
                    setReady();
                  }}
                  className="w-full py-4 rounded-2xl bg-crimson hover:bg-crimson-bright text-white font-extrabold text-lg shadow-xl shadow-crimson/30 transition-all button-press"
                >
                  I’ve seen it (Ready) ›››
                </button>
              </div>
            </div>
          )}

          {/* Phase: Discussion / Final Vote */}
          {(phaseName === "discussion" || phaseName === "finalVote" || phaseName === "accusationPending") && (
            <div className="flex-1 flex flex-col justify-between py-2">
              <div>
                {/* Round status banner */}
                <div className="rounded-2xl bg-panel p-4 border border-line mb-4 flex items-center justify-between">
                  <div>
                    <span className="text-xs uppercase font-extrabold tracking-wider text-crimson-bright block">
                      {isFinalVote
                        ? `Final Vote • Final Accusation`
                        : `Round ${currentRound} of ${totalRounds}`}
                    </span>
                    <h3 className="text-xl font-black text-white">
                      {isFinalVote ? (
                        "Time’s up. Vote to accuse!"
                      ) : (
                        <>
                          Current Speaker:{" "}
                          <span className="text-crimson-bright">
                            {currentSpeaker?.name || "Next Player"}
                            {isMyTurn ? " (You!)" : ""}
                          </span>
                        </>
                      )}
                    </h3>
                  </div>
                  <div className="text-right text-xs text-mute">
                    <span>Category</span>
                    <p className="font-bold text-bone">{category}</p>
                  </div>
                </div>

                {/* Clue Log */}
                <div className="rounded-2xl bg-ink-deep p-4 border border-line mb-4 h-56 overflow-y-auto flex flex-col gap-2.5">
                  <span className="text-[11px] font-bold uppercase tracking-wider text-mute mb-1">
                    Live Clue Log
                  </span>
                  {clues.length === 0 ? (
                    <div className="flex-1 flex items-center justify-center text-xs text-mute italic">
                      No clues given yet. Waiting for first speaker...
                    </div>
                  ) : (
                    clues.map((clue: any, idx: number) => {
                      const speaker = players.find((p: any) => p.id === clue.playerId);
                      return (
                        <div key={idx} className="flex items-start gap-2.5 text-xs">
                          <div
                            className="h-6 w-6 rounded-full flex items-center justify-center text-[10px] font-bold text-white shrink-0 mt-0.5"
                            style={{ backgroundColor: speaker?.color || "#9a0f28" }}
                          >
                            {speaker?.name?.[0] || "?"}
                          </div>
                          <div className="bg-panel px-3 py-2 rounded-xl rounded-tl-sm border border-line/60 max-w-[80%]">
                            <span className="font-bold text-bone block">{speaker?.name || "Player"}</span>
                            <p className="text-mute mt-0.5 text-sm">{clue.text}</p>
                          </div>
                        </div>
                      );
                    })
                  )}
                  <div ref={chatBottomRef} />
                </div>
              </div>

              {/* Player Turn Controls */}
              <div className="space-y-3 pt-2">
                {isMyTurn && phaseName === "discussion" ? (
                  <form onSubmit={handleSendClue} className="flex gap-2">
                    <input
                      type="text"
                      maxLength={60}
                      autoFocus
                      value={clueInput}
                      onChange={(e) => setClueInput(e.target.value)}
                      placeholder="Type your one clue (never say the word)..."
                      className="flex-1 px-4 py-3 rounded-xl bg-panel border-1.5 border-crimson text-white text-sm font-medium focus:outline-none"
                    />
                    <button
                      type="submit"
                      disabled={!clueInput.trim() || submittingClue}
                      className="px-5 py-3 rounded-xl bg-crimson hover:bg-crimson-bright text-white font-bold text-sm shadow-md button-press disabled:opacity-40"
                    >
                      <Send className="w-4 h-4" />
                    </button>
                  </form>
                ) : (
                  <div className="p-3 rounded-xl bg-panel/60 border border-line text-center text-xs text-mute">
                    {phaseName === "discussion"
                      ? `Waiting for ${
                          currentSpeaker?.name || "current speaker"
                        } to give a clue...`
                      : "Group is deciding the final accusation..."}
                  </div>
                )}

                <div className="grid grid-cols-2 gap-3">
                  <button
                    onClick={() => {
                      sounds.playTick();
                      setAccusedId("");
                      setAccuseModalOpen(true);
                    }}
                    className="py-3.5 rounded-xl bg-panel border-2 border-line hover:border-crimson text-sm font-bold text-bone hover:text-white transition-all button-press"
                  >
                    Accuse Player
                  </button>
                  {privateRole?.role === "imposter" && (
                    <button
                      onClick={() => {
                        sounds.playTick();
                        setGuessWord("");
                        setGuessModalOpen(true);
                      }}
                      className="py-3.5 rounded-xl bg-panel border-2 border-line hover:border-amber-600 text-sm font-bold text-bone hover:text-amber-300 transition-all button-press"
                    >
                      Imposter Guess
                    </button>
                  )}
                </div>
              </div>
            </div>
          )}

          {/* Phase: Ended */}
          {phaseName === "ended" && (
            <div className="flex-1 flex flex-col justify-between py-6 text-center animate-in fade-in">
              <div>
                <span
                  className={`text-xs font-black uppercase tracking-widest px-3 py-1 rounded-full border inline-block mb-3 ${
                    roomState.ended?.winner === "normal"
                      ? "bg-emerald-950/60 border-emerald-500/40 text-emerald-400"
                      : "bg-crimson/20 border-crimson text-crimson-bright"
                  }`}
                >
                  Match Finished
                </span>
                <h1 className="text-4xl font-black text-white mb-2">
                  {roomState.ended?.winner === "normal" ? "Normals Win!" : "Imposters Win!"}
                </h1>
                <p className="text-sm text-mute max-w-sm mx-auto mb-6">
                  {roomState.ended?.reason || "Game has ended."}
                </p>

                <div className="rounded-2xl bg-panel p-6 border border-line mb-6 text-center max-w-md mx-auto">
                  <span className="text-xs uppercase tracking-widest text-mute block mb-1">
                    Secret Word Was
                  </span>
                  <span className="text-3xl font-black text-white tracking-wide block mb-3">
                    {secretWord}
                  </span>
                  <span className="text-xs text-mute">
                    Category: <b className="text-bone">{category}</b>
                  </span>
                </div>

                {/* Role reveal of all players */}
                <div className="space-y-2 max-w-md mx-auto">
                  <span className="text-xs font-bold uppercase tracking-wider text-mute block text-left mb-1">
                    Player Roles
                  </span>
                  {players.map((p: any) => {
                    const isImp = p.role === "imposter";
                    return (
                      <div
                        key={p.id}
                        className="flex items-center justify-between p-3.5 rounded-xl bg-panel border border-line"
                      >
                        <div className="flex items-center gap-3">
                          <div
                            className="h-8 w-8 rounded-full flex items-center justify-center font-bold text-white text-xs"
                            style={{ backgroundColor: p.color || "#9a0f28" }}
                          >
                            {p.name?.[0]}
                          </div>
                          <span className="font-bold text-sm text-bone">{p.name}</span>
                        </div>
                        <span
                          className={`text-xs px-2.5 py-1 rounded-full font-black ${
                            isImp
                              ? "bg-crimson text-white border border-crimson-bright"
                              : "bg-white/10 text-mute"
                          }`}
                        >
                          {isImp ? "Imposter" : "Normal"}
                        </span>
                      </div>
                    );
                  })}
                </div>
              </div>

              <div className="pt-6 max-w-md mx-auto w-full">
                {isHost && (
                  <button
                    onClick={handleStartGame}
                    className="w-full py-4 rounded-2xl bg-crimson hover:bg-crimson-bright text-white font-extrabold text-lg shadow-xl shadow-crimson/30 transition-all button-press flex items-center justify-center gap-2"
                  >
                    <RotateCcw className="w-5 h-5" />
                    <span>Play Again ›››</span>
                  </button>
                )}
              </div>
            </div>
          )}
        </div>
      )}

      {/* ACCUSATION MODAL */}
      {accuseModalOpen && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/80 backdrop-blur-sm p-4">
          <div className="w-full max-w-md rounded-2xl bg-panel-dark p-6 border-2 border-crimson shadow-2xl animate-in fade-in duration-150">
            <h3 className="text-xl font-bold text-white mb-1">Accuse an Imposter</h3>
            <p className="text-xs text-mute mb-5">
              Select the player you suspect of being the imposter.
            </p>

            <div className="space-y-2 mb-6">
              {players
                .filter((p: any) => p.isAlive !== false && p.id !== myPlayerId)
                .map((p: any) => (
                  <button
                    key={p.id}
                    type="button"
                    onClick={() => {
                      sounds.playTick();
                      setAccusedId(p.id);
                    }}
                    className={`w-full flex items-center justify-between p-3 rounded-xl border-1.5 transition-all button-press ${
                      accusedId === p.id
                        ? "bg-crimson/30 border-crimson text-white font-bold"
                        : "bg-panel border-line text-bone hover:border-white/20"
                    }`}
                  >
                    <span>{p.name}</span>
                    {accusedId === p.id && <CheckCircle className="w-4 h-4 text-crimson-bright" />}
                  </button>
                ))}
            </div>

            <div className="flex gap-3">
              <button
                type="button"
                onClick={() => setAccuseModalOpen(false)}
                className="flex-1 py-3 rounded-xl bg-panel border border-line text-sm font-bold text-mute hover:text-bone"
              >
                Cancel
              </button>
              <button
                type="button"
                disabled={!accusedId}
                onClick={handleAccuse}
                className="flex-1 py-3 rounded-xl bg-crimson text-sm font-bold text-white hover:bg-crimson-bright disabled:opacity-40 button-press shadow-md shadow-crimson/30"
              >
                Confirm Accusation
              </button>
            </div>
          </div>
        </div>
      )}

      {/* ACCUSATION RESULT POPUP */}
      {lastAccusation && !lastAccusation.isGameOver && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/80 backdrop-blur-sm p-4">
          <div className="w-full max-w-md rounded-2xl bg-panel-dark p-6 border-2 border-crimson shadow-2xl text-center animate-in fade-in zoom-in-95 duration-150">
            <span className="text-xs uppercase font-extrabold tracking-widest text-mute block mb-2">
              Role Revealed
            </span>
            <h3 className="text-2xl font-black text-white mb-2">
              {players.find((p: any) => p.id === (lastAccusation.accusedId || lastAccusation.targetId))?.name || "Player"}
            </h3>
            <div
              className={`p-4 rounded-xl my-4 text-xl font-black tracking-wider ${
                lastAccusation.isImposter || lastAccusation.outcome === "caught"
                  ? "bg-crimson/30 text-crimson-bright border border-crimson"
                  : "bg-white/10 text-bone border border-line"
              }`}
            >
              {lastAccusation.isImposter || lastAccusation.outcome === "caught"
                ? "IMPOSTER! (Eliminated)"
                : "NORMAL PLAYER (Innocent!)"}
            </div>
            <button
              onClick={() => {
                sounds.playTick();
                clearAccusationResult();
              }}
              className="w-full py-3.5 rounded-xl bg-crimson hover:bg-crimson-bright text-white font-bold button-press"
            >
              Continue
            </button>
          </div>
        </div>
      )}

      {/* IMPOSTER GUESS MODAL */}
      {guessModalOpen && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/80 backdrop-blur-sm p-4">
          <form
            onSubmit={handleGuess}
            className="w-full max-w-md rounded-2xl bg-panel-dark p-6 border-2 border-amber-600 shadow-2xl animate-in fade-in duration-150"
          >
            <h3 className="text-xl font-bold text-white mb-1">Guess the Secret Word</h3>
            <p className="text-xs text-mute mb-4">
              Category: <b className="text-bone">{category}</b>. Guess correctly to win
              instantly!
            </p>

            <input
              type="text"
              maxLength={30}
              autoFocus
              value={guessWord}
              onChange={(e) => setGuessWord(e.target.value)}
              placeholder="Enter secret word..."
              className="w-full px-4 py-3 rounded-xl bg-ink border border-line text-white font-bold focus:border-amber-600 focus:outline-none text-base mb-6"
            />

            <div className="flex gap-3">
              <button
                type="button"
                onClick={() => setGuessModalOpen(false)}
                className="flex-1 py-3 rounded-xl bg-panel border border-line text-sm font-bold text-mute hover:text-bone"
              >
                Cancel
              </button>
              <button
                type="submit"
                disabled={!guessWord.trim()}
                className="flex-1 py-3 rounded-xl bg-amber-600 text-sm font-bold text-white hover:bg-amber-500 disabled:opacity-40 button-press shadow-md"
              >
                Submit Guess
              </button>
            </div>
          </form>
        </div>
      )}
    </div>
  );
}
