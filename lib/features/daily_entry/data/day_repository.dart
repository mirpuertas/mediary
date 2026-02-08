import '../../../services/database_helper.dart';
import '../../../models/day_entry.dart';
import '../../../models/sleep_entry.dart';

/// Repository para gestión de day entries y datos del día
class DayRepository {
  final DatabaseHelper _db;

  DayRepository({DatabaseHelper? db}) : _db = db ?? DatabaseHelper.instance;

  // ==================== DAY ENTRIES ====================

  Future<DayEntry> ensureDayEntry(DateTime date) async {
    return _db.ensureDayEntry(date);
  }

  Future<DayEntry?> getDayEntryByDate(DateTime date) async {
    final db = await _db.database;
    final dateOnly = DateTime(
      date.year,
      date.month,
      date.day,
    ).toIso8601String();

    final rows = await db.query(
      'day_entries',
      where: 'entry_date = ?',
      whereArgs: [dateOnly],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return DayEntry.fromMap(rows.first);
  }

  Future<List<DayEntry>> getAllDayEntries() async {
    final db = await _db.database;
    final result = await db.query('day_entries');
    return result.map((m) => DayEntry.fromMap(m)).toList();
  }

  Future<void> deleteFullDayRecordByDate(DateTime date) async {
    final db = await _db.database;
    final dateOnly = DateTime(
      date.year,
      date.month,
      date.day,
    ).toIso8601String();

    await db.transaction((txn) async {
      final rows = await txn.query(
        'day_entries',
        columns: ['id'],
        where: 'entry_date = ?',
        whereArgs: [dateOnly],
        limit: 1,
      );

      final dayEntryId = rows.isNotEmpty ? (rows.first['id'] as int) : null;

      if (dayEntryId != null) {
        await txn.delete(
          'intake_events',
          where: 'day_entry_id = ?',
          whereArgs: [dayEntryId],
        );

        await txn.delete(
          'day_entries',
          where: 'id = ?',
          whereArgs: [dayEntryId],
        );
      }
    });
  }

  // ==================== SLEEP ====================

  Future<void> saveSleepForDay(
    DateTime date,
    int? quality,
    String? notes, {
    int? sleepDurationMinutes,
    int? sleepContinuity,
  }) async {
    final db = await _db.database;
    final day = await _db.ensureDayEntry(date);

    await db.update(
      'day_entries',
      {
        'sleep_quality': quality,
        'sleep_notes': notes,
        'sleep_duration_minutes': sleepDurationMinutes,
        'sleep_continuity': sleepContinuity,
      },
      where: 'id = ?',
      whereArgs: [day.id],
    );
  }

  Future<SleepEntry?> getSleepFromDay(DateTime date) async {
    final day = await getDayEntryByDate(date);
    if (day == null) return null;
    if (day.sleepQuality == null) return null;

    return SleepEntry(
      id: null,
      nightDate: DateTime(
        day.entryDate.year,
        day.entryDate.month,
        day.entryDate.day,
      ),
      sleepQuality: day.sleepQuality!,
      notes: day.sleepNotes,
      sleepDurationMinutes: day.sleepDurationMinutes,
      sleepContinuity: day.sleepContinuity,
    );
  }

  Future<Map<DateTime, int>> getSleepQualitiesBetween(
    DateTime start,
    DateTime end,
  ) async {
    final db = await _db.database;

    final startOnly = DateTime(
      start.year,
      start.month,
      start.day,
    ).toIso8601String();
    final endOnly = DateTime(end.year, end.month, end.day).toIso8601String();

    final rows = await db.query(
      'day_entries',
      columns: ['entry_date', 'sleep_quality'],
      where:
          'entry_date >= ? AND entry_date <= ? AND sleep_quality IS NOT NULL',
      whereArgs: [startOnly, endOnly],
    );

    final result = <DateTime, int>{};
    for (final row in rows) {
      final rawDate = row['entry_date'] as String?;
      final quality = row['sleep_quality'] as int?;
      if (rawDate == null || quality == null) continue;

      final dt = DateTime.parse(rawDate);
      result[DateTime(dt.year, dt.month, dt.day)] = quality;
    }
    return result;
  }

  // ==================== MOOD ====================

  Future<int?> getDayMoodByDate(DateTime date) async {
    final db = await _db.database;
    final dateOnly = DateTime(
      date.year,
      date.month,
      date.day,
    ).toIso8601String();

    final rows = await db.query(
      'day_entries',
      columns: ['day_mood'],
      where: 'entry_date = ?',
      whereArgs: [dateOnly],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first['day_mood'] as int?;
  }

  Future<void> saveDayMoodForDay(DateTime date, int? mood) async {
    final db = await _db.database;
    final day = await _db.ensureDayEntry(date);

    await db.update(
      'day_entries',
      {'day_mood': mood},
      where: 'id = ?',
      whereArgs: [day.id],
    );
  }

  Future<Map<DateTime, int>> getDayMoodsBetween(
    DateTime start,
    DateTime end,
  ) async {
    final db = await _db.database;

    final startOnly = DateTime(
      start.year,
      start.month,
      start.day,
    ).toIso8601String();
    final endOnly = DateTime(end.year, end.month, end.day).toIso8601String();

    final rows = await db.query(
      'day_entries',
      columns: ['entry_date', 'day_mood'],
      where: 'entry_date >= ? AND entry_date <= ? AND day_mood IS NOT NULL',
      whereArgs: [startOnly, endOnly],
    );

    final result = <DateTime, int>{};
    for (final row in rows) {
      final rawDate = row['entry_date'] as String?;
      final mood = row['day_mood'] as int?;
      if (rawDate == null || mood == null) continue;

      final dt = DateTime.parse(rawDate);
      result[DateTime(dt.year, dt.month, dt.day)] = mood;
    }
    return result;
  }

  // ==================== NOTES ====================

  Future<String?> getDayNotesByDate(DateTime date) async {
    final db = await _db.database;
    final dateOnly = DateTime(
      date.year,
      date.month,
      date.day,
    ).toIso8601String();

    final rows = await db.query(
      'day_entries',
      columns: ['day_notes'],
      where: 'entry_date = ?',
      whereArgs: [dateOnly],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first['day_notes'] as String?;
  }

  Future<void> saveDayNotesForDay(DateTime date, String? notes) async {
    final db = await _db.database;
    final day = await _db.ensureDayEntry(date);

    await db.update(
      'day_entries',
      {'day_notes': notes},
      where: 'id = ?',
      whereArgs: [day.id],
    );
  }
}
