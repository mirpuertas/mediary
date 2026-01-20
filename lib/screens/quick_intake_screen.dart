import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/database_helper.dart';
import '../services/notification_service.dart';
import '../providers/sleep_entry_provider.dart';
import '../models/intake_event.dart';
import '../models/medication.dart';

class QuickIntakeScreen extends StatefulWidget {
  final int? reminderId;
  final List<int> medicationIds;
  final String? groupName;

  const QuickIntakeScreen({
    super.key,
    required this.reminderId,
    required this.medicationIds,
    this.groupName,
  });

  @override
  State<QuickIntakeScreen> createState() => _QuickIntakeScreenState();
}

class _QuickIntakeScreenState extends State<QuickIntakeScreen> {
  final Map<int, bool> _selected = {};
  bool _saving = false;

  bool get _isGroup => widget.medicationIds.length > 1;

  @override
  void initState() {
    super.initState();
    for (final id in widget.medicationIds) {
      _selected[id] = true;
    }
  }

  Future<List<Medication>> _loadMedications() async {
    final db = DatabaseHelper.instance;
    final meds = <Medication>[];
    for (final id in widget.medicationIds) {
      final m = await db.getMedication(id);
      if (m != null && !m.isArchived) {
        meds.add(m);
      }
    }
    meds.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return meds;
  }

