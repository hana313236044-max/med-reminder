import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uhd/models/medicine_performance.dart';
import 'package:uhd/models/statistics_filter.dart';
import 'package:uhd/models/statistics_model.dart';
import 'package:uhd/models/statistics_summary.dart';

class StatisticsServiceException implements Exception {
  final String message;

  const StatisticsServiceException(this.message);
}

class StatisticsService {
  static const int onTimeGraceMinutes = 15;

  final FirebaseFirestore firestore;
  final FirebaseAuth auth;

  StatisticsService({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : firestore = firestore ?? FirebaseFirestore.instance,
        auth = auth ?? FirebaseAuth.instance;

  static String intakeLogIdFor(String reminderId, DateTime scheduledAt) {
    return '${reminderId}_${scheduledAt.toUtc().microsecondsSinceEpoch}';
  }

  static Map<String, dynamic> intakeLogData({
    required String userId,
    required Object medicineId,
    required String reminderId,
    required String medicineName,
    required DateTime scheduledDateTime,
    required IntakeLogStatus status,
    required String scheduleLabel,
    DateTime? actionDateTime,
    int? delayMinutes,
  }) {
    final resolvedDelay = delayMinutes ??
        (actionDateTime == null
            ? null
            : math.max(
                0,
                actionDateTime.difference(scheduledDateTime).inMinutes,
              ));

    return {
      'userId': userId,
      'medicineId': medicineId,
      'reminderId': reminderId,
      'medicineName': medicineName,
      'scheduledDateTime': Timestamp.fromDate(scheduledDateTime),
      'actionDateTime': actionDateTime == null
          ? null
          : Timestamp.fromDate(actionDateTime),
      'status': status.name,
      'delayMinutes': resolvedDelay,
      'scheduleLabel': scheduleLabel,
      'scheduleType': _scheduleTypeFromLabel(scheduleLabel).name,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  Future<StatisticsReport> loadReport(StatisticsFilter filter) async {
    if (!filter.dateRange.isValid) {
      throw const StatisticsServiceException('Choose a valid date range.');
    }

    final user = auth.currentUser;
    if (user == null) {
      throw const StatisticsServiceException('Please sign in to view insights.');
    }

    final now = DateTime.now();
    final previousRange = filter.dateRange.previous;
    final queryStart = previousRange.startDate;
    final queryEndExclusive = filter.dateRange.endExclusive;
    final userRef = firestore.collection('users').doc(user.uid);

    final medicineSnapshot =
        await userRef.collection('medicines').orderBy('name').get();
    final medicineNames = _medicineNameMap(medicineSnapshot.docs);
    final medicineOptions = _medicineOptions(medicineSnapshot.docs);

    final logSnapshot = await userRef
        .collection('intakeLogs')
        .where(
          'scheduledDateTime',
          isGreaterThanOrEqualTo: Timestamp.fromDate(queryStart),
        )
        .where(
          'scheduledDateTime',
          isLessThan: Timestamp.fromDate(queryEndExclusive),
        )
        .orderBy('scheduledDateTime')
        .get();

    final reminderSnapshot = await userRef
        .collection('reminders')
        .where(
          'scheduledAt',
          isGreaterThanOrEqualTo: Timestamp.fromDate(queryStart),
        )
        .where(
          'scheduledAt',
          isLessThan: Timestamp.fromDate(queryEndExclusive),
        )
        .orderBy('scheduledAt')
        .get();

    final records = _mergeLogsAndReminders(
      uid: user.uid,
      logDocs: logSnapshot.docs,
      reminderDocs: reminderSnapshot.docs,
      medicineNames: medicineNames,
      now: now,
    );

    final currentAll = records
        .where((record) => filter.dateRange.contains(record.scheduledDateTime))
        .toList();
    final currentFiltered =
        _applyFilters(currentAll, filter, now).toList(growable: false);
    final previousFiltered = _applyFilters(
      records.where(
        (record) => previousRange.contains(record.scheduledDateTime),
      ),
      filter,
      now,
    ).toList(growable: false);

    final summary = StatisticsCalculator.buildSummary(
      records: currentFiltered,
      range: filter.dateRange,
      now: now,
    );
    final previousSummary = StatisticsCalculator.buildSummary(
      records: previousFiltered,
      range: previousRange,
      now: now,
    );

    return StatisticsReport(
      filter: filter,
      summary: summary,
      previousSummary: previousSummary,
      dailyStatistics: StatisticsCalculator.buildDailyStatistics(
        records: currentFiltered,
        range: filter.dateRange,
        now: now,
      ),
      medicinePerformance: StatisticsCalculator.buildMedicinePerformance(
        records: currentFiltered,
        now: now,
      ),
      medicineOptions: medicineOptions,
      filteredRecords: currentFiltered,
      hasAnyRecordsInRange: currentAll.isNotEmpty,
      insightMessage: StatisticsCalculator.buildInsightMessage(
        filter: filter,
        current: summary,
        previous: previousSummary,
      ),
    );
  }

  List<IntakeLogRecord> _mergeLogsAndReminders({
    required String uid,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> logDocs,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> reminderDocs,
    required Map<String, String> medicineNames,
    required DateTime now,
  }) {
    final records = <IntakeLogRecord>[];
    final logKeys = <String>{};

    for (final doc in logDocs) {
      final record = _recordFromLog(uid, doc, medicineNames);
      if (record == null) continue;
      records.add(record);
      logKeys.add(_recordKey(record.reminderId, record.scheduledDateTime));
    }

    for (final doc in reminderDocs) {
      final record = _recordFromReminder(uid, doc, medicineNames, now);
      if (record == null) continue;
      final key = _recordKey(record.reminderId, record.scheduledDateTime);
      if (logKeys.contains(key)) continue;
      records.add(record);
    }

    records.sort((a, b) => a.scheduledDateTime.compareTo(b.scheduledDateTime));
    return records;
  }

  IntakeLogRecord? _recordFromLog(
    String uid,
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
    Map<String, String> medicineNames,
  ) {
    final data = doc.data();
    final scheduledAt =
        _readDateTime(data['scheduledDateTime']) ?? _readDateTime(data['scheduledAt']);
    if (scheduledAt == null) return null;

    final medicineId = _stringId(data['medicineId']);
    final reminderId = _stringId(data['reminderId']).isEmpty
        ? doc.id
        : _stringId(data['reminderId']);
    final scheduleLabel = data['scheduleLabel'] as String? ?? 'One time';

    return IntakeLogRecord(
      id: doc.id,
      userId: data['userId'] as String? ?? uid,
      medicineId: medicineId,
      reminderId: reminderId,
      medicineName: _medicineNameFor(
        data['medicineName'] as String?,
        medicineId,
        medicineNames,
      ),
      scheduledDateTime: scheduledAt,
      actionDateTime: _readDateTime(data['actionDateTime']),
      status: _statusFromName(data['status'] as String?),
      delayMinutes: _readInt(data['delayMinutes']),
      scheduleType: _scheduleTypeFromName(
        data['scheduleType'] as String?,
        scheduleLabel,
      ),
      scheduleLabel: scheduleLabel,
    );
  }

  IntakeLogRecord? _recordFromReminder(
    String uid,
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
    Map<String, String> medicineNames,
    DateTime now,
  ) {
    final data = doc.data();
    final scheduledAt = _readDateTime(data['scheduledAt']);
    if (scheduledAt == null) return null;

    final medicineId = _stringId(data['medicineId']);
    final scheduleLabel = data['scheduleLabel'] as String? ?? 'One time';
    final actionAt = _readDateTime(data['actionDateTime']) ??
        _readDateTime(data['completedAt']);
    final status = _statusFromReminder(data['status'] as String?, scheduledAt, now, actionAt);
    final delayMinutes = actionAt == null
        ? null
        : math.max(0, actionAt.difference(scheduledAt).inMinutes);

    return IntakeLogRecord(
      id: doc.id,
      userId: uid,
      medicineId: medicineId,
      reminderId: doc.id,
      medicineName: _medicineNameFor(
        data['medicineName'] as String?,
        medicineId,
        medicineNames,
      ),
      scheduledDateTime: scheduledAt,
      actionDateTime: status == IntakeLogStatus.taken ||
              status == IntakeLogStatus.delayed
          ? actionAt
          : null,
      status: status,
      delayMinutes: delayMinutes,
      scheduleType: _scheduleTypeFromLabel(scheduleLabel),
      scheduleLabel: scheduleLabel,
      fromReminderFallback: true,
    );
  }

  Iterable<IntakeLogRecord> _applyFilters(
    Iterable<IntakeLogRecord> records,
    StatisticsFilter filter,
    DateTime now,
  ) {
    return records.where((record) {
      final medicineId = filter.medicineId;
      if (medicineId != null && record.medicineId != medicineId) {
        return false;
      }

      if (!_matchesStatus(record, filter.status, now)) {
        return false;
      }

      if (!_matchesScheduleType(record, filter.scheduleType)) {
        return false;
      }

      return true;
    });
  }

  bool _matchesStatus(
    IntakeLogRecord record,
    StatisticsStatusFilter filter,
    DateTime now,
  ) {
    if (filter == StatisticsStatusFilter.all) return true;

    final status = record.effectiveStatus(
      now,
      onTimeGraceMinutes: onTimeGraceMinutes,
    );
    switch (filter) {
      case StatisticsStatusFilter.all:
        return true;
      case StatisticsStatusFilter.taken:
        return status == IntakeLogStatus.taken;
      case StatisticsStatusFilter.delayed:
        return status == IntakeLogStatus.delayed;
      case StatisticsStatusFilter.missed:
        return status == IntakeLogStatus.missed;
      case StatisticsStatusFilter.skipped:
        return status == IntakeLogStatus.skipped;
      case StatisticsStatusFilter.rescheduled:
        return status == IntakeLogStatus.rescheduled;
      case StatisticsStatusFilter.waiting:
        return status == IntakeLogStatus.waiting;
    }
  }

  bool _matchesScheduleType(
    IntakeLogRecord record,
    StatisticsScheduleTypeFilter filter,
  ) {
    switch (filter) {
      case StatisticsScheduleTypeFilter.all:
        return true;
      case StatisticsScheduleTypeFilter.oneTime:
        return record.scheduleType == StatisticsScheduleType.oneTime;
      case StatisticsScheduleTypeFilter.repeating:
        return record.scheduleType == StatisticsScheduleType.repeating;
    }
  }

  Map<String, String> _medicineNameMap(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final names = <String, String>{};
    for (final doc in docs) {
      final data = doc.data();
      final name = data['name'] as String? ?? 'Unknown medicine';
      names[doc.id] = name;
      names[_stringId(data['id'])] = name;
    }
    return names;
  }

  List<MedicineOption> _medicineOptions(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final options = docs.map((doc) {
      final data = doc.data();
      return MedicineOption(
        id: _stringId(data['id']).isEmpty ? doc.id : _stringId(data['id']),
        name: data['name'] as String? ?? 'Unknown medicine',
      );
    }).toList();

    options.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );
    return options;
  }

  static DateTime? _readDateTime(Object? value) {
    if (value is Timestamp) return value.toDate().toLocal();
    if (value is DateTime) return value.toLocal();
    if (value is String) return DateTime.tryParse(value)?.toLocal();
    return null;
  }

  static int? _readInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static String _stringId(Object? value) {
    if (value == null) return '';
    return value.toString();
  }

  static String _medicineNameFor(
    String? documentName,
    String medicineId,
    Map<String, String> medicineNames,
  ) {
    final currentName = medicineNames[medicineId];
    if (currentName != null && currentName.trim().isNotEmpty) {
      return currentName;
    }
    final name = documentName?.trim();
    if (name != null && name.isNotEmpty) return name;
    return 'Unknown medicine';
  }

  static IntakeLogStatus _statusFromName(String? value) {
    final normalized = (value ?? '').toLowerCase().replaceAll('_', '');
    switch (normalized) {
      case 'complete':
      case 'completed':
      case 'took':
      case 'taken':
        return IntakeLogStatus.taken;
      case 'delayed':
        return IntakeLogStatus.delayed;
      case 'notTaken':
      case 'nottaken':
      case 'missed':
        return IntakeLogStatus.missed;
      case 'skipped':
        return IntakeLogStatus.skipped;
      case 'rescheduled':
        return IntakeLogStatus.rescheduled;
      case 'waiting':
      default:
        return IntakeLogStatus.waiting;
    }
  }

  static IntakeLogStatus _statusFromReminder(
    String? value,
    DateTime scheduledAt,
    DateTime now,
    DateTime? actionAt,
  ) {
    final status = _statusFromName(value);
    if (status == IntakeLogStatus.taken) {
      final delay = actionAt == null
          ? 0
          : math.max(0, actionAt.difference(scheduledAt).inMinutes);
      return delay > onTimeGraceMinutes
          ? IntakeLogStatus.delayed
          : IntakeLogStatus.taken;
    }

    if (status == IntakeLogStatus.waiting && !scheduledAt.isAfter(now)) {
      return IntakeLogStatus.missed;
    }

    return status;
  }

  static StatisticsScheduleType _scheduleTypeFromName(
    String? value,
    String scheduleLabel,
  ) {
    final normalized = (value ?? '').toLowerCase().replaceAll('-', '');
    if (normalized == 'repeating' || normalized == 'repeat') {
      return StatisticsScheduleType.repeating;
    }
    if (normalized == 'onetime' || normalized == 'oneTime') {
      return StatisticsScheduleType.oneTime;
    }
    return _scheduleTypeFromLabel(scheduleLabel);
  }

  static StatisticsScheduleType _scheduleTypeFromLabel(String scheduleLabel) {
    return scheduleLabel.toLowerCase().contains('every')
        ? StatisticsScheduleType.repeating
        : StatisticsScheduleType.oneTime;
  }

  static String _recordKey(String reminderId, DateTime scheduledAt) {
    return '$reminderId|${scheduledAt.toUtc().microsecondsSinceEpoch}';
  }
}

class StatisticsCalculator {
  static StatisticsSummary buildSummary({
    required List<IntakeLogRecord> records,
    required StatisticsDateRange range,
    required DateTime now,
  }) {
    var finishedCount = 0;
    var takenCount = 0;
    var delayedCount = 0;
    var missedCount = 0;
    var skippedCount = 0;
    var rescheduledCount = 0;
    var waitingCount = 0;
    var onTimeTakenCount = 0;
    final missedByMedicine = <String, int>{};
    final missedByTime = <int, int>{};

    for (final record in records) {
      final effective = record.effectiveStatus(
        now,
        onTimeGraceMinutes: StatisticsService.onTimeGraceMinutes,
      );

      if (effective == IntakeLogStatus.rescheduled) {
        rescheduledCount++;
        continue;
      }

      if (!record.isFinished(
        now,
        onTimeGraceMinutes: StatisticsService.onTimeGraceMinutes,
      )) {
        if (effective == IntakeLogStatus.waiting) waitingCount++;
        continue;
      }

      finishedCount++;
      switch (effective) {
        case IntakeLogStatus.taken:
          takenCount++;
          break;
        case IntakeLogStatus.delayed:
          delayedCount++;
          break;
        case IntakeLogStatus.missed:
          missedCount++;
          missedByMedicine.update(
            record.medicineName,
            (count) => count + 1,
            ifAbsent: () => 1,
          );
          missedByTime.update(
            record.scheduledMinuteOfDay,
            (count) => count + 1,
            ifAbsent: () => 1,
          );
          break;
        case IntakeLogStatus.skipped:
          skippedCount++;
          missedByMedicine.update(
            record.medicineName,
            (count) => count + 1,
            ifAbsent: () => 1,
          );
          missedByTime.update(
            record.scheduledMinuteOfDay,
            (count) => count + 1,
            ifAbsent: () => 1,
          );
          break;
        case IntakeLogStatus.rescheduled:
        case IntakeLogStatus.waiting:
          break;
      }

      if (record.isOnTime(
        now,
        onTimeGraceMinutes: StatisticsService.onTimeGraceMinutes,
      )) {
        onTimeTakenCount++;
      }
    }

    return StatisticsSummary(
      finishedCount: finishedCount,
      takenCount: takenCount,
      delayedCount: delayedCount,
      missedCount: missedCount,
      skippedCount: skippedCount,
      rescheduledCount: rescheduledCount,
      waitingCount: waitingCount,
      onTimeTakenCount: onTimeTakenCount,
      mostMissedMedicine: _mostFrequentString(missedByMedicine),
      mostMissedTime: _mostFrequentTime(missedByTime),
      currentStreakDays: _successfulDayStreak(records, range, now),
    );
  }

  static List<DailyStatistic> buildDailyStatistics({
    required List<IntakeLogRecord> records,
    required StatisticsDateRange range,
    required DateTime now,
  }) {
    final byDay = <DateTime, List<IntakeLogRecord>>{};
    for (final record in records) {
      byDay.putIfAbsent(record.day, () => []).add(record);
    }

    final statistics = <DailyStatistic>[];
    for (var day = range.startDate;
        !day.isAfter(range.endDate);
        day = day.add(const Duration(days: 1))) {
      var scheduledCount = 0;
      var takenCount = 0;
      var delayedCount = 0;
      var missedCount = 0;
      var skippedCount = 0;

      for (final record in byDay[day] ?? const <IntakeLogRecord>[]) {
        if (!record.isFinished(
          now,
          onTimeGraceMinutes: StatisticsService.onTimeGraceMinutes,
        )) {
          continue;
        }

        scheduledCount++;
        switch (record.effectiveStatus(
          now,
          onTimeGraceMinutes: StatisticsService.onTimeGraceMinutes,
        )) {
          case IntakeLogStatus.taken:
            takenCount++;
            break;
          case IntakeLogStatus.delayed:
            delayedCount++;
            break;
          case IntakeLogStatus.missed:
            missedCount++;
            break;
          case IntakeLogStatus.skipped:
            skippedCount++;
            break;
          case IntakeLogStatus.rescheduled:
          case IntakeLogStatus.waiting:
            break;
        }
      }

      statistics.add(
        DailyStatistic(
          date: day,
          scheduledCount: scheduledCount,
          takenCount: takenCount,
          delayedCount: delayedCount,
          missedCount: missedCount,
          skippedCount: skippedCount,
        ),
      );
    }

    return statistics;
  }

  static List<MedicinePerformance> buildMedicinePerformance({
    required List<IntakeLogRecord> records,
    required DateTime now,
  }) {
    final byMedicine = <String, _MedicinePerformanceBuilder>{};

    for (final record in records) {
      if (!record.isFinished(
        now,
        onTimeGraceMinutes: StatisticsService.onTimeGraceMinutes,
      )) {
        continue;
      }

      final builder = byMedicine.putIfAbsent(
        record.medicineId,
        () => _MedicinePerformanceBuilder(
          medicineId: record.medicineId,
          medicineName: record.medicineName,
        ),
      );
      builder.scheduledCount++;

      switch (record.effectiveStatus(
        now,
        onTimeGraceMinutes: StatisticsService.onTimeGraceMinutes,
      )) {
        case IntakeLogStatus.taken:
          builder.takenCount++;
          break;
        case IntakeLogStatus.delayed:
          builder.delayedCount++;
          break;
        case IntakeLogStatus.missed:
          builder.missedCount++;
          break;
        case IntakeLogStatus.skipped:
          builder.skippedCount++;
          break;
        case IntakeLogStatus.rescheduled:
        case IntakeLogStatus.waiting:
          break;
      }
    }

    final performance = byMedicine.values
        .map((builder) => builder.build())
        .toList(growable: false);
    performance.sort(
      (a, b) => a.medicineName.toLowerCase().compareTo(
            b.medicineName.toLowerCase(),
          ),
    );
    return performance;
  }

  static String buildInsightMessage({
    required StatisticsFilter filter,
    required StatisticsSummary current,
    required StatisticsSummary previous,
  }) {
    if (!current.hasFinishedData || !previous.hasFinishedData) {
      return 'There is not enough information to compare this period.';
    }

    final currentPercent = current.adherencePercent.round();
    final delta = current.adherencePercent - previous.adherencePercent;
    final periodLabel = _periodPhrase(filter.rangePreset);

    if (delta.abs() < 0.5) {
      return 'You completed $currentPercent% of your medicine reminders $periodLabel.\nYour adherence is unchanged from the previous period.';
    }

    final roundedDelta = delta.abs().round();
    if (delta > 0) {
      return 'You completed $currentPercent% of your medicine reminders $periodLabel.\nThis is $roundedDelta% better than the previous period.';
    }

    return 'You completed $currentPercent% of your medicine reminders $periodLabel.\nYour adherence is $roundedDelta% lower than the previous period.';
  }

  static int _successfulDayStreak(
    List<IntakeLogRecord> records,
    StatisticsDateRange range,
    DateTime now,
  ) {
    final today = DateTime(now.year, now.month, now.day);
    final end = range.endDate.isAfter(today) ? today : range.endDate;
    final finishedByDay = <DateTime, List<IntakeLogRecord>>{};

    for (final record in records) {
      if (!record.isFinished(
        now,
        onTimeGraceMinutes: StatisticsService.onTimeGraceMinutes,
      )) {
        continue;
      }
      finishedByDay.putIfAbsent(record.day, () => []).add(record);
    }

    var streak = 0;
    for (var day = end;
        !day.isBefore(range.startDate);
        day = day.subtract(const Duration(days: 1))) {
      final dayRecords = finishedByDay[day] ?? const <IntakeLogRecord>[];
      if (dayRecords.isEmpty) continue;

      final hasFailure = dayRecords.any(
        (record) => record.isUnsuccessful(
          now,
          onTimeGraceMinutes: StatisticsService.onTimeGraceMinutes,
        ),
      );
      if (hasFailure) break;
      streak++;
    }

    return streak;
  }

  static String? _mostFrequentString(Map<String, int> counts) {
    if (counts.isEmpty) return null;
    final entries = counts.entries.toList()
      ..sort((a, b) {
        final countCompare = b.value.compareTo(a.value);
        if (countCompare != 0) return countCompare;
        return a.key.toLowerCase().compareTo(b.key.toLowerCase());
      });
    return entries.first.key;
  }

  static String? _mostFrequentTime(Map<int, int> counts) {
    if (counts.isEmpty) return null;
    final entries = counts.entries.toList()
      ..sort((a, b) {
        final countCompare = b.value.compareTo(a.value);
        if (countCompare != 0) return countCompare;
        return a.key.compareTo(b.key);
      });
    return _formatTime(entries.first.key);
  }

  static String _formatTime(int minuteOfDay) {
    final hour = minuteOfDay ~/ 60;
    final minute = minuteOfDay % 60;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour % 12 == 0 ? 12 : hour % 12;
    return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
  }

  static String _periodPhrase(StatisticsRangePreset preset) {
    switch (preset) {
      case StatisticsRangePreset.today:
        return 'today';
      case StatisticsRangePreset.sevenDays:
        return 'over the last 7 days';
      case StatisticsRangePreset.thirtyDays:
        return 'over the last 30 days';
      case StatisticsRangePreset.custom:
        return 'during this period';
    }
  }
}

class _MedicinePerformanceBuilder {
  final String medicineId;
  final String medicineName;
  int scheduledCount = 0;
  int takenCount = 0;
  int delayedCount = 0;
  int missedCount = 0;
  int skippedCount = 0;

  _MedicinePerformanceBuilder({
    required this.medicineId,
    required this.medicineName,
  });

  MedicinePerformance build() {
    return MedicinePerformance(
      medicineId: medicineId,
      medicineName: medicineName,
      scheduledCount: scheduledCount,
      takenCount: takenCount,
      delayedCount: delayedCount,
      missedCount: missedCount,
      skippedCount: skippedCount,
    );
  }
}
