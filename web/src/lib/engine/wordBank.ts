import wordsData from "./words.json";

export interface WordBankData {
  [category: string]: {
    [word: string]: string[];
  };
}

const bank: WordBankData = wordsData as WordBankData;

export function getCategories(): string[] {
  return ["Random", ...Object.keys(bank), "Custom"];
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

  const availableCategories = Object.keys(bank);
  const selectedCategory =
    categorySetting === "Random" || !bank[categorySetting]
      ? availableCategories[Math.floor(Math.random() * availableCategories.length)]
      : categorySetting;

  const words = Object.keys(bank[selectedCategory]);
  const selectedWord = words[Math.floor(Math.random() * words.length)];

  return { category: selectedCategory, word: selectedWord };
}
