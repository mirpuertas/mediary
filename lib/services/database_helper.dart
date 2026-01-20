import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import '../models/medication.dart';
import '../models/sleep_entry.dart';
import '../models/intake_event.dart';
import '../models/medication_reminder.dart';
import '../models/day_entry.dart';
import '../models/medication_group.dart';
import '../models/medication_group_reminder.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  static const int _schemaVersion = 21;
  static const int _squashRecreateVersion = 20;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('med_journal.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: _schemaVersion,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await _createSchema(db);
  }

  Future<void> _createSchema(DatabaseExecutor db) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const intType = 'INTEGER NOT NULL';
    const textNullable = 'TEXT';

    // medications
    await db.execute('''
      CREATE TABLE medications (
        id $idType,
        name $textType,
        brand_name $textNullable,
        unit $textType,
        type $textType DEFAULT 'tablet',
        default_dose_numerator INTEGER,
        default_dose_denominator INTEGER,
        is_archived INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // day_entries
    await db.execute('''
      CREATE TABLE day_entries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        entry_date TEXT NOT NULL UNIQUE,
        sleep_quality INTEGER,
        sleep_notes TEXT,
        sleep_duration_minutes INTEGER,
        sleep_continuity INTEGER,
        day_mood INTEGER,
        day_notes TEXT
      )
    ''');

    // intake_events (day_entry_id)
    await db.execute('''
      CREATE TABLE intake_events (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        day_entry_id INTEGER,
        medication_id INTEGER NOT NULL,
        taken_at TEXT NOT NULL,
        amount_numerator INTEGER,
        amount_denominator INTEGER,
        note TEXT,
        FOREIGN KEY (day_entry_id) REFERENCES day_entries (id) ON DELETE SET NULL,
        FOREIGN KEY (medication_id) REFERENCES medications (id) ON DELETE CASCADE,
        CHECK (
          (amount_numerator IS NULL AND amount_denominator IS NULL)
          OR (amount_numerator > 0 AND amount_denominator > 0)
        )
      )
    ''');

    // medication_reminders
    await db.execute('''
      CREATE TABLE medication_reminders (
        id $idType,
        medication_id $intType,
        hour $intType,
        minute $intType,
        days_pattern $textType,
        note $textNullable,
        requires_exact_alarm INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (medication_id) REFERENCES medications (id) ON DELETE CASCADE
      )
    ''');

    // groups
    await db.execute('''
      CREATE TABLE medication_groups (
        id $idType,
        name $textType,
        is_archived INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE medication_group_members (
        group_id INTEGER NOT NULL,
        medication_id INTEGER NOT NULL,
        PRIMARY KEY (group_id, medication_id),
        FOREIGN KEY (group_id) REFERENCES medication_groups (id) ON DELETE CASCADE,
        FOREIGN KEY (medication_id) REFERENCES medications (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE medication_group_reminders (
        id $idType,
        group_id INTEGER NOT NULL,
        hour $intType,
        minute $intType,
        days_pattern $textType,
        note $textNullable,
        requires_exact_alarm INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (group_id) REFERENCES medication_groups (id) ON DELETE CASCADE
      )
    ''');

    // indices
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_day_entries_date ON day_entries(entry_date)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_intake_events_day ON intake_events(day_entry_id)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_intake_events_taken ON intake_events(taken_at)',
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < _squashRecreateVersion) {
      await db.transaction((txn) async {
        await txn.execute('DROP TABLE IF EXISTS intake_events');
        await txn.execute('DROP TABLE IF EXISTS medication_group_members');
        await txn.execute('DROP TABLE IF EXISTS medication_group_reminders');
        await txn.execute('DROP TABLE IF EXISTS medication_groups');
        await txn.execute('DROP TABLE IF EXISTS medication_reminders');

        await txn.execute('DROP TABLE IF EXISTS sleep_entries');
        await txn.execute('DROP TABLE IF EXISTS day_entries');
        await txn.execute('DROP TABLE IF EXISTS medications');

        await txn.execute('DROP TABLE IF EXISTS medication_doses');
        await txn.execute('DROP TABLE IF EXISTS sleep_entry_medications');

        await _createSchema(txn);
      });
    }

    // v21: agrega notas del día (separadas de sleep_notes).
    if (oldVersion >= _squashRecreateVersion && oldVersion < 21) {
      await db.execute('ALTER TABLE day_entries ADD COLUMN day_notes TEXT');
    }
  }

  /// DAY ENTRIES (source of truth)

  Future<DayEntry> ensureDayEntry(DateTime date) async {
    final db = await database;
    final dateOnly = DateTime(
      date.year,
      date.month,
      date.day,
    ).toIso8601String();

    final existing = await db.query(
      'day_entries',
      where: 'entry_date = ?',
      whereArgs: [dateOnly],
    );
    if (existing.isNotEmpty) return DayEntry.fromMap(existing.first);

    final id = await db.insert('day_entries', {
      'entry_date': dateOnly,
      'sleep_quality': null,
      'sleep_notes': null,
      'sleep_duration_minutes': null,
      'sleep_continuity': null,
      'day_mood': null,
      'day_notes': null,
    });
    return DayEntry(id: id, entryDate: DateTime.parse(dateOnly));
  }

  Future<DayEntry?> getDayEntryByDate(DateTime date) async {
    final db = await database;
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

  Future<void> saveSleepForDay(
    DateTime date,
    int? quality,
    String? notes, {
    int? sleepDurationMinutes,
    int? sleepContinuity,
  }) async {
    final db = await database;
    final day = await ensureDayEntry(date);

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

  Future<List<SleepEntry>> getAllSleepEntriesFromDayEntries() async {
    final db = await database;

    final rows = await db.query(
      'day_entries',
      where: 'sleep_quality IS NOT NULL',
      orderBy: 'entry_date DESC',
    );

    return rows
        .map((row) {
          final day = DayEntry.fromMap(row);
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
        })
        .toList(growable: false);
  }

  Future<Map<String, int>> getSleepDaysCountByMonthFromDayEntries() async {
    final db = await database;

    final result = await db.rawQuery('''
      SELECT strftime('%Y-%m', entry_date) as month, COUNT(*) as count
      FROM day_entries
      WHERE sleep_quality IS NOT NULL
      GROUP BY month
      ORDER BY month DESC
    ''');

    final Map<String, int> counts = {};
    for (final row in result) {
      final month = row['month'] as String?;
      final count = row['count'] as int?;
      if (month == null) continue;
      counts[month] = count ?? 0;
    }
    return counts;
  }

  Future<int?> getDayMoodByDate(DateTime date) async {
    final db = await database;
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

  Future<String?> getDayNotesByDate(DateTime date) async {
    final db = await database;
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

  Future<void> saveDayMoodForDay(DateTime date, int? mood) async {
    final db = await database;
    final day = await ensureDayEntry(date);

    await db.update(
      'day_entries',
      {'day_mood': mood},
      where: 'id = ?',
      whereArgs: [day.id],
    );
  }

  Future<void> saveDayNotesForDay(DateTime date, String? notes) async {
    final db = await database;
    final day = await ensureDayEntry(date);

    await db.update(
      'day_entries',
      {'day_notes': notes},
      where: 'id = ?',
      whereArgs: [day.id],
    );
  }

  Future<Map<DateTime, int>> getDayMoodsBetween(
    DateTime start,
    DateTime end,
  ) async {
    final db = await database;

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

  Future<Map<DateTime, int>> getSleepQualitiesBetween(
    DateTime start,
    DateTime end,
  ) async {
    final db = await database;

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

  Future<void> deleteFullDayRecordByDate(DateTime date) async {
    final db = await database;
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

  /// SLEEP

  Future<SleepEntry?> getSleepEntryByDate(DateTime date) async {
    return getSleepFromDay(date);
  }

  // Compat: el nombre histórico se mantiene, pero la fuente es day_entries.
  Future<SleepEntry> saveSleepEntry(SleepEntry entry) async {
    final dateOnly = DateTime(
      entry.nightDate.year,
      entry.nightDate.month,
      entry.nightDate.day,
    );

    await saveSleepForDay(
      dateOnly,
      entry.sleepQuality,
      entry.notes,
      sleepDurationMinutes: entry.sleepDurationMinutes,
      sleepContinuity: entry.sleepContinuity,
    );

    return entry.copyWith(id: null, nightDate: dateOnly);
  }

  Future<List<SleepEntry>> getAllSleepEntries() async {
    return getAllSleepEntriesFromDayEntries();
  }

  Future<Map<String, int>> getSleepEntriesCountByMonth() async {
    return getSleepDaysCountByMonthFromDayEntries();
  }

  /// INTAKE EVENTS

  Future<IntakeEvent> saveIntakeEvent(IntakeEvent event) async {
    final db = await database;
    final id = await db.insert('intake_events', event.toMap());
    return event.copyWith(id: id);
  }

  Future<List<IntakeEvent>> getIntakeEventsByDay(int dayEntryId) async {
    final db = await database;
    final result = await db.query(
      'intake_events',
      where: 'day_entry_id = ?',
      whereArgs: [dayEntryId],
      orderBy: 'taken_at ASC',
    );
    return result.map((map) => IntakeEvent.fromMap(map)).toList();
  }

  Future<List<IntakeEvent>> getAllIntakeEvents() async {
    final db = await database;
    final result = await db.query('intake_events', orderBy: 'taken_at DESC');
    return result.map((map) => IntakeEvent.fromMap(map)).toList();
  }

  Future<int> updateIntakeEvent(IntakeEvent event) async {
    final db = await database;
    return db.update(
      'intake_events',
      event.toMap(),
      where: 'id = ?',
      whereArgs: [event.id],
    );
  }

  Future<int> deleteIntakeEvent(int id) async {
    final db = await database;
    return await db.delete('intake_events', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteIntakeEventsByDay(int dayEntryId) async {
    final db = await database;
    return await db.delete(
      'intake_events',
      where: 'day_entry_id = ?',
      whereArgs: [dayEntryId],
    );
  }

  Future<Map<DateTime, int>> getIntakeCountsBetween(
    DateTime start,
    DateTime end,
  ) async {
    final db = await database;

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

  Future<int?> getIntakeCountByDate(DateTime date) async {
    final db = await database;
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

  /// GROUPS

  Future<MedicationGroup> createMedicationGroup(MedicationGroup group) async {
    final db = await database;
    final id = await db.insert('medication_groups', group.toMap());
    return group.copyWith(id: id);
  }

  Future<List<MedicationGroup>> getAllMedicationGroups({
    bool includeArchived = false,
  }) async {
    final db = await database;
    final result = await db.query(
      'medication_groups',
      where: includeArchived ? null : 'is_archived = 0',
      orderBy: 'LOWER(name) ASC',
    );
    return result.map((m) => MedicationGroup.fromMap(m)).toList();
  }

  Future<int> updateMedicationGroup(MedicationGroup group) async {
    final db = await database;
    return db.update(
      'medication_groups',
      group.toMap(),
      where: 'id = ?',
      whereArgs: [group.id],
    );
  }

  Future<int> archiveMedicationGroup(int id) async {
    final db = await database;
    return db.update(
      'medication_groups',
      {'is_archived': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> unarchiveMedicationGroup(int id) async {
    final db = await database;
    return db.update(
      'medication_groups',
      {'is_archived': 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteMedicationGroup(int id) async {
    final db = await database;
    return db.delete('medication_groups', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> setMedicationGroupMembers({
    required int groupId,
    required List<int> medicationIds,
  }) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete(
        'medication_group_members',
        where: 'group_id = ?',
        whereArgs: [groupId],
      );
      for (final medId in medicationIds) {
        await txn.insert('medication_group_members', {
          'group_id': groupId,
          'medication_id': medId,
        });
      }
    });
  }

  Future<List<int>> getMedicationGroupMemberIds(int groupId) async {
    final db = await database;
    final result = await db.query(
      'medication_group_members',
      columns: ['medication_id'],
      where: 'group_id = ?',
      whereArgs: [groupId],
    );
    return result.map((r) => r['medication_id'] as int).toList();
  }

  Future<List<Medication>> getMedicationGroupMembers(int groupId) async {
    final ids = await getMedicationGroupMemberIds(groupId);
    if (ids.isEmpty) return [];

    final all = await getAllMedications();
    final setIds = ids.toSet();

    final members = all
        .where((m) => m.id != null && setIds.contains(m.id))
        .toList();
    members.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );
    return members;
  }

  /// GROUP REMINDERS

  Future<int> createGroupReminder(MedicationGroupReminder reminder) async {
    final db = await database;
    return db.insert('medication_group_reminders', reminder.toMap());
  }

  Future<int> updateGroupReminder(MedicationGroupReminder reminder) async {
    final db = await database;
    return db.update(
      'medication_group_reminders',
      reminder.toMap(),
      where: 'id = ?',
      whereArgs: [reminder.id],
    );
  }

  Future<int> deleteGroupReminder(int id) async {
    final db = await database;
    return db.delete(
      'medication_group_reminders',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<MedicationGroupReminder>> getAllGroupReminders() async {
    final db = await database;
    final result = await db.query('medication_group_reminders');
    return result.map((m) => MedicationGroupReminder.fromMap(m)).toList();
  }

  Future<List<MedicationGroupReminder>> getGroupRemindersByGroup(
    int groupId,
  ) async {
    final db = await database;
    final result = await db.query(
      'medication_group_reminders',
      where: 'group_id = ?',
      whereArgs: [groupId],
      orderBy: 'hour ASC, minute ASC',
    );
    return result.map((m) => MedicationGroupReminder.fromMap(m)).toList();
  }

  Future<MedicationGroup?> getMedicationGroup(int id) async {
    final db = await database;
    final maps = await db.query(
      'medication_groups',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return MedicationGroup.fromMap(maps.first);
  }

  Future<List<Map<String, dynamic>>> getTodayGroupReminders() async {
    final now = DateTime.now();
    final weekday = now.weekday;

    final reminders = await getAllGroupReminders();
    final today = <Map<String, dynamic>>[];

    for (final reminder in reminders) {
      if (!reminder.daysOfWeek.contains(weekday)) continue;

      final group = await getMedicationGroup(reminder.groupId);
      if (group == null || group.isArchived) continue;

      final meds = await getMedicationGroupMembers(reminder.groupId);
      final activeMeds = meds.where((m) => !m.isArchived).toList();
      if (activeMeds.isEmpty) continue;

      today.add({
        'reminder': reminder,
        'group': group,
        'medications': activeMeds,
      });
    }

    today.sort((a, b) {
      final ra = a['reminder'] as MedicationGroupReminder;
      final rb = b['reminder'] as MedicationGroupReminder;
      final ta = ra.hour * 60 + ra.minute;
      final tb = rb.hour * 60 + rb.minute;
      return ta.compareTo(tb);
    });

    return today;
  }

  /// MEDICATIONS

  Future<Medication> createMedication(Medication medication) async {
    final db = await database;
    final id = await db.insert('medications', medication.toMap());
    return medication.copyWith(id: id);
  }

  Future<List<Medication>> getAllMedications() async {
    final db = await database;
    final result = await db.query('medications', orderBy: 'LOWER(name) ASC');
    return result.map((map) => Medication.fromMap(map)).toList();
  }

  Future<List<Medication>> getActiveMedications() async {
    final db = await database;
    final result = await db.query(
      'medications',
      where: 'is_archived = 0',
      orderBy: 'LOWER(name) ASC',
    );
    return result.map((map) => Medication.fromMap(map)).toList();
  }

  Future<List<Medication>> getArchivedMedications() async {
    final db = await database;
    final result = await db.query(
      'medications',
      where: 'is_archived = 1',
      orderBy: 'LOWER(name) ASC',
    );
    return result.map((map) => Medication.fromMap(map)).toList();
  }

  Future<Medication?> getMedication(int id) async {
    final db = await database;
    final maps = await db.query(
      'medications',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return Medication.fromMap(maps.first);
  }

  Future<int> updateMedication(Medication medication) async {
    final db = await database;
    return db.update(
      'medications',
      medication.toMap(),
      where: 'id = ?',
      whereArgs: [medication.id],
    );
  }

  Future<int> archiveMedication(int id) async {
    final db = await database;
    return db.update(
      'medications',
      {'is_archived': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> unarchiveMedication(int id) async {
    final db = await database;
    return db.update(
      'medications',
      {'is_archived': 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteMedication(int id) async {
    final db = await database;
    return await db.delete('medications', where: 'id = ?', whereArgs: [id]);
  }

  /// MEDICATION REMINDERS

  Future<int> createReminder(MedicationReminder reminder) async {
    final db = await database;
    return await db.insert('medication_reminders', reminder.toMap());
  }

  Future<List<MedicationReminder>> getAllReminders() async {
    final db = await database;
    final result = await db.query('medication_reminders');
    return result.map((map) => MedicationReminder.fromMap(map)).toList();
  }

  Future<List<MedicationReminder>> getRemindersByMedication(
    int medicationId,
  ) async {
    final db = await database;
    final result = await db.query(
      'medication_reminders',
      where: 'medication_id = ?',
      whereArgs: [medicationId],
      orderBy: 'hour ASC, minute ASC',
    );
    return result.map((map) => MedicationReminder.fromMap(map)).toList();
  }

  Future<int> deleteRemindersByMedication(int medicationId) async {
    final db = await database;
    return db.delete(
      'medication_reminders',
      where: 'medication_id = ?',
      whereArgs: [medicationId],
    );
  }

  Future<MedicationReminder?> getReminderById(int id) async {
    final db = await database;
    final result = await db.query(
      'medication_reminders',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (result.isEmpty) return null;
    return MedicationReminder.fromMap(result.first);
  }

  Future<int> updateReminder(MedicationReminder reminder) async {
    final db = await database;
    return await db.update(
      'medication_reminders',
      reminder.toMap(),
      where: 'id = ?',
      whereArgs: [reminder.id],
    );
  }

  Future<int> deleteReminder(int id) async {
    final db = await database;
    return await db.delete(
      'medication_reminders',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Map<String, dynamic>>> getTodayReminders() async {
    final now = DateTime.now();
    final weekday = now.weekday;

    final reminders = await getAllReminders();
    final todayReminders = <Map<String, dynamic>>[];

    for (final reminder in reminders) {
      if (!reminder.daysOfWeek.contains(weekday)) continue;

      final medication = await getMedication(reminder.medicationId);
      if (medication != null && !medication.isArchived) {
        todayReminders.add({'reminder': reminder, 'medication': medication});
      }
    }

    todayReminders.sort((a, b) {
      final remA = a['reminder'] as MedicationReminder;
      final remB = b['reminder'] as MedicationReminder;
      final timeA = remA.hour * 60 + remA.minute;
      final timeB = remB.hour * 60 + remB.minute;
      return timeA.compareTo(timeB);
    });

    return todayReminders;
  }

  /// UTIL

  Future<void> wipeAllData() async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('medication_group_members');
      await txn.delete('medication_group_reminders');
      await txn.delete('medication_groups');
      await txn.delete('intake_events');
      await txn.delete('day_entries');
      await txn.delete('medication_reminders');
      await txn.delete('medications');
    });
  }

  Future<void> close() async {
    final db = await database;
    db.close();
  }
}
