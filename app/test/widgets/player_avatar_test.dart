import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sus/core/widgets/player_avatar.dart';

void main() {
  testWidgets('PlayerAvatar renders initial and reacts to tap', (tester) async {
    bool tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: PlayerAvatar(
              name: 'Sneaky Otter',
              colorHex: '#9A0F28',
              size: 50,
              onTap: () => tapped = true,
            ),
          ),
        ),
      ),
    );

    expect(find.text('S'), findsOneWidget);
    await tester.tap(find.byType(PlayerAvatar));
    expect(tapped, isTrue);
  });
}
