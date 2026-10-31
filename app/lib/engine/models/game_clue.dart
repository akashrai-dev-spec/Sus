class GameClue {
  const GameClue({
    required this.playerId,
    required this.text,
    required this.timestamp,
  });

  final String playerId;
  final String text;
  final DateTime timestamp;

  Map<String, dynamic> toJson() => {
        'playerId': playerId,
        'text': text,
        'timestamp': timestamp.toIso8601String(),
      };

  factory GameClue.fromJson(Map<String, dynamic> json) {
    return GameClue(
      playerId: json['playerId'] as String,
      text: json['text'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}
