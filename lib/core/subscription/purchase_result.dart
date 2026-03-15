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
final class PurchaseSuccess extends PurchaseResult {
  const PurchaseSuccess();

  @override
  String toString() => 'PurchaseSuccess()';

  @override
  bool operator ==(Object other) => other is PurchaseSuccess;

  @override
  int get hashCode => runtimeType.hashCode;
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
