import 'package:hive/hive.dart';

/// Minimal key-value storage interface used by [SubscriptionService].
///
/// Abstracting over Hive's [Box] allows the service to be tested without
/// a real Hive database — tests inject a [FakeSubscriptionStorage] instead.
abstract interface class SubscriptionStorage {
  /// Returns the value stored for [key], or `null` if absent.
  dynamic get(String key);

  /// Stores [value] under [key].
  Future<void> put(String key, dynamic value);
}

/// Live implementation backed by a Hive [Box].
class HiveSubscriptionStorage implements SubscriptionStorage {
  HiveSubscriptionStorage(this._box);

  final Box<dynamic> _box;

  @override
  dynamic get(String key) => _box.get(key);

  @override
  Future<void> put(String key, dynamic value) => _box.put(key, value);
}
