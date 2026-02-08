import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';

import '../../../../l10n/l10n.dart';
import '../../state/medication_controller.dart';
import '../../../../ui/app_theme_tokens.dart';
import '../../../../models/medication.dart';
import '../../../../models/medication_reminder.dart';
import '../../../../services/notification_service.dart';
import '../../../../utils/fraction_helper.dart';
import '../../../../utils/ui_feedback.dart';
import '../../../../widgets/fraction_picker_dialog.dart';
import '../../data/medication_reminders_repository.dart';
import '../../data/medication_repository.dart';
import 'medication_detail_screen.dart';
import 'add_reminder_screen.dart';
import 'medication_groups_screen.dart';

String _medTypeLabel(BuildContext context, MedicationType type) {
  final l10n = context.l10n;
  return switch (type) {
    MedicationType.tablet => l10n.medicationTypeTablet,
    MedicationType.drops => l10n.medicationTypeDrops,
    MedicationType.capsule => l10n.medicationTypeCapsule,
    MedicationType.gel => l10n.medicationTypeGel,
  };
}

class MedicationsScreen extends StatefulWidget {
  const MedicationsScreen({super.key});

  @override
  State<MedicationsScreen> createState() => _MedicationsScreenState();
}

class _MedicationsScreenState extends State<MedicationsScreen> {
  final MedicationRemindersRepository _remindersRepo =
      MedicationRemindersRepository();
  final MedicationRepository _medRepo = MedicationRepository();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MedicationController>().loadMedications();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.medicationsTitle),
        backgroundColor: context.surfaces.accentSurface,
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.groups),
            label: Text(l10n.medicationsGroupButton),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const MedicationGroupsScreen(),
                ),
              );
              if (!context.mounted) return;
              await context.read<MedicationController>().loadMedications();
            },
          ),
        ],
      ),
      body: Consumer<MedicationController>(
        builder: (context, provider, _) {
          final medications = provider.medications;
          final archived = provider.allMedications
              .where((m) => m.isArchived)
              .toList();

          if (medications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.medication_outlined,
                    size: 64,
                    color: context.neutralColors.grey400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.medicationsEmptyTitle,
                    style: TextStyle(
                      fontSize: 18,
                      color: context.neutralColors.grey600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.medicationsEmptySubtitle,
                    style: TextStyle(color: context.neutralColors.grey500),
                  ),
                ],
              ),
            );
          }

          final showArchivedSection = archived.isNotEmpty;

          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 80),
            itemCount: medications.length + (showArchivedSection ? 1 : 0),
            itemBuilder: (context, index) {
              if (index < medications.length) {
                final medication = medications[index];
                return _MedicationCard(
                  medication: medication,
                  onEdit: () => _showMedicationDialog(medication: medication),
                  onManage: () => _confirmArchiveOrDelete(medication),
                  onRefresh: () => setState(() {}),
                );
              }

              // Sección de archivados
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Card(
                  child: ExpansionTile(
                    leading: const Icon(Icons.archive_outlined),
                    title: Text(
                      l10n.medicationsArchivedSectionTitle(archived.length),
                    ),
                    children: [
                      for (final med in archived)
                        ListTile(
                          leading: const Icon(Icons.medication_outlined),
                          title: Text(med.name),
                          subtitle: Text(
                            '${med.unit} • ${_medTypeLabel(context, med.type)}',
                          ),
                          trailing: TextButton(
                            onPressed: () => _confirmUnarchive(med),
                            child: Text(l10n.medicationsUnarchiveButton),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showMedicationDialog(),
        label: Text(l10n.medicationsAddButton),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _showMedicationDialog({Medication? medication}) async {
    final nameController = TextEditingController(text: medication?.name ?? '');
    final brandNameController = TextEditingController(
      text: medication?.brandName ?? '',
    );
    final unitController = TextEditingController(text: medication?.unit ?? '');
    MedicationType selectedType = medication?.type ?? MedicationType.tablet;
    final formKey = GlobalKey<FormState>();

    // Dosis por defecto
    int? defaultNumerator = medication?.defaultDoseNumerator;
    int? defaultDenominator = medication?.defaultDoseDenominator;
    bool hasDefaultDose =
        defaultNumerator != null &&
        defaultDenominator != null &&
        defaultDenominator != 0;
    String selectedDefaultKey = hasDefaultDose
        ? '$defaultNumerator/$defaultDenominator'
        : '1/1';

    // Para gotas/cápsulas la dosis debe ser entera (denominador = 1).
    if (selectedType == MedicationType.drops ||
        selectedType == MedicationType.capsule) {
      if (hasDefaultDose) {
        defaultDenominator = 1;
        selectedDefaultKey = '$defaultNumerator/1';
      }
    }

    // Para gel: no hay dosis por defecto (una toma = una aplicación).
    if (selectedType == MedicationType.gel) {
      hasDefaultDose = false;
      defaultNumerator = null;
      defaultDenominator = null;
      selectedDefaultKey = '1/1';
    }

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(
            medication == null
                ? context.l10n.medicationsDialogAddTitle
                : context.l10n.medicationsDialogEditTitle,
          ),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Nombre genérico
                  TextFormField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: context.l10n.medicationsGenericNameLabel,
                      hintText: context.l10n.medicationsGenericNameHint,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return context.l10n.medicationsGenericNameRequired;
                      }
                      return null;
                    },
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 16),

                  // Nombre comercial (opcional)
                  TextFormField(
                    controller: brandNameController,
                    decoration: InputDecoration(
                      labelText: context.l10n.medicationsBrandNameLabel,
                      hintText: context.l10n.medicationsBrandNameHint,
                    ),
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 16),

                  // Unidad base
                  TextFormField(
                    controller: unitController,
                    decoration: InputDecoration(
                      labelText: context.l10n.medicationsBaseUnitLabel,
                      hintText: context.l10n.medicationsBaseUnitHint,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return context.l10n.medicationsBaseUnitRequired;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Tipo de medicación
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
                      setState(() {
                        selectedType = value ?? MedicationType.tablet;

                        if (selectedType == MedicationType.drops ||
                            selectedType == MedicationType.capsule) {
                          if (hasDefaultDose) {
                            defaultNumerator ??= 1;
                            defaultDenominator = 1;
                            selectedDefaultKey = '$defaultNumerator/1';
                          }
                        } else if (selectedType == MedicationType.gel) {
                          // Gel no lleva dosis habitual.
                          hasDefaultDose = false;
                          defaultNumerator = null;
                          defaultDenominator = null;
                          selectedDefaultKey = '1/1';
                        } else {
                          if (hasDefaultDose) {
                            defaultNumerator ??= 1;
                            defaultDenominator ??= 1;
                            if (defaultDenominator == 0) defaultDenominator = 1;
                            selectedDefaultKey =
                                '$defaultNumerator/$defaultDenominator';
                          }
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 24),

                  // Sección: Dosis habitual (opcional)
                  if (selectedType != MedicationType.gel) ...[
                    const Divider(),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            context.l10n.medicationsDefaultDoseOptional,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Switch(
                          value: hasDefaultDose,
                          onChanged: (value) {
                            setState(() {
                              hasDefaultDose = value;
                              if (!value) {
                                defaultNumerator = null;
                                defaultDenominator = null;
                              } else {
                                defaultNumerator = 1;
                                defaultDenominator = 1;
                              }
                              selectedDefaultKey = hasDefaultDose
                                  ? '${defaultNumerator!}/${defaultDenominator!}'
                                  : '1/1';
                            });
                          },
                        ),
                      ],
                    ),
                    if (hasDefaultDose) ...[
                      const SizedBox(height: 12),
                      Builder(
                        builder: (context) {
                          if (selectedType == MedicationType.drops ||
                              selectedType == MedicationType.capsule) {
                            final current =
                                (defaultNumerator != null &&
                                    (defaultDenominator == 1 ||
                                        defaultDenominator == null))
                                ? defaultNumerator
                                : 1;

                            return DropdownButtonFormField<int>(
                              initialValue: current,
                              decoration: InputDecoration(
                                labelText: selectedType == MedicationType.drops
                                    ? context
                                          .l10n
                                          .medicationsDefaultDoseQtyDrops
                                    : context
                                          .l10n
                                          .medicationsDefaultDoseQtyCapsules,
                                border: const OutlineInputBorder(),
                                prefixIcon: const Icon(Icons.numbers),
                              ),
                              items: List.generate(50, (i) => i + 1)
                                  .map(
                                    (count) => DropdownMenuItem<int>(
                                      value: count,
                                      child: Text(count.toString()),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) {
                                setState(() {
                                  defaultNumerator = value ?? 1;
                                  defaultDenominator = 1;
                                  selectedDefaultKey = '${defaultNumerator!}/1';
                                });
                              },
                            );
                          }

                          // Presets: ¼, ½, ¾, 1, 1½, 2, 2½, 3
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

                          final isPreset = presets.containsKey(
                            selectedDefaultKey,
                          );

                          // Combinar presets + actual en una lista
                          final allFractions = <Map<String, dynamic>>[];

                          presets.forEach((key, _) {
                            final parts = key.split('/');
                            allFractions.add({
                              'key': key,
                              'numerator': int.parse(parts[0]),
                              'denominator': int.parse(parts[1]),
                            });
                          });

                          if (!isPreset) {
                            final parts = selectedDefaultKey.split('/');
                            allFractions.add({
                              'key': selectedDefaultKey,
                              'numerator': int.parse(parts[0]),
                              'denominator': int.parse(parts[1]),
                            });
                          }

                          allFractions.sort((a, b) {
                            final valueA = a['numerator'] / a['denominator'];
                            final valueB = b['numerator'] / b['denominator'];
                            return valueA.compareTo(valueB);
                          });

                          final items = <DropdownMenuItem<String>>[];
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
                                style: TextStyle(
                                  fontStyle: FontStyle.italic,
                                  color: context.statusColors.info,
                                ),
                              ),
                            ),
                          );

                          return DropdownButtonFormField<String>(
                            initialValue: selectedDefaultKey,
                            decoration: InputDecoration(
                              labelText:
                                  context.l10n.medicationsDefaultDoseQtyLabel,
                              border: const OutlineInputBorder(),
                              prefixIcon: const Icon(Icons.medication_liquid),
                            ),
                            items: items,
                            onChanged: (value) async {
                              if (value == 'custom') {
                                final result = await FractionPickerDialog.show(
                                  context,
                                  initialNumerator: defaultNumerator ?? 1,
                                  initialDenominator: defaultDenominator ?? 1,
                                  title: context
                                      .l10n
                                      .medicationsDefaultDosePickerTitle,
                                );
                                if (result != null) {
                                  setState(() {
                                    defaultNumerator = result.numerator;
                                    defaultDenominator = result.denominator;
                                    selectedDefaultKey =
                                        '${result.numerator}/${result.denominator}';
                                  });
                                }
                              } else if (value != null) {
                                final parts = value.split('/');
                                setState(() {
                                  defaultNumerator = int.parse(parts[0]);
                                  defaultDenominator = int.parse(parts[1]);
                                  selectedDefaultKey = value;
                                });
                              }
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      Text(
                        context.l10n.medicationsDefaultDoseHelper,
                        style: TextStyle(
                          fontSize: 12,
                          color: context.neutralColors.grey600,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
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
                  final medicationController = context
                      .read<MedicationController>();
                  try {
                    if (medication == null) {
                      await medicationController.addMedication(
                        nameController.text.trim(),
                        unitController.text.trim(),
                        brandName: brandNameController.text.trim().isEmpty
                            ? null
                            : brandNameController.text.trim(),
                        type: selectedType,
                        defaultDoseNumerator: hasDefaultDose
                            ? defaultNumerator
                            : null,
                        defaultDoseDenominator: hasDefaultDose
                            ? defaultDenominator
                            : null,
                      );
                    } else {
                      await medicationController.updateMedication(
                        medication.copyWith(
                          name: nameController.text.trim(),
                          brandName: brandNameController.text.trim().isEmpty
                              ? null
                              : brandNameController.text.trim(),
                          unit: unitController.text.trim(),
                          type: selectedType,
                          defaultDoseNumerator: hasDefaultDose
                              ? defaultNumerator
                              : null,
                          defaultDoseDenominator: hasDefaultDose
                              ? defaultDenominator
                              : null,
                        ),
                      );
                    }

                    if (context.mounted) {
                      Navigator.pop(context);
                      UIFeedback.showSuccess(
                        context,
                        medication == null
                            ? context.l10n.medicationsSavedAdded
                            : context.l10n.medicationsSavedUpdated,
                      );
                    }
                  } on DatabaseException catch (e) {
                    if (!context.mounted) return;

                    if (e.isUniqueConstraintError()) {
                      Navigator.pop(context);
                      UIFeedback.showWarning(
                        context,
                        context.l10n.medicationsDuplicateWarning,
                      );
                    } else {
                      UIFeedback.showError(
                        context,
                        context.l10n.medicationsDbError(e.toString()),
                      );
                    }
                  } catch (e) {
                    if (!context.mounted) return;
                    UIFeedback.showError(
                      context,
                      context.l10n.medicationsError(e.toString()),
                    );
                  }
                }
              },
              child: Text(context.l10n.commonSave),
            ),
          ],
        ),
      ),
    );
  }

  /// Un solo entry-point (botón "archivo") que ofrece Archivar o Eliminar definitivo.
  Future<void> _confirmArchiveOrDelete(Medication medication) async {
    final action = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.medicationsManageTitle),
        content: Text(context.l10n.medicationsManageBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: Text(context.l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'archive'),
            child: Text(context.l10n.commonArchive),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'delete'),
            style: TextButton.styleFrom(
              foregroundColor: context.statusColors.danger,
            ),
            child: Text(context.l10n.commonDeletePermanently),
          ),
        ],
      ),
    );

    if (!mounted || action == null) return;

    if (action == 'archive') {
      await _archiveMedication(medication);
    } else if (action == 'delete') {
      await _confirmHardDelete(medication);
    }
  }

  Future<void> _archiveMedication(Medication medication) async {
    final medicationController = context.read<MedicationController>();
    try {
      // Cancelar notificaciones programadas de este medicamento
      final reminders = await _remindersRepo.listByMedication(medication.id!);
      for (final r in reminders) {
        await NotificationService.instance.cancelMedicationReminder(r);
      }

      await medicationController.archiveMedication(medication.id!);

      if (mounted) {
        UIFeedback.showSuccess(context, context.l10n.medicationsArchivedSnack);
      }
    } catch (e) {
      if (mounted) {
        UIFeedback.showError(
          context,
          context.l10n.medicationsArchiveError(e.toString()),
        );
      }
    }
  }

  Future<void> _confirmHardDelete(Medication medication) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.medicationsHardDeleteTitle),
        content: Text(context.l10n.medicationsHardDeleteBody(medication.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: context.statusColors.danger,
            ),
            child: Text(context.l10n.commonDelete),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final medicationController = context.read<MedicationController>();

    try {
      // Cancelar notificaciones antes
      final reminders = await _remindersRepo.listByMedication(medication.id!);
      for (final r in reminders) {
        await NotificationService.instance.cancelMedicationReminder(r);
      }

      await medicationController.deleteMedication(medication.id!);

      if (mounted) {
        UIFeedback.showError(context, context.l10n.medicationsDeletedSnack);
      }
    } catch (e) {
      if (mounted) {
        UIFeedback.showError(
          context,
          context.l10n.medicationsDeleteError(e.toString()),
        );
      }
    }
  }

  Future<void> _confirmUnarchive(Medication medication) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.medicationsUnarchiveTitle),
        content: Text(context.l10n.medicationsUnarchiveBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.commonCancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.l10n.medicationsUnarchiveButton),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final medicationController = context.read<MedicationController>();
      try {
        await medicationController.unarchiveMedication(medication.id!);

        // Reprogramar recordatorios existentes (si los hay)
        final fresh = await _medRepo.getMedication(medication.id!);
        if (fresh != null && !fresh.isArchived) {
          final reminders = await _remindersRepo.listByMedication(fresh.id!);
          for (final r in reminders) {
            await NotificationService.instance.scheduleMedicationReminder(
              r,
              fresh,
            );
          }
        }

        if (mounted) {
          UIFeedback.showSuccess(
            context,
            context.l10n.medicationsUnarchivedSnack,
          );
        }
      } catch (e) {
        if (mounted) {
          UIFeedback.showError(
            context,
            context.l10n.medicationsError(e.toString()),
          );
        }
      }
    }
  }
}

