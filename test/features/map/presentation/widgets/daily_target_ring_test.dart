import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dander/core/progress/daily_target.dart';
import 'package:dander/features/map/presentation/widgets/daily_target_ring.dart';

Widget _wrap(Widget child) => MaterialApp(
      home: Scaffold(body: child),
    );

void main() {
  group('DailyTargetRing', () {
    testWidgets('renders with 0/1 when no streets walked', (tester) async {
      final target = DailyTarget.empty();
      await tester.pumpWidget(_wrap(DailyTargetRing(target: target)));
      expect(find.textContaining('0'), findsWidgets);
    });

    testWidgets('renders with 1/1 when target met', (tester) async {
      final target = DailyTarget(
        streetsToday: 1,
        target: 1,
        lastResetDate: DateTime.now(),
      );
      await tester.pumpWidget(_wrap(DailyTargetRing(target: target)));
      expect(find.textContaining('1'), findsWidgets);
    });

    testWidgets('shows CustomPaint for the ring', (tester) async {
      final target = DailyTarget.empty();
      await tester.pumpWidget(_wrap(DailyTargetRing(target: target)));
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('renders without error when target exceeded', (tester) async {
      final target = DailyTarget(
        streetsToday: 5,
        target: 1,
        lastResetDate: DateTime.now(),
      );
      await tester.pumpWidget(_wrap(DailyTargetRing(target: target)));
      expect(tester.takeException(), isNull);
    });

    testWidgets('shows label text', (tester) async {
      final target = DailyTarget.empty();
      await tester.pumpWidget(_wrap(DailyTargetRing(target: target)));
      expect(find.textContaining('street'), findsWidgets);
    });
  });
}
