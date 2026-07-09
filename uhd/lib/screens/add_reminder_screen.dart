// This screen schedules medicine reminders.
import 'package:flutter/material.dart';
import 'package:uhd/widgets/app_widgets.dart';
import 'package:uhd/models/medicine_inventory_model.dart';
import 'package:uhd/models/medicine_models.dart';

class AddReminderPage extends StatefulWidget {
  final List<Medicine> medicines;
  final List<MedicineInventory> inventories;
  final Future<void> Function(List<MedicationReminder>) onSaveReminders;

  const AddReminderPage({
    super.key,
    required this.medicines,
    required this.inventories,
    required this.onSaveReminders,
  });

  @override
  State<AddReminderPage> createState() => _AddReminderPageState();
}

class _AddReminderPageState extends State<AddReminderPage> {
  final _notesController = TextEditingController();
  final _intervalController = TextEditingController(text: '1');
  final _durationDaysController = TextEditingController(text: '1');

  _ReminderInventoryOption? _selectedOption;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  bool _isRepeating = false;
  String _repeatUnit = 'hours';
  int _quantity = 1;
  String? _medicineError;
  String? _intervalError;
  String? _durationError;
  bool _isSaving = false;

  final List<String> _repeatUnits = const ['hours', 'days', 'weeks'];

  List<_ReminderInventoryOption> get _inventoryOptions {
    final medicinesById = {
      for (final medicine in widget.medicines) medicine.id.toString(): medicine,
    };
    final options = <_ReminderInventoryOption>[];
    for (final inventory in widget.inventories) {
      if (!inventory.trackingEnabled) continue;
      final medicineId = int.tryParse(inventory.medicineId);
      if (medicineId == null) continue;
      final medicine = medicinesById[inventory.medicineId] ??
          Medicine(
            id: medicineId,
            name: 'Medicine ${inventory.medicineId}',
            category: 'Inventory',
            form: inventoryQuantityUnitLabel(
              inventory.quantityUnitKey,
              customQuantityUnit: inventory.customQuantityUnit,
            ),
            ageGroup: 'All ages',
          );
      options.add(
        _ReminderInventoryOption(medicine: medicine, inventory: inventory),
      );
    }
    options.sort(
      (a, b) => a.medicine.name.toLowerCase().compareTo(
        b.medicine.name.toLowerCase(),
      ),
    );
    return options;
  }

  String get _quantityUnit {
    return _quantityUnitFor(_quantity);
  }

  String _quantityUnitFor(int quantity) {
    final inventory = _selectedOption?.inventory;
    if (inventory == null) return 'units';
    return inventoryQuantityUnitLabel(
      inventory.quantityUnitKey,
      customQuantityUnit: inventory.customQuantityUnit,
      plural: quantity != 1,
    );
  }

