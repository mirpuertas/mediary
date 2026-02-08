import '../../../services/database_helper.dart';
import '../../../models/intake_event.dart';
import '../../../models/day_entry.dart';
import '../../../models/medication.dart';

class IntakeRepository {
  final DatabaseHelper _db;

  IntakeRepository({DatabaseHelper? db}) : _db = db ?? DatabaseHelper.instance;

  Future<DayEntry> ensureDayEntry(DateTime date) async {
    return _db.ensureDayEntry(date);
  }

  Future<Medication?> getMedication(int id) async {
    return _db.getMedication(id);
  }

  Future<IntakeEvent> saveIntakeEvent(IntakeEvent event) async {
    final db = await _db.database;
    final id = await db.insert('intake_events', event.toMap());
    return event.copyWith(id: id);
  }

  Future<DateTime> createIntakeEventFromNotification({
    required int medicationId,
    required DateTime takenAt,
    required String autoLoggedNote,
    required String autoLoggedWithApplicationNote,
    required String autoLoggedWithoutDoseNote,
  }) async {
    final day = DateTime(takenAt.year, takenAt.month, takenAt.day);
    final dayEntry = await _db.ensureDayEntry(day);

    final medication = await _db.getMedication(medicationId);
    final isGel = medication?.type == MedicationType.gel;
    final numerator = medication?.defaultDoseNumerator;
    final den = medication?.defaultDoseDenominator;

    final hasValidDefaultDose =
        numerator != null && den != null && numerator > 0 && den > 0;

    final amountNumerator = (hasValidDefaultDose && !isGel) ? numerator : null;
    final amountDenominator = (hasValidDefaultDose && !isGel) ? den : null;

    final db = await _db.database;
    await db.insert(
      'intake_events',
      IntakeEvent(
        dayEntryId: dayEntry.id!,
        medicationId: medicationId,
        takenAt: takenAt,
        amountNumerator: amountNumerator,
        amountDenominator: amountDenominator,
        note: isGel
            ? autoLoggedWithApplicationNote
            : (hasValidDefaultDose
                  ? autoLoggedNote
                  : autoLoggedWithoutDoseNote),
      ).toMap(),
    );

    return day;
  }

  Future<int?> getIntakeCountByDate(DateTime date) async {
    final db = await _db.database;
    final dateOnly = DateTime(
      date.year,
      date.month,
      date.day,
    ).toIso8601String();

    final rows = await db.rawQuery(
      '''
      SELECT COUNT(i.id) as cnt
      FROM day_entries d
      LEFT JOIN intake_events i ON i.day_entry_id = d.id
      WHERE d.entry_date = ?
    ''',
      [dateOnly],
    );

    if (rows.isEmpty) return 0;
    return (rows.first['cnt'] as int?) ?? 0;
  }

  Future<Map<DateTime, int>> getIntakeCountsBetween(
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

    final rows = await db.rawQuery(
      '''
      SELECT d.entry_date as entry_date, COUNT(i.id) as cnt
      FROM day_entries d
      JOIN intake_events i ON i.day_entry_id = d.id
      WHERE d.entry_date >= ? AND d.entry_date <= ?
      GROUP BY d.entry_date
      HAVING cnt > 0
    ''',
      [startOnly, endOnly],
    );

    final result = <DateTime, int>{};
    for (final row in rows) {
      final raw = row['entry_date'] as String?;
      final cnt = row['cnt'] as int?;
      if (raw == null || cnt == null) continue;

      final dt = DateTime.parse(raw);
      result[DateTime(dt.year, dt.month, dt.day)] = cnt;
    }
    return result;
  }

  Future<List<IntakeEvent>> getIntakeEventsByDay(int dayEntryId) async {
    final db = await _db.database;
    final result = await db.query(
      'intake_events',
      where: 'day_entry_id = ?',
      whereArgs: [dayEntryId],
      orderBy: 'taken_at ASC',
    );
    return result.map((map) => IntakeEvent.fromMap(map)).toList();
  }

  Future<List<IntakeEvent>> getAllIntakeEvents() async {
    final db = await _db.database;
    final result = await db.query('intake_events', orderBy: 'taken_at DESC');
    return result.map((map) => IntakeEvent.fromMap(map)).toList();
  }

  Future<int> updateIntakeEvent(IntakeEvent event) async {
    final db = await _db.database;
    return db.update(
      'intake_events',
      event.toMap(),
      where: 'id = ?',
      whereArgs: [event.id],
    );
  }

  Future<int> deleteIntakeEvent(int id) async {
    final db = await _db.database;
    return await db.delete('intake_events', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteIntakeEventsByDay(int dayEntryId) async {
    final db = await _db.database;
    return await db.delete(
      'intake_events',
      where: 'day_entry_id = ?',
      whereArgs: [dayEntryId],
    );
  }

  Future<void> replaceForDayEntry(
    int dayEntryId,
    List<IntakeEvent> events,
  ) async {
    final db = await _db.database;
    await db.delete(
      'intake_events',
      where: 'day_entry_id = ?',
      whereArgs: [dayEntryId],
    );
    for (final event in events) {
      await db.insert(
        'intake_events',
        event.copyWith(dayEntryId: dayEntryId).toMap(),
      );
    }
  }
}
