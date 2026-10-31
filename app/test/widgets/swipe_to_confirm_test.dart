import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sus/core/theme/sus_colors.dart';
import 'package:sus/core/widgets/swipe_to_confirm.dart';

void main() {
  testWidgets('SwipeToConfirm renders label and triggers onConfirm on full drag', (tester) async {
    bool confirmed = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          extensions: const [SusColors.dark],
        ),
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 300,
              child: SwipeToConfirm(
                label: 'Confirm Action',
                onConfirm: () => confirmed = true,
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Confirm Action'), findsOneWidget);
    expect(confirmed, isFalse);

    // Find knob
    final knobFinder = find.text('›');
    expect(knobFinder, findsOneWidget);

    // Drag right 280 pixels
    await tester.drag(knobFinder, const Offset(280, 0));
    await tester.pumpAndSettle();

    expect(confirmed, isTrue);
  });

  testWidgets('SwipeToConfirm does not trigger when disabled', (tester) async {
    bool confirmed = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          extensions: const [SusColors.dark],
        ),
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 300,
              child: SwipeToConfirm(
                label: 'Disabled Action',
                enabled: false,
                onConfirm: () => confirmed = true,
              ),
            ),
          ),
        ),
      ),
    );

    final knobFinder = find.text('›');
    await tester.drag(knobFinder, const Offset(280, 0));
    await tester.pumpAndSettle();

    expect(confirmed, isFalse);
  });

  testWidgets('SwipeToConfirm springs back on partial drag without confirming', (tester) async {
    bool confirmed = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          extensions: const [SusColors.dark],
        ),
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 300,
              child: SwipeToConfirm(
                label: 'Confirm Action',
                onConfirm: () => confirmed = true,
              ),
            ),
          ),
        ),
      ),
    );

    final knobFinder = find.text('›');
    final initialKnobRect = tester.getRect(knobFinder);

    // Drag halfway (80 px) and release
    await tester.drag(knobFinder, const Offset(80, 0));
    // Animation kicks in to spring back
    await tester.pumpAndSettle();

    expect(confirmed, isFalse);
    final settledKnobRect = tester.getRect(knobFinder);
    expect(settledKnobRect.left, closeTo(initialKnobRect.left, 0.5));
  });
}
