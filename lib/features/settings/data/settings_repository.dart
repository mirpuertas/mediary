import '../../../services/database_helper.dart';
import '../../medication/data/intake_repository.dart';

class SettingsRepository {
  final DatabaseHelper _db;
  final IntakeRepository _intakeRepo;

  SettingsRepository({DatabaseHelper? db, IntakeRepository? intakeRepo})
    : _db = db ?? DatabaseHelper.instance,
      _intakeRepo = intakeRepo ?? IntakeRepository();

  Future<({int totalEntries, int totalEvents, int totalDays})>
  loadExportCounts() async {
    final entries = await _db.getAllSleepEntriesFromDayEntries();
    final events = await _intakeRepo.getAllIntakeEvents();

    final sqlDb = await _db.database;
    final cntRows = await sqlDb.rawQuery('''
        SELECT COUNT(*) as cnt
        FROM day_entries
        WHERE
          sleep_quality IS NOT NULL
          OR sleep_notes IS NOT NULL
          OR sleep_duration_minutes IS NOT NULL
          OR sleep_continuity IS NOT NULL
          OR day_mood IS NOT NULL
          OR blocks_walked IS NOT NULL
          OR (day_notes IS NOT NULL AND TRIM(day_notes) <> '')
          OR water_count IS NOT NULL
      ''');

    final totalDays = cntRows.isEmpty
        ? 0
        : ((cntRows.first['cnt'] as int?) ?? 0);

    return (
      totalEntries: entries.length,
      totalEvents: events.length,
      totalDays: totalDays,
    );
  }

  Future<void> wipeAllData() => _db.wipeAllData();
}
