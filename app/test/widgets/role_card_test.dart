import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sus/core/theme/sus_colors.dart';
import 'package:sus/core/widgets/role_card.dart';

void main() {
  testWidgets('RoleCard hides secret initially and reveals on press down', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          extensions: const [SusColors.dark],
        ),
        home: const Scaffold(
          body: Center(
            child: RoleCard(
              isImposter: false,
              category: 'Objects & Food',
              secretWord: 'Pineapple',
            ),
          ),
        ),
      ),
    );

    expect(find.text('Hold to reveal'), findsOneWidget);
    expect(find.text('Pineapple'), findsNothing);

    // Hold down pointer
    final gesture = await tester.startGesture(tester.getCenter(find.text('Hold to reveal')));
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text('Pineapple'), findsOneWidget);
    expect(find.text('Category: Objects & Food'), findsOneWidget);

    // Release pointer
    await gesture.up();
    await tester.pumpAndSettle();

    expect(find.text('Hold to reveal'), findsOneWidget);
    expect(find.text('Pineapple'), findsNothing);
  });

  testWidgets('RoleCard displays IMPOSTER when player is imposter', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          extensions: const [SusColors.dark],
        ),
        home: const Scaffold(
          body: Center(
            child: RoleCard(
              isImposter: true,
              category: 'Animals',
            ),
          ),
        ),
      ),
    );

    final gesture = await tester.startGesture(tester.getCenter(find.text('Hold to reveal')));
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text('IMPOSTER'), findsOneWidget);
    expect(find.text('Category: Animals'), findsOneWidget);

    await gesture.up();
    await tester.pumpAndSettle();
  });
}
