import 'purchases_adapter.dart';

/// Sealed class representing the outcome of a purchase attempt.
///
/// Three outcomes:
/// - [PurchaseSuccess]   — purchase completed successfully.
/// - [PurchaseCancelled] — user cancelled the payment sheet.
/// - [PurchaseError]     — store error with a human-readable [message].
sealed class PurchaseResult {
  const PurchaseResult();
}

/// The purchase completed successfully.
///
/// [entitlement] carries the post-purchase entitlement state returned
/// directly by the SDK, eliminating the need for a second network fetch.
/// May be null in rare cases where the SDK returns no entitlement info
/// immediately (e.g. sandbox delays), in which case callers should refresh.
final class PurchaseSuccess extends PurchaseResult {
  const PurchaseSuccess({this.entitlement});

  final EntitlementInfo? entitlement;

  @override
  String toString() => 'PurchaseSuccess(entitlement: $entitlement)';

  @override
  bool operator ==(Object other) =>
      other is PurchaseSuccess && other.entitlement == entitlement;

  @override
  int get hashCode => Object.hash(runtimeType, entitlement);
}

/// The user cancelled the payment sheet without completing the purchase.
final class PurchaseCancelled extends PurchaseResult {
  const PurchaseCancelled();

  @override
  String toString() => 'PurchaseCancelled()';

  @override
  bool operator ==(Object other) => other is PurchaseCancelled;

  @override
  int get hashCode => runtimeType.hashCode;
}

/// A store or network error occurred during the purchase.
final class PurchaseError extends PurchaseResult {
  const PurchaseError(this.message);

  /// Human-readable error description. Must not be empty.
  final String message;

  @override
  String toString() => 'PurchaseError(message: $message)';

  @override
  bool operator ==(Object other) =>
      other is PurchaseError && other.message == message;

  @override
  int get hashCode => Object.hash(runtimeType, message);
}
