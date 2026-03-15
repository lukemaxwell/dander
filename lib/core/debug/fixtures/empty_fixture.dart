import '../seed_fixture.dart';

/// Fresh-install fixture — no seeded data, just permission suppression.
class EmptyFixture extends SeedFixture {
  const EmptyFixture();

  @override
  String get name => 'empty';

  @override
  bool get suppressOnboarding => false;
}
