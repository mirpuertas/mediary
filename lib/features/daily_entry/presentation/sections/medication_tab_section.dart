import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../models/medication.dart';
import '../../../medication/state/medication_controller.dart';
import '../../../../l10n/l10n.dart';
import '../../../../ui/app_theme_tokens.dart';
import '../../../../ui/theme_helpers.dart';
import '../../../../utils/fraction_helper.dart';
import '../../../../utils/ui_feedback.dart';
import '../../../../widgets/fraction_picker_dialog.dart';
import '../../state/daily_entry_controller.dart';
import '../../state/intake_event_draft.dart';

String _medTypeLabel(BuildContext context, MedicationType type) {
  final l10n = context.l10n;
  return switch (type) {
    MedicationType.tablet => l10n.medicationTypeTablet,
    MedicationType.drops => l10n.medicationTypeDrops,
    MedicationType.capsule => l10n.medicationTypeCapsule,
    MedicationType.gel => l10n.medicationTypeGel,
  };
}

class MedicationTabSection extends StatefulWidget {
  final DailyEntryController controller;
  final Set<int> expandedIndices;
  final VoidCallback onSavePressed;
  final VoidCallback onAddPressed;
  final void Function(int index) onRemovePressed;

  const MedicationTabSection({
    super.key,
    required this.controller,
    required this.expandedIndices,
    required this.onSavePressed,
    required this.onAddPressed,
    required this.onRemovePressed,
  });

  @override
  State<MedicationTabSection> createState() => _MedicationTabSectionState();
}

class _MedicationTabSectionState extends State<MedicationTabSection> {
  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final l10n = context.l10n;
    final hasEvents = c.intakeEvents.isNotEmpty;

