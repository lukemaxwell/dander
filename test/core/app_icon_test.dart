import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('App icon assets', () {
    test('source icon file exists at assets/icon/app_icon.png', () {
      final file = File('assets/icon/app_icon.png');
      expect(file.existsSync(), isTrue,
          reason: 'App icon source not found at assets/icon/app_icon.png');
    });

    test('source icon is a valid PNG (starts with PNG magic bytes)', () {
      final file = File('assets/icon/app_icon.png');
      if (!file.existsSync()) return; // Skip if not generated yet
      final bytes = file.readAsBytesSync();
      // PNG magic: 0x89 0x50 0x4E 0x47
      expect(bytes[0], 0x89);
      expect(bytes[1], 0x50);
      expect(bytes[2], 0x4E);
      expect(bytes[3], 0x47);
    });

    test('source icon file is at least 1KB', () {
      final file = File('assets/icon/app_icon.png');
      if (!file.existsSync()) return;
      expect(file.lengthSync(), greaterThan(1024));
    });

    test('pubspec.yaml includes flutter_launcher_icons config', () {
      final pubspec = File('pubspec.yaml').readAsStringSync();
      expect(pubspec, contains('flutter_launcher_icons'));
    });

    test('pubspec.yaml references icon source file', () {
      final pubspec = File('pubspec.yaml').readAsStringSync();
      expect(pubspec, contains('app_icon'));
    });
  });
}
