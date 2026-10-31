import 'accusation_result.dart';
import 'game_clue.dart';
import 'game_phase.dart';
import 'game_player.dart';
import 'game_settings.dart';

class GameState {
  const GameState({
    required this.players,
    required this.speakingOrder,
    required this.currentPhase,
    required this.settings,
    required this.secretWord,
    required this.category,
    this.clues = const [],
    this.lastAccusationResult,
  });

  final List<GamePlayer> players;
  final List<String> speakingOrder;
  final GamePhase currentPhase;
  final GameSettings settings;
  final String secretWord;
  final String category;
  final List<GameClue> clues;
  final AccusationResult? lastAccusationResult;

  List<GamePlayer> get alivePlayers =>
      players.where((p) => p.isAlive).toList();

  List<GamePlayer> get imposters =>
      players.where((p) => p.isImposter).toList();

  List<GamePlayer> get aliveImposters =>
      players.where((p) => p.isImposter && p.isAlive).toList();

  List<GamePlayer> get aliveNormals =>
      players.where((p) => p.isNormal && p.isAlive).toList();

  GamePlayer? getPlayer(String id) {
    try {
      return players.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  String? get currentSpeakerId {
    if (currentPhase is! DiscussionPhase) return null;
    final disc = currentPhase as DiscussionPhase;
    if (speakingOrder.isEmpty) return null;

    final candidateId = speakingOrder[disc.turnIndex % speakingOrder.length];
    final p = getPlayer(candidateId);
    if (p != null && p.isAlive) {
      return candidateId;
    }

    // If candidate is eliminated, find next alive player in speaking order
    for (var i = 1; i < speakingOrder.length; i++) {
      final nextId =
          speakingOrder[(disc.turnIndex + i) % speakingOrder.length];
      final nextP = getPlayer(nextId);
      if (nextP != null && nextP.isAlive) {
        return nextId;
      }
    }
    return null;
  }

  GameState copyWith({
    List<GamePlayer>? players,
    List<String>? speakingOrder,
    GamePhase? currentPhase,
    GameSettings? settings,
    String? secretWord,
    String? category,
    List<GameClue>? clues,
    AccusationResult? lastAccusationResult,
  }) {
    return GameState(
      players: players ?? this.players,
      speakingOrder: speakingOrder ?? this.speakingOrder,
      currentPhase: currentPhase ?? this.currentPhase,
      settings: settings ?? this.settings,
      secretWord: secretWord ?? this.secretWord,
      category: category ?? this.category,
      clues: clues ?? this.clues,
      lastAccusationResult: lastAccusationResult ?? this.lastAccusationResult,
    );
  }
}
