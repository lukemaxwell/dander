import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dander/shared/widgets/dander_logo.dart';

void main() {
  group('DanderLogo widget', () {
    testWidgets('renders without crashing', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: DanderLogo()),
        ),
      );
      expect(find.byType(DanderLogo), findsOneWidget);
    });

    testWidgets('accepts a size parameter', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: DanderLogo(size: 80)),
        ),
      );
      expect(find.byType(DanderLogo), findsOneWidget);
    });

    testWidgets('renders in compact (small icon) mode', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: DanderLogo(size: 24, showWordmark: false)),
        ),
      );
      expect(find.byType(DanderLogo), findsOneWidget);
    });

    testWidgets('renders with wordmark by default', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: DanderLogo()),
        ),
      );
      // Wordmark text "Dander" should be visible
      expect(find.text('Dander'), findsOneWidget);
    });

    testWidgets('hides wordmark when showWordmark is false', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: DanderLogo(showWordmark: false)),
        ),
      );
      expect(find.text('Dander'), findsNothing);
    });

    testWidgets('logo mark uses a CustomPaint or Container', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: DanderLogo()),
        ),
      );
      // Should contain a CustomPaint for the compass/footprint motif
      expect(
        find.descendant(
          of: find.byType(DanderLogo),
          matching: find.byType(CustomPaint),
        ),
        findsAtLeastNWidgets(1),
      );
    });
  });

  group('DanderLogoMark', () {
    testWidgets('renders as a standalone logo mark', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: DanderLogoMark(size: 48)),
        ),
      );
      expect(find.byType(DanderLogoMark), findsOneWidget);
    });

    testWidgets('is wrapped in a SizedBox of correct dimensions',
        (tester) async {
      const size = 64.0;
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(child: DanderLogoMark(size: size)),
          ),
        ),
      );
      final sizedBox = tester.widget<SizedBox>(
        find
            .descendant(
              of: find.byType(DanderLogoMark),
              matching: find.byType(SizedBox),
            )
            .first,
      );
      expect(sizedBox.width, size);
      expect(sizedBox.height, size);
    });
  });
}
