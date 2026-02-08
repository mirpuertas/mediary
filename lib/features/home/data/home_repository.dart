import '../../../services/database_helper.dart';
import '../../../models/day_entry.dart';
import '../../../models/intake_event.dart';
import '../../daily_entry/data/day_repository.dart';
import '../../daily_entry/data/habits_repository.dart';
import '../../medication/data/intake_repository.dart';

class HomeRepository {
  final DatabaseHelper _db;
  final DayRepository _dayRepo;
  final HabitsRepository _habitsRepo;
  final IntakeRepository _intakeRepo;

  HomeRepository({
    DatabaseHelper? db,
    DayRepository? dayRepo,
    HabitsRepository? habitsRepo,
    IntakeRepository? intakeRepo,
  }) : _db = db ?? DatabaseHelper.instance,
       _dayRepo = dayRepo ?? DayRepository(),
       _habitsRepo = habitsRepo ?? HabitsRepository(),
       _intakeRepo = intakeRepo ?? IntakeRepository();

  Future<Map<DateTime, int>> getMoodByDayBetween(
    DateTime start,
    DateTime endInclusive,
  ) {
    return _dayRepo.getDayMoodsBetween(start, endInclusive);
  }

  Future<int?> getMoodByDate(DateTime date) => _dayRepo.getDayMoodByDate(date);

  Future<Map<DateTime, int>> getIntakeCountsBetween(
    DateTime start,
    DateTime endInclusive,
  ) {
    return _intakeRepo.getIntakeCountsBetween(start, endInclusive);
  }

  Future<int?> getIntakeCountByDate(DateTime date) {
    return _intakeRepo.getIntakeCountByDate(date);
  }

  Future<
    Map<DateTime, ({int? waterCount, int? blocksWalked})>
  >
  getHabitsBetween(DateTime start, DateTime endInclusive) {
    return _habitsRepo.getHabitsBetween(start, endInclusive);
  }

  Future<DayEntry> ensureDayEntry(DateTime date) => _db.ensureDayEntry(date);

  Future<DayEntry?> getDayEntryByDate(DateTime date) =>
      _dayRepo.getDayEntryByDate(date);

  Future<List<IntakeEvent>> getIntakeEventsByDayEntryId(int dayEntryId) {
    return _intakeRepo.getIntakeEventsByDay(dayEntryId);
  }

  Future<void> deleteFullDayRecordByDate(DateTime date) {
    return _dayRepo.deleteFullDayRecordByDate(date);
  }

  Future<void> updateWaterCount(DateTime date, int waterCount) {
    return _habitsRepo.saveWaterCountForDay(date, waterCount);
  }
}
