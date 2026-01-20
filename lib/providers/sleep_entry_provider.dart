import 'package:flutter/foundation.dart';
import '../models/sleep_entry.dart';
import '../models/intake_event.dart';
import '../models/day_entry.dart';
import '../services/database_helper.dart';

class SleepEntryProvider with ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  List<SleepEntry> _entries = [];
  final Map<int, List<IntakeEvent>> _eventsByDayEntryId = {};
  bool _isLoading = false;

  List<SleepEntry> get entries => _entries;
  bool get isLoading => _isLoading;

  Future<void> loadEntries() async {
    _isLoading = true;
    notifyListeners();

    try {
      _entries = await _dbHelper.getAllSleepEntriesFromDayEntries();
    } catch (e) {
      debugPrint('Error cargando registros: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<SleepEntry?> getEntryByDate(DateTime date) async {
    try {
      return await _dbHelper.getSleepEntryByDate(date);
    } catch (e) {
      debugPrint('Error buscando registro por fecha: $e');
      return null;
    }
  }

  Future<List<IntakeEvent>> getEventsForDayEntry(int dayEntryId) async {
    if (_eventsByDayEntryId.containsKey(dayEntryId)) {
      return _eventsByDayEntryId[dayEntryId]!;
    }

    try {
      final events = await _dbHelper.getIntakeEventsByDay(dayEntryId);
      _eventsByDayEntryId[dayEntryId] = events;
      return events;
    } catch (e) {
      debugPrint('Error cargando eventos: $e');
      return [];
    }
  }

  void clearDayCache(int dayEntryId) {
    _eventsByDayEntryId.remove(dayEntryId);
  }

  /// Guardar o actualizar registro de sueño con sus eventos
  ///
  /// - Sueño: se guarda SOLO en day_entries
  /// - Medicación: se guarda en intake_events asociado a day_entries
  Future<void> saveSleepEntry({
    required DateTime nightDate,
    required int? sleepQuality,
    String? notes,
    int? sleepDurationMinutes,
    int? sleepContinuity,
    required List<IntakeEvent> intakeEvents,
  }) async {
    try {
      final cleanedNotes = notes?.trim().isEmpty == true ? null : notes?.trim();

      final DayEntry dayEntry = await _dbHelper.ensureDayEntry(nightDate);

      if (sleepQuality == null) {
        final hasAnySleepDetails =
            cleanedNotes != null ||
            sleepDurationMinutes != null ||
            sleepContinuity != null;

        if (hasAnySleepDetails) {
          throw ArgumentError(
            'sleepQuality is required when saving sleep details.',
          );
        }

        await _dbHelper.saveSleepForDay(
          nightDate,
          null,
          null,
          sleepDurationMinutes: null,
          sleepContinuity: null,
        );
      } else {
        await _dbHelper.saveSleepForDay(
          nightDate,
          sleepQuality,
          cleanedNotes,
          sleepDurationMinutes: sleepDurationMinutes,
          sleepContinuity: sleepContinuity,
        );
      }

      await _dbHelper.deleteIntakeEventsByDay(dayEntry.id!);

      for (final event in intakeEvents) {
        final eventWithDay = event.copyWith(dayEntryId: dayEntry.id!);
        await _dbHelper.saveIntakeEvent(eventWithDay);
      }

      clearDayCache(dayEntry.id!);
      await loadEntries();
    } catch (e) {
      debugPrint('Error guardando registro: $e');
      rethrow;
    }
  }

  Future<void> deleteSleepByDate(DateTime date) async {
    try {
      await _dbHelper.saveSleepForDay(
        date,
        null,
        null,
        sleepDurationMinutes: null,
        sleepContinuity: null,
      );

      await loadEntries();
    } catch (e) {
      debugPrint('Error eliminando sueño por fecha: $e');
      rethrow;
    }
  }

  Future<Map<String, int>> getEntriesCountByMonth() async {
    try {
      return await _dbHelper.getSleepDaysCountByMonthFromDayEntries();
    } catch (e) {
      debugPrint('Error obteniendo conteo por mes: $e');
      return {};
    }
  }
}
