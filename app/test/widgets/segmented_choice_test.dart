import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sus/core/theme/sus_colors.dart';
import 'package:sus/core/widgets/segmented_choice.dart';

void main() {
  testWidgets('SegmentedChoice selects active option and triggers callback', (tester) async {
    int selected = 1;

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: const [SusColors.dark]),
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              return SegmentedChoice<int>(
                options: const [1, 2, 3],
                selected: selected,
                onChanged: (val) {
                  setState(() => selected = val);
                },
              );
            },
          ),
        ),
      ),
    );

    expect(find.text('1'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);

    await tester.tap(find.text('2'));
    await tester.pumpAndSettle();

    expect(selected, 2);
  });
}
