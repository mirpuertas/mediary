import 'package:sqflite/sqflite.dart';

import '../../../models/day_entry.dart';
import '../../../models/intake_event.dart';
import '../../../services/database_helper.dart';

class DayEntryRepository {
  final DatabaseHelper _dbHelper;

  DayEntryRepository({DatabaseHelper? dbHelper})
    : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  Future<DayEntry> getOrCreate(DateTime date) => _dbHelper.ensureDayEntry(date);

  Future<DayEntry?> getByDate(DateTime date) => _dbHelper.getDayEntryByDate(date);


  Future<void> saveDayEntry(DayEntry entry) async {
    final existing = await _dbHelper.ensureDayEntry(entry.entryDate);
    final db = await _dbHelper.database;

    final normalized = entry.copyWith(id: existing.id, entryDate: existing.entryDate);
    final values = normalized.toMap()
      ..remove('id')
      ..remove('entry_date');

    await db.update(
      'day_entries',
      values,
      where: 'id = ?',
      whereArgs: [existing.id],
    );
  }

  Future<void> saveDayEntryWithIntakeEvents({
    required DayEntry entry,
    required List<IntakeEvent> intakeEvents,
  }) async {
    final existing = await _dbHelper.ensureDayEntry(entry.entryDate);
    final db = await _dbHelper.database;

    final normalized = entry.copyWith(id: existing.id, entryDate: existing.entryDate);
    final values = normalized.toMap()
      ..remove('id')
      ..remove('entry_date');

    await db.transaction((txn) async {
      await txn.update(
        'day_entries',
        values,
        where: 'id = ?',
        whereArgs: [existing.id],
      );

      await txn.delete(
        'intake_events',
        where: 'day_entry_id = ?',
        whereArgs: [existing.id],
      );

      for (final event in intakeEvents) {
        final toInsert =
            event.copyWith(id: null, dayEntryId: existing.id).toMap()
              ..remove('id');
        await txn.insert(
          'intake_events',
          toInsert,
          conflictAlgorithm: ConflictAlgorithm.abort,
        );
      }
    });
  }
}

