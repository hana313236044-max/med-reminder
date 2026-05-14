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
  });

  bool get isDelayed =>
      status == ReminderStatus.waiting && scheduledAt.isBefore(DateTime.now());

  bool get isCompleted => status == ReminderStatus.completed;

  TimeOfDay get time => TimeOfDay.fromDateTime(scheduledAt);
}
