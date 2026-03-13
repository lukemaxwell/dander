import 'dart:collection';

/// The learning state of a street in the spaced repetition system.
enum MemoryState {
  /// Never reviewed — just added to the collection.
  newCard,

  /// Answered incorrectly and reset to re-learning.
  learning,

  /// Actively being reviewed on an increasing schedule.
  review,

  /// Interval has reached ≥ 30 days — considered well-known.
  mastered,
}

/// Immutable record tracking a single street's spaced repetition state.
///
/// All fields are final. Use [copyWith] to derive updated instances.
class StreetMemoryRecord {
  const StreetMemoryRecord({
    required this.streetId,
    required this.state,
    required this.intervalDays,
    required this.easeFactor,
    required this.nextReviewDate,
    required List<DateTime> reviewHistory,
  }) : _reviewHistory = reviewHistory;

  /// Creates a brand-new record for [streetId] ready for its first review today.
  factory StreetMemoryRecord.initial(String streetId) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return StreetMemoryRecord(
      streetId: streetId,
      state: MemoryState.newCard,
      intervalDays: 0,
      easeFactor: 2.5,
      nextReviewDate: today,
      reviewHistory: const [],
    );
  }

  /// Deserialises a record from a JSON map.
  factory StreetMemoryRecord.fromJson(Map<String, dynamic> json) {
    final historyRaw = json['reviewHistory'] as List<dynamic>? ?? [];
    final history = historyRaw
        .map((e) => DateTime.parse(e as String))
        .toList(growable: false);

    return StreetMemoryRecord(
      streetId: json['streetId'] as String,
      state: MemoryState.values.byName(json['state'] as String),
      intervalDays: (json['intervalDays'] as num).toInt(),
      easeFactor: (json['easeFactor'] as num).toDouble(),
      nextReviewDate: DateTime.parse(json['nextReviewDate'] as String),
      reviewHistory: history,
    );
  }

  final String streetId;
  final MemoryState state;
  final int intervalDays;

  /// SM-2 ease factor. Minimum 1.3, default 2.5.
  final double easeFactor;

  final DateTime nextReviewDate;

  // Internal backing field — never exposed as mutable.
  final List<DateTime> _reviewHistory;

  /// Unmodifiable view of past review timestamps.
  List<DateTime> get reviewHistory =>
      UnmodifiableListView(_reviewHistory);

  // ---------------------------------------------------------------------------
  // Derived / utility
  // ---------------------------------------------------------------------------

  /// Returns a new [StreetMemoryRecord] with the specified fields replaced.
  ///
  /// All other fields are copied from this record unchanged.
  StreetMemoryRecord copyWith({
    String? streetId,
    MemoryState? state,
    int? intervalDays,
    double? easeFactor,
    DateTime? nextReviewDate,
    List<DateTime>? reviewHistory,
  }) {
    return StreetMemoryRecord(
      streetId: streetId ?? this.streetId,
      state: state ?? this.state,
      intervalDays: intervalDays ?? this.intervalDays,
      easeFactor: easeFactor ?? this.easeFactor,
      nextReviewDate: nextReviewDate ?? this.nextReviewDate,
      reviewHistory: reviewHistory != null
          ? List.unmodifiable(reviewHistory)
          : _reviewHistory,
    );
  }

  /// Serialises the record to a JSON map.
  Map<String, dynamic> toJson() => {
        'streetId': streetId,
        'state': state.name,
        'intervalDays': intervalDays,
        'easeFactor': easeFactor,
        'nextReviewDate': nextReviewDate.toIso8601String(),
        'reviewHistory':
            _reviewHistory.map((d) => d.toIso8601String()).toList(),
      };
}
