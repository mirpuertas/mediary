import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../l10n/l10n.dart';
import '../../../../models/medication.dart';
import '../../../../models/medication_reminder.dart';
import '../../../../ui/app_theme_tokens.dart';
import '../../../../ui/theme_helpers.dart';
import '../../state/home_reminders_controller.dart';

class TodayRemindersCardSection extends StatefulWidget {
  const TodayRemindersCardSection({super.key});

  @override
  State<TodayRemindersCardSection> createState() =>
      _TodayRemindersCardSectionState();
}

class _TodayRemindersCardSectionState extends State<TodayRemindersCardSection> {
  bool _showAll = false;

  @override
  Widget build(BuildContext context) {
    final r = context.watch<HomeRemindersController>();
    if (r.error != null) return const SizedBox.shrink();

    final data = r.data;
    if (data == null) {
      if (kDebugMode) {
        debugPrint('⚠️ TodayRemindersCardSection: data is null');
      }
      return const SizedBox.shrink();
    }

    final reminders = data.reminders;
    final groupReminders = data.groupReminders;
    final snoozes = data.snoozes;

    if (kDebugMode) {
      debugPrint(
        '🔎 TodayRemindersCardSection: reminders=${reminders.length}, groups=${groupReminders.length}, snoozes=${snoozes.length}',
      );
    }

    if (reminders.isEmpty && groupReminders.isEmpty && snoozes.isEmpty) {
      return const SizedBox.shrink();
    }

    final cs = Theme.of(context).colorScheme;
    final m1 = muted(context, 0.60);
    final m2 = muted(context, 0.45);

    final now = DateTime.now();
    final all = <({int hour, int minute, String label})>[];

    for (final item in reminders) {
      final reminder = item['reminder'] as MedicationReminder;
      final medication = item['medication'] as Medication;
      all.add((
        hour: reminder.hour,
        minute: reminder.minute,
        label: medication.name,
      ));
    }

    for (final item in groupReminders) {
      final reminder = item['reminder'] as dynamic;
      final group = item['group'] as dynamic;
      final meds = (item['medications'] as List?) ?? const [];

      final hour = (reminder.hour as int);
      final minute = (reminder.minute as int);
      final name = (group.name as String);
      final count = meds.length;
      all.add((hour: hour, minute: minute, label: '$name ($count)'));
    }

    all.sort((a, b) {
      final ta = a.hour * 60 + a.minute;
      final tb = b.hour * 60 + b.minute;
      return ta.compareTo(tb);
    });

    final items = _showAll ? all : all.take(3).toList(growable: false);

    return Card(
      margin: const EdgeInsets.all(12),
      color: context.surfaces.accentSurface,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.alarm, color: cs.tertiary),
                const SizedBox(width: 8),
                Text(
                  context.l10n.homeRemindersTodayTitle,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...items.map((item) {
              final reminderTime = DateTime(
                now.year,
                now.month,
                now.day,
                item.hour,
                item.minute,
              );
              final isPast = reminderTime.isBefore(now);

              return Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  children: [
                    Icon(
                      isPast
                          ? Icons.check_circle_outline
                          : Icons.notifications_active,
                      size: 16,
                      color: isPast ? m2 : cs.tertiary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${item.hour.toString().padLeft(2, '0')}:${item.minute.toString().padLeft(2, '0')}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isPast ? m1 : null,
                        decoration: isPast ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item.label,
                        style: TextStyle(color: isPast ? m1 : null),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            }),
            if (snoozes.isNotEmpty) ...[
              const SizedBox(height: 12),
              Divider(height: 1, color: dividerColor(context)),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(
                    Icons.alarm_add,
                    size: 18,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    context.l10n.homeRemindersSnoozedHeader,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ...snoozes.map((item) {
                final scheduledAt = item['scheduledAt'] as DateTime;
                final medication = item['medication'] as Medication?;
                final medicationId = item['medicationId'] as int;
                final groupName = item['groupName'] as String?;
                final isPast = scheduledAt.isBefore(now);
                final localeName = Localizations.localeOf(context).toString();
                final timeText = DateFormat(
                  'HH:mm',
                  localeName,
                ).format(scheduledAt);
                final medName =
                    medication?.name ??
                    context.l10n.selectedDayMedicationFallbackName(
                      medicationId,
                    );
                final label = (groupName != null && groupName.trim().isNotEmpty)
                    ? '${groupName.trim()} — $medName'
                    : medName;

                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    children: [
                      Icon(
                        isPast ? Icons.check_circle_outline : Icons.snooze,
                        size: 16,
                        color: isPast ? m2 : cs.secondary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        timeText,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isPast ? m1 : null,
                          decoration: isPast
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          label,
                          style: TextStyle(color: isPast ? m1 : null),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
            if (all.length > 3)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: GestureDetector(
                  onTap: () => setState(() => _showAll = !_showAll),
                  child: Text(
                    _showAll ? 'Ver menos' : 'Mostrar todos (${all.length})',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w500,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
