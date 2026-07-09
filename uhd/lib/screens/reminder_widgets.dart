// Reminder cards and empty/loading states for the home screen.
part of 'home_screen.dart';

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

  Color _statusBackground(BuildContext context) {
    final isDark = appIsDark(context);
    if (isDark) {
      if (reminder.isCompleted) return const Color(0xFF123C3B);
      if (reminder.isNotTaken) return const Color(0xFF3B2025);
      if (reminder.isDelayed) return const Color(0xFF3B2025);
      return const Color(0xFF3A311E);
    }
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
    final statusBackground = _statusBackground(context);
    final isDark = appIsDark(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? statusBackground : statusBackground.withOpacity(0.48),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark
              ? appBorderColor(context)
              : statusColor.withOpacity(0.32),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.24)
                : statusColor.withOpacity(0.10),
            blurRadius: isDark ? 14 : 18,
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
                  color: appSurfaceColor(context),
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
                  style: TextStyle(
                    color: appTextColor(context),
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
                _Tag(
                  label: 'Rescheduled',
                  color: isDark
                      ? const Color(0xFF1C335A)
                      : const Color(0xFFE8F0FF),
                  textColor: isDark
                      ? const Color(0xFF9DBBFF)
                      : const Color(0xFF3157B7),
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
                style: TextStyle(
                  color: appTextColor(context),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${reminder.quantity} ${reminder.quantityUnit}',
            style: TextStyle(
              color: appMutedTextColor(context),
              fontWeight: FontWeight.w700,
            ),
          ),
          if (reminder.notes != null) ...[
            const SizedBox(height: 6),
            Text(
              reminder.notes!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: appMutedTextColor(context)),
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
                    disabledBackgroundColor:
                        isDark ? appDarkSurfaceAlt : Colors.grey.shade200,
                    disabledForegroundColor:
                        isDark ? appDarkMuted : Colors.grey.shade500,
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
                    disabledForegroundColor:
                        isDark ? appDarkMuted : Colors.grey.shade500,
                    side: BorderSide(
                      color: isDark ? appDarkBorder : Colors.teal.shade100,
                    ),
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
        color: color ?? appTintSurfaceColor(context),
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
  final bool hasInventory;
  final VoidCallback onOpenInventory;
  final VoidCallback onAddReminder;
  final String? title;
  final String? message;

  const _EmptyReminderState({
    required this.hasInventory,
    required this.onOpenInventory,
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
          color: appSurfaceColor(context).withOpacity(0.96),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: appBorderColor(context)),
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
              style: TextStyle(
                color: appTextColor(context),
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message ??
                  (hasInventory
                      ? 'Create a reminder from one of your inventory medicines.'
                      : 'Track medicines in inventory first, then create reminders from them.'),
              textAlign: TextAlign.center,
              style: TextStyle(color: appMutedTextColor(context)),
            ),
            const SizedBox(height: 18),
            AuthPrimaryButton(
              label: hasInventory ? 'Add Reminder' : 'Open Inventory',
              icon: hasInventory ? Icons.add : Icons.inventory_2_outlined,
              onPressed: hasInventory ? onAddReminder : onOpenInventory,
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingDataState extends StatelessWidget {
  const _LoadingDataState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(color: authPrimary),
    );
  }
}
