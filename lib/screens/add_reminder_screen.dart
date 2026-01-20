import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/medication_provider.dart';
import '../models/medication_reminder.dart';
import '../services/database_helper.dart';
import '../services/notification_service.dart';
import '../utils/permission_utils.dart';

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
  int? selectedMedicationId;
  TimeOfDay selectedTime = const TimeOfDay(hour: 9, minute: 0);
  final TextEditingController noteCtrl = TextEditingController();
  List<bool> selectedDays = [true, true, true, true, true, true, true];
  final dayLabels = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
  bool isExactAlarm = false;

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
    if (selectedMedicationId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ Selecciona un medicamento')),
      );
      return;
    }

    final daysOfWeek = <int>[];
    for (var i = 0; i < 7; i++) {
      if (selectedDays[i]) {
        daysOfWeek.add(i + 1);
      }
    }

    if (daysOfWeek.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ Selecciona al menos un día')),
      );
      return;
    }

    final meds = context.read<MedicationProvider>().medications;
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
      final db = DatabaseHelper.instance;

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
        reminderId = await db.createReminder(reminder);
      } else {
        // Actualizar existente
        await db.updateReminder(reminder);
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.reminderToEdit == null
                  ? '${isExactAlarm ? "⏰" : "📌"} Recordatorio creado'
                  : '${isExactAlarm ? "⏰" : "📌"} Recordatorio actualizado',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final meds = context.watch<MedicationProvider>().medications;
    final colorSheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.reminderToEdit == null
              ? '➕ Nuevo recordatorio'
              : '✏️ Editar recordatorio',
        ),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<int>(
              initialValue: selectedMedicationId,
              decoration: const InputDecoration(
                labelText: 'Medicamento',
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
                title: const Text('Hora del recordatorio'),
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

            const Text(
              'Días de la semana',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: List.generate(7, (i) {
                return FilterChip(
                  label: Text(dayLabels[i]),
                  selected: selectedDays[i],
                  onSelected: (val) {
                    setState(() {
                      selectedDays[i] = val;
                    });
                  },
                  selectedColor: Theme.of(
                    context,
                  ).colorScheme.tertiaryContainer,
                  checkmarkColor: Colors.white,
                );
              }),
            ),
            const SizedBox(height: 24),

            TextField(
              controller: noteCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Nota (opcional)',
                hintText: 'Ej: Después de comer, con agua...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.note),
              ),
            ),
            const SizedBox(height: 24),

            CheckboxListTile(
              title: const Text(
                'Este medicamento requiere precisión (como despertador)',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              subtitle: const Text(
                'Suena aunque el celular esté en reposo. Necesita permisos especiales.',
                style: TextStyle(fontSize: 12),
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
                        '⚠️ Si usás "No Molestar", este recordatorio puede no sonar. Para que funcione como despertador, asegurate de permitir alarmas para esta app en Ajustes de Sonido.',
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
                      ? 'Guardar recordatorio'
                      : 'Actualizar recordatorio',
                  style: const TextStyle(fontSize: 18),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.inversePrimary,
                  foregroundColor: Colors.black87,
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
