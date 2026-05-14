import 'package:flutter/material.dart';

enum ReminderStatus { waiting, completed }

class Medicine {
  final int id;
  String name;
  String category;
  String form;
  String ageGroup;
  String? notes;

  Medicine({
    required this.id,
    required this.name,
    required this.category,
    required this.form,
    required this.ageGroup,
    this.notes,
  });
}

class MedicationReminder {
  final int id;
  final int medicineId;
  String medicineName;
  String medicineCategory;
  String medicineForm;
  DateTime scheduledAt;
  int quantity;
  String quantityUnit;
  String scheduleLabel;
  String? notes;
  ReminderStatus status;
  bool isRescheduled;

  MedicationReminder({
    required this.id,
    required this.medicineId,
    required this.medicineName,
    required this.medicineCategory,
    required this.medicineForm,
    required this.scheduledAt,
    required this.quantity,
    required this.quantityUnit,
    required this.scheduleLabel,
    this.notes,
    this.status = ReminderStatus.waiting,
    this.isRescheduled = false,
  });

  bool get isDelayed {
    final now = DateTime.now();
    return status == ReminderStatus.waiting &&
        _isSameDay(scheduledAt, now) &&
        scheduledAt.isBefore(now);
  }

  bool get isNotTaken {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final scheduledDay = DateTime(
      scheduledAt.year,
      scheduledAt.month,
      scheduledAt.day,
    );
    return status == ReminderStatus.waiting && scheduledDay.isBefore(today);
  }

  bool get isCompleted => status == ReminderStatus.completed;

  TimeOfDay get time => TimeOfDay.fromDateTime(scheduledAt);

  bool _isSameDay(DateTime first, DateTime second) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }
}
