import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uhd/models/medicine_inventory_model.dart';
import 'package:uhd/models/medicine_models.dart';
import 'package:uhd/services/inventory_calculator.dart';

class InventoryServiceException implements Exception {
  final String message;

  const InventoryServiceException(this.message);

  @override
  String toString() => message;
}

class InventoryDoseDeduction {
  final String transactionId;
  final double requestedQuantity;
  final double deductedQuantity;
  final double previousQuantity;
  final double newQuantity;
  final bool duplicate;

  const InventoryDoseDeduction({
    required this.transactionId,
    required this.requestedQuantity,
    required this.deductedQuantity,
    required this.previousQuantity,
    required this.newQuantity,
    this.duplicate = false,
  });
}

class InventoryService {
  final FirebaseFirestore firestore;
  final FirebaseAuth auth;
  final InventoryCalculator calculator;

  InventoryService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    InventoryCalculator? calculator,
  })  : firestore = firestore ?? FirebaseFirestore.instance,
        auth = auth ?? FirebaseAuth.instance,
        calculator = calculator ?? const InventoryCalculator();

  String get _uid {
    final user = auth.currentUser;
    if (user == null) {
      throw const InventoryServiceException(
        'Please sign in to manage inventory.',
      );
    }
    return user.uid;
  }

  DocumentReference<Map<String, dynamic>> _userRef(String uid) {
    return firestore.collection('users').doc(uid);
  }

  CollectionReference<Map<String, dynamic>> _inventoryRef(String uid) {
    return _userRef(uid).collection('medicineInventory');
  }

  CollectionReference<Map<String, dynamic>> _transactionsRef(String uid) {
    return _userRef(uid).collection('inventoryTransactions');
  }

  CollectionReference<Map<String, dynamic>> _medicinesRef(String uid) {
    return _userRef(uid).collection('medicines');
  }

  CollectionReference<Map<String, dynamic>> _remindersRef(String uid) {
    return _userRef(uid).collection('reminders');
  }

  String inventoryIdForMedicine(Object medicineId) => medicineId.toString();

  Stream<List<MedicineInventory>> watchInventories() {
    final uid = _uid;
    return _inventoryRef(uid)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map(MedicineInventory.fromFirestore).toList(),
        );
  }

  Stream<List<InventoryTransactionRecord>> watchTransactions({
    String? inventoryId,
    int limit = 80,
  }) {
    final uid = _uid;
    final query = _transactionsRef(uid)
        .orderBy('createdAt', descending: true)
        .limit(limit);
    final stream = query.snapshots().map(
          (snapshot) =>
              snapshot.docs.map(InventoryTransactionRecord.fromFirestore).toList(),
        );
    if (inventoryId == null) {
      return stream;
    }
    return stream.map(
      (records) => records
          .where((record) => record.inventoryId == inventoryId)
          .toList(),
    );
  }

  Stream<List<Medicine>> watchMedicines() {
    final uid = _uid;
    return _medicinesRef(uid).orderBy('name').snapshots().map(
          (snapshot) => snapshot.docs.map(Medicine.fromFirestore).toList(),
        );
  }

  Stream<List<MedicationReminder>> watchReminders() {
    final uid = _uid;
    return _remindersRef(uid).orderBy('scheduledAt').snapshots().map(
          (snapshot) =>
              snapshot.docs.map(MedicationReminder.fromFirestore).toList(),
        );
  }

  Future<void> createInventory(MedicineInventory inventory) async {
    final uid = _uid;
    final inventoryId = inventoryIdForMedicine(inventory.medicineId);
    final inventoryDoc = _inventoryRef(uid).doc(inventoryId);
    final transactionDoc = _transactionsRef(uid).doc();

    await firestore.runTransaction((transaction) async {
      final existing = await transaction.get(inventoryDoc);
      final existingData = existing.data();
      if (existing.exists) {
        final current = MedicineInventory.fromFirestore(existing);
        if (current.trackingEnabled) {
          throw const InventoryServiceException(
            'This medicine already has active inventory tracking.',
          );
        }
      }

      final data = {
        ...inventory.copyWith(id: inventoryId, userId: uid).toMap(),
        'createdAt': existingData == null
            ? FieldValue.serverTimestamp()
            : existingData['createdAt'],
        'updatedAt': FieldValue.serverTimestamp(),
        'lowStockAlertSent': _shouldSendLowStockAlert(inventory),
        'outOfStockAlertSent': inventory.currentQuantity <= 0,
      };
      transaction.set(inventoryDoc, data, SetOptions(merge: true));
      transaction.set(transactionDoc, {
        ...InventoryTransactionRecord(
          id: transactionDoc.id,
          userId: uid,
          inventoryId: inventoryId,
          medicineId: inventory.medicineId,
          type: inventory.currentQuantity > 0
              ? InventoryTransactionType.initialStock
              : InventoryTransactionType.inventoryEnabled,
          quantityChange: inventory.currentQuantity,
          previousQuantity: 0,
          newQuantity: inventory.currentQuantity,
          quantityUnitKey: inventory.quantityUnitKey,
          customQuantityUnit: inventory.customQuantityUnit,
          reason: 'Inventory tracking enabled',
          notes: inventory.notes,
          isAutomatic: false,
        ).toMap(),
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> updateInventory(MedicineInventory updated) async {
    final uid = _uid;
    final inventoryDoc = _inventoryRef(uid).doc(updated.id);
    final transactionDoc = _transactionsRef(uid).doc();

    await firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(inventoryDoc);
      if (!snapshot.exists) {
        throw const InventoryServiceException('Inventory record not found.');
      }
      final current = MedicineInventory.fromFirestore(snapshot);
      final quantityChanged =
          (current.currentQuantity - updated.currentQuantity).abs() > 0.0001;
      final trackingChanged =
          current.trackingEnabled != updated.trackingEnabled;

      transaction.set(inventoryDoc, {
        ...updated.copyWith(userId: uid).toMap(),
        'createdAt': snapshot.data()?['createdAt'] ?? FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'lowStockAlertSent': _alertStateAfterQuantityChange(updated),
        'outOfStockAlertSent': updated.currentQuantity <= 0,
      }, SetOptions(merge: true));

      if (quantityChanged || trackingChanged) {
        final type = trackingChanged
            ? updated.trackingEnabled
                ? InventoryTransactionType.inventoryEnabled
                : InventoryTransactionType.inventoryDisabled
            : InventoryTransactionType.manualAdjustment;
        transaction.set(transactionDoc, {
          ...InventoryTransactionRecord(
            id: transactionDoc.id,
            userId: uid,
            inventoryId: updated.id,
            medicineId: updated.medicineId,
            type: type,
            quantityChange: updated.currentQuantity - current.currentQuantity,
            previousQuantity: current.currentQuantity,
            newQuantity: updated.currentQuantity,
            quantityUnitKey: updated.quantityUnitKey,
            customQuantityUnit: updated.customQuantityUnit,
            reason: trackingChanged
                ? (updated.trackingEnabled
                    ? 'Inventory tracking enabled'
                    : 'Inventory tracking disabled')
                : 'Inventory settings updated',
            notes: updated.notes,
            isAutomatic: false,
          ).toMap(),
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    });
  }

  Future<void> addStock({
    required String inventoryId,
    required double quantityAdded,
    DateTime? refillDate,
    DateTime? expirationDate,
    String? lotNumber,
    String? notes,
  }) async {
    if (quantityAdded <= 0) {
      throw const InventoryServiceException(
        'Quantity added must be greater than zero.',
      );
    }

    final uid = _uid;
    final inventoryDoc = _inventoryRef(uid).doc(inventoryId);
    final transactionDoc = _transactionsRef(uid).doc();

    await firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(inventoryDoc);
      if (!snapshot.exists) {
        throw const InventoryServiceException('Inventory record not found.');
      }
      final inventory = MedicineInventory.fromFirestore(snapshot);
      final previous = inventory.currentQuantity;
      final next = previous + quantityAdded;
      final nearestExpiration = _nearestExpiration(
        inventory.expirationDate,
        expirationDate,
      );

      transaction.update(inventoryDoc, {
        'currentQuantity': next,
        'expirationDate': nearestExpiration == null
            ? null
            : Timestamp.fromDate(nearestExpiration),
        'lowStockAlertSent': _shouldSendLowStockAlert(
          inventory.copyWith(currentQuantity: next),
        ),
        'lastLowStockAlertAt':
            next > (inventory.lowStockThreshold ?? -1)
                ? null
                : _timestampOrNull(inventory.lastLowStockAlertAt),
        'outOfStockAlertSent': next <= 0,
        'lastOutOfStockAlertAt':
            next > 0 ? null : _timestampOrNull(inventory.lastOutOfStockAlertAt),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      transaction.set(transactionDoc, {
        ...InventoryTransactionRecord(
          id: transactionDoc.id,
          userId: uid,
          inventoryId: inventory.id,
          medicineId: inventory.medicineId,
          type: InventoryTransactionType.stockAdded,
          quantityChange: quantityAdded,
          previousQuantity: previous,
          newQuantity: next,
          quantityUnitKey: inventory.quantityUnitKey,
          customQuantityUnit: inventory.customQuantityUnit,
          reason: refillDate == null
              ? 'Stock added'
              : 'Stock added on ${refillDate.year}/${refillDate.month}/${refillDate.day}',
          notes: [
            if (lotNumber != null && lotNumber.trim().isNotEmpty)
              'Lot: ${lotNumber.trim()}',
            if (notes != null && notes.trim().isNotEmpty) notes.trim(),
          ].join('\n'),
          isAutomatic: false,
        ).toMap(),
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> adjustQuantity({
    required String inventoryId,
    required double newQuantity,
    required String reason,
    String? notes,
  }) async {
    if (newQuantity < 0) {
      throw const InventoryServiceException('New quantity cannot be negative.');
    }

    final uid = _uid;
    final inventoryDoc = _inventoryRef(uid).doc(inventoryId);
    final transactionDoc = _transactionsRef(uid).doc();

    await firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(inventoryDoc);
      if (!snapshot.exists) {
        throw const InventoryServiceException('Inventory record not found.');
      }
      final inventory = MedicineInventory.fromFirestore(snapshot);
      final previous = inventory.currentQuantity;
      final difference = newQuantity - previous;

      transaction.update(inventoryDoc, {
        'currentQuantity': newQuantity,
        'lowStockAlertSent': _shouldSendLowStockAlert(
          inventory.copyWith(currentQuantity: newQuantity),
        ),
        'outOfStockAlertSent': newQuantity <= 0,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      transaction.set(transactionDoc, {
        ...InventoryTransactionRecord(
          id: transactionDoc.id,
          userId: uid,
          inventoryId: inventory.id,
          medicineId: inventory.medicineId,
          type: _transactionTypeForAdjustment(reason, difference),
          quantityChange: difference,
          previousQuantity: previous,
          newQuantity: newQuantity,
          quantityUnitKey: inventory.quantityUnitKey,
          customQuantityUnit: inventory.customQuantityUnit,
          reason: reason,
          notes: notes?.trim().isEmpty == true ? null : notes?.trim(),
          isAutomatic: false,
        ).toMap(),
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> deleteInventory({
    required String inventoryId,
    bool deleteHistory = false,
  }) async {
    final uid = _uid;
    final inventoryDoc = _inventoryRef(uid).doc(inventoryId);
    final batch = firestore.batch();
    batch.delete(inventoryDoc);

    if (deleteHistory) {
      final history = await _transactionsRef(uid)
          .where('inventoryId', isEqualTo: inventoryId)
          .get();
      for (final doc in history.docs) {
        batch.delete(doc.reference);
      }
    }

    await batch.commit();
  }

  Future<InventoryDoseDeduction?> recordDoseTakenInTransaction({
    required Transaction transaction,
    required String userId,
    required MedicationReminder reminder,
    required String intakeLogId,
    required String occurrenceId,
  }) async {
    final inventoryId = inventoryIdForMedicine(reminder.medicineId);
    final inventoryDoc = _inventoryRef(userId).doc(inventoryId);
    final transactionId = 'dose_$occurrenceId';
    final transactionDoc = _transactionsRef(userId).doc(transactionId);

    final inventorySnapshot = await transaction.get(inventoryDoc);
    if (!inventorySnapshot.exists) return null;

    final existingTransaction = await transaction.get(transactionDoc);
    if (existingTransaction.exists) {
      final record = InventoryTransactionRecord.fromFirestore(
        existingTransaction,
      );
      return InventoryDoseDeduction(
        transactionId: record.id,
        requestedQuantity: record.quantityChange.abs(),
        deductedQuantity: 0,
        previousQuantity: record.previousQuantity,
        newQuantity: record.newQuantity,
        duplicate: true,
      );
    }

    final inventory = MedicineInventory.fromFirestore(inventorySnapshot);
    if (!inventory.trackingEnabled) return null;

    final requestedDose = reminder.quantity > 0
        ? reminder.quantity.toDouble()
        : inventory.defaultDoseQuantity;
    if (requestedDose == null || requestedDose <= 0) return null;

    final previous = inventory.currentQuantity;
    final available = math.max(0, previous);
    final deducted = math.min(available, requestedDose);
    final next = math.max(0.0, previous - requestedDose).toDouble();
    final afterDose = inventory.copyWith(currentQuantity: next);
    final now = DateTime.now();

    transaction.update(inventoryDoc, {
      'currentQuantity': next,
      'lowStockAlertSent': _shouldSendLowStockAlert(afterDose),
      'lastLowStockAlertAt':
          _shouldSendLowStockAlert(afterDose) && !inventory.lowStockAlertSent
              ? FieldValue.serverTimestamp()
              : _timestampOrNull(inventory.lastLowStockAlertAt),
      'outOfStockAlertSent': next <= 0,
      'lastOutOfStockAlertAt':
          next <= 0 && !inventory.outOfStockAlertSent
              ? FieldValue.serverTimestamp()
              : _timestampOrNull(inventory.lastOutOfStockAlertAt),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    transaction.set(transactionDoc, {
      ...InventoryTransactionRecord(
        id: transactionId,
        userId: userId,
        inventoryId: inventory.id,
        medicineId: inventory.medicineId,
        reminderId: reminder.id.toString(),
        intakeLogId: intakeLogId,
        occurrenceId: occurrenceId,
        type: InventoryTransactionType.doseTaken,
        quantityChange: -deducted.toDouble(),
        previousQuantity: previous,
        newQuantity: next.toDouble(),
        quantityUnitKey: inventory.quantityUnitKey,
        customQuantityUnit: inventory.customQuantityUnit,
        reason: 'Reminder marked taken',
        notes: deducted <= 0
            ? 'Inventory was already out of stock when this dose was recorded.'
            : null,
        isAutomatic: true,
        createdAt: now,
      ).toMap(),
      'requestedDoseQuantity': requestedDose,
      'createdAt': FieldValue.serverTimestamp(),
    });

    return InventoryDoseDeduction(
      transactionId: transactionId,
      requestedQuantity: requestedDose,
      deductedQuantity: deducted.toDouble(),
      previousQuantity: previous,
      newQuantity: next.toDouble(),
    );
  }

  Future<void> reverseDoseDeduction({
    required String medicineId,
    required String occurrenceId,
    String? reason,
  }) async {
    final uid = _uid;
    final inventoryId = inventoryIdForMedicine(medicineId);
    final inventoryDoc = _inventoryRef(uid).doc(inventoryId);
    final originalDoc = _transactionsRef(uid).doc('dose_$occurrenceId');
    final reversalDoc = _transactionsRef(uid).doc('reverse_$occurrenceId');

    await firestore.runTransaction((transaction) async {
      final inventorySnapshot = await transaction.get(inventoryDoc);
      final originalSnapshot = await transaction.get(originalDoc);
      final reversalSnapshot = await transaction.get(reversalDoc);
      if (!inventorySnapshot.exists ||
          !originalSnapshot.exists ||
          reversalSnapshot.exists) {
        return;
      }

      final inventory = MedicineInventory.fromFirestore(inventorySnapshot);
      final original = InventoryTransactionRecord.fromFirestore(
        originalSnapshot,
      );
      final restored = original.quantityChange.abs();
      final previous = inventory.currentQuantity;
      final next = previous + restored;

      transaction.update(inventoryDoc, {
        'currentQuantity': next,
        'lowStockAlertSent': _shouldSendLowStockAlert(
          inventory.copyWith(currentQuantity: next),
        ),
        'outOfStockAlertSent': next <= 0,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      transaction.set(reversalDoc, {
        ...InventoryTransactionRecord(
          id: reversalDoc.id,
          userId: uid,
          inventoryId: inventory.id,
          medicineId: inventory.medicineId,
          reminderId: original.reminderId,
          intakeLogId: original.intakeLogId,
          occurrenceId: occurrenceId,
          type: InventoryTransactionType.doseReversed,
          quantityChange: restored,
          previousQuantity: previous,
          newQuantity: next,
          quantityUnitKey: inventory.quantityUnitKey,
          customQuantityUnit: inventory.customQuantityUnit,
          reason: reason ?? 'Completed dose was changed',
          isAutomatic: true,
        ).toMap(),
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
  }

  bool _shouldSendLowStockAlert(MedicineInventory inventory) {
    final threshold = inventory.lowStockThreshold;
    return threshold != null &&
        inventory.trackingEnabled &&
        inventory.currentQuantity > 0 &&
        inventory.currentQuantity <= threshold;
  }

  bool _alertStateAfterQuantityChange(MedicineInventory inventory) {
    final threshold = inventory.lowStockThreshold;
    if (threshold == null || inventory.currentQuantity > threshold) {
      return false;
    }
    return _shouldSendLowStockAlert(inventory);
  }

  DateTime? _nearestExpiration(DateTime? current, DateTime? incoming) {
    if (current == null) return incoming;
    if (incoming == null) return current;
    return incoming.isBefore(current) ? incoming : current;
  }

  InventoryTransactionType _transactionTypeForAdjustment(
    String reason,
    double difference,
  ) {
    final normalized = reason.toLowerCase();
    if (difference < 0 && normalized.contains('discard')) {
      return InventoryTransactionType.discarded;
    }
    return InventoryTransactionType.manualAdjustment;
  }

  Object? _timestampOrNull(DateTime? value) {
    return value == null ? null : Timestamp.fromDate(value);
  }
}
