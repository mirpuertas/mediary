import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WaterWidgetService {
  WaterWidgetService._();
  static final WaterWidgetService instance = WaterWidgetService._();

  static const String _keyPrefix = 'water_';

  String _keyForDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$_keyPrefix$y-$m-$d';
  }


  Future<int?> getWaterCount(DateTime date) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload();
      final key = _keyForDate(date);
      if (!prefs.containsKey(key)) return null;
      return prefs.getInt(key);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('WaterWidgetService.getWaterCount error: $e');
      }
      return null;
    }
  }

  Future<void> setWaterCount(DateTime date, int count) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _keyForDate(date);
      await prefs.setInt(key, count.clamp(0, 10));
    } catch (e) {
      if (kDebugMode) {
        debugPrint('WaterWidgetService.setWaterCount error: $e');
      }
    }
  }

  Future<int?> syncFromWidget(DateTime date, int appValue) async {
    final widgetValue = await getWaterCount(date);
    if (widgetValue != null && widgetValue != appValue) {
      return widgetValue;
    }
    return null;
  }

  Future<void> cleanupOldEntries() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();
      final cutoff = now.subtract(const Duration(days: 7));

      final allKeys = prefs.getKeys().where((k) => k.startsWith(_keyPrefix));
      for (final key in allKeys) {
        try {
          final dateStr = key.substring(_keyPrefix.length);
          final parts = dateStr.split('-');
          if (parts.length == 3) {
            final date = DateTime(
              int.parse(parts[0]),
              int.parse(parts[1]),
              int.parse(parts[2]),
            );
            if (date.isBefore(cutoff)) {
              await prefs.remove(key);
            }
          }
        } catch (_) {
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('WaterWidgetService.cleanupOldEntries error: $e');
      }
    }
  }
}
