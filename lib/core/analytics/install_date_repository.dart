import 'package:hive/hive.dart';

/// Hive key used to persist the install date.
const _kInstallDateKey = 'install_date';

/// Persists and retrieves the app install date from a Hive box.
///
/// On the very first call to [getOrCreate] the current time is stored and
/// returned. All subsequent calls return the stored value unchanged.
class InstallDateRepository {
  const InstallDateRepository(this._box);

  final Box<dynamic> _box;

  /// Returns the stored install date, or creates one from [DateTime.now].
  ///
  /// Idempotent: calling this multiple times always returns the same value.
  Future<DateTime> getOrCreate() async {
    final stored = _box.get(_kInstallDateKey);
    if (stored != null) {
      return DateTime.parse(stored as String);
    }
    final now = DateTime.now();
    await _box.put(_kInstallDateKey, now.toIso8601String());
    return now;
  }
}
