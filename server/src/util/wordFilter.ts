export class WordFilter {
  static containsSecretWord(clue: string, secretWord: string): boolean {
    if (!clue.trim() || !secretWord.trim()) return false;

    const normClue = WordFilter.normalize(clue);
    const normWord = WordFilter.normalize(secretWord);

    if (!normClue || !normWord) return false;

    const clueWords = normClue.split(" ");
    const targetWords = normWord.split(" ");

    if (targetWords.length === 1) {
      const target = targetWords[0];
      for (const w of clueWords) {
        if (w === target) return true;
      }
    }

    return normClue.includes(normWord);
  }

  private static normalize(input: string): string {
    return input
      .toLowerCase()
      .replace(/[^\w\s]/g, " ")
      .replace(/\s+/g, " ")
      .trim();
  }
}
