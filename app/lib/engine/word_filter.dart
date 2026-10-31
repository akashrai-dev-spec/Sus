/// Utility to check whether a clue reveals the secret word.
class WordFilter {
  WordFilter._();

  /// Returns true if [clue] mentions [secretWord] (case-insensitive, punctuation stripped).
  static bool containsSecretWord(String clue, String secretWord) {
    if (clue.trim().isEmpty || secretWord.trim().isEmpty) return false;

    final normClue = _normalize(clue);
    final normWord = _normalize(secretWord);

    if (normClue.isEmpty || normWord.isEmpty) return false;

    // Check whole words or direct substring matches
    final words = normClue.split(' ');
    final targetWords = normWord.split(' ');

    if (targetWords.length == 1) {
      final target = targetWords.first;
      for (final w in words) {
        if (w == target) return true;
      }
    }

    // Also check complete multi-word phrase or normalized containment
    return normClue.contains(normWord);
  }

  static String _normalize(String input) {
    return input
        .toLowerCase()
        .replaceAll(RegExp(r"[^\w\s]"), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
