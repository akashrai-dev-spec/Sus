import crypto from "crypto";
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

export function pickSecretWord(
  categorySetting: string,
  customWord?: string,
  customCategory?: string
): { category: string; word: string } {
  if (
    categorySetting === "Custom" &&
    customWord &&
    customWord.trim().length > 0
  ) {
    return {
      category:
        customCategory && customCategory.trim().length > 0
          ? customCategory.trim()
          : "Custom",
      word: customWord.trim(),
    };
  }

  const bank = loadWordBank();
  const availableCategories = Object.keys(bank);

  const selectedCategory =
    categorySetting === "Random" || !bank[categorySetting]
      ? availableCategories[crypto.randomInt(0, availableCategories.length)]
      : categorySetting;

  const words = Object.keys(bank[selectedCategory]);
  const selectedWord = words[crypto.randomInt(0, words.length)];

  return { category: selectedCategory, word: selectedWord };
}
