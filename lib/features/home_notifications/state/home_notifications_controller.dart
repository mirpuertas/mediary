import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:med_journal/l10n/l10n_lookup.dart';

import '../../sleep/state/sleep_controller.dart';
import '../../../utils/date_parse.dart';
import '../../home/state/home_controller.dart';
import '../data/home_notifications_repository.dart';

sealed class HomeNotificationNavigation {
  const HomeNotificationNavigation();
}

class HomeNotificationNavSleep extends HomeNotificationNavigation {
  final DateTime date;
  const HomeNotificationNavSleep(this.date);
}

class HomeNotificationNavQuickIntake extends HomeNotificationNavigation {
  final int? reminderId;
  final List<int> medicationIds;
  final String? groupName;

  const HomeNotificationNavQuickIntake({
    required this.reminderId,
    required this.medicationIds,
    required this.groupName,
  });
}

class HomeNotificationsController extends ChangeNotifier {
  final HomeNotificationsRepository _repo;

  HomeNotificationsController({required HomeNotificationsRepository repo})
    : _repo = repo;

  HomeController? _home;
  SleepController? _sleepController;

  void updateDependencies({
    required HomeController home,
    required SleepController sleepController,
  }) {
    _home = home;
    _sleepController = sleepController;
  }

  Future<void> processPendingCompletes() async {
    final home = _home;
    final sleepController = _sleepController;
    if (home == null || sleepController == null) return;

    try {
      final l10n = lookupL10n();
      final items = await _repo.consumePendingCompletesDetailed();
      if (items.isEmpty) return;

      final affectedDays = <DateTime>{};

      for (final item in items) {
        try {
          final payload = item['payload'] as String?;
          if (payload == null || payload.isEmpty) continue;

          final ts = (item['ts'] as num?)?.toInt();
          final data = jsonDecode(payload) as Map<String, dynamic>;

          final medicationIds = (data['medicationIds'] is List)
              ? (data['medicationIds'] as List)
                    .whereType<num>()
                    .map((n) => n.toInt())
                    .toList(growable: false)
              : <int>[];

          final singleId = (data['medicationId'] as num?)?.toInt();
          final resolvedMedicationIds = medicationIds.isNotEmpty
              ? medicationIds
              : (singleId != null ? <int>[singleId] : <int>[]);

          if (resolvedMedicationIds.isEmpty) continue;

          final takenAt = ts != null
              ? DateTime.fromMillisecondsSinceEpoch(ts)
              : DateTime.now();

          final days = await _repo.createIntakeEventsFromNotifications(
            medicationIds: resolvedMedicationIds,
            takenAt: takenAt,
            autoLoggedNote: l10n.notificationsAutoLogged,
            autoLoggedWithApplicationNote:
                l10n.notificationsAutoLoggedWithApplication,
            autoLoggedWithoutDoseNote: l10n.quickIntakeAutoLoggedWithoutDose,
          );

          affectedDays.addAll(days);
        } catch (e) {
          if (kDebugMode) {
            debugPrint('HomeNotifications: error guardando evento: $e');
          }
        }
      }

      await sleepController.loadEntries();

      for (final day in affectedDays) {
        await home.refreshIntakesForDay(day);
        if (home.selectedDay == home.dateOnly(day)) {
          await home.loadSelectedDay(day);
        }
      }
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('HomeNotifications: error procesando pending completes: $e');
        debugPrint('$st');
      }
    }
  }

  Future<HomeNotificationNavigation?>
  consumePendingNotificationNavigation() async {
    try {
      final payload = await _repo.consumePendingOpenPayload();
      if (payload == null || payload.isEmpty) return null;

      final data = jsonDecode(payload) as Map<String, dynamic>;

      if (data['type'] == 'sleep') {
        final raw = data['date'];
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final date = parseDateOnly(raw is String ? raw : null, fallback: today);
        return HomeNotificationNavSleep(date);
      }

      final reminderId = (data['reminderId'] as num?)?.toInt();
      final groupReminderId = (data['groupReminderId'] as num?)?.toInt();
      final groupName = data['groupName'] as String?;

      final medicationIds = (data['medicationIds'] is List)
          ? (data['medicationIds'] as List)
                .whereType<num>()
                .map((n) => n.toInt())
                .toList(growable: false)
          : <int>[];

      final medicationId = (data['medicationId'] as num?)?.toInt();
      final resolvedMedicationIds = medicationIds.isNotEmpty
          ? medicationIds
          : (medicationId != null ? <int>[medicationId] : <int>[]);

      if (resolvedMedicationIds.isEmpty) return null;

      return HomeNotificationNavQuickIntake(
        reminderId: reminderId ?? groupReminderId,
        medicationIds: resolvedMedicationIds,
        groupName: groupName,
      );
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('HomeNotifications: error consuming navigation: $e');
        debugPrint('$st');
      }
      return null;
    }
  }
}
