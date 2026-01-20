import 'dart:convert';
import 'dart:ui' show DartPluginRegistrant;

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../app/navigation.dart';
import '../models/intake_event.dart';
import '../models/medication.dart';
import '../models/medication_reminder.dart';
import '../models/medication_group_reminder.dart';
import '../models/medication_group.dart';
import '../screens/daily_entry_screen.dart';
import '../screens/quick_intake_screen.dart';
import 'database_helper.dart';

class NotificationService {
  static final NotificationService instance = NotificationService._init();
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  NotificationService._init();

  // Canales
  static const String _dailyChannelId = 'daily_reminder_v2';
  static const String _dailyChannelName = 'Recordatorio diario';
  static const String _dailyChannelDescription =
      'Recordatorio para registrar el sueño diariamente';

  static const String _medChannelId = 'medication_reminders_v2';
  static const String _medChannelName = 'Recordatorios de medicación';
  static const String _medChannelDescription =
      'Alarmas para tomar medicamentos';

  // IDs one-shot (snooze) para NO pisar schedules recurrentes
  static const int _snoozeIdOffset = 9000000;
  static const int _maxNotificationId = 2147483647;
  int _makeSnoozeNotificationId({
    required int reminderId,
    required int medicationId,
    required bool fromGroup,
  }) {
    final base = _snoozeIdOffset;
    final range = _maxNotificationId - base - 1;
    if (range <= 0) return base;

    final seed = (reminderId * 1000003) ^ (medicationId * 9176);
    final namespaced = seed ^ (fromGroup ? 0x5f3759df : 0);
    final idx = namespaced.abs() % range;
    return base + idx + 1;
  }

  // IDs para notificaciones recurrentes de grupos (evita colisiones con reminder.id)
  static const int _groupNotifIdOffset = 5000000;

  // Pending navigation (tap / "Elegir")
  static const String _pendingOpenKey = 'pending_notification_payload';

  // Pending completes (cuando "Tomé todo" ocurre con app cerrada)
  static const String _pendingCompletesKey = 'pending_complete_payloads';

  // Para mostrar "pospuestos" en HomeScreen
  static const String _snoozedListKey = 'snoozed_notifications';

  /// INIT

  Future<void> initialize() async {
    tz_data.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const initSettings = InitializationSettings(android: androidSettings);

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    final android = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (android != null) {
      await android.createNotificationChannel(
        const AndroidNotificationChannel(
          _dailyChannelId,
          _dailyChannelName,
          description: _dailyChannelDescription,
          importance: Importance.high,
          playSound: true,
        ),
      );

      await android.createNotificationChannel(
        const AndroidNotificationChannel(
          _medChannelId,
          _medChannelName,
          description: _medChannelDescription,
          importance: Importance.max,
          playSound: true,
        ),
      );
    }
  }

