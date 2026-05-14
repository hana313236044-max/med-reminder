import 'package:flutter/material.dart';
import 'package:uhd/AddReminderPage.dart';
import 'package:uhd/ContactUs.dart';
import 'package:uhd/Help.dart';
import 'package:uhd/MyMedicinesPage.dart';
import 'package:uhd/Settings.dart';
import 'package:uhd/auth_widgets.dart';
import 'package:uhd/med_models.dart';

enum ReminderFilter { all, completed, delayed, waiting }

class HomePage extends StatefulWidget {
  final String userName;

  const HomePage({super.key, required this.userName});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final List<MedicationReminder> _reminders = [];
  final List<Medicine> _medicines = [];
  ReminderFilter _filter = ReminderFilter.all;
  DateTime _selectedDate = DateTime.now();

  List<MedicationReminder> get _filteredReminders {
    final dayReminders = _reminders
        .where((reminder) => _isSameDay(reminder.scheduledAt, _selectedDate))
        .toList();
    switch (_filter) {
      case ReminderFilter.completed:
        return dayReminders.where((reminder) => reminder.isCompleted).toList();
      case ReminderFilter.delayed:
        return dayReminders.where((reminder) => reminder.isDelayed).toList();
      case ReminderFilter.waiting:
        return dayReminders
            .where(
              (reminder) =>
                  reminder.status == ReminderStatus.waiting &&
                  !reminder.isDelayed,
            )
            .toList();
      case ReminderFilter.all:
        return dayReminders;
    }
  }

  int _countFor(ReminderFilter filter) {
    final dayReminders = _reminders
        .where((reminder) => _isSameDay(reminder.scheduledAt, _selectedDate))
        .toList();
    switch (filter) {
      case ReminderFilter.all:
        return dayReminders.length;
      case ReminderFilter.completed:
        return dayReminders.where((reminder) => reminder.isCompleted).length;
      case ReminderFilter.delayed:
        return dayReminders.where((reminder) => reminder.isDelayed).length;
      case ReminderFilter.waiting:
        return dayReminders
            .where(
              (reminder) =>
                  reminder.status == ReminderStatus.waiting &&
                  !reminder.isDelayed,
            )
            .length;
    }
  }

