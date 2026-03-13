import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:dander/core/streets/street.dart';

void main() {
  // ---------------------------------------------------------------------------
  // Fixtures
  // ---------------------------------------------------------------------------
  final nodes = [
    const LatLng(51.523, -0.157),
    const LatLng(51.524, -0.158),
    const LatLng(51.525, -0.159),
  ];

  Street buildStreet({
    String id = 'way/123456',
    String name = 'Baker Street',
    List<LatLng>? streetNodes,
    DateTime? walkedAt,
  }) {
    return Street(
      id: id,
      name: name,
      nodes: streetNodes ?? nodes,
      walkedAt: walkedAt,
    );
  }

  // ---------------------------------------------------------------------------
  // Construction
  // ---------------------------------------------------------------------------
  group('Street construction', () {
    test('creates a street with required fields', () {
      final street = buildStreet();
      expect(street.id, equals('way/123456'));
      expect(street.name, equals('Baker Street'));
      expect(street.nodes, hasLength(3));
      expect(street.walkedAt, isNull);
    });

    test('creates a street with walkedAt set', () {
      final ts = DateTime(2024, 3, 1, 10, 0);
      final street = buildStreet(walkedAt: ts);
      expect(street.walkedAt, equals(ts));
    });
  });

  // ---------------------------------------------------------------------------
  // isWalked
  // ---------------------------------------------------------------------------
  group('Street.isWalked', () {
    test('returns false when walkedAt is null', () {
      final street = buildStreet();
      expect(street.isWalked, isFalse);
    });

    test('returns true when walkedAt is set', () {
      final street = buildStreet(walkedAt: DateTime(2024, 6, 1));
      expect(street.isWalked, isTrue);
    });
  });

  // ---------------------------------------------------------------------------
  // markWalked — immutability
  // ---------------------------------------------------------------------------
  group('Street.markWalked', () {
    test('returns a new Street instance', () {
      final original = buildStreet();
      final ts = DateTime(2024, 6, 1, 9, 0);
      final walked = original.markWalked(ts);
      expect(walked, isNot(same(original)));
    });

    test('returned street has the provided walkedAt timestamp', () {
      final original = buildStreet();
      final ts = DateTime(2024, 6, 1, 9, 0);
      final walked = original.markWalked(ts);
      expect(walked.walkedAt, equals(ts));
    });

    test('original street remains unmodified after markWalked', () {
      final original = buildStreet();
      final ts = DateTime(2024, 6, 1, 9, 0);
      original.markWalked(ts);
      expect(original.walkedAt, isNull);
      expect(original.isWalked, isFalse);
    });

    test('preserves all other fields when marking as walked', () {
      final original = buildStreet(id: 'way/99', name: 'High Street');
      final ts = DateTime(2024, 6, 1);
      final walked = original.markWalked(ts);
      expect(walked.id, equals('way/99'));
      expect(walked.name, equals('High Street'));
      expect(walked.nodes, equals(original.nodes));
    });
  });

  // ---------------------------------------------------------------------------
  // JSON serialisation round-trip
  // ---------------------------------------------------------------------------
  group('Street JSON round-trip', () {
    test('toJson contains all expected keys', () {
      final street = buildStreet();
      final json = street.toJson();
      expect(json.containsKey('id'), isTrue);
      expect(json.containsKey('name'), isTrue);
      expect(json.containsKey('nodes'), isTrue);
      expect(json.containsKey('walkedAt'), isFalse); // null is omitted
    });

    test('toJson includes walkedAt as ISO string when set', () {
      final ts = DateTime.utc(2024, 6, 1, 12, 0);
      final street = buildStreet(walkedAt: ts);
      final json = street.toJson();
      expect(json['walkedAt'], equals(ts.toIso8601String()));
    });

    test('fromJson restores all fields', () {
      final original = buildStreet();
      final json = original.toJson();
      final restored = Street.fromJson(json);
      expect(restored.id, equals(original.id));
      expect(restored.name, equals(original.name));
      expect(restored.nodes.length, equals(original.nodes.length));
      expect(restored.walkedAt, isNull);
    });

    test('fromJson restores walkedAt from ISO string', () {
      final ts = DateTime.utc(2024, 6, 1, 12, 0);
      final original = buildStreet(walkedAt: ts);
      final json = original.toJson();
      final restored = Street.fromJson(json);
      expect(restored.walkedAt, equals(ts));
    });

    test('fromJson restores node lat/lng correctly', () {
      final original = buildStreet();
      final json = original.toJson();
      final restored = Street.fromJson(json);
      expect(
        restored.nodes.first.latitude,
        closeTo(original.nodes.first.latitude, 0.000001),
      );
      expect(
        restored.nodes.first.longitude,
        closeTo(original.nodes.first.longitude, 0.000001),
      );
    });

    test('round-trip preserves node ordering', () {
      final original = buildStreet();
      final json = original.toJson();
      final restored = Street.fromJson(json);
      for (var i = 0; i < original.nodes.length; i++) {
        expect(
          restored.nodes[i].latitude,
          closeTo(original.nodes[i].latitude, 0.000001),
        );
        expect(
          restored.nodes[i].longitude,
          closeTo(original.nodes[i].longitude, 0.000001),
        );
      }
    });

    test('handles an empty nodes list in round-trip', () {
      final street = buildStreet(streetNodes: []);
      final json = street.toJson();
      final restored = Street.fromJson(json);
      expect(restored.nodes, isEmpty);
    });
  });

  // ---------------------------------------------------------------------------
  // Edge cases
  // ---------------------------------------------------------------------------
  group('Street edge cases', () {
    test('name may be empty string', () {
      final street = buildStreet(name: '');
      expect(street.name, equals(''));
    });

    test('id uses OSM way format', () {
      final street = buildStreet(id: 'way/987654321');
      expect(street.id, startsWith('way/'));
    });

    test('street with single node is valid', () {
      final street = buildStreet(streetNodes: [const LatLng(51.5, -0.1)]);
      expect(street.nodes, hasLength(1));
    });
  });
}
