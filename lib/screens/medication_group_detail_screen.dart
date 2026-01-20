import 'package:flutter/material.dart';

import '../models/medication.dart';
import '../models/medication_group.dart';
import '../models/medication_group_reminder.dart';
import '../services/database_helper.dart';
import '../services/notification_service.dart';
import '../utils/permission_utils.dart';

class MedicationGroupDetailScreen extends StatefulWidget {
  final int groupId;

  const MedicationGroupDetailScreen({super.key, required this.groupId});

  @override
  State<MedicationGroupDetailScreen> createState() =>
      _MedicationGroupDetailScreenState();
}

class _MedicationGroupDetailScreenState
    extends State<MedicationGroupDetailScreen> {
  Future<
    ({
      MedicationGroup group,
      List<Medication> members,
      List<Medication> allActiveMeds,
      List<MedicationGroupReminder> reminders,
    })
  >
  _load() async {
    final db = DatabaseHelper.instance;

    final group = await db.getMedicationGroup(widget.groupId);
    if (group == null) {
      throw Exception('Grupo no encontrado');
    }

    final members = await db.getMedicationGroupMembers(widget.groupId);
    final allMeds = await db.getAllMedications();
    final allActiveMeds = allMeds.where((m) => !m.isArchived).toList();
    allActiveMeds.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );

    final reminders = await db.getGroupRemindersByGroup(widget.groupId);
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
    final db = DatabaseHelper.instance;
    final reminders = await db.getGroupRemindersByGroup(group.id!);
    final meds = await db.getMedicationGroupMembers(group.id!);
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
    final db = DatabaseHelper.instance;
    final existingIds = (await db.getMedicationGroupMemberIds(
      group.id!,
    )).toSet();

    if (!mounted) return;
    final selected = <int, bool>{
      for (final m in allActiveMeds) m.id!: existingIds.contains(m.id),
    };

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setLocalState) {
            return AlertDialog(
              title: const Text('Medicamentos del grupo'),
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
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Guardar'),
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

    await db.setMedicationGroupMembers(
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
        return StatefulBuilder(
          builder: (context, setLocalState) {
            return AlertDialog(
              title: Text(
                reminderToEdit == null
                    ? '➕ Nuevo recordatorio'
                    : '✏️ Editar recordatorio',
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.schedule),
                      title: Text('Hora: ${time.format(context)}'),
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
                    const Text('Días'),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      children: [
                        for (final d in const [1, 2, 3, 4, 5, 6, 7])
                          FilterChip(
                            label: Text(_dayLabel(d)),
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
                      decoration: const InputDecoration(
                        labelText: 'Nota (opcional)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.note),
                      ),
                    ),
                    const SizedBox(height: 12),
                    CheckboxListTile(
                      title: const Text(
                        'Este grupo requiere precisión (como despertador)',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      subtitle: const Text(
                        'Suena aunque el celular esté en reposo. Necesita permisos especiales.',
                        style: TextStyle(fontSize: 12),
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
                                '⚠️ Si usás "No Molestar", este recordatorio puede no sonar. Para que funcione como despertador, asegurate de permitir alarmas para esta app en Ajustes de Sonido.',
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
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(reminderToEdit == null ? 'Crear' : 'Guardar'),
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

    final id = await DatabaseHelper.instance.createGroupReminder(reminder);
    final savedReminder = reminder.copyWith(id: id);

    final meds = await DatabaseHelper.instance.getMedicationGroupMembers(
      group.id!,
    );
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

    await DatabaseHelper.instance.updateGroupReminder(updated);

    final meds = await DatabaseHelper.instance.getMedicationGroupMembers(
      group.id!,
    );
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
        return AlertDialog(
          title: const Text('Eliminar recordatorio'),
          content: const Text('¿Seguro?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );

    if (ok != true) return;

    await NotificationService.instance.cancelMedicationGroupReminder(reminder);
    if (reminder.id != null) {
      await DatabaseHelper.instance.deleteGroupReminder(reminder.id!);
    }

    if (!mounted) return;
    setState(() {});
  }

  Future<void> _toggleArchive(MedicationGroup group) async {
    if (group.isArchived) {
      await DatabaseHelper.instance.unarchiveMedicationGroup(group.id!);
    } else {
      await DatabaseHelper.instance.archiveMedicationGroup(group.id!);
    }

    final updated = (await DatabaseHelper.instance.getMedicationGroup(
      group.id!,
    ))!;
    await _rescheduleAllReminders(updated);

    if (!mounted) return;
    setState(() {});
  }

  Future<void> _deleteGroup(MedicationGroup group) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Eliminar grupo'),
          content: const Text('Se eliminarán también sus recordatorios.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );

    if (ok != true) return;

    final db = DatabaseHelper.instance;
    final reminders = await db.getGroupRemindersByGroup(group.id!);
    for (final r in reminders) {
      await NotificationService.instance.cancelMedicationGroupReminder(r);
      if (r.id != null) {
        await db.deleteGroupReminder(r.id!);
      }
    }

    await db.deleteMedicationGroup(group.id!);

    if (!mounted) return;
    Navigator.pop(context);
  }

  static String _dayLabel(int d) {
    return switch (d) {
      1 => 'L',
      2 => 'M',
      3 => 'X',
      4 => 'J',
      5 => 'V',
      6 => 'S',
      7 => 'D',
      _ => '?',
    };
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _load(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Grupo')),
            body: Center(child: Text('Error: ${snapshot.error}')),
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
                tooltip: group.isArchived ? 'Desarchivar' : 'Archivar',
                icon: Icon(group.isArchived ? Icons.unarchive : Icons.archive),
                onPressed: () => _toggleArchive(group),
              ),
              IconButton(
                tooltip: 'Eliminar grupo',
                icon: Icon(Icons.delete_outline, color: colorScheme.error),
                onPressed: () => _deleteGroup(group),
              ),
            ],
            backgroundColor: colorScheme.inversePrimary,
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  const Text(
                    'Medicamentos',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: group.isArchived
                        ? null
                        : () => _editMembers(group, allActiveMeds),
                    child: const Text('Editar'),
                  ),
                ],
              ),
              if (members.isEmpty)
                const Text('Sin medicamentos asignados')
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
                  const Text(
                    'Recordatorios',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: group.isArchived
                        ? null
                        : () => _addReminder(group),
                    icon: const Icon(Icons.add),
                    label: const Text('Agregar'),
                  ),
                ],
              ),
              if (reminders.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text('Sin recordatorios'),
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
                          color: Colors.white,
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
                          Text(r.daysText),
                          if (r.requiresExactAlarm)
                            Text(
                              '⏰ Alarma exacta',
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
                                  color: Colors.grey[600],
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
