import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:uhd/models/medicine_inventory_model.dart';
import 'package:uhd/models/medicine_models.dart';
import 'package:uhd/services/inventory_calculator.dart';
import 'package:uhd/services/inventory_service.dart';
import 'package:uhd/widgets/app_widgets.dart';

class MedicineInventoryPage extends StatefulWidget {
  final ValueChanged<String>? onMedicineSelected;

  const MedicineInventoryPage({super.key, this.onMedicineSelected});

  @override
  State<MedicineInventoryPage> createState() => _MedicineInventoryPageState();
}

class _MedicineInventoryPageState extends State<MedicineInventoryPage> {
  final InventoryService _service = InventoryService();
  final InventoryCalculator _calculator = const InventoryCalculator();
  final TextEditingController _searchController = TextEditingController();

  StreamSubscription<List<MedicineInventory>>? _inventorySub;
  StreamSubscription<List<Medicine>>? _medicineSub;
  StreamSubscription<List<MedicationReminder>>? _reminderSub;
  StreamSubscription<List<InventoryTransactionRecord>>? _transactionSub;

  List<MedicineInventory> _inventories = [];
  List<Medicine> _medicines = [];
  List<MedicationReminder> _reminders = [];
  List<InventoryTransactionRecord> _recentTransactions = [];
  InventoryFilter _filter = const InventoryFilter();
  String? _error;
  bool _loadedInventories = false;
  bool _loadedMedicines = false;
  bool _loadedReminders = false;

  bool get _isLoading =>
      !_loadedInventories || !_loadedMedicines || !_loadedReminders;

  @override
  void initState() {
    super.initState();
    _listen();
  }

  void _listen() {
    _inventorySub = _service.watchInventories().listen((records) {
      if (!mounted) return;
      setState(() {
        _inventories = records;
        _loadedInventories = true;
        _error = null;
      });
    }, onError: (_) => _setLoadError());

    _medicineSub = _service.watchMedicines().listen((records) {
      if (!mounted) return;
      setState(() {
        _medicines = records;
        _loadedMedicines = true;
        _error = null;
      });
    }, onError: (_) => _setLoadError());

    _reminderSub = _service.watchReminders().listen((records) {
      if (!mounted) return;
      setState(() {
        _reminders = records;
        _loadedReminders = true;
        _error = null;
      });
    }, onError: (_) => _setLoadError());

    _transactionSub = _service.watchTransactions(limit: 8).listen((records) {
      if (!mounted) return;
      setState(() => _recentTransactions = records);
    });
  }

  void _setLoadError() {
    if (!mounted) return;
    setState(() {
      _error = 'Could not load inventory. Please check your connection.';
      _loadedInventories = true;
      _loadedMedicines = true;
      _loadedReminders = true;
    });
  }

  Map<String, Medicine> get _medicineById {
    return {
      for (final medicine in _medicines) medicine.id.toString(): medicine,
    };
  }

  List<_InventoryViewItem> get _items {
    final medicineMap = _medicineById;
    return _inventories.map((inventory) {
      final status = _calculator.statusFor(inventory);
      return _InventoryViewItem(
        inventory: inventory,
        medicine: medicineMap[inventory.medicineId],
        status: status,
        dosesRemaining: _calculator.estimatedDosesRemaining(inventory),
        daysRemaining: _calculator.estimatedDaysRemaining(
          inventory: inventory,
          reminders: _reminders,
        ),
      );
    }).toList();
  }

  List<_InventoryViewItem> get _filteredItems {
    final query = _filter.searchQuery.trim().toLowerCase();
    final items = _items.where((item) {
      if (_filter.medicineVisibility == InventoryMedicineVisibility.active &&
          item.isArchived) {
        return false;
      }
      if (_filter.medicineVisibility == InventoryMedicineVisibility.archived &&
          !item.isArchived) {
        return false;
      }
      if (query.isNotEmpty &&
          !item.medicineName.toLowerCase().contains(query)) {
        return false;
      }
      if (_filter.medicineId != null &&
          item.inventory.medicineId != _filter.medicineId) {
        return false;
      }
      if (_filter.medicineForm != null &&
          item.medicineForm != _filter.medicineForm) {
        return false;
      }
      if (!_matchesStatus(item.status, _filter.status)) {
        return false;
      }
      final expiration = item.inventory.expirationDate;
      if (_filter.expirationStart != null &&
          (expiration == null || expiration.isBefore(_filter.expirationStart!))) {
        return false;
      }
      if (_filter.expirationEnd != null &&
          (expiration == null || expiration.isAfter(_filter.expirationEnd!))) {
        return false;
      }
      return true;
    }).toList();

    items.sort((a, b) {
      switch (_filter.sortOption) {
        case InventorySortOption.medicineName:
          return a.medicineName.toLowerCase().compareTo(
                b.medicineName.toLowerCase(),
              );
        case InventorySortOption.lowestQuantity:
          return a.inventory.currentQuantity.compareTo(
            b.inventory.currentQuantity,
          );
        case InventorySortOption.highestQuantity:
          return b.inventory.currentQuantity.compareTo(
            a.inventory.currentQuantity,
          );
        case InventorySortOption.expirationDate:
          return _dateSort(a.inventory.expirationDate, b.inventory.expirationDate);
        case InventorySortOption.fewestDaysRemaining:
          return _nullableIntSort(a.daysRemaining, b.daysRemaining);
        case InventorySortOption.recentlyUpdated:
          return _dateSortDesc(a.inventory.updatedAt, b.inventory.updatedAt);
      }
    });
    return items;
  }

  _InventorySummary get _summary {
    final activeItems = _items.where((item) => !item.isArchived).toList();
    return _InventorySummary(
      tracked: activeItems
          .where((item) => item.inventory.trackingEnabled)
          .length,
      lowStock: activeItems
          .where((item) => item.status == InventoryStatus.lowStock)
          .length,
      outOfStock: activeItems
          .where((item) => item.status == InventoryStatus.outOfStock)
          .length,
      expiringSoon: activeItems
          .where((item) => item.status == InventoryStatus.expiringSoon)
          .length,
    );
  }

  bool _matchesStatus(InventoryStatus status, InventoryStatusFilter filter) {
    switch (filter) {
      case InventoryStatusFilter.all:
        return true;
      case InventoryStatusFilter.goodSupply:
        return status == InventoryStatus.goodSupply;
      case InventoryStatusFilter.lowStock:
        return status == InventoryStatus.lowStock;
      case InventoryStatusFilter.outOfStock:
        return status == InventoryStatus.outOfStock;
      case InventoryStatusFilter.expiringSoon:
        return status == InventoryStatus.expiringSoon;
      case InventoryStatusFilter.expired:
        return status == InventoryStatus.expired;
      case InventoryStatusFilter.trackingDisabled:
        return status == InventoryStatus.trackingDisabled;
    }
  }

