/// Helper calculating consecutive daily logging streaks from discrete ISO dates.
class StreakCalculator {
  static int calculateStreakFromDates(List<String> dates) {
    if (dates.isEmpty) return 0;
    final dateSet = dates.toSet();

    final now = DateTime.now();
    final todayStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final yesterday = now.subtract(const Duration(days: 1));
    final yesterdayStr =
        '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';

    DateTime checkDate;
    if (dateSet.contains(todayStr)) {
      checkDate = now;
    } else if (dateSet.contains(yesterdayStr)) {
      checkDate = yesterday;
    } else {
      return 0;
    }

    int streak = 0;
    while (true) {
      final key =
          '${checkDate.year}-${checkDate.month.toString().padLeft(2, '0')}-${checkDate.day.toString().padLeft(2, '0')}';
      if (dateSet.contains(key)) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    return streak;
  }
}
