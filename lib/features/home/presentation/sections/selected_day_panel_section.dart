import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../l10n/l10n.dart';
import '../../../../models/intake_event.dart';
import '../../../../models/medication.dart';
import '../../../../models/sleep_entry.dart';
import '../../../medication/state/medication_controller.dart';
import '../../../sleep/state/sleep_controller.dart';
import '../../../../ui/theme_helpers.dart';
import '../../../../utils/fraction_helper.dart';
import '../../../daily_entry/presentation/screens/daily_entry_screen.dart';
import '../../state/calendar_filter.dart';
import '../../state/home_controller.dart';

class SelectedDayPanelSection extends StatelessWidget {
  final SleepController sleepController;
  final MedicationController medicationController;
  final DateFormat dateFormat;

  const SelectedDayPanelSection({
    super.key,
    required this.sleepController,
    required this.medicationController,
    required this.dateFormat,
  });

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final home = context.watch<HomeController>();

    return FutureBuilder<SleepEntry?>(
      future: sleepController.getEntryByDate(home.selectedDay),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final entry = snapshot.data;
        final selected = home.selectedDayData;
        final dayOnly = _dateOnly(home.selectedDay);

        if (!home.isLoadingSelectedDay &&
            (selected == null || selected.day != dayOnly)) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!context.mounted) return;
            context.read<HomeController>().loadSelectedDay(dayOnly);
          });
        }

        if (home.isLoadingSelectedDay ||
            selected == null ||
            selected.day != dayOnly) {
          return const Center(child: CircularProgressIndicator());
        }

        final dayEntry = selected.dayEntry;
        final events = selected.intakeEvents;

        final mood = dayEntry.dayMood;
        final blocksWalked = dayEntry.blocksWalked;
        final dayNotes = dayEntry.dayNotes;
        final waterCount = (dayEntry.waterCount ?? 0).clamp(0, 10);

        final hasAnyData =
            entry != null ||
            events.isNotEmpty ||
            mood != null ||
            blocksWalked != null ||
            ((dayNotes ?? '').trim().isNotEmpty) ||
            waterCount > 0;

        final filter = context.watch<HomeController>().calendarFilter;
        final showMoodSection =
            filter == CalendarFilter.all || filter == CalendarFilter.mood;
        final showHabitsSection =
            filter == CalendarFilter.all || filter == CalendarFilter.habits;
        final showSleep =
            filter == CalendarFilter.all || filter == CalendarFilter.sleep;
        final showMeds =
            filter == CalendarFilter.all || filter == CalendarFilter.medication;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.dayTabHeader(
                            dateFormat.format(home.selectedDay),
                          ),
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 10),
                        _DayChips(
                          sleepEntry: entry,
                          mood: mood,
                          waterCount: waterCount,
                          intakesCount: events.length,
                        ),
                      ],
                    ),
                  ),
                  if (hasAnyData)
                    IconButton(
                      tooltip: l10n.selectedDayDeleteTooltip,
                      icon: Icon(
                        Icons.delete,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text(
                              context.l10n.selectedDayDeleteDialogTitle,
                            ),
                            content: Text(
                              context.l10n.selectedDayDeleteDialogBody,
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: Text(context.l10n.commonCancel),
                              ),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: Text(context.l10n.commonDelete),
                              ),
                            ],
                          ),
                        );

                        if (confirm == true && context.mounted) {
                          final home = context.read<HomeController>();
                          await home.deleteFullDayRecord(home.selectedDay);
                          await sleepController.loadEntries();
                          await home.refreshMoodForDay(home.selectedDay);
                          await home.refreshIntakesForDay(home.selectedDay);
                        }
                      },
                    ),
                ],
              ),
              const SizedBox(height: 16),
              if (showMoodSection) ...[
                _DayCard(mood: mood, dayNotes: dayNotes),
                const SizedBox(height: 16),
              ],

              if (showHabitsSection) ...[
                _WaterCard(waterCount: waterCount),
                const SizedBox(height: 16),
                _BlocksWalkedCard(blocksWalked: blocksWalked),
                const SizedBox(height: 16),
              ],
              if (showSleep) ...[_SleepCard(entry), const SizedBox(height: 16)],
              if (showMeds)
                _MedicationCard(
                  events: events,
                  medicationController: medicationController,
                ),
            ],
          ),
        );
      },
    );
  }
}

class _DayChips extends StatelessWidget {
  final SleepEntry? sleepEntry;
  final int? mood;
  final int waterCount;
  final int intakesCount;