  Future<void> _saveSelection({Duration? snoozeRemaining}) async {
    if (_saving) return;
    setState(() => _saving = true);

    final db = DatabaseHelper.instance;
    final provider = context.read<SleepEntryProvider>();

    final selectedIds = _selected.entries
        .where((e) => e.value)
        .map((e) => e.key)
        .toList(growable: false);

    final remainingIds = _selected.entries
        .where((e) => !e.value)
        .map((e) => e.key)
        .toList(growable: false);

    if (selectedIds.isEmpty) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seleccioná al menos un medicamento')),
      );
      return;
    }

    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final dayEntry = await db.ensureDayEntry(today);

      final existing = await provider.getEventsForDayEntry(dayEntry.id!);
      final events = List<IntakeEvent>.from(existing);

      final missingDose = <String>[];

      for (final medicationId in selectedIds) {
        final medication = await db.getMedication(medicationId);
        if (medication == null) continue;

        final num = medication.defaultDoseNumerator;
        final den = medication.defaultDoseDenominator;
        final hasValidDefaultDose =
            num != null && den != null && num > 0 && den > 0;

        if (!hasValidDefaultDose) {
          missingDose.add(medication.name);
        }

        events.add(
          IntakeEvent(
            dayEntryId: dayEntry.id!,
            medicationId: medicationId,
            takenAt: now,
            amountNumerator: hasValidDefaultDose ? num : null,
            amountDenominator: hasValidDefaultDose ? den : null,
            note: hasValidDefaultDose
                ? 'Registrado automáticamente'
                : 'Registrado automáticamente (sin dosis)',
          ),
        );
      }

      await db.deleteIntakeEventsByDay(dayEntry.id!);
      for (final event in events) {
        await db.saveIntakeEvent(event);
      }

      // Snooze individuales para las restantes
      if (snoozeRemaining != null && remainingIds.isNotEmpty) {
        final baseReminderId = widget.reminderId ?? 0;
        for (final medicationId in remainingIds) {
          final medication = await db.getMedication(medicationId);
          if (medication == null || medication.isArchived) continue;
          await NotificationService.instance.snoozeMedicationReminder(
            baseReminderId,
            medicationId,
            medication,
            snoozeRemaining,
            groupName: widget.groupName,
            fromGroup: true,
          );
        }
      }

      provider.clearDayCache(dayEntry.id!);
      await provider.loadEntries();

      if (!mounted) return;
      if (missingDose.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Sin dosis por defecto: ${missingDose.take(2).join(', ')}${missingDose.length > 2 ? '…' : ''}',
            ),
            backgroundColor: Colors.orange,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Toma registrada'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }

      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _snoozeSingle(Duration delay) async {
    final db = DatabaseHelper.instance;

    try {
      final medicationId = widget.medicationIds.first;
      final medication = await db.getMedication(medicationId);
      if (medication == null) {
        throw Exception('Medicamento no encontrado');
      }

      await NotificationService.instance.snoozeMedicationReminder(
        widget.reminderId ?? 0,
        medicationId,
        medication,
        delay,
      );

      if (!mounted) return;
      final minutes = delay.inMinutes;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('⏰ Recordatorio pospuesto $minutes min'),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 2),
        ),
      );
      Navigator.pop(context);
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
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isGroup
              ? '💊 ${widget.groupName?.trim().isNotEmpty == true ? widget.groupName!.trim() : 'Grupo de medicación'}'
              : '💊 Recordatorio',
        ),
        backgroundColor: Theme.of(context).colorScheme.tertiary,
      ),
      body: FutureBuilder<List<Medication>>(
        future: _loadMedications(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final meds = snapshot.data!;
          if (meds.isEmpty) {
            return const Center(
              child: Text('No hay medicamentos activos para este recordatorio'),
            );
          }

          if (!_isGroup) {
            final medication = meds.first;
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.medication,
                      size: 80,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      medication.name,
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Unidad: ${medication.unit}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 40),
                    const Text(
                      '¿Qué querés hacer?',
                      style: TextStyle(fontSize: 18),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.check_circle, size: 28),
                        label: const Text(
                          'Ya tomé',
                          style: TextStyle(fontSize: 18),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.secondary,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: _saving
                            ? null
                            : () => _saveSelection(snoozeRemaining: null),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.snooze),
                        label: const Text('Posponer 10 minutos'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Theme.of(
                            context,
                          ).colorScheme.tertiary,
                        ),
                        onPressed: _saving
                            ? null
                            : () => _snoozeSingle(const Duration(minutes: 10)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.access_time),
                        label: const Text('Posponer 1 hora'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Theme.of(
                            context,
                          ).colorScheme.tertiary,
                        ),
                        onPressed: _saving
                            ? null
                            : () => _snoozeSingle(const Duration(hours: 1)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: _saving ? null : () => Navigator.pop(context),
                      child: Text(
                        'Ignorar',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          // Grupo
          final selectedCount = meds
              .where((m) => (_selected[m.id] ?? false) == true)
              .length;

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Elegí cuáles tomaste',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: _saving
                          ? null
                          : () {
                              setState(() {
                                for (final m in meds) {
                                  if (m.id != null) _selected[m.id!] = true;
                                }
                              });
                            },
                      child: const Text('Todo'),
                    ),
                    TextButton(
                      onPressed: _saving
                          ? null
                          : () {
                              setState(() {
                                for (final m in meds) {
                                  if (m.id != null) _selected[m.id!] = false;
                                }
                              });
                            },
                      child: const Text('Nada'),
                    ),
                  ],
                ),
                Text(
                  '$selectedCount/${meds.length} seleccionados',
                  style: TextStyle(color: Colors.grey[700]),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.builder(
                    itemCount: meds.length,
                    itemBuilder: (context, index) {
                      final med = meds[index];
                      final checked = _selected[med.id] ?? false;
                      return CheckboxListTile(
                        value: checked,
                        title: Text(med.name),
                        subtitle: Text(med.unit),
                        onChanged: _saving
                            ? null
                            : (v) {
                                setState(() {
                                  _selected[med.id!] = v ?? false;
                                });
                              },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.check_circle),
                    label: const Text('Guardar seleccionadas (cerrar)'),
                    onPressed: _saving ? null : () => _saveSelection(),
                  ),
                ),
                if (selectedCount < meds.length) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Las ${meds.length - selectedCount} restantes no se vuelven a avisar automáticamente. Si querés que te notifique más tarde, usá “Posponer restantes”.',
                    style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                  ),
                ],
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.snooze),
                        label: const Text('Posponer restantes 10m'),
                        onPressed: _saving
                            ? null
                            : () => _saveSelection(
                                snoozeRemaining: const Duration(minutes: 10),
                              ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.access_time),
                        label: const Text('Posponer restantes 1h'),
                        onPressed: _saving
                            ? null
                            : () => _saveSelection(
                                snoozeRemaining: const Duration(hours: 1),
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
