import 'package:dander/features/subscription/paywall_trigger.dart';

/// Base class for all analytics events.
///
/// Sealed so that switch exhaustiveness is enforced at compile time.
sealed class AnalyticsEvent {
  const AnalyticsEvent();

  /// The event name sent to the analytics backend.
  String get name;

  /// Flat map of event properties. Values must be JSON-serialisable primitives.
  Map<String, Object?> get properties;
}

/// Fired when the paywall modal is displayed to the user.
final class PaywallViewed extends AnalyticsEvent {
  const PaywallViewed({
    required this.trigger,
    required this.sessionDay,
  });

  final PaywallTrigger trigger;
  final int sessionDay;

  @override
  String get name => 'paywall_viewed';

  @override
  Map<String, Object?> get properties => {
        'trigger': trigger.name,
        'session_day': sessionDay,
      };
}

/// Fired when the user dismisses the paywall without purchasing.
final class PaywallDismissed extends AnalyticsEvent {
  const PaywallDismissed({
    required this.trigger,
    required this.timeOnScreenMs,
  });

  final PaywallTrigger trigger;
  final int timeOnScreenMs;

  @override
  String get name => 'paywall_dismissed';

  @override
  Map<String, Object?> get properties => {
        'trigger': trigger.name,
        'time_on_screen_ms': timeOnScreenMs,
      };
}

/// Fired when the user starts a free trial.
final class TrialStarted extends AnalyticsEvent {
  const TrialStarted({required this.trigger});

  final PaywallTrigger trigger;

  @override
  String get name => 'trial_started';

  @override
  Map<String, Object?> get properties => {
        'trigger': trigger.name,
        'plan': 'annual',
      };
}

/// Fired when the user completes a subscription purchase.
final class SubscriptionStarted extends AnalyticsEvent {
  const SubscriptionStarted({
    required this.trigger,
    required this.plan,
  });

  final PaywallTrigger trigger;

  /// The purchased plan identifier: `'monthly'` or `'annual'`.
  final String plan;

  @override
  String get name => 'subscription_started';

  @override
  Map<String, Object?> get properties => {
        'trigger': trigger.name,
        'plan': plan,
      };
}

/// Fired when the Pro badge is tapped in the profile screen.
final class ProBadgeTapped extends AnalyticsEvent {
  const ProBadgeTapped({required this.isPro});

  final bool isPro;

  @override
  String get name => 'pro_badge_tapped';

  @override
  Map<String, Object?> get properties => {
        'is_pro': isPro,
      };
}

/// Fired when a free user reaches the daily quiz question limit.
final class QuizLimitReached extends AnalyticsEvent {
  const QuizLimitReached({
    required this.correct,
    required this.total,
  });

  final int correct;
  final int total;

  @override
  String get name => 'quiz_limit_reached';

  @override
  Map<String, Object?> get properties => {
        'correct': correct,
        'total': total,
      };
}

/// Fired when the zone-expansion upsell banner is shown.
final class ZoneExpansionShown extends AnalyticsEvent {
  const ZoneExpansionShown({
    required this.dismissed,
    required this.tapped,
  });

  final bool dismissed;
  final bool tapped;

  @override
  String get name => 'zone_expansion_shown';

  @override
  Map<String, Object?> get properties => {
        'dismissed': dismissed,
        'tapped': tapped,
      };
}

/// Fired when a blurred stats tease card is tapped.
final class StatsTeaseCardTapped extends AnalyticsEvent {
  const StatsTeaseCardTapped({required this.cardType});

  /// Normalised card type identifier: `'heatmap'`, `'trends'`, or `'other'`.
  final String cardType;

  @override
  String get name => 'stats_tease_tapped';

  @override
  Map<String, Object?> get properties => {
        'card_type': cardType,
      };
}

/// Fired when the user shares their zone turf card.
final class ZoneTurfShared extends AnalyticsEvent {
  const ZoneTurfShared({
    required this.zoneName,
    required this.level,
    required this.streetCount,
  });

  final String zoneName;
  final int level;
  final int streetCount;

  @override
  String get name => 'zone_turf_shared';

  @override
  Map<String, Object?> get properties => {
        'zone_name': zoneName,
        'level': level,
        'street_count': streetCount,
      };
}

/// Fired when a Pro upgrade suggestion is shown at a milestone moment.
final class MilestoneProShown extends AnalyticsEvent {
  const MilestoneProShown({
    required this.achievementType,
    required this.tapped,
  });

  final String achievementType;
  final bool tapped;

  @override
  String get name => 'milestone_pro_shown';

  @override
  Map<String, Object?> get properties => {
        'achievement_type': achievementType,
        'tapped': tapped,
      };
}
