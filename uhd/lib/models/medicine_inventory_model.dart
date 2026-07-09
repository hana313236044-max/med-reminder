import 'package:cloud_firestore/cloud_firestore.dart';

enum InventoryQuantityUnit {
  tablets,
  capsules,
  milliliters,
  drops,
  spoons,
  injections,
  units,
  patches,
  sachets,
  applications,
  other,
}

enum InventoryStatus {
  goodSupply,
  lowStock,
  outOfStock,
  expiringSoon,
  expired,
  trackingDisabled,
}

enum InventoryTransactionType {
  initialStock,
  stockAdded,
  doseTaken,
  doseReversed,
  manualAdjustment,
  discarded,
  expired,
  inventoryEnabled,
  inventoryDisabled,
}

enum InventorySortOption {
  medicineName,
  lowestQuantity,
  highestQuantity,
  expirationDate,
  fewestDaysRemaining,
  recentlyUpdated,
}

enum InventoryStatusFilter {
  all,
  goodSupply,
  lowStock,
  outOfStock,
  expiringSoon,
  expired,
  trackingDisabled,
}

enum InventoryMedicineVisibility { active, archived, all }

class MedicineInventory {
  final String id;
  final String userId;
  final String medicineId;
  final String quantityUnitKey;
  final String? customQuantityUnit;
  final double? packageQuantity;
  final double currentQuantity;
  final double? defaultDoseQuantity;
  final double? lowStockThreshold;
  final DateTime? expirationDate;
  final bool trackingEnabled;
  final String? notes;
  final bool lowStockAlertSent;
  final DateTime? lastLowStockAlertAt;
  final bool outOfStockAlertSent;
  final DateTime? lastOutOfStockAlertAt;
  final bool expirationAlertSent;
  final DateTime? lastExpirationAlertAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const MedicineInventory({
    required this.id,
    required this.userId,
    required this.medicineId,
    required this.quantityUnitKey,
    required this.currentQuantity,
    this.customQuantityUnit,
    this.packageQuantity,
    this.defaultDoseQuantity,
    this.lowStockThreshold,
    this.expirationDate,
    this.trackingEnabled = true,
    this.notes,
    this.lowStockAlertSent = false,
    this.lastLowStockAlertAt,
    this.outOfStockAlertSent = false,
    this.lastOutOfStockAlertAt,
    this.expirationAlertSent = false,
    this.lastExpirationAlertAt,
    this.createdAt,
    this.updatedAt,
  });

  factory MedicineInventory.empty({
    required String userId,
    required String medicineId,
  }) {
    return MedicineInventory(
      id: medicineId,
      userId: userId,
      medicineId: medicineId,
      quantityUnitKey: InventoryQuantityUnit.tablets.name,
      currentQuantity: 0,
      defaultDoseQuantity: 1,
      trackingEnabled: true,
    );
  }