// Widget Card expandible para cada medicamento con sus recordatorios
class _MedicationCard extends StatefulWidget {
  final Medication medication;
  final VoidCallback onEdit;
  final VoidCallback onManage;
  final VoidCallback onRefresh;

  const _MedicationCard({
    required this.medication,
    required this.onEdit,
    required this.onManage,
    required this.onRefresh,
  });

  @override
  State<_MedicationCard> createState() => _MedicationCardState();
}

class _MedicationCardState extends State<_MedicationCard> {
  final MedicationRemindersRepository _remindersRepo =
      MedicationRemindersRepository();

  bool _isExpanded = false;
  List<MedicationReminder> _reminders = [];
  bool _isLoadingReminders = false;

  @override
  void initState() {
    super.initState();
    _loadReminders();
  }

  Future<void> _loadReminders() async {
    setState(() => _isLoadingReminders = true);
    final reminders = await _remindersRepo.listByMedication(
      widget.medication.id!,
    );
    if (mounted) {
      setState(() {
        _reminders = reminders;
        _isLoadingReminders = false;
      });
    }
  }

  Future<void> _deleteReminder(MedicationReminder reminder) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.medicationsDeleteReminderTitle),
        content: Text(context.l10n.medicationsDeleteReminderBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: context.statusColors.danger,
            ),
            child: Text(context.l10n.commonDelete),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await NotificationService.instance.cancelMedicationReminder(reminder);
        await _remindersRepo.delete(reminder.id!);
        await _loadReminders();
        if (mounted) {
          UIFeedback.showWarning(
            context,
            context.l10n.medicationsReminderDeletedSnack,
          );
        }
      } catch (e) {
        if (mounted) {
          UIFeedback.showError(
            context,
            context.l10n.medicationsError(e.toString()),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      child: Column(
        children: [
          ListTile(
            leading: Icon(
              Icons.medication,
              color: Theme.of(context).colorScheme.secondary,
              size: 32,
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.medication.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                if (widget.medication.brandName != null)
                  Text(
                    widget.medication.brandName!,
                    style: TextStyle(
                      fontSize: 14,
                      color: context.neutralColors.grey600,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ),
            subtitle: Text(
              '${widget.medication.unit} • ${_medTypeLabel(context, widget.medication.type)}',
            ),
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      MedicationDetailScreen(medication: widget.medication),
                ),
              );
              await _loadReminders();
              widget.onRefresh();
            },
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_reminders.isNotEmpty)
                  Badge(
                    label: Text('${_reminders.length}'),
                    backgroundColor: Theme.of(context).colorScheme.tertiary,
                    child: IconButton(
                      icon: Icon(
                        _isExpanded ? Icons.expand_less : Icons.expand_more,
                      ),
                      onPressed: () =>
                          setState(() => _isExpanded = !_isExpanded),
                      tooltip: l10n.medicationsTooltipViewReminders,
                    ),
                  )
                else
                  IconButton(
                    icon: Icon(
                      _isExpanded ? Icons.expand_less : Icons.expand_more,
                    ),
                    onPressed: () => setState(() => _isExpanded = !_isExpanded),
                    tooltip: l10n.medicationsTooltipViewReminders,
                  ),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: widget.onEdit,
                  tooltip: l10n.medicationsTooltipAdjustDose,
                ),
                IconButton(
                  icon: const Icon(Icons.archive_outlined), // <- ya no rojo
                  onPressed: widget.onManage,
                  tooltip: l10n.medicationsTooltipArchiveDelete,
                ),
              ],
            ),
          ),

          // Sección expandible de recordatorios
          if (_isExpanded)
            Container(
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                border: Border(
                  top: BorderSide(
                    color: scheme.onSurface.withValues(
                      alpha: isDark ? 0.18 : 0.12,
                    ),
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Icon(
                          Icons.alarm,
                          size: 20,
                          color: Theme.of(context).colorScheme.tertiary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          l10n.medicationsRemindersTitle,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const Spacer(),
                        TextButton.icon(
                          icon: const Icon(Icons.add_alarm, size: 18),
                          label: Text(l10n.commonAdd),
                          onPressed: widget.medication.isArchived
                              ? null
                              : () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => AddReminderScreen(
                                        preselectedMedicationId:
                                            widget.medication.id,
                                      ),
                                    ),
                                  );
                                  if (result == true) {
                                    await _loadReminders();
                                    widget.onRefresh();
                                  }
                                },
                        ),
                      ],
                    ),
                  ),
                  if (_isLoadingReminders)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (_reminders.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Center(
                        child: Text(
                          l10n.medicationsNoReminders,
                          style: TextStyle(
                            color: context.neutralColors.grey600,
                          ),
                        ),
                      ),
                    )
                  else
                    ...(_reminders.map((reminder) {
                      return ListTile(
                        dense: true,
                        leading: Icon(
                          Icons.notifications_active,
                          color: Theme.of(context).colorScheme.tertiary,
                        ),
                        title: Text(
                          '${reminder.timeText} • ${reminder.daysText}',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        subtitle: reminder.note != null
                            ? Text(
                                reminder.note!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: context.neutralColors.grey600,
                                ),
                              )
                            : null,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, size: 20),
                              onPressed: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => AddReminderScreen(
                                      reminderToEdit: reminder,
                                    ),
                                  ),
                                );
                                if (result == true) {
                                  await _loadReminders();
                                  widget.onRefresh();
                                }
                              },
                              tooltip: l10n.commonEdit,
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.delete_outline,
                                size: 20,
                                color: scheme.error,
                              ),
                              onPressed: () => _deleteReminder(reminder),
                              tooltip: l10n.commonDelete,
                            ),
                          ],
                        ),
                      );
                    })),
                  const SizedBox(height: 8),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
