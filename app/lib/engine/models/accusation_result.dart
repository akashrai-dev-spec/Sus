import 'game_player.dart';

enum AccusationOutcome {
  caught,
  innocentFail,
  imposterGuessed,
}

class AccusationResult {
  const AccusationResult({
    this.accuserId,
    required this.targetId,
    required this.revealedRole,
    required this.outcome,
    required this.isFinalVote,
    this.roleReverse = false,
  });

  final String? accuserId;
  final String targetId;
  final PlayerRole revealedRole;
  final AccusationOutcome outcome;
  final bool isFinalVote;
  final bool roleReverse;

  Map<String, dynamic> toJson() => {
        if (accuserId != null) 'accuserId': accuserId,
        'targetId': targetId,
        'revealedRole': revealedRole.name,
        'outcome': outcome.name,
        'isFinalVote': isFinalVote,
        'roleReverse': roleReverse,
      };

  factory AccusationResult.fromJson(Map<String, dynamic> json) {
    return AccusationResult(
      accuserId: json['accuserId'] as String?,
      targetId: json['targetId'] as String,
      revealedRole: PlayerRole.values.byName(json['revealedRole'] as String),
      outcome: AccusationOutcome.values.byName(json['outcome'] as String),
      isFinalVote: (json['isFinalVote'] as bool?) ?? false,
      roleReverse: (json['roleReverse'] as bool?) ?? false,
    );
  }
}