  factory MedicineInventory.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    return MedicineInventory.fromMap(doc.id, doc.data() ?? {});
  }

  factory MedicineInventory.fromMap(String id, Map<String, dynamic> data) {
    final quantityUnit =
        _readString(data['quantityUnitKey']).isNotEmpty
            ? _readString(data['quantityUnitKey'])
            : _readString(data['quantityUnit']).isNotEmpty
                ? _readString(data['quantityUnit'])
                : InventoryQuantityUnit.tablets.name;

    return MedicineInventory(
      id: id,
      userId: _readString(data['userId']),
      medicineId: _readString(data['medicineId']).isNotEmpty
          ? _readString(data['medicineId'])
          : id,
      quantityUnitKey: quantityUnit,
      customQuantityUnit: _readNullableString(data['customQuantityUnit']),
      packageQuantity: _readNullableDouble(data['packageQuantity']),
      currentQuantity: _readDouble(data['currentQuantity']),
      defaultDoseQuantity: _readNullableDouble(data['defaultDoseQuantity']),
      lowStockThreshold: _readNullableDouble(data['lowStockThreshold']),
      expirationDate: _readDateTime(data['expirationDate']),
      trackingEnabled: data['trackingEnabled'] as bool? ?? true,
      notes: _readNullableString(data['notes']),
      lowStockAlertSent: data['lowStockAlertSent'] as bool? ?? false,
      lastLowStockAlertAt: _readDateTime(data['lastLowStockAlertAt']),
      outOfStockAlertSent: data['outOfStockAlertSent'] as bool? ?? false,
      lastOutOfStockAlertAt: _readDateTime(data['lastOutOfStockAlertAt']),
      expirationAlertSent: data['expirationAlertSent'] as bool? ?? false,
      lastExpirationAlertAt: _readDateTime(data['lastExpirationAlertAt']),
      createdAt: _readDateTime(data['createdAt']),
      updatedAt: _readDateTime(data['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'medicineId': medicineId,
      'quantityUnitKey': quantityUnitKey,
      'quantityUnit': quantityUnitKey,
      'customQuantityUnit': customQuantityUnit,
      'packageQuantity': packageQuantity,
      'currentQuantity': currentQuantity,
      'defaultDoseQuantity': defaultDoseQuantity,
      'lowStockThreshold': lowStockThreshold,
      'expirationDate': expirationDate == null
          ? null
          : Timestamp.fromDate(expirationDate!),
      'trackingEnabled': trackingEnabled,
      'notes': notes,
      'lowStockAlertSent': lowStockAlertSent,
      'lastLowStockAlertAt': lastLowStockAlertAt == null
          ? null
          : Timestamp.fromDate(lastLowStockAlertAt!),
      'outOfStockAlertSent': outOfStockAlertSent,
      'lastOutOfStockAlertAt': lastOutOfStockAlertAt == null
          ? null
          : Timestamp.fromDate(lastOutOfStockAlertAt!),
      'expirationAlertSent': expirationAlertSent,
      'lastExpirationAlertAt': lastExpirationAlertAt == null
          ? null
          : Timestamp.fromDate(lastExpirationAlertAt!),
      'createdAt': createdAt == null ? null : Timestamp.fromDate(createdAt!),
      'updatedAt': updatedAt == null ? null : Timestamp.fromDate(updatedAt!),
    };
  }

  MedicineInventory copyWith({
    String? id,
    String? userId,
    String? medicineId,
    String? quantityUnitKey,
    String? customQuantityUnit,
    double? packageQuantity,
    double? currentQuantity,
    double? defaultDoseQuantity,
    double? lowStockThreshold,
    DateTime? expirationDate,
    bool? trackingEnabled,
    String? notes,
    bool? lowStockAlertSent,
    DateTime? lastLowStockAlertAt,
    bool? outOfStockAlertSent,
    DateTime? lastOutOfStockAlertAt,
    bool? expirationAlertSent,
    DateTime? lastExpirationAlertAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MedicineInventory(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      medicineId: medicineId ?? this.medicineId,
      quantityUnitKey: quantityUnitKey ?? this.quantityUnitKey,
      customQuantityUnit: customQuantityUnit ?? this.customQuantityUnit,
      packageQuantity: packageQuantity ?? this.packageQuantity,
      currentQuantity: currentQuantity ?? this.currentQuantity,
      defaultDoseQuantity: defaultDoseQuantity ?? this.defaultDoseQuantity,
      lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
      expirationDate: expirationDate ?? this.expirationDate,
      trackingEnabled: trackingEnabled ?? this.trackingEnabled,
      notes: notes ?? this.notes,
      lowStockAlertSent: lowStockAlertSent ?? this.lowStockAlertSent,
      lastLowStockAlertAt: lastLowStockAlertAt ?? this.lastLowStockAlertAt,
      outOfStockAlertSent:
          outOfStockAlertSent ?? this.outOfStockAlertSent,
      lastOutOfStockAlertAt:
          lastOutOfStockAlertAt ?? this.lastOutOfStockAlertAt,
      expirationAlertSent: expirationAlertSent ?? this.expirationAlertSent,
      lastExpirationAlertAt:
          lastExpirationAlertAt ?? this.lastExpirationAlertAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class InventoryTransactionRecord {
  final String id;
  final String userId;
  final String inventoryId;
  final String medicineId;
  final String? reminderId;
  final String? intakeLogId;
  final String? occurrenceId;
  final InventoryTransactionType type;
  final double quantityChange;
  final double previousQuantity;
  final double newQuantity;
  final String quantityUnitKey;
  final String? customQuantityUnit;
  final String? reason;
  final String? notes;
  final bool isAutomatic;
  final DateTime? createdAt;

  const InventoryTransactionRecord({
    required this.id,
    required this.userId,
    required this.inventoryId,
    required this.medicineId,
    required this.type,
    required this.quantityChange,
    required this.previousQuantity,
    required this.newQuantity,
    required this.quantityUnitKey,
    this.customQuantityUnit,
    this.reminderId,
    this.intakeLogId,
    this.occurrenceId,
    this.reason,
    this.notes,
    this.isAutomatic = false,
    this.createdAt,
  });

  factory InventoryTransactionRecord.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    return InventoryTransactionRecord.fromMap(doc.id, doc.data() ?? {});
  }

  factory InventoryTransactionRecord.fromMap(
    String id,
    Map<String, dynamic> data,
  ) {
    return InventoryTransactionRecord(
      id: id,
      userId: _readString(data['userId']),
      inventoryId: _readString(data['inventoryId']),
      medicineId: _readString(data['medicineId']),
      reminderId: _readNullableString(data['reminderId']),
      intakeLogId: _readNullableString(data['intakeLogId']),
      occurrenceId: _readNullableString(data['occurrenceId']),
      type: inventoryTransactionTypeFromName(data['type'] as String?),
      quantityChange: _readDouble(data['quantityChange']),
      previousQuantity: _readDouble(data['previousQuantity']),
      newQuantity: _readDouble(data['newQuantity']),
      quantityUnitKey: _readString(data['quantityUnitKey']).isNotEmpty
          ? _readString(data['quantityUnitKey'])
          : _readString(data['quantityUnit']),
      customQuantityUnit: _readNullableString(data['customQuantityUnit']),
      reason: _readNullableString(data['reason']),
      notes: _readNullableString(data['notes']),
      isAutomatic: data['isAutomatic'] as bool? ?? false,
      createdAt: _readDateTime(data['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'inventoryId': inventoryId,
      'medicineId': medicineId,
      'reminderId': reminderId,
      'intakeLogId': intakeLogId,
      'occurrenceId': occurrenceId,
      'type': type.name,
      'quantityChange': quantityChange,
      'previousQuantity': previousQuantity,
      'newQuantity': newQuantity,
      'quantityUnitKey': quantityUnitKey,
      'quantityUnit': quantityUnitKey,
      'customQuantityUnit': customQuantityUnit,
      'reason': reason,
      'notes': notes,
      'isAutomatic': isAutomatic,
      'createdAt': createdAt == null ? null : Timestamp.fromDate(createdAt!),
    };
  }

  InventoryTransactionRecord copyWith({
    String? id,
    String? userId,
    String? inventoryId,
    String? medicineId,
    String? reminderId,
    String? intakeLogId,
    String? occurrenceId,
    InventoryTransactionType? type,
    double? quantityChange,
    double? previousQuantity,
    double? newQuantity,
    String? quantityUnitKey,
    String? customQuantityUnit,
    String? reason,
    String? notes,
    bool? isAutomatic,
    DateTime? createdAt,
  }) {
    return InventoryTransactionRecord(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      inventoryId: inventoryId ?? this.inventoryId,
      medicineId: medicineId ?? this.medicineId,
      reminderId: reminderId ?? this.reminderId,
      intakeLogId: intakeLogId ?? this.intakeLogId,
      occurrenceId: occurrenceId ?? this.occurrenceId,
      type: type ?? this.type,
      quantityChange: quantityChange ?? this.quantityChange,
      previousQuantity: previousQuantity ?? this.previousQuantity,
      newQuantity: newQuantity ?? this.newQuantity,
      quantityUnitKey: quantityUnitKey ?? this.quantityUnitKey,
      customQuantityUnit: customQuantityUnit ?? this.customQuantityUnit,
      reason: reason ?? this.reason,
      notes: notes ?? this.notes,
      isAutomatic: isAutomatic ?? this.isAutomatic,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class InventoryFilter {
  final String searchQuery;
  final InventoryStatusFilter status;
  final String? medicineId;
  final String? medicineForm;
  final InventoryMedicineVisibility medicineVisibility;
  final DateTime? expirationStart;
  final DateTime? expirationEnd;
  final InventorySortOption sortOption;

  const InventoryFilter({
    this.searchQuery = '',
    this.status = InventoryStatusFilter.all,
    this.medicineId,
    this.medicineForm,
    this.medicineVisibility = InventoryMedicineVisibility.active,
    this.expirationStart,
    this.expirationEnd,
    this.sortOption = InventorySortOption.recentlyUpdated,
  });

  bool get hasActiveFilters {
    return searchQuery.trim().isNotEmpty ||
        status != InventoryStatusFilter.all ||
        medicineId != null ||
        medicineForm != null ||
        medicineVisibility != InventoryMedicineVisibility.active ||
        expirationStart != null ||
        expirationEnd != null;
  }

  InventoryFilter copyWith({
    String? searchQuery,
    InventoryStatusFilter? status,
    String? medicineId,
    String? medicineForm,
    InventoryMedicineVisibility? medicineVisibility,
    DateTime? expirationStart,
    DateTime? expirationEnd,
    InventorySortOption? sortOption,
    bool clearMedicineId = false,
    bool clearMedicineForm = false,
    bool clearExpiration = false,
  }) {
    return InventoryFilter(
      searchQuery: searchQuery ?? this.searchQuery,
      status: status ?? this.status,
      medicineId: clearMedicineId ? null : medicineId ?? this.medicineId,
      medicineForm:
          clearMedicineForm ? null : medicineForm ?? this.medicineForm,
      medicineVisibility: medicineVisibility ?? this.medicineVisibility,
      expirationStart:
          clearExpiration ? null : expirationStart ?? this.expirationStart,
      expirationEnd: clearExpiration ? null : expirationEnd ?? this.expirationEnd,
      sortOption: sortOption ?? this.sortOption,
    );
  }

  InventoryFilter resetFilters() {
    return InventoryFilter(sortOption: sortOption);
  }
}

InventoryTransactionType inventoryTransactionTypeFromName(String? value) {
  final normalized = (value ?? '').replaceAll('_', '').toLowerCase();
  for (final type in InventoryTransactionType.values) {
    if (type.name.toLowerCase() == normalized) return type;
    if (_snakeCase(type.name).replaceAll('_', '') == normalized) return type;
  }
  return InventoryTransactionType.manualAdjustment;
}

String inventoryQuantityUnitLabel(
  String key, {
  String? customQuantityUnit,
  bool plural = true,
}) {
  if (key == InventoryQuantityUnit.other.name) {
    final custom = customQuantityUnit?.trim();
    return custom == null || custom.isEmpty ? 'units' : custom;
  }

  switch (InventoryQuantityUnit.values.firstWhere(
    (unit) => unit.name == key,
    orElse: () => InventoryQuantityUnit.units,
  )) {
    case InventoryQuantityUnit.tablets:
      return plural ? 'tablets' : 'tablet';
    case InventoryQuantityUnit.capsules:
      return plural ? 'capsules' : 'capsule';
    case InventoryQuantityUnit.milliliters:
      return 'milliliters';
    case InventoryQuantityUnit.drops:
      return plural ? 'drops' : 'drop';
    case InventoryQuantityUnit.spoons:
      return plural ? 'spoons' : 'spoon';
    case InventoryQuantityUnit.injections:
      return plural ? 'injections' : 'injection';
    case InventoryQuantityUnit.units:
      return plural ? 'units' : 'unit';
    case InventoryQuantityUnit.patches:
      return plural ? 'patches' : 'patch';
    case InventoryQuantityUnit.sachets:
      return plural ? 'sachets' : 'sachet';
    case InventoryQuantityUnit.applications:
      return plural ? 'applications' : 'application';
    case InventoryQuantityUnit.other:
      return 'units';
  }
}

String inventoryStatusLabel(InventoryStatus status) {
  switch (status) {
    case InventoryStatus.goodSupply:
      return 'Good supply';
    case InventoryStatus.lowStock:
      return 'Low stock';
    case InventoryStatus.outOfStock:
      return 'Out of stock';
    case InventoryStatus.expiringSoon:
      return 'Expiring soon';
    case InventoryStatus.expired:
      return 'Expired';
    case InventoryStatus.trackingDisabled:
      return 'Tracking disabled';
  }
}

String inventoryTransactionTypeLabel(InventoryTransactionType type) {
  switch (type) {
    case InventoryTransactionType.initialStock:
      return 'Initial stock';
    case InventoryTransactionType.stockAdded:
      return 'Stock added';
    case InventoryTransactionType.doseTaken:
      return 'Dose taken';
    case InventoryTransactionType.doseReversed:
      return 'Dose reversed';
    case InventoryTransactionType.manualAdjustment:
      return 'Manual adjustment';
    case InventoryTransactionType.discarded:
      return 'Discarded';
    case InventoryTransactionType.expired:
      return 'Expired';
    case InventoryTransactionType.inventoryEnabled:
      return 'Inventory enabled';
    case InventoryTransactionType.inventoryDisabled:
      return 'Inventory disabled';
  }
}

String inventorySortLabel(InventorySortOption option) {
  switch (option) {
    case InventorySortOption.medicineName:
      return 'Medicine Name';
    case InventorySortOption.lowestQuantity:
      return 'Lowest Quantity';
    case InventorySortOption.highestQuantity:
      return 'Highest Quantity';
    case InventorySortOption.expirationDate:
      return 'Expiration Date';
    case InventorySortOption.fewestDaysRemaining:
      return 'Fewest Days Remaining';
    case InventorySortOption.recentlyUpdated:
      return 'Most Recently Updated';
  }
}

String inventoryStatusFilterLabel(InventoryStatusFilter filter) {
  switch (filter) {
    case InventoryStatusFilter.all:
      return 'All';
    case InventoryStatusFilter.goodSupply:
      return 'Good Supply';
    case InventoryStatusFilter.lowStock:
      return 'Low Stock';
    case InventoryStatusFilter.outOfStock:
      return 'Out of Stock';
    case InventoryStatusFilter.expiringSoon:
      return 'Expiring Soon';
    case InventoryStatusFilter.expired:
      return 'Expired';
    case InventoryStatusFilter.trackingDisabled:
      return 'Tracking Disabled';
  }
}

String inventoryMedicineVisibilityLabel(InventoryMedicineVisibility value) {
  switch (value) {
    case InventoryMedicineVisibility.active:
      return 'Active medicines';
    case InventoryMedicineVisibility.archived:
      return 'Archived medicines';
    case InventoryMedicineVisibility.all:
      return 'Active and archived';
  }
}

String formatInventoryQuantity(double value) {
  if (value == value.roundToDouble()) return value.round().toString();
  return value.toStringAsFixed(2).replaceFirst(RegExp(r'0+$'), '').replaceFirst(
        RegExp(r'\.$'),
        '',
      );
}

String _snakeCase(String value) {
  return value.replaceAllMapped(
    RegExp('[A-Z]'),
    (match) => '_${match.group(0)!.toLowerCase()}',
  );
}

String _readString(Object? value) => value?.toString() ?? '';

String? _readNullableString(Object? value) {
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? null : text;
}

double _readDouble(Object? value) => _readNullableDouble(value) ?? 0;

double? _readNullableDouble(Object? value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}

DateTime? _readDateTime(Object? value) {
  if (value is Timestamp) return value.toDate().toLocal();
  if (value is DateTime) return value.toLocal();
  if (value is String) return DateTime.tryParse(value)?.toLocal();
  return null;
}
