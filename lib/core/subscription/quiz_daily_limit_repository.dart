import 'package:dander/core/subscription/subscription_state.dart';

// ---------------------------------------------------------------------------
// Storage interface
// ---------------------------------------------------------------------------

/// Minimal key-value storage for the quiz daily limit counter.
///
/// Separate from [SubscriptionStorage] so each concern has its own box.
abstract interface class QuizLimitStorage {
  /// Returns the value stored for [key], or `null` if absent.
  dynamic get(String key);

  /// Stores [value] under [key].
  Future<void> put(String key, dynamic value);
}

// ---------------------------------------------------------------------------
// Hive-backed implementation
// ---------------------------------------------------------------------------

/// Hive-backed [QuizLimitStorage] used in production.
class HiveQuizLimitStorage implements QuizLimitStorage {
  HiveQuizLimitStorage(this._box);

  final dynamic _box; // Box<dynamic> — typed loosely to avoid Hive import leak

  @override
  dynamic get(String key) => (_box as dynamic).get(key);

  @override
  Future<void> put(String key, dynamic value) async {
    await (_box as dynamic).put(key, value);
  }
}

// ---------------------------------------------------------------------------
// Key constants
// ---------------------------------------------------------------------------

const _kDateKey = 'quiz_limit_date';
const _kCountKey = 'quiz_limit_count';
const _kDailyLimit = 10;

// ---------------------------------------------------------------------------
// Repository
// ---------------------------------------------------------------------------

/// Tracks how many quiz questions a free user has answered today.
///
/// - Counts persist in [QuizLimitStorage] across app restarts.
/// - Count resets to 0 at midnight local time (date string comparison).
/// - Pro users bypass the limit entirely — [isLimitReached] returns `false`.
///
/// All writes return new stored values; no in-place mutation.
class QuizDailyLimitRepository {
  QuizDailyLimitRepository({
    required QuizLimitStorage storage,
    required DateTime Function() clock,
    required SubscriptionState Function() subscriptionState,
  })  : _storage = storage,
        _clock = clock,
        _subscriptionState = subscriptionState;

  final QuizLimitStorage _storage;
  final DateTime Function() _clock;
  final SubscriptionState Function() _subscriptionState;

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Returns the number of quiz answers recorded today (0 if a new day).
  Future<int> getTodayCount() async {
    final storedDate = _storage.get(_kDateKey) as String?;
    final todayString = _todayString();

    if (storedDate != todayString) {
      return 0;
    }

    final count = _storage.get(_kCountKey);
    if (count == null) return 0;
    return (count as num).toInt();
  }

  /// Increments today's answer count by 1.
  ///
  /// Resets the count to 1 if the stored date differs from today.
  Future<void> increment() async {
    final todayString = _todayString();
    final storedDate = _storage.get(_kDateKey) as String?;

    final currentCount = (storedDate == todayString)
        ? ((_storage.get(_kCountKey) as num?)?.toInt() ?? 0)
        : 0;

    final newCount = currentCount + 1;

    // Write both date and count as an immutable pair — never mutate in place.
    await _storage.put(_kDateKey, todayString);
    await _storage.put(_kCountKey, newCount);
  }

  /// Returns `true` when the daily limit has been reached.
  ///
  /// Always returns `false` for Pro users (paid or trial).
  Future<bool> isLimitReached() async {
    if (_subscriptionState().isPro) return false;

    final count = await getTodayCount();
    return count >= _kDailyLimit;
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  /// Returns today's date as a zero-padded ISO-8601 string (e.g. `2026-03-15`).
  String _todayString() {
    final now = _clock();
    final y = now.year.toString().padLeft(4, '0');
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}
