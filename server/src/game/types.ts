export type PlayerRole = "normal" | "imposter";

export type AccusationOutcome = "caught" | "innocentFail";

export type GamePhase =
  | { name: "lobby" }
  | { name: "roleReveal" }
  | { name: "discussion"; round: number; turnIndex: number }
  | {
      name: "accusationPending";
      accuserId?: string;
      targetId: string;
      isFinalVote: boolean;
      previousPhase: GamePhase;
    }
  | { name: "finalVote"; voteRound: number }
  | {
      name: "ended";
      winner: "normal" | "imposter";
      reason: string;
      secretWord: string;
      category: string;
    };

export interface GameSettings {
  maxPlayers: number;
  imposters: number;
  rounds: number;
  guessAttempts: number;
  category: string;
  customWord?: string;
  customCategory?: string;
}

export interface GamePlayer {
  id: string;
  name: string;
  color: string;
  role?: PlayerRole;
  isAlive: boolean;
  isHost: boolean;
  usedAccusation: boolean;
  remainingGuesses: number;
  isReady: boolean;
  isConnected?: boolean;
}

export interface GameClue {
  playerId: string;
  text: string;
  timestamp: string;
}

export interface AccusationResult {
  accuserId?: string;
  targetId: string;
  revealedRole: PlayerRole;
  outcome: AccusationOutcome;
  isFinalVote: boolean;
}

export interface GameState {
  players: GamePlayer[];
  speakingOrder: string[];
  currentPhase: GamePhase;
  settings: GameSettings;
  secretWord: string;
  category: string;
  clues: GameClue[];
  lastAccusationResult?: AccusationResult;
}
