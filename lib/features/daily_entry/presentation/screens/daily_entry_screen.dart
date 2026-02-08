import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../../l10n/l10n.dart';
import '../../../../ui/app_theme_tokens.dart';
import '../../../../utils/ui_feedback.dart';
import '../../../medication/state/medication_controller.dart';
import '../../../medication/data/intake_repository.dart';
import '../../data/day_entry_repository.dart';
import '../sections/day_tab_section.dart';
import '../sections/medication_tab_section.dart';
import '../sections/sleep_tab_section.dart';
import '../../state/daily_entry_controller.dart';

enum DailyEntryDaySection { mood, habits }

class DailyEntryScreen extends StatefulWidget {
  final DateTime selectedDate;
  final int initialTabIndex;
  final DailyEntryDaySection? initialDaySection;

  const DailyEntryScreen({
    super.key,
    required this.selectedDate,
    this.initialTabIndex = 1,
    this.initialDaySection,
  }) : assert(initialTabIndex >= 0 && initialTabIndex < 3);

  static Widget withProvider({
    Key? key,
    required DateTime selectedDate,
    int initialTabIndex = 1,
    DailyEntryDaySection? initialDaySection,
  }) {
    return ChangeNotifierProvider(
      create: (context) => DailyEntryController(
        dayRepo: DayEntryRepository(),
        intakeRepo: IntakeRepository(),
        medicationController: context.read<MedicationController>(),
      )..load(selectedDate),
      child: DailyEntryScreen(
        key: key,
        selectedDate: selectedDate,
        initialTabIndex: initialTabIndex,
        initialDaySection: initialDaySection,
      ),
    );
  }

  @override
  State<DailyEntryScreen> createState() => _DailyEntryScreenState();
}

class _DailyEntryScreenState extends State<DailyEntryScreen>
    with SingleTickerProviderStateMixin {
  final GlobalKey _moodSectionKey = GlobalKey();
  final GlobalKey _habitsSectionKey = GlobalKey();
  DailyEntryDaySection? _pendingScrollSection;

  bool _dayDetailsExpanded = false;
  final TextEditingController _dayNotesController = TextEditingController();

  final TextEditingController _blocksWalkedController = TextEditingController();

  final TextEditingController _sleepNotesController = TextEditingController();
  bool _sleepDetailsExpanded = false;

  final Set<int> _expandedIntakeEventIndices = <int>{};

  DateTime? _lastSyncedDate;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
    if (widget.initialTabIndex == 0) {
      _pendingScrollSection = widget.initialDaySection;
    }
  }

  void _scheduleInitialSectionScroll() {
    final section = _pendingScrollSection;
    if (section == null) return;
    if (_tabController.index != 0) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final ctx = switch (section) {
        DailyEntryDaySection.mood => _moodSectionKey.currentContext,
        DailyEntryDaySection.habits => _habitsSectionKey.currentContext,
      };
      if (ctx == null) return;
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        alignment: 0.05,
      );
      _pendingScrollSection = null;
    });
  }

  void _maybeSyncTextControllers(DailyEntryController c) {
    if (c.isLoading) return;
    final dateOnly = DateTime(
      c.selectedDate.year,
      c.selectedDate.month,
      c.selectedDate.day,
    );
    if (_lastSyncedDate == dateOnly) return;
    _lastSyncedDate = dateOnly;

    _dayNotesController.text = c.dayNotes;
    _blocksWalkedController.text = c.blocksWalkedText;
    _sleepNotesController.text = c.sleepNotes;

    _dayDetailsExpanded = _dayNotesController.text.trim().isNotEmpty;
    _sleepDetailsExpanded =
        c.sleepDurationHours != null ||
        c.sleepDurationMinutes != null ||
        c.sleepContinuity != null;

    _expandedIntakeEventIndices.clear();
    _scheduleInitialSectionScroll();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _dayNotesController.dispose();
    _sleepNotesController.dispose();
    _blocksWalkedController.dispose();
    super.dispose();
  }

  void _addIntakeEvent(DailyEntryController c) {
    c.addIntakeEvent();
    setState(() {
      _expandedIntakeEventIndices.add(c.intakeEvents.length - 1);
    });

    UIFeedback.showInfo(context, context.l10n.dailyEntryMedicationAdded);
  }

  void _removeIntakeEvent(DailyEntryController c, int index) {
    c.removeIntakeEventAt(index);
    setState(() {
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
    final l10n = context.l10n;
    final c = context.watch<DailyEntryController>();
    _maybeSyncTextControllers(c);

    final localeName = Localizations.localeOf(context).toString();
    final dateFormat = DateFormat('d MMMM yyyy', localeName);
    final yesterday = widget.selectedDate.subtract(const Duration(days: 1));

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.dailyEntryTitle),
        backgroundColor: context.surfaces.accentSurface,
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              icon: const Icon(Icons.emoji_emotions),
              text: l10n.dailyEntryTabDayOptional,
            ),
            Tab(
              icon: const Icon(Icons.bedtime),
              text: l10n.dailyEntryTabSleepOptional,
            ),
            Tab(
              icon: const Icon(Icons.medication),
              text: l10n.dailyEntryTabMedication,
            ),
          ],
        ),
      ),
      body: c.isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                DayTabSection(
                  dateFormat: dateFormat,
                  selectedDate: widget.selectedDate,
                  controller: c,
                  moodSectionKey: _moodSectionKey,
                  habitsSectionKey: _habitsSectionKey,
                  dayNotesController: _dayNotesController,
                  blocksWalkedController: _blocksWalkedController,
                  dayDetailsExpanded: _dayDetailsExpanded,
                  onDayDetailsExpandedChanged: (v) =>
                      setState(() => _dayDetailsExpanded = v),
                  onSavePressed: () => _saveEntry(c),
                ),
                SleepTabSection(
                  dateFormat: dateFormat,
                  selectedDate: widget.selectedDate,
                  yesterday: yesterday,
                  controller: c,
                  sleepNotesController: _sleepNotesController,
                  sleepDetailsExpanded: _sleepDetailsExpanded,
                  onSleepDetailsExpandedChanged: (v) =>
                      setState(() => _sleepDetailsExpanded = v),
                  onSavePressed: () => _saveEntry(c),
                ),
                MedicationTabSection(
                  controller: c,
                  expandedIndices: _expandedIntakeEventIndices,
                  onAddPressed: () => _addIntakeEvent(c),
                  onRemovePressed: (i) => _removeIntakeEvent(c, i),
                  onSavePressed: () => _saveEntry(c),
                ),
              ],
            ),
    );
  }

  Future<void> _saveEntry(DailyEntryController c) async {
    final result = await c.save(context.l10n);
    if (!mounted) return;

    if (!result.ok) {
      UIFeedback.showError(
        context,
        result.message ?? context.l10n.dailyEntrySaveError,
      );
      return;
    }

    UIFeedback.showSuccess(context, context.l10n.dailyEntrySaveSuccess);
    Navigator.pop(context, true);
  }
}
