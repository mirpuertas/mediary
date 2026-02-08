import 'package:flutter/foundation.dart';
import 'package:med_journal/l10n/gen/app_localizations.dart';

import '../../../models/day_entry.dart';
import '../../../services/water_widget_service.dart';
import '../../../models/medication.dart';
import '../../medication/state/medication_controller.dart';
import '../../medication/data/intake_repository.dart';
import '../data/day_entry_repository.dart';
import 'intake_event_draft.dart';

class DailyEntrySaveResult {
  final bool ok;
  final String? message;

  const DailyEntrySaveResult._({required this.ok, this.message});

  const DailyEntrySaveResult.ok() : this._(ok: true);

  const DailyEntrySaveResult.error(String message)
    : this._(ok: false, message: message);
}

class DailyEntryController extends ChangeNotifier {
  final DayEntryRepository _dayRepo;
  final IntakeRepository _intakeRepo;
  final MedicationController _medicationController;

  DailyEntryController({
    required DayEntryRepository dayRepo,
    required IntakeRepository intakeRepo,
    required MedicationController medicationController,
  }) : _dayRepo = dayRepo,
       _intakeRepo = intakeRepo,
       _medicationController = medicationController;

  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  bool _isSaving = false;
  bool _isDirty = false;
  String? _error;

  int? dayMood; // 1..5
  String blocksWalkedText = '';

  String dayNotes = '';

  int waterCount = 0; // 0..10

  int? sleepQuality; // 1..5
  String sleepNotes = '';
  int? sleepDurationHours;
  int? sleepDurationMinutes;
  int? sleepContinuity; // 1=corrido, 2=cortado

  final List<IntakeEventDraft> _intakeEvents = [];

  DateTime get selectedDate => _selectedDate;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  bool get isDirty => _isDirty;
  String? get error => _error;

  List<IntakeEventDraft> get intakeEvents => List.unmodifiable(_intakeEvents);

  void _markDirty() {
    if (_isDirty) return;
    _isDirty = true;
  }

