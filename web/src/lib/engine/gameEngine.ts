import { WordFilter } from "./wordFilter";
import {
  AccusationResult,
  GameClue,
  GamePhase,
  GamePlayer,
  GameSettings,
  GameState,
  PlayerRole,
} from "./types";

export class GameEngineError extends Error {
  constructor(
    public readonly code: string,
    message: string
  ) {
    super(message);
    this.name = "GameEngineError";
  }
}

/**
 * Unbiased Fisher-Yates shuffle using crypto.getRandomValues if available,
 * falling back to Math.random.
 */
export function secureShuffle<T>(items: readonly T[]): T[] {
  const result = [...items];
  for (let i = result.length - 1; i > 0; i--) {
    let rand = Math.random();
    if (typeof window !== "undefined" && window.crypto && window.crypto.getRandomValues) {
      const buf = new Uint32Array(1);
      window.crypto.getRandomValues(buf);
      rand = buf[0] / (0xffffffff + 1);
    }
    const j = Math.floor(rand * (i + 1));
    const temp = result[i];
    result[i] = result[j];
    result[j] = temp;
  }
  return result;
}

export class WebGameEngine {
  static calculateCappedImposters(requested: number, totalPlayers: number): number {
    const maxAllowed = Math.max(1, Math.floor((totalPlayers - 1) / 2));
    return Math.min(requested, maxAllowed);
  }

  static startGame(params: {
    players: Array<Omit<GamePlayer, "role">>;
    settings: GameSettings;
    secretWord: string;
    category: string;
    customOrder?: string[];
    customImposterIds?: string[];
  }): GameState {
    const { players, settings, secretWord, category, customOrder, customImposterIds } = params;

    if (players.length < 3 || players.length > 12) {
      throw new GameEngineError(
        "INVALID_PLAYER_COUNT",
        "Sus requires between 3 and 12 players."
      );
    }

    const imposterCount = this.calculateCappedImposters(settings.imposters, players.length);

    let imposterIds: string[];
    if (customImposterIds) {
      imposterIds = [...customImposterIds];
    } else {
      const shuffled = secureShuffle(players);
      imposterIds = shuffled.slice(0, imposterCount).map((p) => p.id);
    }

    const assignedPlayers: GamePlayer[] = players.map((p) => {
      const isImp = imposterIds.includes(p.id);
      return {
        ...p,
        role: isImp ? "imposter" : "normal",
        isAlive: true,
        usedAccusation: false,
        remainingGuesses: settings.guessAttempts,
        isReady: false,
      };
    });

    const order = customOrder
      ? [...customOrder]
      : secureShuffle(assignedPlayers.map((p) => p.id));

    return {
      players: assignedPlayers,
      speakingOrder: order,
      currentPhase: { name: "roleReveal" },
      settings,
      secretWord,
      category,
      clues: [],
    };
  }

  static setPlayerReady(state: GameState, playerId: string): GameState {
    if (state.currentPhase.name !== "roleReveal") return state;

    const updated = state.players.map((p) =>
      p.id === playerId ? { ...p, isReady: true } : p
    );

    const allReady = updated.every((p) => p.isReady);
    if (allReady) {
      const firstSpeaker = state.speakingOrder[0];
      return {
        ...state,
        players: updated,
        currentPhase: {
          name: "discussion",
          round: 1,
          currentSpeakerId: firstSpeaker,
          turnIndex: 0,
        },
      };
    }

    return { ...state, players: updated };
  }

  static submitClue(state: GameState, params: { playerId: string; text: string }): GameState {
    if (state.currentPhase.name !== "discussion") {
      throw new GameEngineError("INVALID_PHASE", "Clues may only be submitted during discussion.");
    }

    const phase = state.currentPhase;
    if (phase.currentSpeakerId !== params.playerId) {
      throw new GameEngineError("NOT_YOUR_TURN", "It is not your turn to speak.");
    }

    const player = state.players.find((p) => p.id === params.playerId);
    if (player && player.role === "normal") {
      if (WordFilter.containsSecretWord(params.text, state.secretWord)) {
        throw new GameEngineError(
          "SECRET_WORD_FORBIDDEN",
          "You may not say the secret word or any direct variant."
        );
      }
    }

    const newClue: GameClue = {
      playerId: params.playerId,
      round: phase.round,
      text: params.text.trim(),
      timestamp: Date.now(),
    };

    const nextState = this.advanceTurn(state, phase.turnIndex + 1);
    return {
      ...nextState,
      clues: [...state.clues, newClue],
    };
  }

