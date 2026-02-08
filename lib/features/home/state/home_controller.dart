import 'package:flutter/foundation.dart';
import 'package:table_calendar/table_calendar.dart';

import '../data/home_repository.dart';
import '../../../models/day_entry.dart';
import '../../../models/intake_event.dart';
import '../../../services/water_widget_service.dart';
import 'calendar_filter.dart';

typedef HabitsSummary = ({
  int? waterCount,
  int? blocksWalked,
});

class SelectedDayData {
  final DateTime day;
  final DayEntry dayEntry;
  final List<IntakeEvent> intakeEvents;

  const SelectedDayData({
    required this.day,
    required this.dayEntry,
    required this.intakeEvents,
  });
}

class HomeController extends ChangeNotifier {
  final HomeRepository _repo;

  HomeController({required HomeRepository repo}) : _repo = repo;

  DateTime get _today => dateOnly(DateTime.now());

  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.month;
  CalendarFilter _calendarFilter = CalendarFilter.all;

  DateTime get focusedDay => dateOnly(_focusedDay);
  DateTime get selectedDay => dateOnly(_selectedDay);
  CalendarFormat get calendarFormat => _calendarFormat;
  CalendarFilter get calendarFilter => _calendarFilter;

  final Map<DateTime, int> moodByDay = {};
  final Set<int> loadedMoodMonths = {};

  final Map<DateTime, int> intakesCountByDay = {};
  final Set<int> loadedIntakeMonths = {};

  final Map<DateTime, HabitsSummary> habitsByDay = {};
  final Set<int> loadedHabitsMonths = {};

  final Map<DateTime, int> blocksWalkedByDay = {};
  final Set<int> loadedBlocksWalkedMonths = {};

  bool _isLoadingSelectedDay = false;
  SelectedDayData? _selectedDayData;

  bool get isLoadingSelectedDay => _isLoadingSelectedDay;
  SelectedDayData? get selectedDayData => _selectedDayData;

  DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
  int monthKey(DateTime d) => (d.year * 100) + d.month;
  DateTime endOfDay(DateTime d) =>
      DateTime(d.year, d.month, d.day, 23, 59, 59, 999);

  Future<void> ensureMoodLoadedForMonth(DateTime focusedDay) async {
    final key = monthKey(focusedDay);
    if (loadedMoodMonths.contains(key)) return;
    loadedMoodMonths.add(key);

    final start = DateTime(focusedDay.year, focusedDay.month, 1);
    final lastDay = DateTime(focusedDay.year, focusedDay.month + 1, 0);
    final endInclusive = endOfDay(lastDay);

    try {
      final moods = await _repo.getMoodByDayBetween(start, endInclusive);
      moodByDay.addAll(moods);
      notifyListeners();
    } catch (e) {
      loadedMoodMonths.remove(key);
      if (kDebugMode) {
        debugPrint('Error loading moods for month $key: $e');
      }
    }
  }

  Future<void> selectDay(DateTime selected, DateTime focused) async {
    final today = _today;
    final selectedDay = dateOnly(selected);
    final focusedDay = dateOnly(focused);

    _selectedDay = selectedDay.isAfter(today) ? today : selectedDay;
    _focusedDay = focusedDay.isAfter(today) ? today : focusedDay;
    notifyListeners();

    await Future.wait([
      ensureMoodLoadedForMonth(_focusedDay),
      ensureIntakesLoadedForMonth(_focusedDay),
      ensureHabitsLoadedForMonth(_focusedDay),
      ensureBlocksWalkedLoadedForMonth(_focusedDay),
      loadSelectedDay(_selectedDay),
    ]);
  }

  Future<void> setFocusedDay(DateTime focused) async {
    final today = _today;
    final focusedDay = dateOnly(focused);
    _focusedDay = focusedDay.isAfter(today) ? today : focusedDay;
    notifyListeners();
    await Future.wait([
      ensureMoodLoadedForMonth(_focusedDay),
      ensureIntakesLoadedForMonth(_focusedDay),
      ensureHabitsLoadedForMonth(_focusedDay),
      ensureBlocksWalkedLoadedForMonth(_focusedDay),
    ]);
  }

  void setCalendarFormat(CalendarFormat format) {
    if (_calendarFormat == format) return;
    _calendarFormat = format;
    notifyListeners();
  }

  Future<void> setCalendarFilter(CalendarFilter filter) async {
    if (_calendarFilter == filter) return;
    _calendarFilter = filter;
    notifyListeners();
    if (filter == CalendarFilter.habits) {
      await ensureHabitsLoadedForMonth(_focusedDay);
    }
  }

  Future<void> resetToToday() async {
    final now = DateTime.now();
    final today = dateOnly(now);
    _calendarFormat = CalendarFormat.month;
    _calendarFilter = CalendarFilter.all;
    _selectedDay = today;
    _focusedDay = today;
    notifyListeners();
    await selectDay(today, today);
  }

