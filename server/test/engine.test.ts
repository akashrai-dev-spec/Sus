import fs from "fs";
import path from "path";
import { describe, expect, it } from "vitest";
import { GameEngine, GameEngineError } from "../src/game/gameEngine.js";
import { GamePlayer, GameSettings } from "../src/game/types.js";
import { WordFilter } from "../src/util/wordFilter.js";
import { pickSecretWord } from "../src/words/wordBank.js";

const FIXTURES_DIR = path.resolve(__dirname, "../../docs/fixtures");

describe("WordFilter", () => {
  it("detects exact, punctuated, and case-varied secret word", () => {
    expect(WordFilter.containsSecretWord("I love Apple", "Apple")).toBe(true);
    expect(WordFilter.containsSecretWord("APPLE!", "Apple")).toBe(true);
    expect(WordFilter.containsSecretWord("Is it an apple...?", "Apple")).toBe(true);
    expect(WordFilter.containsSecretWord("Just red fruit", "Apple")).toBe(false);
    expect(WordFilter.containsSecretWord("Baking a pizza pie", "Pizza")).toBe(true);
    expect(WordFilter.containsSecretWord("Baked in an oven", "Pizza")).toBe(false);
  });
});

describe("GameSettings imposter cap", () => {
  it("accurately calculates capped imposters for all group sizes", () => {
    expect(GameEngine.calculateCappedImposters(3, 3)).toBe(1);
    expect(GameEngine.calculateCappedImposters(3, 4)).toBe(1);
    expect(GameEngine.calculateCappedImposters(3, 5)).toBe(2);
    expect(GameEngine.calculateCappedImposters(3, 6)).toBe(2);
    expect(GameEngine.calculateCappedImposters(3, 8)).toBe(3);
    expect(GameEngine.calculateCappedImposters(3, 12)).toBe(3);
  });
});

describe("GameEngine Core Rules", () => {
  it("enforces player counts 3 to 12", () => {
    const twoPlayers: GamePlayer[] = [
      {
        id: "1",
        name: "A",
        color: "#9A0F28",
        isAlive: true,
        isHost: true,
        usedAccusation: false,
        remainingGuesses: 1,
        isReady: false,
      },
      {
        id: "2",
        name: "B",
        color: "#9A0F28",
        isAlive: true,
        isHost: false,
        usedAccusation: false,
        remainingGuesses: 1,
        isReady: false,
      },
    ];
    const settings: GameSettings = {
      maxPlayers: 6,
      imposters: 1,
      rounds: 2,
      guessAttempts: 1,
      category: "Food",
    };

    expect(() =>
      GameEngine.startGame({
        players: twoPlayers,
        settings,
        secretWord: "Apple",
        category: "Food",
      }),
    ).toThrow(GameEngineError);
  });

  it("skips eliminated players in turn order", () => {
    const players: GamePlayer[] = [
      {
        id: "p1",
        name: "P1",
        color: "#9A0F28",
        role: "normal",
        isAlive: true,
        isHost: true,
        usedAccusation: false,
        remainingGuesses: 1,
        isReady: false,
      },
      {
        id: "p2",
        name: "P2",
        color: "#9A0F28",
        role: "normal",
        isAlive: true,
        isHost: false,
        usedAccusation: false,
        remainingGuesses: 1,
        isReady: false,
      },
      {
        id: "p3",
        name: "P3",
        color: "#9A0F28",
        role: "imposter",
        isAlive: true,
        isHost: false,
        usedAccusation: false,
        remainingGuesses: 1,
        isReady: false,
      },
    ];

    let state = GameEngine.startGame({
      players,
      settings: {
        maxPlayers: 3,
        imposters: 1,
        rounds: 2,
        guessAttempts: 1,
        category: "Food",
      },
      secretWord: "Apple",
      category: "Food",
      customOrder: ["p1", "p2", "p3"],
      customImposterIds: ["p3"],
    });

    for (const p of players) {
      state = GameEngine.markPlayerReady(state, p.id);
    }
    expect(GameEngine.getCurrentSpeakerId(state)).toBe("p1");

    // Eliminate p2
    state.players = state.players.map((p) => (p.id === "p2" ? { ...p, isAlive: false } : p));

    state = GameEngine.submitClue(state, { playerId: "p1", text: "Sweet fruit" });
    expect(GameEngine.getCurrentSpeakerId(state)).toBe("p3");
  });

  it("rejects clue with secret word from normal player", () => {
    const players: GamePlayer[] = [
      {
        id: "p1",
        name: "P1",
        color: "#9A0F28",
        role: "normal",
        isAlive: true,
        isHost: true,
        usedAccusation: false,
        remainingGuesses: 1,
        isReady: false,
      },
      {
        id: "p2",
        name: "P2",
        color: "#9A0F28",
        role: "imposter",
        isAlive: true,
        isHost: false,
        usedAccusation: false,
        remainingGuesses: 1,
        isReady: false,
      },
      {
        id: "p3",
        name: "P3",
        color: "#9A0F28",
        role: "normal",
        isAlive: true,
        isHost: false,
        usedAccusation: false,
        remainingGuesses: 1,
        isReady: false,
      },
    ];

    let state = GameEngine.startGame({
      players,
      settings: {
        maxPlayers: 3,
        imposters: 1,
        rounds: 2,
        guessAttempts: 1,
        category: "Food",
      },
      secretWord: "Apple",
      category: "Food",
      customOrder: ["p1", "p2", "p3"],
      customImposterIds: ["p2"],
    });

    for (const p of players) {
      state = GameEngine.markPlayerReady(state, p.id);
    }

    expect(() =>
      GameEngine.submitClue(state, { playerId: "p1", text: "It is an Apple!" }),
    ).toThrowError("You cannot say the secret word.");
  });
});

