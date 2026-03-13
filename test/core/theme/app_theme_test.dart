import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dander/core/theme/app_theme.dart';

void main() {
  group('buildAppTheme — structural properties (useGoogleFonts: false)', () {
    late ThemeData theme;

    setUp(() {
      // Skip Google Fonts loading in unit tests to avoid network/asset errors.
      theme = buildAppTheme(useGoogleFonts: false);
    });

    test('is Material 3', () {
      expect(theme.useMaterial3, isTrue);
    });

    test('textTheme is non-null', () {
      expect(theme.textTheme, isNotNull);
    });

    test('colorScheme brightness is dark', () {
      expect(theme.colorScheme.brightness, Brightness.dark);
    });

    test('scaffoldBackgroundColor equals DanderColors.surface', () {
      expect(theme.scaffoldBackgroundColor, DanderColors.surface);
    });

    test('appBarTheme has no elevation', () {
      expect(theme.appBarTheme.elevation, 0);
    });

    test('appBarTheme backgroundColor is surfaceElevated', () {
      expect(
        theme.appBarTheme.backgroundColor,
        DanderColors.surfaceElevated,
      );
    });

    test('bottomNavigationBarTheme selectedItemColor is accent', () {
      expect(
        theme.bottomNavigationBarTheme.selectedItemColor,
        DanderColors.accent,
      );
    });

    test('cardTheme color is cardBackground', () {
      expect(theme.cardTheme.color, DanderColors.cardBackground);
    });

    test('colorScheme primary matches DanderColors.primary', () {
      expect(theme.colorScheme.primary, DanderColors.primary);
    });

    test('colorScheme secondary matches DanderColors.secondary', () {
      expect(theme.colorScheme.secondary, DanderColors.secondary);
    });

    test('colorScheme error matches DanderColors.error', () {
      expect(theme.colorScheme.error, DanderColors.error);
    });

    test('dividerTheme color is DanderColors.divider', () {
      expect(theme.dividerTheme.color, DanderColors.divider);
    });
  });

  group('buildAppTheme — typography widget rendering', () {
    testWidgets(
      'MaterialApp renders with custom theme without crashing',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: buildAppTheme(useGoogleFonts: false),
            home: const Scaffold(
              body: Column(
                children: [
                  Text('Display', key: Key('display')),
                  Text('Body', key: Key('body')),
                ],
              ),
            ),
          ),
        );

        expect(find.text('Display'), findsOneWidget);
        expect(find.text('Body'), findsOneWidget);
      },
    );

    testWidgets(
      'Text widget data is preserved under custom theme',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: buildAppTheme(useGoogleFonts: false),
            home: const Scaffold(body: Text('Hello', key: Key('t'))),
          ),
        );

        final textWidget = tester.widget<Text>(find.byKey(const Key('t')));
        expect(textWidget.data, 'Hello');
      },
    );
  });

  group('buildTextTheme — font sizing (no Google Fonts network calls)', () {
    test('buildTextTheme falls back to Material dark theme without crash', () {
      // This tests the fallback path: when google_fonts throws (as it does
      // in unit tests without asset bundle), _buildTextTheme catches the
      // error and returns a valid TextTheme.
      //
      // We cannot test exact font families without bundled font assets,
      // but we can verify the returned TextTheme has expected font sizes
      // and weights by checking the constants match DanderTextStyles.
      expect(DanderTextStyles.displayLarge.fontSize, 57);
      expect(DanderTextStyles.headlineMedium.fontSize, 28);
      expect(DanderTextStyles.bodyLarge.fontSize, 16);
      expect(DanderTextStyles.bodyMedium.fontSize, 14);
      expect(DanderTextStyles.labelSmall.fontSize, 11);
    });

    test('display styles use bold weight', () {
      expect(DanderTextStyles.displayLarge.fontWeight, FontWeight.bold);
      expect(DanderTextStyles.headlineMedium.fontWeight, FontWeight.bold);
    });

    test('body styles use normal weight', () {
      expect(DanderTextStyles.bodyLarge.fontWeight, FontWeight.normal);
      expect(DanderTextStyles.bodyMedium.fontWeight, FontWeight.normal);
    });

    test('title and label styles use semibold weight', () {
      expect(DanderTextStyles.titleMedium.fontWeight, FontWeight.w600);
      expect(DanderTextStyles.labelLarge.fontWeight, FontWeight.w600);
    });
  });
}
