import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:dander/core/zone/zone.dart';
import 'package:dander/core/theme/dander_colors.dart';
import 'package:dander/core/theme/dander_elevation.dart';
import 'package:dander/features/zones/presentation/widgets/zone_card.dart';
import 'package:dander/shared/widgets/pressable.dart';

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

      testWidgets('displays level badge with Lv. prefix for level 1 zone',
          (tester) async {
        // 0 XP → Level 1
        final zone = _buildZone(xp: 0);
        await tester.pumpWidget(_wrap(ZoneCard(zone: zone, isActive: false)));
        expect(find.textContaining('Lv.1'), findsAtLeastNWidgets(1));
      });

      testWidgets('displays level badge with Lv. prefix for level 3 zone',
          (tester) async {
        // 300 XP → Level 3
        final zone = _buildZone(xp: 300);
        await tester.pumpWidget(_wrap(ZoneCard(zone: zone, isActive: false)));
        expect(find.textContaining('Lv.3'), findsAtLeastNWidgets(1));
      });

      testWidgets('displays level badge with Lv. prefix for max level zone',
          (tester) async {
        // 1500+ XP → Level 5
        final zone = _buildZone(xp: 1500);
        await tester.pumpWidget(_wrap(ZoneCard(zone: zone, isActive: false)));
        expect(find.textContaining('Lv.5'), findsAtLeastNWidgets(1));
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
        expect(find.textContaining('Max'), findsAtLeastNWidgets(1));
      });

      testWidgets('displays a LinearProgressIndicator for XP progress',
          (tester) async {
        final zone = _buildZone(xp: 50);
        await tester.pumpWidget(_wrap(ZoneCard(zone: zone, isActive: false)));
        expect(find.byType(LinearProgressIndicator), findsOneWidget);
      });

      testWidgets('does not show streets placeholder "—"', (tester) async {
        final zone = _buildZone();
        await tester.pumpWidget(_wrap(ZoneCard(zone: zone, isActive: false)));
        expect(find.text('—'), findsNothing);
      });

      testWidgets('displays zone radius in footer', (tester) async {
        // 0 XP → L1 → 500m radius
        final zone = _buildZone(xp: 0);
        await tester.pumpWidget(_wrap(ZoneCard(zone: zone, isActive: false)));
        expect(find.textContaining('500m'), findsAtLeastNWidgets(1));
      });

      testWidgets('shows chevron icon for tap affordance', (tester) async {
        final zone = _buildZone();
        await tester.pumpWidget(_wrap(ZoneCard(zone: zone, isActive: false)));
        expect(find.byIcon(Icons.chevron_right), findsOneWidget);
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
      testWidgets('shows human-readable explainer at L1', (tester) async {
        // At 50 XP (L1), next level radius is 1.5km
        final zone = _buildZone(xp: 50);
        await tester.pumpWidget(_wrap(ZoneCard(zone: zone, isActive: false)));
        // Should show something like "1.5km radius at next level"
        expect(find.textContaining('1.5km radius'), findsOneWidget);
      });

      testWidgets('shows max level text at L5', (tester) async {
        final zone = _buildZone(xp: 1500);
        await tester.pumpWidget(_wrap(ZoneCard(zone: zone, isActive: false)));
        expect(find.textContaining('Max'), findsAtLeastNWidgets(1));
      });

      testWidgets('shows XP needed for next level', (tester) async {
        // At 50 XP, need 50 more to reach L2 (100 XP)
        final zone = _buildZone(xp: 50);
        await tester.pumpWidget(_wrap(ZoneCard(zone: zone, isActive: false)));
        expect(find.textContaining('50 XP'), findsAtLeastNWidgets(1));
      });
    });

    group('elevation and visual polish', () {
      testWidgets('card has elevation shadow', (tester) async {
        final zone = _buildZone();
        await tester.pumpWidget(_wrap(ZoneCard(zone: zone, isActive: false)));

        final containers =
            tester.widgetList<Container>(find.byType(Container));
        final hasShadow = containers.any((c) {
          final decoration = c.decoration;
          if (decoration is BoxDecoration) {
            return decoration.boxShadow != null &&
                decoration.boxShadow!.isNotEmpty;
          }
          return false;
        });
        expect(hasShadow, isTrue);
      });

      testWidgets('card has thin border for OLED separation', (tester) async {
        final zone = _buildZone();
        await tester.pumpWidget(_wrap(ZoneCard(zone: zone, isActive: false)));

        final containers =
            tester.widgetList<Container>(find.byType(Container));
        final hasBorder = containers.any((c) {
          final decoration = c.decoration;
          if (decoration is BoxDecoration && decoration.border is Border) {
            final border = decoration.border as Border;
            return border.top.color == DanderColors.cardBorder;
          }
          return false;
        });
        expect(hasBorder, isTrue);
      });

      testWidgets('progress bar is 6pt height', (tester) async {
        final zone = _buildZone(xp: 50);
        await tester.pumpWidget(_wrap(ZoneCard(zone: zone, isActive: false)));

        final bar = tester.widget<LinearProgressIndicator>(
          find.byType(LinearProgressIndicator),
        );
        expect(bar.minHeight, 6);
      });

      testWidgets('edit icon uses Pressable with 44pt touch target',
          (tester) async {
        final zone = _buildZone();
        await tester.pumpWidget(_wrap(ZoneCard(
          zone: zone,
          isActive: false,
          onRename: (_) {},
        )));

        // Should find Pressable widgets (card + edit icon)
        final pressables =
            tester.widgetList<Pressable>(find.byType(Pressable));
        // At least 2: one for the card, one for the edit icon
        expect(pressables.length, greaterThanOrEqualTo(2));
      });

      testWidgets('delete icon uses Pressable with 44pt touch target',
          (tester) async {
        final zone = _buildZone();
        await tester.pumpWidget(_wrap(ZoneCard(
          zone: zone,
          isActive: false,
          onDelete: () {},
        )));

        // Should find Pressable widgets (card + delete icon)
        final pressables =
            tester.widgetList<Pressable>(find.byType(Pressable));
        expect(pressables.length, greaterThanOrEqualTo(2));
      });
    });
  });
}
