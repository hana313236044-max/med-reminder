import 'package:flutter/material.dart';
import 'package:uhd/auth_widgets.dart';
import 'package:uhd/med_models.dart';

class AddReminderPage extends StatefulWidget {
  final List<Medicine> medicines;
  final ValueChanged<List<MedicationReminder>> onSaveReminders;

  const AddReminderPage({
    super.key,
    required this.medicines,
    required this.onSaveReminders,
  });

  @override
  State<AddReminderPage> createState() => _AddReminderPageState();
}

class _AddReminderPageState extends State<AddReminderPage> {
  final _notesController = TextEditingController();
  final _intervalController = TextEditingController(text: '1');
  final _durationDaysController = TextEditingController(text: '1');

  Medicine? _selectedMedicine;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  bool _isRepeating = false;
  String _repeatUnit = 'hours';
  int _quantity = 1;
  String? _medicineError;
  String? _intervalError;
  String? _durationError;

  final List<String> _repeatUnits = const ['hours', 'days', 'weeks'];

  String get _quantityUnit {
    final form = _selectedMedicine?.form.toLowerCase() ?? '';
    if (form.contains('drop')) return 'drops';
    if (form.contains('pill')) return 'pills';
    if (form.contains('syrup')) return 'spoons';
    if (form.contains('injection')) return 'doses';
    if (form.contains('inhaler') || form.contains('spray')) return 'puffs';
    return 'units';
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

  void _save() {
    final interval = int.tryParse(_intervalController.text.trim());
    final durationDays = int.tryParse(_durationDaysController.text.trim());
    setState(() {
      _medicineError = _selectedMedicine == null ? 'Choose a medicine' : null;
      _intervalError = _isRepeating && (interval == null || interval <= 0)
          ? 'Enter a number greater than 0'
          : null;
      _durationError = _isRepeating &&
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

    final medicine = _selectedMedicine!;
    widget.onSaveReminders(
      _buildReminderRecords(
        medicine: medicine,
        firstAt: scheduledAt,
        interval: interval ?? 1,
        durationDays: durationDays ?? 1,
        label: label,
      ),
    );
    Navigator.pop(context);
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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: authInk,
        elevation: 0,
        title: const Text(
          'Add Reminder',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
          children: [
            Text(
              'Schedule medicine',
              style: const TextStyle(
                color: authInk,
                fontSize: 28,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Pick a saved medicine, dose, and exact schedule.',
              style: TextStyle(
                color: Colors.blueGrey.shade600,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 20),
            if (widget.medicines.isEmpty)
              _NoMedicinesNotice()
            else
              _MedicineAutocomplete(
                medicines: widget.medicines,
                selected: _selectedMedicine,
                errorText: _medicineError,
                onCleared: () {
                  setState(() => _selectedMedicine = null);
                },
                onSelected: (medicine) {
                  setState(() {
                    _selectedMedicine = medicine;
                    _medicineError = null;
                    _quantity = 1;
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
                      hintText: 'How many $_quantityUnit?',
                      icon: Icons.format_list_numbered,
                    ),
                    items: List.generate(10, (index) => index + 1)
                        .map(
                          (count) => DropdownMenuItem(
                            value: count,
                            child: Text('$count $_quantityUnit'),
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
                color: const Color(0xFFEAF8F6),
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
                hintText: 'Notes optional',
                icon: Icons.notes_outlined,
              ),
            ),
            const SizedBox(height: 22),
            AuthPrimaryButton(
              label: 'Save Reminder',
              icon: Icons.check_circle_outline,
              onPressed: widget.medicines.isEmpty ? () {} : _save,
            ),
          ],
        ),
      ),
    );
  }
}

class _MedicineAutocomplete extends StatelessWidget {
  final List<Medicine> medicines;
  final Medicine? selected;
  final String? errorText;
  final ValueChanged<Medicine> onSelected;
  final VoidCallback onCleared;

  const _MedicineAutocomplete({
    required this.medicines,
    required this.selected,
    required this.errorText,
    required this.onSelected,
    required this.onCleared,
  });

  @override
  Widget build(BuildContext context) {
    return Autocomplete<Medicine>(
      displayStringForOption: (medicine) => medicine.name,
      optionsBuilder: (value) {
        final query = value.text.toLowerCase().trim();
        if (query.isEmpty) return medicines;
        return medicines.where(
          (medicine) =>
              medicine.name.toLowerCase().contains(query) ||
              medicine.category.toLowerCase().contains(query) ||
              medicine.form.toLowerCase().contains(query),
        );
      },
      onSelected: onSelected,
      fieldViewBuilder: (context, controller, focusNode, onSubmit) {
        if (selected != null && controller.text != selected!.name) {
          controller.text = selected!.name;
        }
        return TextField(
          controller: controller,
          focusNode: focusNode,
          onChanged: (value) {
            if (selected != null && value != selected!.name) {
              onCleared();
            }
          },
          decoration: authInputDecoration(
            hintText: 'Search and choose medicine',
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
                  final medicine = options.elementAt(index);
                  return ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    leading: const Icon(
                      Icons.medication_outlined,
                      color: authPrimary,
                    ),
                    title: Text(medicine.name),
                    subtitle: Text('${medicine.category} - ${medicine.form}'),
                    onTap: () => onSelectedOption(medicine),
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
          color: const Color(0xFFF3FAF9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.teal.shade50),
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
                      color: Colors.blueGrey.shade500,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    value,
                    style: const TextStyle(
                      color: authInk,
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
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? authPrimary : Colors.blueGrey.shade500,
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
        'Add a medicine first from My Medicines, then create reminders.',
        style: TextStyle(
          color: Color(0xFF7A4B00),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