describe("Shared Fixture Replays", () => {
  it("replay: innocent_accusation_and_imposter_guess.json", () => {
    const file = path.join(FIXTURES_DIR, "scenario_innocent_accusation_and_imposter_guess.json");
    const data = JSON.parse(fs.readFileSync(file, "utf-8"));

    const rawPlayers: GamePlayer[] = data.players.map((p: any) => ({
      id: p.id,
      name: p.name,
      color: "#9A0F28",
      role: p.role,
      isAlive: true,
      isHost: p.id === "p1",
      usedAccusation: false,
      remainingGuesses: 1,
      isReady: false,
    }));

    const settings: GameSettings = data.settings;
    const imposterIds = rawPlayers.filter((p) => p.role === "imposter").map((p) => p.id);

    let state = GameEngine.startGame({
      players: rawPlayers,
      settings,
      secretWord: data.secretWord,
      category: settings.category,
      customOrder: rawPlayers.map((p) => p.id),
      customImposterIds: imposterIds,
    });

    expect(state.currentPhase.name).toBe("roleReveal");

    for (const p of rawPlayers) {
      state = GameEngine.markPlayerReady(state, p.id);
    }
    expect(state.currentPhase.name).toBe("discussion");
    expect(GameEngine.getCurrentSpeakerId(state)).toBe("p1");

    state = GameEngine.submitClue(state, { playerId: "p1", text: "It can be red or green" });
    expect(GameEngine.getCurrentSpeakerId(state)).toBe("p2");

    state = GameEngine.submitAccusation(state, { accuserId: "p1", targetId: "p3" });
    expect(state.currentPhase.name).toBe("accusationPending");

    state = GameEngine.resolveAccusation(state);
    expect(state.currentPhase.name).toBe("discussion");

    const p1 = state.players.find((p) => p.id === "p1")!;
    const p3 = state.players.find((p) => p.id === "p3")!;
    expect(p1.usedAccusation).toBe(true);
    expect(p3.isAlive).toBe(true);

    state = GameEngine.imposterGuess(state, { playerId: "p2", word: "Apple" });
    expect(state.currentPhase.name).toBe("ended");
    if (state.currentPhase.name === "ended") {
      expect(state.currentPhase.winner).toBe("imposter");
    }
  });

  it("replay: imposter_caught_normals_win.json", () => {
    const file = path.join(FIXTURES_DIR, "scenario_imposter_caught_normals_win.json");
    const data = JSON.parse(fs.readFileSync(file, "utf-8"));

    const rawPlayers: GamePlayer[] = data.players.map((p: any) => ({
      id: p.id,
      name: p.name,
      color: "#9A0F28",
      role: p.role,
      isAlive: true,
      isHost: p.id === "p1",
      usedAccusation: false,
      remainingGuesses: 1,
      isReady: false,
    }));

    const settings: GameSettings = data.settings;
    const imposterIds = rawPlayers.filter((p) => p.role === "imposter").map((p) => p.id);

    let state = GameEngine.startGame({
      players: rawPlayers,
      settings,
      secretWord: data.secretWord,
      category: settings.category,
      customOrder: rawPlayers.map((p) => p.id),
      customImposterIds: imposterIds,
    });

    for (const p of rawPlayers) {
      state = GameEngine.markPlayerReady(state, p.id);
    }

    state = GameEngine.submitClue(state, {
      playerId: "p1",
      text: "It is baked in a very hot oven",
    });
    expect(GameEngine.getCurrentSpeakerId(state)).toBe("p2");

    state = GameEngine.submitAccusation(state, { accuserId: "p3", targetId: "p2" });
    state = GameEngine.resolveAccusation(state);

    expect(state.currentPhase.name).toBe("ended");
    if (state.currentPhase.name === "ended") {
      expect(state.currentPhase.winner).toBe("normal");
      expect(state.currentPhase.reason).toBe("Every imposter was caught.");
    }
    expect(state.players.find((p) => p.id === "p2")!.isAlive).toBe(false);
  });

  it("replay: final_vote_repeat_multi_imposter.json", () => {
    const file = path.join(FIXTURES_DIR, "scenario_final_vote_repeat_multi_imposter.json");
    const data = JSON.parse(fs.readFileSync(file, "utf-8"));

    const rawPlayers: GamePlayer[] = data.players.map((p: any) => ({
      id: p.id,
      name: p.name,
      color: "#9A0F28",
      role: p.role,
      isAlive: true,
      isHost: p.id === "p1",
      usedAccusation: false,
      remainingGuesses: 1,
      isReady: false,
    }));

    const settings: GameSettings = data.settings;
    const imposterIds = rawPlayers.filter((p) => p.role === "imposter").map((p) => p.id);

    let state = GameEngine.startGame({
      players: rawPlayers,
      settings,
      secretWord: data.secretWord,
      category: settings.category,
      customOrder: rawPlayers.map((p) => p.id),
      customImposterIds: imposterIds,
    });

    for (const p of rawPlayers) {
      state = GameEngine.markPlayerReady(state, p.id);
    }

    for (let i = 0; i < 5; i++) {
      state = GameEngine.nextSpeaker(state);
    }

    expect(state.currentPhase.name).toBe("finalVote");
    if (state.currentPhase.name === "finalVote") {
      expect(state.currentPhase.voteRound).toBe(1);
    }

    state = GameEngine.submitAccusation(state, { targetId: "p2" });
    state = GameEngine.resolveAccusation(state);

    expect(state.currentPhase.name).toBe("finalVote");
    if (state.currentPhase.name === "finalVote") {
      expect(state.currentPhase.voteRound).toBe(2);
    }
    expect(state.players.find((p) => p.id === "p2")!.isAlive).toBe(false);

    state = GameEngine.submitAccusation(state, { targetId: "p1" });
    state = GameEngine.resolveAccusation(state);

    expect(state.currentPhase.name).toBe("ended");
    if (state.currentPhase.name === "ended") {
      expect(state.currentPhase.winner).toBe("imposter");
    }
  });

  it("replay: word_filter_and_imposter_cap.json", () => {
    const file = path.join(FIXTURES_DIR, "scenario_word_filter_and_imposter_cap.json");
    const data = JSON.parse(fs.readFileSync(file, "utf-8"));

    for (const t of data.imposterCapTests) {
      const res = GameEngine.calculateCappedImposters(t.setting, t.players);
      expect(res).toBe(t.expectedCap);
    }

    for (const t of data.wordFilterTests) {
      const res = WordFilter.containsSecretWord(t.clue, t.secretWord);
      expect(res).toBe(t.expectedForbidden);
    }
  });

  it("supports custom words and categories", () => {
    const res = pickSecretWord("Custom", "Everest", "Mountains");
    expect(res.category).toBe("Mountains");
    expect(res.word).toBe("Everest");

    const res2 = pickSecretWord("Custom", "Kathmandu");
    expect(res2.category).toBe("Custom");
    expect(res2.word).toBe("Kathmandu");
  });

  it("selects imposters with unbiased uniform randomness across repeated games", () => {
    const players: GamePlayer[] = [
      { id: "p1", name: "P1", color: "#9A0F28", isAlive: true, isHost: true, usedAccusation: false, remainingGuesses: 1, isReady: true },
      { id: "p2", name: "P2", color: "#9A0F28", isAlive: true, isHost: false, usedAccusation: false, remainingGuesses: 1, isReady: true },
      { id: "p3", name: "P3", color: "#9A0F28", isAlive: true, isHost: false, usedAccusation: false, remainingGuesses: 1, isReady: true },
    ];
    const settings: GameSettings = {
      maxPlayers: 3,
      imposters: 1,
      rounds: 2,
      guessAttempts: 1,
      category: "Objects & Food",
    };

    const imposterCounts: Record<string, number> = { p1: 0, p2: 0, p3: 0 };
    const iterations = 600;

    for (let i = 0; i < iterations; i++) {
      const state = GameEngine.startGame({
        players,
        settings,
        secretWord: "Apple",
        category: "Objects & Food",
      });
      const imp = state.players.find((p) => p.role === "imposter")!;
      imposterCounts[imp.id]++;
    }

    // Each player should be picked around ~200 times (within reasonable statistical bounds, e.g. 130 - 270)
    expect(imposterCounts.p1).toBeGreaterThan(130);
    expect(imposterCounts.p1).toBeLessThan(270);
    expect(imposterCounts.p2).toBeGreaterThan(130);
    expect(imposterCounts.p2).toBeLessThan(270);
    expect(imposterCounts.p3).toBeGreaterThan(130);
    expect(imposterCounts.p3).toBeLessThan(270);
  });

  it("supports custom discussion rounds up to 10", () => {
    const players: GamePlayer[] = [
      { id: "p1", name: "P1", color: "#9A0F28", isAlive: true, isHost: true, usedAccusation: false, remainingGuesses: 1, isReady: true },
      { id: "p2", name: "P2", color: "#9A0F28", isAlive: true, isHost: false, usedAccusation: false, remainingGuesses: 1, isReady: true },
      { id: "p3", name: "P3", color: "#9A0F28", isAlive: true, isHost: false, usedAccusation: false, remainingGuesses: 1, isReady: true },
    ];
    const settings: GameSettings = {
      maxPlayers: 3,
      imposters: 1,
      rounds: 10,
      guessAttempts: 1,
      category: "Objects & Food",
    };

    const state = GameEngine.startGame({
      players,
      settings,
      secretWord: "Apple",
      category: "Objects & Food",
      customOrder: ["p1", "p2", "p3"],
    });

    expect(state.settings.rounds).toBe(10);
  });
});
