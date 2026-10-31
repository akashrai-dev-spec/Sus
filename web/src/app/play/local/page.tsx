"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import {
  ArrowLeft,
  Eye,
  EyeOff,
  Shield,
  Volume2,
  VolumeX,
  Play,
  CheckCircle,
  AlertTriangle,
  RotateCcw,
  Sparkles,
} from "lucide-react";
import { WebGameEngine } from "@/lib/engine/gameEngine";
import { pickSecretWord } from "@/lib/engine/wordBank";
import { GamePlayer, GameState } from "@/lib/engine/types";
import { sounds } from "@/lib/audio/soundEffects";

const PLAYER_COLORS = [
  "#9a0f28",
  "#c2410c",
  "#a16207",
  "#4d7c0f",
  "#0f766e",
  "#1d4ed8",
  "#6d28d9",
  "#be185d",
];

export default function LocalGamePage() {
  const router = useRouter();

  const [gameState, setGameState] = useState<GameState | null>(null);
  const [handoverIndex, setHandoverIndex] = useState(0);
  const [isRevealed, setIsRevealed] = useState(false);
  const [soundOn, setSoundOn] = useState(true);

  // Accusation modal state
  const [accuseModalOpen, setAccuseModalOpen] = useState(false);
  const [accuserId, setAccuserId] = useState<string>("");
  const [accusedId, setAccusedId] = useState<string>("");
  const [accuseResult, setAccuseResult] = useState<any | null>(null);

  // Imposter guess modal state
  const [guessModalOpen, setGuessModalOpen] = useState(false);
  const [guessPlayerId, setGuessPlayerId] = useState<string>("");
  const [guessWord, setGuessWord] = useState<string>("");

  // Start or reset game
  const initializeGame = (draftData?: any) => {
    let playersList = ["Player 1", "Player 2", "Player 3", "Player 4"];
    let settings = {
      maxPlayers: 4,
      imposters: 1,
      rounds: 2,
      guessAttempts: 1,
      category: "Random",
    };

    if (draftData) {
      if (draftData.players && draftData.players.length >= 3) {
        playersList = draftData.players;
      }
      if (draftData.settings) {
        settings = { ...settings, ...draftData.settings };
      }
    }

    const { category, word } = pickSecretWord(
      settings.category,
      (settings as any).customWord,
      (settings as any).customCategory
    );

    const players: Array<Omit<GamePlayer, "role">> = playersList.map((name, i) => ({
      id: `p-${i + 1}`,
      name,
      color: PLAYER_COLORS[i % PLAYER_COLORS.length],
      isAlive: true,
      isHost: i === 0,
      usedAccusation: false,
      remainingGuesses: settings.guessAttempts,
      isReady: false,
    }));

    const state = WebGameEngine.startGame({
      players,
      settings,
      secretWord: word,
      category,
    });

    setGameState(state);
    setHandoverIndex(0);
    setIsRevealed(false);
    setAccuseResult(null);
    setAccuseModalOpen(false);
    setGuessModalOpen(false);
  };

  useEffect(() => {
    const rawDraft = localStorage.getItem("sus_local_draft");
    let draft = null;
    if (rawDraft) {
      try {
        draft = JSON.parse(rawDraft);
      } catch (_) {}
    }
    initializeGame(draft);
  }, []);

  if (!gameState) {
    return (
      <div className="flex-1 flex items-center justify-center p-8 text-mute">
        Loading local pass & play match...
      </div>
    );
  }

  const phase = gameState.currentPhase;
  const isHandover = phase.name === "roleReveal";
  const currentPlayer = gameState.players[handoverIndex];

  // Handover action
  const handleHandoverNext = () => {
    sounds.playTick();
    if (handoverIndex + 1 < gameState.players.length) {
      setHandoverIndex(handoverIndex + 1);
      setIsRevealed(false);
    } else {
      // All have seen their cards -> begin discussion
      const firstSpeaker = gameState.speakingOrder[0];
      setGameState({
        ...gameState,
        currentPhase: {
          name: "discussion",
          round: 1,
          currentSpeakerId: firstSpeaker,
          turnIndex: 0,
        },
      });
      sounds.playSuccess();
    }
  };

  // Next speaker
  const handleNextSpeaker = () => {
    if (phase.name !== "discussion") return;
    sounds.playTick();
    const nextState = WebGameEngine.advanceTurn(gameState, phase.turnIndex + 1);
    setGameState(nextState);
  };

  // Perform accusation
  const handleExecuteAccusation = () => {
    if (!accusedId) return;
    sounds.playAccusationAlert();

    const target = gameState.players.find((p) => p.id === accusedId)!;
    const isHit = target.role === "imposter";

    if (phase.name === "finalVote") {
      // Final vote accusation
      const withAccused: GameState = {
        ...gameState,
        currentPhase: {
          name: "finalVote",
          voteRound: phase.voteRound || 1,
          accusedPlayerId: accusedId,
        },
      };
      const { state: nextState, result } = WebGameEngine.resolveAccusation(withAccused);
      setGameState(nextState);
      setAccuseResult(result);
      setAccuseModalOpen(false);
      if (result.isGameOver) {
        if (result.winner === "normal") sounds.playSuccess();
        else sounds.playFailure();
      }
      return;
    }

    // Normal discussion accusation
    const actingAccuser =
      accuserId || (phase.name === "discussion" ? phase.currentSpeakerId : gameState.players[0].id);
    const withAccuse = WebGameEngine.startAccusation(gameState, {
      accuserId: actingAccuser,
      targetId: accusedId,
    });
    const { state: nextState, result } = WebGameEngine.resolveAccusation(withAccuse);
    setGameState(nextState);
    setAccuseResult(result);
    setAccuseModalOpen(false);

    if (result.isGameOver) {
      sounds.playSuccess();
    } else if (isHit) {
      sounds.playSuccess();
    } else {
      sounds.playFailure();
    }
  };

  // Imposter secret word guess
  const handleExecuteGuess = () => {
    if (!guessPlayerId || !guessWord.trim()) return;
    sounds.playTick();
    const nextState = WebGameEngine.imposterGuess(gameState, {
      playerId: guessPlayerId,
      word: guessWord.trim(),
    });
    setGameState(nextState);
    setGuessModalOpen(false);
    setGuessWord("");

    if (nextState.currentPhase.name === "ended") {
      sounds.playSuccess();
    } else {
      sounds.playFailure();
    }
  };

  return (
    <div className="mx-auto max-w-xl w-full px-4 sm:px-6 py-8 flex-1 flex flex-col">
      {/* Top Bar */}
      <div className="flex items-center justify-between mb-6">
        <Link
          href="/play/mode"
          onClick={() => sounds.playTick()}
          className="inline-flex items-center gap-2 text-sm font-semibold text-mute hover:text-bone"
        >
          <ArrowLeft className="w-4 h-4" />
          <span>Exit Game</span>
        </Link>
        <div className="flex items-center gap-2">
          <button
            onClick={() => {
              const enabled = sounds.toggleSound();
              setSoundOn(enabled);
            }}
            className="p-2 rounded-lg bg-panel border border-line text-mute hover:text-bone"
          >
            {soundOn ? <Volume2 className="w-4 h-4" /> : <VolumeX className="w-4 h-4" />}
          </button>
        </div>
      </div>

      {/* PHASE 1: ROLE REVEAL HANDOVER */}
      {isHandover && currentPlayer && (
        <div className="flex-1 flex flex-col justify-between py-4">
          <div>
            <div className="text-center mb-6">
              <span className="text-xs uppercase font-extrabold tracking-widest text-crimson-bright">
                Private Handover • Player {handoverIndex + 1} of {gameState.players.length}
              </span>
              <h1 className="text-3xl font-black text-white mt-1">
                Pass phone to <span className="text-crimson-bright">{currentPlayer.name}</span>
              </h1>
              <p className="text-xs text-mute mt-1">
                Make sure no one else is peeking at the screen.
              </p>
            </div>

            {/* Secret Hold to Reveal Card */}
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
                  ? currentPlayer.role === "imposter"
                    ? "bg-crimson border-crimson-bright shadow-2xl shadow-crimson/50"
                    : "bg-panel-dark border-white/40 shadow-2xl"
                  : "bg-panel border-dashed border-line hover:border-crimson"
              }`}
            >
              {isRevealed ? (
                currentPlayer.role === "imposter" ? (
                  <div className="animate-in fade-in duration-100">
                    <span className="text-xs uppercase tracking-widest font-black text-white/80 block mb-1">
                      You are the
                    </span>
                    <h2 className="text-4xl font-black text-white tracking-wide mb-3">IMPOSTER</h2>
                    <p className="text-sm text-white/90 font-medium max-w-xs">
                      Category: <b>{gameState.category}</b>. Bluff your way through the clues and
                      deduce the secret word!
                    </p>
                  </div>
                ) : (
                  <div className="animate-in fade-in duration-100">
                    <span className="text-xs uppercase tracking-widest font-black text-mute block mb-1">
                      Secret Word
                    </span>
                    <h2 className="text-4xl font-black text-white tracking-wide mb-3">
                      {gameState.secretWord}
                    </h2>
                    <p className="text-sm text-mute font-medium max-w-xs">
                      Category: <b>{gameState.category}</b>. Describe it subtly, but never say the
                      word!
                    </p>
                  </div>
                )
              ) : (
                <div className="flex flex-col items-center gap-3">
                  <div className="h-12 w-12 rounded-full bg-white/5 border border-white/10 flex items-center justify-center text-mute">
                    <Eye className="w-6 h-6" />
                  </div>
                  <span className="text-lg font-bold text-bone">Press & Hold to Reveal Role</span>
                  <span className="text-xs text-mute">Release to hide immediately</span>
                </div>
              )}
            </div>
          </div>

          <div className="pt-6">
            <button
              onClick={handleHandoverNext}
              className="w-full py-4 rounded-2xl bg-crimson hover:bg-crimson-bright text-white font-extrabold text-lg shadow-xl shadow-crimson/30 transition-all button-press"
            >
              {handoverIndex + 1 < gameState.players.length ? "I’ve seen it (Pass device) ›››" : "Everyone is ready! Start game ›››"}
            </button>
          </div>
        </div>
      )}

      {/* PHASE 2 & 3: DISCUSSION / FINAL VOTE */}
      {(phase.name === "discussion" || phase.name === "finalVote") && (
        <div className="flex-1 flex flex-col justify-between py-2">
          <div>
            {/* Status Header */}
            <div className="rounded-2xl bg-panel p-5 border border-line mb-6 flex items-center justify-between">
              <div>
                <span className="text-xs uppercase font-extrabold tracking-wider text-crimson-bright block">
                  {phase.name === "finalVote"
                    ? `Final Accusation • Round ${phase.voteRound || 1}`
                    : `Round ${phase.round} of ${gameState.settings.rounds}`}
                </span>
                <h2 className="text-2xl font-black text-white mt-0.5">
                  {phase.name === "finalVote" ? (
                    "Time’s up. Vote to accuse!"
                  ) : (
                    <>
                      Speaker:{" "}
                      <span className="text-crimson-bright">
                        {gameState.players.find((p) => p.id === phase.currentSpeakerId)?.name}
                      </span>
                    </>
                  )}
                </h2>
              </div>
              <div className="text-right text-xs text-mute">
                <span>Category</span>
                <p className="font-bold text-bone text-sm">{gameState.category}</p>
              </div>
            </div>

            {/* Speaking Turn Order Roster */}
            <div className="space-y-2 mb-6">
              <span className="text-xs font-bold uppercase tracking-wider text-mute block mb-1">
                Turn Order
              </span>
              {gameState.speakingOrder.map((id, idx) => {
                const p = gameState.players.find((pl) => pl.id === id)!;
                const isCurrent = phase.name === "discussion" && phase.currentSpeakerId === id;
                return (
                  <div
                    key={id}
                    className={`flex items-center justify-between p-3.5 rounded-xl border-1.5 transition-all ${
                      !p.isAlive
                        ? "opacity-30 bg-ink-deep border-line line-through"
                        : isCurrent
                        ? "bg-panel-dark border-crimson shadow-md shadow-crimson/20"
                        : "bg-panel border-line"
                    }`}
                  >
                    <div className="flex items-center gap-3">
                      <div
                        className="h-8 w-8 rounded-full flex items-center justify-center font-extrabold text-white text-xs"
                        style={{ backgroundColor: p.color }}
                      >
                        {p.name[0]}
                      </div>
                      <span className="font-bold text-sm text-bone">{p.name}</span>
                    </div>
                    <div>
                      {isCurrent && (
                        <span className="text-xs px-2.5 py-1 rounded-full bg-crimson text-white font-extrabold animate-pulse">
                          Speaking Now
                        </span>
                      )}
                      {!p.isAlive && (
                        <span className="text-xs text-mute font-bold">Eliminated</span>
                      )}
                    </div>
                  </div>
                );
              })}
            </div>
          </div>

          {/* Action Buttons */}
          <div className="space-y-3 pt-4 border-t border-line/60">
            {phase.name === "discussion" && (
              <button
                onClick={handleNextSpeaker}
                className="w-full py-4 rounded-xl bg-crimson hover:bg-crimson-bright text-white font-extrabold text-base shadow-lg shadow-crimson/30 transition-all button-press"
              >
                Next Speaker ›››
              </button>
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
                {phase.name === "finalVote" ? "Final Accusation" : "Accuse Player"}
              </button>
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
            </div>
          </div>
        </div>
      )}

      {/* PHASE 4: GAME ENDED */}
      {phase.name === "ended" && (
        <div className="flex-1 flex flex-col justify-between py-6 animate-in fade-in duration-200">
          <div className="text-center">
            <span
              className={`text-xs font-black uppercase tracking-widest px-3 py-1 rounded-full border inline-block mb-3 ${
                phase.winner === "normal"
                  ? "bg-emerald-950/60 border-emerald-500/40 text-emerald-400"
                  : "bg-crimson/20 border-crimson text-crimson-bright"
              }`}
            >
              Match Complete
            </span>
            <h1 className="text-4xl font-black text-white mb-2">
              {phase.winner === "normal" ? "Normals Win!" : "Imposters Win!"}
            </h1>
            <p className="text-sm text-mute max-w-sm mx-auto mb-6">{phase.reason}</p>

            <div className="rounded-2xl bg-panel p-6 border border-line mb-6 text-center max-w-md mx-auto">
              <span className="text-xs uppercase tracking-widest text-mute block mb-1">
                The Secret Word Was
              </span>
              <span className="text-3xl font-black text-white tracking-wide block mb-3">
                {gameState.secretWord}
              </span>
              <span className="text-xs text-mute">
                Category: <b className="text-bone">{gameState.category}</b>
              </span>
            </div>

            {/* Reveal all roles */}
            <div className="space-y-2 max-w-md mx-auto">
              <span className="text-xs font-bold uppercase tracking-wider text-mute block text-left mb-1">
                All Players & Roles
              </span>
              {gameState.players.map((p) => {
                const isImp = p.role === "imposter";
                return (
                  <div
                    key={p.id}
                    className="flex items-center justify-between p-3.5 rounded-xl bg-panel border border-line"
                  >
                    <div className="flex items-center gap-3">
                      <div
                        className="h-8 w-8 rounded-full flex items-center justify-center font-bold text-white text-xs"
                        style={{ backgroundColor: p.color }}
                      >
                        {p.name[0]}
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

          <div className="space-y-3 pt-6 max-w-md mx-auto w-full">
            <button
              onClick={() => {
                sounds.playSuccess();
                initializeGame({
                  players: gameState.players.map((p) => p.name),
                  settings: gameState.settings,
                });
              }}
              className="w-full py-4 rounded-2xl bg-crimson hover:bg-crimson-bright text-white font-extrabold text-lg shadow-xl shadow-crimson/30 transition-all button-press flex items-center justify-center gap-2"
            >
              <RotateCcw className="w-5 h-5" />
              <span>Play Again ›››</span>
            </button>
            <Link
              href="/"
              onClick={() => sounds.playTick()}
              className="block w-full py-3.5 rounded-xl bg-panel border border-line text-sm font-bold text-center text-mute hover:text-bone button-press"
            >
              Back to Home
            </Link>
          </div>
        </div>
      )}

      {/* ACCUSATION MODAL */}
      {accuseModalOpen && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/80 backdrop-blur-sm p-4">
          <div className="w-full max-w-md rounded-2xl bg-panel-dark p-6 border-2 border-crimson shadow-2xl animate-in fade-in duration-150">
            <h3 className="text-xl font-bold text-white mb-1">Make an Accusation</h3>
            <p className="text-xs text-mute mb-5">
              Select the player you suspect of being the imposter.
            </p>

            <div className="space-y-2 mb-6">
              {gameState.players
                .filter((p) => p.isAlive)
                .map((p) => (
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
                onClick={handleExecuteAccusation}
                className="flex-1 py-3 rounded-xl bg-crimson text-sm font-bold text-white hover:bg-crimson-bright disabled:opacity-40 button-press shadow-md shadow-crimson/30"
              >
                Confirm Accuse
              </button>
            </div>
          </div>
        </div>
      )}

      {/* ACCUSATION RESULT REVEAL MODAL */}
      {accuseResult && !accuseResult.isGameOver && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/80 backdrop-blur-sm p-4">
          <div className="w-full max-w-md rounded-2xl bg-panel-dark p-6 border-2 border-crimson shadow-2xl text-center animate-in fade-in zoom-in-95 duration-150">
            <span className="text-xs uppercase font-extrabold tracking-widest text-mute block mb-2">
              Accusation Result
            </span>
            <h3 className="text-2xl font-black text-white mb-2">
              {gameState.players.find((p) => p.id === accuseResult.accusedId)?.name} was revealed!
            </h3>
            <div
              className={`p-4 rounded-xl my-4 text-xl font-black tracking-wider ${
                accuseResult.isImposter
                  ? "bg-crimson/30 text-crimson-bright border border-crimson"
                  : "bg-white/10 text-bone border border-line"
              }`}
            >
              {accuseResult.isImposter ? "IMPOSTER! (Eliminated)" : "NORMAL PLAYER (Innocent!)"}
            </div>
            <p className="text-xs text-mute mb-5">
              {accuseResult.isImposter
                ? "The imposter was caught, but more imposters remain!"
                : "The accusation was wrong. The accuser lost their accusation ability."}
            </p>
            <button
              onClick={() => {
                sounds.playTick();
                setAccuseResult(null);
              }}
              className="w-full py-3.5 rounded-xl bg-crimson hover:bg-crimson-bright text-white font-bold button-press"
            >
              Continue Game
            </button>
          </div>
        </div>
      )}

      {/* IMPOSTER GUESS MODAL */}
      {guessModalOpen && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/80 backdrop-blur-sm p-4">
          <div className="w-full max-w-md rounded-2xl bg-panel-dark p-6 border-2 border-amber-600 shadow-2xl animate-in fade-in duration-150">
            <h3 className="text-xl font-bold text-white mb-1">Guess the Secret Word</h3>
            <p className="text-xs text-mute mb-4">
              If an imposter guesses correctly, they win immediately!
            </p>

            <div className="space-y-4 mb-6">
              <div>
                <label className="text-xs font-bold uppercase tracking-wider text-mute block mb-1">
                  Which player is guessing?
                </label>
                <select
                  value={guessPlayerId}
                  onChange={(e) => setGuessPlayerId(e.target.value)}
                  className="w-full px-4 py-2.5 rounded-xl bg-panel border border-line text-bone font-medium focus:outline-none"
                >
                  <option value="">Select Player</option>
                  {gameState.players
                    .filter((p) => p.isAlive && p.remainingGuesses > 0)
                    .map((p) => (
                      <option key={p.id} value={p.id}>
                        {p.name} ({p.remainingGuesses} guess left)
                      </option>
                    ))}
                </select>
              </div>

              <div>
                <label className="text-xs font-bold uppercase tracking-wider text-mute block mb-1">
                  Secret Word Guess
                </label>
                <input
                  type="text"
                  maxLength={30}
                  value={guessWord}
                  onChange={(e) => setGuessWord(e.target.value)}
                  placeholder="Enter secret word..."
                  className="w-full px-4 py-2.5 rounded-xl bg-ink border border-line text-white font-medium focus:border-amber-600 focus:outline-none text-sm"
                />
              </div>
            </div>

            <div className="flex gap-3">
              <button
                type="button"
                onClick={() => setGuessModalOpen(false)}
                className="flex-1 py-3 rounded-xl bg-panel border border-line text-sm font-bold text-mute hover:text-bone"
              >
                Cancel
              </button>
              <button
                type="button"
                disabled={!guessPlayerId || !guessWord.trim()}
                onClick={handleExecuteGuess}
                className="flex-1 py-3 rounded-xl bg-amber-600 text-sm font-bold text-white hover:bg-amber-500 disabled:opacity-40 button-press shadow-md"
              >
                Submit Guess
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
