import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';

import '../providers/medication_provider.dart';
import '../models/medication.dart';
import '../models/medication_reminder.dart';
import '../services/database_helper.dart';
import '../services/notification_service.dart';
import '../utils/fraction_helper.dart';
import '../widgets/fraction_picker_dialog.dart';
import 'medication_detail_screen.dart';
import 'add_reminder_screen.dart';
import 'medication_groups_screen.dart';

class MedicationsScreen extends StatefulWidget {
  const MedicationsScreen({super.key});

  @override
  State<MedicationsScreen> createState() => _MedicationsScreenState();
}

class _MedicationsScreenState extends State<MedicationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MedicationProvider>().loadMedications();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Medicamentos'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.groups),
            label: const Text('Agrupar'),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const MedicationGroupsScreen(),
                ),
              );
              if (!context.mounted) return;
              await context.read<MedicationProvider>().loadMedications();
            },
          ),
        ],
      ),
      body: Consumer<MedicationProvider>(
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
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No hay medicamentos',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Agrega uno con el botón +',
                    style: TextStyle(color: Colors.grey[500]),
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
                    title: Text('Archivados (${archived.length})'),
                    children: [
                      for (final med in archived)
                        ListTile(
                          leading: const Icon(Icons.medication_outlined),
                          title: Text(med.name),
                          subtitle: Text(
                            '${med.unit} • ${med.type.displayName}',
                          ),
                          trailing: TextButton(
                            onPressed: () => _confirmUnarchive(med),
                            child: const Text('Reactivar'),
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
        label: const Text('Agregar'),
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

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(
            medication == null ? 'Agregar medicamento' : 'Editar medicamento',
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
                    decoration: const InputDecoration(
                      labelText: 'Nombre genérico *',
                      hintText: 'Ej: Ibuprofeno',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'El nombre genérico es obligatorio';
                      }
                      return null;
                    },
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 16),

                  // Nombre comercial (opcional)
                  TextFormField(
                    controller: brandNameController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre comercial (opcional)',
                      hintText: 'Ej: Ibupirac',
                    ),
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 16),

                  // Unidad base
                  TextFormField(
                    controller: unitController,
                    decoration: const InputDecoration(
                      labelText: 'Unidad base *',
                      hintText: 'Ej: 1mg, 2mg, 10ml',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'La unidad base es obligatoria';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Tipo de medicación
                  DropdownButtonFormField<MedicationType>(
                    initialValue: selectedType,
                    decoration: const InputDecoration(
                      labelText: 'Tipo *',
                      border: OutlineInputBorder(),
                    ),
                    items: MedicationType.values.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Text(type.displayName),
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
                  const Divider(),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Dosis habitual (opcional)',
                          style: TextStyle(
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
                                  ? 'Cantidad habitual (gotas)'
                                  : 'Cantidad habitual (cápsulas)',
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
                          const DropdownMenuItem(
                            value: 'custom',
                            child: Text(
                              'Personalizada…',
                              style: TextStyle(
                                fontStyle: FontStyle.italic,
                                color: Colors.blue,
                              ),
                            ),
                          ),
                        );

                        return DropdownButtonFormField<String>(
                          initialValue: selectedDefaultKey,
                          decoration: const InputDecoration(
                            labelText: 'Cantidad habitual',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.medication_liquid),
                          ),
                          items: items,
                          onChanged: (value) async {
                            if (value == 'custom') {
                              final result = await FractionPickerDialog.show(
                                context,
                                initialNumerator: defaultNumerator ?? 1,
                                initialDenominator: defaultDenominator ?? 1,
                                title: 'Dosis habitual',
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
                      'Esta cantidad se precargará al registrar tomas',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final provider = context.read<MedicationProvider>();
                  try {
                    if (medication == null) {
                      await provider.addMedication(
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
                      await provider.updateMedication(
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
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            medication == null
                                ? 'Medicamento agregado'
                                : 'Medicamento actualizado',
                          ),
                        ),
                      );
                    }
                  } on DatabaseException catch (e) {
                    if (!context.mounted) return;

                    if (e.isUniqueConstraintError()) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Ya existe una medicación igual cargada. Podés editarla desde la lista.',
                          ),
                          backgroundColor: Colors.orange,
                          duration: Duration(seconds: 4),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Error de base de datos: ${e.toString()}',
                          ),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  } catch (e) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                }
              },
              child: const Text('Guardar'),
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
        title: const Text('Gestionar medicamento'),
        content: const Text(
          'Elegí qué querés hacer:\n\n'
          '• Archivar: no borra registros históricos y pausa recordatorios.\n'
          '• Eliminar definitivamente: borra el medicamento y todos sus registros asociados.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'archive'),
            child: const Text('Archivar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'delete'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar definitivamente'),
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
    final provider = context.read<MedicationProvider>();
    try {
      // Cancelar notificaciones programadas de este medicamento
      final reminders = await DatabaseHelper.instance.getRemindersByMedication(
        medication.id!,
      );
      for (final r in reminders) {
        await NotificationService.instance.cancelMedicationReminder(r);
      }

      await provider.archiveMedication(medication.id!);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Medicamento archivado')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al archivar: $e')));
      }
    }
  }

  Future<void> _confirmHardDelete(Medication medication) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar definitivamente'),
        content: Text(
          'Esta acción NO se puede deshacer.\n\n'
          'Se eliminará:\n'
          '• ${medication.name}\n'
          '• todos los registros históricos asociados\n'
          '• recordatorios\n\n'
          '¿Querés continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final provider = context.read<MedicationProvider>();

    try {
      // Cancelar notificaciones antes
      final reminders = await DatabaseHelper.instance.getRemindersByMedication(
        medication.id!,
      );
      for (final r in reminders) {
        await NotificationService.instance.cancelMedicationReminder(r);
      }

      await provider.deleteMedication(medication.id!);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Medicamento eliminado definitivamente'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al eliminar: $e')));
      }
    }
  }

  Future<void> _confirmUnarchive(Medication medication) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reactivar medicamento'),
        content: const Text(
          '¿Reactivar este medicamento?\n\n'
          'Volverá a aparecer en la lista y en los selectores.\n'
          'Los recordatorios que tuviera configurados se reprogramarán.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reactivar'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final provider = context.read<MedicationProvider>();
      try {
        await provider.unarchiveMedication(medication.id!);

        // Reprogramar recordatorios existentes (si los hay)
        final fresh = await DatabaseHelper.instance.getMedication(
          medication.id!,
        );
        if (fresh != null && !fresh.isArchived) {
          final reminders = await DatabaseHelper.instance
              .getRemindersByMedication(fresh.id!);
          for (final r in reminders) {
            await NotificationService.instance.scheduleMedicationReminder(
              r,
              fresh,
            );
          }
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Medicamento reactivado')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: $e')));
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
    final reminders = await DatabaseHelper.instance.getRemindersByMedication(
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
        title: const Text('Eliminar recordatorio'),
        content: const Text('¿Estás seguro de eliminar este recordatorio?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await NotificationService.instance.cancelMedicationReminder(reminder);
        await DatabaseHelper.instance.deleteReminder(reminder.id!);
        await _loadReminders();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('🗑️ Recordatorio eliminado'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ),
            subtitle: Text(
              '${widget.medication.unit} • ${widget.medication.type.displayName}',
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
                      tooltip: 'Ver recordatorios',
                    ),
                  )
                else
                  IconButton(
                    icon: Icon(
                      _isExpanded ? Icons.expand_less : Icons.expand_more,
                    ),
                    onPressed: () => setState(() => _isExpanded = !_isExpanded),
                    tooltip: 'Ver recordatorios',
                  ),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: widget.onEdit,
                  tooltip: 'Ajustar dosis',
                ),
                IconButton(
                  icon: const Icon(Icons.archive_outlined), // <- ya no rojo
                  onPressed: widget.onManage,
                  tooltip: 'Archivar / Eliminar',
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
                        const Text(
                          'Recordatorios',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const Spacer(),
                        TextButton.icon(
                          icon: const Icon(Icons.add_alarm, size: 18),
                          label: const Text('Agregar'),
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
                          'Sin recordatorios',
                          style: TextStyle(color: Colors.grey[600]),
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
                                  color: Colors.grey[600],
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
                              tooltip: 'Editar',
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.delete_outline,
                                size: 20,
                                color: scheme.error,
                              ),
                              onPressed: () => _deleteReminder(reminder),
                              tooltip: 'Eliminar',
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
