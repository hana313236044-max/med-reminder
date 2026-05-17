import 'package:cloud_firestore/cloud_firestore.dart';
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

  factory Medicine.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return Medicine(
      id: int.tryParse(doc.id) ?? (data['id'] as num?)?.toInt() ?? 0,
      name: data['name'] as String? ?? '',
      category: data['category'] as String? ?? '',
      form: data['form'] as String? ?? '',
      ageGroup: data['ageGroup'] as String? ?? '',
      notes: data['notes'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'form': form,
      'ageGroup': ageGroup,
      'notes': notes,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
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

  factory MedicationReminder.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    final scheduledValue = data['scheduledAt'];
    final scheduledAt = scheduledValue is Timestamp
        ? scheduledValue.toDate()
        : DateTime.tryParse(scheduledValue?.toString() ?? '') ??
              DateTime.now();
    final statusName = data['status'] as String?;

    return MedicationReminder(
      id: int.tryParse(doc.id) ?? (data['id'] as num?)?.toInt() ?? 0,
      medicineId: (data['medicineId'] as num?)?.toInt() ?? 0,
      medicineName: data['medicineName'] as String? ?? '',
      medicineCategory: data['medicineCategory'] as String? ?? '',
      medicineForm: data['medicineForm'] as String? ?? '',
      scheduledAt: scheduledAt,
      quantity: (data['quantity'] as num?)?.toInt() ?? 1,
      quantityUnit: data['quantityUnit'] as String? ?? 'units',
      scheduleLabel: data['scheduleLabel'] as String? ?? 'One time',
      notes: data['notes'] as String?,
      status: ReminderStatus.values.firstWhere(
        (status) => status.name == statusName,
        orElse: () => ReminderStatus.waiting,
      ),
      isRescheduled: data['isRescheduled'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'medicineId': medicineId,
      'medicineName': medicineName,
      'medicineCategory': medicineCategory,
      'medicineForm': medicineForm,
      'scheduledAt': Timestamp.fromDate(scheduledAt),
      'quantity': quantity,
      'quantityUnit': quantityUnit,
      'scheduleLabel': scheduleLabel,
      'notes': notes,
      'status': status.name,
      'isRescheduled': isRescheduled,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

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
