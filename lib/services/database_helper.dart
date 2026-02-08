import 'dart:io';

import 'package:sqflite/sqflite.dart' as plain_sqflite;
import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart';

import 'database_key_service.dart';

import '../models/medication.dart';
import '../models/sleep_entry.dart';
import '../models/medication_reminder.dart';
import '../models/day_entry.dart';
import '../models/medication_group.dart';
import '../models/medication_group_reminder.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  static bool _didEnsureSchema = false;
  static Future<Database>? _opening;

  static const int _schemaVersion = 31;
  static const int _squashRecreateVersion = 31;

  DatabaseHelper._init();

  static final DatabaseKeyService _keyService = DatabaseKeyService();

  Future<Database> get database async {
    final existing = _database;
    if (existing != null) {
      if (!_didEnsureSchema) {
        await _ensureSchemaUpToDate(existing);
        _didEnsureSchema = true;
      }
      return existing;
    }

    final inFlight = _opening;
    if (inFlight != null) {
      final db = await inFlight;
      if (!_didEnsureSchema) {
        await _ensureSchemaUpToDate(db);
        _didEnsureSchema = true;
      }
      return db;
    }

    final future = _initDB('med_journal.db');
    _opening = future;
    try {
      final db = await future;
      _database = db;
      if (!_didEnsureSchema) {
        await _ensureSchemaUpToDate(db);
        _didEnsureSchema = true;
      }
      return db;
    } finally {
      _opening = null;
    }
  }

  /// Fuerza una verificación de schema (útil antes de restore/backup).
  Future<void> ensureLatestSchema() async {
    final db = await database;
    await _ensureSchemaUpToDate(db);
    _didEnsureSchema = true;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    final password = await _keyService.getOrCreateKey();

    // Si hay una DB plaintext en el mismo lugar, migrarla.
    await _migratePlaintextIfNeeded(
      dbPath: dbPath,
      encryptedPath: path,
      password: password,
    );

    return await openDatabase(
      path,
      password: password,
      version: _schemaVersion,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  /// Retorna si la DB está encriptada en reposo.
  ///
  /// - `true`: el archivo existe y NO parece una DB SQLite plaintext.
  /// - `false`: el archivo existe y parece una DB SQLite plaintext.
  /// - `null`: el archivo no existe todavía.
  Future<bool?> isDatabaseEncryptedAtRest() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'med_journal.db');
    final file = File(path);
    if (!await file.exists()) return null;
    final isPlaintext = await _isPlaintextSqliteFile(path);
    return !isPlaintext;
  }

  Future<void> _migratePlaintextIfNeeded({
    required String dbPath,
    required String encryptedPath,
    required String password,
  }) async {
    final encryptedFile = File(encryptedPath);
    final legacyPath = join(dbPath, 'med_journal_legacy_plain.db');
    final legacyFile = File(legacyPath);

    // Si una ejecución anterior ya movió la DB plaintext a legacy pero también creó
    // una DB encriptada, finalizar la migración desde legacy (común después de crashes).
    if (await legacyFile.exists()) {
      if (!await encryptedFile.exists()) {
        await _copyPlainToEncrypted(
          plainPath: legacyPath,
          encryptedPath: encryptedPath,
          password: password,
          wipeDestination: true,
        );
        await legacyFile.delete();
        return;
      }

      final encryptedLooksPlaintext = await _isPlaintextSqliteFile(
        encryptedPath,
      );
      if (!encryptedLooksPlaintext) {
        final empty = await _isEncryptedDbEmpty(encryptedPath, password);
        if (empty) {
          await _copyPlainToEncrypted(
            plainPath: legacyPath,
            encryptedPath: encryptedPath,
            password: password,
            wipeDestination: true,
          );
          await legacyFile.delete();
        }
        return;
      }
      // Si encryptedPath es todavía plaintext y legacy existe, continuar con la migración normal.
    }

    if (!await encryptedFile.exists()) return;

    final isPlaintext = await _isPlaintextSqliteFile(encryptedPath);
    if (!isPlaintext) {
      return;
    }

    if (await legacyFile.exists()) {
      try {
        final legacyStat = await legacyFile.stat();
        final currentStat = await encryptedFile.stat();
        final keepCurrent = currentStat.modified.isAfter(legacyStat.modified);
        if (keepCurrent) {
          await legacyFile.delete();
          await encryptedFile.rename(legacyPath);
        }
      } catch (_) {
        // Si falla, mantener la legacy existente.
      }
    } else {
      await encryptedFile.rename(legacyPath);
    }

    // Remover cualquier archivo restante en la ruta encriptada para que SQLCipher pueda crearlo.
    if (await File(encryptedPath).exists()) {
      await File(encryptedPath).delete();
    }

    try {
      await _copyPlainToEncrypted(
        plainPath: legacyPath,
        encryptedPath: encryptedPath,
        password: password,
        wipeDestination: true,
      );

      // Migración exitosa: eliminar la legacy.
      if (await legacyFile.exists()) {
        await legacyFile.delete();
      }
    } catch (e) {
      if (await File(encryptedPath).exists()) {
        try {
          await File(encryptedPath).delete();
        } catch (e) {
          if (kDebugMode) debugPrint('DatabaseHelper: failed to delete legacy encrypted file: $e');
        }
      }

      if (await legacyFile.exists()) {
        try {
          await legacyFile.rename(encryptedPath);
        } catch (e) {
          if (kDebugMode) debugPrint('DatabaseHelper: failed to rename legacy db file: $e');
        }
      }

      rethrow;
    }
  }

  Future<bool> _isPlaintextSqliteFile(String path) async {
    try {
      final file = File(path);
      final raf = await file.open(mode: FileMode.read);
      try {
        final header = await raf.read(16);
        // SQLite plaintext comienza con "SQLite format 3\x00".
        const magic = <int>[
          0x53,
          0x51,
          0x4C,
          0x69,
          0x74,
          0x65,
          0x20,
          0x66,
          0x6F,
          0x72,
          0x6D,
          0x61,
          0x74,
          0x20,
          0x33,
          0x00,
        ];
        if (header.length < magic.length) return false;
        final bytes = Uint8List.fromList(header);
        for (var i = 0; i < magic.length; i++) {
          if (bytes[i] != magic[i]) return false;
        }
        return true;
      } finally {
        await raf.close();
      }
    } catch (_) {
      return false;
    }
  }

  Future<void> _copyPlainToEncrypted({
    required String plainPath,
    required String encryptedPath,
    required String password,
    required bool wipeDestination,
  }) async {
    final plainDb = await plain_sqflite.openDatabase(plainPath);

    final encDb = await openDatabase(
      encryptedPath,
      password: password,
      version: _schemaVersion,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );

    try {
      final plainTables = await _listUserTables(plainDb);

      // Copiar todas las tablas de plaintext -> encriptado, filtrando columnas para coincidir
      // con el schema de destino (maneja diferencias de versión).
      await encDb.transaction((txn) async {
        await txn.execute('PRAGMA foreign_keys = OFF');

        for (final table in plainTables) {
          final destColumns = await _getTableColumns(txn, table);
          if (destColumns.isEmpty) continue;

          if (wipeDestination) {
            await txn.delete(table);
          }

          final rows = await plainDb.query(table);
          for (final row in rows) {
            final filtered = <String, Object?>{};
            for (final entry in row.entries) {
              if (destColumns.contains(entry.key)) {
                filtered[entry.key] = entry.value;
              }
            }
            if (filtered.isNotEmpty) {
              await txn.insert(
                table,
                filtered,
                conflictAlgorithm: ConflictAlgorithm.replace,
              );
            }
          }
        }

        await txn.execute('PRAGMA foreign_keys = ON');
      });

      // Asegurar que el schema esté actualizado para futuras operaciones.
      await _ensureSchemaUpToDate(encDb);
    } finally {
      await plainDb.close();
      await encDb.close();
    }
  }

  Future<List<String>> _listUserTables(plain_sqflite.Database db) async {
    final rows = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'",
    );
    return rows
        .map((r) => r['name'])
        .whereType<String>()
        .where((name) => name != 'android_metadata')
        .toList(growable: false);
  }

  Future<Set<String>> _getTableColumns(
    DatabaseExecutor db,
    String table,
  ) async {
    try {
      final rows = await db.rawQuery('PRAGMA table_info($table)');
      return rows.map((r) => r['name']).whereType<String>().toSet();
    } catch (_) {
      return <String>{};
    }
  }

  Future<bool> _isEncryptedDbEmpty(String path, String password) async {
    try {
      final db = await openDatabase(path, password: password);
      try {
        final counts = await Future.wait<int>([
          _tableCount(db, 'medications'),
          _tableCount(db, 'medication_reminders'),
          _tableCount(db, 'day_entries'),
        ]);
        return counts.every((c) => c == 0);
      } finally {
        await db.close();
      }
    } catch (_) {
      // Si no podemos abrirla, tratar como no vacía para evitar acciones destructivas.
      return false;
    }
  }

  Future<int> _tableCount(DatabaseExecutor db, String table) async {
    try {
      final rows = await db.rawQuery('SELECT COUNT(*) AS c FROM $table');
      final value = rows.first['c'];
      if (value is int) return value;
      if (value is num) return value.toInt();
      return 0;
    } catch (_) {
      return 0;
    }
  }

  Future<void> _createDB(Database db, int version) async {
    await _createSchema(db);
  }

  Future<void> _ensureSchemaUpToDate(Database db) async {
    try {
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='day_entries'",
      );
      if (tables.isEmpty) return;

      final info = await db.rawQuery('PRAGMA table_info(day_entries)');
      final cols = <String>{
        for (final r in info)
          if (r['name'] is String) (r['name'] as String),
      };

      var changed = false;

      if (!cols.contains('day_notes')) {
        await db.execute('ALTER TABLE day_entries ADD COLUMN day_notes TEXT');
        changed = true;
      }
      if (!cols.contains('water_count')) {
        await db.execute(
          'ALTER TABLE day_entries ADD COLUMN water_count INTEGER',
        );
        changed = true;
      }
      if (!cols.contains('blocks_walked')) {
        await db.execute(
          'ALTER TABLE day_entries ADD COLUMN blocks_walked INTEGER',
        );
        changed = true;
      }

      final userVersion =
          Sqflite.firstIntValue(await db.rawQuery('PRAGMA user_version')) ?? 0;
      if (userVersion < _schemaVersion) {
        await db.execute('PRAGMA user_version = $_schemaVersion');
      } else if (changed) {
        await db.execute('PRAGMA user_version = $_schemaVersion');
      }
    } catch (_) {
      // Best-effort: si falla, dejamos que explote con el error real.
    }
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
        blocks_walked INTEGER,
        day_notes TEXT,
        water_count INTEGER
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
    // Destructive migration: recrear el schema desde cero.
    if (oldVersion < _squashRecreateVersion) {
      await db.transaction((txn) async {
        await txn.execute('PRAGMA foreign_keys = OFF');

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
        await txn.execute('PRAGMA foreign_keys = ON');
      });
      return;
    }
  }

  /// DAY ENTRIES (punto de referencia)

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
      'blocks_walked': null,
      'day_notes': null,
      'water_count': null,
    });
    return DayEntry(id: id, entryDate: DateTime.parse(dateOnly));
  }

  /// SLEEP

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

  Future<SleepEntry?> getSleepEntryByDate(DateTime date) async {
    return getSleepFromDay(date);
  }

  // Compatibilidad: el nombre histórico se mantiene, pero la fuente es day_entries.
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

  Future<List<DayEntry>> getAllDayEntries() async {
    final db = await database;
    final result = await db.query('day_entries');
    return result.map((m) => DayEntry.fromMap(m)).toList();
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
