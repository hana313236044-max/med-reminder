class MedicinePerformance {
  final String medicineId;
  final String medicineName;
  final int scheduledCount;
  final int takenCount;
  final int delayedCount;
  final int missedCount;
  final int skippedCount;

  const MedicinePerformance({
    required this.medicineId,
    required this.medicineName,
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
