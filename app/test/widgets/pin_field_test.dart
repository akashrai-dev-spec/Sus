import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sus/core/theme/sus_colors.dart';
import 'package:sus/core/widgets/pin_field.dart';

void main() {
  testWidgets('PinField updates when controller changes and calls onCompleted', (tester) async {
    String pin = '';
    String completed = '';
    final controller = TextEditingController();

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: const [SusColors.dark]),
        home: Scaffold(
          body: Center(
            child: PinField(
              controller: controller,
              onChanged: (val) => pin = val,
              onCompleted: (val) => completed = val,
            ),
          ),
        ),
      ),
    );

    controller.text = '1234';
    await tester.pump();

    expect(pin, '1234');
    expect(completed, '1234');
    expect(find.text('1'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('4'), findsOneWidget);
  });
}
