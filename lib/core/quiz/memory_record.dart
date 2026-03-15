import 'dart:collection';

import 'street_memory_record.dart';

export 'street_memory_record.dart' show MemoryState;

/// Immutable record tracking a single question's spaced repetition state.
///
/// Generalised from [StreetMemoryRecord] to support any question type.
/// The [questionId] encodes both the type and the subject, e.g.
/// `streetName:way/123`, `direction:node/1-node/2`, `category:node/456`.
///
/// All fields are final. Use [copyWith] to derive updated instances.
class MemoryRecord {
  const MemoryRecord({
    required this.questionId,
    required this.state,
    required this.intervalDays,
    required this.easeFactor,
    required this.nextReviewDate,
    required List<DateTime> reviewHistory,
  }) : _reviewHistory = reviewHistory;

  /// Creates a brand-new record for [questionId] ready for its first review.
  factory MemoryRecord.initial(String questionId) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return MemoryRecord(
      questionId: questionId,
      state: MemoryState.newCard,
      intervalDays: 0,
      easeFactor: 2.5,
      nextReviewDate: today,
      reviewHistory: const [],
    );
  }

  /// Migrates a legacy [StreetMemoryRecord] to the generalised format.
  ///
  /// Prefixes the street ID with `streetName:` to form the question ID.
  factory MemoryRecord.fromLegacy(StreetMemoryRecord legacy) {
    return MemoryRecord(
      questionId: 'streetName:${legacy.streetId}',
      state: legacy.state,
      intervalDays: legacy.intervalDays,
      easeFactor: legacy.easeFactor,
      nextReviewDate: legacy.nextReviewDate,
      reviewHistory: legacy.reviewHistory,
    );
  }

  /// Deserialises a record from a JSON map.
  factory MemoryRecord.fromJson(Map<String, dynamic> json) {
    final historyRaw = json['reviewHistory'] as List<dynamic>? ?? [];
    final history = historyRaw
        .map((e) => DateTime.parse(e as String))
        .toList(growable: false);

    return MemoryRecord(
      questionId: json['questionId'] as String,
      state: MemoryState.values.byName(json['state'] as String),
      intervalDays: (json['intervalDays'] as num).toInt(),
      easeFactor: (json['easeFactor'] as num).toDouble(),
      nextReviewDate: DateTime.parse(json['nextReviewDate'] as String),
      reviewHistory: history,
    );
  }

  final String questionId;
  final MemoryState state;
  final int intervalDays;

  /// SM-2 ease factor. Minimum 1.3, default 2.5.
  final double easeFactor;

  final DateTime nextReviewDate;

  final List<DateTime> _reviewHistory;

  /// Unmodifiable view of past review timestamps.
  List<DateTime> get reviewHistory => UnmodifiableListView(_reviewHistory);

  /// Returns a new [MemoryRecord] with the specified fields replaced.
  MemoryRecord copyWith({
    String? questionId,
    MemoryState? state,
    int? intervalDays,
    double? easeFactor,
    DateTime? nextReviewDate,
    List<DateTime>? reviewHistory,
  }) {
    return MemoryRecord(
      questionId: questionId ?? this.questionId,
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
        'questionId': questionId,
        'state': state.name,
        'intervalDays': intervalDays,
        'easeFactor': easeFactor,
        'nextReviewDate': nextReviewDate.toIso8601String(),
        'reviewHistory':
            _reviewHistory.map((d) => d.toIso8601String()).toList(),
      };
}
