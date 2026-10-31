sealed class GamePhase {
  const GamePhase();

  String get name;
  Map<String, dynamic> toJson();
}

class LobbyPhase extends GamePhase {
  const LobbyPhase();

  @override
  String get name => 'lobby';

  @override
  Map<String, dynamic> toJson() => {'name': name};
}

class RoleRevealPhase extends GamePhase {
  const RoleRevealPhase();

  @override
  String get name => 'roleReveal';

  @override
  Map<String, dynamic> toJson() => {'name': name};
}

class DiscussionPhase extends GamePhase {
  const DiscussionPhase({
    required this.round,
    required this.turnIndex,
  });

  final int round;
  final int turnIndex;

  @override
  String get name => 'discussion';

  @override
  Map<String, dynamic> toJson() => {
        'name': name,
        'round': round,
        'turnIndex': turnIndex,
      };
}

class AccusationPendingPhase extends GamePhase {
  const AccusationPendingPhase({
    this.accuserId,
    required this.targetId,
    required this.isFinalVote,
    required this.previousPhase,
  });

  final String? accuserId;
  final String targetId;
  final bool isFinalVote;
  final GamePhase previousPhase;

  @override
  String get name => 'accusationPending';

  @override
  Map<String, dynamic> toJson() => {
        'name': name,
        'accuserId': accuserId,
        'targetId': targetId,
        'isFinalVote': isFinalVote,
      };
}

class FinalVotePhase extends GamePhase {
  const FinalVotePhase({
    required this.voteRound,
  });

  final int voteRound;

  @override
  String get name => 'finalVote';

  @override
  Map<String, dynamic> toJson() => {
        'name': name,
        'voteRound': voteRound,
      };
}

class EndedPhase extends GamePhase {
  const EndedPhase({
    required this.winner,
    required this.reason,
    required this.secretWord,
    required this.category,
  });

  /// 'normal' or 'imposter'
  final String winner;
  final String reason;
  final String secretWord;
  final String category;

  @override
  String get name => 'ended';

  @override
  Map<String, dynamic> toJson() => {
        'name': name,
        'winner': winner,
        'reason': reason,
        'secretWord': secretWord,
        'category': category,
      };
}
