enum StatisticsRangePreset { today, sevenDays, thirtyDays, custom }

enum StatisticsStatusFilter {
  all,
  taken,
  delayed,
  missed,
  skipped,
  rescheduled,
  waiting,
}

enum StatisticsScheduleTypeFilter { all, oneTime, repeating }

class StatisticsDateRange {
  final DateTime startDate;
  final DateTime endDate;

  factory StatisticsDateRange({
    required DateTime startDate,
    required DateTime endDate,
  }) {
    return StatisticsDateRange._(_dateOnly(startDate), _dateOnly(endDate));
  }

  const StatisticsDateRange._(this.startDate, this.endDate);

  factory StatisticsDateRange.forPreset(
    StatisticsRangePreset preset, {
    DateTime? now,
  }) {
    final today = _dateOnly(now ?? DateTime.now());
    switch (preset) {
      case StatisticsRangePreset.today:
        return StatisticsDateRange(startDate: today, endDate: today);
      case StatisticsRangePreset.sevenDays:
        return StatisticsDateRange(
          startDate: today.subtract(const Duration(days: 6)),
          endDate: today,
        );
      case StatisticsRangePreset.thirtyDays:
        return StatisticsDateRange(
          startDate: today.subtract(const Duration(days: 29)),
          endDate: today,
        );
      case StatisticsRangePreset.custom:
        return StatisticsDateRange(startDate: today, endDate: today);
    }
  }

  int get dayCount => endDate.difference(startDate).inDays + 1;

  DateTime get endExclusive => endDate.add(const Duration(days: 1));

  bool get isValid => !endDate.isBefore(startDate);

  StatisticsDateRange get previous {
    final previousEnd = startDate.subtract(const Duration(days: 1));
    final previousStart = previousEnd.subtract(Duration(days: dayCount - 1));
    return StatisticsDateRange(startDate: previousStart, endDate: previousEnd);
  }

  bool contains(DateTime value) {
    final local = value.toLocal();
    return !local.isBefore(startDate) && local.isBefore(endExclusive);
  }

  static DateTime _dateOnly(DateTime value) {
    final local = value.toLocal();
    return DateTime(local.year, local.month, local.day);
  }
}

class StatisticsFilter {
  static const Object _unchangedMedicine = Object();

  final StatisticsRangePreset rangePreset;
  final StatisticsDateRange dateRange;
  final String? medicineId;
  final StatisticsStatusFilter status;
  final StatisticsScheduleTypeFilter scheduleType;

  StatisticsFilter({
    required this.rangePreset,
    required this.dateRange,
    this.medicineId,
    this.status = StatisticsStatusFilter.all,
    this.scheduleType = StatisticsScheduleTypeFilter.all,
  });

  factory StatisticsFilter.initial() {
    return StatisticsFilter(
      rangePreset: StatisticsRangePreset.sevenDays,
      dateRange: StatisticsDateRange.forPreset(
        StatisticsRangePreset.sevenDays,
      ),
    );
  }

  bool get hasActiveFilters =>
      medicineId != null ||
      status != StatisticsStatusFilter.all ||
      scheduleType != StatisticsScheduleTypeFilter.all;

  StatisticsFilter copyWith({
    StatisticsRangePreset? rangePreset,
    StatisticsDateRange? dateRange,
    Object? medicineId = _unchangedMedicine,
    StatisticsStatusFilter? status,
    StatisticsScheduleTypeFilter? scheduleType,
  }) {
    return StatisticsFilter(
      rangePreset: rangePreset ?? this.rangePreset,
      dateRange: dateRange ?? this.dateRange,
      medicineId: identical(medicineId, _unchangedMedicine)
          ? this.medicineId
          : medicineId as String?,
      status: status ?? this.status,
      scheduleType: scheduleType ?? this.scheduleType,
    );
  }

  StatisticsFilter resetFilters() {
    return copyWith(
      medicineId: null,
      status: StatisticsStatusFilter.all,
      scheduleType: StatisticsScheduleTypeFilter.all,
    );
  }
}

extension StatisticsRangePresetLabel on StatisticsRangePreset {
  String get label {
    switch (this) {
      case StatisticsRangePreset.today:
        return 'Today';
      case StatisticsRangePreset.sevenDays:
        return '7 Days';
      case StatisticsRangePreset.thirtyDays:
        return '30 Days';
      case StatisticsRangePreset.custom:
        return 'Custom';
    }
  }
}

extension StatisticsStatusFilterLabel on StatisticsStatusFilter {
  String get label {
    switch (this) {
      case StatisticsStatusFilter.all:
        return 'All statuses';
      case StatisticsStatusFilter.taken:
        return 'Taken';
      case StatisticsStatusFilter.delayed:
        return 'Delayed';
      case StatisticsStatusFilter.missed:
        return 'Missed';
      case StatisticsStatusFilter.skipped:
        return 'Skipped';
      case StatisticsStatusFilter.rescheduled:
        return 'Rescheduled';
      case StatisticsStatusFilter.waiting:
        return 'Waiting';
    }
  }
}

extension StatisticsScheduleTypeFilterLabel on StatisticsScheduleTypeFilter {
  String get label {
    switch (this) {
      case StatisticsScheduleTypeFilter.all:
        return 'All types';
      case StatisticsScheduleTypeFilter.oneTime:
        return 'One-time';
      case StatisticsScheduleTypeFilter.repeating:
        return 'Repeating';
    }
  }
}
