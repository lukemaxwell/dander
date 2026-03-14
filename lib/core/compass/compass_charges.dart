/// Immutable model tracking compass charge state.
///
/// Charges are earned by walking [metersPerCharge] metres.
/// The model tracks partial distance toward the next charge via
/// [metersSinceLastCharge], ensuring no distance is lost between updates.
/// Charges are capped at [maxCharges].
class CompassCharges {
  const CompassCharges({
    this.currentCharges = 1,
    this.metersSinceLastCharge = 0.0,
  });

  /// The number of charges currently available.
  final int currentCharges;

  /// Partial metres accumulated toward the next charge.
  final double metersSinceLastCharge;

  /// Maximum number of charges the compass can hold.
  static const int maxCharges = 3;

  /// Metres of walking required to earn one charge.
  static const double metersPerCharge = 500.0;

  /// Whether at least one charge is available to spend.
  bool get canSpend => currentCharges > 0;

  /// Returns a new [CompassCharges] with charges earned from [meters] walked.
  ///
  /// Partial metres are tracked across calls. Charges cap at [maxCharges].
  CompassCharges earnFromDistance(double meters) {
    final totalMeters = metersSinceLastCharge + meters;
    final earned = (totalMeters ~/ metersPerCharge);
    final remainder = totalMeters % metersPerCharge;
    final newCharges = (currentCharges + earned).clamp(0, maxCharges);
    // When already at cap, discard remainder to avoid phantom accumulation.
    final newRemainder = newCharges >= maxCharges ? 0.0 : remainder;
    return CompassCharges(
      currentCharges: newCharges,
      metersSinceLastCharge: newRemainder,
    );
  }

  /// Returns a new [CompassCharges] with [currentCharges] decremented by one.
  ///
  /// Throws [StateError] if there are no charges to spend.
  CompassCharges spend() {
    if (currentCharges == 0) {
      throw StateError('Cannot spend a compass charge: no charges available.');
    }
    return CompassCharges(
      currentCharges: currentCharges - 1,
      metersSinceLastCharge: metersSinceLastCharge,
    );
  }

  /// Serialises to a JSON-compatible map.
  Map<String, dynamic> toJson() => {
        'currentCharges': currentCharges,
        'metersSinceLastCharge': metersSinceLastCharge,
      };

  /// Deserialises from a JSON-compatible map produced by [toJson].
  factory CompassCharges.fromJson(Map<String, dynamic> json) => CompassCharges(
        currentCharges: (json['currentCharges'] as num).toInt(),
        metersSinceLastCharge:
            (json['metersSinceLastCharge'] as num).toDouble(),
      );
}
