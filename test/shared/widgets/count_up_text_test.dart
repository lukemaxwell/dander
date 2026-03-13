import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dander/shared/widgets/count_up_text.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('CountUpText — basic rendering', () {
    testWidgets('renders without throwing', (tester) async {
      await tester.pumpWidget(_wrap(const CountUpText(value: 42)));
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.byType(CountUpText), findsOneWidget);
    });

    testWidgets('shows target value after animation completes', (tester) async {
      await tester.pumpWidget(_wrap(const CountUpText(value: 100)));
      await tester.pumpAndSettle();
      expect(find.text('100'), findsAtLeastNWidgets(1));
    });

    testWidgets('shows 0 at start for non-zero target', (tester) async {
      await tester.pumpWidget(_wrap(const CountUpText(value: 50)));
      // At pump zero the text should start from 0
      expect(find.text('0'), findsAtLeastNWidgets(1));
      await tester.pumpAndSettle();
    });

    testWidgets('shows 0 when value is 0', (tester) async {
      await tester.pumpWidget(_wrap(const CountUpText(value: 0)));
      await tester.pumpAndSettle();
      expect(find.text('0'), findsAtLeastNWidgets(1));
    });

    testWidgets('respects custom text style', (tester) async {
      const style = TextStyle(fontSize: 32, color: Colors.red);
      await tester.pumpWidget(_wrap(const CountUpText(value: 5, style: style)));
      await tester.pumpAndSettle();
      final text = tester.widget<Text>(find.byType(Text).first);
      expect(text.style?.fontSize, equals(32.0));
    });
  });

  group('CountUpText — animation', () {
    testWidgets('value increases over time', (tester) async {
      await tester.pumpWidget(_wrap(const CountUpText(value: 100)));
      // Advance halfway through the default 500ms duration
      await tester.pump(const Duration(milliseconds: 250));
      // The displayed value should be somewhere between 0 and 100
      final texts = tester
          .widgetList<Text>(find.byType(Text))
          .map((t) => int.tryParse(t.data ?? ''))
          .where((v) => v != null)
          .toList();
      final anyMid = texts.any((v) => v! > 0 && v < 100);
      expect(anyMid, isTrue,
          reason: 'Expected an intermediate value during count-up animation');
      await tester.pump(const Duration(milliseconds: 300));
    });

    testWidgets('reaches target value when animation ends', (tester) async {
      await tester.pumpWidget(_wrap(const CountUpText(value: 25)));
      await tester.pump(const Duration(milliseconds: 500));
      // Allow one more pump to settle
      await tester.pump();
      expect(find.text('25'), findsAtLeastNWidgets(1));
    });
  });

  group('CountUpText — suffix', () {
    testWidgets('appends suffix to displayed value', (tester) async {
      await tester.pumpWidget(_wrap(const CountUpText(value: 42, suffix: '%')));
      await tester.pumpAndSettle();
      expect(find.text('42%'), findsAtLeastNWidgets(1));
    });
  });
}
