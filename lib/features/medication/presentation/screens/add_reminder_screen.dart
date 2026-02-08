import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../state/medication_controller.dart';
import '../../../../ui/app_theme_tokens.dart';
import '../../../../l10n/l10n.dart';
import '../../../../models/medication_reminder.dart';
import '../../../../services/notification_service.dart';
import '../../../../utils/permission_utils.dart';
import '../../../../utils/ui_feedback.dart';
import '../../data/medication_reminders_repository.dart';

class AddReminderScreen extends StatefulWidget {
  final int? preselectedMedicationId;
  final MedicationReminder? reminderToEdit;

  const AddReminderScreen({
    super.key,
    this.preselectedMedicationId,
    this.reminderToEdit,
  });

  @override
  State<AddReminderScreen> createState() => _AddReminderScreenState();
}

class _AddReminderScreenState extends State<AddReminderScreen> {
  final MedicationRemindersRepository _repo = MedicationRemindersRepository();
  int? selectedMedicationId;
  TimeOfDay selectedTime = const TimeOfDay(hour: 9, minute: 0);
  final TextEditingController noteCtrl = TextEditingController();
  List<bool> selectedDays = [true, true, true, true, true, true, true];
  bool isExactAlarm = false;

  String _weekdayShort(BuildContext context, int weekday) {
    final locale = Localizations.localeOf(context).toString();
    final baseMonday = DateTime(2024, 1, 1); // Monday
    final d = baseMonday.add(Duration(days: weekday - 1));
    return DateFormat.E(locale).format(d);
  }

  @override
  void initState() {
    super.initState();

    if (widget.reminderToEdit != null) {
      final reminder = widget.reminderToEdit!;
      selectedMedicationId = reminder.medicationId;
      selectedTime = TimeOfDay(hour: reminder.hour, minute: reminder.minute);
      noteCtrl.text = reminder.note ?? '';
      isExactAlarm = reminder.requiresExactAlarm;

      selectedDays = List.generate(
        7,
        (i) => reminder.daysOfWeek.contains(i + 1),
      );
    } else {
      selectedMedicationId = widget.preselectedMedicationId;
    }
  }

