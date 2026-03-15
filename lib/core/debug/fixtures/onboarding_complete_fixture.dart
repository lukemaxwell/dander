import 'package:latlong2/latlong.dart';

import '../../storage/app_state_repository.dart';
import '../seed_fixture.dart';

/// Past-onboarding fixture — onboarding complete, map centred on
/// Greenwich/Blackheath (good POI density), no walks or discoveries yet.
class OnboardingCompleteFixture extends SeedFixture {
  const OnboardingCompleteFixture();

  /// Greenwich/Blackheath area — dense with heritage, parks, and landmarks.
  static const defaultPosition = LatLng(51.4769, -0.0005);

  @override
  String get name => 'onboarding_complete';

  @override
  LatLng? get seedPosition => defaultPosition;

  @override
  Future<void> seedAppState(AppStateRepository repo) async {
    await repo.saveLastPosition(defaultPosition);
  }
}