  // En background, Android puede levantar un isolate "frío".
  // Re-inicializamos timezones + plugin.
  Future<void> ensureInitializedForBackground() async {
    tz_data.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const initSettings = InitializationSettings(android: androidSettings);

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );
  }

  /// PENDING OPEN

  Future<void> storePendingOpen(String payload) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pendingOpenKey, payload);
  }

  Future<String?> consumePendingOpen() async {
    final prefs = await SharedPreferences.getInstance();
    final p = prefs.getString(_pendingOpenKey);
    if (p != null) {
      await prefs.remove(_pendingOpenKey);
    }
    return p;
  }

  // Limpia estado persistido usado para navegación/acciones de notificaciones.
  //
  // - pending open (tap)
  // - cola de "completados" en background
  // - lista de pospuestos
  Future<void> clearLocalNotificationState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pendingOpenKey);
    await prefs.remove(_pendingCompletesKey);
    await prefs.remove(_snoozedListKey);
  }

  // Cancela TODAS las notificaciones (diarias, medicación y pospuestas).
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  /// PENDING COMPLETE QUEUE

  Future<void> enqueuePendingComplete(String payload) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_pendingCompletesKey);

    List<dynamic> list;
    try {
      list = raw == null || raw.isEmpty ? <dynamic>[] : jsonDecode(raw) as List;
    } catch (_) {
      list = <dynamic>[];
    }

    list.add({'payload': payload, 'ts': DateTime.now().millisecondsSinceEpoch});

    final cutoff = DateTime.now()
        .subtract(const Duration(hours: 48))
        .millisecondsSinceEpoch;
    list = list
        .where((e) {
          if (e is! Map) return false;
          final ts = (e['ts'] as num?)?.toInt() ?? 0;
          return ts >= cutoff;
        })
        .toList(growable: false);

    await prefs.setString(_pendingCompletesKey, jsonEncode(list));
  }

  Future<List<String>> consumePendingCompletes() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_pendingCompletesKey);

    if (raw == null || raw.isEmpty) return <String>[];

    List<dynamic> list;
    try {
      list = jsonDecode(raw) as List<dynamic>;
    } catch (_) {
      return <String>[];
    }

    await prefs.remove(_pendingCompletesKey);

    final payloads = <String>[];
    for (final e in list) {
      if (e is! Map) continue;
      final p = e['payload'];
      if (p is String && p.isNotEmpty) payloads.add(p);
    }
    return payloads;
  }

  // Igual que [consumePendingCompletes] pero preserva el timestamp
  // original (cuando el usuario tocó el botón en la notificación).
  Future<List<Map<String, dynamic>>> consumePendingCompletesDetailed() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_pendingCompletesKey);

    if (raw == null || raw.isEmpty) return <Map<String, dynamic>>[];

    List<dynamic> list;
    try {
      list = jsonDecode(raw) as List<dynamic>;
    } catch (_) {
      return <Map<String, dynamic>>[];
    }

    await prefs.remove(_pendingCompletesKey);

    final result = <Map<String, dynamic>>[];
    for (final e in list) {
      if (e is! Map) continue;
      final p = e['payload'];
      final ts = (e['ts'] as num?)?.toInt();
      if (p is String && p.isNotEmpty) {
        result.add({'payload': p, if (ts != null) 'ts': ts});
      }
    }
    return result;
  }

  /// SNOOZED LIST

  Future<void> _removeSnoozedByNotificationId(int? notificationId) async {
    if (notificationId == null) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_snoozedListKey);

    List<dynamic> list;
    try {
      list = raw == null || raw.isEmpty
          ? <dynamic>[]
          : jsonDecode(raw) as List<dynamic>;
    } catch (_) {
      return;
    }

    final kept = <Map<String, dynamic>>[];
    var changed = false;

    for (final item in list) {
      if (item is! Map) continue;
      final m = Map<String, dynamic>.from(item);
      final id = (m['id'] as num?)?.toInt();
      if (id == null) continue;
      if (id == notificationId) {
        changed = true;
        continue;
      }
      kept.add(m);
    }

    if (!changed) return;
    await prefs.setString(_snoozedListKey, jsonEncode(kept));
  }

  Future<void> cancelSnoozesForReminderId(
    int reminderId, {
    int? medicationId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_snoozedListKey);

    List<dynamic> list;
    try {
      list = raw == null || raw.isEmpty
          ? <dynamic>[]
          : jsonDecode(raw) as List<dynamic>;
    } catch (_) {
      list = <dynamic>[];
    }

    final kept = <Map<String, dynamic>>[];
    final toCancel = <int>[];

    for (final item in list) {
      if (item is! Map) continue;
      final m = Map<String, dynamic>.from(item);
      final id = (m['id'] as num?)?.toInt();
      final rid = (m['reminderId'] as num?)?.toInt();
      final mid = (m['medicationId'] as num?)?.toInt();
      if (id == null || rid == null || mid == null) continue;

      final matches =
          rid == reminderId && (medicationId == null || mid == medicationId);
      if (matches) {
        toCancel.add(id);
      } else {
        kept.add(m);
      }
    }

    for (final id in toCancel) {
      await _notifications.cancel(id);
    }

    if (toCancel.isNotEmpty) {
      await prefs.setString(_snoozedListKey, jsonEncode(kept));
    }
  }

  Future<void> _storeSnoozed({
    required int snoozeId,
    required int reminderId,
    required int medicationId,
    String? groupName,
    required DateTime scheduledAt,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_snoozedListKey);

    List<dynamic> list;
    try {
      list = raw == null || raw.isEmpty
          ? <dynamic>[]
          : jsonDecode(raw) as List<dynamic>;
    } catch (_) {
      list = <dynamic>[];
    }

    final cutoffMs = DateTime.now()
        .subtract(const Duration(hours: 48))
        .millisecondsSinceEpoch;

    final kept = <Map<String, dynamic>>[];
    for (final item in list) {
      if (item is! Map) continue;
      final m = Map<String, dynamic>.from(item);
      final scheduledMs = (m['scheduledAt'] as num?)?.toInt() ?? 0;
      if (scheduledMs >= cutoffMs) {
        kept.add(m);
      }
    }

    kept.removeWhere((m) => (m['id'] as num?)?.toInt() == snoozeId);
    kept.add({
      'id': snoozeId,
      'reminderId': reminderId,
      'medicationId': medicationId,
      if (groupName != null && groupName.trim().isNotEmpty)
        'groupName': groupName.trim(),
      'scheduledAt': scheduledAt.millisecondsSinceEpoch,
    });

    await prefs.setString(_snoozedListKey, jsonEncode(kept));
  }

  Future<List<Map<String, dynamic>>> getTodaySnoozedReminders() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_snoozedListKey);

    List<dynamic> list;
    try {
      list = raw == null || raw.isEmpty
          ? <dynamic>[]
          : jsonDecode(raw) as List<dynamic>;
    } catch (_) {
      list = <dynamic>[];
    }

    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 1));

    final result = <Map<String, dynamic>>[];

    for (final item in list) {
      if (item is! Map) continue;
      final m = Map<String, dynamic>.from(item);
      final scheduledMs = (m['scheduledAt'] as num?)?.toInt();
      final reminderId = (m['reminderId'] as num?)?.toInt();
      final medicationId = (m['medicationId'] as num?)?.toInt();
      final groupName = m['groupName'] as String?;

      if (scheduledMs == null || reminderId == null || medicationId == null) {
        continue;
      }

      final scheduledAt = DateTime.fromMillisecondsSinceEpoch(scheduledMs);
      if (scheduledAt.isBefore(start) || !scheduledAt.isBefore(end)) continue;

      final medication = await DatabaseHelper.instance.getMedication(
        medicationId,
      );

      // Si el medicamento está archivado, no mostrar snoozes en Home.
      if (medication?.isArchived == true) {
        continue;
      }

      result.add({
        'scheduledAt': scheduledAt,
        'reminderId': reminderId,
        'medicationId': medicationId,
        'medication': medication,
        'groupName': groupName,
      });
    }

    result.sort((a, b) {
      final ta = a['scheduledAt'] as DateTime;
      final tb = b['scheduledAt'] as DateTime;
      return ta.compareTo(tb);
    });

    return result;
  }

  /// HANDLER (FOREGROUND)

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  String _formatDateOnly(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  DateTime? _parseDateOnly(dynamic raw) {
    if (raw is! String) return null;
    final parts = raw.split('-');
    if (parts.length != 3) return null;
    final y = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    final d = int.tryParse(parts[2]);
    if (y == null || m == null || d == null) return null;
    return DateTime(y, m, d);
  }

  Future<void> _onNotificationTapped(NotificationResponse response) async {
    final payload = response.payload;
    if (payload == null || payload.isEmpty) return;

    try {
      final data = jsonDecode(payload) as Map<String, dynamic>;

      // Si fue una notificación pospuesta, al interactuar la sacamos de la lista
      // (evita snoozes "fantasma" en Home y ayuda a evitar alarmas colgadas).
      await _removeSnoozedByNotificationId(response.id);

      if (data['type'] == 'sleep') {
        final date = _parseDateOnly(data['date']) ?? _dateOnly(DateTime.now());

        if (navigatorKey.currentState != null) {
          navigatorKey.currentState!.push(
            MaterialPageRoute(
              builder: (_) => DailyEntryScreen(selectedDate: date),
            ),
          );
        } else {
          await storePendingOpen(payload);
        }
        return;
      }

      final reminderId = (data['reminderId'] as num?)?.toInt();
      final groupReminderId = (data['groupReminderId'] as num?)?.toInt();
      final medicationId = (data['medicationId'] as num?)?.toInt();
      final groupName = data['groupName'] as String?;
      final firedNotificationId = response.id;

      final medicationIds = (data['medicationIds'] is List)
          ? (data['medicationIds'] as List)
                .whereType<num>()
                .map((n) => n.toInt())
                .toList(growable: false)
          : <int>[];

      final resolvedMedicationIds = medicationIds.isNotEmpty
          ? medicationIds
          : (medicationId != null ? <int>[medicationId] : <int>[]);

      final effectiveReminderId = reminderId ?? groupReminderId;
      final isGroup = resolvedMedicationIds.length > 1;

      if (response.actionId == 'snooze') {
        if (!isGroup) {
          if (effectiveReminderId == null || resolvedMedicationIds.isEmpty) {
            return;
          }
          await snoozeFromAction(
            firedNotificationId: firedNotificationId,
            reminderId: effectiveReminderId,
            medicationId: resolvedMedicationIds.first,
            delay: const Duration(minutes: 5),
          );
        } else {
          await snoozeGroupFromAction(
            firedNotificationId: firedNotificationId,
            payload: payload,
            delay: const Duration(minutes: 5),
          );
        }
        return;
      }

      if (response.actionId == 'complete') {
        bool ok;
        if (!isGroup) {
          if (effectiveReminderId == null || resolvedMedicationIds.isEmpty) {
            return;
          }
          ok = await completeFromActionForeground(
            firedNotificationId: firedNotificationId,
            reminderId: effectiveReminderId,
            medicationId: resolvedMedicationIds.first,
          );
        } else {
          ok = await completeManyFromActionForeground(
            firedNotificationId: firedNotificationId,
            medicationIds: resolvedMedicationIds,
          );
        }

        if (!ok) {
          if (navigatorKey.currentState != null) {
            navigatorKey.currentState!.push(
              MaterialPageRoute(
                builder: (_) => QuickIntakeScreen(
                  reminderId: effectiveReminderId,
                  medicationIds: resolvedMedicationIds,
                  groupName: groupName,
                ),
              ),
            );
          } else {
            await storePendingOpen(payload);
          }
        }
        return;
      }

      // Elegir / tap: abrir QuickIntake.
      // Si la app está viva -> navega directo.
      // Si no está viva -> main.dart ya guarda payload, y Home lo consume.
      if (navigatorKey.currentState != null) {
        navigatorKey.currentState!.push(
          MaterialPageRoute(
            builder: (_) => QuickIntakeScreen(
              reminderId: effectiveReminderId,
              medicationIds: resolvedMedicationIds,
              groupName: groupName,
            ),
          ),
        );
      } else {
        await storePendingOpen(payload);
      }
    } catch (e) {
      debugPrint('Error al procesar notificación: $e');
    }
  }

  /// DETAILS

  AndroidNotificationDetails _dailyReminderAndroidDetails() {
    return const AndroidNotificationDetails(
      _dailyChannelId,
      _dailyChannelName,
      channelDescription: _dailyChannelDescription,
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      icon: '@mipmap/ic_launcher',
    );
  }

  AndroidNotificationDetails _medicationAndroidDetails({
    required bool showChoose,
    required String completeLabel,
    bool completeShowsUserInterface = false,
  }) {
    final actions = <AndroidNotificationAction>[
      if (showChoose)
        const AndroidNotificationAction(
          'open',
          '📝 Elegir',
          showsUserInterface: true,
        ),
      AndroidNotificationAction(
        'complete',
        completeLabel,
        showsUserInterface: completeShowsUserInterface,
      ),
      const AndroidNotificationAction(
        'snooze',
        '⏰ Posponer 5 min',
        showsUserInterface: false,
      ),
    ];

    return AndroidNotificationDetails(
      _medChannelId,
      _medChannelName,
      channelDescription: _medChannelDescription,
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      icon: '@mipmap/ic_launcher',
      category: AndroidNotificationCategory.alarm,
      actions: actions,
    );
  }

  /// ACTIONS

  Future<void> snoozeFromAction({
    required int? firedNotificationId,
    required int reminderId,
    required int medicationId,
    required Duration delay,
  }) async {
    if (firedNotificationId != null) {
      await _notifications.cancel(firedNotificationId);
    }

    final scheduledDate = tz.TZDateTime.now(tz.local).add(delay);

    final payload = jsonEncode({
      'type': 'med',
      'mode': 'single',
      'reminderId': reminderId,
      'medicationId': medicationId,
      'medicationIds': [medicationId],
    });

    final medication = await DatabaseHelper.instance.getMedication(
      medicationId,
    );

    final num = medication?.defaultDoseNumerator;
    final den = medication?.defaultDoseDenominator;
    final canCompleteInBackground =
        num != null && den != null && num > 0 && den > 0;

    final snoozeId = _makeSnoozeNotificationId(
      reminderId: reminderId,
      medicationId: medicationId,
      fromGroup: false,
    );

    await _storeSnoozed(
      snoozeId: snoozeId,
      reminderId: reminderId,
      medicationId: medicationId,
      scheduledAt: scheduledDate,
    );

    await _notifications.zonedSchedule(
      snoozeId,
      '💊 Recordatorio (pospuesto)',
      'Tomar ${medication?.name ?? "medicamento"}',
      scheduledDate,
      NotificationDetails(
        android: _medicationAndroidDetails(
          showChoose: !canCompleteInBackground,
          completeLabel: '✅ Ya tomé',
          completeShowsUserInterface: !canCompleteInBackground,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );
  }

  Future<void> snoozeGroupFromAction({
    required int? firedNotificationId,
    required String payload,
    required Duration delay,
  }) async {
    if (firedNotificationId != null) {
      await _notifications.cancel(firedNotificationId);
    }

    final scheduledDate = tz.TZDateTime.now(tz.local).add(delay);
    final snoozeId = _snoozeIdOffset + (firedNotificationId ?? 0);

    await _notifications.zonedSchedule(
      snoozeId,
      '💊 Recordatorio (pospuesto)',
      'Tocar para registrar',
      scheduledDate,
      NotificationDetails(
        android: _medicationAndroidDetails(
          showChoose: true,
          completeLabel: '✅ Tomé todo',
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );
  }

  /// Foreground-safe: intenta registrar en DB.
  /// Devuelve true si registró.
  Future<bool> completeFromActionForeground({
    required int? firedNotificationId,
    required int reminderId,
    required int medicationId,
  }) async {
    if (firedNotificationId != null) {
      await _notifications.cancel(firedNotificationId);
    }

    final db = DatabaseHelper.instance;
    final medication = await db.getMedication(medicationId);

    final num = medication?.defaultDoseNumerator;
    final den = medication?.defaultDoseDenominator;

    final hasValidDefaultDose =
        num != null && den != null && num > 0 && den > 0;

    final amountNumerator = hasValidDefaultDose ? num : null;
    final amountDenominator = hasValidDefaultDose ? den : null;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dayEntry = await db.ensureDayEntry(today);

    await db.saveIntakeEvent(
      IntakeEvent(
        dayEntryId: dayEntry.id!,
        medicationId: medicationId,
        takenAt: now,
        amountNumerator: amountNumerator,
        amountDenominator: amountDenominator,
        note: 'Registrado automáticamente',
      ),
    );

    return true;
  }

  /// Foreground-safe: registra múltiples tomas (grupo).
  /// Devuelve true si registró.
  Future<bool> completeManyFromActionForeground({
    required int? firedNotificationId,
    required List<int> medicationIds,
  }) async {
    if (firedNotificationId != null) {
      await _notifications.cancel(firedNotificationId);
    }

    if (medicationIds.isEmpty) return true;

    final db = DatabaseHelper.instance;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dayEntry = await db.ensureDayEntry(today);

    for (final medicationId in medicationIds) {
      final medication = await db.getMedication(medicationId);
      final num = medication?.defaultDoseNumerator;
      final den = medication?.defaultDoseDenominator;
      final hasValidDefaultDose =
          num != null && den != null && num > 0 && den > 0;

      final amountNumerator = hasValidDefaultDose ? num : null;
      final amountDenominator = hasValidDefaultDose ? den : null;

      await db.saveIntakeEvent(
        IntakeEvent(
          dayEntryId: dayEntry.id!,
          medicationId: medicationId,
          takenAt: now,
          amountNumerator: amountNumerator,
          amountDenominator: amountDenominator,
          note: 'Registrado automáticamente',
        ),
      );
    }

    return true;
  }

  /// DAILY REMINDER

  Future<void> scheduleDailyReminder({
    required int hour,
    required int minute,
  }) async {
    await _notifications.cancel(0);

    final now = DateTime.now();
    var scheduledDateTime = DateTime(
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (scheduledDateTime.isBefore(now)) {
      scheduledDateTime = scheduledDateTime.add(const Duration(days: 1));
    }

    final scheduledDate = tz.TZDateTime.from(scheduledDateTime, tz.local);

    final payload = jsonEncode({
      'type': 'sleep',
      // Abrir el registro del día en que se dispara el recordatorio.
      'date': _formatDateOnly(scheduledDateTime),
    });

    await _notifications.zonedSchedule(
      0,
      '🌙 Registro de sueño',
      '¿Cómo dormiste anoche? Registrá tu sueño',
      scheduledDate,
      NotificationDetails(android: _dailyReminderAndroidDetails()),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );
  }

  Future<void> cancelDailyReminder() async {
    await _notifications.cancel(0);
  }

  /// PERMISSIONS

  Future<bool> requestPermissions() async {
    final status = await Permission.notification.request();
    if (status.isGranted) return true;

    final android = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (android != null) {
      final granted = await android.requestNotificationsPermission();
      return granted ?? false;
    }
    return false;
  }

  Future<bool> areNotificationsEnabled() async {
    final status = await Permission.notification.status;
    return status.isGranted;
  }

  /// MEDICATION REMINDERS

  Future<void> scheduleMedicationReminder(
    MedicationReminder reminder,
    Medication medication,
  ) async {
    if (reminder.id == null) {
      throw Exception('El recordatorio debe tener un ID de base de datos');
    }

    final payload = jsonEncode({
      'type': 'med',
      'mode': 'single',
      'reminderId': reminder.id,
      'medicationId': medication.id,
      'medicationIds': [medication.id],
    });

    final scheduleMode = reminder.requiresExactAlarm
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;

    final num = medication.defaultDoseNumerator;
    final den = medication.defaultDoseDenominator;
    final canCompleteInBackground =
        num != null && den != null && num > 0 && den > 0;

    if (reminder.isDaily) {
      final scheduledDate = _nextInstanceOfTime(
        hour: reminder.hour,
        minute: reminder.minute,
      );

      await _notifications.zonedSchedule(
        reminder.id!,
        '💊 Recordatorio de medicación',
        'Tomar ${medication.name}',
        scheduledDate,
        NotificationDetails(
          android: _medicationAndroidDetails(
            showChoose: !canCompleteInBackground,
            completeLabel: '✅ Ya tomé',
            completeShowsUserInterface: false,
          ),
        ),
        androidScheduleMode: scheduleMode,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: payload,
      );
    } else {
      for (final day in reminder.daysOfWeek) {
        final scheduledDate = _nextInstanceOfDay(
          day: day,
          hour: reminder.hour,
          minute: reminder.minute,
        );

        final notificationId = reminder.id! * 10 + day;

        await _notifications.zonedSchedule(
          notificationId,
          '💊 Recordatorio de medicación',
          'Tomar ${medication.name}',
          scheduledDate,
          NotificationDetails(
            android: _medicationAndroidDetails(
              showChoose: !canCompleteInBackground,
              completeLabel: '✅ Ya tomé',
              completeShowsUserInterface: false,
            ),
          ),
          androidScheduleMode: scheduleMode,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
          payload: payload,
        );
      }
    }
  }

  ///GROUP REMINDERS

  int _groupNotificationIdDaily(int groupReminderId) =>
      _groupNotifIdOffset + groupReminderId;

  int _groupNotificationIdWeekly(int groupReminderId, int day) =>
      _groupNotifIdOffset + (groupReminderId * 10) + day;

  Future<void> scheduleMedicationGroupReminder({
    required MedicationGroupReminder reminder,
    required MedicationGroup group,
    required List<Medication> medicationsSnapshot,
  }) async {
    if (reminder.id == null) {
      throw Exception('El recordatorio de grupo debe tener un ID de DB');
    }

    final medicationIds = medicationsSnapshot
        .where((m) => m.id != null)
        .map((m) => m.id!)
        .toList(growable: false);

    final payload = jsonEncode({
      'type': 'med',
      'mode': 'group',
      'groupReminderId': reminder.id,
      'groupId': group.id,
      'groupName': group.name,
      'medicationIds': medicationIds,
    });

    final showChoose = medicationIds.length > 1;
    medicationsSnapshot.where((m) => m.id != null).every((m) {
      final num = m.defaultDoseNumerator;
      final den = m.defaultDoseDenominator;
      return num != null && den != null && num > 0 && den > 0;
    });

    final completeLabel = showChoose ? '✅ Tomé todo' : '✅ Ya tomé';

    final scheduleMode = reminder.requiresExactAlarm
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;

    final names = medicationsSnapshot
        .map((m) => m.name)
        .toList(growable: false);
    final body = names.isEmpty
        ? 'Tocar para registrar'
        : (names.length <= 3
              ? 'Tomar: ${names.join(', ')}'
              : 'Tomar: ${names.take(3).join(', ')}…');

    if (reminder.isDaily) {
      final scheduledDate = _nextInstanceOfTime(
        hour: reminder.hour,
        minute: reminder.minute,
      );

      await _notifications.zonedSchedule(
        _groupNotificationIdDaily(reminder.id!),
        '💊 ${group.name}',
        body,
        scheduledDate,
        NotificationDetails(
          android: _medicationAndroidDetails(
            showChoose: showChoose,
            completeLabel: completeLabel,
            completeShowsUserInterface: false,
          ),
        ),
        androidScheduleMode: scheduleMode,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: payload,
      );
    } else {
      for (final day in reminder.daysOfWeek) {
        final scheduledDate = _nextInstanceOfDay(
          day: day,
          hour: reminder.hour,
          minute: reminder.minute,
        );

        await _notifications.zonedSchedule(
          _groupNotificationIdWeekly(reminder.id!, day),
          '💊 ${group.name}',
          body,
          scheduledDate,
          NotificationDetails(
            android: _medicationAndroidDetails(
              showChoose: showChoose,
              completeLabel: completeLabel,
              completeShowsUserInterface: false,
            ),
          ),
          androidScheduleMode: scheduleMode,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
          payload: payload,
        );
      }
    }
  }

  Future<void> cancelMedicationGroupReminder(
    MedicationGroupReminder reminder,
  ) async {
    if (reminder.id == null) return;

    // Cancela también snoozes asociados a este reminder (si existieran).
    await cancelSnoozesForReminderId(reminder.id!);

    if (reminder.isDaily) {
      await _notifications.cancel(_groupNotificationIdDaily(reminder.id!));
    } else {
      for (final day in reminder.daysOfWeek) {
        await _notifications.cancel(
          _groupNotificationIdWeekly(reminder.id!, day),
        );
      }
    }
  }

  Future<void> cancelMedicationReminder(MedicationReminder reminder) async {
    if (reminder.id == null) return;

    // Cancela también snoozes asociados a este reminder (si existieran).
    await cancelSnoozesForReminderId(
      reminder.id!,
      medicationId: reminder.medicationId,
    );

    if (reminder.isDaily) {
      await _notifications.cancel(reminder.id!);
    } else {
      for (final day in reminder.daysOfWeek) {
        final notificationId = reminder.id! * 10 + day;
        await _notifications.cancel(notificationId);
      }
    }
  }

  /// Snooze manual desde UI (QuickIntakeScreen)
  Future<void> snoozeMedicationReminder(
    int reminderId,
    int medicationId,
    Medication medication,
    Duration delay, {
    String? groupName,
    bool fromGroup = false,
  }) async {
    final scheduledDate = tz.TZDateTime.now(tz.local).add(delay);

    final payload = jsonEncode({
      'type': 'med',
      'mode': 'single',
      'reminderId': reminderId,
      'medicationId': medicationId,
      'medicationIds': [medicationId],
    });

    final snoozeId = _makeSnoozeNotificationId(
      reminderId: reminderId,
      medicationId: medicationId,
      fromGroup: fromGroup,
    );

    await _storeSnoozed(
      snoozeId: snoozeId,
      reminderId: reminderId,
      medicationId: medicationId,
      groupName: groupName,
      scheduledAt: scheduledDate,
    );

    await _notifications.zonedSchedule(
      snoozeId,
      '💊 Recordatorio (pospuesto)',
      'Tomar ${medication.name}',
      scheduledDate,
      NotificationDetails(
        android: _medicationAndroidDetails(
          showChoose:
              !(medication.defaultDoseNumerator != null &&
                  medication.defaultDoseDenominator != null &&
                  medication.defaultDoseNumerator! > 0 &&
                  medication.defaultDoseDenominator! > 0),
          completeLabel: '✅ Ya tomé',
          completeShowsUserInterface: false,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );
  }

  tz.TZDateTime _nextInstanceOfTime({required int hour, required int minute}) {
    final now = DateTime.now();
    var scheduled = DateTime(now.year, now.month, now.day, hour, minute);

    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return tz.TZDateTime.from(scheduled, tz.local);
  }

  tz.TZDateTime _nextInstanceOfDay({
    required int day, // 1=Lunes ... 7=Domingo
    required int hour,
    required int minute,
  }) {
    final now = DateTime.now();
    var scheduled = DateTime(now.year, now.month, now.day, hour, minute);

    while (scheduled.weekday != day) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 7));
    }
    return tz.TZDateTime.from(scheduled, tz.local);
  }

  /// DEBUG

  Future<void> showTestNotification() async {
    final androidDetails = AndroidNotificationDetails(
      _medChannelId,
      _medChannelName,
      channelDescription: _medChannelDescription,
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );

    await _notifications.show(
      999,
      'Notificación de prueba',
      'Si ves esto, las notificaciones funcionan correctamente',
      NotificationDetails(android: androidDetails),
    );
  }
}

/// BACKGROUND ENTRYPOINT
// En background:
// - posponer: OK (one-shot, no DB)
// - tomé todo: NO DB (frágil). Encola pending_complete para que Home lo procese.
@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse response) async {
  DartPluginRegistrant.ensureInitialized();

  final payload = response.payload;
  if (payload == null || payload.isEmpty) return;

  try {
    await NotificationService.instance.ensureInitializedForBackground();

    final data = jsonDecode(payload) as Map<String, dynamic>;

    if (data['type'] == 'sleep') {
      await NotificationService.instance.storePendingOpen(payload);
      return;
    }

    final reminderId = (data['reminderId'] as num?)?.toInt();
    final groupReminderId = (data['groupReminderId'] as num?)?.toInt();
    final medicationId = (data['medicationId'] as num?)?.toInt();
    final medicationIds = (data['medicationIds'] is List)
        ? (data['medicationIds'] as List)
              .whereType<num>()
              .map((n) => n.toInt())
              .toList(growable: false)
        : <int>[];

    final resolvedMedicationIds = medicationIds.isNotEmpty
        ? medicationIds
        : (medicationId != null ? <int>[medicationId] : <int>[]);

    final effectiveReminderId = reminderId ?? groupReminderId;
    final isGroup = resolvedMedicationIds.length > 1;
    final firedNotificationId = response.id;

    if (response.actionId == 'snooze') {
      if (!isGroup) {
        if (effectiveReminderId == null || resolvedMedicationIds.isEmpty) {
          return;
        }
        final medId = resolvedMedicationIds.first;

        if (firedNotificationId != null) {
          await NotificationService.instance._notifications.cancel(
            firedNotificationId,
          );
        }

        final scheduledDate = tz.TZDateTime.now(
          tz.local,
        ).add(const Duration(minutes: 5));

        final snoozeId =
            NotificationService._snoozeIdOffset +
            (firedNotificationId ?? (effectiveReminderId * 10));

        await NotificationService.instance._storeSnoozed(
          snoozeId: snoozeId,
          reminderId: effectiveReminderId,
          medicationId: medId,
          scheduledAt: scheduledDate,
        );

        await NotificationService.instance._notifications.zonedSchedule(
          snoozeId,
          '💊 Recordatorio (pospuesto)',
          'Tocar para registrar',
          scheduledDate,
          NotificationDetails(
            android: NotificationService.instance._medicationAndroidDetails(
              showChoose: false,
              completeLabel: '✅ Ya tomé',
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          payload: payload,
        );
      } else {
        if (firedNotificationId != null) {
          await NotificationService.instance._notifications.cancel(
            firedNotificationId,
          );
        }

        final scheduledDate = tz.TZDateTime.now(
          tz.local,
        ).add(const Duration(minutes: 5));

        final snoozeId =
            NotificationService._snoozeIdOffset + (firedNotificationId ?? 0);

        await NotificationService.instance._notifications.zonedSchedule(
          snoozeId,
          '💊 Recordatorio (pospuesto)',
          'Tocar para registrar',
          scheduledDate,
          NotificationDetails(
            android: NotificationService.instance._medicationAndroidDetails(
              showChoose: true,
              completeLabel: '✅ Tomé todo',
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          payload: payload,
        );
      }
      return;
    }

    if (response.actionId == 'complete') {
      if (firedNotificationId != null) {
        await NotificationService.instance._notifications.cancel(
          firedNotificationId,
        );
      }

      await NotificationService.instance.enqueuePendingComplete(payload);
      return;
    }

    await NotificationService.instance.storePendingOpen(payload);
  } catch (e) {
    debugPrint('notificationTapBackground error: $e');
  }
}
