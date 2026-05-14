import 'package:flutter/material.dart';
import 'package:uhd/AddMedicinePage.dart';
import 'package:uhd/AddReminderPage.dart';
import 'package:uhd/Settings.dart';
import 'package:uhd/auth_widgets.dart';
import 'package:uhd/med_models.dart';

enum ReminderFilter { all, completed, delayed, waiting, notTaken }

class HomePage extends StatefulWidget {
  final String userName;
  final String email;
  final String age;
  final String bloodType;

  const HomePage({
    super.key,
    required this.userName,
    this.email = 'Not added',
    this.age = 'Not added',
    this.bloodType = 'Not added',
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final List<MedicationReminder> _reminders = [];
  final List<Medicine> _medicines = [];
  ReminderFilter _filter = ReminderFilter.all;
  DateTime _selectedDate = DateTime.now();
  int _selectedTab = 0;

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
                  !reminder.isDelayed &&
                  !reminder.isNotTaken,
            )
            .toList();
      case ReminderFilter.notTaken:
        return dayReminders.where((reminder) => reminder.isNotTaken).toList();
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
                  !reminder.isDelayed &&
                  !reminder.isNotTaken,
            )
            .length;
      case ReminderFilter.notTaken:
        return dayReminders.where((reminder) => reminder.isNotTaken).length;
    }
  }

  bool _isSameDay(DateTime first, DateTime second) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }

  bool _isDateBeforeToday(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final checked = DateTime(date.year, date.month, date.day);
    return checked.isBefore(today);
  }

  bool _isReminderInPast(MedicationReminder reminder) {
    return _isDateBeforeToday(reminder.scheduledAt);
  }

  void _setSelectedDate(DateTime date) {
    setState(() {
      _selectedDate = date;
      if (!_isDateBeforeToday(date) && _filter == ReminderFilter.notTaken) {
        _filter = ReminderFilter.all;
      }
    });
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

  Future<void> _deleteMedicine(int medicineId) async {
    final confirmed = await _confirmAction(
      title: 'Delete medicine?',
      message:
          'Do you want to delete this medicine? Related reminders will be removed too.',
      confirmLabel: 'Delete',
      confirmColor: Colors.redAccent,
    );
    if (!confirmed) return;

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

    final updatedAt = DateTime(
      reminder.scheduledAt.year,
      reminder.scheduledAt.month,
      reminder.scheduledAt.day,
      time.hour,
      time.minute,
    );

    if (updatedAt.isBefore(DateTime.now())) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Choose a future time for this reminder.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.redAccent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );
      return;
    }

    setState(() {
      reminder.scheduledAt = updatedAt;
      reminder.status = ReminderStatus.waiting;
      reminder.isRescheduled = true;
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
    setState(() => _selectedTab = 1);
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
      _setSelectedDate(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: authPrimary,
        foregroundColor: authInk,
        elevation: 0,
        title: Text(
          _titleForTab(),
          style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white),
        ),
      ),
      floatingActionButton: _selectedTab > 1
          ? null
          : FloatingActionButton.extended(
              backgroundColor: authPrimary,
              foregroundColor: Colors.white,
              onPressed: _selectedTab == 1
                  ? _openAddMedicineFromTab
                  : _openAddReminder,
              icon: const Icon(Icons.add),
              label: Text(_selectedTab == 1 ? 'Medicine' : 'Reminder'),
            ),
      bottomNavigationBar: _AppBottomNavigation(
        selectedIndex: _selectedTab,
        onSelected: (index) => setState(() => _selectedTab = index),
      ),
      body: _bodyForTab(),
    );
  }

  String _titleForTab() {
    switch (_selectedTab) {
      case 1:
        return 'Medicine';
      case 2:
        return 'Settings';
      case 3:
        return 'Profile';
      case 0:
      default:
        return 'MedReminder';
    }
  }

  Widget _bodyForTab() {
    switch (_selectedTab) {
      case 1:
        return _MedicineTab(
          medicines: _medicines,
          onAddMedicine: _openAddMedicineFromTab,
          onEditMedicine: _openEditMedicineFromTab,
          onDeleteMedicine: _deleteMedicine,
        );
      case 2:
        return const Settings(showScaffold: false);
      case 3:
        return _ProfileTab(
          userName: widget.userName,
          email: widget.email,
          age: widget.age,
          bloodType: widget.bloodType,
        );
      case 0:
      default:
        return _HomeTab();
    }
  }

  Widget _HomeTab() {
    final reminders = _filteredReminders;
    final isPastDate = _isDateBeforeToday(_selectedDate);
    final showSkippedEmptyState =
        _filter == ReminderFilter.notTaken && isPastDate;

    return CustomScrollView(
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
                _setSelectedDate(
                  _selectedDate.subtract(const Duration(days: 1)),
                );
              },
              onNext: () {
                _setSelectedDate(_selectedDate.add(const Duration(days: 1)));
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
              showNotTaken: isPastDate,
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
                title: showSkippedEmptyState
                    ? 'No medicine has been skipped'
                    : null,
                message: showSkippedEmptyState
                    ? 'Everything was handled on this day.'
                    : null,
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
                      onTook: _isReminderInPast(reminder)
                          ? null
                          : () => _markTook(reminder),
                      onReschedule:
                          reminder.isCompleted || _isReminderInPast(reminder)
                          ? null
                          : () => _reschedule(reminder),
                      onDelete: _isReminderInPast(reminder)
                          ? null
                          : () => _deleteReminder(reminder),
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
    );
  }

  void _openAddMedicineFromTab() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddMedicinePage(onSaveMedicine: _saveMedicine),
      ),
    );
  }

  void _openEditMedicineFromTab(Medicine medicine) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            AddMedicinePage(medicine: medicine, onSaveMedicine: _saveMedicine),
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

