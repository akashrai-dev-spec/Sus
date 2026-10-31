import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));

export interface WordBankData {
  [category: string]: {
    [word: string]: string[];
  };
}

let cachedWords: WordBankData | null = null;

export function loadWordBank(): WordBankData {
  if (cachedWords) return cachedWords;
  const filePath = path.resolve(__dirname, "words.json");
  const raw = fs.readFileSync(filePath, "utf-8");
  cachedWords = JSON.parse(raw) as WordBankData;
  return cachedWords;
}

export function getCategories(): string[] {
  const bank = loadWordBank();
  return Object.keys(bank);
}

export function pickSecretWord(categorySetting: string): { category: string; word: string } {
  const bank = loadWordBank();
  const availableCategories = Object.keys(bank);

  const selectedCategory =
    categorySetting === "Random" || !bank[categorySetting]
      ? availableCategories[Math.floor(Math.random() * availableCategories.length)]
      : categorySetting;

  const words = Object.keys(bank[selectedCategory]);
  const selectedWord = words[Math.floor(Math.random() * words.length)];

  return { category: selectedCategory, word: selectedWord };
}
