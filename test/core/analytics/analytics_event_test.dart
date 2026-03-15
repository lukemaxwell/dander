import 'package:flutter_test/flutter_test.dart';

import 'package:dander/core/analytics/analytics_event.dart';
import 'package:dander/features/subscription/paywall_trigger.dart';

void main() {
  group('PaywallViewed', () {
    test('name is paywall_viewed', () {
      const event = PaywallViewed(
        trigger: PaywallTrigger.profile,
        sessionDay: 1,
      );
      expect(event.name, equals('paywall_viewed'));
    });

    test('properties contains trigger name', () {
      const event = PaywallViewed(
        trigger: PaywallTrigger.quizLimit,
        sessionDay: 3,
      );
      expect(event.properties['trigger'], equals('quizLimit'));
    });

    test('properties contains session_day', () {
      const event = PaywallViewed(
        trigger: PaywallTrigger.profile,
        sessionDay: 7,
      );
      expect(event.properties['session_day'], equals(7));
    });

    test('properties contains both trigger and session_day', () {
      const event = PaywallViewed(
        trigger: PaywallTrigger.stats,
        sessionDay: 30,
      );
      final props = event.properties;
      expect(props.containsKey('trigger'), isTrue);
      expect(props.containsKey('session_day'), isTrue);
      expect(props['trigger'], equals('stats'));
      expect(props['session_day'], equals(30));
    });
  });

  group('PaywallDismissed', () {
    test('name is paywall_dismissed', () {
      const event = PaywallDismissed(
        trigger: PaywallTrigger.profile,
        timeOnScreenMs: 1000,
      );
      expect(event.name, equals('paywall_dismissed'));
    });

    test('properties contains timeOnScreenMs', () {
      const event = PaywallDismissed(
        trigger: PaywallTrigger.zoneExpansion,
        timeOnScreenMs: 4500,
      );
      expect(event.properties['time_on_screen_ms'], equals(4500));
    });

    test('properties contains trigger', () {
      const event = PaywallDismissed(
        trigger: PaywallTrigger.quizLimit,
        timeOnScreenMs: 2000,
      );
      expect(event.properties['trigger'], equals('quizLimit'));
    });
  });

  group('TrialStarted', () {
    test('name is trial_started', () {
      const event = TrialStarted(trigger: PaywallTrigger.profile);
      expect(event.name, equals('trial_started'));
    });

    test('properties plan is always annual', () {
      const event = TrialStarted(trigger: PaywallTrigger.stats);
      expect(event.properties['plan'], equals('annual'));
    });

    test('properties contains trigger', () {
      const event = TrialStarted(trigger: PaywallTrigger.milestone);
      expect(event.properties['trigger'], equals('milestone'));
    });
  });

  group('SubscriptionStarted', () {
    test('name is subscription_started', () {
      const event = SubscriptionStarted(
        trigger: PaywallTrigger.profile,
        plan: 'annual',
      );
      expect(event.name, equals('subscription_started'));
    });

    test('properties contains plan annual', () {
      const event = SubscriptionStarted(
        trigger: PaywallTrigger.profile,
        plan: 'annual',
      );
      expect(event.properties['plan'], equals('annual'));
    });

    test('properties contains plan monthly', () {
      const event = SubscriptionStarted(
        trigger: PaywallTrigger.quizLimit,
        plan: 'monthly',
      );
      expect(event.properties['plan'], equals('monthly'));
    });

    test('properties contains trigger', () {
      const event = SubscriptionStarted(
        trigger: PaywallTrigger.zoneExpansion,
        plan: 'annual',
      );
      expect(event.properties['trigger'], equals('zoneExpansion'));
    });
  });

  group('ProBadgeTapped', () {
    test('name is pro_badge_tapped', () {
      const event = ProBadgeTapped(isPro: false);
      expect(event.name, equals('pro_badge_tapped'));
    });

    test('properties contains is_pro false', () {
      const event = ProBadgeTapped(isPro: false);
      expect(event.properties['is_pro'], isFalse);
    });

    test('properties contains is_pro true', () {
      const event = ProBadgeTapped(isPro: true);
      expect(event.properties['is_pro'], isTrue);
    });
  });

  group('QuizLimitReached', () {
    test('name is quiz_limit_reached', () {
      const event = QuizLimitReached(correct: 7, total: 10);
      expect(event.name, equals('quiz_limit_reached'));
    });

    test('properties contains correct', () {
      const event = QuizLimitReached(correct: 7, total: 10);
      expect(event.properties['correct'], equals(7));
    });

    test('properties contains total', () {
      const event = QuizLimitReached(correct: 7, total: 10);
      expect(event.properties['total'], equals(10));
    });

    test('properties contains correct=0 edge case', () {
      const event = QuizLimitReached(correct: 0, total: 10);
      expect(event.properties['correct'], equals(0));
      expect(event.properties['total'], equals(10));
    });
  });

  group('ZoneExpansionShown', () {
    test('name is zone_expansion_shown', () {
      const event = ZoneExpansionShown(dismissed: true, tapped: false);
      expect(event.name, equals('zone_expansion_shown'));
    });

    test('properties contains dismissed and tapped', () {
      const event = ZoneExpansionShown(dismissed: false, tapped: true);
      expect(event.properties['dismissed'], isFalse);
      expect(event.properties['tapped'], isTrue);
    });
  });

  group('StatsTeaseCardTapped', () {
    test('name is stats_tease_tapped', () {
      const event = StatsTeaseCardTapped(cardType: 'heatmap');
      expect(event.name, equals('stats_tease_tapped'));
    });

    test('properties contains cardType heatmap', () {
      const event = StatsTeaseCardTapped(cardType: 'heatmap');
      expect(event.properties['card_type'], equals('heatmap'));
    });

    test('properties contains cardType trends', () {
      const event = StatsTeaseCardTapped(cardType: 'trends');
      expect(event.properties['card_type'], equals('trends'));
    });

    test('properties contains cardType other', () {
      const event = StatsTeaseCardTapped(cardType: 'other');
      expect(event.properties['card_type'], equals('other'));
    });
  });

  group('ZoneTurfShared', () {
    test('name is zone_turf_shared', () {
      const event = ZoneTurfShared(
        zoneName: 'Downtown',
        level: 3,
        streetCount: 42,
      );
      expect(event.name, equals('zone_turf_shared'));
    });

    test('properties contains zone_name with correct value', () {
      const event = ZoneTurfShared(
        zoneName: 'Midtown',
        level: 1,
        streetCount: 10,
      );
      expect(event.properties['zone_name'], equals('Midtown'));
    });

    test('properties contains level with correct value', () {
      const event = ZoneTurfShared(
        zoneName: 'Uptown',
        level: 5,
        streetCount: 20,
      );
      expect(event.properties['level'], equals(5));
    });

    test('properties contains street_count with correct value', () {
      const event = ZoneTurfShared(
        zoneName: 'Old Town',
        level: 2,
        streetCount: 99,
      );
      expect(event.properties['street_count'], equals(99));
    });
  });

  group('MilestoneProShown', () {
    test('name is milestone_pro_shown', () {
      const event = MilestoneProShown(
        achievementType: 'zone_levelup',
        tapped: false,
      );
      expect(event.name, equals('milestone_pro_shown'));
    });

    test('properties contains achievement_type', () {
      const event = MilestoneProShown(
        achievementType: 'streak',
        tapped: true,
      );
      expect(event.properties['achievement_type'], equals('streak'));
    });

    test('properties contains tapped', () {
      const event = MilestoneProShown(
        achievementType: 'zone_levelup',
        tapped: true,
      );
      expect(event.properties['tapped'], isTrue);
    });
  });
}
