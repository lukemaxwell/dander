import 'analytics_event.dart';

/// Contract for all analytics backends.
abstract interface class AnalyticsService {
  void track(AnalyticsEvent event);
}

/// No-op implementation used in release builds until a real backend is wired.
final class NoOpAnalyticsService implements AnalyticsService {
  const NoOpAnalyticsService();

  @override
  void track(AnalyticsEvent event) {}
}

/// Debug implementation that prints events to the console.
final class DebugAnalyticsService implements AnalyticsService {
  @override
  void track(AnalyticsEvent event) {
    // ignore: avoid_print
    print('[Analytics] ${event.name}: ${event.properties}');
  }
}

/// In-memory implementation used in widget and integration tests.
///
/// Accumulates all tracked events in [events] for assertion.
final class InMemoryAnalyticsService implements AnalyticsService {
  final List<AnalyticsEvent> events = [];

  @override
  void track(AnalyticsEvent event) => events.add(event);
}
