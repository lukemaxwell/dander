import 'package:flutter_test/flutter_test.dart';
import 'package:dander/core/fog/fog_cell.dart';

void main() {
  group('FogCell', () {
    group('construction', () {
      test('creates cell with x and y coordinates', () {
        const cell = FogCell(x: 3, y: 7);
        expect(cell.x, equals(3));
        expect(cell.y, equals(7));
      });

      test('creates cell with negative coordinates', () {
        const cell = FogCell(x: -5, y: -12);
        expect(cell.x, equals(-5));
        expect(cell.y, equals(-12));
      });

      test('creates cell at origin', () {
        const cell = FogCell(x: 0, y: 0);
        expect(cell.x, equals(0));
        expect(cell.y, equals(0));
      });
    });

    group('equality', () {
      test('two cells with same coordinates are equal', () {
        const a = FogCell(x: 1, y: 2);
        const b = FogCell(x: 1, y: 2);
        expect(a, equals(b));
      });

      test('two cells with different x are not equal', () {
        const a = FogCell(x: 1, y: 2);
        const b = FogCell(x: 9, y: 2);
        expect(a, isNot(equals(b)));
      });

      test('two cells with different y are not equal', () {
        const a = FogCell(x: 1, y: 2);
        const b = FogCell(x: 1, y: 9);
        expect(a, isNot(equals(b)));
      });
    });

    group('hashCode', () {
      test('equal cells have same hash code', () {
        const a = FogCell(x: 4, y: 8);
        const b = FogCell(x: 4, y: 8);
        expect(a.hashCode, equals(b.hashCode));
      });

      test('cells can be used in a Set', () {
        const a = FogCell(x: 1, y: 2);
        const c = FogCell(x: 3, y: 4);
        // Adding a duplicate of 'a' via a variable avoids lint warning.
        final duplicate = FogCell(x: a.x, y: a.y);
        final set = <FogCell>{a, duplicate, c};
        expect(set.length, equals(2));
      });
    });

    group('toString', () {
      test('returns readable string', () {
        const cell = FogCell(x: 3, y: 7);
        final str = cell.toString();
        expect(str, contains('3'));
        expect(str, contains('7'));
      });
    });
  });
}
