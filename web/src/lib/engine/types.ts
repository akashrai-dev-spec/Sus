export type PlayerRole = "normal" | "imposter";

export interface GamePlayer {
  id: string;
  name: string;
  color: string;
  role: PlayerRole;
  isAlive: boolean;
  isHost: boolean;
  usedAccusation: boolean;
  remainingGuesses: number;
  isReady: boolean;
}

export type GamePhase =
  | { name: "roleReveal" }
  | { name: "discussion"; round: number; currentSpeakerId: string; turnIndex: number }
  | { name: "accusing"; accuserPlayerId: string; accusedPlayerId: string; previousSpeakerId: string }
  | { name: "finalVote"; voteRound: number; accusedPlayerId?: string }
  | { name: "ended"; winner: "normal" | "imposter"; reason: string };

export interface GameSettings {
  maxPlayers: number;
  imposters: number;
  rounds: number;
  guessAttempts: number;
  category: string;
  customWord?: string;
  customCategory?: string;
}

export interface GameClue {
  playerId: string;
  round: number;
  text: string;
  timestamp: number;
}

export interface GameState {
  players: GamePlayer[];
  speakingOrder: string[];
  currentPhase: GamePhase;
  settings: GameSettings;
  secretWord: string;
  category: string;
  clues: GameClue[];
}

export interface AccusationResult {
  accusedId: string;
  accuserId: string;
  roleRevealed: PlayerRole;
  isImposter: boolean;
  eliminated: boolean;
  isGameOver: boolean;
  winner?: "normal" | "imposter";
}
