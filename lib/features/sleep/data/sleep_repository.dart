import '../../../services/database_helper.dart';
import '../../../models/sleep_entry.dart';
import '../../../models/day_entry.dart';

class SleepRepository {
  final DatabaseHelper _db;

  SleepRepository({DatabaseHelper? db}) : _db = db ?? DatabaseHelper.instance;

  Future<List<SleepEntry>> getAllSleepEntries() async {
    return _db.getAllSleepEntriesFromDayEntries();
  }

  Future<SleepEntry?> getSleepEntryByDate(DateTime date) async {
    return _db.getSleepEntryByDate(date);
  }

  Future<DayEntry> ensureDayEntry(DateTime date) async {
    return _db.ensureDayEntry(date);
  }

  Future<void> saveSleepForDay(
    DateTime nightDate,
    int? sleepQuality,
    String? notes, {
    int? sleepDurationMinutes,
    int? sleepContinuity,
  }) async {
    await _db.saveSleepForDay(
      nightDate,
      sleepQuality,
      notes,
      sleepDurationMinutes: sleepDurationMinutes,
      sleepContinuity: sleepContinuity,
    );
  }

  Future<Map<String, int>> getSleepDaysCountByMonth() async {
    return _db.getSleepDaysCountByMonthFromDayEntries();
  }
}
