import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:dander/core/zone/zone.dart';
import 'package:dander/core/theme/dander_colors.dart';
import 'package:dander/features/zones/presentation/widgets/zone_card.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Zone _buildZone({
  String id = 'zone-1',
  String name = 'Hackney',
  int xp = 0,
  DateTime? createdAt,
}) {
  return Zone(
    id: id,
    name: name,
    centre: const LatLng(51.5, -0.05),
    xp: xp,
    createdAt: createdAt ?? DateTime(2024, 3, 15),
  );
}

Widget _wrap(Widget child) => MaterialApp(
      theme: ThemeData(splashFactory: NoSplash.splashFactory),
      home: Scaffold(body: child),
    );

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('ZoneCard', () {
    group('rendering — basic fields', () {
      testWidgets('displays the zone name', (tester) async {
        final zone = _buildZone(name: 'Hackney Central');
        await tester.pumpWidget(_wrap(ZoneCard(zone: zone, isActive: false)));
        expect(find.text('Hackney Central'), findsOneWidget);
      });

      testWidgets('displays level badge for level 1 zone', (tester) async {
        // 0 XP → Level 1
        final zone = _buildZone(xp: 0);
        await tester.pumpWidget(_wrap(ZoneCard(zone: zone, isActive: false)));
        expect(find.textContaining('L1'), findsAtLeastNWidgets(1));
      });

      testWidgets('displays level badge for level 3 zone', (tester) async {
        // 300 XP → Level 3
        final zone = _buildZone(xp: 300);
        await tester.pumpWidget(_wrap(ZoneCard(zone: zone, isActive: false)));
        expect(find.textContaining('L3'), findsAtLeastNWidgets(1));
      });

      testWidgets('displays level badge for max level zone', (tester) async {
        // 1500+ XP → Level 5
        final zone = _buildZone(xp: 1500);
        await tester.pumpWidget(_wrap(ZoneCard(zone: zone, isActive: false)));
        expect(find.textContaining('L5'), findsAtLeastNWidgets(1));
      });

      testWidgets('displays current XP value', (tester) async {
        final zone = _buildZone(xp: 150);
        await tester.pumpWidget(_wrap(ZoneCard(zone: zone, isActive: false)));
        expect(find.textContaining('150'), findsWidgets);
      });

      testWidgets('displays next-level XP target', (tester) async {
        // L2 zone: next level threshold is 300 XP
        final zone = _buildZone(xp: 150);
        await tester.pumpWidget(_wrap(ZoneCard(zone: zone, isActive: false)));
        // xpForNextLevel(150 XP, L2) = 300
        expect(find.textContaining('300'), findsWidgets);
      });

      testWidgets('shows max level text when zone is at max level',
          (tester) async {
        final zone = _buildZone(xp: 1500);
        await tester.pumpWidget(_wrap(ZoneCard(zone: zone, isActive: false)));
        expect(find.textContaining('Max'), findsOneWidget);
      });

      testWidgets('displays a LinearProgressIndicator for XP progress',
          (tester) async {
        final zone = _buildZone(xp: 50);
        await tester.pumpWidget(_wrap(ZoneCard(zone: zone, isActive: false)));
        expect(find.byType(LinearProgressIndicator), findsOneWidget);
      });

      testWidgets('displays streets explored placeholder "—"', (tester) async {
        final zone = _buildZone();
        await tester.pumpWidget(_wrap(ZoneCard(zone: zone, isActive: false)));
        expect(find.text('—'), findsOneWidget);
      });

      testWidgets('displays the createdAt date', (tester) async {
        final zone = _buildZone(createdAt: DateTime(2024, 6, 15));
        await tester.pumpWidget(_wrap(ZoneCard(zone: zone, isActive: false)));
        expect(find.textContaining('2024'), findsWidgets);
      });
    });

    group('active state', () {
      testWidgets('active zone card has accent border decoration',
          (tester) async {
        final zone = _buildZone();
        await tester.pumpWidget(_wrap(ZoneCard(zone: zone, isActive: true)));
        await tester.pump();

        // An active card should carry a border with the accent color.
        final containers =
            tester.widgetList<Container>(find.byType(Container));
        final hasAccentBorder = containers.any((c) {
          final decoration = c.decoration;
          if (decoration is BoxDecoration) {
            final border = decoration.border;
            if (border is Border) {
              return border.top.color == DanderColors.accent;
            }
          }
          return false;
        });
        expect(hasAccentBorder, isTrue);
      });

      testWidgets('inactive zone card does not have accent border',
          (tester) async {
        final zone = _buildZone();
        await tester.pumpWidget(_wrap(ZoneCard(zone: zone, isActive: false)));
        await tester.pump();

        final containers =
            tester.widgetList<Container>(find.byType(Container));
        final hasAccentBorder = containers.any((c) {
          final decoration = c.decoration;
          if (decoration is BoxDecoration) {
            final border = decoration.border;
            if (border is Border) {
              return border.top.color == DanderColors.accent;
            }
          }
          return false;
        });
        expect(hasAccentBorder, isFalse);
      });
    });

    group('XP progress bar values', () {
      testWidgets('progress bar value is 0 for a brand-new zone',
          (tester) async {
        final zone = _buildZone(xp: 0);
        await tester.pumpWidget(_wrap(ZoneCard(zone: zone, isActive: false)));

        final bar = tester.widget<LinearProgressIndicator>(
          find.byType(LinearProgressIndicator),
        );
        expect(bar.value, 0.0);
      });

      testWidgets('progress bar value is 0.5 at halfway to next level',
          (tester) async {
        // L1: 0–99 XP, halfway = 50 XP → 50/100 = 0.5
        final zone = _buildZone(xp: 50);
        await tester.pumpWidget(_wrap(ZoneCard(zone: zone, isActive: false)));

        final bar = tester.widget<LinearProgressIndicator>(
          find.byType(LinearProgressIndicator),
        );
        expect(bar.value, closeTo(0.5, 0.01));
      });

      testWidgets('max level zone has full progress bar', (tester) async {
        final zone = _buildZone(xp: 1500);
        await tester.pumpWidget(_wrap(ZoneCard(zone: zone, isActive: false)));

        final bar = tester.widget<LinearProgressIndicator>(
          find.byType(LinearProgressIndicator),
        );
        expect(bar.value, 1.0);
      });
    });

    group('edge cases', () {
      testWidgets('renders with very long zone name without overflow error',
          (tester) async {
        final zone = _buildZone(
          name: 'A Very Long Zone Name That Might Cause Layout Issues In Card',
        );
        await tester.pumpWidget(_wrap(ZoneCard(zone: zone, isActive: false)));
        expect(tester.takeException(), isNull);
      });

      testWidgets('renders with special characters in name', (tester) async {
        final zone = _buildZone(name: "L'Île-de-Ré & Côte d'Azur");
        await tester.pumpWidget(_wrap(ZoneCard(zone: zone, isActive: false)));
        expect(find.text("L'Île-de-Ré & Côte d'Azur"), findsOneWidget);
      });

      testWidgets('renders with zero XP without throwing', (tester) async {
        final zone = _buildZone(xp: 0);
        await tester.pumpWidget(_wrap(ZoneCard(zone: zone, isActive: false)));
        expect(tester.takeException(), isNull);
      });
    });

    group('level explainer', () {
      testWidgets('shows current and next level radius at L1', (tester) async {
        final zone = _buildZone(xp: 50);
        await tester.pumpWidget(_wrap(ZoneCard(zone: zone, isActive: false)));
        // L1: 500m → L2: 1.5km (50 XP needed)
        expect(find.textContaining('L1'), findsAtLeastNWidgets(1));
        expect(find.textContaining('500m'), findsAtLeastNWidgets(1));
        expect(find.textContaining('L2'), findsAtLeastNWidgets(1));
      });

      testWidgets('shows max at L5', (tester) async {
        final zone = _buildZone(xp: 1500);
        await tester.pumpWidget(_wrap(ZoneCard(zone: zone, isActive: false)));
        expect(find.textContaining('max'), findsAtLeastNWidgets(1));
      });

      testWidgets('shows XP needed for next level', (tester) async {
        // At 50 XP, need 50 more to reach L2 (100 XP)
        final zone = _buildZone(xp: 50);
        await tester.pumpWidget(_wrap(ZoneCard(zone: zone, isActive: false)));
        expect(find.textContaining('50 XP needed'), findsOneWidget);
      });
    });
  });
}
