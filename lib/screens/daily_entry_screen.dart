import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:collection/collection.dart';

import '../services/database_helper.dart';
import '../providers/sleep_entry_provider.dart';
import '../providers/medication_provider.dart';
import '../models/intake_event.dart';
import '../models/medication.dart';
import '../utils/fraction_helper.dart';
import '../widgets/fraction_picker_dialog.dart';
import '../ui/theme_helpers.dart';

class DailyEntryScreen extends StatefulWidget {
  final DateTime selectedDate;
  final int initialTabIndex;

  const DailyEntryScreen({
    super.key,
    required this.selectedDate,
    this.initialTabIndex = 1,
  }) : assert(initialTabIndex >= 0 && initialTabIndex < 3);

  @override
  State<DailyEntryScreen> createState() => _DailyEntryScreenState();
}

class _DailyEntryScreenState extends State<DailyEntryScreen>
    with SingleTickerProviderStateMixin {
  int? _dayMood; // 1..5 (opcional)
  bool _dayDetailsExpanded = false;
  final TextEditingController _dayNotesController = TextEditingController();

  int? _sleepQuality;
  final TextEditingController _notesController = TextEditingController();
  int? _sleepDurationHours;
  int? _sleepDurationMinutes;
  int? _sleepContinuity; // 1=corrido, 2=cortado
  bool _sleepDetailsExpanded = false;

  final List<_IntakeEventInput> _intakeEvents = [];
  final Set<int> _expandedIntakeEventIndices = <int>{};

  bool _isLoading = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
    _loadExistingEntry();
  }

  Future<void> _loadExistingEntry() async {
    final provider = context.read<SleepEntryProvider>();
    final medProvider = context.read<MedicationProvider>();

    await medProvider.loadMedications();

    final entry = await provider.getEntryByDate(widget.selectedDate);

    if (entry != null && mounted) {
      setState(() {
        _sleepQuality = entry.sleepQuality;
        _notesController.text = entry.notes ?? '';

        final total = entry.sleepDurationMinutes;
        if (total != null && total > 0) {
          _sleepDurationHours = total ~/ 60;
          _sleepDurationMinutes = total % 60;
          _sleepDetailsExpanded = true;
        } else {
          _sleepDurationHours = null;
          _sleepDurationMinutes = null;
        }

        _sleepContinuity = entry.sleepContinuity;
        if (_sleepContinuity != null) {
          _sleepDetailsExpanded = true;
        }
      });
    }

    final db = DatabaseHelper.instance;
    final dayEntry = await db.ensureDayEntry(widget.selectedDate);
    final events = await provider.getEventsForDayEntry(dayEntry.id!);
    final dayMood = await db.getDayMoodByDate(widget.selectedDate);
    final dayNotes = await db.getDayNotesByDate(widget.selectedDate);

    if (mounted) {
      setState(() {
        _intakeEvents.clear();
        _expandedIntakeEventIndices.clear();
        for (var event in events) {
          _intakeEvents.add(_IntakeEventInput.fromIntakeEvent(event));
        }
        _dayMood = dayMood;
        _dayNotesController.text = dayNotes ?? '';
        if (_dayNotesController.text.trim().isNotEmpty) {
          _dayDetailsExpanded = true;
        }
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _dayNotesController.dispose();
    _notesController.dispose();
    for (var event in _intakeEvents) {
      event.dispose();
    }
    super.dispose();
  }

  void _addIntakeEvent() {
    final base = widget.selectedDate;
    final now = DateTime.now();

    setState(() {
      _intakeEvents.add(
        _IntakeEventInput(
          takenAt: DateTime(
            base.year,
            base.month,
            base.day,
            now.hour,
            now.minute,
          ),
          medicationId: null,
          numerator: 1,
          denominator: 1,
        ),
      );
      _expandedIntakeEventIndices.add(_intakeEvents.length - 1);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Medicación agregada'),
        duration: Duration(milliseconds: 800),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _removeIntakeEvent(int index) {
    setState(() {
      _intakeEvents[index].dispose();
      _intakeEvents.removeAt(index);

      final updated = <int>{};
      for (final i in _expandedIntakeEventIndices) {
        if (i == index) continue;
        updated.add(i > index ? i - 1 : i);
      }
      _expandedIntakeEventIndices
        ..clear()
        ..addAll(updated);
    });
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('d MMMM yyyy', 'es_ES');
    final yesterday = widget.selectedDate.subtract(const Duration(days: 1));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrar tu día'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.emoji_emotions), text: 'Día (opcional)'),
            Tab(icon: Icon(Icons.bedtime), text: 'Sueño (opcional)'),
            Tab(icon: Icon(Icons.medication), text: 'Medicación'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildDayTab(dateFormat),
                _buildSleepTab(dateFormat, yesterday),
                _buildMedicationTab(),
              ],
            ),
    );
  }

  Widget _buildDayTab(DateFormat dateFormat) {
    final items = <({int v, IconData icon, String label})>[
      (v: 1, icon: Icons.sentiment_very_dissatisfied, label: 'Muy mal'),
      (v: 2, icon: Icons.sentiment_dissatisfied, label: 'Mal'),
      (v: 3, icon: Icons.sentiment_neutral, label: 'Regular'),
      (v: 4, icon: Icons.sentiment_satisfied, label: 'Bien'),
      (v: 5, icon: Icons.sentiment_very_satisfied, label: 'Muy bien'),
    ];

    final labelMuted = muted(context, 0.60);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  const Icon(Icons.today, size: 32),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Día ${dateFormat.format(widget.selectedDate)}',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Cómo te sentís hoy?',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      for (final it in items)
                        _MoodButton(
                          icon: it.icon,
                          mood: it.v,
                          selected: _dayMood == it.v,
                          onTap: () {
                            setState(() {
                              _dayMood = (_dayMood == it.v) ? null : it.v;
                            });
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _dayMood == null
                        ? 'Sin registrar'
                        : items.firstWhere((e) => e.v == _dayMood).label,
                    style: TextStyle(color: labelMuted, fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Card(
            child: ExpansionTile(
              initiallyExpanded: _dayDetailsExpanded,
              onExpansionChanged: (v) {
                setState(() {
                  _dayDetailsExpanded = v;
                });
              },
              leading: const Icon(Icons.more_horiz),
              title: const Text('Detalles (opcional)'),
              subtitle: Text(() {
                final hasNotes = _dayNotesController.text.trim().isNotEmpty;
                return hasNotes ? 'Nota guardada' : 'Sin completar';
              }(), style: TextStyle(color: muted(context, 0.70), fontSize: 12)),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Notas del día',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _dayNotesController,
                        maxLines: 3,
                        textCapitalization: TextCapitalization.sentences,
                        onChanged: (_) => setState(() {}),
                        decoration: const InputDecoration(
                          hintText: 'Algo para recordar sobre el día...',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _saveEntry,
              icon: const Icon(Icons.save),
              label: const Text('Guardar'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSleepTab(DateFormat dateFormat, DateTime yesterday) {
    final cs = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  const Icon(Icons.bedtime, size: 32),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Noche del ${dateFormat.format(widget.selectedDate)}',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        Text(
                          '(${yesterday.day}→${widget.selectedDate.day})',
                          style: TextStyle(
                            color: muted(context, 0.60),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Cómo dormiste?',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final star = index + 1;
                      final isOn = star <= (_sleepQuality ?? 0);
                      return IconButton(
                        iconSize: 40,
                        icon: Icon(
                          isOn ? Icons.star : Icons.star_border,
                          color: isOn ? cs.primary : muted(context, 0.25),
                        ),
                        onPressed: () {
                          setState(() {
                            _sleepQuality = star;
                          });
                        },
                      );
                    }),
                  ),
                  Text(
                    _getSleepQualityLabel(_sleepQuality),
                    style: TextStyle(color: muted(context, 0.60), fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Card(
            child: ExpansionTile(
              initiallyExpanded: _sleepDetailsExpanded,
              onExpansionChanged: (v) {
                setState(() {
                  _sleepDetailsExpanded = v;
                });
              },
              leading: const Icon(Icons.more_horiz),
              title: const Text('Detalles (opcional)'),
              subtitle: Text(() {
                final parts = <String>[];
                final h = _sleepDurationHours;
                final m = _sleepDurationMinutes;
                if (h != null || m != null) {
                  final hh = h ?? 0;
                  final mm = m ?? 0;
                  if (!(hh == 0 && mm == 0)) {
                    final mm2 = mm.toString().padLeft(2, '0');
                    parts.add('${hh}h ${mm2}m');
                  }
                }
                if (_sleepContinuity == 1) parts.add('De corrido');
                if (_sleepContinuity == 2) parts.add('Cortado');
                return parts.isEmpty ? 'Sin completar' : parts.join(' • ');
              }(), style: TextStyle(color: muted(context, 0.70), fontSize: 12)),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '¿Cuánto dormiste?',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<int?>(
                              key: ValueKey(_sleepDurationHours),
                              initialValue: _sleepDurationHours,
                              decoration: const InputDecoration(
                                labelText: 'Horas',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              items: [
                                const DropdownMenuItem<int?>(
                                  value: null,
                                  child: Text('—'),
                                ),
                                for (final h in List<int>.generate(
                                  15,
                                  (i) => i,
                                ))
                                  DropdownMenuItem<int?>(
                                    value: h,
                                    child: Text('$h'),
                                  ),
                              ],
                              onChanged: (v) {
                                setState(() => _sleepDurationHours = v);
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<int?>(
                              key: ValueKey(_sleepDurationMinutes),
                              initialValue: _sleepDurationMinutes,
                              decoration: const InputDecoration(
                                labelText: 'Minutos',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              items: [
                                const DropdownMenuItem<int?>(
                                  value: null,
                                  child: Text('—'),
                                ),
                                for (final m in const [0, 10, 20, 30, 40, 50])
                                  DropdownMenuItem<int?>(
                                    value: m,
                                    child: Text(m.toString().padLeft(2, '0')),
                                  ),
                              ],
                              onChanged: (v) {
                                setState(() => _sleepDurationMinutes = v);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        '¿Cómo fue el sueño?',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ChoiceChip(
                            label: const Text('De corrido'),
                            selected: _sleepContinuity == 1,
                            onSelected: (v) {
                              setState(() {
                                _sleepContinuity = v ? 1 : null;
                              });
                            },
                          ),
                          ChoiceChip(
                            label: const Text('Cortado'),
                            selected: _sleepContinuity == 2,
                            onSelected: (v) {
                              setState(() {
                                _sleepContinuity = v ? 2 : null;
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Opcional: si no querés, dejalo vacío.',
                        style: TextStyle(
                          color: muted(context, 0.60),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Notas generales (opcional)',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notesController,
            maxLines: 4,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              hintText: 'Algo para recordar mañana...',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _saveEntry,
              icon: const Icon(Icons.save),
              label: const Text('Guardar'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicationTab() {
    final hasEvents = _intakeEvents.isNotEmpty;

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
                        _intakeEvents.isNotEmpty &&
                        _expandedIntakeEventIndices.length ==
                            _intakeEvents.length;

                    return TextButton.icon(
                      onPressed: () {
                        setState(() {
                          if (allExpanded) {
                            _expandedIntakeEventIndices.clear();
                          } else {
                            _expandedIntakeEventIndices
                              ..clear()
                              ..addAll(
                                List.generate(_intakeEvents.length, (i) => i),
                              );
                          }
                        });
                      },
                      icon: Icon(
                        allExpanded ? Icons.unfold_less : Icons.unfold_more,
                      ),
                      label: Text(
                        allExpanded ? 'Contraer todo' : 'Expandir todo',
                      ),
                    );
                  },
                ),
                const Spacer(),
                Text(
                  '${_intakeEvents.length}',
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
                          'Sin medicamentos registrados',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: muted(context, 0.70),
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Presiona el botón + para agregar',
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
                  itemCount: _intakeEvents.length,
                  itemBuilder: (context, index) {
                    return _IntakeEventCard(
                      key: ValueKey(index),
                      event: _intakeEvents[index],
                      index: index,
                      isExpanded: _expandedIntakeEventIndices.contains(index),
                      onExpandedChanged: (expanded) {
                        setState(() {
                          if (expanded) {
                            _expandedIntakeEventIndices.add(index);
                          } else {
                            _expandedIntakeEventIndices.remove(index);
                          }
                        });
                      },
                      onRemove: () => _removeIntakeEvent(index),
                      onDoseChanged: (numerator, denominator) {
                        setState(() {
                          _intakeEvents[index].numerator = numerator;
                          _intakeEvents[index].denominator = denominator;
                        });
                      },
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
                color: Colors.black.withValues(alpha: 0.10),
                blurRadius: 4,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _addIntakeEvent,
                  icon: const Icon(Icons.add),
                  label: const Text('Agregar medicación'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: _saveEntry,
                icon: const Icon(Icons.save),
                label: const Text('Guardar'),
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

  String _getSleepQualityLabel(int? quality) {
    if (quality == null) return 'Sin registrar';
    switch (quality) {
      case 1:
        return 'Muy mal';
      case 2:
        return 'Mal';
      case 3:
        return 'Regular';
      case 4:
        return 'Bien';
      case 5:
        return 'Muy bien';
      default:
        return '';
    }
  }

  Future<void> _saveEntry() async {
    final provider = context.read<SleepEntryProvider>();
    final medProvider = context.read<MedicationProvider>();
    final messenger = ScaffoldMessenger.of(context);

    try {
      await DatabaseHelper.instance.saveDayMoodForDay(
        widget.selectedDate,
        _dayMood,
      );
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text('Error guardando mood: $e')),
        );
      }
    }

    try {
      final notes = _dayNotesController.text.trim().isEmpty
          ? null
          : _dayNotesController.text.trim();
      await DatabaseHelper.instance.saveDayNotesForDay(
        widget.selectedDate,
        notes,
      );
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text('Error guardando notas del día: $e')),
        );
      }
    }

    if (!mounted) return;

    for (var i = 0; i < _intakeEvents.length; i++) {
      if (_intakeEvents[i].medicationId == null) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              'Por favor selecciona el medicamento en el evento ${i + 1}',
            ),
          ),
        );
        return;
      }

      final medId = _intakeEvents[i].medicationId;
      final medication = medId == null
          ? null
          : medProvider.allMedications.firstWhereOrNull((m) => m.id == medId);
      final medicationType = medication?.type;

      final num = _intakeEvents[i].numerator;
      final den = _intakeEvents[i].denominator;
      final isUnknown = num == null && den == null;

      final isValidKnown =
          medicationType == MedicationType.drops ||
              medicationType == MedicationType.capsule
          ? (num != null && den == 1 && num > 0)
          : (num != null && den != null && num > 0 && den > 0);

      if (!(isUnknown || isValidKnown)) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              (medicationType == MedicationType.drops ||
                      medicationType == MedicationType.capsule)
                  ? 'La cantidad del evento ${i + 1} es inválida. Elegí “Sin dosis” o un entero válido.'
                  : 'La cantidad del evento ${i + 1} es inválida. Elegí “Sin dosis” o una fracción válida.',
            ),
          ),
        );
        return;
      }
    }

    final events = _intakeEvents
        .map(
          (input) => IntakeEvent(
            dayEntryId: null,
            medicationId: input.medicationId!,
            takenAt: input.takenAt,
            amountNumerator: input.numerator,
            amountDenominator: input.denominator,
            note: input.noteController.text.trim().isEmpty
                ? null
                : input.noteController.text.trim(),
          ),
        )
        .toList();

    try {
      int? durationMinutes;
      if (_sleepDurationHours != null || _sleepDurationMinutes != null) {
        final hh = _sleepDurationHours ?? 0;
        final mm = _sleepDurationMinutes ?? 0;
        final total = (hh * 60) + mm;
        durationMinutes = total <= 0 ? null : total;
      }

      final notes = _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim();

      final hasAnySleepDetails =
          notes != null || durationMinutes != null || _sleepContinuity != null;

      if (_sleepQuality == null && hasAnySleepDetails) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text(
              'Para guardar el sueño, elegí “Cómo dormiste” (1–5) o borrá los detalles.',
            ),
          ),
        );
        return;
      }

      await provider.saveSleepEntry(
        nightDate: widget.selectedDate,
        sleepQuality: _sleepQuality,
        notes: notes,
        sleepDurationMinutes: durationMinutes,
        sleepContinuity: _sleepContinuity,
        intakeEvents: events,
      );

      if (mounted) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Registro guardado correctamente')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(SnackBar(content: Text('Error al guardar: $e')));
      }
    }
  }
}

class _IntakeEventInput {
  DateTime takenAt;
  int? medicationId;
  int? numerator;
  int? denominator;
  final TextEditingController noteController;

  _IntakeEventInput({
    required this.takenAt,
    this.medicationId,
    required this.numerator,
    required this.denominator,
  }) : noteController = TextEditingController();

  factory _IntakeEventInput.fromIntakeEvent(IntakeEvent event) {
    return _IntakeEventInput(
      takenAt: event.takenAt,
      medicationId: event.medicationId,
      numerator: event.amountNumerator,
      denominator: event.amountDenominator,
    )..noteController.text = event.note ?? '';
  }

  void dispose() {
    noteController.dispose();
  }
}

class _IntakeEventCard extends StatefulWidget {
  final _IntakeEventInput event;
  final int index;
  final VoidCallback onRemove;
  final void Function(int? numerator, int? denominator) onDoseChanged;
  final bool isExpanded;
  final ValueChanged<bool> onExpandedChanged;

  const _IntakeEventCard({
    super.key,
    required this.event,
    required this.index,
    required this.onRemove,
    required this.onDoseChanged,
    required this.isExpanded,
    required this.onExpandedChanged,
  });

  @override
  State<_IntakeEventCard> createState() => _IntakeEventCardState();
}

class _MoodButton extends StatelessWidget {
  final IconData icon;
  final int mood;
  final bool selected;
  final VoidCallback onTap;

  const _MoodButton({
    required this.icon,
    required this.mood,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final background = moodBg(context, mood, selected: selected);
    final border = moodBorder(context, mood, selected: selected);
    final iconColor = moodIconColor(context, mood, selected: selected);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: background,
          shape: BoxShape.circle,
          border: Border.all(color: border, width: selected ? 2.2 : 1.4),
        ),
        child: Icon(icon, size: 32, color: iconColor),
      ),
    );
  }
}

class _IntakeEventCardState extends State<_IntakeEventCard> {
  late String _selectedKey;
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _selectedKey =
        (widget.event.numerator == null || widget.event.denominator == null)
        ? 'unknown'
        : '${widget.event.numerator}/${widget.event.denominator}';
    _isExpanded = widget.isExpanded;
  }

  @override
  void didUpdateWidget(covariant _IntakeEventCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isExpanded != widget.isExpanded) {
      _isExpanded = widget.isExpanded;
    }
  }

  void _toggleExpanded() {
    final next = !_isExpanded;
    setState(() {
      _isExpanded = next;
    });
    widget.onExpandedChanged(next);
  }

  String _doseSummary(MedicationType medicationType) {
    final num = widget.event.numerator;
    final den = widget.event.denominator;
    if (num == null || den == null) return 'Sin dosis';

    if (medicationType == MedicationType.drops) {
      return num == 1 ? '1 gota' : '$num gotas';
    }
    if (medicationType == MedicationType.capsule) {
      return num == 1 ? '1 cápsula' : '$num cápsulas';
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
      const DropdownMenuItem(value: 'unknown', child: Text('Sin dosis (—)')),
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
          'Personalizada…',
          style: TextStyle(fontStyle: FontStyle.italic, color: cs.primary),
        ),
      ),
    );

    return DropdownButtonFormField<String>(
      initialValue: _selectedKey,
      decoration: const InputDecoration(
        labelText: 'Cantidad',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.format_list_numbered),
      ),
      items: items,
      onChanged: (value) async {
        if (value == 'unknown') {
          setState(() {
            _selectedKey = 'unknown';
          });
          widget.onDoseChanged(null, null);
          return;
        }

        if (value == 'custom') {
          final result = await FractionPickerDialog.show(
            context,
            initialNumerator: widget.event.numerator ?? 1,
            initialDenominator: widget.event.denominator ?? 1,
            title: 'Cantidad personalizada',
          );
          if (result != null) {
            final newKey = '${result.numerator}/${result.denominator}';
            setState(() {
              _selectedKey = newKey;
            });
            widget.onDoseChanged(result.numerator, result.denominator);
          }
        } else if (value != null) {
          final parts = value.split('/');
          setState(() {
            _selectedKey = value;
          });
          widget.onDoseChanged(int.parse(parts[0]), int.parse(parts[1]));
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

    setState(() {
      widget.event.takenAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
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
          title: const Text('Agregar Medicamento'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre genérico *',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Ingresá el nombre';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: brandNameController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre comercial (opcional)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: unitController,
                    decoration: const InputDecoration(
                      labelText: 'Unidad base *',
                      hintText: 'Ej: 1mg, 2mg, 10ml',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'La unidad base es obligatoria';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
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
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  try {
                    final provider = context.read<MedicationProvider>();
                    await provider.addMedication(
                      nameController.text.trim(),
                      unitController.text.trim(),
                      brandName: brandNameController.text.trim().isEmpty
                          ? null
                          : brandNameController.text.trim(),
                      type: selectedType,
                    );

                    final medications = provider.medications;
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
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text('Error: $e')));
                    }
                  }
                }
              },
              child: const Text('Agregar'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final timeFormat = DateFormat('HH:mm', 'es_ES');
    final medProvider = context.watch<MedicationProvider>();
    final medications = medProvider.medications; // activos
    final allMedications = medProvider.allMedications; // incluye archivados

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
        ? 'Sin medicamento'
        : '${selectedMedication.name} (${selectedMedication.unit})';
    final doseSummary = _doseSummary(medicationType);
    final timeSummary = timeFormat.format(widget.event.takenAt);
    final hasNote = widget.event.noteController.text.trim().isNotEmpty;

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
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        'Toma ${widget.index + 1}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: _isExpanded ? 'Contraer' : 'Expandir',
                  icon: AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 150),
                    child: const Icon(Icons.expand_more),
                  ),
                  onPressed: _toggleExpanded,
                ),
                IconButton(
                  icon: Icon(Icons.delete, color: cs.error),
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Eliminar registro'),
                        content: Text('¿Eliminar la toma ${widget.index + 1}?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancelar'),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context, true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: cs.error,
                              foregroundColor: cs.onError,
                            ),
                            child: const Text('Eliminar'),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true && mounted) {
                      widget.onRemove();
                    }
                  },
                  tooltip: 'Eliminar',
                ),
              ],
            ),
            if (!_isExpanded) ...[
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          medicationSummary,
                          style: TextStyle(color: muted(context, 0.85)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$timeSummary • $doseSummary${hasNote ? ' • Nota' : ''}',
                          style: TextStyle(color: muted(context, 0.60)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 180),
              crossFadeState: _isExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              firstChild: const SizedBox.shrink(),
              secondChild: Column(
                children: [
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int?>(
                    key: ValueKey('med_$safeMedicationId'),
                    initialValue: safeMedicationId,
                    decoration: const InputDecoration(
                      labelText: 'Medicamento',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.medication),
                    ),
                    items: [
                      ...medications.where((m) => m.id != null).map((med) {
                        return DropdownMenuItem<int?>(
                          value: med.id,
                          child: Text('${med.name} (${med.unit})'),
                        );
                      }),
                      if (selectedMedication != null &&
                          selectedMedication.isArchived)
                        DropdownMenuItem<int?>(
                          value: selectedMedication.id,
                          child: Text(
                            '${selectedMedication.name} (${selectedMedication.unit}) (Archivado)',
                            style: TextStyle(color: muted(context, 0.70)),
                          ),
                        ),
                      DropdownMenuItem<int?>(
                        value: -1,
                        child: Text(
                          '+ Agregar otro',
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
                            widget.event.medicationId = newMed.id;

                            if (newMed.defaultDoseNumerator != null &&
                                newMed.defaultDoseDenominator != null &&
                                newMed.defaultDoseDenominator! > 0) {
                              final newKey =
                                  '${newMed.defaultDoseNumerator}/${newMed.defaultDoseDenominator}';
                              _selectedKey = newKey;
                              widget.onDoseChanged(
                                newMed.defaultDoseNumerator!,
                                newMed.defaultDoseDenominator!,
                              );
                            } else {
                              _selectedKey = 'unknown';
                              widget.onDoseChanged(null, null);
                            }
                          });
                        } else {
                          setState(() {});
                        }
                      } else {
                        setState(() {
                          widget.event.medicationId = value;

                          if (value != null) {
                            final medication = medications.firstWhere(
                              (m) => m.id == value,
                            );
                            if (medication.defaultDoseNumerator != null &&
                                medication.defaultDoseDenominator != null &&
                                medication.defaultDoseDenominator! > 0) {
                              final newKey =
                                  '${medication.defaultDoseNumerator}/${medication.defaultDoseDenominator}';
                              _selectedKey = newKey;
                              widget.onDoseChanged(
                                medication.defaultDoseNumerator!,
                                medication.defaultDoseDenominator!,
                              );
                            } else {
                              _selectedKey = 'unknown';
                              widget.onDoseChanged(null, null);
                            }
                          }
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.access_time),
                    title: const Text('Hora'),
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
                            ? 'Cantidad de gotas'
                            : 'Cantidad de cápsulas',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.numbers),
                      ),
                      items: [
                        const DropdownMenuItem<int?>(
                          value: null,
                          child: Text('Sin dosis (—)'),
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
                          widget.onDoseChanged(null, null);
                          setState(() => _selectedKey = 'unknown');
                          return;
                        }
                        widget.onDoseChanged(value, 1);
                        setState(() => _selectedKey = '$value/1');
                      },
                    )
                  else
                    _buildFractionDropdown(),
                  const SizedBox(height: 12),
                  TextField(
                    controller: widget.event.noteController,
                    maxLines: 2,
                    textCapitalization: TextCapitalization.sentences,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      labelText: 'Nota (opcional)',
                      hintText: 'Efectos, contexto...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
