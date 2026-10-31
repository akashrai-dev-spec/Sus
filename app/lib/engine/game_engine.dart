import 'dart:math' as math;

import 'engine_exceptions.dart';
import 'models/accusation_result.dart';
import 'models/game_clue.dart';
import 'models/game_phase.dart';
import 'models/game_player.dart';
import 'models/game_settings.dart';
import 'models/game_state.dart';
import 'word_filter.dart';

class GameEngine {
  GameEngine._();

  /// Starts a new game from a list of players and settings.
  static GameState startGame({
    required List<GamePlayer> players,
    required GameSettings settings,
    required String secretWord,
    required String category,
    List<String>? customOrder,
    List<String>? customImposterIds,
  }) {
    if (players.length < 3 || players.length > 12) {
      throw const GameEngineException(
        'INVALID_PLAYER_COUNT',
        'Sus requires between 3 and 12 players.',
      );
    }

    final imposterCount = GameSettings.calculateCappedImposters(
      settings.imposters,
      players.length,
    );

    List<String> imposterIds;
    if (customImposterIds != null) {
      imposterIds = List.from(customImposterIds);
    } else {
      final shuffled = List<GamePlayer>.from(players)..shuffle(math.Random());
      imposterIds = shuffled.take(imposterCount).map((p) => p.id).toList();
    }

    final assignedPlayers = players.map((p) {
      final isImp = imposterIds.contains(p.id);
      return p.copyWith(
        role: isImp ? PlayerRole.imposter : PlayerRole.normal,
        isAlive: true,
        usedAccusation: false,
        remainingGuesses: settings.guessAttempts,
        isReady: false,
      );
    }).toList();

    List<String> order;
    if (customOrder != null) {
      order = List.from(customOrder);
    } else {
      order = assignedPlayers.map((p) => p.id).toList()..shuffle(math.Random());
    }

    return GameState(
      players: assignedPlayers,
      speakingOrder: order,
      currentPhase: const RoleRevealPhase(),
      settings: settings,
      secretWord: secretWord,
      category: category,
      clues: const [],
    );
  }

  /// Marks a player as ready after seeing their role.
  static GameState markPlayerReady(GameState state, String playerId) {
    if (state.currentPhase is! RoleRevealPhase) {
      throw const GameEngineException(
        'ILLEGAL_PHASE',
        'Cannot mark player ready outside role reveal phase.',
      );
    }

    final updatedPlayers = state.players.map((p) {
      if (p.id == playerId) {
        return p.copyWith(isReady: true);
      }
      return p;
    }).toList();

    final allReady = updatedPlayers.every((p) => p.isReady);
    final nextPhase = allReady
        ? const DiscussionPhase(round: 1, turnIndex: 0)
        : state.currentPhase;

    return state.copyWith(
      players: updatedPlayers,
      currentPhase: nextPhase,
    );
  }

  /// Directly transitions to discussion phase (e.g. for offline testing or when all ready)
  static GameState startDiscussion(GameState state) {
    return state.copyWith(
      currentPhase: const DiscussionPhase(round: 1, turnIndex: 0),
    );
  }

