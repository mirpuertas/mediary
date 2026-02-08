import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../l10n/l10n.dart';
import '../../../../models/medication.dart';
import '../../../../models/medication_reminder.dart';
import '../../../../services/notification_service.dart';
import '../../data/medication_reminders_repository.dart';
import '../../../../ui/app_theme_tokens.dart';
import '../../../../utils/ui_feedback.dart';
import 'add_reminder_screen.dart';

class MedicationDetailScreen extends StatefulWidget {
  final Medication medication;

  const MedicationDetailScreen({super.key, required this.medication});

  @override
  State<MedicationDetailScreen> createState() => _MedicationDetailScreenState();
}

class _MedicationDetailScreenState extends State<MedicationDetailScreen> {
  final MedicationRemindersRepository _repo = MedicationRemindersRepository();
  List<MedicationReminder> _reminders = [];
  bool _isLoading = true;

  String _weekdayShort(BuildContext context, int weekday) {
    final locale = Localizations.localeOf(context).toString();
    final baseMonday = DateTime(2024, 1, 1); // Monday
    final d = baseMonday.add(Duration(days: weekday - 1));
    return DateFormat.E(locale).format(d);
  }

  @override
  void initState() {
    super.initState();
    _loadReminders();
  }

  Future<void> _loadReminders() async {
    setState(() => _isLoading = true);
    try {
      final reminders = await _repo.listByMedication(widget.medication.id!);
      setState(() {
        _reminders = reminders;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        UIFeedback.showError(
          context,
          context.l10n.medicationDetailLoadError('$e'),
        );
      }
    }
  }

  Future<void> _deleteReminder(MedicationReminder reminder) async {
    final l10n = context.l10n;
    final timeStr =
        '${reminder.hour.toString().padLeft(2, '0')}:${reminder.minute.toString().padLeft(2, '0')}';
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.medicationDetailDeleteReminderTitle),
        content: Text(l10n.medicationDetailDeleteReminderBody(timeStr)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              l10n.commonDelete,
              style: TextStyle(color: context.statusColors.danger),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _repo.delete(reminder.id!);
      await NotificationService.instance.cancelMedicationReminder(reminder);

      if (mounted) {
        UIFeedback.showSuccess(context, l10n.medicationDetailReminderDeleted);
      }

      await _loadReminders();
    } catch (e) {
      if (mounted) {
        UIFeedback.showError(context, l10n.medicationDetailDeleteError('$e'));
      }
    }
  }

  String _formatDays(BuildContext context, MedicationReminder reminder) {
    final l10n = context.l10n;
    if (reminder.isDaily) {
      return l10n.commonEveryDay;
    }

    final selectedDays = reminder.daysOfWeek
        .map((d) => _weekdayShort(context, d))
        .join(', ');
    return l10n.medicationDetailDaysLabel(selectedDays);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.medication.name),
        backgroundColor: context.surfaces.accentSurface,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Info del medicamento
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Theme.of(
                    context,
                  ).colorScheme.tertiary.withValues(alpha: 0),
                  child: Row(
                    children: [
                      Icon(
                        Icons.medication,
                        size: 48,
                        color: Theme.of(context).colorScheme.tertiary,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.medication.name,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.medication.unit,
                              style: TextStyle(
                                fontSize: 14,
                                color: context.neutralColors.grey600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const Divider(),

                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.alarm, color: colorScheme.tertiary),
                      const SizedBox(width: 8),
                      Text(
                        l10n.medicationDetailSchedulesTitle,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        l10n.medicationDetailSchedulesCount(_reminders.length),
                        style: TextStyle(
                          fontSize: 14,
                          color: context.neutralColors.grey600,
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: _reminders.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.alarm_off,
                                size: 64,
                                color: context.neutralColors.grey400,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                l10n.medicationDetailNoRemindersTitle,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: context.neutralColors.grey600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                l10n.medicationDetailNoRemindersSubtitle,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: context.neutralColors.grey500,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: _reminders.length,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemBuilder: (context, index) {
                            final reminder = _reminders[index];
                            final timeStr =
                                '${reminder.hour.toString().padLeft(2, '0')}:${reminder.minute.toString().padLeft(2, '0')}';

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: reminder.requiresExactAlarm
                                      ? Theme.of(context).colorScheme.tertiary
                                      : Theme.of(context).colorScheme.primary,
                                  child: Icon(
                                    reminder.requiresExactAlarm
                                        ? Icons.alarm
                                        : Icons.notifications,
                                    color: context.neutralColors.white,
                                  ),
                                ),
                                title: Text(
                                  timeStr,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(_formatDays(context, reminder)),
                                    if (reminder.requiresExactAlarm)
                                      Text(
                                        l10n.commonExactAlarm,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: colorScheme.tertiary,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    if (reminder.note != null &&
                                        reminder.note!.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Text(
                                          reminder.note!,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontStyle: FontStyle.italic,
                                            color:
                                                context.neutralColors.grey600,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: Icon(
                                        Icons.edit,
                                        color: context.statusColors.info,
                                      ),
                                      onPressed: () async {
                                        final updated =
                                            await Navigator.push<bool>(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    AddReminderScreen(
                                                      preselectedMedicationId:
                                                          widget.medication.id,
                                                      reminderToEdit: reminder,
                                                    ),
                                              ),
                                            );
                                        if (updated == true) {
                                          await _loadReminders();
                                        }
                                      },
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        Icons.delete,
                                        color: colorScheme.error,
                                      ),
                                      onPressed: () =>
                                          _deleteReminder(reminder),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (_) => AddReminderScreen(
                preselectedMedicationId: widget.medication.id,
              ),
            ),
          );
          if (created == true) {
            await _loadReminders();
          }
        },
        icon: const Icon(Icons.add),
        label: Text(l10n.medicationDetailAddSchedule),
        backgroundColor: Theme.of(context).colorScheme.tertiary,
        foregroundColor: context.neutralColors.black87,
      ),
    );
  }
}