  Future<void> ensureIntakesLoadedForMonth(DateTime focusedDay) async {
    final key = monthKey(focusedDay);
    if (loadedIntakeMonths.contains(key)) return;
    loadedIntakeMonths.add(key);

    final start = DateTime(focusedDay.year, focusedDay.month, 1);
    final lastDay = DateTime(focusedDay.year, focusedDay.month + 1, 0);
    final endInclusive = endOfDay(lastDay);

    try {
      final counts = await _repo.getIntakeCountsBetween(start, endInclusive);
      intakesCountByDay.addAll(counts);
      notifyListeners();
    } catch (e) {
      loadedIntakeMonths.remove(key);
      if (kDebugMode) {
        debugPrint('Error loading intakes for month $key: $e');
      }
    }
  }

  Future<void> ensureHabitsLoadedForMonth(DateTime focusedDay) async {
    final key = monthKey(focusedDay);
    if (loadedHabitsMonths.contains(key)) return;

    final start = DateTime(focusedDay.year, focusedDay.month, 1);
    final lastDay = DateTime(focusedDay.year, focusedDay.month + 1, 0);
    final endInclusive = endOfDay(lastDay);

    try {
      final habits = await _repo.getHabitsBetween(start, endInclusive);
      habitsByDay.addAll(habits);
      loadedHabitsMonths.add(key);

      for (final e in habits.entries) {
        final blocks = (e.value.blocksWalked ?? 0).clamp(0, 1000);
        if (blocks <= 0) {
          blocksWalkedByDay.remove(e.key);
        } else {
          blocksWalkedByDay[e.key] = blocks;
        }
      }
      loadedBlocksWalkedMonths.add(key);
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error loading habits for month $key: $e');
      }
    }
  }

  Future<void> refreshIntakesForDay(DateTime date) async {
    final day = dateOnly(date);
    final count = await _repo.getIntakeCountByDate(day);
    if (count == null || count == 0) {
      intakesCountByDay.remove(day);
    } else {
      intakesCountByDay[day] = count;
    }
    notifyListeners();
  }

  Future<void> refreshMoodForDay(DateTime date) async {
    final day = dateOnly(date);
    final mood = await _repo.getMoodByDate(day);
    if (mood == null) {
      moodByDay.remove(day);
    } else {
      moodByDay[day] = mood;
    }
    notifyListeners();
  }

  Future<void> loadSelectedDay(DateTime date) async {
    final day = dateOnly(date);
    _isLoadingSelectedDay = true;
    notifyListeners();

    try {
      final existing = await _repo.getDayEntryByDate(day);
      final entry = existing ?? await _repo.ensureDayEntry(day);
      final ensuredEntry = entry.id == null
          ? await _repo.ensureDayEntry(day)
          : entry;

      final events = await _repo.getIntakeEventsByDayEntryId(ensuredEntry.id!);
      _selectedDayData = SelectedDayData(
        day: day,
        dayEntry: ensuredEntry,
        intakeEvents: events,
      );

      final mood = ensuredEntry.dayMood;
      if (mood == null) {
        moodByDay.remove(day);
      } else {
        moodByDay[day] = mood;
      }

      final intakeCount = events.length;
      if (intakeCount == 0) {
        intakesCountByDay.remove(day);
      } else {
        intakesCountByDay[day] = intakeCount;
      }

      var water = (ensuredEntry.waterCount ?? 0).clamp(0, 10);
      final blocks = (ensuredEntry.blocksWalked ?? 0).clamp(0, 1000);

      final widgetWater = await WaterWidgetService.instance.syncFromWidget(
        day,
        water,
      );
      if (widgetWater != null && widgetWater != water) {
        water = widgetWater;
        await _repo.updateWaterCount(day, water);
        _selectedDayData = SelectedDayData(
          day: day,
          dayEntry: ensuredEntry.copyWith(waterCount: water),
          intakeEvents: events,
        );
      }

      final hasHabits = water > 0 || blocks > 0;
      if (!hasHabits) {
        habitsByDay.remove(day);
      } else {
        habitsByDay[day] = (
          waterCount: water > 0 ? water : null,
          blocksWalked: blocks > 0 ? blocks : null,
        );
      }

      if (blocks <= 0) {
        blocksWalkedByDay.remove(day);
      } else {
        blocksWalkedByDay[day] = blocks;
      }
    } finally {
      _isLoadingSelectedDay = false;
      notifyListeners();
    }
  }

  Future<void> ensureBlocksWalkedLoadedForMonth(DateTime focusedDay) async {
    await ensureHabitsLoadedForMonth(focusedDay);
  }

  Future<void> deleteFullDayRecord(DateTime date) async {
    final day = dateOnly(date);
    await _repo.deleteFullDayRecordByDate(day);

    moodByDay.remove(day);
    intakesCountByDay.remove(day);
    habitsByDay.remove(day);
    blocksWalkedByDay.remove(day);

    await loadSelectedDay(day);

    notifyListeners();
  }
}
