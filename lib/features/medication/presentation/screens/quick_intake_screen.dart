import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../services/notification_service.dart';
import '../../../sleep/state/sleep_controller.dart';
import '../../../../models/intake_event.dart';
import '../../../../models/medication.dart';
import '../../../../l10n/l10n.dart';
import '../../../../ui/app_theme_tokens.dart';
import '../../../../utils/ui_feedback.dart';
import '../../data/quick_intake_repository.dart';

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
  final QuickIntakeRepository _repo = QuickIntakeRepository();

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
    return _repo.getActiveMedicationsByIds(widget.medicationIds);
  }

  Future<void> _saveSelection({Duration? snoozeRemaining}) async {
    if (_saving) return;
    setState(() => _saving = true);

    final l10n = context.l10n;
    final sleepController = context.read<SleepController>();

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
      UIFeedback.showWarning(
        context,
        l10n.quickIntakeSelectAtLeastOneMedication,
      );
      return;
    }

    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final dayEntry = await _repo.ensureDayEntry(today);

      final existing = await sleepController.getEventsForDayEntry(dayEntry.id!);
      final events = List<IntakeEvent>.from(existing);

      final missingDose = <String>[];

      for (final medicationId in selectedIds) {
        final medication = await _repo.getMedication(medicationId);
        if (medication == null) continue;

        final isGel = medication.type == MedicationType.gel;
        final num = medication.defaultDoseNumerator;
        final den = medication.defaultDoseDenominator;
        final hasValidDefaultDose =
            num != null && den != null && num > 0 && den > 0;

        if (!hasValidDefaultDose && !isGel) {
          missingDose.add(medication.name);
        }

        events.add(
          IntakeEvent(
            dayEntryId: dayEntry.id!,
            medicationId: medicationId,
            takenAt: now,
            amountNumerator: (hasValidDefaultDose && !isGel) ? num : null,
            amountDenominator: (hasValidDefaultDose && !isGel) ? den : null,
            note: isGel
                ? l10n.notificationsAutoLoggedWithApplication
                : (hasValidDefaultDose
                      ? l10n.notificationsAutoLogged
                      : l10n.quickIntakeAutoLoggedWithoutDose),
          ),
        );
      }

      await _repo.replaceIntakeEvents(dayEntryId: dayEntry.id!, events: events);

      // Snooze individuales para las restantes
      if (snoozeRemaining != null && remainingIds.isNotEmpty) {
        final baseReminderId = widget.reminderId ?? 0;
        for (final medicationId in remainingIds) {
          final medication = await _repo.getMedication(medicationId);
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

      sleepController.clearDayCache(dayEntry.id!);
      await sleepController.loadEntries();

      if (!mounted) return;
      if (missingDose.isNotEmpty) {
        final names =
            '${missingDose.take(2).join(', ')}${missingDose.length > 2 ? '…' : ''}';
        UIFeedback.showWarning(
          context,
          l10n.quickIntakeMissingDefaultDose(names),
        );
      } else {
        UIFeedback.showSuccess(context, l10n.quickIntakeSaved);
      }

      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        UIFeedback.showError(context, l10n.commonErrorWithMessage('$e'));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _snoozeSingle(Duration delay) async {
    final l10n = context.l10n;
    try {
      final medicationId = widget.medicationIds.first;
      final medication = await _repo.getMedication(medicationId);
      if (medication == null) {
        throw Exception(l10n.quickIntakeMedicationNotFound);
      }

      await NotificationService.instance.snoozeMedicationReminder(
        widget.reminderId ?? 0,
        medicationId,
        medication,
        delay,
      );

      if (!mounted) return;
      final minutes = delay.inMinutes;
      UIFeedback.showWarning(context, l10n.quickIntakeSnoozed(minutes));
      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        UIFeedback.showError(context, l10n.commonErrorWithMessage('$e'));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isGroup
              ? l10n.quickIntakeAppBarGroup(
                  widget.groupName?.trim().isNotEmpty == true
                      ? widget.groupName!.trim()
                      : l10n.quickIntakeDefaultGroupName,
                )
              : l10n.quickIntakeAppBarSingle,
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
            return Center(child: Text(l10n.quickIntakeNoActiveMeds));
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
                      l10n.quickIntakeUnitLabel(medication.unit),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: context.neutralColors.grey600,
                      ),
                    ),
                    const SizedBox(height: 40),
                    Text(
                      l10n.quickIntakeWhatToDo,
                      style: const TextStyle(fontSize: 18),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.check_circle, size: 28),
                        label: Text(
                          l10n.quickIntakeIHaveTaken,
                          style: const TextStyle(fontSize: 18),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.secondary,
                          foregroundColor: context.neutralColors.white,
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
                        label: Text(l10n.quickIntakeSnooze10m),
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
                        label: Text(l10n.quickIntakeSnooze1h),
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
                        l10n.commonIgnore,
                        style: TextStyle(color: context.neutralColors.grey600),
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
                        l10n.quickIntakeChooseTaken,
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
                      child: Text(l10n.commonAll),
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
                      child: Text(l10n.commonNone),
                    ),
                  ],
                ),
                Text(
                  l10n.quickIntakeSelectedCount(selectedCount, meds.length),
                  style: TextStyle(color: context.neutralColors.grey700),
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
                    label: Text(l10n.quickIntakeSaveSelectedClose),
                    onPressed: _saving ? null : () => _saveSelection(),
                  ),
                ),
                if (selectedCount < meds.length) ...[
                  const SizedBox(height: 6),
                  Text(
                    l10n.quickIntakeRemainingHint(meds.length - selectedCount),
                    style: TextStyle(
                      fontSize: 12,
                      color: context.neutralColors.grey700,
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.snooze),
                        label: Text(l10n.quickIntakeSnoozeRemaining10m),
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
                        label: Text(l10n.quickIntakeSnoozeRemaining1h),
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