  /// Submits a clue on the current player's turn.
  static GameState submitClue(
    GameState state, {
    required String playerId,
    required String text,
    DateTime? timestamp,
  }) {
    if (state.currentPhase is! DiscussionPhase) {
      throw const GameEngineException(
        'ILLEGAL_PHASE',
        'Clues can only be submitted during the discussion phase.',
      );
    }

    final disc = state.currentPhase as DiscussionPhase;
    final currentSpeaker = state.currentSpeakerId;

    if (currentSpeaker != playerId) {
      throw const GameEngineException(
        'NOT_PLAYER_TURN',
        'It is not this player’s turn to give a clue.',
      );
    }

    final player = state.getPlayer(playerId);
    if (player == null || !player.isAlive) {
      throw const GameEngineException(
        'PLAYER_NOT_ALIVE',
        'Player is not alive to speak.',
      );
    }

    final cleanText = text.trim();
    if (cleanText.isEmpty || cleanText.length > 60) {
      throw const GameEngineException(
        'INVALID_CLUE_LENGTH',
        'Clue must be between 1 and 60 characters.',
      );
    }

    // Normal players cannot state the secret word
    if (player.isNormal &&
        WordFilter.containsSecretWord(cleanText, state.secretWord)) {
      throw const GameEngineException(
        'WORD_FORBIDDEN',
        'You cannot say the secret word.',
      );
    }

    final newClue = GameClue(
      playerId: playerId,
      text: cleanText,
      timestamp: timestamp ?? DateTime.now(),
    );

    final updatedClues = [...state.clues, newClue];

    return _advanceTurn(state.copyWith(clues: updatedClues), disc);
  }

  /// Advances turn without a clue (for Local mode out-loud speaking).
  static GameState nextSpeaker(GameState state) {
    if (state.currentPhase is! DiscussionPhase) {
      throw const GameEngineException(
        'ILLEGAL_PHASE',
        'Next speaker only valid during discussion.',
      );
    }
    return _advanceTurn(state, state.currentPhase as DiscussionPhase);
  }

  static GameState _advanceTurn(GameState state, DiscussionPhase disc) {
    final totalSpeakingOrder = state.speakingOrder.length;
    final maxTurns = totalSpeakingOrder * state.settings.rounds;

    var nextTurnIndex = disc.turnIndex + 1;

    // Skip dead players
    while (nextTurnIndex < maxTurns) {
      final candId =
          state.speakingOrder[nextTurnIndex % totalSpeakingOrder];
      final cand = state.getPlayer(candId);
      if (cand != null && cand.isAlive) {
        break;
      }
      nextTurnIndex++;
    }

    if (nextTurnIndex >= maxTurns) {
      // All discussion rounds complete -> Final vote!
      return state.copyWith(
        currentPhase: const FinalVotePhase(voteRound: 1),
      );
    }

    final nextRound = (nextTurnIndex ~/ totalSpeakingOrder) + 1;
    return state.copyWith(
      currentPhase: DiscussionPhase(
        round: math.min(nextRound, state.settings.rounds),
        turnIndex: nextTurnIndex,
      ),
    );
  }

  /// Triggers an accusation against a target player.
  static GameState submitAccusation(
    GameState state, {
    String? accuserId,
    required String targetId,
  }) {
    final phase = state.currentPhase;
    final isFinalVote = phase is FinalVotePhase;

    if (phase is! DiscussionPhase && !isFinalVote) {
      throw const GameEngineException(
        'ILLEGAL_PHASE',
        'Accusations can only be made during discussion or final vote.',
      );
    }

    final target = state.getPlayer(targetId);
    if (target == null || !target.isAlive) {
      throw const GameEngineException(
        'INVALID_TARGET',
        'Target player is invalid or already eliminated.',
      );
    }

    if (accuserId != null) {
      if (accuserId == targetId) {
        throw const GameEngineException(
          'SELF_ACCUSATION',
          'Players cannot accuse themselves.',
        );
      }
      final accuser = state.getPlayer(accuserId);
      if (accuser == null || !accuser.isAlive) {
        throw const GameEngineException(
          'ACCUSER_NOT_ALIVE',
          'Accusing player is not alive.',
        );
      }
      if (!isFinalVote && accuser.usedAccusation) {
        throw const GameEngineException(
          'ACCUSATION_ALREADY_USED',
          'This player has already used their accusation this game.',
        );
      }
    }

    return state.copyWith(
      currentPhase: AccusationPendingPhase(
        accuserId: accuserId,
        targetId: targetId,
        isFinalVote: isFinalVote,
        previousPhase: phase,
      ),
    );
  }