  const _DayChips({
    required this.sleepEntry,
    required this.mood,
    required this.waterCount,
    required this.intakesCount,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final chipBg = cs.surfaceContainerHighest;
    final chipSide = BorderSide(color: dividerColor(context, 0.18));
    final chipLabelStyle = TextStyle(color: cs.onSurface);
    final chipShape = StadiumBorder(side: chipSide);

    final iconMuted = muted(context, 0.80);

    final hasSleep = sleepEntry != null;
    final sleepText = hasSleep
        ? context.l10n.selectedDayChipSleepWithQuality(sleepEntry!.sleepQuality)
        : context.l10n.selectedDayChipSleepEmpty;

    final moodValue = mood;
    final hasMood = moodValue != null;

    final habitsSummary = '💧$waterCount';

    final hasMeds = intakesCount > 0;
    final medsText = hasMeds
        ? context.l10n.selectedDayChipMedicationWithCount(intakesCount)
        : context.l10n.selectedDayChipMedicationEmpty;

    Future<void> afterReturnRefresh() async {
      final home = context.read<HomeController>();
      final sleepController = context.read<SleepController>();
      await sleepController.loadEntries();
      await home.refreshMoodForDay(home.selectedDay);
      await home.refreshIntakesForDay(home.selectedDay);
      await home.ensureIntakesLoadedForMonth(home.focusedDay);
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ActionChip(
          backgroundColor: chipBg,
          shape: chipShape,
          labelStyle: chipLabelStyle,
          avatar: Icon(
            hasMood ? moodIcon(moodValue) : Icons.sentiment_neutral,
            size: 18,
            color: hasMood
                ? moodColor(context, moodValue).withValues(alpha: 0.95)
                : iconMuted,
          ),
          label: Text(
            hasMood ? context.l10n.commonMood : '${context.l10n.commonMood}: —',
          ),
          onPressed: () async {
            final home = context.read<HomeController>();
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => DailyEntryScreen.withProvider(
                  selectedDate: home.selectedDay,
                  initialTabIndex: 0,
                  initialDaySection: DailyEntryDaySection.mood,
                ),
              ),
            );
            if (result == true && context.mounted) await afterReturnRefresh();
          },
        ),

        ActionChip(
          backgroundColor: chipBg,
          shape: chipShape,
          labelStyle: chipLabelStyle,
          avatar: Icon(Icons.checklist, size: 18, color: cs.primary),
          label: Text('${context.l10n.commonHabits}  $habitsSummary'),
          onPressed: () async {
            final home = context.read<HomeController>();
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => DailyEntryScreen.withProvider(
                  selectedDate: home.selectedDay,
                  initialTabIndex: 0,
                  initialDaySection: DailyEntryDaySection.habits,
                ),
              ),
            );
            if (result == true && context.mounted) await afterReturnRefresh();
          },
        ),
        ActionChip(
          backgroundColor: chipBg,
          shape: chipShape,
          labelStyle: chipLabelStyle,
          avatar: Icon(Icons.bedtime, size: 18, color: iconMuted),
          label: Text(sleepText),
          onPressed: () async {
            final home = context.read<HomeController>();
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => DailyEntryScreen.withProvider(
                  selectedDate: home.selectedDay,
                  initialTabIndex: 1,
                ),
              ),
            );
            if (result == true && context.mounted) await afterReturnRefresh();
          },
        ),
        ActionChip(
          backgroundColor: chipBg,
          shape: chipShape,
          labelStyle: chipLabelStyle,
          avatar: Icon(Icons.medication, size: 18, color: iconMuted),
          label: Text(medsText),
          onPressed: () async {
            final home = context.read<HomeController>();
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => DailyEntryScreen.withProvider(
                  selectedDate: home.selectedDay,
                  initialTabIndex: 2,
                ),
              ),
            );
            if (result == true && context.mounted) await afterReturnRefresh();
          },
        ),
      ],
    );
  }
}

class _DayCard extends StatelessWidget {
  final int? mood;
  final String? dayNotes;

  const _DayCard({required this.mood, required this.dayNotes});

  @override
  Widget build(BuildContext context) {
    final moodValue = mood;
    final notes = (dayNotes ?? '').trim();

    IconData headerIcon = Icons.emoji_emotions_outlined;
    Color? headerColor;
    if (moodValue != null) {
      headerIcon = moodIcon(moodValue);
      headerColor = moodColor(context, moodValue);
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(headerIcon, size: 28, color: headerColor),
                const SizedBox(width: 12),
                Text(
                  context.l10n.commonDay,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (moodValue == null)
              Text(
                context.l10n.selectedDayNoMoodRecorded,
                style: TextStyle(color: muted(context, 0.70)),
              ),

            if (notes.isNotEmpty) ...[
              const SizedBox(height: 8),
              Divider(height: 1, color: dividerColor(context, 0.25)),
              const SizedBox(height: 8),
              Text(notes),
            ],
          ],
        ),
      ),
    );
  }
}

