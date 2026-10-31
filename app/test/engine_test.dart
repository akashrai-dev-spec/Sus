import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sus/engine/engine_exceptions.dart';
import 'package:sus/engine/game_engine.dart';
import 'package:sus/engine/models/game_phase.dart';
import 'package:sus/engine/models/game_player.dart';
import 'package:sus/engine/models/game_settings.dart';
import 'package:sus/engine/word_filter.dart';

void main() {
  group('WordFilter', () {
    test('detects exact, punctuated, and case-varied secret word', () {
      expect(WordFilter.containsSecretWord('I love Apple', 'Apple'), isTrue);
      expect(WordFilter.containsSecretWord('APPLE!', 'Apple'), isTrue);
      expect(WordFilter.containsSecretWord('Is it an apple...?', 'Apple'), isTrue);
      expect(WordFilter.containsSecretWord('Just red fruit', 'Apple'), isFalse);
      expect(WordFilter.containsSecretWord('Baking a pizza pie', 'Pizza'), isTrue);
      expect(WordFilter.containsSecretWord('Baked in an oven', 'Pizza'), isFalse);
    });
  });

  group('GameSettings imposter cap', () {
    test('accurately calculates capped imposters for all group sizes', () {
      expect(GameSettings.calculateCappedImposters(3, 3), equals(1));
      expect(GameSettings.calculateCappedImposters(3, 4), equals(1));
      expect(GameSettings.calculateCappedImposters(3, 5), equals(2));
      expect(GameSettings.calculateCappedImposters(3, 6), equals(2));
      expect(GameSettings.calculateCappedImposters(3, 8), equals(3));
      expect(GameSettings.calculateCappedImposters(3, 12), equals(3));
    });
  });

  group('GameEngine Core Rules', () {
    test('enforces player counts 3 to 12', () {
      final twoPlayers = [
        const GamePlayer(id: '1', name: 'A'),
        const GamePlayer(id: '2', name: 'B'),
      ];
      expect(
        () => GameEngine.startGame(
          players: twoPlayers,
          settings: const GameSettings(),
          secretWord: 'Apple',
          category: 'Objects & Food',
        ),
        throwsA(isA<GameEngineException>()),
      );

      final thirteenPlayers = List.generate(
        13,
        (i) => GamePlayer(id: '$i', name: 'P$i'),
      );
      expect(
        () => GameEngine.startGame(
          players: thirteenPlayers,
          settings: const GameSettings(),
          secretWord: 'Apple',
          category: 'Objects & Food',
        ),
        throwsA(isA<GameEngineException>()),
      );
    });

    test('skips eliminated players in turn order', () {
      final players = [
        const GamePlayer(id: 'p1', name: 'P1', role: PlayerRole.normal),
        const GamePlayer(id: 'p2', name: 'P2', role: PlayerRole.normal),
        const GamePlayer(id: 'p3', name: 'P3', role: PlayerRole.imposter),
      ];
      var state = GameEngine.startGame(
        players: players,
        settings: const GameSettings(rounds: 2),
        secretWord: 'Apple',
        category: 'Food',
        customOrder: ['p1', 'p2', 'p3'],
        customImposterIds: ['p3'],
      );

      state = GameEngine.startDiscussion(state);
      expect(state.currentSpeakerId, 'p1');

      // Eliminate p2
      state = state.copyWith(
        players: state.players.map((p) => p.id == 'p2' ? p.copyWith(isAlive: false) : p).toList(),
      );

      // p1 submits clue -> next should be p3 (p2 skipped!)
      state = GameEngine.submitClue(state, playerId: 'p1', text: 'Sweet fruit');
      expect(state.currentSpeakerId, 'p3');
    });

    test('rejects clue with secret word from normal player', () {
      final players = [
        const GamePlayer(id: 'p1', name: 'P1', role: PlayerRole.normal),
        const GamePlayer(id: 'p2', name: 'P2', role: PlayerRole.imposter),
        const GamePlayer(id: 'p3', name: 'P3', role: PlayerRole.normal),
      ];
      var state = GameEngine.startGame(
        players: players,
        settings: const GameSettings(),
        secretWord: 'Apple',
        category: 'Food',
        customOrder: ['p1', 'p2', 'p3'],
        customImposterIds: ['p2'],
      );
      state = GameEngine.startDiscussion(state);

      expect(
        () => GameEngine.submitClue(state, playerId: 'p1', text: 'It is an Apple!'),
        throwsA(
          predicate(
            (e) => e is GameEngineException && e.code == 'WORD_FORBIDDEN',
          ),
        ),
      );
    });
  });

  group('Shared Fixture Replays', () {
    test('replay: innocent_accusation_and_imposter_guess.json', () {
      final file = File('../docs/fixtures/scenario_innocent_accusation_and_imposter_guess.json');
      final data = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;

      final rawPlayers = (data['players'] as List).map((p) {
        return GamePlayer(
          id: p['id'] as String,
          name: p['name'] as String,
          role: (p['role'] as String) == 'imposter'
              ? PlayerRole.imposter
              : PlayerRole.normal,
        );
      }).toList();

      final settings = GameSettings.fromJson(data['settings'] as Map<String, dynamic>);
      final imposterIds = rawPlayers.where((p) => p.isImposter).map((p) => p.id).toList();

      var state = GameEngine.startGame(
        players: rawPlayers,
        settings: settings,
        secretWord: data['secretWord'] as String,
        category: settings.category,
        customOrder: rawPlayers.map((p) => p.id).toList(),
        customImposterIds: imposterIds,
      );

      expect(state.currentPhase.name, 'roleReveal');

      // Ready all
      for (final p in rawPlayers) {
        state = GameEngine.markPlayerReady(state, p.id);
      }
      expect(state.currentPhase.name, 'discussion');
      expect(state.currentSpeakerId, 'p1');

      // p1 submits clue
      state = GameEngine.submitClue(state, playerId: 'p1', text: 'It can be red or green');
      expect(state.currentSpeakerId, 'p2');

      // p1 accuses p3 (innocent)
      state = GameEngine.submitAccusation(state, accuserId: 'p1', targetId: 'p3');
      expect(state.currentPhase.name, 'accusationPending');
      state = GameEngine.resolveAccusation(state);

      expect(state.currentPhase.name, 'discussion');
      final p1 = state.getPlayer('p1')!;
      final p3 = state.getPlayer('p3')!;
      expect(p1.usedAccusation, isTrue);
      expect(p3.isAlive, isTrue);

      // p2 (imposter) guesses word correctly
      state = GameEngine.imposterGuess(state, playerId: 'p2', word: 'Apple');
      expect(state.currentPhase, isA<EndedPhase>());
      final ended = state.currentPhase as EndedPhase;
      expect(ended.winner, 'imposter');
    });

    test('replay: imposter_caught_normals_win.json', () {
      final file = File('../docs/fixtures/scenario_imposter_caught_normals_win.json');
      final data = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;

      final rawPlayers = (data['players'] as List).map((p) {
        return GamePlayer(
          id: p['id'] as String,
          name: p['name'] as String,
          role: (p['role'] as String) == 'imposter'
              ? PlayerRole.imposter
              : PlayerRole.normal,
        );
      }).toList();

      final settings = GameSettings.fromJson(data['settings'] as Map<String, dynamic>);
      final imposterIds = rawPlayers.where((p) => p.isImposter).map((p) => p.id).toList();

      var state = GameEngine.startGame(
        players: rawPlayers,
        settings: settings,
        secretWord: data['secretWord'] as String,
        category: settings.category,
        customOrder: rawPlayers.map((p) => p.id).toList(),
        customImposterIds: imposterIds,
      );

      for (final p in rawPlayers) {
        state = GameEngine.markPlayerReady(state, p.id);
      }
      expect(state.currentPhase.name, 'discussion');

      // Clue
      state = GameEngine.submitClue(state, playerId: 'p1', text: 'It is baked in a very hot oven');
      expect(state.currentSpeakerId, 'p2');

      // p3 accuses p2 (imposter)
      state = GameEngine.submitAccusation(state, accuserId: 'p3', targetId: 'p2');
      state = GameEngine.resolveAccusation(state);

      expect(state.currentPhase, isA<EndedPhase>());
      final ended = state.currentPhase as EndedPhase;
      expect(ended.winner, 'normal');
      expect(ended.reason, 'Every imposter was caught.');
      expect(state.getPlayer('p2')!.isAlive, isFalse);
    });

    test('replay: final_vote_repeat_multi_imposter.json', () {
      final file = File('../docs/fixtures/scenario_final_vote_repeat_multi_imposter.json');
      final data = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;

      final rawPlayers = (data['players'] as List).map((p) {
        return GamePlayer(
          id: p['id'] as String,
          name: p['name'] as String,
          role: (p['role'] as String) == 'imposter'
              ? PlayerRole.imposter
              : PlayerRole.normal,
        );
      }).toList();

      final settings = GameSettings.fromJson(data['settings'] as Map<String, dynamic>);
      final imposterIds = rawPlayers.where((p) => p.isImposter).map((p) => p.id).toList();

      var state = GameEngine.startGame(
        players: rawPlayers,
        settings: settings,
        secretWord: data['secretWord'] as String,
        category: settings.category,
        customOrder: rawPlayers.map((p) => p.id).toList(),
        customImposterIds: imposterIds,
      );

      for (final p in rawPlayers) {
        state = GameEngine.markPlayerReady(state, p.id);
      }

      // Complete round (5 turns for 5 players)
      for (var i = 0; i < 5; i++) {
        state = GameEngine.nextSpeaker(state);
      }

      expect(state.currentPhase, isA<FinalVotePhase>());
      expect((state.currentPhase as FinalVotePhase).voteRound, 1);

      // Final accusation on p2 (imposter 1)
      state = GameEngine.submitAccusation(state, targetId: 'p2');
      state = GameEngine.resolveAccusation(state);

      // p2 is caught, but p4 remains -> repeats final vote!
      expect(state.currentPhase, isA<FinalVotePhase>());
      expect((state.currentPhase as FinalVotePhase).voteRound, 2);
      expect(state.getPlayer('p2')!.isAlive, isFalse);

      // Final accusation on p1 (innocent)
      state = GameEngine.submitAccusation(state, targetId: 'p1');
      state = GameEngine.resolveAccusation(state);

      // Innocent caught in final vote -> imposters win!
      expect(state.currentPhase, isA<EndedPhase>());
      final ended = state.currentPhase as EndedPhase;
      expect(ended.winner, 'imposter');
    });

    test('replay: word_filter_and_imposter_cap.json', () {
      final file = File('../docs/fixtures/scenario_word_filter_and_imposter_cap.json');
      final data = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;

      final capTests = data['imposterCapTests'] as List;
      for (final t in capTests) {
        final res = GameSettings.calculateCappedImposters(
          t['setting'] as int,
          t['players'] as int,
        );
        expect(res, equals(t['expectedCap']));
      }

      final filterTests = data['wordFilterTests'] as List;
      for (final t in filterTests) {
        final res = WordFilter.containsSecretWord(
          t['clue'] as String,
          t['secretWord'] as String,
        );
        expect(res, equals(t['expectedForbidden']));
      }
    });
  });
}