    return Column(
      children: [
        if (hasEvents)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                Builder(
                  builder: (context) {
                    final allExpanded =
                        c.intakeEvents.isNotEmpty &&
                        widget.expandedIndices.length == c.intakeEvents.length;

                    return TextButton.icon(
                      onPressed: () {
                        setState(() {
                          if (allExpanded) {
                            widget.expandedIndices.clear();
                          } else {
                            widget.expandedIndices
                              ..clear()
                              ..addAll(
                                List.generate(c.intakeEvents.length, (i) => i),
                              );
                          }
                        });
                      },
                      icon: Icon(
                        allExpanded ? Icons.unfold_less : Icons.unfold_more,
                      ),
                      label: Text(
                        allExpanded
                            ? l10n.medicationTabCollapseAll
                            : l10n.medicationTabExpandAll,
                      ),
                    );
                  },
                ),
                const Spacer(),
                Text(
                  '${c.intakeEvents.length}',
                  style: TextStyle(color: muted(context, 0.60)),
                ),
              ],
            ),
          ),
        Expanded(
          child: !hasEvents
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.medication_outlined,
                          size: 64,
                          color: muted(context, 0.30),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l10n.medicationTabEmptyTitle,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: muted(context, 0.70),
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.medicationTabEmptySubtitle,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: muted(context, 0.55),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: c.intakeEvents.length,
                  itemBuilder: (context, index) {
                    return IntakeEventCard(
                      key: ValueKey(index),
                      event: c.intakeEvents[index],
                      index: index,
                      isExpanded: widget.expandedIndices.contains(index),
                      onExpandedChanged: (expanded) {
                        setState(() {
                          if (expanded) {
                            widget.expandedIndices.add(index);
                          } else {
                            widget.expandedIndices.remove(index);
                          }
                        });
                      },
                      onRemove: () => widget.onRemovePressed(index),
                      onEventChanged: (next) =>
                          c.updateIntakeEvent(index, next),
                    );
                  },
                ),
        ),
        Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            boxShadow: [
              BoxShadow(
                color: context.neutralColors.black.withValues(alpha: 0.10),
                blurRadius: 4,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: widget.onAddPressed,
                  icon: const Icon(Icons.add),
                  label: Text(l10n.medicationTabAddMedication),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: widget.onSavePressed,
                icon: const Icon(Icons.save),
                label: Text(l10n.commonSave),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class IntakeEventCard extends StatefulWidget {
  final IntakeEventDraft event;
  final int index;
  final VoidCallback onRemove;
  final ValueChanged<IntakeEventDraft> onEventChanged;
  final bool isExpanded;
  final ValueChanged<bool> onExpandedChanged;

  const IntakeEventCard({
    super.key,
    required this.event,
    required this.index,
    required this.onRemove,
    required this.onEventChanged,
    required this.isExpanded,
    required this.onExpandedChanged,
  });

  @override
  State<IntakeEventCard> createState() => _IntakeEventCardState();
}

class _IntakeEventCardState extends State<IntakeEventCard> {
  late String _selectedKey;
  late bool _isExpanded;
  late final TextEditingController _noteController;

  @override
  void initState() {
    super.initState();
    _selectedKey =
        (widget.event.numerator == null || widget.event.denominator == null)
        ? 'unknown'
        : '${widget.event.numerator}/${widget.event.denominator}';
    _isExpanded = widget.isExpanded;
    _noteController = TextEditingController(text: widget.event.note);
  }

  @override
  void didUpdateWidget(covariant IntakeEventCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isExpanded != widget.isExpanded) {
      _isExpanded = widget.isExpanded;
    }

    if (oldWidget.event.note != widget.event.note &&
        _noteController.text != widget.event.note) {
      _noteController.text = widget.event.note;
    }

    final nextKey =
        (widget.event.numerator == null || widget.event.denominator == null)
        ? 'unknown'
        : '${widget.event.numerator}/${widget.event.denominator}';
    if (_selectedKey != nextKey) {
      _selectedKey = nextKey;
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    final next = !_isExpanded;
    setState(() {
      _isExpanded = next;
    });
    widget.onExpandedChanged(next);
  }

  String _doseSummary(BuildContext context, MedicationType medicationType) {
    final l10n = context.l10n;
    final num = widget.event.numerator;
    final den = widget.event.denominator;
    if (medicationType == MedicationType.gel) {
      return l10n.medicationTabDoseApplication;
    }
    if (num == null || den == null) {
      return l10n.commonNoDose;
    }

    if (medicationType == MedicationType.drops) {
      return l10n.medicationTabDropsDose(num);
    }
    if (medicationType == MedicationType.capsule) {
      return l10n.medicationTabCapsulesDose(num);
    }

    return FractionHelper.fractionToText(num, den);
  }

  Widget _buildFractionDropdown() {
    final cs = Theme.of(context).colorScheme;

    final presets = {
      '1/4': 'preset',
      '1/2': 'preset',
      '3/4': 'preset',
      '1/1': 'preset',
      '3/2': 'preset',
      '2/1': 'preset',
      '5/2': 'preset',
      '3/1': 'preset',
    };

    final currentKey =
        (widget.event.numerator == null || widget.event.denominator == null)
        ? 'unknown'
        : '${widget.event.numerator}/${widget.event.denominator}';
    final isPreset = presets.containsKey(currentKey);

    final allFractions = <Map<String, dynamic>>[];

    presets.forEach((key, _) {
      final parts = key.split('/');
      allFractions.add({
        'key': key,
        'numerator': int.parse(parts[0]),
        'denominator': int.parse(parts[1]),
      });
    });

    if (!isPreset && currentKey != 'unknown') {
      allFractions.add({
        'key': currentKey,
        'numerator': widget.event.numerator,
        'denominator': widget.event.denominator,
      });
    }

    allFractions.sort((a, b) {
      final valueA = a['numerator'] / a['denominator'];
      final valueB = b['numerator'] / b['denominator'];
      return valueA.compareTo(valueB);
    });

    final items = <DropdownMenuItem<String>>[];

    items.add(
      DropdownMenuItem(
        value: 'unknown',
        child: Text(context.l10n.commonNoDoseWithDash),
      ),
    );

    for (final frac in allFractions) {
      items.add(
        DropdownMenuItem(
          value: frac['key'] as String,
          child: Text(
            FractionHelper.fractionToText(
              frac['numerator'] as int,
              frac['denominator'] as int,
            ),
          ),
        ),
      );
    }

    items.add(
      DropdownMenuItem(
        value: 'custom',
        child: Text(
          context.l10n.medicationsDefaultDoseCustom,
          style: TextStyle(fontStyle: FontStyle.italic, color: cs.primary),
        ),
      ),
    );

    return DropdownButtonFormField<String>(
      initialValue: _selectedKey,
      decoration: InputDecoration(
        labelText: context.l10n.commonQuantity,
        border: const OutlineInputBorder(),
        prefixIcon: const Icon(Icons.format_list_numbered),
      ),
      items: items,
      onChanged: (value) async {
        if (value == 'unknown') {
          setState(() {
            _selectedKey = 'unknown';
          });
          widget.onEventChanged(
            widget.event.copyWith(numerator: null, denominator: null),
          );
          return;
        }

        if (value == 'custom') {
          final result = await FractionPickerDialog.show(
            context,
            initialNumerator: widget.event.numerator ?? 1,
            initialDenominator: widget.event.denominator ?? 1,
            title: context.l10n.medicationTabCustomQuantityTitle,
          );
          if (result != null) {
            final newKey = '${result.numerator}/${result.denominator}';
            setState(() {
              _selectedKey = newKey;
            });
            widget.onEventChanged(
              widget.event.copyWith(
                numerator: result.numerator,
                denominator: result.denominator,
              ),
            );
          }
        } else if (value != null) {
          final parts = value.split('/');
          setState(() {
            _selectedKey = value;
          });
          widget.onEventChanged(
            widget.event.copyWith(
              numerator: int.parse(parts[0]),
              denominator: int.parse(parts[1]),
            ),
          );
        }
      },
    );
  }

  Future<void> _selectDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: widget.event.takenAt,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );

    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(widget.event.takenAt),
    );

    if (time == null || !mounted) return;

    widget.onEventChanged(
      widget.event.copyWith(
        takenAt: DateTime(
          date.year,
          date.month,
          date.day,
          time.hour,
          time.minute,
        ),
      ),
    );
  }

  Future<Medication?> _showAddMedicationDialog() async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final brandNameController = TextEditingController();
    final unitController = TextEditingController();
    MedicationType selectedType = MedicationType.tablet;

    return showDialog<Medication>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(context.l10n.medicationsDialogAddTitle),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: context.l10n.medicationsGenericNameLabel,
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return context.l10n.medicationsGenericNameRequired;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: brandNameController,
                    decoration: InputDecoration(
                      labelText: context.l10n.medicationsBrandNameLabel,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: unitController,
                    decoration: InputDecoration(
                      labelText: context.l10n.medicationsBaseUnitLabel,
                      hintText: context.l10n.medicationsBaseUnitHint,
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return context.l10n.medicationsBaseUnitRequired;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<MedicationType>(
                    initialValue: selectedType,
                    decoration: InputDecoration(
                      labelText: context.l10n.medicationsTypeLabel,
                      border: const OutlineInputBorder(),
                    ),
                    items: MedicationType.values.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Text(_medTypeLabel(context, type)),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() {
                          selectedType = value;
                        });
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(context.l10n.commonCancel),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  try {
                    final medicationController = context
                        .read<MedicationController>();
                    await medicationController.addMedication(
                      nameController.text.trim(),
                      unitController.text.trim(),
                      brandName: brandNameController.text.trim().isEmpty
                          ? null
                          : brandNameController.text.trim(),
                      type: selectedType,
                    );

                    final medications = medicationController.medications;
                    final newMed = medications.firstWhere(
                      (m) =>
                          m.name == nameController.text.trim() &&
                          m.unit == unitController.text.trim(),
                    );

                    if (context.mounted) {
                      Navigator.pop(context, newMed);
                    }
                  } catch (e) {
                    if (context.mounted) {
                      UIFeedback.showError(
                        context,
                        context.l10n.medicationsError(e.toString()),
                      );
                    }
                  }
                }
              },
              child: Text(context.l10n.commonAdd),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cs = Theme.of(context).colorScheme;
    final localeName = Localizations.localeOf(context).toString();
    final timeFormat = DateFormat('HH:mm', localeName);
    final medicationController = context.watch<MedicationController>();
    final medications = medicationController.medications; // activos
    final allMedications =
        medicationController.allMedications; // incluye archivados

    int? safeMedicationId = widget.event.medicationId;
    if (safeMedicationId != null &&
        !allMedications.any((m) => m.id == safeMedicationId)) {
      safeMedicationId = null;
    }

    final selectedMedication = safeMedicationId != null
        ? allMedications.where((m) => m.id == safeMedicationId).firstOrNull
        : null;

    final medicationType = selectedMedication?.type ?? MedicationType.tablet;
    final medicationSummary = selectedMedication == null
        ? l10n.commonNoMedication
        : '${selectedMedication.name} (${selectedMedication.unit})';
    final doseSummary = _doseSummary(context, medicationType);
    final timeSummary = timeFormat.format(widget.event.takenAt);
    final hasNote = _noteController.text.trim().isNotEmpty;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: _toggleExpanded,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            medicationSummary,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: [
                              _Pill(text: timeSummary, icon: Icons.access_time),
                              _Pill(text: doseSummary, icon: Icons.functions),
                              if (hasNote)
                                _Pill(text: l10n.commonNote, icon: Icons.notes),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: l10n.commonDelete,
                  onPressed: widget.onRemove,
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
            if (_isExpanded) ...[
              const Divider(height: 24),
              DropdownButtonFormField<int?>(
                isExpanded: true,
                initialValue: safeMedicationId,
                decoration: InputDecoration(
                  labelText: l10n.medicationTabMedicationLabel,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.medication),
                ),
                items: [
                  DropdownMenuItem<int?>(
                    value: null,
                    child: Text(l10n.commonSelect),
                  ),
                  ...medications.map(
                    (m) => DropdownMenuItem<int?>(
                      value: m.id,
                      child: Text(
                        '${m.name} (${m.unit})',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        softWrap: false,
                      ),
                    ),
                  ),
                  if (selectedMedication != null &&
                      selectedMedication.isArchived)
                    DropdownMenuItem<int?>(
                      value: selectedMedication.id,
                      child: Text(
                        '${selectedMedication.name} (${selectedMedication.unit}) (Archivado)',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        softWrap: false,
                        style: TextStyle(color: muted(context, 0.70)),
                      ),
                    ),
                  DropdownMenuItem<int?>(
                    value: -1,
                    child: Text(
                      l10n.medicationTabAddAnotherMedication,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      softWrap: false,
                      style: TextStyle(
                        color: cs.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
                onChanged: (value) async {
                  if (value == -1) {
                    final newMed = await _showAddMedicationDialog();
                    if (newMed != null && mounted) {
                      setState(() {
                        var updated = widget.event.copyWith(
                          medicationId: newMed.id,
                        );

                        if (newMed.type == MedicationType.gel) {
                          _selectedKey = 'unknown';
                          updated = updated.copyWith(
                            numerator: null,
                            denominator: null,
                          );
                        } else if (newMed.defaultDoseNumerator != null &&
                            newMed.defaultDoseDenominator != null &&
                            newMed.defaultDoseDenominator! > 0) {
                          final newKey =
                              '${newMed.defaultDoseNumerator}/${newMed.defaultDoseDenominator}';
                          _selectedKey = newKey;
                          updated = updated.copyWith(
                            numerator: newMed.defaultDoseNumerator!,
                            denominator: newMed.defaultDoseDenominator!,
                          );
                        } else {
                          _selectedKey = 'unknown';
                          updated = updated.copyWith(
                            numerator: null,
                            denominator: null,
                          );
                        }

                        widget.onEventChanged(updated);
                      });
                    } else {
                      setState(() {});
                    }
                  } else {
                    setState(() {
                      if (value != null) {
                        var updated = widget.event.copyWith(
                          medicationId: value,
                        );
                        final medication = allMedications.firstWhere(
                          (m) => m.id == value,
                        );
                        if (medication.type == MedicationType.gel) {
                          _selectedKey = 'unknown';
                          updated = updated.copyWith(
                            numerator: null,
                            denominator: null,
                          );
                        } else if (medication.defaultDoseNumerator != null &&
                            medication.defaultDoseDenominator != null &&
                            medication.defaultDoseDenominator! > 0) {
                          final newKey =
                              '${medication.defaultDoseNumerator}/${medication.defaultDoseDenominator}';
                          _selectedKey = newKey;
                          updated = updated.copyWith(
                            numerator: medication.defaultDoseNumerator!,
                            denominator: medication.defaultDoseDenominator!,
                          );
                        } else {
                          _selectedKey = 'unknown';
                          updated = updated.copyWith(
                            numerator: null,
                            denominator: null,
                          );
                        }

                        widget.onEventChanged(updated);
                      } else {
                        widget.onEventChanged(
                          widget.event.copyWith(medicationId: null),
                        );
                      }
                    });
                  }
                },
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.access_time),
                title: Text(l10n.commonTime),
                subtitle: Text(timeFormat.format(widget.event.takenAt)),
                trailing: const Icon(Icons.edit),
                onTap: _selectDateTime,
              ),
              const SizedBox(height: 12),
              if (medicationType == MedicationType.drops ||
                  medicationType == MedicationType.capsule)
                DropdownButtonFormField<int?>(
                  initialValue:
                      (widget.event.numerator == null ||
                          widget.event.denominator == null ||
                          widget.event.denominator != 1)
                      ? null
                      : widget.event.numerator,
                  decoration: InputDecoration(
                    labelText: medicationType == MedicationType.drops
                        ? l10n.medicationTabDoseDropsLabel
                        : l10n.medicationTabDoseCapsulesLabel,
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.numbers),
                  ),
                  items: [
                    DropdownMenuItem<int?>(
                      value: null,
                      child: Text(l10n.commonNoDoseWithDash),
                    ),
                    ...List.generate(50, (i) => i + 1).map((count) {
                      return DropdownMenuItem<int?>(
                        value: count,
                        child: Text(count.toString()),
                      );
                    }),
                  ],
                  onChanged: (value) {
                    if (value == null) {
                      widget.onEventChanged(
                        widget.event.copyWith(
                          numerator: null,
                          denominator: null,
                        ),
                      );
                      setState(() => _selectedKey = 'unknown');
                      return;
                    }
                    widget.onEventChanged(
                      widget.event.copyWith(numerator: value, denominator: 1),
                    );
                    setState(() => _selectedKey = '$value/1');
                  },
                )
              else if (medicationType == MedicationType.gel)
                InputDecorator(
                  decoration: InputDecoration(
                    labelText: l10n.commonQuantity,
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.opacity),
                  ),
                  child: Text(
                    l10n.medicationTabDoseApplication,
                    style: TextStyle(color: muted(context, 0.85)),
                  ),
                )
              else
                _buildFractionDropdown(),
              const SizedBox(height: 12),
              TextField(
                controller: _noteController,
                maxLines: 2,
                textCapitalization: TextCapitalization.sentences,
                onChanged: (v) {
                  widget.onEventChanged(widget.event.copyWith(note: v));
                  setState(() {});
                },
                decoration: InputDecoration(
                  labelText: l10n.medicationTabNoteOptionalLabel,
                  hintText: l10n.medicationTabNoteHint,
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String text;
  final IconData icon;

  const _Pill({required this.text, required this.icon});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final border = dividerColor(context, 0.18);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: muted(context, 0.70)),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(color: muted(context, 0.80), fontSize: 12),
          ),
        ],
      ),
    );
  }
}
