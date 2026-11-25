import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:market_space/app/safe_vertical_caret_actions.dart';

void main() {
  testWidgets(
    'does not throw VerticalCaretMovementRun isValid assertion on RTL TextField arrow down/up',
    (WidgetTester tester) async {
      final controller = TextEditingController(text: 'مرحبا');
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => SafeVerticalCaretActions(
            child: child ?? const SizedBox.shrink(),
          ),
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              body: TextField(
                controller: controller,
                autofocus: true,
                textDirection: TextDirection.rtl,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();

      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'preserves vertical caret movement in LTR multiline TextField',
    (WidgetTester tester) async {
      final controller = TextEditingController(text: 'first\nsecond');
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => SafeVerticalCaretActions(
            child: child ?? const SizedBox.shrink(),
          ),
          home: Scaffold(
            body: TextField(
              controller: controller,
              autofocus: true,
              maxLines: 3,
            ),
          ),
        ),
      );
      await tester.pump();

      controller.selection = const TextSelection.collapsed(offset: 1);
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(controller.selection.baseOffset, greaterThan(5));
    },
  );
}
