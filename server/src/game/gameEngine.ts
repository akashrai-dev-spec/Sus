import crypto from "crypto";
import { WordFilter } from "../util/wordFilter.js";
import {
  AccusationResult,
  GameClue,
  GamePhase,
  GamePlayer,
  GameSettings,
  GameState,
  PlayerRole,
} from "./types.js";

export class GameEngineError extends Error {
  constructor(
    public readonly code: string,
    message: string,
  ) {
    super(message);
    this.name = "GameEngineError";
  }
}

/**
 * Performs a cryptographically secure, unbiased Fisher-Yates (Knuth) shuffle.
 */
export function secureShuffle<T>(items: readonly T[]): T[] {
  const result = [...items];
  for (let i = result.length - 1; i > 0; i--) {
    const j = crypto.randomInt(0, i + 1);
    const temp = result[i];
    result[i] = result[j];
    result[j] = temp;
  }
  return result;
}

export class GameEngine {
  static calculateCappedImposters(requested: number, totalPlayers: number): number {
    const maxAllowed = Math.max(1, Math.floor((totalPlayers - 1) / 2));
    return Math.min(requested, maxAllowed);
  }

  static getCurrentSpeakerId(state: GameState): string | null {
    if (state.currentPhase.name !== "discussion") return null;
    const { turnIndex } = state.currentPhase;
    if (state.speakingOrder.length === 0) return null;

    const candId = state.speakingOrder[turnIndex % state.speakingOrder.length];
    const cand = state.players.find((p) => p.id === candId);
    if (cand && cand.isAlive) {
      return candId;
    }

    for (let i = 1; i < state.speakingOrder.length; i++) {
      const nextId = state.speakingOrder[(turnIndex + i) % state.speakingOrder.length];
      const nextP = state.players.find((p) => p.id === nextId);
      if (nextP && nextP.isAlive) {
        return nextId;
      }
    }
    return null;
  }

  static startGame(params: {
    players: GamePlayer[];
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
        "Sus requires between 3 and 12 players.",
      );
    }

    const imposterCount = GameEngine.calculateCappedImposters(settings.imposters, players.length);

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

  static markPlayerReady(state: GameState, playerId: string): GameState {
    if (state.currentPhase.name !== "roleReveal") {
      throw new GameEngineError(
        "ILLEGAL_PHASE",
        "Cannot mark player ready outside role reveal phase.",
      );
    }

    const updatedPlayers = state.players.map((p) =>
      p.id === playerId ? { ...p, isReady: true } : p,
    );

    const allReady = updatedPlayers.every((p) => p.isReady);
    const nextPhase: GamePhase = allReady
      ? { name: "discussion", round: 1, turnIndex: 0 }
      : state.currentPhase;

    return {
      ...state,
      players: updatedPlayers,
      currentPhase: nextPhase,
    };
  }

  static submitClue(
    state: GameState,
    params: { playerId: string; text: string; timestamp?: string },
  ): GameState {
    if (state.currentPhase.name !== "discussion") {
      throw new GameEngineError(
        "ILLEGAL_PHASE",
        "Clues can only be submitted during the discussion phase.",
      );
    }

    const currentSpeaker = GameEngine.getCurrentSpeakerId(state);
    if (currentSpeaker !== params.playerId) {
      throw new GameEngineError(
        "NOT_PLAYER_TURN",
        "It is not this player's turn to give a clue.",
      );
    }

    const player = state.players.find((p) => p.id === params.playerId);
    if (!player || !player.isAlive) {
      throw new GameEngineError("PLAYER_NOT_ALIVE", "Player is not alive to speak.");
    }

    const cleanText = params.text.trim();
    if (!cleanText || cleanText.length > 60) {
      throw new GameEngineError(
        "INVALID_CLUE_LENGTH",
        "Clue must be between 1 and 60 characters.",
      );
    }

    if (player.role === "normal" && WordFilter.containsSecretWord(cleanText, state.secretWord)) {
      throw new GameEngineError("WORD_FORBIDDEN", "You cannot say the secret word.");
    }

    const newClue: GameClue = {
      playerId: params.playerId,
      text: cleanText,
      timestamp: params.timestamp || new Date().toISOString(),
    };

    return GameEngine.advanceTurn(
      { ...state, clues: [...state.clues, newClue] },
      state.currentPhase.turnIndex,
    );
  }

  static nextSpeaker(state: GameState): GameState {
    if (state.currentPhase.name !== "discussion") {
      throw new GameEngineError("ILLEGAL_PHASE", "Next speaker only valid during discussion.");
    }
    return GameEngine.advanceTurn(state, state.currentPhase.turnIndex);
  }

  private static advanceTurn(state: GameState, currentTurnIndex: number): GameState {
    const totalSpeakingOrder = state.speakingOrder.length;
    const maxTurns = totalSpeakingOrder * state.settings.rounds;

    let nextTurnIndex = currentTurnIndex + 1;

    while (nextTurnIndex < maxTurns) {
      const candId = state.speakingOrder[nextTurnIndex % totalSpeakingOrder];
      const cand = state.players.find((p) => p.id === candId);
      if (cand && cand.isAlive) {
        break;
      }
      nextTurnIndex++;
    }

    if (nextTurnIndex >= maxTurns) {
      return {
        ...state,
        currentPhase: { name: "finalVote", voteRound: 1 },
      };
    }

    const nextRound = Math.floor(nextTurnIndex / totalSpeakingOrder) + 1;
    return {
      ...state,
      currentPhase: {
        name: "discussion",
        round: Math.min(nextRound, state.settings.rounds),
        turnIndex: nextTurnIndex,
      },
    };
  }

