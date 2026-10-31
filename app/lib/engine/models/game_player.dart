enum PlayerRole {
  normal,
  imposter,
}

class GamePlayer {
  const GamePlayer({
    required this.id,
    required this.name,
    this.color = '#9A0F28',
    this.role,
    this.isAlive = true,
    this.isHost = false,
    this.usedAccusation = false,
    this.remainingGuesses = 1,
    this.isReady = false,
  });

  final String id;
  final String name;
  final String color;
  final PlayerRole? role;
  final bool isAlive;
  final bool isHost;
  final bool usedAccusation;
  final int remainingGuesses;
  final bool isReady;

  bool get isImposter => role == PlayerRole.imposter;
  bool get isNormal => role == PlayerRole.normal;

  GamePlayer copyWith({
    String? id,
    String? name,
    String? color,
    PlayerRole? role,
    bool? isAlive,
    bool? isHost,
    bool? usedAccusation,
    int? remainingGuesses,
    bool? isReady,
  }) {
    return GamePlayer(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      role: role ?? this.role,
      isAlive: isAlive ?? this.isAlive,
      isHost: isHost ?? this.isHost,
      usedAccusation: usedAccusation ?? this.usedAccusation,
      remainingGuesses: remainingGuesses ?? this.remainingGuesses,
      isReady: isReady ?? this.isReady,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'color': color,
        if (role != null) 'role': role!.name,
        'isAlive': isAlive,
        'isHost': isHost,
        'usedAccusation': usedAccusation,
        'remainingGuesses': remainingGuesses,
        'isReady': isReady,
      };

  factory GamePlayer.fromJson(Map<String, dynamic> json) {
    return GamePlayer(
      id: json['id'] as String,
      name: json['name'] as String,
      color: (json['color'] as String?) ?? '#9A0F28',
      role: json['role'] != null
          ? PlayerRole.values.byName(json['role'] as String)
          : null,
      isAlive: (json['isAlive'] as bool?) ?? true,
      isHost: (json['isHost'] as bool?) ?? false,
      usedAccusation: (json['usedAccusation'] as bool?) ?? false,
      remainingGuesses: (json['remainingGuesses'] as int?) ?? 1,
      isReady: (json['isReady'] as bool?) ?? false,
    );
  }
}
