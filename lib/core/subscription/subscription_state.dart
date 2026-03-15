/// Sealed class representing the user's current subscription status.
///
/// Three states:
/// - [SubscriptionStateFree]   — no active subscription or trial.
/// - [SubscriptionStateTrial]  — active free trial with days remaining.
/// - [SubscriptionStatePro]    — paid Pro subscriber.
///
/// All subclasses are immutable; use `const` constructors where possible.
sealed class SubscriptionState {
  const SubscriptionState();

  /// Returns `true` when the user has full Pro access (paid or active trial).
  bool get isPro;
}

/// The user has no subscription and no active trial.
final class SubscriptionStateFree extends SubscriptionState {
  const SubscriptionStateFree();

  @override
  bool get isPro => false;

  @override
  String toString() => 'SubscriptionStateFree()';

  @override
  bool operator ==(Object other) => other is SubscriptionStateFree;

  @override
  int get hashCode => runtimeType.hashCode;
}

/// The user is on an active free trial with [daysLeft] days remaining.
///
/// [daysLeft] must be >= 1. A trial that has expired maps to
/// [SubscriptionStateFree], not [SubscriptionStateTrial].
final class SubscriptionStateTrial extends SubscriptionState {
  const SubscriptionStateTrial({required this.daysLeft})
      : assert(daysLeft >= 1, 'daysLeft must be at least 1');

  /// Number of full days remaining in the trial.
  final int daysLeft;

  @override
  bool get isPro => true;

  @override
  String toString() => 'SubscriptionStateTrial(daysLeft: $daysLeft)';

  @override
  bool operator ==(Object other) =>
      other is SubscriptionStateTrial && other.daysLeft == daysLeft;

  @override
  int get hashCode => Object.hash(runtimeType, daysLeft);
}

/// The user is a paying Pro subscriber.
final class SubscriptionStatePro extends SubscriptionState {
  const SubscriptionStatePro();

  @override
  bool get isPro => true;

  @override
  String toString() => 'SubscriptionStatePro()';

  @override
  bool operator ==(Object other) => other is SubscriptionStatePro;

  @override
  int get hashCode => runtimeType.hashCode;
}