  static advanceTurn(state: GameState, targetTurnIndex: number): GameState {
    const totalSpeakingOrder = state.speakingOrder.length;
    const maxTurns = totalSpeakingOrder * state.settings.rounds;

    if (targetTurnIndex >= maxTurns) {
      return {
        ...state,
        currentPhase: {
          name: "finalVote",
          voteRound: 1,
        },
      };
    }

    let nextTurn = targetTurnIndex;
    let nextSpeakerId = state.speakingOrder[nextTurn % totalSpeakingOrder];
    let nextPlayer = state.players.find((p) => p.id === nextSpeakerId);

    while (nextPlayer && !nextPlayer.isAlive && nextTurn < maxTurns) {
      nextTurn++;
      nextSpeakerId = state.speakingOrder[nextTurn % totalSpeakingOrder];
      nextPlayer = state.players.find((p) => p.id === nextSpeakerId);
    }

    if (nextTurn >= maxTurns) {
      return {
        ...state,
        currentPhase: {
          name: "finalVote",
          voteRound: 1,
        },
      };
    }

    const nextRound = Math.floor(nextTurn / totalSpeakingOrder) + 1;

    return {
      ...state,
      currentPhase: {
        name: "discussion",
        round: Math.min(nextRound, state.settings.rounds),
        currentSpeakerId: nextSpeakerId,
        turnIndex: nextTurn,
      },
    };
  }

  static startAccusation(
    state: GameState,
    params: { accuserId: string; targetId: string }
  ): GameState {
    if (state.currentPhase.name !== "discussion") {
      throw new GameEngineError("INVALID_PHASE", "Accusations can only be initiated during discussion.");
    }

    const accuser = state.players.find((p) => p.id === params.accuserId);
    const accused = state.players.find((p) => p.id === params.targetId);

    if (!accuser || !accused) throw new GameEngineError("PLAYER_NOT_FOUND", "Player not found.");
    if (!accuser.isAlive || accuser.usedAccusation) {
      throw new GameEngineError("ACCUSATION_UNAVAILABLE", "Accuser has already used their accusation.");
    }
    if (!accused.isAlive) {
      throw new GameEngineError("TARGET_NOT_ALIVE", "Target is already eliminated.");
    }
    if (params.accuserId === params.targetId) {
      throw new GameEngineError("CANNOT_ACCUSE_SELF", "You cannot accuse yourself.");
    }

    const prevSpeaker = state.currentPhase.currentSpeakerId;

    return {
      ...state,
      currentPhase: {
        name: "accusing",
        accuserPlayerId: params.accuserId,
        accusedPlayerId: params.targetId,
        previousSpeakerId: prevSpeaker,
      },
    };
  }

