import 'package:flutter_test/flutter_test.dart';
import 'package:uhd/models/statistics_filter.dart';
import 'package:uhd/models/statistics_model.dart';
import 'package:uhd/services/statistics_service.dart';

void main() {
  IntakeLogRecord record({
    required String id,
    required DateTime scheduledAt,
    required IntakeLogStatus status,
    DateTime? actionAt,
    String medicineId = '1',
    String medicineName = 'Amoxicillin',
    String scheduleLabel = 'One time',
  }) {
    return IntakeLogRecord(
      id: id,
      userId: 'user-1',
      medicineId: medicineId,
      reminderId: id,
      medicineName: medicineName,
      scheduledDateTime: scheduledAt,
      actionDateTime: actionAt,
      status: status,
      delayMinutes: actionAt == null
          ? null
          : actionAt.difference(scheduledAt).inMinutes,
      scheduleType: scheduleLabel.toLowerCase().contains('every')
          ? StatisticsScheduleType.repeating
          : StatisticsScheduleType.oneTime,
      scheduleLabel: scheduleLabel,
    );
  }

  test('calculates adherence and excludes future waiting and rescheduled logs', () {
    final now = DateTime(2026, 6, 27, 12);
    final range = StatisticsDateRange(
      startDate: DateTime(2026, 6, 21),
      endDate: DateTime(2026, 6, 27),
    );
    final records = [
      record(
        id: 'taken',
        scheduledAt: DateTime(2026, 6, 27, 8),
        status: IntakeLogStatus.taken,
        actionAt: DateTime(2026, 6, 27, 8, 5),
      ),
      record(
        id: 'delayed',
        scheduledAt: DateTime(2026, 6, 27, 9),
        status: IntakeLogStatus.taken,
        actionAt: DateTime(2026, 6, 27, 9, 25),
      ),
      record(
        id: 'missed',
        scheduledAt: DateTime(2026, 6, 26, 8),
        status: IntakeLogStatus.missed,
      ),
      record(
        id: 'future',
        scheduledAt: DateTime(2026, 6, 27, 20),
        status: IntakeLogStatus.waiting,
      ),
      record(
        id: 'rescheduled',
        scheduledAt: DateTime(2026, 6, 25, 8),
        status: IntakeLogStatus.rescheduled,
      ),
    ];

    final summary = StatisticsCalculator.buildSummary(
      records: records,
      range: range,
      now: now,
    );

    expect(summary.finishedCount, 3);
    expect(summary.completedCount, 2);
    expect(summary.takenCount, 1);
    expect(summary.delayedCount, 1);
    expect(summary.missedCount, 1);
    expect(summary.waitingCount, 1);
    expect(summary.rescheduledCount, 1);
    expect(summary.adherencePercent.round(), 67);
    expect(summary.onTimeAdherencePercent.round(), 33);
    expect(summary.mostMissedMedicine, 'Amoxicillin');
    expect(summary.mostMissedTime, '8:00 AM');
  });

  test('daily statistics count past waiting reminders as missed', () {
    final now = DateTime(2026, 6, 27, 12);
    final range = StatisticsDateRange(
      startDate: DateTime(2026, 6, 27),
      endDate: DateTime(2026, 6, 27),
    );
    final daily = StatisticsCalculator.buildDailyStatistics(
      records: [
        record(
          id: 'past-waiting',
          scheduledAt: DateTime(2026, 6, 27, 8),
          status: IntakeLogStatus.waiting,
        ),
      ],
      range: range,
      now: now,
    );

    expect(daily.single.scheduledCount, 1);
    expect(daily.single.missedCount, 1);
    expect(daily.single.adherencePercent, 0);
  });

  test('successful-day streak skips empty days and stops at a failed day', () {
    final now = DateTime(2026, 6, 27, 12);
    final range = StatisticsDateRange(
      startDate: DateTime(2026, 6, 24),
      endDate: DateTime(2026, 6, 27),
    );
    final summary = StatisticsCalculator.buildSummary(
      records: [
        record(
          id: 'today',
          scheduledAt: DateTime(2026, 6, 27, 8),
          status: IntakeLogStatus.taken,
          actionAt: DateTime(2026, 6, 27, 8, 1),
        ),
        record(
          id: 'older-success',
          scheduledAt: DateTime(2026, 6, 25, 8),
          status: IntakeLogStatus.delayed,
          actionAt: DateTime(2026, 6, 25, 8, 30),
        ),
        record(
          id: 'older-failure',
          scheduledAt: DateTime(2026, 6, 24, 8),
          status: IntakeLogStatus.skipped,
        ),
      ],
      range: range,
      now: now,
    );

    expect(summary.currentStreakDays, 2);
  });
}
