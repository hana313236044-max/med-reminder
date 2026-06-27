// This screen shows the main medicine reminder dashboard.
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:uhd/screens/add_medicine_screen.dart';
import 'package:uhd/screens/add_reminder_screen.dart';
import 'package:uhd/screens/medical_profile_page.dart';
import 'package:uhd/screens/settings_screen.dart';
import 'package:uhd/screens/statistics_page.dart';
import 'package:uhd/services/statistics_service.dart';
import 'package:uhd/widgets/app_widgets.dart';
import 'package:uhd/models/medicine_models.dart';
import 'package:uhd/models/statistics_model.dart';

part 'home_dashboard_widgets.dart';
part 'reminder_widgets.dart';
part 'medicine_tab.dart';
part 'profile_tab.dart';

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
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
      _medicinesSubscription;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
      _remindersSubscription;
  ReminderFilter _filter = ReminderFilter.all;
  DateTime _selectedDate = DateTime.now();
  int _selectedTab = 0;
  bool _isLoadingData = true;

  String? get _userId => FirebaseAuth.instance.currentUser?.uid;

  CollectionReference<Map<String, dynamic>>? get _medicinesRef {
    final uid = _userId;
    if (uid == null) return null;
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('medicines');
  }

  CollectionReference<Map<String, dynamic>>? get _remindersRef {
    final uid = _userId;
    if (uid == null) return null;
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('reminders');
  }

  CollectionReference<Map<String, dynamic>>? get _intakeLogsRef {
    final uid = _userId;
    if (uid == null) return null;
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('intakeLogs');
  }

  @override
  void initState() {
    super.initState();
    _listenToUserData();
  }

  void _listenToUserData() {
    final medicinesRef = _medicinesRef;
    final remindersRef = _remindersRef;
    if (medicinesRef == null || remindersRef == null) {
      setState(() => _isLoadingData = false);
      return;
    }

    _medicinesSubscription = medicinesRef
        .orderBy('name')
        .snapshots()
        .listen((snapshot) {
          if (!mounted) return;
          setState(() {
            _medicines
              ..clear()
              ..addAll(snapshot.docs.map(Medicine.fromFirestore));
            _isLoadingData = false;
          });
        });

    _remindersSubscription = remindersRef
        .orderBy('scheduledAt')
        .snapshots()
        .listen((snapshot) {
          if (!mounted) return;
          setState(() {
            _reminders
              ..clear()
              ..addAll(snapshot.docs.map(MedicationReminder.fromFirestore));
            _isLoadingData = false;
          });
        });
  }

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

  Future<void> _saveMedicine(Medicine medicine) async {
    final medicinesRef = _medicinesRef;
    final remindersRef = _remindersRef;
    if (medicinesRef == null || remindersRef == null) return;

    final batch = FirebaseFirestore.instance.batch();
    batch.set(
      medicinesRef.doc(medicine.id.toString()),
      {
        ...medicine.toFirestore(),
        'createdAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    for (final reminder in _reminders) {
      if (reminder.medicineId == medicine.id) {
        batch.set(
          remindersRef.doc(reminder.id.toString()),
          {
            'medicineName': medicine.name,
            'medicineCategory': medicine.category,
            'medicineForm': medicine.form,
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      }
    }

    await batch.commit();
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

    final medicinesRef = _medicinesRef;
    final remindersRef = _remindersRef;
    final intakeLogsRef = _intakeLogsRef;
    if (medicinesRef == null || remindersRef == null) return;

    final numericLogSnapshot = intakeLogsRef == null
        ? null
        : await intakeLogsRef.where('medicineId', isEqualTo: medicineId).get();
    final stringLogSnapshot = intakeLogsRef == null
        ? null
        : await intakeLogsRef
              .where('medicineId', isEqualTo: medicineId.toString())
              .get();

    final batch = FirebaseFirestore.instance.batch();
    batch.delete(medicinesRef.doc(medicineId.toString()));
    for (final reminder in _reminders) {
      if (reminder.medicineId == medicineId) {
        batch.delete(remindersRef.doc(reminder.id.toString()));
      }
    }
    final deletedLogIds = <String>{};
    for (final doc in numericLogSnapshot?.docs ?? const []) {
      deletedLogIds.add(doc.id);
      batch.delete(doc.reference);
    }
    for (final doc in stringLogSnapshot?.docs ?? const []) {
      if (deletedLogIds.add(doc.id)) {
        batch.delete(doc.reference);
      }
    }
    await batch.commit();
  }

  Future<void> _saveReminders(List<MedicationReminder> reminders) async {
    final remindersRef = _remindersRef;
    final intakeLogsRef = _intakeLogsRef;
    final uid = _userId;
    if (remindersRef == null || intakeLogsRef == null || uid == null) return;

    final batch = FirebaseFirestore.instance.batch();
    for (final reminder in reminders) {
      batch.set(
        remindersRef.doc(reminder.id.toString()),
        {
          ...reminder.toFirestore(),
          'createdAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      batch.set(
        intakeLogsRef.doc(_intakeLogId(reminder, reminder.scheduledAt)),
        {
          ..._intakeLogData(
            uid: uid,
            reminder: reminder,
            scheduledAt: reminder.scheduledAt,
            status: IntakeLogStatus.waiting,
          ),
          'createdAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    }
    await batch.commit();

    if (reminders.isNotEmpty && mounted) {
      setState(() => _selectedDate = reminders.first.scheduledAt);
    }
  }

  Future<void> _markTook(MedicationReminder reminder) async {
    final confirmed = await _confirmAction(
      title: 'Mark as took?',
      message: 'Do you want to mark this reminder as taken?',
      confirmLabel: 'Yes, Took',
      confirmColor: authPrimary,
    );
    if (!confirmed) return;

    final remindersRef = _remindersRef;
    final intakeLogsRef = _intakeLogsRef;
    final uid = _userId;
    if (remindersRef == null || intakeLogsRef == null || uid == null) return;

    final actionAt = DateTime.now();
    final delayMinutes = actionAt.difference(reminder.scheduledAt).inMinutes;
    final status = delayMinutes > StatisticsService.onTimeGraceMinutes
        ? IntakeLogStatus.delayed
        : IntakeLogStatus.taken;

    final batch = FirebaseFirestore.instance.batch();
    batch.set(remindersRef.doc(reminder.id.toString()), {
      'status': ReminderStatus.completed.name,
      'actionDateTime': Timestamp.fromDate(actionAt),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    batch.set(
      intakeLogsRef.doc(_intakeLogId(reminder, reminder.scheduledAt)),
      _intakeLogData(
        uid: uid,
        reminder: reminder,
        scheduledAt: reminder.scheduledAt,
        status: status,
        actionAt: actionAt,
        delayMinutes: delayMinutes < 0 ? 0 : delayMinutes,
      ),
      SetOptions(merge: true),
    );
    await batch.commit();
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

    final remindersRef = _remindersRef;
    final intakeLogsRef = _intakeLogsRef;
    final uid = _userId;
    if (remindersRef == null || intakeLogsRef == null || uid == null) return;

    final actionAt = DateTime.now();
    final batch = FirebaseFirestore.instance.batch();
    batch.set(
      intakeLogsRef.doc(_intakeLogId(reminder, reminder.scheduledAt)),
      _intakeLogData(
        uid: uid,
        reminder: reminder,
        scheduledAt: reminder.scheduledAt,
        status: IntakeLogStatus.rescheduled,
        actionAt: actionAt,
      ),
      SetOptions(merge: true),
    );
    batch.set(
      intakeLogsRef.doc(_intakeLogId(reminder, updatedAt)),
      _intakeLogData(
        uid: uid,
        reminder: reminder,
        scheduledAt: updatedAt,
        status: IntakeLogStatus.waiting,
      ),
      SetOptions(merge: true),
    );
    batch.set(remindersRef.doc(reminder.id.toString()), {
      'scheduledAt': Timestamp.fromDate(updatedAt),
      'status': ReminderStatus.waiting.name,
      'isRescheduled': true,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await batch.commit();
  }

  Future<void> _deleteReminder(MedicationReminder reminder) async {
    final confirmed = await _confirmAction(
      title: 'Delete reminder?',
      message: 'Do you want to delete this reminder?',
      confirmLabel: 'Delete',
      confirmColor: Colors.redAccent,
    );
    if (!confirmed) return;

    final remindersRef = _remindersRef;
    if (remindersRef == null) return;
    final intakeLogsRef = _intakeLogsRef;
    final logSnapshot = intakeLogsRef == null
        ? null
        : await intakeLogsRef
            .where('reminderId', isEqualTo: reminder.id.toString())
            .get();

    final batch = FirebaseFirestore.instance.batch();
    batch.delete(remindersRef.doc(reminder.id.toString()));
    for (final doc in logSnapshot?.docs ?? const []) {
      batch.delete(doc.reference);
    }
    await batch.commit();
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
  void dispose() {
    _medicinesSubscription?.cancel();
    _remindersSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appScaffoldColor(context),
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
      body: _isLoadingData ? const _LoadingDataState() : _bodyForTab(),
    );
  }

  String _titleForTab() {
    switch (_selectedTab) {
      case 1:
        return 'Medicine';
      case 2:
        return 'Statistics / Insights';
      case 3:
        return 'Settings';
      case 4:
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
        return StatisticsPage(onMedicineSelected: _openMedicineFromStats);
      case 3:
        return const AppSettings(showScaffold: false);
      case 4:
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

  void _openMedicineFromStats(String medicineId) {
    for (final medicine in _medicines) {
      if (medicine.id.toString() == medicineId) {
        _openEditMedicineFromTab(medicine);
        return;
      }
    }
    setState(() => _selectedTab = 1);
  }

  String _intakeLogId(MedicationReminder reminder, DateTime scheduledAt) {
    return StatisticsService.intakeLogIdFor(
      reminder.id.toString(),
      scheduledAt,
    );
  }

  Map<String, dynamic> _intakeLogData({
    required String uid,
    required MedicationReminder reminder,
    required DateTime scheduledAt,
    required IntakeLogStatus status,
    DateTime? actionAt,
    int? delayMinutes,
  }) {
    return StatisticsService.intakeLogData(
      userId: uid,
      medicineId: reminder.medicineId,
      reminderId: reminder.id.toString(),
      medicineName: reminder.medicineName,
      scheduledDateTime: scheduledAt,
      status: status,
      scheduleLabel: reminder.scheduleLabel,
      actionDateTime: actionAt,
      delayMinutes: delayMinutes,
    );
  }
}
