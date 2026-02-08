import '../../../services/database_helper.dart';

class HabitsRepository {
  final DatabaseHelper _db;

  HabitsRepository({DatabaseHelper? db}) : _db = db ?? DatabaseHelper.instance;

  // ==================== WATER ====================

  Future<int?> getWaterCountByDate(DateTime date) async {
    final db = await _db.database;
    final dateOnly = DateTime(
      date.year,
      date.month,
      date.day,
    ).toIso8601String();

    final rows = await db.query(
      'day_entries',
      columns: ['water_count'],
      where: 'entry_date = ?',
      whereArgs: [dateOnly],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first['water_count'] as int?;
  }

  Future<void> saveWaterCountForDay(DateTime date, int waterCount) async {
    final db = await _db.database;
    final day = await _db.ensureDayEntry(date);

    await db.update(
      'day_entries',
      {'water_count': waterCount},
      where: 'id = ?',
      whereArgs: [day.id],
    );
  }

  // ==================== BLOCKS WALKED ====================

  Future<int?> getBlocksWalkedByDate(DateTime date) async {
    final db = await _db.database;
    final dateOnly = DateTime(
      date.year,
      date.month,
      date.day,
    ).toIso8601String();

    final rows = await db.query(
      'day_entries',
      columns: ['blocks_walked'],
      where: 'entry_date = ?',
      whereArgs: [dateOnly],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first['blocks_walked'] as int?;
  }

  Future<void> saveBlocksWalkedForDay(DateTime date, int? blocksWalked) async {
    final db = await _db.database;
    final day = await _db.ensureDayEntry(date);

    await db.update(
      'day_entries',
      {'blocks_walked': blocksWalked},
      where: 'id = ?',
      whereArgs: [day.id],
    );
  }

  // ==================== HABITS COMBINED ====================

  Future<
    Map<DateTime, ({int? waterCount, int? blocksWalked})>
  >
  getHabitsBetween(DateTime start, DateTime end) async {
    final db = await _db.database;

    final startOnly = DateTime(
      start.year,
      start.month,
      start.day,
    ).toIso8601String();
    final endOnly = DateTime(end.year, end.month, end.day).toIso8601String();

    final rows = await db.query(
      'day_entries',
      columns: ['entry_date', 'water_count', 'blocks_walked'],
      where: '''
        entry_date >= ? AND entry_date <= ?
        AND (
          (water_count IS NOT NULL AND water_count > 0)
          OR (blocks_walked IS NOT NULL AND blocks_walked > 0)
        )
      ''',
      whereArgs: [startOnly, endOnly],
    );

    final result =
        <DateTime, ({int? waterCount, int? blocksWalked})>{};
    for (final row in rows) {
      final rawDate = row['entry_date'] as String?;
      if (rawDate == null) continue;
      final dt = DateTime.parse(rawDate);
      final key = DateTime(dt.year, dt.month, dt.day);

      final waterRaw = row['water_count'] as int?;
      final blocksRaw = row['blocks_walked'] as int?;

      result[key] = (
        waterCount: waterRaw?.clamp(0, 10),
        blocksWalked: blocksRaw?.clamp(0, 1000),
      );
    }
    return result;
  }
}
