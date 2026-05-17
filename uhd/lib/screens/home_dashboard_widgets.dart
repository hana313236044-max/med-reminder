// Home screen widgets for dates, navigation, filters, and reminders.
part of 'home_screen.dart';

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
        color: appSurfaceColor(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: appBorderColor(context)),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Previous day',
            onPressed: onPrevious,
            icon: Icon(Icons.chevron_left, color: appTextColor(context)),
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
                      style: TextStyle(
                        color: appTextColor(context),
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${selectedDate.year}/${selectedDate.month}/${selectedDate.day}',
                      style: TextStyle(
                        color: appMutedTextColor(context),
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
            icon: Icon(Icons.chevron_right, color: appTextColor(context)),
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
          color: appSurfaceColor(context),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: appBorderColor(context)),
          boxShadow: [
            BoxShadow(
              color: appShadowColor(context, 0.14),
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
              color: selected ? Colors.white : appMutedTextColor(context),
              size: 22,
            ),
            const SizedBox(height: 3),
            FittedBox(
              child: Text(
                data.label,
                style: TextStyle(
                  color: selected ? Colors.white : appMutedTextColor(context),
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
          style: TextStyle(
            color: appTextColor(context),
            fontSize: 28,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Your reminders for the selected day',
          style: TextStyle(
            color: appMutedTextColor(context),
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
          color: appSurfaceColor(context),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: appBorderColor(context)),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: appTintSurfaceColor(context),
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
                  style: TextStyle(
                    color: appTextColor(context),
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    color: appMutedTextColor(context),
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
              backgroundColor: appSurfaceColor(context).withOpacity(0.78),
              selectedColor: appSurfaceColor(context),
              side: BorderSide(
                color: isSelected ? authPrimary : appBorderColor(context),
              ),
              label: Text(
                '$label ${countFor(filter)}',
                style: TextStyle(
                  color: isSelected ? authPrimary : appTextColor(context),
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
