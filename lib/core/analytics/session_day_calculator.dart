/// Pure utility for computing the session day number relative to install date.
///
/// Day numbering is 1-based: the install day itself is day 1.
abstract final class SessionDayCalculator {
  /// Returns the number of calendar days since [installDate], minimum 1.
  ///
  /// Uses [Duration.inDays] which truncates to whole days, so the install day
  /// and any partial day on [now] both count as day 1.
  static int calculate(DateTime installDate, DateTime now) {
    final diff = now.difference(installDate);
    return diff.inDays + 1;
  }
}