class _AppBottomNavigation extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const _AppBottomNavigation({
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    const items = [
      _BottomNavData(Icons.home_outlined, Icons.home, 'Home'),
      _BottomNavData(Icons.medication_outlined, Icons.medication, 'Medicine'),
      _BottomNavData(Icons.settings_outlined, Icons.settings, 'Settings'),
      _BottomNavData(Icons.person_outline, Icons.person, 'Profile'),
    ];

    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(14, 0, 14, 12),
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFE2F3F0)),
          boxShadow: [
            BoxShadow(
              color: authPrimary.withOpacity(0.14),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            for (var i = 0; i < items.length; i++)
              Expanded(
                child: _BottomNavItem(
                  data: items[i],
                  selected: selectedIndex == i,
                  onTap: () => onSelected(i),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _BottomNavData {
  final IconData icon;
  final IconData selectedIcon;
  final String label;

  const _BottomNavData(this.icon, this.selectedIcon, this.label);
}

class _BottomNavItem extends StatelessWidget {
  final _BottomNavData data;
  final bool selected;
  final VoidCallback onTap;

  const _BottomNavItem({
    required this.data,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 54,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: selected ? authPrimary : Colors.transparent,
          borderRadius: BorderRadius.circular(17),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: authPrimary.withOpacity(0.24),
                    blurRadius: 14,
                    offset: const Offset(0, 7),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              selected ? data.selectedIcon : data.icon,
              color: selected ? Colors.white : Colors.blueGrey.shade400,
              size: 22,
            ),
            const SizedBox(height: 3),
            FittedBox(
              child: Text(
                data.label,
                style: TextStyle(
                  color: selected ? Colors.white : Colors.blueGrey.shade500,
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
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
  final bool showNotTaken;
  final ValueChanged<ReminderFilter> onSelected;

  const _FilterBar({
    required this.selected,
    required this.countFor,
    required this.showNotTaken,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final filters = [
      (ReminderFilter.all, 'All'),
      (ReminderFilter.completed, 'Complete'),
      (ReminderFilter.delayed, 'Delayed'),
      (ReminderFilter.waiting, 'Waiting'),
      if (showNotTaken) (ReminderFilter.notTaken, 'Not taken'),
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
  final VoidCallback? onTook;
  final VoidCallback? onReschedule;
  final VoidCallback? onDelete;

  const _ReminderCard({
    required this.reminder,
    required this.onTook,
    required this.onReschedule,
    required this.onDelete,
  });

  String _statusLabel() {
    if (reminder.isCompleted) return 'Complete';
    if (reminder.isNotTaken) return 'Not taken';
    if (reminder.isDelayed) return 'Delayed';
    return 'Waiting';
  }

  Color _statusColor() {
    if (reminder.isCompleted) return authPrimary;
    if (reminder.isNotTaken) return Colors.redAccent;
    if (reminder.isDelayed) return Colors.redAccent;
    return const Color(0xFFB7791F);
  }

  Color _statusBackground() {
    if (reminder.isCompleted) return const Color(0xFFEAF8F6);
    if (reminder.isNotTaken) return const Color(0xFFFFECEC);
    if (reminder.isDelayed) return const Color(0xFFFFECEC);
    return const Color(0xFFFFF6E5);
  }

  IconData _statusIcon() {
    if (reminder.isCompleted) return Icons.check_circle_outline;
    if (reminder.isNotTaken) return Icons.cancel_outlined;
    if (reminder.isDelayed) return Icons.warning_amber_outlined;
    return Icons.schedule_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor();
    final statusBackground = _statusBackground();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusBackground.withOpacity(0.48),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: statusColor.withOpacity(0.32), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: statusColor.withOpacity(0.10),
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
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(_statusIcon(), color: statusColor),
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
                icon: Icon(
                  Icons.delete_outline,
                  color: onDelete == null ? Colors.grey : Colors.redAccent,
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
              if (reminder.isRescheduled)
                const _Tag(
                  label: 'Rescheduled',
                  color: Color(0xFFE8F0FF),
                  textColor: Color(0xFF3157B7),
                ),
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
                    disabledBackgroundColor: Colors.grey.shade200,
                    disabledForegroundColor: Colors.grey.shade500,
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
                    disabledForegroundColor: Colors.grey.shade500,
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
  final String? title;
  final String? message;

  const _EmptyReminderState({
    required this.hasMedicines,
    required this.onOpenMedicines,
    required this.onAddReminder,
    this.title,
    this.message,
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
            Text(
              title ?? 'No reminders here',
              style: const TextStyle(
                color: authInk,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message ??
                  (hasMedicines
                      ? 'Create a reminder from one of your saved medicines.'
                      : 'Add medicines first, then create reminders from them.'),
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

class _MedicineTab extends StatelessWidget {
  final List<Medicine> medicines;
  final VoidCallback onAddMedicine;
  final ValueChanged<Medicine> onEditMedicine;
  final ValueChanged<int> onDeleteMedicine;

  const _MedicineTab({
    required this.medicines,
    required this.onAddMedicine,
    required this.onEditMedicine,
    required this.onDeleteMedicine,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 96),
      children: [
        const Text(
          'Medicine',
          style: TextStyle(
            color: authInk,
            fontSize: 28,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Saved medicines for reminders and tracking.',
          style: TextStyle(
            color: Colors.blueGrey.shade600,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 16),
        if (medicines.isEmpty)
          const _EmptyMedicineInline()
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = constraints.maxWidth >= 560 ? 2 : 1;
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: medicines.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  mainAxisExtent: 220,
                ),
                itemBuilder: (context, index) {
                  final medicine = medicines[index];
                  return _MedicineInlineCard(
                    medicine: medicine,
                    onEdit: () => onEditMedicine(medicine),
                    onDelete: () => onDeleteMedicine(medicine.id),
                  );
                },
              );
            },
          ),
      ],
    );
  }
}

class _ProfileTab extends StatelessWidget {
  final String userName;
  final String email;
  final String age;
  final String bloodType;

  const _ProfileTab({
    required this.userName,
    required this.email,
    required this.age,
    required this.bloodType,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 96),
      children: [
        const Text(
          'Profile',
          style: TextStyle(
            color: authInk,
            fontSize: 28,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFE2F3F0)),
            boxShadow: [
              BoxShadow(
                color: authPrimary.withOpacity(0.08),
                blurRadius: 18,
                offset: const Offset(0, 9),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const CircleAvatar(
                    radius: 30,
                    backgroundColor: Color(0xFFEAF8F6),
                    child: Icon(Icons.person, color: authPrimary, size: 30),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userName,
                          style: const TextStyle(
                            color: authInk,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          'MediTrack user',
                          style: TextStyle(
                            color: Colors.blueGrey.shade500,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              LayoutBuilder(
                builder: (context, constraints) {
                  final useTwoColumns = constraints.maxWidth >= 520;
                  final items = [
                    _ProfileInfoData(
                      icon: Icons.badge_outlined,
                      label: 'Name',
                      value: userName,
                    ),
                    _ProfileInfoData(
                      icon: Icons.email_outlined,
                      label: 'Email',
                      value: email,
                    ),
                    _ProfileInfoData(
                      icon: Icons.cake_outlined,
                      label: 'Age',
                      value: age,
                    ),
                    _ProfileInfoData(
                      icon: Icons.bloodtype_outlined,
                      label: 'Blood type',
                      value: bloodType,
                    ),
                  ];

                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: items.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: useTwoColumns ? 2 : 1,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      mainAxisExtent: 86,
                    ),
                    itemBuilder: (context, index) {
                      return _ProfileInfoTile(data: items[index]);
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProfileInfoData {
  final IconData icon;
  final String label;
  final String value;

  const _ProfileInfoData({
    required this.icon,
    required this.label,
    required this.value,
  });
}

class _ProfileInfoTile extends StatelessWidget {
  final _ProfileInfoData data;

  const _ProfileInfoTile({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FCFB),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2F3F0)),
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
            child: Icon(data.icon, color: authPrimary, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  data.label,
                  style: TextStyle(
                    color: Colors.blueGrey.shade500,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  data.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: authInk,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
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

class _EmptyMedicineInline extends StatelessWidget {
  const _EmptyMedicineInline();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF8F6),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.teal.shade100),
      ),
      child: Column(
        children: [
          Icon(
            Icons.medication_outlined,
            size: 42,
            color: Colors.teal.shade700,
          ),
          const SizedBox(height: 10),
          const Text(
            'No medicines saved yet',
            style: TextStyle(
              color: authInk,
              fontWeight: FontWeight.w800,
              fontSize: 17,
            ),
          ),
        ],
      ),
    );
  }
}

class _MedicineInlineCard extends StatelessWidget {
  final Medicine medicine;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _MedicineInlineCard({
    required this.medicine,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.teal.shade50),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF8F6),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.medication_outlined, color: authPrimary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  medicine.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: authInk,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _Tag(label: medicine.category),
                    _Tag(label: medicine.form),
                    _Tag(label: medicine.ageGroup),
                  ],
                ),
                if (medicine.notes != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    medicine.notes!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.blueGrey.shade500,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            tooltip: 'Edit',
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined, color: authPrimary),
          ),
          IconButton(
            tooltip: 'Delete',
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
          ),
        ],
      ),
    );
  }
}
