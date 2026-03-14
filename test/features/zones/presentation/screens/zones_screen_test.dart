import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:dander/core/zone/zone.dart';
import 'package:dander/core/zone/zone_repository.dart';
import 'package:dander/features/zones/presentation/screens/zones_screen.dart';
import 'package:dander/features/zones/presentation/widgets/zone_card.dart';
import 'package:dander/features/zones/presentation/widgets/zones_loading_skeleton.dart';

// ---------------------------------------------------------------------------
// Fake repository
// ---------------------------------------------------------------------------

class _FakeZoneRepository implements ZoneRepository {
  _FakeZoneRepository(this._zones);

  final List<Zone> _zones;

  @override
  Future<List<Zone>> loadAll() async => List.unmodifiable(_zones);

  @override
  Future<Zone?> load(String id) async =>
      _zones.cast<Zone?>().firstWhere((z) => z?.id == id, orElse: () => null);

  @override
  Future<void> save(Zone zone) async {}

  @override
  Future<void> delete(String id) async {}
}

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
      home: child,
    );

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('ZonesScreen', () {
    group('empty state', () {
      testWidgets('shows empty-state message when no zones exist',
          (tester) async {
        final repo = _FakeZoneRepository([]);
        await tester.pumpWidget(
          _wrap(ZonesScreen(repository: repo)),
        );
        // Resolve the FutureBuilder
        await tester.pumpAndSettle();

        expect(
          find.textContaining('Start walking to create your first zone'),
          findsOneWidget,
        );
      });

      testWidgets('does not show ZoneCard widgets in empty state',
          (tester) async {
        final repo = _FakeZoneRepository([]);
        await tester.pumpWidget(_wrap(ZonesScreen(repository: repo)));
        await tester.pumpAndSettle();

        expect(find.byType(ZoneCard), findsNothing);
      });

      testWidgets('shows skeleton before future resolves', (tester) async {
        final repo = _FakeZoneRepository([]);
        await tester.pumpWidget(_wrap(ZonesScreen(repository: repo)));
        // Do NOT call pumpAndSettle — check the initial frame.
        expect(find.byType(ZonesLoadingSkeleton), findsOneWidget);
      });
    });

    group('zone list', () {
      testWidgets('renders one ZoneCard per zone', (tester) async {
        final zones = [
          _buildZone(id: 'z1', name: 'Hackney'),
          _buildZone(id: 'z2', name: 'Shoreditch'),
          _buildZone(id: 'z3', name: 'Dalston'),
        ];
        final repo = _FakeZoneRepository(zones);
        await tester.pumpWidget(_wrap(ZonesScreen(repository: repo)));
        await tester.pumpAndSettle();

        expect(find.byType(ZoneCard), findsNWidgets(3));
      });

      testWidgets('displays zone names from repository', (tester) async {
        final zones = [
          _buildZone(id: 'z1', name: 'Hackney'),
          _buildZone(id: 'z2', name: 'Barcelona Eixample'),
        ];
        final repo = _FakeZoneRepository(zones);
        await tester.pumpWidget(_wrap(ZonesScreen(repository: repo)));
        await tester.pumpAndSettle();

        expect(find.text('Hackney'), findsOneWidget);
        expect(find.text('Barcelona Eixample'), findsOneWidget);
      });

      testWidgets('renders correct number of cards for a single zone',
          (tester) async {
        final zones = [_buildZone(id: 'z1', name: 'Solo Zone')];
        final repo = _FakeZoneRepository(zones);
        await tester.pumpWidget(_wrap(ZonesScreen(repository: repo)));
        await tester.pumpAndSettle();

        expect(find.byType(ZoneCard), findsOneWidget);
      });
    });

    group('active zone highlighting', () {
      testWidgets('active zone card has isActive=true', (tester) async {
        final zones = [
          _buildZone(id: 'z1', name: 'Active Zone'),
          _buildZone(id: 'z2', name: 'Inactive Zone'),
        ];
        final repo = _FakeZoneRepository(zones);
        await tester.pumpWidget(
          _wrap(ZonesScreen(repository: repo, activeZoneId: 'z1')),
        );
        await tester.pumpAndSettle();

        // Find the ZoneCard for 'Active Zone' and verify isActive
        final cards =
            tester.widgetList<ZoneCard>(find.byType(ZoneCard)).toList();
        final activeCard = cards.firstWhere(
          (c) => c.zone.id == 'z1',
        );
        final inactiveCard = cards.firstWhere(
          (c) => c.zone.id == 'z2',
        );

        expect(activeCard.isActive, isTrue);
        expect(inactiveCard.isActive, isFalse);
      });

      testWidgets('no card is active when activeZoneId is null',
          (tester) async {
        final zones = [
          _buildZone(id: 'z1', name: 'Zone A'),
          _buildZone(id: 'z2', name: 'Zone B'),
        ];
        final repo = _FakeZoneRepository(zones);
        await tester.pumpWidget(
          _wrap(ZonesScreen(repository: repo)),
        );
        await tester.pumpAndSettle();

        final cards =
            tester.widgetList<ZoneCard>(find.byType(ZoneCard)).toList();
        expect(cards.every((c) => c.isActive == false), isTrue);
      });

      testWidgets('no card is active when activeZoneId does not match any zone',
          (tester) async {
        final zones = [
          _buildZone(id: 'z1', name: 'Zone A'),
        ];
        final repo = _FakeZoneRepository(zones);
        await tester.pumpWidget(
          _wrap(ZonesScreen(repository: repo, activeZoneId: 'nonexistent')),
        );
        await tester.pumpAndSettle();

        final cards =
            tester.widgetList<ZoneCard>(find.byType(ZoneCard)).toList();
        expect(cards.every((c) => c.isActive == false), isTrue);
      });
    });

    group('tapping a zone card', () {
      testWidgets('tapping a zone card does not throw', (tester) async {
        final zones = [_buildZone(id: 'z1', name: 'Tap Me')];
        final repo = _FakeZoneRepository(zones);
        await tester.pumpWidget(_wrap(ZonesScreen(repository: repo)));
        await tester.pumpAndSettle();

        await tester.tap(find.byType(ZoneCard).first);
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      });

      testWidgets('onZoneTapped callback fires with the correct zone id',
          (tester) async {
        String? tappedId;
        final zones = [
          _buildZone(id: 'zone-abc', name: 'Tappable Zone'),
        ];
        final repo = _FakeZoneRepository(zones);
        await tester.pumpWidget(
          _wrap(
            ZonesScreen(
              repository: repo,
              onZoneTapped: (id) => tappedId = id,
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byType(ZoneCard).first);
        await tester.pump();

        expect(tappedId, 'zone-abc');
      });
    });

    group('screen structure', () {
      testWidgets('renders without AppBar (title removed)', (tester) async {
        final repo = _FakeZoneRepository([]);
        await tester.pumpWidget(_wrap(ZonesScreen(repository: repo)));
        await tester.pumpAndSettle();

        expect(find.byType(AppBar), findsNothing);
      });
    });

    group('large data', () {
      testWidgets('handles 20 zones without error', (tester) async {
        final zones = List.generate(
          20,
          (i) => _buildZone(id: 'z$i', name: 'Zone $i', xp: i * 50),
        );
        final repo = _FakeZoneRepository(zones);
        await tester.pumpWidget(_wrap(ZonesScreen(repository: repo)));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      });
    });
  });
}
