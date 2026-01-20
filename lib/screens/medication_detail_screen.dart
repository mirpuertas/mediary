import 'package:flutter/material.dart';
import '../models/medication.dart';
import '../models/medication_reminder.dart';
import '../services/database_helper.dart';
import '../services/notification_service.dart';
import 'add_reminder_screen.dart';

class MedicationDetailScreen extends StatefulWidget {
  final Medication medication;

  const MedicationDetailScreen({super.key, required this.medication});

  @override
  State<MedicationDetailScreen> createState() => _MedicationDetailScreenState();
}

class _MedicationDetailScreenState extends State<MedicationDetailScreen> {
  List<MedicationReminder> _reminders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReminders();
  }

  Future<void> _loadReminders() async {
    setState(() => _isLoading = true);
    try {
      final db = DatabaseHelper.instance;
      final reminders = await db.getRemindersByMedication(
        widget.medication.id!,
      );
      setState(() {
        _reminders = reminders;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error al cargar recordatorios: $e')),
        );
      }
    }
  }

  Future<void> _deleteReminder(MedicationReminder reminder) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar recordatorio'),
        content: Text(
          '¿Eliminar el recordatorio de las ${reminder.hour.toString().padLeft(2, '0')}:${reminder.minute.toString().padLeft(2, '0')}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final db = DatabaseHelper.instance;
      await db.deleteReminder(reminder.id!);
      await NotificationService.instance.cancelMedicationReminder(reminder);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Recordatorio eliminado'),
            backgroundColor: Colors.green,
          ),
        );
      }

      await _loadReminders();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  String _formatDays(MedicationReminder reminder) {
    if (reminder.isDaily) {
      return 'Todos los días';
    }

    final dayNames = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
    final selectedDays = reminder.daysOfWeek
        .map((d) => dayNames[d - 1])
        .join(', ');
    return 'Días: $selectedDays';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.medication.name),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
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
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const Divider(),

                // Encabezado de lista de horarios
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.alarm, color: colorScheme.tertiary),
                      const SizedBox(width: 8),
                      const Text(
                        'Horarios de toma',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${_reminders.length} ${_reminders.length == 1 ? "horario" : "horarios"}',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),

                // Lista de recordatorios
                Expanded(
                  child: _reminders.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.alarm_off,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Sin recordatorios configurados',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Presioná el botón + para agregar uno',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[500],
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
                                    color: Colors.white,
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
                                    Text(_formatDays(reminder)),
                                    if (reminder.requiresExactAlarm)
                                      Text(
                                        '⏰ Alarma exacta',
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
                                      icon: const Icon(
                                        Icons.edit,
                                        color: Colors.blue,
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
        label: const Text('Agregar horario'),
        backgroundColor: Theme.of(context).colorScheme.tertiary,
        foregroundColor: Colors.black87,
      ),
    );
  }
}
