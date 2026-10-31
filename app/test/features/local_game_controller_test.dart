import 'package:flutter_test/flutter_test.dart';
import 'package:sus/engine/models/game_phase.dart';
import 'package:sus/features/local_game/presentation/local_game_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('LocalGameNotifier initializes local game flow through handover and discussion', () async {
    final notifier = LocalGameNotifier();

    await notifier.startLocalGame(
      playerNames: ['Alice', 'Bob', 'Charlie'],
      imposters: 1,
      rounds: 1,
      guessAttempts: 1,
      category: 'Objects & Food',
    );

    expect(notifier.state, isNotNull);
    expect(notifier.state!.gameState.players.length, 3);
    expect(notifier.state!.handoverPlayerIndex, 0);
    expect(notifier.state!.isCardRevealedToPlayer, isFalse);

    // Player 1 seen
    notifier.onPlayerAcknowledgedHandover();
    expect(notifier.state!.isCardRevealedToPlayer, isTrue);

    // Pass to Player 2
    notifier.onNextPlayerHandover();
    expect(notifier.state!.handoverPlayerIndex, 1);
    expect(notifier.state!.isCardRevealedToPlayer, isFalse);

    // Player 2 seen
    notifier.onPlayerAcknowledgedHandover();
    notifier.onNextPlayerHandover();
    expect(notifier.state!.handoverPlayerIndex, 2);

    // Player 3 seen (last player)
    notifier.onPlayerAcknowledgedHandover();
    notifier.onNextPlayerHandover();

    // Discussion started!
    expect(notifier.state!.gameState.currentPhase, isA<DiscussionPhase>());
  });
}