  @override
  void dispose() {
    noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveReminder() async {
    final l10n = context.l10n;
    if (selectedMedicationId == null) {
      UIFeedback.showWarning(context, l10n.addReminderSelectMedicationError);
      return;
    }

    final daysOfWeek = <int>[];
    for (var i = 0; i < 7; i++) {
      if (selectedDays[i]) {
        daysOfWeek.add(i + 1);
      }
    }

    if (daysOfWeek.isEmpty) {
      UIFeedback.showWarning(context, l10n.addReminderSelectAtLeastOneDayError);
      return;
    }

    final meds = context.read<MedicationController>().medications;
    final medication = meds.firstWhere((m) => m.id == selectedMedicationId);

    /// FLUJO PROGRESIVO DE PERMISOS
    // 1. Permiso de notificaciones (obligatorio)
    if (!await ensureNotificationPermission(context)) {
      return; // Usuario rechazó o está en ajustes
    }
    if (!mounted) return;

    // 2. Permiso de alarmas exactas (solo si marcó checkbox)
    if (isExactAlarm) {
      if (!await ensureExactAlarmPermission(context)) {
        return;
      }
      if (!mounted) return;
    }

    try {
      final reminder = MedicationReminder(
        id: widget.reminderToEdit?.id,
        medicationId: selectedMedicationId!,
        hour: selectedTime.hour,
        minute: selectedTime.minute,
        daysOfWeek: daysOfWeek,
        note: noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim(),
        requiresExactAlarm: isExactAlarm,
      );

      int reminderId;
      if (widget.reminderToEdit == null) {
        // Crear nuevo
        reminderId = await _repo.create(reminder);
      } else {
        // Actualizar existente
        await _repo.update(reminder);
        reminderId = reminder.id!;
        // Cancelar notificaciones antiguas
        await NotificationService.instance.cancelMedicationReminder(reminder);
      }

      // Programar notificaciones
      final reminderConId = reminder.copyWith(id: reminderId);

      await NotificationService.instance.scheduleMedicationReminder(
        reminderConId,
        medication,
      );

      // 3. Advertencia sobre restricciones de batería (solo si marcó exacto)
      if (isExactAlarm && mounted) {
        await checkBatteryRestrictions(context);
      }

      if (mounted) {
        UIFeedback.showSuccess(
          context,
          widget.reminderToEdit == null
              ? l10n.addReminderCreated(isExactAlarm ? '⏰' : '📌')
              : l10n.addReminderUpdated(isExactAlarm ? '⏰' : '📌'),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        UIFeedback.showError(context, l10n.commonErrorWithMessage('$e'));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final meds = context.watch<MedicationController>().medications;
    final colorSheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.reminderToEdit == null
              ? l10n.addReminderTitleNew
              : l10n.addReminderTitleEdit,
        ),
        backgroundColor: context.surfaces.accentSurface,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<int>(
              initialValue: selectedMedicationId,
              decoration: InputDecoration(
                labelText: l10n.addReminderMedicationLabel,
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.medication),
              ),
              items: meds.map((med) {
                return DropdownMenuItem<int>(
                  value: med.id,
                  child: Text('${med.name} (${med.unit})'),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedMedicationId = value;
                });
              },
            ),
            const SizedBox(height: 24),

            Card(
              child: ListTile(
                leading: Icon(Icons.access_time, color: colorSheme.tertiary),
                title: Text(l10n.addReminderTimeTitle),
                subtitle: Text(
                  selectedTime.format(context),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                trailing: const Icon(Icons.edit),
                onTap: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: selectedTime,
                  );
                  if (time != null) {
                    setState(() {
                      selectedTime = time;
                    });
                  }
                },
              ),
            ),
            const SizedBox(height: 24),

            Text(
              l10n.addReminderDaysOfWeekTitle,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: List.generate(7, (i) {
                return FilterChip(
                  label: Text(_weekdayShort(context, i + 1)),
                  selected: selectedDays[i],
                  onSelected: (val) {
                    setState(() {
                      selectedDays[i] = val;
                    });
                  },
                  selectedColor: Theme.of(
                    context,
                  ).colorScheme.tertiaryContainer,
                  checkmarkColor: context.neutralColors.white,
                );
              }),
            ),
            const SizedBox(height: 24),

            TextField(
              controller: noteCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: l10n.commonNoteOptionalLabel,
                hintText: l10n.addReminderNoteHint,
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.note),
              ),
            ),
            const SizedBox(height: 24),

            CheckboxListTile(
              title: Text(
                l10n.addReminderExactAlarmTitle,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              subtitle: Text(
                l10n.addReminderExactAlarmSubtitle,
                style: const TextStyle(fontSize: 12),
              ),
              value: isExactAlarm,
              onChanged: (value) {
                setState(() {
                  isExactAlarm = value ?? false;
                });
              },
              controlAffinity: ListTileControlAffinity.leading,
              activeColor: colorSheme.tertiary,
            ),

            // ADVERTENCIA sobre No Molestar
            if (isExactAlarm)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(top: 8),
                decoration: BoxDecoration(
                  color: colorSheme.tertiary.withValues(alpha: 0.1),
                  border: Border.all(
                    color: colorSheme.tertiary.withValues(alpha: 0.3),
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: colorSheme.tertiary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n.addReminderDndWarning,
                        style: TextStyle(
                          fontSize: 12,
                          color: colorSheme.tertiary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.alarm_add, size: 28),
                label: Text(
                  widget.reminderToEdit == null
                      ? l10n.addReminderSaveButton
                      : l10n.addReminderUpdateButton,
                  style: const TextStyle(fontSize: 18),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.surfaces.accentSurface,
                  foregroundColor: context.neutralColors.black87,
                ),
                onPressed: _saveReminder,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
