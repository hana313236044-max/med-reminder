class StatisticsSummary {
  final int finishedCount;
  final int takenCount;
  final int delayedCount;
  final int missedCount;
  final int skippedCount;
  final int rescheduledCount;
  final int waitingCount;
  final int onTimeTakenCount;
  final String? mostMissedMedicine;
  final String? mostMissedTime;
  final int currentStreakDays;

  const StatisticsSummary({
    required this.finishedCount,
    required this.takenCount,
    required this.delayedCount,
    required this.missedCount,
    required this.skippedCount,
    required this.rescheduledCount,
    required this.waitingCount,
    required this.onTimeTakenCount,
    required this.mostMissedMedicine,
    required this.mostMissedTime,
    required this.currentStreakDays,
  });

  int get completedCount => takenCount + delayedCount;

  int get unsuccessfulCount => missedCount + skippedCount;

  bool get hasFinishedData => finishedCount > 0;

  double get adherencePercent {
    if (finishedCount == 0) return 0;
    return completedCount / finishedCount * 100;
  }

  double get onTimeAdherencePercent {
    if (finishedCount == 0) return 0;
    return onTimeTakenCount / finishedCount * 100;
  }
}