  bool _isSameDay(DateTime first, DateTime second) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }

  void _saveMedicine(Medicine medicine) {
    setState(() {
      final index = _medicines.indexWhere((item) => item.id == medicine.id);
      if (index == -1) {
        _medicines.add(medicine);
      } else {
        _medicines[index] = medicine;
        for (final reminder in _reminders) {
          if (reminder.medicineId == medicine.id) {
            reminder.medicineName = medicine.name;
            reminder.medicineCategory = medicine.category;
            reminder.medicineForm = medicine.form;
          }
        }
      }
    });
  }

  void _deleteMedicine(int medicineId) {
    setState(() {
      _medicines.removeWhere((medicine) => medicine.id == medicineId);
      _reminders.removeWhere((reminder) => reminder.medicineId == medicineId);
    });
  }

  void _saveReminders(List<MedicationReminder> reminders) {
    setState(() {
      _reminders.addAll(reminders);
      if (reminders.isNotEmpty) {
        _selectedDate = reminders.first.scheduledAt;
      }
    });
  }

  Future<void> _markTook(MedicationReminder reminder) async {
    final confirmed = await _confirmAction(
      title: 'Mark as took?',
      message: 'Do you want to mark this reminder as taken?',
      confirmLabel: 'Yes, Took',
      confirmColor: authPrimary,
    );
    if (!confirmed) return;

    setState(() => reminder.status = ReminderStatus.completed);
  }

  Future<void> _reschedule(MedicationReminder reminder) async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(reminder.scheduledAt),
    );
    if (time == null) return;

    setState(() {
      reminder.scheduledAt = DateTime(
        reminder.scheduledAt.year,
        reminder.scheduledAt.month,
        reminder.scheduledAt.day,
        time.hour,
        time.minute,
      );
      reminder.status = ReminderStatus.waiting;
    });
  }

  Future<void> _deleteReminder(MedicationReminder reminder) async {
    final confirmed = await _confirmAction(
      title: 'Delete reminder?',
      message: 'Do you want to delete this reminder?',
      confirmLabel: 'Delete',
      confirmColor: Colors.redAccent,
    );
    if (!confirmed) return;

    setState(() => _reminders.remove(reminder));
  }

  Future<bool> _confirmAction({
    required String title,
    required String message,
    required String confirmLabel,
    required Color confirmColor,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: confirmColor),
              onPressed: () => Navigator.pop(context, true),
              child: Text(confirmLabel),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }

  void _openMedicines() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MyMedicinesPage(
          medicines: _medicines,
          onSaveMedicine: _saveMedicine,
          onDeleteMedicine: _deleteMedicine,
        ),
      ),
    );
  }

  void _openAddReminder() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddReminderPage(
          medicines: _medicines,
          onSaveReminders: _saveReminders,
        ),
      ),
    );
  }

  Future<void> _pickSelectedDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() => _selectedDate = date);
    }
  }

  @override
  Widget build(BuildContext context) {
    final reminders = _filteredReminders;

    return Scaffold(
      backgroundColor: Colors.white,
      drawer: _HomeDrawer(
        userName: widget.userName,
        onOpenMedicines: _openMedicines,
      ),
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: authPrimary,
        foregroundColor: authInk,
        elevation: 0,
        title: const Text(
          'MedReminder',
          style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white),
        ),
        actions: [
          IconButton(
            tooltip: 'My Medicines',
            onPressed: _openMedicines,
            icon: const Icon(Icons.inventory_2_outlined, color: Colors.white),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: authPrimary,
        foregroundColor: Colors.white,
        onPressed: _openAddReminder,
        icon: const Icon(Icons.add),
        label: const Text('Reminder'),
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 6, 18, 0),
              child: _HomeHeader(
                userName: widget.userName,
                medicineCount: _medicines.length,
                reminderCount: _countFor(ReminderFilter.all),
                onOpenMedicines: _openMedicines,
                onAddReminder: _openAddReminder,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
              child: _SelectedDateCard(
                selectedDate: _selectedDate,
                onPrevious: () {
                  setState(() {
                    _selectedDate = _selectedDate.subtract(
                      const Duration(days: 1),
                    );
                  });
                },
                onNext: () {
                  setState(() {
                    _selectedDate = _selectedDate.add(const Duration(days: 1));
                  });
                },
                onPickDate: _pickSelectedDate,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
              child: _FilterBar(
                selected: _filter,
                countFor: _countFor,
                onSelected: (filter) => setState(() => _filter = filter),
              ),
            ),
          ),
          if (reminders.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 90),
                child: _EmptyReminderState(
                  hasMedicines: _medicines.isNotEmpty,
                  onOpenMedicines: _openMedicines,
                  onAddReminder: _openAddReminder,
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 96),
              sliver: SliverLayoutBuilder(
                builder: (context, constraints) {
                  final crossAxisCount = constraints.crossAxisExtent >= 560
                      ? 2
                      : 1;
                  return SliverGrid(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final reminder = reminders[index];
                      return _ReminderCard(
                        reminder: reminder,
                        onTook: () => _markTook(reminder),
                        onReschedule: reminder.isCompleted
                            ? null
                            : () => _reschedule(reminder),
                        onDelete: () => _deleteReminder(reminder),
                      );
                    }, childCount: reminders.length),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      mainAxisExtent: 285,
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _SelectedDateCard extends StatelessWidget {
  final DateTime selectedDate;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onPickDate;

  const _SelectedDateCard({
    required this.selectedDate,
    required this.onPrevious,
    required this.onNext,
    required this.onPickDate,
  });

  String get _label {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selected = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
    );
    if (selected == today) return 'Today';
    if (selected == today.add(const Duration(days: 1))) return 'Tomorrow';
    if (selected == today.subtract(const Duration(days: 1))) return 'Yesterday';
    return '${selectedDate.year}/${selectedDate.month}/${selectedDate.day}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.teal.shade50),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Previous day',
            onPressed: onPrevious,
            icon: const Icon(Icons.chevron_left, color: authInk),
          ),
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: onPickDate,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  children: [
                    Text(
                      _label,
                      style: const TextStyle(
                        color: authInk,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${selectedDate.year}/${selectedDate.month}/${selectedDate.day}',
                      style: TextStyle(
                        color: Colors.blueGrey.shade500,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Next day',
            onPressed: onNext,
            icon: const Icon(Icons.chevron_right, color: authInk),
          ),
        ],
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  final String userName;
  final int medicineCount;
  final int reminderCount;
  final VoidCallback onOpenMedicines;
  final VoidCallback onAddReminder;

  const _HomeHeader({
    required this.userName,
    required this.medicineCount,
    required this.reminderCount,
    required this.onOpenMedicines,
    required this.onAddReminder,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hi, $userName',
          style: const TextStyle(
            color: authInk,
            fontSize: 28,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Your reminders for the selected day',
          style: TextStyle(
            color: Colors.blueGrey.shade600,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _QuickAction(
                icon: Icons.inventory_2_outlined,
                label: 'Medicines',
                value: medicineCount.toString(),
                onTap: onOpenMedicines,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickAction(
                icon: Icons.notifications_active_outlined,
                label: 'Today',
                value: reminderCount.toString(),
                onTap: onAddReminder,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.teal.shade50),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFFEAF8F6),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: authPrimary),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: authInk,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.blueGrey.shade500,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  final ReminderFilter selected;
  final int Function(ReminderFilter filter) countFor;
  final ValueChanged<ReminderFilter> onSelected;

  const _FilterBar({
    required this.selected,
    required this.countFor,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final filters = [
      (ReminderFilter.all, 'All'),
      (ReminderFilter.completed, 'Complete'),
      (ReminderFilter.delayed, 'Delayed'),
      (ReminderFilter.waiting, 'Waiting'),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((entry) {
          final filter = entry.$1;
          final label = entry.$2;
          final isSelected = selected == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: ChoiceChip(
              selected: isSelected,
              onSelected: (_) => onSelected(filter),
              backgroundColor: Colors.white.withOpacity(0.78),
              selectedColor: Colors.white,
              side: BorderSide(
                color: isSelected ? authPrimary : Colors.white.withOpacity(0.6),
              ),
              label: Text(
                '$label ${countFor(filter)}',
                style: TextStyle(
                  color: isSelected ? authPrimary : authInk,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _ReminderCard extends StatelessWidget {
  final MedicationReminder reminder;
  final VoidCallback onTook;
  final VoidCallback? onReschedule;
  final VoidCallback onDelete;

  const _ReminderCard({
    required this.reminder,
    required this.onTook,
    required this.onReschedule,
    required this.onDelete,
  });

  String _statusLabel() {
    if (reminder.isCompleted) return 'Complete';
    if (reminder.isDelayed) return 'Delayed';
    return 'Waiting';
  }

  Color _statusColor() {
    if (reminder.isCompleted) return authPrimary;
    if (reminder.isDelayed) return Colors.redAccent;
    return const Color(0xFFB7791F);
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.96),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withOpacity(0.7)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF8F6),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.medication_outlined,
                  color: authPrimary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  reminder.medicineName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: authInk,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Delete',
                onPressed: onDelete,
                icon: const Icon(
                  Icons.delete_outline,
                  color: Colors.redAccent,
                  size: 22,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Tag(label: reminder.medicineCategory),
              _Tag(label: reminder.medicineForm),
              _Tag(label: reminder.scheduleLabel),
              _Tag(
                label: _statusLabel(),
                color: statusColor.withOpacity(0.12),
                textColor: statusColor,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Icon(Icons.schedule_outlined, color: authPrimary, size: 19),
              const SizedBox(width: 8),
              Text(
                '${reminder.scheduledAt.year}/${reminder.scheduledAt.month}/${reminder.scheduledAt.day}  ${reminder.time.format(context)}',
                style: const TextStyle(
                  color: authInk,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${reminder.quantity} ${reminder.quantityUnit}',
            style: TextStyle(
              color: Colors.blueGrey.shade600,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (reminder.notes != null) ...[
            const SizedBox(height: 6),
            Text(
              reminder.notes!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.blueGrey.shade500),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: reminder.isCompleted ? null : onTook,
                  icon: const Icon(Icons.check_circle_outline, size: 18),
                  label: const Text('Took'),
                  style: FilledButton.styleFrom(
                    backgroundColor: authPrimary,
                    disabledBackgroundColor: Colors.teal.shade100,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onReschedule,
                  icon: const Icon(Icons.update, size: 18),
                  label: const Text('Reschedule'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: authPrimary,
                    side: BorderSide(color: Colors.teal.shade100),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  final Color? color;
  final Color? textColor;

  const _Tag({required this.label, this.color, this.textColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color ?? const Color(0xFFEAF8F6),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor ?? authPrimary,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _EmptyReminderState extends StatelessWidget {
  final bool hasMedicines;
  final VoidCallback onOpenMedicines;
  final VoidCallback onAddReminder;

  const _EmptyReminderState({
    required this.hasMedicines,
    required this.onOpenMedicines,
    required this.onAddReminder,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.96),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.65)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.notifications_none_outlined,
              color: authPrimary,
              size: 48,
            ),
            const SizedBox(height: 12),
            const Text(
              'No reminders here',
              style: TextStyle(
                color: authInk,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              hasMedicines
                  ? 'Create a reminder from one of your saved medicines.'
                  : 'Add medicines first, then create reminders from them.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.blueGrey.shade500),
            ),
            const SizedBox(height: 18),
            AuthPrimaryButton(
              label: hasMedicines ? 'Add Reminder' : 'Open My Medicines',
              icon: hasMedicines ? Icons.add : Icons.inventory_2_outlined,
              onPressed: hasMedicines ? onAddReminder : onOpenMedicines,
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeDrawer extends StatelessWidget {
  final String userName;
  final VoidCallback onOpenMedicines;

  const _HomeDrawer({required this.userName, required this.onOpenMedicines});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: Colors.white),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Icon(Icons.medication_outlined, color: authPrimary),
                const SizedBox(height: 10),
                Text(
                  'Welcome, $userName',
                  style: const TextStyle(
                    color: authInk,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home_outlined),
            title: const Text('Home'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.inventory_2_outlined),
            title: const Text('My Medicines'),
            onTap: () {
              Navigator.pop(context);
              onOpenMedicines();
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => Settings()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.contact_mail),
            title: const Text('Contact Us'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ContactUsPage()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.help),
            title: const Text('Help'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => HelpPage()),
              );
            },
          ),
        ],
      ),
    );
  }
}