  /// Resolves the pending accusation.
  static GameState resolveAccusation(GameState state) {
    if (state.currentPhase is! AccusationPendingPhase) {
      throw const GameEngineException(
        'ILLEGAL_PHASE',
        'No pending accusation to resolve.',
      );
    }

    final pend = state.currentPhase as AccusationPendingPhase;
    final target = state.getPlayer(pend.targetId)!;
    final isHit = target.isImposter;

    List<GamePlayer> updatedPlayers = state.players.map((p) {
      if (p.id == pend.targetId && isHit) {
        return p.copyWith(isAlive: false);
      }
      if (p.id == pend.accuserId && !isHit && !pend.isFinalVote) {
        return p.copyWith(usedAccusation: true);
      }
      return p;
    }).toList();

    final result = AccusationResult(
      accuserId: pend.accuserId,
      targetId: pend.targetId,
      revealedRole: target.role!,
      outcome: isHit
          ? AccusationOutcome.caught
          : AccusationOutcome.innocentFail,
      isFinalVote: pend.isFinalVote,
    );

    final remainingImposters =
        updatedPlayers.where((p) => p.isImposter && p.isAlive).toList();

    if (remainingImposters.isEmpty) {
      // Normals win!
      return state.copyWith(
        players: updatedPlayers,
        lastAccusationResult: result,
        currentPhase: EndedPhase(
          winner: 'normal',
          reason: 'Every imposter was caught.',
          secretWord: state.secretWord,
          category: state.category,
        ),
      );
    }

    if (pend.isFinalVote) {
      if (!isHit) {
        // Wrong final accusation -> Imposters win!
        return state.copyWith(
          players: updatedPlayers,
          lastAccusationResult: result,
          currentPhase: EndedPhase(
            winner: 'imposter',
            reason: 'The final accusation named the wrong player.',
            secretWord: state.secretWord,
            category: state.category,
          ),
        );
      } else {
        // Imposter was caught in final vote, but more imposters remain -> repeat final vote!
        final prevVote = pend.previousPhase is FinalVotePhase
            ? (pend.previousPhase as FinalVotePhase).voteRound
            : 1;
        return state.copyWith(
          players: updatedPlayers,
          lastAccusationResult: result,
          currentPhase: FinalVotePhase(voteRound: prevVote + 1),
        );
      }
    }

    // Normal discussion phase resumes
    return state.copyWith(
      players: updatedPlayers,
      lastAccusationResult: result,
      currentPhase: pend.previousPhase,
    );
  }

  /// Handles an imposter guessing the secret word.
  static GameState imposterGuess(
    GameState state, {
    required String playerId,
    required String word,
  }) {
    if (state.currentPhase is EndedPhase) {
      throw const GameEngineException(
        'GAME_ALREADY_ENDED',
        'Cannot guess word in an ended game.',
      );
    }

    final player = state.getPlayer(playerId);
    if (player == null || !player.isAlive) {
      throw const GameEngineException(
        'PLAYER_NOT_ALIVE',
        'Player is not alive.',
      );
    }

    if (player.remainingGuesses <= 0) {
      throw const GameEngineException(
        'NO_GUESSES_REMAINING',
        'No guess attempts remaining.',
      );
    }

    final updatedPlayers = state.players.map((p) {
      if (p.id == playerId) {
        return p.copyWith(remainingGuesses: p.remainingGuesses - 1);
      }
      return p;
    }).toList();

    // Check match
    final cleanGuess = word.trim().toLowerCase();
    final cleanSecret = state.secretWord.trim().toLowerCase();

    // Non-imposters always fail silently/neutrally to prevent leakage
    if (player.isImposter && cleanGuess == cleanSecret) {
      return state.copyWith(
        players: updatedPlayers,
        currentPhase: EndedPhase(
          winner: 'imposter',
          reason: '${player.name} guessed the word “${state.secretWord}”.',
          secretWord: state.secretWord,
          category: state.category,
        ),
      );
    }

    return state.copyWith(players: updatedPlayers);
  }
}
