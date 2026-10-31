import 'dart:math' as math;

class GameSettings {
  const GameSettings({
    this.maxPlayers = 6,
    this.imposters = 1,
    this.rounds = 2,
    this.guessAttempts = 1,
    this.category = 'Random',
  });

  final int maxPlayers;
  final int imposters;
  final int rounds;
  final int guessAttempts;
  final String category;

  /// Capped imposter formula: min(setting, max(1, floor((n-1)/2)))
  static int calculateCappedImposters(int requested, int totalPlayers) {
    final maxAllowed = math.max(1, (totalPlayers - 1) ~/ 2);
    return math.min(requested, maxAllowed);
  }

  GameSettings copyWith({
    int? maxPlayers,
    int? imposters,
    int? rounds,
    int? guessAttempts,
    String? category,
  }) {
    return GameSettings(
      maxPlayers: maxPlayers ?? this.maxPlayers,
      imposters: imposters ?? this.imposters,
      rounds: rounds ?? this.rounds,
      guessAttempts: guessAttempts ?? this.guessAttempts,
      category: category ?? this.category,
    );
  }

  Map<String, dynamic> toJson() => {
        'maxPlayers': maxPlayers,
        'imposters': imposters,
        'rounds': rounds,
        'guessAttempts': guessAttempts,
        'category': category,
      };

  factory GameSettings.fromJson(Map<String, dynamic> json) {
    return GameSettings(
      maxPlayers: (json['maxPlayers'] as int?) ?? 6,
      imposters: (json['imposters'] as int?) ?? 1,
      rounds: (json['rounds'] as int?) ?? 2,
      guessAttempts: (json['guessAttempts'] as int?) ?? 1,
      category: (json['category'] as String?) ?? 'Random',
    );
  }
}
