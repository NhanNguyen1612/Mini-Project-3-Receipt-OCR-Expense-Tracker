import 'package:intl/intl.dart';
import 'expense.dart';

enum TimeFilterMode {
  day,
  week,
  month,
  year,
  all,
}

extension TimeFilterModeExt on TimeFilterMode {
  String get label => switch (this) {
        TimeFilterMode.day => 'Ngày',
        TimeFilterMode.week => 'Tuần',
        TimeFilterMode.month => 'Tháng',
        TimeFilterMode.year => 'Năm',
        TimeFilterMode.all => 'Tất cả',
      };
}

class TimeFilterState {
  const TimeFilterState({
    required this.mode,
    required this.anchorDate,
  });

  final TimeFilterMode mode;
  final DateTime anchorDate;

  factory TimeFilterState.initial() => TimeFilterState(
        mode: TimeFilterMode.month,
        anchorDate: DateTime.now(),
      );

  TimeFilterState copyWith({
    TimeFilterMode? mode,
    DateTime? anchorDate,
  }) =>
      TimeFilterState(
        mode: mode ?? this.mode,
        anchorDate: anchorDate ?? this.anchorDate,
      );

  bool matches(DateTime date) {
    switch (mode) {
      case TimeFilterMode.day:
        return date.year == anchorDate.year &&
            date.month == anchorDate.month &&
            date.day == anchorDate.day;
      case TimeFilterMode.week:
        final start = startOfWeek(anchorDate);
        final end = endOfWeek(anchorDate);
        final dayOnly = DateTime(date.year, date.month, date.day);
        return !dayOnly.isBefore(start) && !dayOnly.isAfter(end);
      case TimeFilterMode.month:
        return date.year == anchorDate.year && date.month == anchorDate.month;
      case TimeFilterMode.year:
        return date.year == anchorDate.year;
      case TimeFilterMode.all:
        return true;
    }
  }

  List<Expense> filter(List<Expense> all) =>
      all.where((e) => matches(e.date)).toList();

  int total(List<Expense> all) =>
      filter(all).fold<int>(0, (sum, e) => sum + e.amount);

  static DateTime startOfWeek(DateTime d) {
    final dayOnly = DateTime(d.year, d.month, d.day);
    return dayOnly.subtract(Duration(days: dayOnly.weekday - 1));
  }

  static DateTime endOfWeek(DateTime d) {
    final start = startOfWeek(d);
    return start.add(const Duration(days: 6));
  }

  String get displayTitle {
    final now = DateTime.now();
    switch (mode) {
      case TimeFilterMode.day:
        final isToday = anchorDate.year == now.year &&
            anchorDate.month == now.month &&
            anchorDate.day == now.day;
        final dateStr = DateFormat('dd/MM/yyyy').format(anchorDate);
        return isToday ? 'Hôm nay ($dateStr)' : 'Ngày $dateStr';
      case TimeFilterMode.week:
        final start = startOfWeek(anchorDate);
        final end = endOfWeek(anchorDate);
        return 'Tuần ${DateFormat('dd/MM').format(start)} - ${DateFormat('dd/MM/yyyy').format(end)}';
      case TimeFilterMode.month:
        final isCurrentMonth =
            anchorDate.year == now.year && anchorDate.month == now.month;
        final monthStr = 'Tháng ${anchorDate.month}/${anchorDate.year}';
        return isCurrentMonth ? '$monthStr (Này)' : monthStr;
      case TimeFilterMode.year:
        final isCurrentYear = anchorDate.year == now.year;
        return isCurrentYear
            ? 'Năm ${anchorDate.year} (Này)'
            : 'Năm ${anchorDate.year}';
      case TimeFilterMode.all:
        return 'Tất cả thời gian';
    }
  }

  String get shortBadge {
    switch (mode) {
      case TimeFilterMode.day:
        return DateFormat('dd/MM/yyyy').format(anchorDate);
      case TimeFilterMode.week:
        final start = startOfWeek(anchorDate);
        final end = endOfWeek(anchorDate);
        return '${DateFormat('dd/MM').format(start)} - ${DateFormat('dd/MM').format(end)}';
      case TimeFilterMode.month:
        return '${anchorDate.month}/${anchorDate.year}';
      case TimeFilterMode.year:
        return '${anchorDate.year}';
      case TimeFilterMode.all:
        return 'TẤT CẢ';
    }
  }

  TimeFilterState previous() {
    switch (mode) {
      case TimeFilterMode.day:
        return copyWith(
          anchorDate: anchorDate.subtract(const Duration(days: 1)),
        );
      case TimeFilterMode.week:
        return copyWith(
          anchorDate: anchorDate.subtract(const Duration(days: 7)),
        );
      case TimeFilterMode.month:
        return copyWith(
          anchorDate: DateTime(anchorDate.year, anchorDate.month - 1, 1),
        );
      case TimeFilterMode.year:
        return copyWith(
          anchorDate: DateTime(anchorDate.year - 1, 1, 1),
        );
      case TimeFilterMode.all:
        return this;
    }
  }

  TimeFilterState next() {
    switch (mode) {
      case TimeFilterMode.day:
        return copyWith(
          anchorDate: anchorDate.add(const Duration(days: 1)),
        );
      case TimeFilterMode.week:
        return copyWith(
          anchorDate: anchorDate.add(const Duration(days: 7)),
        );
      case TimeFilterMode.month:
        return copyWith(
          anchorDate: DateTime(anchorDate.year, anchorDate.month + 1, 1),
        );
      case TimeFilterMode.year:
        return copyWith(
          anchorDate: DateTime(anchorDate.year + 1, 1, 1),
        );
      case TimeFilterMode.all:
        return this;
    }
  }

  bool get canGoNext {
    if (mode == TimeFilterMode.all) return false;
    return true;
  }

  bool get isCurrent {
    final now = DateTime.now();
    switch (mode) {
      case TimeFilterMode.day:
        return anchorDate.year == now.year &&
            anchorDate.month == now.month &&
            anchorDate.day == now.day;
      case TimeFilterMode.week:
        final nowStart = startOfWeek(now);
        final currentStart = startOfWeek(anchorDate);
        return nowStart.isAtSameMomentAs(currentStart);
      case TimeFilterMode.month:
        return anchorDate.year == now.year && anchorDate.month == now.month;
      case TimeFilterMode.year:
        return anchorDate.year == now.year;
      case TimeFilterMode.all:
        return true;
    }
  }
}
