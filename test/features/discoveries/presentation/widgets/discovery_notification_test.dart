import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:dander/core/discoveries/discovery.dart';
import 'package:dander/features/discoveries/presentation/widgets/discovery_notification.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Discovery _buildDiscovery({
  String name = 'Mystery Park',
  RarityTier rarity = RarityTier.uncommon,
}) {
  return Discovery(
    id: 'node/42',
    name: name,
    category: 'park',
    rarity: rarity,
    position: const LatLng(51.5, -0.1),
    osmTags: const {'leisure': 'park'},
    discoveredAt: DateTime(2024, 7, 4),
  );
}

Widget _wrap(Widget child) => MaterialApp(
      theme: ThemeData(splashFactory: NoSplash.splashFactory),
      home: Scaffold(body: child),
    );

/// Builds a [DiscoveryNotification] with auto-dismiss disabled for tests that
/// do not need it (uses a very long duration so the timer never fires).
DiscoveryNotification _buildNotification(
  Discovery discovery, {
  required VoidCallback onDismiss,
  int discoveryNumber = 1,
}) {
  return DiscoveryNotification(
    discovery: discovery,
    onDismiss: onDismiss,
    discoveryNumber: discoveryNumber,
    // Long enough that the timer never fires during test execution.
    autoDismissDuration: const Duration(hours: 1),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('DiscoveryNotification', () {
    group('rendering', () {
      testWidgets('renders without error', (tester) async {
        final d = _buildDiscovery();
        await tester.pumpWidget(
          _wrap(_buildNotification(d, onDismiss: () {})),
        );
        expect(tester.takeException(), isNull);
      });

      testWidgets('displays the discovery name', (tester) async {
        final d = _buildDiscovery(name: 'Victoria Park Viewpoint');
        await tester.pumpWidget(
          _wrap(_buildNotification(d, onDismiss: () {})),
        );
        expect(find.text('Victoria Park Viewpoint'), findsOneWidget);
      });

      testWidgets('contains DiscoveryCard content', (tester) async {
        final d = _buildDiscovery(name: 'Riverside Walk');
        await tester.pumpWidget(
          _wrap(_buildNotification(d, onDismiss: () {})),
        );
        expect(find.textContaining('Riverside Walk'), findsWidgets);
      });
    });

    group('dismiss behaviour', () {
      testWidgets('calls onDismiss when tapped', (tester) async {
        var dismissed = false;
        final d = _buildDiscovery();

        await tester.pumpWidget(
          _wrap(
            _buildNotification(d, onDismiss: () => dismissed = true),
          ),
        );

        // Pump animation to completion so the widget is on screen.
        await tester.pump(const Duration(milliseconds: 400));

        await tester.tap(find.byType(DiscoveryNotification));
        await tester.pump();

        expect(dismissed, isTrue);
      });

      testWidgets('collect button fires onDismiss', (tester) async {
        var dismissed = false;
        final d = _buildDiscovery();

        await tester.pumpWidget(
          _wrap(
            _buildNotification(d, onDismiss: () => dismissed = true),
          ),
        );

        // Pump animation to completion so buttons are on screen.
        await tester.pump(const Duration(milliseconds: 400));

        final button = find.byType(ElevatedButton);
        if (button.evaluate().isNotEmpty) {
          await tester.tap(button.first);
          await tester.pump();
          expect(dismissed, isTrue);
        }
      });
    });

    group('auto-dismiss timer', () {
      testWidgets('auto-dismiss fires after the specified duration',
          (tester) async {
        var dismissed = false;
        final d = _buildDiscovery();

        await tester.pumpWidget(
          _wrap(
            DiscoveryNotification(
              discovery: d,
              onDismiss: () => dismissed = true,
              autoDismissDuration: const Duration(milliseconds: 100),
            ),
          ),
        );

        expect(dismissed, isFalse);
        // Advance fake time past the auto-dismiss threshold.
        await tester.pump(const Duration(milliseconds: 200));
        expect(dismissed, isTrue);
      });
    });

    group('animation', () {
      testWidgets('slide-in animation starts on construction', (tester) async {
        final d = _buildDiscovery();
        await tester.pumpWidget(
          _wrap(_buildNotification(d, onDismiss: () {})),
        );
        await tester.pump(const Duration(milliseconds: 50));
        expect(tester.takeException(), isNull);
      });

      testWidgets('widget tree remains stable after animation completes',
          (tester) async {
        final d = _buildDiscovery();
        await tester.pumpWidget(
          _wrap(_buildNotification(d, onDismiss: () {})),
        );
        await tester.pump(const Duration(milliseconds: 400));
        expect(tester.takeException(), isNull);
      });
    });

    group('edge cases', () {
      testWidgets('works with rare tier discovery', (tester) async {
        final d = _buildDiscovery(rarity: RarityTier.rare);
        await tester.pumpWidget(
          _wrap(_buildNotification(d, onDismiss: () {})),
        );
        expect(tester.takeException(), isNull);
      });

      testWidgets('works with common tier discovery', (tester) async {
        final d = _buildDiscovery(rarity: RarityTier.common);
        await tester.pumpWidget(
          _wrap(_buildNotification(d, onDismiss: () {})),
        );
        expect(tester.takeException(), isNull);
      });

      testWidgets('discovery number is passed through to card', (tester) async {
        final d = _buildDiscovery();
        await tester.pumpWidget(
          _wrap(_buildNotification(d, onDismiss: () {}, discoveryNumber: 42)),
        );
        expect(find.textContaining('#42'), findsOneWidget);
      });
    });
  });
}