  int _initialQuantityFor(MedicineInventory inventory) {
    final defaultDose = inventory.defaultDoseQuantity;
    if (defaultDose == null || defaultDose <= 0) return 1;
    return defaultDose.round().clamp(1, 10).toInt();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  Future<void> _save() async {
    if (_isSaving) return;

    final interval = int.tryParse(_intervalController.text.trim());
    final durationDays = int.tryParse(_durationDaysController.text.trim());
    setState(() {
      _medicineError = _selectedOption == null
          ? 'Choose a medicine from inventory'
          : null;
      _intervalError = _isRepeating && (interval == null || interval <= 0)
          ? 'Enter a number greater than 0'
          : null;
      _durationError =
          _isRepeating &&
              (durationDays == null || durationDays <= 0 || durationDays > 365)
          ? 'Enter 1 to 365 days'
          : null;
    });

    if (_medicineError != null ||
        _intervalError != null ||
        _durationError != null) {
      return;
    }

    final scheduledAt = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    final label = _isRepeating
        ? 'Every ${_intervalController.text.trim()} $_repeatUnit'
        : 'One time';

    final medicine = _selectedOption!.medicine;
    setState(() => _isSaving = true);
    try {
      await widget.onSaveReminders(
        _buildReminderRecords(
          medicine: medicine,
          firstAt: scheduledAt,
          interval: interval ?? 1,
          durationDays: durationDays ?? 1,
          label: label,
        ),
      );
      if (!mounted) return;
      Navigator.pop(context);
    } catch (_) {
      if (!mounted) return;
      showAuthMessage(
        context,
        'Could not save reminder. Please try again.',
        backgroundColor: Colors.redAccent,
      );
      setState(() => _isSaving = false);
    }
  }

  List<MedicationReminder> _buildReminderRecords({
    required Medicine medicine,
    required DateTime firstAt,
    required int interval,
    required int durationDays,
    required String label,
  }) {
    final dates = <DateTime>[];
    if (_isRepeating) {
      final endAt = firstAt.add(Duration(days: durationDays));
      var current = firstAt;
      while (current.isBefore(endAt)) {
        dates.add(current);
        current = current.add(_intervalDuration(interval));
      }
    } else {
      dates.add(firstAt);
    }

    final records = <MedicationReminder>[];
    final notes = _notesController.text.trim();
    var idSeed = DateTime.now().microsecondsSinceEpoch;

    for (final date in dates) {
      records.add(
        MedicationReminder(
          id: idSeed++,
          medicineId: medicine.id,
          medicineName: medicine.name,
          medicineCategory: medicine.category,
          medicineForm: medicine.form,
          scheduledAt: date,
          quantity: _quantity,
          quantityUnit: _quantityUnit,
          scheduleLabel: label,
          notes: notes.isEmpty ? null : notes,
        ),
      );
    }

    return records;
  }

  Duration _intervalDuration(int interval) {
    switch (_repeatUnit) {
      case 'days':
        return Duration(days: interval);
      case 'weeks':
        return Duration(days: interval * 7);
      case 'hours':
      default:
        return Duration(hours: interval);
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    _intervalController.dispose();
    _durationDaysController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inventoryOptions = _inventoryOptions;
    return Scaffold(
      backgroundColor: appScaffoldColor(context),
      appBar: AppBar(
        backgroundColor: authPrimary,
        foregroundColor: authInk,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Add Reminder',
          style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
          children: [
            Text(
              'Schedule medicine',
              style: TextStyle(
                color: appTextColor(context),
                fontSize: 28,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Pick a medicine from inventory, dose, and exact schedule.',
              style: TextStyle(
                color: appMutedTextColor(context),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 20),
            if (inventoryOptions.isEmpty)
              _NoMedicinesNotice()
            else
              _InventoryMedicineAutocomplete(
                options: inventoryOptions,
                selected: _selectedOption,
                errorText: _medicineError,
                onCleared: () {
                  setState(() => _selectedOption = null);
                },
                onSelected: (option) {
                  setState(() {
                    _selectedOption = option;
                    _medicineError = null;
                    _quantity = _initialQuantityFor(option.inventory);
                  });
                },
              ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _PickerTile(
                    icon: Icons.calendar_today_outlined,
                    label: 'Day',
                    value:
                        '${_selectedDate.year}/${_selectedDate.month}/${_selectedDate.day}',
                    onTap: _pickDate,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _PickerTile(
                    icon: Icons.schedule_outlined,
                    label: 'Time',
                    value: _selectedTime.format(context),
                    onTap: _pickTime,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: _quantity,
                    decoration: authInputDecoration(
                      context: context,
                      hintText: 'How many $_quantityUnit?',
                      icon: Icons.format_list_numbered,
                    ),
                    items: List.generate(10, (index) => index + 1)
                        .map(
                          (count) => DropdownMenuItem(
                            value: count,
                            child: Text('$count ${_quantityUnitFor(count)}'),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setState(() => _quantity = value ?? 1);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: appTintSurfaceColor(context),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  _ScheduleModeButton(
                    label: 'One time',
                    selected: !_isRepeating,
                    onTap: () => setState(() => _isRepeating = false),
                  ),
                  _ScheduleModeButton(
                    label: 'Repeating',
                    selected: _isRepeating,
                    onTap: () => setState(() => _isRepeating = true),
                  ),
                ],
              ),
            ),
            if (_isRepeating) ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _intervalController,
                      keyboardType: TextInputType.number,
                      decoration: authInputDecoration(
                        context: context,
                        hintText: 'Every number',
                        icon: Icons.repeat_outlined,
                        errorText: _intervalError,
                      ),
                      onChanged: (_) {
                        if (_intervalError != null) {
                          setState(() {
                            final value = int.tryParse(
                              _intervalController.text.trim(),
                            );
                            _intervalError = value == null || value <= 0
                                ? 'Enter a number greater than 0'
                                : null;
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _repeatUnit,
                      decoration: authInputDecoration(
                        context: context,
                        hintText: 'Every what',
                        icon: Icons.timelapse_outlined,
                      ),
                      items: _repeatUnits
                          .map(
                            (unit) => DropdownMenuItem(
                              value: unit,
                              child: Text(unit),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setState(() => _repeatUnit = value ?? 'hours');
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _durationDaysController,
                keyboardType: TextInputType.number,
                decoration: authInputDecoration(
                  context: context,
                  hintText: 'For how many days?',
                  icon: Icons.event_repeat_outlined,
                  errorText: _durationError,
                ),
                onChanged: (_) {
                  if (_durationError != null) {
                    setState(() {
                      final value = int.tryParse(
                        _durationDaysController.text.trim(),
                      );
                      _durationError =
                          value == null || value <= 0 || value > 365
                          ? 'Enter 1 to 365 days'
                          : null;
                    });
                  }
                },
              ),
            ],
            const SizedBox(height: 14),
            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: authInputDecoration(
                context: context,
                hintText: 'Notes optional',
                icon: Icons.notes_outlined,
              ),
            ),
            const SizedBox(height: 22),
            AuthPrimaryButton(
              label: _isSaving ? 'Saving...' : 'Save Reminder',
              icon: Icons.check_circle_outline,
              onPressed: inventoryOptions.isEmpty ? () {} : _save,
            ),
          ],
        ),
      ),
    );
  }
}

class _ReminderInventoryOption {
  final Medicine medicine;
  final MedicineInventory inventory;

  const _ReminderInventoryOption({
    required this.medicine,
    required this.inventory,
  });

  String get unitLabel {
    return inventoryQuantityUnitLabel(
      inventory.quantityUnitKey,
      customQuantityUnit: inventory.customQuantityUnit,
    );
  }

  String get stockLabel {
    return '${formatInventoryQuantity(inventory.currentQuantity)} $unitLabel';
  }
}

class _InventoryMedicineAutocomplete extends StatelessWidget {
  final List<_ReminderInventoryOption> options;
  final _ReminderInventoryOption? selected;
  final String? errorText;
  final ValueChanged<_ReminderInventoryOption> onSelected;
  final VoidCallback onCleared;

  const _InventoryMedicineAutocomplete({
    required this.options,
    required this.selected,
    required this.errorText,
    required this.onSelected,
    required this.onCleared,
  });

  @override
  Widget build(BuildContext context) {
    return Autocomplete<_ReminderInventoryOption>(
      displayStringForOption: (option) => option.medicine.name,
      optionsBuilder: (value) {
        final query = value.text.toLowerCase().trim();
        if (query.isEmpty) return options;
        return options.where(
          (option) =>
              option.medicine.name.toLowerCase().contains(query) ||
              option.medicine.category.toLowerCase().contains(query) ||
              option.medicine.form.toLowerCase().contains(query) ||
              option.unitLabel.toLowerCase().contains(query),
        );
      },
      onSelected: onSelected,
      fieldViewBuilder: (context, controller, focusNode, onSubmit) {
        if (selected != null && controller.text != selected!.medicine.name) {
          controller.text = selected!.medicine.name;
        }
        return TextField(
          controller: controller,
          focusNode: focusNode,
          onChanged: (value) {
            if (selected != null && value != selected!.medicine.name) {
              onCleared();
            }
          },
          decoration: authInputDecoration(
            context: context,
            hintText: 'Search and choose inventory medicine',
            icon: Icons.search,
            errorText: errorText,
          ),
        );
      },
      optionsViewBuilder: (context, onSelectedOption, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 220, maxWidth: 520),
              child: ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final option = options.elementAt(index);
                  final medicine = option.medicine;
                  return ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    leading: const Icon(
                      Icons.medication_outlined,
                      color: authPrimary,
                    ),
                    title: Text(medicine.name),
                    subtitle: Text(
                      '${medicine.category} - ${medicine.form} - Stock: ${option.stockLabel}',
                    ),
                    onTap: () => onSelectedOption(option),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PickerTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  const _PickerTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
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
            Icon(icon, color: authPrimary),
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
          ],
        ),
      ),
    );
  }
}

class _ScheduleModeButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ScheduleModeButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? appSurfaceColor(context) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: appShadowColor(context, 0.06),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? authPrimary : appMutedTextColor(context),
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _NoMedicinesNotice extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4E5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFD7A3)),
      ),
      child: const Text(
        'Track a medicine first from Medicine Inventory, then create reminders.',
        style: TextStyle(color: Color(0xFF7A4B00), fontWeight: FontWeight.w700),
      ),
    );
  }
}