  static submitAccusation(
    state: GameState,
    params: { accuserId?: string; targetId: string },
  ): GameState {
    const phase = state.currentPhase;
    const isFinalVote = phase.name === "finalVote";

    if (phase.name !== "discussion" && !isFinalVote) {
      throw new GameEngineError(
        "ILLEGAL_PHASE",
        "Accusations can only be made during discussion or final vote.",
      );
    }

    const target = state.players.find((p) => p.id === params.targetId);
    if (!target || !target.isAlive) {
      throw new GameEngineError(
        "INVALID_TARGET",
        "Target player is invalid or already eliminated.",
      );
    }

    if (params.accuserId) {
      if (params.accuserId === params.targetId) {
        throw new GameEngineError("SELF_ACCUSATION", "Players cannot accuse themselves.");
      }
      const accuser = state.players.find((p) => p.id === params.accuserId);
      if (!accuser || !accuser.isAlive) {
        throw new GameEngineError("ACCUSER_NOT_ALIVE", "Accusing player is not alive.");
      }
      if (!isFinalVote && accuser.usedAccusation) {
        throw new GameEngineError(
          "ACCUSATION_ALREADY_USED",
          "This player has already used their accusation this game.",
        );
      }
    }

    return {
      ...state,
      currentPhase: {
        name: "accusationPending",
        accuserId: params.accuserId,
        targetId: params.targetId,
        isFinalVote,
        previousPhase: phase,
      },
    };
  }

  static resolveAccusation(state: GameState): GameState {
    if (state.currentPhase.name !== "accusationPending") {
      throw new GameEngineError("ILLEGAL_PHASE", "No pending accusation to resolve.");
    }

    const pend = state.currentPhase;
    const target = state.players.find((p) => p.id === pend.targetId)!;
    const isHit = target.role === "imposter";

    const updatedPlayers = state.players.map((p) => {
      if (p.id === pend.targetId && isHit) {
        return { ...p, isAlive: false };
      }
      if (p.id === pend.accuserId && !isHit && !pend.isFinalVote) {
        return { ...p, usedAccusation: true };
      }
      return p;
    });

    const result: AccusationResult = {
      accuserId: pend.accuserId,
      targetId: pend.targetId,
      revealedRole: target.role as PlayerRole,
      outcome: isHit ? "caught" : "innocentFail",
      isFinalVote: pend.isFinalVote,
    };

    const remainingImposters = updatedPlayers.filter((p) => p.role === "imposter" && p.isAlive);

    if (remainingImposters.length === 0) {
      return {
        ...state,
        players: updatedPlayers,
        lastAccusationResult: result,
        currentPhase: {
          name: "ended",
          winner: "normal",
          reason: "Every imposter was caught.",
          secretWord: state.secretWord,
          category: state.category,
        },
      };
    }

    if (pend.isFinalVote) {
      if (!isHit) {
        return {
          ...state,
          players: updatedPlayers,
          lastAccusationResult: result,
          currentPhase: {
            name: "ended",
            winner: "imposter",
            reason: "The final accusation named the wrong player.",
            secretWord: state.secretWord,
            category: state.category,
          },
        };
      } else {
        const prevVote =
          pend.previousPhase.name === "finalVote" ? pend.previousPhase.voteRound : 1;
        return {
          ...state,
          players: updatedPlayers,
          lastAccusationResult: result,
          currentPhase: { name: "finalVote", voteRound: prevVote + 1 },
        };
      }
    }

    return {
      ...state,
      players: updatedPlayers,
      lastAccusationResult: result,
      currentPhase: pend.previousPhase,
    };
  }

  static imposterGuess(
    state: GameState,
    params: { playerId: string; word: string },
  ): GameState {
    if (state.currentPhase.name === "ended") {
      throw new GameEngineError("GAME_ALREADY_ENDED", "Cannot guess word in an ended game.");
    }

    const player = state.players.find((p) => p.id === params.playerId);
    if (!player || !player.isAlive) {
      throw new GameEngineError("PLAYER_NOT_ALIVE", "Player is not alive.");
    }

    if (player.remainingGuesses <= 0) {
      throw new GameEngineError("NO_GUESSES_REMAINING", "No guess attempts remaining.");
    }

    const updatedPlayers = state.players.map((p) =>
      p.id === params.playerId ? { ...p, remainingGuesses: p.remainingGuesses - 1 } : p,
    );

    const cleanGuess = params.word.trim().toLowerCase();
    const cleanSecret = state.secretWord.trim().toLowerCase();

    if (player.role === "imposter" && cleanGuess === cleanSecret) {
      return {
        ...state,
        players: updatedPlayers,
        currentPhase: {
          name: "ended",
          winner: "imposter",
          reason: `${player.name} guessed the word "${state.secretWord}".`,
          secretWord: state.secretWord,
          category: state.category,
        },
      };
    }

    return {
      ...state,
      players: updatedPlayers,
    };
  }
}
