import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../models/medication.dart';
import '../../../../models/medication_group.dart';
import '../../../../models/medication_group_reminder.dart';
import '../../../../services/notification_service.dart';
import '../../../../utils/permission_utils.dart';
import '../../../../l10n/l10n.dart';
import '../../data/medication_groups_repository.dart';
import '../../../../ui/app_theme_tokens.dart';
import '../../data/medication_repository.dart';

class MedicationGroupDetailScreen extends StatefulWidget {
  final int groupId;

  const MedicationGroupDetailScreen({super.key, required this.groupId});

  @override
  State<MedicationGroupDetailScreen> createState() =>
      _MedicationGroupDetailScreenState();
}

class _MedicationGroupDetailScreenState
    extends State<MedicationGroupDetailScreen> {
  final MedicationGroupsRepository _groupsRepo = MedicationGroupsRepository();
  final MedicationRepository _medRepo = MedicationRepository();

  String _weekdayShort(BuildContext context, int weekday) {
    final locale = Localizations.localeOf(context).toString();
    final baseMonday = DateTime(2024, 1, 1); // Monday
    final d = baseMonday.add(Duration(days: weekday - 1));
    return DateFormat.E(locale).format(d);
  }

  String _formatDays(BuildContext context, List<int> daysOfWeek) {
    final l10n = context.l10n;
    if (daysOfWeek.length == 7) return l10n.commonEveryDay;
    return daysOfWeek.map((d) => _weekdayShort(context, d)).join(' ');
  }

  Future<
    ({
      MedicationGroup group,
      List<Medication> members,
      List<Medication> allActiveMeds,
      List<MedicationGroupReminder> reminders,
    })
  >
  _load() async {
    final l10n = context.l10n;
    final group = await _groupsRepo.getGroup(widget.groupId);
    if (group == null) {
      throw Exception(l10n.medicationGroupDetailGroupNotFound);
    }

    final members = await _groupsRepo.getGroupMembers(widget.groupId);
    final allMeds = await _medRepo.getAllMedications();
    final allActiveMeds = allMeds.where((m) => !m.isArchived).toList();
    allActiveMeds.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );

    final reminders = await _groupsRepo.listGroupReminders(widget.groupId);
    reminders.sort((a, b) {
      final ta = a.hour * 60 + a.minute;
      final tb = b.hour * 60 + b.minute;
      return ta.compareTo(tb);
    });

    return (
      group: group,
      members: members.where((m) => !m.isArchived).toList(),
      allActiveMeds: allActiveMeds,
      reminders: reminders,
    );
  }

  Future<void> _rescheduleAllReminders(MedicationGroup group) async {
    final reminders = await _groupsRepo.listGroupReminders(group.id!);
    final meds = await _groupsRepo.getGroupMembers(group.id!);
    final activeMeds = meds.where((m) => !m.isArchived).toList();

    for (final r in reminders) {
      if (r.id != null) {
        await NotificationService.instance.cancelMedicationGroupReminder(r);
      }
    }

    if (group.isArchived) return;
    if (activeMeds.isEmpty) return;

    for (final r in reminders) {
      if (r.id == null) continue;
      await NotificationService.instance.scheduleMedicationGroupReminder(
        reminder: r,
        group: group,
        medicationsSnapshot: activeMeds,
      );
    }
  }

  Future<void> _editMembers(
    MedicationGroup group,
    List<Medication> allActiveMeds,
  ) async {
    final existingIds = (await _groupsRepo.getGroupMemberIds(
      group.id!,
    )).toSet();

    if (!mounted) return;
    final selected = <int, bool>{
      for (final m in allActiveMeds) m.id!: existingIds.contains(m.id),
    };

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) {
        final l10n = context.l10n;
        return StatefulBuilder(
          builder: (context, setLocalState) {
            return AlertDialog(
              title: Text(l10n.medicationGroupDetailMembersDialogTitle),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: allActiveMeds.length,
                  itemBuilder: (context, index) {
                    final med = allActiveMeds[index];
                    final v = selected[med.id!] ?? false;
                    return CheckboxListTile(
                      value: v,
                      title: Text(med.name),
                      subtitle: Text(med.unit),
                      onChanged: (nv) {
                        setLocalState(() {
                          selected[med.id!] = nv ?? false;
                        });
                      },
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(l10n.commonCancel),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(l10n.commonSave),
                ),
              ],
            );
          },
        );
      },
    );

    if (saved != true) return;

    final memberIds = selected.entries
        .where((e) => e.value)
        .map((e) => e.key)
        .toList(growable: false);

    await _groupsRepo.setGroupMembers(
      groupId: group.id!,
      medicationIds: memberIds,
    );
    await _rescheduleAllReminders(group);

    if (!mounted) return;
    setState(() {});
  }

  Future<MedicationGroupReminder?> _showReminderDialog(
    MedicationGroup group, {
    MedicationGroupReminder? reminderToEdit,
  }) async {
    final initialTime = reminderToEdit == null
        ? TimeOfDay.now()
        : TimeOfDay(hour: reminderToEdit.hour, minute: reminderToEdit.minute);
    var time = initialTime;

    final initialDays = reminderToEdit == null
        ? <int>{1, 2, 3, 4, 5, 6, 7}
        : reminderToEdit.daysOfWeek.toSet();
    final selectedDays = <int>{...initialDays};

    var isExactAlarm = reminderToEdit?.requiresExactAlarm ?? false;
    final noteCtrl = TextEditingController(text: reminderToEdit?.note ?? '');

    final colorScheme = Theme.of(context).colorScheme;

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) {
        final l10n = context.l10n;
        return StatefulBuilder(
          builder: (context, setLocalState) {
            return AlertDialog(
              title: Text(
                reminderToEdit == null
                    ? l10n.medicationGroupDetailNewReminderTitle
                    : l10n.medicationGroupDetailEditReminderTitle,
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.schedule),
                      title: Text(
                        l10n.medicationGroupDetailTimeLabel(
                          time.format(context),
                        ),
                      ),
                      trailing: const Icon(Icons.edit),
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: time,
                        );
                        if (picked == null) return;
                        setLocalState(() => time = picked);
                      },
                    ),
                    const SizedBox(height: 8),
                    Text(l10n.commonDaysLabel),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      children: [
                        for (final d in const [1, 2, 3, 4, 5, 6, 7])
                          FilterChip(
                            label: Text(_weekdayShort(context, d)),
                            selected: selectedDays.contains(d),
                            onSelected: (v) {
                              setLocalState(() {
                                if (v) {
                                  selectedDays.add(d);
                                } else {
                                  selectedDays.remove(d);
                                }
                              });
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: noteCtrl,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: l10n.commonNoteOptionalLabel,
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.note),
                      ),
                    ),
                    const SizedBox(height: 12),
                    CheckboxListTile(
                      title: Text(
                        l10n.medicationGroupDetailExactAlarmTitle,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      subtitle: Text(
                        l10n.medicationGroupDetailExactAlarmSubtitle,
                        style: const TextStyle(fontSize: 12),
                      ),
                      value: isExactAlarm,
                      onChanged: (value) {
                        setLocalState(() {
                          isExactAlarm = value ?? false;
                        });
                      },
                      controlAffinity: ListTileControlAffinity.leading,
                      activeColor: Theme.of(context).colorScheme.tertiary,
                      contentPadding: EdgeInsets.zero,
                    ),
                    if (isExactAlarm)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(top: 8),
                        decoration: BoxDecoration(
                          color: colorScheme.tertiary.withValues(alpha: 0.1),
                          border: Border.all(
                            color: colorScheme.tertiary.withValues(alpha: 0.3),
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: colorScheme.tertiary,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                l10n.medicationGroupDetailDndWarning,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: colorScheme.tertiary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(l10n.commonCancel),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(
                    reminderToEdit == null
                        ? l10n.commonCreate
                        : l10n.commonSave,
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    if (saved != true) return null;
    if (selectedDays.isEmpty) return null;

    return MedicationGroupReminder(
      id: reminderToEdit?.id,
      groupId: group.id!,
      hour: time.hour,
      minute: time.minute,
      daysOfWeek: selectedDays.toList()..sort(),
      note: noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim(),
      requiresExactAlarm: isExactAlarm,
    );
  }

  Future<void> _addReminder(MedicationGroup group) async {
    final reminder = await _showReminderDialog(group);
    if (reminder == null) return;

    if (!mounted) return;

    // 1) Notificaciones (obligatorio)
    if (!await ensureNotificationPermission(context)) {
      return;
    }
    if (!mounted) return;

    // 2) Alarmas exactas (solo si marcó)
    if (reminder.requiresExactAlarm) {
      if (!await ensureExactAlarmPermission(context)) {
        return;
      }
      if (!mounted) return;
    }

    final id = await _groupsRepo.createGroupReminder(reminder);
    final savedReminder = reminder.copyWith(id: id);

    final meds = await _groupsRepo.getGroupMembers(group.id!);
    final activeMeds = meds.where((m) => !m.isArchived).toList();

    if (!group.isArchived && activeMeds.isNotEmpty) {
      await NotificationService.instance.scheduleMedicationGroupReminder(
        reminder: savedReminder,
        group: group,
        medicationsSnapshot: activeMeds,
      );
    }

    // 3) Restricciones batería (solo si exacta)
    if (savedReminder.requiresExactAlarm && mounted) {
      await checkBatteryRestrictions(context);
    }

    if (!mounted) return;
    setState(() {});
  }

  Future<void> _editReminder(
    MedicationGroup group,
    MedicationGroupReminder reminderToEdit,
  ) async {
    final updated = await _showReminderDialog(
      group,
      reminderToEdit: reminderToEdit,
    );
    if (updated == null) return;

    if (!mounted) return;

    // 1) Notificaciones (obligatorio)
    if (!await ensureNotificationPermission(context)) {
      return;
    }
    if (!mounted) return;

    // 2) Alarmas exactas (solo si marcó)
    if (updated.requiresExactAlarm) {
      if (!await ensureExactAlarmPermission(context)) {
        return;
      }
      if (!mounted) return;
    }

    // Cancelar notificaciones antiguas
    await NotificationService.instance.cancelMedicationGroupReminder(
      reminderToEdit,
    );

    await _groupsRepo.updateGroupReminder(updated);

    final meds = await _groupsRepo.getGroupMembers(group.id!);
    final activeMeds = meds.where((m) => !m.isArchived).toList();

    if (!group.isArchived && activeMeds.isNotEmpty && updated.id != null) {
      await NotificationService.instance.scheduleMedicationGroupReminder(
        reminder: updated,
        group: group,
        medicationsSnapshot: activeMeds,
      );
    }

    if (updated.requiresExactAlarm && mounted) {
      await checkBatteryRestrictions(context);
    }

    if (!mounted) return;
    setState(() {});
  }

  Future<void> _deleteReminder(MedicationGroupReminder reminder) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) {
        final l10n = context.l10n;
        return AlertDialog(
          title: Text(l10n.medicationGroupDetailDeleteReminderTitle),
          content: Text(l10n.commonAreYouSure),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.commonCancel),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: context.statusColors.danger,
                foregroundColor: context.statusColors.onDanger,
              ),
              child: Text(l10n.commonDelete),
            ),
          ],
        );
      },
    );

    if (ok != true) return;

    await NotificationService.instance.cancelMedicationGroupReminder(reminder);
    if (reminder.id != null) {
      await _groupsRepo.deleteGroupReminder(reminder.id!);
    }

    if (!mounted) return;
    setState(() {});
  }

  Future<void> _toggleArchive(MedicationGroup group) async {
    if (group.isArchived) {
      await _groupsRepo.unarchiveGroup(group.id!);
    } else {
      await _groupsRepo.archiveGroup(group.id!);
    }

    final updated = (await _groupsRepo.getGroup(group.id!))!;
    await _rescheduleAllReminders(updated);

    if (!mounted) return;
    setState(() {});
  }

  Future<void> _deleteGroup(MedicationGroup group) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) {
        final l10n = context.l10n;
        return AlertDialog(
          title: Text(l10n.medicationGroupDetailDeleteGroupTitle),
          content: Text(l10n.medicationGroupDetailDeleteGroupBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.commonCancel),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: context.statusColors.danger,
                foregroundColor: context.statusColors.onDanger,
              ),
              child: Text(l10n.commonDelete),
            ),
          ],
        );
      },
    );

    if (ok != true) return;

    final reminders = await _groupsRepo.listGroupReminders(group.id!);
    for (final r in reminders) {
      await NotificationService.instance.cancelMedicationGroupReminder(r);
      if (r.id != null) {
        await _groupsRepo.deleteGroupReminder(r.id!);
      }
    }

    await _groupsRepo.deleteGroup(group.id!);

    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return FutureBuilder(
      future: _load(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: Text(l10n.commonGroup)),
            body: Center(
              child: Text(l10n.commonErrorWithMessage('${snapshot.error}')),
            ),
          );
        }

        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final data = snapshot.data!;
        final group = data.group;
        final members = data.members;
        final allActiveMeds = data.allActiveMeds;
        final reminders = data.reminders;
        final colorScheme = Theme.of(context).colorScheme;

        return Scaffold(
          appBar: AppBar(
            title: Text(group.name),
            actions: [
              IconButton(
                tooltip: group.isArchived
                    ? l10n.commonUnarchive
                    : l10n.commonArchive,
                icon: Icon(group.isArchived ? Icons.unarchive : Icons.archive),
                onPressed: () => _toggleArchive(group),
              ),
              IconButton(
                tooltip: l10n.medicationGroupDetailDeleteGroupTooltip,
                icon: Icon(Icons.delete_outline, color: colorScheme.error),
                onPressed: () => _deleteGroup(group),
              ),
            ],
            backgroundColor: context.surfaces.accentSurface,
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  Text(
                    l10n.commonMedications,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: group.isArchived
                        ? null
                        : () => _editMembers(group, allActiveMeds),
                    child: Text(l10n.commonEdit),
                  ),
                ],
              ),
              if (members.isEmpty)
                Text(l10n.medicationGroupDetailNoMembers)
              else
                ...members.map(
                  (m) => ListTile(
                    leading: const Icon(Icons.medication),
                    title: Text(m.name),
                    subtitle: Text(m.unit),
                  ),
                ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text(
                    l10n.commonReminders,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: group.isArchived
                        ? null
                        : () => _addReminder(group),
                    icon: const Icon(Icons.add),
                    label: Text(l10n.commonAdd),
                  ),
                ],
              ),
              if (reminders.isEmpty)
                Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(l10n.medicationGroupDetailNoReminders),
                )
              else
                ...reminders.map(
                  (r) => Card(
                    margin: const EdgeInsets.only(top: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: r.requiresExactAlarm
                            ? colorScheme.tertiary
                            : colorScheme.primary,
                        child: Icon(
                          r.requiresExactAlarm
                              ? Icons.alarm
                              : Icons.notifications,
                          color: context.neutralColors.white,
                        ),
                      ),
                      title: Text(
                        r.timeText,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_formatDays(context, r.daysOfWeek)),
                          if (r.requiresExactAlarm)
                            Text(
                              l10n.commonExactAlarm,
                              style: TextStyle(
                                fontSize: 12,
                                color: colorScheme.tertiary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          if (r.note != null && r.note!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                r.note!,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontStyle: FontStyle.italic,
                                  color: context.neutralColors.grey600,
                                ),
                              ),
                            ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.edit, color: colorScheme.primary),
                            onPressed: group.isArchived
                                ? null
                                : () => _editReminder(group, r),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete, color: colorScheme.error),
                            onPressed: group.isArchived
                                ? null
                                : () => _deleteReminder(r),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
