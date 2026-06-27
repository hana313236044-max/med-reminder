import 'package:uhd/models/medicine_performance.dart';
import 'package:uhd/models/statistics_filter.dart';
import 'package:uhd/models/statistics_summary.dart';

enum IntakeLogStatus { taken, delayed, missed, skipped, rescheduled, waiting }

enum StatisticsScheduleType { oneTime, repeating }

class IntakeLogRecord {
  final String id;
  final String userId;
  final String medicineId;
  final String reminderId;
  final String medicineName;
  final DateTime scheduledDateTime;
  final DateTime? actionDateTime;
  final IntakeLogStatus status;
  final int? delayMinutes;
  final StatisticsScheduleType scheduleType;
  final String scheduleLabel;
  final bool fromReminderFallback;

  const IntakeLogRecord({
    required this.id,
    required this.userId,
    required this.medicineId,
    required this.reminderId,
    required this.medicineName,
    required this.scheduledDateTime,
    required this.actionDateTime,
    required this.status,
    required this.delayMinutes,
    required this.scheduleType,
    required this.scheduleLabel,
    this.fromReminderFallback = false,
  });

  DateTime get day =>
      DateTime(scheduledDateTime.year, scheduledDateTime.month, scheduledDateTime.day);

  int get scheduledMinuteOfDay =>
      scheduledDateTime.hour * 60 + scheduledDateTime.minute;

  IntakeLogStatus effectiveStatus(
    DateTime now, {
    int onTimeGraceMinutes = 15,
  }) {
    if (status == IntakeLogStatus.waiting && !scheduledDateTime.isAfter(now)) {
      return IntakeLogStatus.missed;
    }

    if (status == IntakeLogStatus.taken &&
        delayMinutes != null &&
        delayMinutes! > onTimeGraceMinutes) {
      return IntakeLogStatus.delayed;
    }

    return status;
  }

  bool isFinished(DateTime now, {int onTimeGraceMinutes = 15}) {
    if (scheduledDateTime.isAfter(now)) return false;

    final effective = effectiveStatus(
      now,
      onTimeGraceMinutes: onTimeGraceMinutes,
    );
    return effective != IntakeLogStatus.waiting &&
        effective != IntakeLogStatus.rescheduled;
  }

  bool isCompleted(DateTime now, {int onTimeGraceMinutes = 15}) {
    final effective = effectiveStatus(
      now,
      onTimeGraceMinutes: onTimeGraceMinutes,
    );
    return isFinished(now, onTimeGraceMinutes: onTimeGraceMinutes) &&
        (effective == IntakeLogStatus.taken ||
            effective == IntakeLogStatus.delayed);
  }

  bool isUnsuccessful(DateTime now, {int onTimeGraceMinutes = 15}) {
    final effective = effectiveStatus(
      now,
      onTimeGraceMinutes: onTimeGraceMinutes,
    );
    return isFinished(now, onTimeGraceMinutes: onTimeGraceMinutes) &&
        (effective == IntakeLogStatus.missed ||
            effective == IntakeLogStatus.skipped);
  }

  bool isOnTime(DateTime now, {int onTimeGraceMinutes = 15}) {
    if (!isFinished(now, onTimeGraceMinutes: onTimeGraceMinutes)) {
      return false;
    }

    if (effectiveStatus(now, onTimeGraceMinutes: onTimeGraceMinutes) !=
        IntakeLogStatus.taken) {
      return false;
    }

    final actionAt = actionDateTime;
    if (actionAt == null) {
      return (delayMinutes ?? 0) <= onTimeGraceMinutes;
    }

    final latestOnTime =
        scheduledDateTime.add(Duration(minutes: onTimeGraceMinutes));
    return !actionAt.isAfter(latestOnTime);
  }
}

class DailyStatistic {
  final DateTime date;
  final int scheduledCount;
  final int takenCount;
  final int delayedCount;
  final int missedCount;
  final int skippedCount;

  const DailyStatistic({
    required this.date,
    required this.scheduledCount,
    required this.takenCount,
    required this.delayedCount,
    required this.missedCount,
    required this.skippedCount,
  });

  int get completedCount => takenCount + delayedCount;

  int get unsuccessfulCount => missedCount + skippedCount;

  double get adherencePercent {
    if (scheduledCount == 0) return 0;
    return completedCount / scheduledCount * 100;
  }
}

class MedicineOption {
  final String id;
  final String name;

  const MedicineOption({required this.id, required this.name});
}

class StatisticsReport {
  final StatisticsFilter filter;
  final StatisticsSummary summary;
  final StatisticsSummary previousSummary;
  final List<DailyStatistic> dailyStatistics;
  final List<MedicinePerformance> medicinePerformance;
  final List<MedicineOption> medicineOptions;
  final List<IntakeLogRecord> filteredRecords;
  final bool hasAnyRecordsInRange;
  final String insightMessage;

  const StatisticsReport({
    required this.filter,
    required this.summary,
    required this.previousSummary,
    required this.dailyStatistics,
    required this.medicinePerformance,
    required this.medicineOptions,
    required this.filteredRecords,
    required this.hasAnyRecordsInRange,
    required this.insightMessage,
  });

  bool get hasFilteredRecords => filteredRecords.isNotEmpty;

  bool get hasFinishedData => summary.hasFinishedData;
}
