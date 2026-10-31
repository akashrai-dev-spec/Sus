import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/name_generator.dart';
import '../../../engine/game_engine.dart';
import '../../../engine/models/game_player.dart';
import '../../../engine/models/game_settings.dart';
import '../../../engine/models/game_state.dart';

class LocalGameProgress {
  const LocalGameProgress({
    required this.gameState,
    this.handoverPlayerIndex = 0,
    this.isCardRevealedToPlayer = false,
  });

  final GameState gameState;
  final int handoverPlayerIndex;
  final bool isCardRevealedToPlayer;

  LocalGameProgress copyWith({
    GameState? gameState,
    int? handoverPlayerIndex,
    bool? isCardRevealedToPlayer,
  }) {
    return LocalGameProgress(
      gameState: gameState ?? this.gameState,
      handoverPlayerIndex: handoverPlayerIndex ?? this.handoverPlayerIndex,
      isCardRevealedToPlayer: isCardRevealedToPlayer ?? this.isCardRevealedToPlayer,
    );
  }
}

final localGameControllerProvider =
    StateNotifierProvider<LocalGameNotifier, LocalGameProgress?>((ref) {
  return LocalGameNotifier();
});

class LocalGameNotifier extends StateNotifier<LocalGameProgress?> {
  LocalGameNotifier() : super(null);

  Map<String, dynamic>? _cachedWordBank;

  Future<void> _ensureWordBankLoaded() async {
    if (_cachedWordBank != null) return;
    try {
      final jsonStr = await rootBundle.loadString('assets/words/words.json');
      _cachedWordBank = jsonDecode(jsonStr) as Map<String, dynamic>;
    } catch (_) {
      _cachedWordBank = {
        'Objects & Food': {
          'Apple': ['Red or green fruit', 'Grows on trees'],
          'Pizza': ['Cheesy round pie', 'Cut into triangles'],
        },
      };
    }
  }

  Future<void> startLocalGame({
    required List<String> playerNames,
    required int imposters,
    required int rounds,
    required int guessAttempts,
    required String category,
    String? customWord,
    String? customCategory,
  }) async {
    await _ensureWordBankLoaded();

    final String chosenCategory;
    final String chosenWord;

    if (category == 'Custom' && customWord != null && customWord.trim().isNotEmpty) {
      chosenCategory = (customCategory != null && customCategory.trim().isNotEmpty)
          ? customCategory.trim()
          : 'Custom';
      chosenWord = customWord.trim();
    } else {
      final secureRng = math.Random.secure();
      final categories = _cachedWordBank!.keys.toList();
      chosenCategory = category == 'Random' || !_cachedWordBank!.containsKey(category)
          ? categories[secureRng.nextInt(categories.length)]
          : category;

      final wordsMap = _cachedWordBank![chosenCategory] as Map<String, dynamic>;
      final words = wordsMap.keys.toList();
      chosenWord = words[secureRng.nextInt(words.length)];
    }

    final players = playerNames.asMap().entries.map((e) {
      final i = e.key;
      final name = e.value;
      return GamePlayer(
        id: 'local-p$i',
        name: name,
        color: NameGenerator.colors[i % NameGenerator.colors.length],
        isAlive: true,
        isHost: i == 0,
        usedAccusation: false,
        remainingGuesses: guessAttempts,
        isReady: false,
      );
    }).toList();

    final settings = GameSettings(
      maxPlayers: players.length,
      imposters: imposters,
      rounds: rounds,
      guessAttempts: guessAttempts,
      category: chosenCategory,
    );

    final gameState = GameEngine.startGame(
      players: players,
      settings: settings,
      secretWord: chosenWord,
      category: chosenCategory,
    );

    state = LocalGameProgress(
      gameState: gameState,
      handoverPlayerIndex: 0,
      isCardRevealedToPlayer: false,
    );
  }

  void onPlayerAcknowledgedHandover() {
    if (state == null) return;
    state = state!.copyWith(isCardRevealedToPlayer: true);
  }

  void onNextPlayerHandover() {
    if (state == null) return;
    final totalPlayers = state!.gameState.players.length;
    final nextIdx = state!.handoverPlayerIndex + 1;

    if (nextIdx >= totalPlayers) {
      // All players have seen their role -> start discussion!
      final discState = GameEngine.startDiscussion(state!.gameState);
      state = state!.copyWith(
        gameState: discState,
        handoverPlayerIndex: nextIdx,
        isCardRevealedToPlayer: false,
      );
    } else {
      state = state!.copyWith(
        handoverPlayerIndex: nextIdx,
        isCardRevealedToPlayer: false,
      );
    }
  }

  void nextSpeaker() {
    if (state == null) return;
    final nextState = GameEngine.nextSpeaker(state!.gameState);
    state = state!.copyWith(gameState: nextState);
  }

  void accuse({String? accuserId, required String targetId}) {
    if (state == null) return;
    final pendingState = GameEngine.submitAccusation(
      state!.gameState,
      accuserId: accuserId,
      targetId: targetId,
    );
    final resolvedState = GameEngine.resolveAccusation(pendingState);
    state = state!.copyWith(gameState: resolvedState);
  }

  bool imposterGuess({required String playerId, required String word}) {
    if (state == null) return false;
    final prevPhase = state!.gameState.currentPhase.name;
    final updated = GameEngine.imposterGuess(
      state!.gameState,
      playerId: playerId,
      word: word,
    );
    state = state!.copyWith(gameState: updated);

    return updated.currentPhase.name == 'ended' && prevPhase != 'ended';
  }

  void restartGame() {
    if (state == null) return;
    final playerNames = state!.gameState.players.map((p) => p.name).toList();
    final settings = state!.gameState.settings;
    startLocalGame(
      playerNames: playerNames,
      imposters: settings.imposters,
      rounds: settings.rounds,
      guessAttempts: settings.guessAttempts,
      category: settings.category,
    );
  }
}
