export class WordFilter {
  static normalize(text: string): string {
    return text.toLowerCase().replace(/[^a-z0-9]/g, "");
  }

  static containsSecretWord(clue: string, secretWord: string): boolean {
    const cleanClue = this.normalize(clue);
    const cleanSecret = this.normalize(secretWord);

    if (cleanSecret.length === 0) return false;
    if (cleanClue.includes(cleanSecret)) return true;

    // Word boundary check
    const secretEscaped = secretWord.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
    const regex = new RegExp(`\\b${secretEscaped}\\b`, "i");
    return regex.test(clue);
  }
}