class _WaterCard extends StatelessWidget {
  final int waterCount;
  const _WaterCard({required this.waterCount});

  @override
  Widget build(BuildContext context) {
    final m1 = muted(context, 0.70);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            const Icon(Icons.water_drop_outlined, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                waterCount > 0
                    ? context.l10n.dayTabWaterCountLabel(waterCount)
                    : context.l10n.selectedDayNoWater,
                style: TextStyle(color: m1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BlocksWalkedCard extends StatelessWidget {
  final int? blocksWalked;
  const _BlocksWalkedCard({required this.blocksWalked});

  @override
  Widget build(BuildContext context) {
    final m1 = muted(context, 0.70);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            const Icon(Icons.directions_walk, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                blocksWalked != null
                    ? context.l10n.selectedDayBlocksWalkedValue(blocksWalked!)
                    : context.l10n.selectedDayNoBlocksWalked,
                style: TextStyle(color: m1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SleepCard extends StatelessWidget {
  final SleepEntry? entry;
  const _SleepCard(this.entry);

  @override
  Widget build(BuildContext context) {
    final m1 = muted(context, 0.70);
    final m2 = muted(context, 0.60);

    if (entry == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              const Icon(Icons.bedtime_outlined, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  context.l10n.selectedDayNoSleepRecord,
                  style: TextStyle(color: m1),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final notes = (entry!.notes ?? '').trim();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.bedtime, size: 28),
                const SizedBox(width: 12),
                Text(
                  context.l10n.commonSleep,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if ((entry!.sleepDurationMinutes ?? 0) > 0 ||
                (entry!.sleepContinuity != null))
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(() {
                  final parts = <String>[];
                  final total = entry!.sleepDurationMinutes;
                  if (total != null && total > 0) {
                    final hh = total ~/ 60;
                    final mm = total % 60;
                    parts.add('${hh}h ${mm.toString().padLeft(2, '0')}m');
                  }
                  if (entry!.sleepContinuity == 1) {
                    parts.add(context.l10n.sleepTabContinuityStraight);
                  }
                  if (entry!.sleepContinuity == 2) {
                    parts.add(context.l10n.sleepTabContinuityBroken);
                  }
                  return parts.join(' • ');
                }(), style: TextStyle(color: m1, fontSize: 12)),
              ),
            Divider(height: 1, color: dividerColor(context, 0.25)),
            if (notes.isNotEmpty)
              Text(notes)
            else
              Text(context.l10n.commonNoNotes, style: TextStyle(color: m2)),
          ],
        ),
      ),
    );
  }
}

class _MedicationCard extends StatelessWidget {
  final List<IntakeEvent> events;
  final MedicationController medicationController;

  const _MedicationCard({
    required this.events,
    required this.medicationController,
  });

  @override
  Widget build(BuildContext context) {
    final localeTag = Localizations.localeOf(context).toString();
    final medsById = <int, Medication>{
      for (final m in medicationController.allMedications)
        if (m.id != null) m.id!: m,
    };

    final m1 = muted(context, 0.70);
    final m2 = muted(context, 0.60);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.medication, size: 28),
                const SizedBox(width: 12),
                Text(
                  context.l10n.selectedDayMedicationsTitle,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (events.isEmpty)
              Text(
                context.l10n.selectedDayNoMedications,
                style: TextStyle(color: m1),
              )
            else
              ...events.map((e) {
                final med = medsById[e.medicationId];
                final name =
                    med?.name ??
                    context.l10n.selectedDayMedicationFallbackName(
                      e.medicationId,
                    );
                final unit = (med?.unit ?? '').trim();
                final unitText = unit.isEmpty ? '' : ' ($unit)';

                final isGel = med?.type == MedicationType.gel;
                final qty = isGel
                    ? context.l10n.medicationTabDoseApplication
                    : (e.amountNumerator == null || e.amountDenominator == null)
                    ? '—'
                    : FractionHelper.fractionToText(
                        e.amountNumerator!,
                        e.amountDenominator!,
                      );
                final qtyLabel = isGel
                    ? context.l10n.selectedDayMedicationQtyLabelRecord
                    : context.l10n.commonQuantity;

                final time = DateFormat('HH:mm', localeTag).format(e.takenAt);
                final note = (e.note ?? '').trim();

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 56,
                        child: Text(
                          time,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('$name$unitText'),
                            const SizedBox(height: 2),
                            Text(
                              '$qtyLabel: $qty',
                              style: TextStyle(color: m1),
                            ),
                            if (note.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(note, style: TextStyle(color: m2)),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