  static resolveAccusation(state: GameState): { state: GameState; result: AccusationResult } {
    if (state.currentPhase.name !== "accusing" && state.currentPhase.name !== "finalVote") {
      throw new GameEngineError("INVALID_PHASE", "No accusation is pending resolution.");
    }

    if (state.currentPhase.name === "accusing") {
      const { accuserPlayerId, accusedPlayerId, previousSpeakerId } = state.currentPhase;
      const target = state.players.find((p) => p.id === accusedPlayerId)!;
      const isHit = target.role === "imposter";

      const updatedPlayers = state.players.map((p) => {
        if (p.id === accuserPlayerId) {
          return { ...p, usedAccusation: true };
        }
        if (p.id === accusedPlayerId) {
          return isHit ? { ...p, isAlive: false } : p;
        }
        return p;
      });

      const remainingImposters = updatedPlayers.filter((p) => p.role === "imposter" && p.isAlive);

      if (isHit && remainingImposters.length === 0) {
        const endedState: GameState = {
          ...state,
          players: updatedPlayers,
          currentPhase: {
            name: "ended",
            winner: "normal",
            reason: "Every imposter was caught.",
          },
        };
        return {
          state: endedState,
          result: {
            accusedId: accusedPlayerId,
            accuserId: accuserPlayerId,
            roleRevealed: target.role,
            isImposter: isHit,
            eliminated: isHit,
            isGameOver: true,
            winner: "normal",
          },
        };
      }

      // Resume discussion
      const discState: GameState = {
        ...state,
        players: updatedPlayers,
        currentPhase: {
          name: "discussion",
          round: 1,
          currentSpeakerId: previousSpeakerId,
          turnIndex: 0,
        },
      };

      return {
        state: discState,
        result: {
          accusedId: accusedPlayerId,
          accuserId: accuserPlayerId,
          roleRevealed: target.role,
          isImposter: isHit,
          eliminated: isHit,
          isGameOver: false,
        },
      };
    }

    // Final Vote resolution
    const accusedId = state.currentPhase.accusedPlayerId!;
    const target = state.players.find((p) => p.id === accusedId)!;
    const isHit = target.role === "imposter";

    if (!isHit) {
      const endedState: GameState = {
        ...state,
        currentPhase: {
          name: "ended",
          winner: "imposter",
          reason: "Normal players failed their final vote.",
        },
      };
      return {
        state: endedState,
        result: {
          accusedId,
          accuserId: "group",
          roleRevealed: target.role,
          isImposter: false,
          eliminated: false,
          isGameOver: true,
          winner: "imposter",
        },
      };
    }

    const updatedPlayers = state.players.map((p) =>
      p.id === accusedId ? { ...p, isAlive: false } : p
    );
    const remainingImposters = updatedPlayers.filter((p) => p.role === "imposter" && p.isAlive);

    if (remainingImposters.length === 0) {
      const endedState: GameState = {
        ...state,
        players: updatedPlayers,
        currentPhase: {
          name: "ended",
          winner: "normal",
          reason: "All imposters caught in the final vote.",
        },
      };
      return {
        state: endedState,
        result: {
          accusedId,
          accuserId: "group",
          roleRevealed: target.role,
          isImposter: true,
          eliminated: true,
          isGameOver: true,
          winner: "normal",
        },
      };
    }

    // Repeat final vote
    const repeatState: GameState = {
      ...state,
      players: updatedPlayers,
      currentPhase: {
        name: "finalVote",
        voteRound: (state.currentPhase.voteRound || 1) + 1,
      },
    };
    return {
      state: repeatState,
      result: {
        accusedId,
        accuserId: "group",
        roleRevealed: target.role,
        isImposter: true,
        eliminated: true,
        isGameOver: false,
      },
    };
  }

  static imposterGuess(
    state: GameState,
    params: { playerId: string; word: string }
  ): GameState {
    const player = state.players.find((p) => p.id === params.playerId);
    if (!player || !player.isAlive || player.remainingGuesses <= 0) {
      return state;
    }

    const normalizeWord = (w: string) =>
      w
        .trim()
        .toLowerCase()
        .replace(/[^\w\s]/g, "")
        .trim()
        .replace(/^(a|an|the)\s+/i, "")
        .replace(/\s+/g, " ")
        .trim();

    const cleanGuess = normalizeWord(params.word);
    const cleanSecret = normalizeWord(state.secretWord);

    if (player.role === "imposter" && cleanGuess === cleanSecret) {
      return {
        ...state,
        currentPhase: {
          name: "ended",
          winner: "imposter",
          reason: `${player.name} guessed the secret word!`,
        },
      };
    }

    return {
      ...state,
      players: state.players.map((p) =>
        p.id === params.playerId
          ? { ...p, remainingGuesses: p.remainingGuesses - 1 }
          : p
      ),
    };
  }
}
