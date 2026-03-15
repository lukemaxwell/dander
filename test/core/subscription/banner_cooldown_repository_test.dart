import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:dander/core/subscription/banner_cooldown_repository.dart';

void main() {
  late Box<dynamic> box;
  late BannerCooldownRepository repo;

  setUp(() async {
    Hive.init(
      '/tmp/hive_banner_cooldown_test_${DateTime.now().millisecondsSinceEpoch}',
    );
    box = await Hive.openBox<dynamic>(
      'banner_cooldown_test_${DateTime.now().millisecondsSinceEpoch}',
    );
    repo = BannerCooldownRepository.withBox(box);
  });

  tearDown(() async {
    await box.close();
  });

  group('BannerCooldownRepository', () {
    group('isOnCooldown', () {
      test('returns false when no timestamp has been stored', () {
        expect(repo.isOnCooldown(), isFalse);
      });

      test('returns true when dismissed 24 hours ago (within 48h window)', () {
        final dismissedAt = DateTime.now().subtract(const Duration(hours: 24));
        box.put('dismissed_at', dismissedAt.millisecondsSinceEpoch);
        expect(repo.isOnCooldown(), isTrue);
      });

      test('returns true when dismissed 1 hour ago', () {
        final dismissedAt = DateTime.now().subtract(const Duration(hours: 1));
        box.put('dismissed_at', dismissedAt.millisecondsSinceEpoch);
        expect(repo.isOnCooldown(), isTrue);
      });

      test('returns false when dismissed 49 hours ago (beyond 48h window)', () {
        final dismissedAt = DateTime.now().subtract(const Duration(hours: 49));
        box.put('dismissed_at', dismissedAt.millisecondsSinceEpoch);
        expect(repo.isOnCooldown(), isFalse);
      });

      test('returns false when dismissed exactly 48h ago (boundary = expired)', () {
        // Exactly 48h ago — should be expired (cooldown uses > not >=)
        final dismissedAt =
            DateTime.now().subtract(const Duration(hours: 48));
        box.put('dismissed_at', dismissedAt.millisecondsSinceEpoch);
        // Implementation: cooldown elapsed when duration >= 48h.
        // "48h ago exactly" means the 48h window has just elapsed → not on cooldown.
        expect(repo.isOnCooldown(), isFalse);
      });
    });

    group('markDismissed', () {
      test('stores a timestamp so isOnCooldown returns true immediately after', () {
        expect(repo.isOnCooldown(), isFalse);
        repo.markDismissed();
        expect(repo.isOnCooldown(), isTrue);
      });

      test('overwrites an old timestamp with the current time', () {
        // Put an old timestamp (expired)
        final oldTime =
            DateTime.now().subtract(const Duration(hours: 60));
        box.put('dismissed_at', oldTime.millisecondsSinceEpoch);
        expect(repo.isOnCooldown(), isFalse);

        // Now mark dismissed again
        repo.markDismissed();
        expect(repo.isOnCooldown(), isTrue);
      });
    });

    group('resetForTest', () {
      test('clears the stored timestamp so isOnCooldown returns false', () {
        repo.markDismissed();
        expect(repo.isOnCooldown(), isTrue);

        repo.resetForTest();
        expect(repo.isOnCooldown(), isFalse);
      });

      test('is idempotent when called with no stored timestamp', () {
        expect(repo.isOnCooldown(), isFalse);
        repo.resetForTest();
        expect(repo.isOnCooldown(), isFalse);
      });
    });
  });
}
