import 'dart:math' as math;

import 'package:uhd/models/medicine_inventory_model.dart';
import 'package:uhd/models/medicine_models.dart';

class InventoryCalculator {
  static const int defaultExpirationWarningDays = 30;

  const InventoryCalculator();

  InventoryStatus statusFor(
    MedicineInventory inventory, {
    DateTime? now,
    int expirationWarningDays = defaultExpirationWarningDays,
  }) {
    final current = now ?? DateTime.now();
    final today = DateTime(current.year, current.month, current.day);
    final expiration = inventory.expirationDate == null
        ? null
        : DateTime(
            inventory.expirationDate!.year,
            inventory.expirationDate!.month,
            inventory.expirationDate!.day,
          );

    // Tracking disabled intentionally overrides quantity and expiration status.
    if (!inventory.trackingEnabled) return InventoryStatus.trackingDisabled;
    if (expiration != null && expiration.isBefore(today)) {
      return InventoryStatus.expired;
    }
    if (inventory.currentQuantity <= 0) return InventoryStatus.outOfStock;
    if (expiration != null &&
        !expiration.isAfter(
          today.add(Duration(days: expirationWarningDays)),
        )) {
      return InventoryStatus.expiringSoon;
    }
    final threshold = inventory.lowStockThreshold;
    if (threshold != null &&
        inventory.currentQuantity > 0 &&
        inventory.currentQuantity <= threshold) {
      return InventoryStatus.lowStock;
    }
    return InventoryStatus.goodSupply;
  }

  int? estimatedDosesRemaining(MedicineInventory inventory) {
    final dose = inventory.defaultDoseQuantity;
    if (dose == null || dose <= 0 || inventory.currentQuantity < 0) {
      return null;
    }
    return math.max(0, (inventory.currentQuantity / dose).floor());
  }

  int? estimatedDaysRemaining({
    required MedicineInventory inventory,
    required Iterable<MedicationReminder> reminders,
    DateTime? now,
  }) {
    final relevant = reminders.where((reminder) {
      if (reminder.medicineId.toString() != inventory.medicineId) {
        return false;
      }
      if (reminder.quantity <= 0) return false;
      return true;
    }).toList()
      ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));

    if (relevant.isEmpty || inventory.currentQuantity < 0) return null;

    var expectedQuantity = 0.0;
    for (final reminder in relevant) {
      final reminderDose = reminder.quantity > 0
          ? reminder.quantity.toDouble()
          : inventory.defaultDoseQuantity;
      if (reminderDose == null || reminderDose <= 0) continue;
      expectedQuantity += reminderDose;
    }
    if (expectedQuantity <= 0) return null;

    final firstDay = DateTime(
      relevant.first.scheduledAt.year,
      relevant.first.scheduledAt.month,
      relevant.first.scheduledAt.day,
    );
    final lastDay = DateTime(
      relevant.last.scheduledAt.year,
      relevant.last.scheduledAt.month,
      relevant.last.scheduledAt.day,
    );
    final coveredDays = math.max(1, lastDay.difference(firstDay).inDays + 1);
    final averageDailyUse = expectedQuantity / coveredDays;
    if (averageDailyUse <= 0) return null;
    return math.max(0, (inventory.currentQuantity / averageDailyUse).floor());
  }

  bool isExpiringSoon(
    MedicineInventory inventory, {
    DateTime? now,
    int expirationWarningDays = defaultExpirationWarningDays,
  }) {
    return statusFor(
          inventory,
          now: now,
          expirationWarningDays: expirationWarningDays,
        ) ==
        InventoryStatus.expiringSoon;
  }
}