  Future<void> _pickExpirationRange() async {
    final now = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      initialDateRange: _filter.expirationStart == null ||
              _filter.expirationEnd == null
          ? null
          : DateTimeRange(
              start: _filter.expirationStart!,
              end: _filter.expirationEnd!,
            ),
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 10),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: authPrimary,
                  secondary: authAccent,
                ),
          ),
          child: child!,
        );
      },
    );
    if (range == null) return;
    setState(() {
      _filter = _filter.copyWith(
        expirationStart: DateTime(
          range.start.year,
          range.start.month,
          range.start.day,
        ),
        expirationEnd: DateTime(
          range.end.year,
          range.end.month,
          range.end.day,
          23,
          59,
        ),
      );
    });
  }

  void _resetFilters() {
    _searchController.clear();
    setState(() => _filter = _filter.resetFilters());
  }

  Future<void> _openAddInventory() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddInventoryPage(
          medicines: _medicines,
          existingInventories: _inventories,
        ),
      ),
    );
  }

  Future<void> _openEditInventory(_InventoryViewItem item) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddInventoryPage(
          medicines: _medicines,
          existingInventories: _inventories,
          inventory: item.inventory,
        ),
      ),
    );
  }

  Future<void> _openAddStock(_InventoryViewItem item) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddStockPage(
          inventory: item.inventory,
          medicineName: item.medicineName,
        ),
      ),
    );
  }

  Future<void> _openAdjustInventory(_InventoryViewItem item) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AdjustInventoryPage(
          inventory: item.inventory,
          medicineName: item.medicineName,
        ),
      ),
    );
  }

  Future<void> _openHistory([_InventoryViewItem? item]) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => InventoryHistoryPage(
          inventory: item?.inventory,
          medicineName: item?.medicineName,
          medicines: _medicines,
        ),
      ),
    );
  }

  void _openMedicine(_InventoryViewItem item) {
    final medicine = item.medicine;
    if (medicine == null) {
      showAuthMessage(
        context,
        'The related medicine was deleted. Inventory history is still saved.',
        backgroundColor: Colors.redAccent,
      );
      return;
    }
    widget.onMedicineSelected?.call(medicine.id.toString());
  }

  @override
  void dispose() {
    _inventorySub?.cancel();
    _medicineSub?.cancel();
    _reminderSub?.cancel();
    _transactionSub?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const _InventoryLoadingState();
    if (_error != null) {
      return _InventoryErrorState(
        message: _error!,
        onRetry: () {
          setState(() {
            _error = null;
            _loadedInventories = false;
            _loadedMedicines = false;
            _loadedReminders = false;
          });
          _inventorySub?.cancel();
          _medicineSub?.cancel();
          _reminderSub?.cancel();
          _transactionSub?.cancel();
          _listen();
        },
      );
    }

    final items = _filteredItems;
    final summary = _summary;
    final forms = _medicines
        .map((medicine) => medicine.form)
        .where((form) => form.trim().isNotEmpty)
        .toSet()
        .toList()
      ..sort();

    return SafeArea(
      top: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 96),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1160),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _InventoryHeader(onAdd: _openAddInventory),
                  const SizedBox(height: 14),
                  _InventoryFilters(
                    filter: _filter,
                    searchController: _searchController,
                    medicines: _medicines,
                    forms: forms,
                    onSearchChanged: (value) {
                      setState(() {
                        _filter = _filter.copyWith(searchQuery: value);
                      });
                    },
                    onStatusChanged: (status) {
                      setState(() => _filter = _filter.copyWith(status: status));
                    },
                    onMedicineChanged: (medicineId) {
                      setState(() {
                        _filter = _filter.copyWith(
                          medicineId: medicineId,
                          clearMedicineId: medicineId == null,
                        );
                      });
                    },
                    onFormChanged: (form) {
                      setState(() {
                        _filter = _filter.copyWith(
                          medicineForm: form,
                          clearMedicineForm: form == null,
                        );
                      });
                    },
                    onVisibilityChanged: (visibility) {
                      setState(() {
                        _filter = _filter.copyWith(
                          medicineVisibility: visibility,
                        );
                      });
                    },
                    onSortChanged: (sort) {
                      setState(() {
                        _filter = _filter.copyWith(sortOption: sort);
                      });
                    },
                    onPickExpirationRange: _pickExpirationRange,
                    onClearExpirationRange: () {
                      setState(() {
                        _filter = _filter.copyWith(clearExpiration: true);
                      });
                    },
                    onReset: _resetFilters,
                  ),
                  const SizedBox(height: 14),
                  _SummaryGrid(summary: summary),
                  const SizedBox(height: 14),
                  if (_inventories.isEmpty)
                    _InventoryEmptyState(onAdd: _openAddInventory)
                  else if (items.isEmpty)
                    _InventoryFilteredEmptyState(onReset: _resetFilters)
                  else
                    _InventoryGrid(
                      items: items,
                      onOpenMedicine: _openMedicine,
                      onAddStock: _openAddStock,
                      onAdjust: _openAdjustInventory,
                      onHistory: _openHistory,
                      onEdit: _openEditInventory,
                    ),
                  const SizedBox(height: 14),
                  _RecentInventoryChanges(
                    transactions: _recentTransactions,
                    medicines: _medicineById,
                    onViewAll: () => _openHistory(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AddInventoryPage extends StatefulWidget {
  final List<Medicine> medicines;
  final List<MedicineInventory> existingInventories;
  final MedicineInventory? inventory;

  const AddInventoryPage({
    super.key,
    required this.medicines,
    required this.existingInventories,
    this.inventory,
  });

  @override
  State<AddInventoryPage> createState() => _AddInventoryPageState();
}

class _AddInventoryPageState extends State<AddInventoryPage> {
  final InventoryService _service = InventoryService();
  final _packageController = TextEditingController();
  final _currentController = TextEditingController();
  final _doseController = TextEditingController(text: '1');
  final _thresholdController = TextEditingController();
  final _customUnitController = TextEditingController();
  final _notesController = TextEditingController();

  Medicine? _medicine;
  String _unitKey = InventoryQuantityUnit.tablets.name;
  DateTime? _expirationDate;
  bool _trackingEnabled = true;
  bool _isSaving = false;
  String? _medicineError;
  String? _packageError;
  String? _currentError;
  String? _doseError;
  String? _thresholdError;
  String? _customUnitError;
  String? _notesError;

  bool get _isEditing => widget.inventory != null;

  String get _unitLabel => inventoryQuantityUnitLabel(
        _unitKey,
        customQuantityUnit: _customUnitController.text.trim(),
      );

  @override
  void initState() {
    super.initState();
    final inventory = widget.inventory;
    if (inventory != null) {
      _medicine = widget.medicines.firstWhere(
        (medicine) => medicine.id.toString() == inventory.medicineId,
        orElse: () => Medicine(
          id: int.tryParse(inventory.medicineId) ?? 0,
          name: 'Deleted medicine',
          category: '',
          form: '',
          ageGroup: '',
          archived: true,
        ),
      );
      _unitKey = inventory.quantityUnitKey;
      _packageController.text = _formatOptional(inventory.packageQuantity);
      _currentController.text = formatInventoryQuantity(
        inventory.currentQuantity,
      );
      _doseController.text = _formatOptional(inventory.defaultDoseQuantity);
      _thresholdController.text =
          _formatOptional(inventory.lowStockThreshold);
      _customUnitController.text = inventory.customQuantityUnit ?? '';
      _notesController.text = inventory.notes ?? '';
      _expirationDate = inventory.expirationDate;
      _trackingEnabled = inventory.trackingEnabled;
    }
  }

  List<Medicine> get _availableMedicines {
    if (_isEditing) return widget.medicines;
    final tracked = widget.existingInventories
        .where((inventory) => inventory.trackingEnabled)
        .map((inventory) => inventory.medicineId)
        .toSet();
    return widget.medicines
        .where((medicine) => !medicine.isArchived)
        .where((medicine) => !tracked.contains(medicine.id.toString()))
        .toList();
  }

  Future<void> _pickExpirationDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _expirationDate ?? now,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 10),
    );
    if (picked == null) return;
    setState(() {
      _expirationDate = DateTime(picked.year, picked.month, picked.day);
    });
  }

  Future<void> _save() async {
    if (_isSaving) return;

    final packageQuantity = _parseOptionalDouble(_packageController.text);
    final currentQuantity = _parseRequiredDouble(_currentController.text);
    final doseQuantity = _parseRequiredDouble(_doseController.text);
    final threshold = _parseOptionalDouble(_thresholdController.text);
    final customUnit = _customUnitController.text.trim();
    final notes = _notesController.text.trim();

    setState(() {
      _medicineError = _medicine == null ? 'Choose a medicine' : null;
      _packageError =
          _packageController.text.trim().isNotEmpty &&
                  (packageQuantity == null || packageQuantity <= 0)
              ? 'Package quantity must be greater than zero'
              : null;
      _currentError = currentQuantity == null || currentQuantity < 0
          ? 'Current quantity must be zero or greater'
          : null;
      _doseError = doseQuantity == null || doseQuantity <= 0
          ? 'Dose quantity must be greater than zero'
          : null;
      _thresholdError =
          _thresholdController.text.trim().isNotEmpty &&
                  (threshold == null || threshold < 0)
              ? 'Warning level must be zero or greater'
              : null;
      _customUnitError = _unitKey == InventoryQuantityUnit.other.name &&
              customUnit.isEmpty
          ? 'Custom unit is required'
          : customUnit.length > 30
              ? 'Use 30 characters or fewer'
              : null;
      _notesError = notes.length > 1000
          ? 'Notes must be 1000 characters or fewer'
          : null;
    });

    if (_medicineError != null ||
        _packageError != null ||
        _currentError != null ||
        _doseError != null ||
        _thresholdError != null ||
        _customUnitError != null ||
        _notesError != null ||
        _medicine == null ||
        currentQuantity == null ||
        doseQuantity == null) {
      return;
    }

    final inventory = MedicineInventory(
      id: widget.inventory?.id ?? _medicine!.id.toString(),
      userId: widget.inventory?.userId ?? '',
      medicineId: _medicine!.id.toString(),
      quantityUnitKey: _unitKey,
      customQuantityUnit: _unitKey == InventoryQuantityUnit.other.name
          ? customUnit
          : null,
      packageQuantity: packageQuantity,
      currentQuantity: currentQuantity,
      defaultDoseQuantity: doseQuantity,
      lowStockThreshold: threshold,
      expirationDate: _expirationDate,
      trackingEnabled: _trackingEnabled,
      notes: notes.isEmpty ? null : notes,
      createdAt: widget.inventory?.createdAt,
    );

    setState(() => _isSaving = true);
    try {
      if (_isEditing) {
        await _service.updateInventory(inventory);
      } else {
        await _service.createInventory(inventory);
      }
      if (!mounted) return;
      showAuthMessage(
        context,
        _isEditing ? 'Inventory updated' : 'Medicine inventory is now tracked',
      );
      Navigator.pop(context);
    } on InventoryServiceException catch (error) {
      _showSaveError(error.message);
    } catch (_) {
      _showSaveError('Could not save inventory. Please try again.');
    }
  }

  void _showSaveError(String message) {
    if (!mounted) return;
    showAuthMessage(context, message, backgroundColor: Colors.redAccent);
    setState(() => _isSaving = false);
  }

  Future<void> _deleteInventory() async {
    final choice = await showDialog<_DeleteInventoryChoice>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete inventory record?'),
        content: const Text(
          'This removes the inventory settings for this medicine. Choose whether to keep or permanently delete its transaction history.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(
              context,
              _DeleteInventoryChoice.keepHistory,
            ),
            child: const Text('Delete, keep history'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(
              context,
              _DeleteInventoryChoice.deleteHistory,
            ),
            child: const Text('Delete all'),
          ),
        ],
      ),
    );
    if (choice == null || widget.inventory == null) return;

    setState(() => _isSaving = true);
    try {
      await _service.deleteInventory(
        inventoryId: widget.inventory!.id,
        deleteHistory: choice == _DeleteInventoryChoice.deleteHistory,
      );
      if (!mounted) return;
      showAuthMessage(context, 'Inventory record deleted');
      Navigator.pop(context);
    } catch (_) {
      _showSaveError('Could not delete inventory. Please try again.');
    }
  }

  @override
  void dispose() {
    _packageController.dispose();
    _currentController.dispose();
    _doseController.dispose();
    _thresholdController.dispose();
    _customUnitController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final availableMedicines = _availableMedicines;
    final threshold = _parseOptionalDouble(_thresholdController.text);
    final current = _parseRequiredDouble(_currentController.text);
    final showThresholdWarning = threshold != null &&
        current != null &&
        threshold > current &&
        _thresholdError == null;

    return Scaffold(
      backgroundColor: appScaffoldColor(context),
      appBar: AppBar(
        backgroundColor: authPrimary,
        foregroundColor: Colors.white,
        title: Text(
          _isEditing ? 'Edit Inventory' : 'Track Medicine',
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
              children: [
                Text(
                  _isEditing ? 'Edit inventory' : 'Track a medicine',
                  style: TextStyle(
                    color: appTextColor(context),
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Set quantity, dose deduction, refill warning, and expiration.',
                  style: TextStyle(
                    color: appMutedTextColor(context),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 18),
                if (!_isEditing && availableMedicines.isEmpty)
                  _FormNotice(
                    icon: Icons.inventory_2_outlined,
                    message:
                        'All active medicines are already tracked. Edit an existing inventory record to change it.',
                  )
                else
                  DropdownButtonFormField<Medicine>(
                    value: _medicine != null &&
                            availableMedicines.any(
                              (medicine) => medicine.id == _medicine!.id,
                            )
                        ? _medicine
                        : null,
                    isExpanded: true,
                    decoration: authInputDecoration(
                      context: context,
                      hintText: 'Medicine',
                      icon: Icons.medication_outlined,
                      errorText: _medicineError,
                    ),
                    items: availableMedicines
                        .map(
                          (medicine) => DropdownMenuItem(
                            value: medicine,
                            child: Text(
                              '${medicine.name} - ${medicine.form}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: _isEditing
                        ? null
                        : (medicine) {
                            setState(() {
                              _medicine = medicine;
                              _medicineError = null;
                              _unitKey = _unitFromMedicine(medicine);
                            });
                          },
                  ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  value: _unitKey,
                  isExpanded: true,
                  decoration: authInputDecoration(
                    context: context,
                    hintText: 'Quantity type',
                    icon: Icons.straighten_outlined,
                  ),
                  items: InventoryQuantityUnit.values
                      .map(
                        (unit) => DropdownMenuItem(
                          value: unit.name,
                          child: Text(_unitMenuLabel(unit)),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      _unitKey = value;
                      _customUnitError = null;
                    });
                  },
                ),
                if (_unitKey == InventoryQuantityUnit.other.name) ...[
                  const SizedBox(height: 14),
                  TextField(
                    controller: _customUnitController,
                    maxLength: 30,
                    decoration: authInputDecoration(
                      context: context,
                      hintText: 'Custom unit name',
                      icon: Icons.edit_outlined,
                      errorText: _customUnitError,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ],
                const SizedBox(height: 14),
                _NumberField(
                  controller: _packageController,
                  label: 'Package quantity optional',
                  unitLabel: _unitLabel,
                  icon: Icons.inventory_2_outlined,
                  errorText: _packageError,
                ),
                const SizedBox(height: 14),
                _NumberField(
                  controller: _currentController,
                  label: 'Current quantity',
                  unitLabel: _unitLabel,
                  icon: Icons.format_list_numbered,
                  errorText: _currentError,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 14),
                _NumberField(
                  controller: _doseController,
                  label: 'Amount used per dose',
                  unitLabel: _unitLabel,
                  icon: Icons.medication_liquid_outlined,
                  errorText: _doseError,
                ),
                const SizedBox(height: 14),
                _NumberField(
                  controller: _thresholdController,
                  label: 'Low-stock warning level optional',
                  unitLabel: _unitLabel,
                  icon: Icons.warning_amber_outlined,
                  errorText: _thresholdError,
                  onChanged: (_) => setState(() {}),
                ),
                if (showThresholdWarning) ...[
                  const SizedBox(height: 8),
                  _FormNotice(
                    icon: Icons.info_outline,
                    message:
                        'This warning level is above the current quantity, so this medicine will appear as low stock.',
                  ),
                ],
                const SizedBox(height: 14),
                _DatePickerTile(
                  label: 'Expiration date',
                  value: _expirationDate == null
                      ? 'No expiration date'
                      : _formatDate(_expirationDate!),
                  onTap: _pickExpirationDate,
                  onClear: _expirationDate == null
                      ? null
                      : () => setState(() => _expirationDate = null),
                ),
                const SizedBox(height: 14),
                SwitchListTile(
                  value: _trackingEnabled,
                  activeColor: authPrimary,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                  title: Text(
                    'Tracking enabled',
                    style: TextStyle(
                      color: appTextColor(context),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  subtitle: Text(
                    _trackingEnabled
                        ? 'Taken doses will reduce this inventory.'
                        : 'Quantity and history remain saved, but automatic deduction stops.',
                    style: TextStyle(
                      color: appMutedTextColor(context),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onChanged: (value) async {
                    if (!value) {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Disable inventory tracking?'),
                          content: const Text(
                            'The current quantity and transaction history will remain saved, but doses will no longer be deducted automatically.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancel'),
                            ),
                            FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: authPrimary,
                              ),
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Disable'),
                            ),
                          ],
                        ),
                      );
                      if (confirmed != true) return;
                    }
                    setState(() => _trackingEnabled = value);
                  },
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _notesController,
                  maxLines: 4,
                  maxLength: 1000,
                  decoration: authInputDecoration(
                    context: context,
                    hintText: 'Optional notes',
                    icon: Icons.notes_outlined,
                    errorText: _notesError,
                  ),
                ),
                const SizedBox(height: 16),
                AuthPrimaryButton(
                  label: _isSaving
                      ? 'Saving...'
                      : _isEditing
                          ? 'Save Inventory'
                          : 'Track Medicine',
                  icon: _isEditing ? Icons.save_outlined : Icons.add,
                  onPressed:
                      _isSaving || (!_isEditing && availableMedicines.isEmpty)
                          ? () {}
                          : _save,
                ),
                if (_isEditing) ...[
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: _isSaving ? null : _deleteInventory,
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Delete inventory record'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      side: const BorderSide(color: Colors.redAccent),
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AddStockPage extends StatefulWidget {
  final MedicineInventory inventory;
  final String medicineName;

  const AddStockPage({
    super.key,
    required this.inventory,
    required this.medicineName,
  });

  @override
  State<AddStockPage> createState() => _AddStockPageState();
}

class _AddStockPageState extends State<AddStockPage> {
  final InventoryService _service = InventoryService();
  final _quantityController = TextEditingController();
  final _lotController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime _refillDate = DateTime.now();
  DateTime? _expirationDate;
  bool _isSaving = false;
  String? _quantityError;
  String? _notesError;

  String get _unitLabel => inventoryQuantityUnitLabel(
        widget.inventory.quantityUnitKey,
        customQuantityUnit: widget.inventory.customQuantityUnit,
      );

  double? get _quantity => _parseRequiredDouble(_quantityController.text);

  double get _newTotal => widget.inventory.currentQuantity + (_quantity ?? 0);

  Future<void> _pickRefillDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _refillDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked == null) return;
    setState(() => _refillDate = picked);
  }

  Future<void> _pickExpirationDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _expirationDate ?? widget.inventory.expirationDate ?? now,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 10),
    );
    if (picked == null) return;
    setState(() => _expirationDate = picked);
  }

  Future<void> _save() async {
    final quantity = _quantity;
    final notes = _notesController.text.trim();
    setState(() {
      _quantityError = quantity == null || quantity <= 0
          ? 'Quantity added must be greater than zero'
          : null;
      _notesError = notes.length > 500
          ? 'Notes must be 500 characters or fewer'
          : null;
    });
    if (_quantityError != null || _notesError != null || quantity == null) {
      return;
    }

    setState(() => _isSaving = true);
    try {
      await _service.addStock(
        inventoryId: widget.inventory.id,
        quantityAdded: quantity,
        refillDate: _refillDate,
        expirationDate: _expirationDate,
        lotNumber: _lotController.text.trim(),
        notes: notes,
      );
      if (!mounted) return;
      showAuthMessage(
        context,
        'Added ${formatInventoryQuantity(quantity)} $_unitLabel. New total: ${formatInventoryQuantity(_newTotal)} $_unitLabel.',
      );
      Navigator.pop(context);
    } catch (_) {
      if (!mounted) return;
      showAuthMessage(
        context,
        'Could not add stock. Please try again.',
        backgroundColor: Colors.redAccent,
      );
      setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _lotController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _InventoryFormScaffold(
      title: 'Add Stock',
      heading: 'Add stock',
      subtitle: widget.medicineName,
      children: [
        _ReadOnlyQuantityTile(
          label: 'Current quantity',
          value:
              '${formatInventoryQuantity(widget.inventory.currentQuantity)} $_unitLabel',
        ),
        const SizedBox(height: 14),
        _NumberField(
          controller: _quantityController,
          label: 'Quantity added',
          unitLabel: _unitLabel,
          icon: Icons.add_box_outlined,
          errorText: _quantityError,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 14),
        _ReadOnlyQuantityTile(
          label: 'New total',
          value: '${formatInventoryQuantity(_newTotal)} $_unitLabel',
        ),
        const SizedBox(height: 14),
        _DatePickerTile(
          label: 'Purchase or refill date',
          value: _formatDate(_refillDate),
          onTap: _pickRefillDate,
        ),
        const SizedBox(height: 14),
        _DatePickerTile(
          label: 'Expiration date',
          value: _expirationDate == null
              ? 'Keep current expiration'
              : _formatDate(_expirationDate!),
          onTap: _pickExpirationDate,
          onClear: _expirationDate == null
              ? null
              : () => setState(() => _expirationDate = null),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _lotController,
          decoration: authInputDecoration(
            context: context,
            hintText: 'Batch or lot number optional',
            icon: Icons.qr_code_2_outlined,
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _notesController,
          maxLines: 3,
          maxLength: 500,
          decoration: authInputDecoration(
            context: context,
            hintText: 'Notes optional',
            icon: Icons.notes_outlined,
            errorText: _notesError,
          ),
        ),
        const SizedBox(height: 16),
        AuthPrimaryButton(
          label: _isSaving ? 'Saving...' : 'Add Stock',
          icon: Icons.add,
          onPressed: _isSaving ? () {} : _save,
        ),
      ],
    );
  }
}

class AdjustInventoryPage extends StatefulWidget {
  final MedicineInventory inventory;
  final String medicineName;

  const AdjustInventoryPage({
    super.key,
    required this.inventory,
    required this.medicineName,
  });

  @override
  State<AdjustInventoryPage> createState() => _AdjustInventoryPageState();
}

class _AdjustInventoryPageState extends State<AdjustInventoryPage> {
  final InventoryService _service = InventoryService();
  final _newQuantityController = TextEditingController();
  final _notesController = TextEditingController();
  String _reason = 'Manual count';
  bool _isSaving = false;
  String? _quantityError;
  String? _notesError;

  final List<String> _reasons = const [
    'Manual count',
    'Medicine discarded',
    'Medicine lost',
    'Incorrect previous value',
    'Dose not recorded',
    'Other',
  ];

  String get _unitLabel => inventoryQuantityUnitLabel(
        widget.inventory.quantityUnitKey,
        customQuantityUnit: widget.inventory.customQuantityUnit,
      );

  double? get _newQuantity => _parseRequiredDouble(_newQuantityController.text);

  double get _difference =>
      (_newQuantity ?? widget.inventory.currentQuantity) -
      widget.inventory.currentQuantity;

  Future<void> _save() async {
    final newQuantity = _newQuantity;
    final notes = _notesController.text.trim();
    setState(() {
      _quantityError = newQuantity == null || newQuantity < 0
          ? 'New quantity cannot be negative'
          : null;
      _notesError = notes.length > 500
          ? 'Notes must be 500 characters or fewer'
          : null;
    });
    if (_quantityError != null || _notesError != null || newQuantity == null) {
      return;
    }

    final reduction = widget.inventory.currentQuantity - newQuantity;
    if (reduction > 0 &&
        (reduction >= 25 || newQuantity <= widget.inventory.currentQuantity / 2)) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Confirm quantity adjustment'),
          content: Text(
            'The quantity will change from ${formatInventoryQuantity(widget.inventory.currentQuantity)} $_unitLabel to ${formatInventoryQuantity(newQuantity)} $_unitLabel.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: authPrimary),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Confirm'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }

    setState(() => _isSaving = true);
    try {
      await _service.adjustQuantity(
        inventoryId: widget.inventory.id,
        newQuantity: newQuantity,
        reason: _reason,
        notes: notes,
      );
      if (!mounted) return;
      showAuthMessage(context, 'Inventory quantity adjusted');
      Navigator.pop(context);
    } catch (_) {
      if (!mounted) return;
      showAuthMessage(
        context,
        'Could not adjust quantity. Please try again.',
        backgroundColor: Colors.redAccent,
      );
      setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _newQuantityController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final diff = _difference;
    return _InventoryFormScaffold(
      title: 'Adjust Quantity',
      heading: 'Adjust quantity',
      subtitle: widget.medicineName,
      children: [
        _ReadOnlyQuantityTile(
          label: 'Current recorded quantity',
          value:
              '${formatInventoryQuantity(widget.inventory.currentQuantity)} $_unitLabel',
        ),
        const SizedBox(height: 14),
        _NumberField(
          controller: _newQuantityController,
          label: 'New quantity',
          unitLabel: _unitLabel,
          icon: Icons.edit_note_outlined,
          errorText: _quantityError,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 14),
        _ReadOnlyQuantityTile(
          label: 'Difference',
          value:
              '${diff >= 0 ? '+' : ''}${formatInventoryQuantity(diff)} $_unitLabel',
        ),
        const SizedBox(height: 14),
        DropdownButtonFormField<String>(
          value: _reason,
          decoration: authInputDecoration(
            context: context,
            hintText: 'Reason',
            icon: Icons.fact_check_outlined,
          ),
          items: _reasons
              .map((reason) => DropdownMenuItem(value: reason, child: Text(reason)))
              .toList(),
          onChanged: (value) => setState(() => _reason = value ?? _reason),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _notesController,
          maxLines: 3,
          maxLength: 500,
          decoration: authInputDecoration(
            context: context,
            hintText: 'Notes optional',
            icon: Icons.notes_outlined,
            errorText: _notesError,
          ),
        ),
        const SizedBox(height: 16),
        AuthPrimaryButton(
          label: _isSaving ? 'Saving...' : 'Save Adjustment',
          icon: Icons.save_outlined,
          onPressed: _isSaving ? () {} : _save,
        ),
      ],
    );
  }
}

class InventoryHistoryPage extends StatefulWidget {
  final MedicineInventory? inventory;
  final String? medicineName;
  final List<Medicine> medicines;

  const InventoryHistoryPage({
    super.key,
    required this.medicines,
    this.inventory,
    this.medicineName,
  });

  @override
  State<InventoryHistoryPage> createState() => _InventoryHistoryPageState();
}

class _InventoryHistoryPageState extends State<InventoryHistoryPage> {
  final InventoryService _service = InventoryService();
  String _typeKey = 'all';
  String _sourceKey = 'all';
  DateTime? _startDate;
  DateTime? _endDate;

  Map<String, Medicine> get _medicineById {
    return {
      for (final medicine in widget.medicines) medicine.id.toString(): medicine,
    };
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      initialDateRange: _startDate == null || _endDate == null
          ? null
          : DateTimeRange(start: _startDate!, end: _endDate!),
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
    );
    if (range == null) return;
    setState(() {
      _startDate = DateTime(range.start.year, range.start.month, range.start.day);
      _endDate = DateTime(range.end.year, range.end.month, range.end.day, 23, 59);
    });
  }

  List<InventoryTransactionRecord> _applyFilters(
    List<InventoryTransactionRecord> records,
  ) {
    return records.where((record) {
      if (_typeKey != 'all' && record.type.name != _typeKey) return false;
      if (_sourceKey == 'automatic' && !record.isAutomatic) return false;
      if (_sourceKey == 'manual' && record.isAutomatic) return false;
      final createdAt = record.createdAt;
      if (_startDate != null &&
          (createdAt == null || createdAt.isBefore(_startDate!))) {
        return false;
      }
      if (_endDate != null &&
          (createdAt == null || createdAt.isAfter(_endDate!))) {
        return false;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appScaffoldColor(context),
      appBar: AppBar(
        backgroundColor: authPrimary,
        foregroundColor: Colors.white,
        title: Text(
          widget.inventory == null ? 'Inventory History' : 'Inventory History',
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: SafeArea(
        child: StreamBuilder<List<InventoryTransactionRecord>>(
          stream: _service.watchTransactions(
            inventoryId: widget.inventory?.id,
            limit: 200,
          ),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const _InventoryLoadingState();
            }
            if (snapshot.hasError) {
              return _InventoryErrorState(
                message: 'Could not load transaction history.',
                onRetry: () => setState(() {}),
              );
            }

            final transactions = _applyFilters(snapshot.data ?? const []);
            return ListView(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 900),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.medicineName ?? 'Inventory history',
                          style: TextStyle(
                            color: appTextColor(context),
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Newest inventory changes appear first.',
                          style: TextStyle(
                            color: appMutedTextColor(context),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 14),
                        _HistoryFilters(
                          typeKey: _typeKey,
                          sourceKey: _sourceKey,
                          startDate: _startDate,
                          endDate: _endDate,
                          onTypeChanged: (value) {
                            setState(() => _typeKey = value);
                          },
                          onSourceChanged: (value) {
                            setState(() => _sourceKey = value);
                          },
                          onPickDateRange: _pickDateRange,
                          onClearDateRange: () {
                            setState(() {
                              _startDate = null;
                              _endDate = null;
                            });
                          },
                        ),
                        const SizedBox(height: 14),
                        if (transactions.isEmpty)
                          _InventoryPanel(
                            child: _CenteredMessage(
                              icon: Icons.history_outlined,
                              title: 'No inventory changes found',
                              message:
                                  'Try a different transaction type, source, or date range.',
                            ),
                          )
                        else
                          ...transactions.map(
                            (record) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _TransactionCard(
                                record: record,
                                medicineName: _medicineById[record.medicineId]
                                        ?.name ??
                                    widget.medicineName ??
                                    'Unknown medicine',
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _InventoryHeader extends StatelessWidget {
  final VoidCallback onAdd;

  const _InventoryHeader({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 620;
        final title = Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: appTintSurfaceColor(context),
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Icon(Icons.inventory_2_outlined, color: authPrimary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Medicine Inventory',
                    style: TextStyle(
                      color: appTextColor(context),
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Track medicine quantities, refill needs, and expiration dates.',
                    style: TextStyle(
                      color: appMutedTextColor(context),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );

        final button = FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: authPrimary,
            foregroundColor: Colors.white,
            minimumSize: compact ? const Size.fromHeight(50) : const Size(176, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          onPressed: onAdd,
          icon: const Icon(Icons.add),
          label: const Text(
            'Track Medicine',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
        );

        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [title, const SizedBox(height: 14), button],
          );
        }

        return Row(children: [Expanded(child: title), const SizedBox(width: 16), button]);
      },
    );
  }
}

class _InventoryFilters extends StatelessWidget {
  final InventoryFilter filter;
  final TextEditingController searchController;
  final List<Medicine> medicines;
  final List<String> forms;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<InventoryStatusFilter> onStatusChanged;
  final ValueChanged<String?> onMedicineChanged;
  final ValueChanged<String?> onFormChanged;
  final ValueChanged<InventoryMedicineVisibility> onVisibilityChanged;
  final ValueChanged<InventorySortOption> onSortChanged;
  final VoidCallback onPickExpirationRange;
  final VoidCallback onClearExpirationRange;
  final VoidCallback onReset;

  const _InventoryFilters({
    required this.filter,
    required this.searchController,
    required this.medicines,
    required this.forms,
    required this.onSearchChanged,
    required this.onStatusChanged,
    required this.onMedicineChanged,
    required this.onFormChanged,
    required this.onVisibilityChanged,
    required this.onSortChanged,
    required this.onPickExpirationRange,
    required this.onClearExpirationRange,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    return _InventoryPanel(
      padding: const EdgeInsets.all(14),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final itemWidth = constraints.maxWidth >= 900
              ? (constraints.maxWidth - 24) / 3
              : constraints.maxWidth >= 620
                  ? (constraints.maxWidth - 12) / 2
                  : constraints.maxWidth;
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(
                width: itemWidth,
                child: AuthTextField(
                  controller: searchController,
                  hintText: 'Search medicine',
                  icon: Icons.search,
                  onChanged: onSearchChanged,
                ),
              ),
              SizedBox(
                width: itemWidth,
                child: DropdownButtonFormField<InventoryStatusFilter>(
                  value: filter.status,
                  isExpanded: true,
                  decoration: authInputDecoration(
                    context: context,
                    hintText: 'Status',
                    icon: Icons.fact_check_outlined,
                  ),
                  items: InventoryStatusFilter.values
                      .map(
                        (status) => DropdownMenuItem(
                          value: status,
                          child: Text(inventoryStatusFilterLabel(status)),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) onStatusChanged(value);
                  },
                ),
              ),
              SizedBox(
                width: itemWidth,
                child: DropdownButtonFormField<String>(
                  value: filter.medicineId ?? '__all__',
                  isExpanded: true,
                  decoration: authInputDecoration(
                    context: context,
                    hintText: 'Medicine',
                    icon: Icons.medication_outlined,
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: '__all__',
                      child: Text('All medicines'),
                    ),
                    ...medicines.map(
                      (medicine) => DropdownMenuItem(
                        value: medicine.id.toString(),
                        child: Text(medicine.name, overflow: TextOverflow.ellipsis),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    onMedicineChanged(value == '__all__' ? null : value);
                  },
                ),
              ),
              SizedBox(
                width: itemWidth,
                child: DropdownButtonFormField<String>(
                  value: filter.medicineForm ?? '__all__',
                  isExpanded: true,
                  decoration: authInputDecoration(
                    context: context,
                    hintText: 'Form',
                    icon: Icons.category_outlined,
                  ),
                  items: [
                    const DropdownMenuItem(value: '__all__', child: Text('All forms')),
                    ...forms.map(
                      (form) => DropdownMenuItem(
                        value: form,
                        child: Text(form, overflow: TextOverflow.ellipsis),
                      ),
                    ),
                  ],
                  onChanged: (value) => onFormChanged(value == '__all__' ? null : value),
                ),
              ),
              SizedBox(
                width: itemWidth,
                child: DropdownButtonFormField<InventoryMedicineVisibility>(
                  value: filter.medicineVisibility,
                  isExpanded: true,
                  decoration: authInputDecoration(
                    context: context,
                    hintText: 'Active or archived',
                    icon: Icons.archive_outlined,
                  ),
                  items: InventoryMedicineVisibility.values
                      .map(
                        (visibility) => DropdownMenuItem(
                          value: visibility,
                          child: Text(inventoryMedicineVisibilityLabel(visibility)),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) onVisibilityChanged(value);
                  },
                ),
              ),
              SizedBox(
                width: itemWidth,
                child: DropdownButtonFormField<InventorySortOption>(
                  value: filter.sortOption,
                  isExpanded: true,
                  decoration: authInputDecoration(
                    context: context,
                    hintText: 'Sort',
                    icon: Icons.sort_outlined,
                  ),
                  items: InventorySortOption.values
                      .map(
                        (sort) => DropdownMenuItem(
                          value: sort,
                          child: Text(inventorySortLabel(sort)),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) onSortChanged(value);
                  },
                ),
              ),
              SizedBox(
                width: itemWidth,
                height: 56,
                child: OutlinedButton.icon(
                  onPressed: onPickExpirationRange,
                  icon: const Icon(Icons.date_range_outlined),
                  label: Text(
                    filter.expirationStart == null || filter.expirationEnd == null
                        ? 'Expiration range'
                        : '${_formatDate(filter.expirationStart!)} - ${_formatDate(filter.expirationEnd!)}',
                    overflow: TextOverflow.ellipsis,
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: authPrimary,
                    side: BorderSide(color: appBorderColor(context)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
              if (filter.expirationStart != null || filter.expirationEnd != null)
                SizedBox(
                  width: itemWidth,
                  height: 56,
                  child: OutlinedButton.icon(
                    onPressed: onClearExpirationRange,
                    icon: const Icon(Icons.event_busy_outlined),
                    label: const Text('Clear expiration'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: authPrimary,
                      side: BorderSide(color: appBorderColor(context)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              SizedBox(
                width: itemWidth,
                height: 56,
                child: OutlinedButton.icon(
                  onPressed: filter.hasActiveFilters ? onReset : null,
                  icon: const Icon(Icons.restart_alt_outlined),
                  label: const Text('Reset Filters'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: authPrimary,
                    side: BorderSide(color: appBorderColor(context)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SummaryGrid extends StatelessWidget {
  final _InventorySummary summary;

  const _SummaryGrid({required this.summary});

  @override
  Widget build(BuildContext context) {
    final cards = [
      _SummaryData('Tracked Medicines', summary.tracked, Icons.inventory_2_outlined, authPrimary),
      _SummaryData('Low Stock', summary.lowStock, Icons.warning_amber_outlined, const Color(0xFFF59E0B)),
      _SummaryData('Out of Stock', summary.outOfStock, Icons.remove_shopping_cart_outlined, Colors.redAccent),
      _SummaryData('Expiring Soon', summary.expiringSoon, Icons.event_busy_outlined, const Color(0xFF7C3AED)),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth >= 900
            ? (constraints.maxWidth - 36) / 4
            : constraints.maxWidth >= 560
                ? (constraints.maxWidth - 12) / 2
                : constraints.maxWidth;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: cards
              .map(
                (card) => SizedBox(
                  width: width,
                  child: _SummaryCard(data: card),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _InventoryGrid extends StatelessWidget {
  final List<_InventoryViewItem> items;
  final ValueChanged<_InventoryViewItem> onOpenMedicine;
  final ValueChanged<_InventoryViewItem> onAddStock;
  final ValueChanged<_InventoryViewItem> onAdjust;
  final ValueChanged<_InventoryViewItem> onHistory;
  final ValueChanged<_InventoryViewItem> onEdit;

  const _InventoryGrid({
    required this.items,
    required this.onOpenMedicine,
    required this.onAddStock,
    required this.onAdjust,
    required this.onHistory,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth >= 980
            ? 3
            : constraints.maxWidth >= 660
                ? 2
                : 1;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            mainAxisExtent: 404,
          ),
          itemBuilder: (context, index) {
            final item = items[index];
            return _InventoryCard(
              item: item,
              onOpenMedicine: () => onOpenMedicine(item),
              onAddStock: () => onAddStock(item),
              onAdjust: () => onAdjust(item),
              onHistory: () => onHistory(item),
              onEdit: () => onEdit(item),
            );
          },
        );
      },
    );
  }
}

class _InventoryCard extends StatelessWidget {
  final _InventoryViewItem item;
  final VoidCallback onOpenMedicine;
  final VoidCallback onAddStock;
  final VoidCallback onAdjust;
  final VoidCallback onHistory;
  final VoidCallback onEdit;

  const _InventoryCard({
    required this.item,
    required this.onOpenMedicine,
    required this.onAddStock,
    required this.onAdjust,
    required this.onHistory,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final inventory = item.inventory;
    final unit = inventoryQuantityUnitLabel(
      inventory.quantityUnitKey,
      customQuantityUnit: inventory.customQuantityUnit,
    );
    final statusColor = _statusColor(item.status);
    final expirationLabel = _expirationLabel(inventory.expirationDate);

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onOpenMedicine,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: appSurfaceColor(context),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: appBorderColor(context)),
          boxShadow: [
            BoxShadow(
              color: appShadowColor(context, 0.05),
              blurRadius: 14,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: appTintSurfaceColor(context),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.inventory_2_outlined, color: authPrimary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.medicineName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: appTextColor(context),
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.medicineForm,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: appMutedTextColor(context),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Edit Inventory',
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined, color: authPrimary),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _StatusPill(
              status: item.status,
              color: statusColor,
            ),
            const SizedBox(height: 14),
            _InventoryMetricLine(
              label: 'Remaining',
              value:
                  '${formatInventoryQuantity(inventory.currentQuantity)} $unit',
            ),
            _InventoryMetricLine(
              label: 'Dose',
              value: inventory.defaultDoseQuantity == null
                  ? 'No estimate'
                  : '${formatInventoryQuantity(inventory.defaultDoseQuantity!)} $unit',
            ),
            _InventoryMetricLine(
              label: 'Estimated supply',
              value: item.dosesRemaining == null
                  ? 'No estimate'
                  : '${item.dosesRemaining} doses',
            ),
            _InventoryMetricLine(
              label: 'Estimated duration',
              value: item.daysRemaining == null
                  ? 'No estimate'
                  : '${item.daysRemaining} days',
            ),
            _InventoryMetricLine(
              label: 'Refill warning',
              value: inventory.lowStockThreshold == null
                  ? 'Disabled'
                  : '${formatInventoryQuantity(inventory.lowStockThreshold!)} $unit',
            ),
            _InventoryMetricLine(label: 'Expires', value: expirationLabel),
            _InventoryMetricLine(
              label: 'Last updated',
              value: inventory.updatedAt == null
                  ? 'Not recorded'
                  : _formatDate(inventory.updatedAt!),
            ),
            const Spacer(),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _CardActionButton(
                  icon: Icons.add,
                  label: 'Add Stock',
                  onPressed: onAddStock,
                ),
                _CardActionButton(
                  icon: Icons.edit_note_outlined,
                  label: 'Adjust',
                  onPressed: onAdjust,
                ),
                _CardActionButton(
                  icon: Icons.history_outlined,
                  label: 'History',
                  onPressed: onHistory,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentInventoryChanges extends StatelessWidget {
  final List<InventoryTransactionRecord> transactions;
  final Map<String, Medicine> medicines;
  final VoidCallback onViewAll;

  const _RecentInventoryChanges({
    required this.transactions,
    required this.medicines,
    required this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    return _InventoryPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Recent inventory changes',
                  style: TextStyle(
                    color: appTextColor(context),
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: onViewAll,
                icon: const Icon(Icons.history_outlined),
                label: const Text('View History'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (transactions.isEmpty)
            Text(
              'No inventory changes have been recorded yet.',
              style: TextStyle(
                color: appMutedTextColor(context),
                fontWeight: FontWeight.w700,
              ),
            )
          else
            ...transactions.take(4).map(
                  (record) => Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: _CompactTransactionRow(
                      record: record,
                      medicineName:
                          medicines[record.medicineId]?.name ?? 'Unknown medicine',
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}

class _HistoryFilters extends StatelessWidget {
  final String typeKey;
  final String sourceKey;
  final DateTime? startDate;
  final DateTime? endDate;
  final ValueChanged<String> onTypeChanged;
  final ValueChanged<String> onSourceChanged;
  final VoidCallback onPickDateRange;
  final VoidCallback onClearDateRange;

  const _HistoryFilters({
    required this.typeKey,
    required this.sourceKey,
    required this.startDate,
    required this.endDate,
    required this.onTypeChanged,
    required this.onSourceChanged,
    required this.onPickDateRange,
    required this.onClearDateRange,
  });

  @override
  Widget build(BuildContext context) {
    return _InventoryPanel(
      padding: const EdgeInsets.all(14),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth >= 720
              ? (constraints.maxWidth - 24) / 3
              : constraints.maxWidth;
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(
                width: width,
                child: DropdownButtonFormField<String>(
                  value: typeKey,
                  decoration: authInputDecoration(
                    context: context,
                    hintText: 'Transaction type',
                    icon: Icons.swap_vert_outlined,
                  ),
                  items: [
                    const DropdownMenuItem(value: 'all', child: Text('All types')),
                    ...InventoryTransactionType.values.map(
                      (type) => DropdownMenuItem(
                        value: type.name,
                        child: Text(inventoryTransactionTypeLabel(type)),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) onTypeChanged(value);
                  },
                ),
              ),
              SizedBox(
                width: width,
                child: DropdownButtonFormField<String>(
                  value: sourceKey,
                  decoration: authInputDecoration(
                    context: context,
                    hintText: 'Source',
                    icon: Icons.smart_toy_outlined,
                  ),
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('Automatic and manual')),
                    DropdownMenuItem(value: 'automatic', child: Text('Automatic only')),
                    DropdownMenuItem(value: 'manual', child: Text('Manual only')),
                  ],
                  onChanged: (value) {
                    if (value != null) onSourceChanged(value);
                  },
                ),
              ),
              SizedBox(
                width: width,
                height: 56,
                child: OutlinedButton.icon(
                  onPressed: onPickDateRange,
                  icon: const Icon(Icons.date_range_outlined),
                  label: Text(
                    startDate == null || endDate == null
                        ? 'Date range'
                        : '${_formatDate(startDate!)} - ${_formatDate(endDate!)}',
                    overflow: TextOverflow.ellipsis,
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: authPrimary,
                    side: BorderSide(color: appBorderColor(context)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
              if (startDate != null || endDate != null)
                SizedBox(
                  width: width,
                  height: 56,
                  child: OutlinedButton.icon(
                    onPressed: onClearDateRange,
                    icon: const Icon(Icons.restart_alt_outlined),
                    label: const Text('Clear dates'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: authPrimary,
                      side: BorderSide(color: appBorderColor(context)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _TransactionCard extends StatelessWidget {
  final InventoryTransactionRecord record;
  final String medicineName;

  const _TransactionCard({
    required this.record,
    required this.medicineName,
  });

  @override
  Widget build(BuildContext context) {
    final unit = inventoryQuantityUnitLabel(
      record.quantityUnitKey,
      customQuantityUnit: record.customQuantityUnit,
    );
    return _InventoryPanel(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: record.quantityChange < 0
                  ? Colors.redAccent.withOpacity(0.12)
                  : appTintSurfaceColor(context),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              record.quantityChange < 0
                  ? Icons.remove_circle_outline
                  : Icons.add_circle_outline,
              color: record.quantityChange < 0 ? Colors.redAccent : authPrimary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  medicineName,
                  style: TextStyle(
                    color: appTextColor(context),
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  inventoryTransactionTypeLabel(record.type),
                  style: TextStyle(
                    color: appMutedTextColor(context),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${record.quantityChange >= 0 ? '+' : ''}${formatInventoryQuantity(record.quantityChange)} $unit',
                  style: TextStyle(
                    color: record.quantityChange < 0
                        ? Colors.redAccent
                        : authPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${formatInventoryQuantity(record.previousQuantity)} -> ${formatInventoryQuantity(record.newQuantity)} $unit',
                  style: TextStyle(
                    color: appTextColor(context),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDateTime(record.createdAt),
                  style: TextStyle(color: appMutedTextColor(context)),
                ),
                if (record.reason != null || record.notes != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    [record.reason, record.notes]
                        .whereType<String>()
                        .where((text) => text.trim().isNotEmpty)
                        .join('\n'),
                    style: TextStyle(color: appMutedTextColor(context)),
                  ),
                ],
              ],
            ),
          ),
          _SourcePill(isAutomatic: record.isAutomatic),
        ],
      ),
    );
  }
}

class _CompactTransactionRow extends StatelessWidget {
  final InventoryTransactionRecord record;
  final String medicineName;

  const _CompactTransactionRow({
    required this.record,
    required this.medicineName,
  });

  @override
  Widget build(BuildContext context) {
    final unit = inventoryQuantityUnitLabel(
      record.quantityUnitKey,
      customQuantityUnit: record.customQuantityUnit,
    );
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: appSoftSurfaceColor(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: appBorderColor(context)),
      ),
      child: Row(
        children: [
          Icon(
            record.quantityChange < 0
                ? Icons.remove_circle_outline
                : Icons.add_circle_outline,
            color: record.quantityChange < 0 ? Colors.redAccent : authPrimary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  medicineName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: appTextColor(context),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  inventoryTransactionTypeLabel(record.type),
                  style: TextStyle(
                    color: appMutedTextColor(context),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${record.quantityChange >= 0 ? '+' : ''}${formatInventoryQuantity(record.quantityChange)} $unit',
            style: TextStyle(
              color: record.quantityChange < 0 ? Colors.redAccent : authPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _InventoryPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const _InventoryPanel({
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: appSurfaceColor(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: appBorderColor(context)),
        boxShadow: [
          BoxShadow(
            color: appShadowColor(context, 0.04),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final _SummaryData data;

  const _SummaryCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return _InventoryPanel(
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: data.color.withOpacity(appIsDark(context) ? 0.18 : 0.11),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(data.icon, color: data.color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.value.toString(),
                  style: TextStyle(
                    color: appTextColor(context),
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  data.label,
                  style: TextStyle(
                    color: appMutedTextColor(context),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final InventoryStatus status;
  final Color color;

  const _StatusPill({required this.status, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(appIsDark(context) ? 0.18 : 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_statusIcon(status), color: color, size: 16),
          const SizedBox(width: 6),
          Text(
            inventoryStatusLabel(status),
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _InventoryMetricLine extends StatelessWidget {
  final String label;
  final String value;

  const _InventoryMetricLine({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 124,
            child: Text(
              label,
              style: TextStyle(
                color: appMutedTextColor(context),
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                color: appTextColor(context),
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CardActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _CardActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: authPrimary,
        side: BorderSide(color: appBorderColor(context)),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
      ),
    );
  }
}

class _SourcePill extends StatelessWidget {
  final bool isAutomatic;

  const _SourcePill({required this.isAutomatic});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: appTintSurfaceColor(context),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        isAutomatic ? 'Automatic' : 'Manual',
        style: const TextStyle(
          color: authPrimary,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _InventoryEmptyState extends StatelessWidget {
  final VoidCallback onAdd;

  const _InventoryEmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return _InventoryPanel(
      child: _CenteredMessage(
        icon: Icons.inventory_2_outlined,
        title: 'No medicine inventory is being tracked.',
        message:
            'Select one of your saved medicines to begin tracking its quantity.',
        actionLabel: 'Track a Medicine',
        onAction: onAdd,
      ),
    );
  }
}

class _InventoryFilteredEmptyState extends StatelessWidget {
  final VoidCallback onReset;

  const _InventoryFilteredEmptyState({required this.onReset});

  @override
  Widget build(BuildContext context) {
    return _InventoryPanel(
      child: _CenteredMessage(
        icon: Icons.filter_alt_off_outlined,
        title: 'No inventory records match the selected filters.',
        message: 'Adjust the search, status, medicine, form, or date filters.',
        actionLabel: 'Reset Filters',
        onAction: onReset,
      ),
    );
  }
}

class _InventoryLoadingState extends StatelessWidget {
  const _InventoryLoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator(color: authPrimary));
  }
}

class _InventoryErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _InventoryErrorState({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: _InventoryPanel(
          child: _CenteredMessage(
            icon: Icons.error_outline,
            title: 'Could not load inventory',
            message: message,
            actionLabel: 'Retry',
            onAction: onRetry,
          ),
        ),
      ),
    );
  }
}

class _CenteredMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _CenteredMessage({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: authPrimary, size: 46),
        const SizedBox(height: 12),
        Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: appTextColor(context),
            fontSize: 19,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: appMutedTextColor(context),
            fontWeight: FontWeight.w700,
          ),
        ),
        if (actionLabel != null && onAction != null) ...[
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onAction,
            icon: const Icon(Icons.add),
            label: Text(actionLabel!),
            style: FilledButton.styleFrom(backgroundColor: authPrimary),
          ),
        ],
      ],
    );
  }
}

class _InventoryFormScaffold extends StatelessWidget {
  final String title;
  final String heading;
  final String subtitle;
  final List<Widget> children;

  const _InventoryFormScaffold({
    required this.title,
    required this.heading,
    required this.subtitle,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appScaffoldColor(context),
      appBar: AppBar(
        backgroundColor: authPrimary,
        foregroundColor: Colors.white,
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
              children: [
                Text(
                  heading,
                  style: TextStyle(
                    color: appTextColor(context),
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: appMutedTextColor(context),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 18),
                ...children,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NumberField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String unitLabel;
  final IconData icon;
  final String? errorText;
  final ValueChanged<String>? onChanged;

  const _NumberField({
    required this.controller,
    required this.label,
    required this.unitLabel,
    required this.icon,
    this.errorText,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onChanged: onChanged,
      decoration: authInputDecoration(
        context: context,
        hintText: label,
        icon: icon,
        errorText: errorText,
        suffixIcon: Padding(
          padding: const EdgeInsetsDirectional.only(end: 12),
          child: Center(
            widthFactor: 1,
            child: Text(
              unitLabel,
              style: TextStyle(
                color: appMutedTextColor(context),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DatePickerTile extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  const _DatePickerTile({
    required this.label,
    required this.value,
    required this.onTap,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: appSoftSurfaceColor(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: appBorderColor(context)),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_outlined, color: authPrimary),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: appMutedTextColor(context),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    value,
                    style: TextStyle(
                      color: appTextColor(context),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            if (onClear != null)
              IconButton(
                tooltip: 'Clear',
                onPressed: onClear,
                icon: const Icon(Icons.close, color: authPrimary),
              ),
          ],
        ),
      ),
    );
  }
}

class _ReadOnlyQuantityTile extends StatelessWidget {
  final String label;
  final String value;

  const _ReadOnlyQuantityTile({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: appSoftSurfaceColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: appBorderColor(context)),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              color: appMutedTextColor(context),
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              color: appTextColor(context),
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _FormNotice extends StatelessWidget {
  final IconData icon;
  final String message;

  const _FormNotice({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: appTintSurfaceColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: authPrimary.withOpacity(0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: authPrimary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: authPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InventoryViewItem {
  final MedicineInventory inventory;
  final Medicine? medicine;
  final InventoryStatus status;
  final int? dosesRemaining;
  final int? daysRemaining;

  const _InventoryViewItem({
    required this.inventory,
    required this.medicine,
    required this.status,
    required this.dosesRemaining,
    required this.daysRemaining,
  });

  String get medicineName => medicine?.name ?? 'Deleted medicine';

  String get medicineForm {
    final form = medicine?.form.trim();
    return form == null || form.isEmpty ? 'Unknown form' : form;
  }

  bool get isArchived => medicine == null || medicine!.isArchived;
}

class _InventorySummary {
  final int tracked;
  final int lowStock;
  final int outOfStock;
  final int expiringSoon;

  const _InventorySummary({
    required this.tracked,
    required this.lowStock,
    required this.outOfStock,
    required this.expiringSoon,
  });
}

class _SummaryData {
  final String label;
  final int value;
  final IconData icon;
  final Color color;

  const _SummaryData(this.label, this.value, this.icon, this.color);
}

enum _DeleteInventoryChoice { keepHistory, deleteHistory }

int _dateSort(DateTime? a, DateTime? b) {
  if (a == null && b == null) return 0;
  if (a == null) return 1;
  if (b == null) return -1;
  return a.compareTo(b);
}

int _dateSortDesc(DateTime? a, DateTime? b) {
  if (a == null && b == null) return 0;
  if (a == null) return 1;
  if (b == null) return -1;
  return b.compareTo(a);
}

int _nullableIntSort(int? a, int? b) {
  if (a == null && b == null) return 0;
  if (a == null) return 1;
  if (b == null) return -1;
  return a.compareTo(b);
}

Color _statusColor(InventoryStatus status) {
  switch (status) {
    case InventoryStatus.goodSupply:
      return authPrimary;
    case InventoryStatus.lowStock:
      return const Color(0xFFF59E0B);
    case InventoryStatus.outOfStock:
      return Colors.redAccent;
    case InventoryStatus.expiringSoon:
      return const Color(0xFF7C3AED);
    case InventoryStatus.expired:
      return const Color(0xFFB91C1C);
    case InventoryStatus.trackingDisabled:
      return const Color(0xFF64748B);
  }
}

IconData _statusIcon(InventoryStatus status) {
  switch (status) {
    case InventoryStatus.goodSupply:
      return Icons.check_circle_outline;
    case InventoryStatus.lowStock:
      return Icons.warning_amber_outlined;
    case InventoryStatus.outOfStock:
      return Icons.remove_shopping_cart_outlined;
    case InventoryStatus.expiringSoon:
      return Icons.event_busy_outlined;
    case InventoryStatus.expired:
      return Icons.error_outline;
    case InventoryStatus.trackingDisabled:
      return Icons.pause_circle_outline;
  }
}

String _expirationLabel(DateTime? date) {
  if (date == null) return 'No expiration date';
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final expiration = DateTime(date.year, date.month, date.day);
  final days = expiration.difference(today).inDays;
  if (days < 0) return 'Expired ${days.abs()} days ago';
  if (days == 0) return 'Expires today';
  if (days == 1) return 'Expires tomorrow';
  return 'Expires in $days days';
}

String _formatDate(DateTime date) {
  const months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  return '${months[date.month - 1]} ${date.day}, ${date.year}';
}

String _formatDateTime(DateTime? date) {
  if (date == null) return 'Date not recorded';
  final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
  final minute = date.minute.toString().padLeft(2, '0');
  final period = date.hour >= 12 ? 'PM' : 'AM';
  return '${_formatDate(date)} at $hour:$minute $period';
}

String _formatOptional(double? value) {
  return value == null ? '' : formatInventoryQuantity(value);
}

double? _parseRequiredDouble(String value) {
  final text = value.trim();
  if (text.isEmpty) return null;
  return double.tryParse(text);
}

double? _parseOptionalDouble(String value) {
  final text = value.trim();
  if (text.isEmpty) return null;
  return double.tryParse(text);
}

String _unitMenuLabel(InventoryQuantityUnit unit) {
  switch (unit) {
    case InventoryQuantityUnit.tablets:
      return 'Tablets';
    case InventoryQuantityUnit.capsules:
      return 'Capsules';
    case InventoryQuantityUnit.milliliters:
      return 'Milliliters';
    case InventoryQuantityUnit.drops:
      return 'Drops';
    case InventoryQuantityUnit.spoons:
      return 'Spoons';
    case InventoryQuantityUnit.injections:
      return 'Injections';
    case InventoryQuantityUnit.units:
      return 'Units';
    case InventoryQuantityUnit.patches:
      return 'Patches';
    case InventoryQuantityUnit.sachets:
      return 'Sachets';
    case InventoryQuantityUnit.applications:
      return 'Applications';
    case InventoryQuantityUnit.other:
      return 'Other';
  }
}

String _unitFromMedicine(Medicine? medicine) {
  final form = medicine?.form.toLowerCase() ?? '';
  if (form.contains('pill')) return InventoryQuantityUnit.tablets.name;
  if (form.contains('syrup')) return InventoryQuantityUnit.milliliters.name;
  if (form.contains('drop')) return InventoryQuantityUnit.drops.name;
  if (form.contains('injection')) return InventoryQuantityUnit.injections.name;
  if (form.contains('cream') || form.contains('gel')) {
    return InventoryQuantityUnit.applications.name;
  }
  if (form.contains('patch')) return InventoryQuantityUnit.patches.name;
  return InventoryQuantityUnit.units.name;
}