  Future<void> load(DateTime date) async {
    _selectedDate = DateTime(date.year, date.month, date.day);
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _medicationController.loadMedications();

      final dayEntry =
          await _dayRepo.getByDate(_selectedDate) ??
          await _dayRepo.getOrCreate(_selectedDate);

      final dayEntryId =
          dayEntry.id ?? (await _dayRepo.getOrCreate(_selectedDate)).id!;

      final events = await _intakeRepo.getIntakeEventsByDay(dayEntryId);

      _isDirty = false;

      dayMood = dayEntry.dayMood;
      blocksWalkedText = dayEntry.blocksWalked?.toString() ?? '';

      dayNotes = dayEntry.dayNotes ?? '';
      waterCount = (dayEntry.waterCount ?? 0).clamp(0, 10);

      final widgetWater = await WaterWidgetService.instance.syncFromWidget(
        _selectedDate,
        waterCount,
      );
      if (widgetWater != null) {
        waterCount = widgetWater;
        _markDirty();
      } else {

        await WaterWidgetService.instance.setWaterCount(
          _selectedDate,
          waterCount,
        );
      }

      sleepQuality = dayEntry.sleepQuality;
      sleepNotes = dayEntry.sleepNotes ?? '';

      final totalSleep = dayEntry.sleepDurationMinutes;
      if (totalSleep != null && totalSleep > 0) {
        sleepDurationHours = totalSleep ~/ 60;
        sleepDurationMinutes = totalSleep % 60;
      } else {
        sleepDurationHours = null;
        sleepDurationMinutes = null;
      }
      sleepContinuity = dayEntry.sleepContinuity;

      _intakeEvents
        ..clear()
        ..addAll(events.map(IntakeEventDraft.fromModel));
    } catch (e) {
      _error = 'Error cargando el registro: $e';
      if (kDebugMode) {
        debugPrint(_error);
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setDayMood(int? value) {
    dayMood = value;
    _markDirty();
    notifyListeners();
  }

  void setBlocksWalkedText(String value) {
    blocksWalkedText = value;
    _markDirty();
    notifyListeners();
  }

  void setDayNotes(String value) {
    dayNotes = value;
    _markDirty();
    notifyListeners();
  }

  void setWaterCount(int value) {
    waterCount = value.clamp(0, 10);
    _markDirty();

    WaterWidgetService.instance.setWaterCount(_selectedDate, waterCount);
    notifyListeners();
  }

  void setSleepQuality(int? value) {
    sleepQuality = value;
    _markDirty();
    notifyListeners();
  }

  void setSleepNotes(String value) {
    sleepNotes = value;
    _markDirty();
    notifyListeners();
  }

  void setSleepDuration({int? hours, int? minutes}) {
    sleepDurationHours = hours;
    sleepDurationMinutes = minutes;
    _markDirty();
    notifyListeners();
  }

  void setSleepContinuity(int? value) {
    sleepContinuity = value;
    _markDirty();
    notifyListeners();
  }

  void addIntakeEvent() {
    _intakeEvents.add(
      IntakeEventDraft.newForDay(_selectedDate, DateTime.now()),
    );
    _markDirty();
    notifyListeners();
  }

  void removeIntakeEventAt(int index) {
    if (index < 0 || index >= _intakeEvents.length) return;
    _intakeEvents.removeAt(index);
    _markDirty();
    notifyListeners();
  }

  void updateIntakeEvent(int index, IntakeEventDraft next) {
    if (index < 0 || index >= _intakeEvents.length) return;
    _intakeEvents[index] = next;
    _markDirty();
    notifyListeners();
  }

  String? validateForSave(AppLocalizations l10n) {
    for (var i = 0; i < _intakeEvents.length; i++) {
      final ev = _intakeEvents[i];
      if (ev.medicationId == null) {
        return l10n.dailyEntryValidationSelectMedication(i + 1);
      }

      final medication = _medicationController.getMedicationById(
        ev.medicationId!,
      );
      final medicationType = medication?.type;

      final num = ev.numerator;
      final den = ev.denominator;
      final isUnknown = num == null && den == null;
      final isGel = medicationType == MedicationType.gel;

      final isValidKnown = isGel
          ? false
          : medicationType == MedicationType.drops ||
                medicationType == MedicationType.capsule
          ? (num != null && den == 1 && num > 0)
          : (num != null && den != null && num > 0 && den > 0);

      if (!(isUnknown || isValidKnown)) {
        if (isGel) {
          return l10n.dailyEntryValidationGelNoQuantity(i + 1);
        }
        if (medicationType == MedicationType.drops ||
            medicationType == MedicationType.capsule) {
          return l10n.dailyEntryValidationInvalidQuantityInteger(i + 1);
        }
        return l10n.dailyEntryValidationInvalidQuantityFraction(i + 1);
      }
    }

    int? durationMinutes;
    if (sleepDurationHours != null || sleepDurationMinutes != null) {
      final hh = sleepDurationHours ?? 0;
      final mm = sleepDurationMinutes ?? 0;
      final total = (hh * 60) + mm;
      durationMinutes = total <= 0 ? null : total;
    }

    final cleanedSleepNotes = sleepNotes.trim().isEmpty
        ? null
        : sleepNotes.trim();
    final hasAnySleepDetails =
        cleanedSleepNotes != null ||
        durationMinutes != null ||
        sleepContinuity != null;

    if (sleepQuality == null && hasAnySleepDetails) {
      return l10n.dailyEntryValidationSleepNeedsQuality;
    }

    return null;
  }

  Future<DailyEntrySaveResult> save(AppLocalizations l10n) async {
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    if (_selectedDate.isAfter(todayOnly)) {
      return DailyEntrySaveResult.error(l10n.dailyEntryValidationFutureDay);
    }

    final validationMessage = validateForSave(l10n);
    if (validationMessage != null) {
      return DailyEntrySaveResult.error(validationMessage);
    }

    _isSaving = true;
    _error = null;
    notifyListeners();

    try {
      final day = await _dayRepo.getOrCreate(_selectedDate);
      final dayEntryId = day.id!;

      int? blocks;
      final rawBlocks = blocksWalkedText.trim();
      final parsed = rawBlocks.isEmpty ? null : int.tryParse(rawBlocks);
      blocks = parsed?.clamp(0, 1000);

      int? durationMinutes;
      if (sleepDurationHours != null || sleepDurationMinutes != null) {
        final hh = sleepDurationHours ?? 0;
        final mm = sleepDurationMinutes ?? 0;
        final total = (hh * 60) + mm;
        durationMinutes = total <= 0 ? null : total;
      }

      final cleanedDayNotes = dayNotes.trim().isEmpty ? null : dayNotes.trim();
      final cleanedSleepNotes = sleepNotes.trim().isEmpty
          ? null
          : sleepNotes.trim();

      final entry = DayEntry(
        id: dayEntryId,
        entryDate: _selectedDate,
        // sleep
        sleepQuality: sleepQuality,
        sleepNotes: cleanedSleepNotes,
        sleepDurationMinutes: durationMinutes,
        sleepContinuity: sleepContinuity,
        // day
        dayMood: dayMood,
        blocksWalked: blocks,
        dayNotes: cleanedDayNotes,
        waterCount: waterCount.clamp(0, 10),
      );

      final intakeModels = _intakeEvents
          .map((d) => d.toModel(dayEntryId: dayEntryId))
          .toList();

      await _dayRepo.saveDayEntryWithIntakeEvents(
        entry: entry,
        intakeEvents: intakeModels,
      );

      _isDirty = false;
      return const DailyEntrySaveResult.ok();
    } catch (e) {
      _error = l10n.dailyEntrySaveErrorWithMessage(e.toString());
      if (kDebugMode) {
        debugPrint(_error);
      }
      return DailyEntrySaveResult.error(_error!);
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }
}
