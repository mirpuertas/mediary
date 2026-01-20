import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';

import '../providers/sleep_entry_provider.dart';
import '../providers/medication_provider.dart';
import '../models/medication.dart';
import '../models/medication_reminder.dart';
import '../models/sleep_entry.dart';
import '../models/intake_event.dart';
import '../services/database_helper.dart';
import '../services/notification_service.dart';
import '../utils/fraction_helper.dart';
import '../utils/date_parse.dart';

import '../ui/theme_helpers.dart';

import 'daily_entry_screen.dart';
import 'medications_screen.dart';
import 'settings_screen.dart';
import 'quick_intake_screen.dart';
import 'summary_screen.dart';

enum CalendarFilter { all, sleep, mood, medication }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late DateTime _focusedDay;
  late DateTime _selectedDay;

  bool _showAllReminders = false;
  CalendarFormat _calendarFormat = CalendarFormat.month;

  CalendarFilter _calendarFilter = CalendarFilter.all;

  final Map<DateTime, int> _moodByDay = {};
  final Set<int> _loadedMoodMonths = {};

  final Map<DateTime, int> _intakesCountByDay = {};
  final Set<int> _loadedIntakeMonths = {};

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _focusedDay = DateTime(now.year, now.month, now.day);
    _selectedDay = _focusedDay;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final sleepProvider = context.read<SleepEntryProvider>();
      final medProvider = context.read<MedicationProvider>();

      await Future.wait([
        sleepProvider.loadEntries(),
        medProvider.loadMedications(),
      ]);

      await _ensureMoodLoadedForMonth(_focusedDay);
      await _ensureIntakesLoadedForMonth(_focusedDay);

      // Procesar “Tomé todo” pendientes (app estaba cerrada, sin UI)
      await _processPendingCompletes();

      // Si la app se abrió desde una notificación (tap / "Elegir")
      await _consumePendingNotificationNavigation();
    });
  }

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
  int _monthKey(DateTime d) => (d.year * 100) + d.month;
  DateTime _endOfDay(DateTime d) =>
      DateTime(d.year, d.month, d.day, 23, 59, 59, 999);

  String _filterLabel(CalendarFilter f) {
    switch (f) {
      case CalendarFilter.all:
        return 'Todo';
      case CalendarFilter.sleep:
        return 'Sueño';
      case CalendarFilter.mood:
        return 'Ánimo';
      case CalendarFilter.medication:
        return 'Medicación';
    }
  }

  Widget _buildDayChips({
    required SleepEntry? entry,
    required int? mood,
    required int intakesCount,
  }) {
    final cs = Theme.of(context).colorScheme;

    final chipBg = cs.surfaceContainerHighest;
    final chipSide = BorderSide(color: dividerColor(context, 0.18));
    final chipLabelStyle = TextStyle(color: cs.onSurface);
    final chipShape = StadiumBorder(side: chipSide);

    final iconMuted = muted(context, 0.80);

    final hasSleep = entry != null;
    final sleepText = hasSleep ? 'Sueño: ${entry.sleepQuality}/5' : 'Sueño: —';

    final moodValue = mood;
    final hasMood = moodValue != null;

    final hasMeds = intakesCount > 0;
    final medsText = hasMeds ? 'Medicación: $intakesCount' : 'Medicación: —';

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ActionChip(
          backgroundColor: chipBg,
          shape: chipShape,
          labelStyle: chipLabelStyle,
          avatar: Icon(Icons.bedtime, size: 18, color: iconMuted),
          label: Text(sleepText),
          onPressed: () async {
            final sleepProvider = context.read<SleepEntryProvider>();
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => DailyEntryScreen(
                  selectedDate: _selectedDay,
                  initialTabIndex: 1,
                ),
              ),
            );
            if (result == true && mounted) {
              await sleepProvider.loadEntries();
              await _refreshMoodForDay(_selectedDay);
              await _refreshIntakesForDay(_selectedDay);
            }
          },
        ),
        ActionChip(
          backgroundColor: chipBg,
          shape: chipShape,
          labelStyle: chipLabelStyle,
          avatar: Icon(
            hasMood ? moodIcon(moodValue) : Icons.sentiment_neutral,
            size: 18,
            color: hasMood
                ? moodColor(context, moodValue).withValues(alpha: 0.95)
                : iconMuted,
          ),
          label: Text(hasMood ? 'Ánimo' : 'Ánimo: —'),
          onPressed: () async {
            final sleepProvider = context.read<SleepEntryProvider>();
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => DailyEntryScreen(
                  selectedDate: _selectedDay,
                  initialTabIndex: 0,
                ),
              ),
            );
            if (result == true && mounted) {
              await sleepProvider.loadEntries();
              await _refreshMoodForDay(_selectedDay);
              await _refreshIntakesForDay(_selectedDay);
            }
          },
        ),
        ActionChip(
          backgroundColor: chipBg,
          shape: chipShape,
          labelStyle: chipLabelStyle,
          avatar: Icon(Icons.medication, size: 18, color: iconMuted),
          label: Text(medsText),
          onPressed: () async {
            final sleepProvider = context.read<SleepEntryProvider>();
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => DailyEntryScreen(
                  selectedDate: _selectedDay,
                  initialTabIndex: 2,
                ),
              ),
            );
            if (result == true && mounted) {
              await sleepProvider.loadEntries();
              await _refreshMoodForDay(_selectedDay);
              await _refreshIntakesForDay(_selectedDay);
            }
          },
        ),
      ],
    );
  }

  Future<void> _ensureMoodLoadedForMonth(DateTime focusedDay) async {
    final key = _monthKey(focusedDay);
    if (_loadedMoodMonths.contains(key)) return;
    _loadedMoodMonths.add(key);

    final start = DateTime(focusedDay.year, focusedDay.month, 1);
    final lastDay = DateTime(focusedDay.year, focusedDay.month + 1, 0);
    final endInclusive = _endOfDay(lastDay);

    final moods = await DatabaseHelper.instance.getDayMoodsBetween(
      start,
      endInclusive,
    );
    if (!mounted) return;
    setState(() {
      _moodByDay.addAll(moods);
    });
  }

  Future<void> _refreshMoodForDay(DateTime date) async {
    final mood = await DatabaseHelper.instance.getDayMoodByDate(date);
    if (!mounted) return;
    setState(() {
      final day = _dateOnly(date);
      if (mood == null) {
        _moodByDay.remove(day);
      } else {
        _moodByDay[day] = mood;
      }
    });
  }

  Future<void> _ensureIntakesLoadedForMonth(DateTime focusedDay) async {
    final key = _monthKey(focusedDay);
    if (_loadedIntakeMonths.contains(key)) return;
    _loadedIntakeMonths.add(key);

    final start = DateTime(focusedDay.year, focusedDay.month, 1);
    final lastDay = DateTime(focusedDay.year, focusedDay.month + 1, 0);
    final endInclusive = _endOfDay(lastDay);

    final counts = await DatabaseHelper.instance.getIntakeCountsBetween(
      start,
      endInclusive,
    );

    if (!mounted) return;
    setState(() {
      _intakesCountByDay.addAll(counts);
    });
  }

  Future<void> _refreshIntakesForDay(DateTime date) async {
    final day = _dateOnly(date);
    final count = await DatabaseHelper.instance.getIntakeCountByDate(day);

    if (!mounted) return;
    setState(() {
      if (count == null || count == 0) {
        _intakesCountByDay.remove(day);
      } else {
        _intakesCountByDay[day] = count;
      }
    });
  }

  Future<void> _processPendingCompletes() async {
    try {
      final items = await NotificationService.instance
          .consumePendingCompletesDetailed();
      if (items.isEmpty) return;

      final db = DatabaseHelper.instance;
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
          final day = DateTime(takenAt.year, takenAt.month, takenAt.day);
          affectedDays.add(day);

          final dayEntry = await db.ensureDayEntry(day);

          for (final medicationId in resolvedMedicationIds) {
            final medication = await db.getMedication(medicationId);
            final numerator = medication?.defaultDoseNumerator;
            final den = medication?.defaultDoseDenominator;

            final hasValidDefaultDose =
                numerator != null && den != null && numerator > 0 && den > 0;

            final amountNumerator = hasValidDefaultDose ? numerator : null;
            final amountDenominator = hasValidDefaultDose ? den : null;

            await db.saveIntakeEvent(
              IntakeEvent(
                dayEntryId: dayEntry.id!,
                medicationId: medicationId,
                takenAt: takenAt,
                amountNumerator: amountNumerator,
                amountDenominator: amountDenominator,
                note: hasValidDefaultDose
                    ? 'Registrado automáticamente'
                    : 'Registrado automáticamente (sin dosis)',
              ),
            );
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint('HomeScreen: error guardando evento individual: $e');
          }
        }
      }

      if (!mounted) return;
      await context.read<SleepEntryProvider>().loadEntries();
      for (final day in affectedDays) {
        await _refreshIntakesForDay(day);
      }
      setState(() {});
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('HomeScreen: error procesando payload/notifs: $e');
        debugPrint('$st');
      }
    }
  }

  Future<void> _consumePendingNotificationNavigation() async {
    final prefs = await SharedPreferences.getInstance();
    final payload = prefs.getString('pending_notification_payload');

    if (payload == null || payload.isEmpty) return;
    await prefs.remove('pending_notification_payload');

    try {
      final data = jsonDecode(payload) as Map<String, dynamic>;

      if (data['type'] == 'sleep') {
        final raw = data['date'];
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final date = parseDateOnly(raw is String ? raw : null, fallback: today);

        if (!mounted) return;
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => DailyEntryScreen(selectedDate: date),
          ),
        );
        return;
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

      if (resolvedMedicationIds.isEmpty) return;
      if (!mounted) return;

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => QuickIntakeScreen(
            reminderId: reminderId ?? groupReminderId,
            medicationIds: resolvedMedicationIds,
            groupName: groupName,
          ),
        ),
      );
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('HomeScreen: error procesando payload/notifs: $e');
        debugPrint('$st');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final sleepProvider = context.watch<SleepEntryProvider>();
    final medProvider = context.watch<MedicationProvider>();

    final dateFormat = DateFormat('d MMMM yyyy', 'es_ES');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Diario'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart_sharp),
            tooltip: 'Resumen',
            onPressed: () async {
              final goToCalendar = await Navigator.push<bool>(
                context,
                MaterialPageRoute(builder: (_) => const SummaryScreen()),
              );

              if (goToCalendar != true || !mounted) return;

              final now = DateTime.now();
              final today = DateTime(now.year, now.month, now.day);

              setState(() {
                _selectedDay = today;
                _focusedDay = today;
                _calendarFormat = CalendarFormat.month;
                _calendarFilter = CalendarFilter.all;
              });

              await _ensureMoodLoadedForMonth(_focusedDay);
              await _ensureIntakesLoadedForMonth(_focusedDay);
            },
          ),
          IconButton(
            icon: const Icon(Icons.medication),
            tooltip: 'Medicamentos',
            onPressed: () async {
              final medProvider = context.read<MedicationProvider>();
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MedicationsScreen()),
              );
              if (!mounted) return;
              await medProvider.loadMedications();
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Ajustes',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: sleepProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildTodayRemindersCard(),
                _buildCalendar(sleepProvider),
                const Divider(height: 1),
                Expanded(
                  child: _buildSelectedDayPanel(
                    sleepProvider: sleepProvider,
                    medProvider: medProvider,
                    dateFormat: dateFormat,
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildTodayRemindersCard() {
    return FutureBuilder<
      ({
        List<Map<String, dynamic>> reminders,
        List<Map<String, dynamic>> groupReminders,
        List<Map<String, dynamic>> snoozes,
      })
    >(
      future: () async {
        final reminders = await DatabaseHelper.instance.getTodayReminders();
        final groupReminders = await DatabaseHelper.instance
            .getTodayGroupReminders();
        final snoozes = await NotificationService.instance
            .getTodaySnoozedReminders();
        return (
          reminders: reminders,
          groupReminders: groupReminders,
          snoozes: snoozes,
        );
      }(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return const SizedBox.shrink();

        final reminders =
            snapshot.data?.reminders ?? const <Map<String, dynamic>>[];
        final groupReminders =
            snapshot.data?.groupReminders ?? const <Map<String, dynamic>>[];
        final snoozes =
            snapshot.data?.snoozes ?? const <Map<String, dynamic>>[];

        if (reminders.isEmpty && groupReminders.isEmpty && snoozes.isEmpty) {
          return const SizedBox.shrink();
        }

        final cs = Theme.of(context).colorScheme;
        final m1 = muted(context, 0.60);
        final m2 = muted(context, 0.45);

        final now = DateTime.now();
        final all = <({int hour, int minute, String label})>[];

        for (final item in reminders) {
          final reminder = item['reminder'] as MedicationReminder;
          final medication = item['medication'] as Medication;
          all.add((
            hour: reminder.hour,
            minute: reminder.minute,
            label: medication.name,
          ));
        }

        for (final item in groupReminders) {
          final reminder = item['reminder'] as dynamic;
          final group = item['group'] as dynamic;
          final meds = (item['medications'] as List?) ?? const [];

          final hour = (reminder.hour as int);
          final minute = (reminder.minute as int);
          final name = (group.name as String);
          final count = meds.length;
          all.add((hour: hour, minute: minute, label: '$name ($count)'));
        }

        all.sort((a, b) {
          final ta = a.hour * 60 + a.minute;
          final tb = b.hour * 60 + b.minute;
          return ta.compareTo(tb);
        });

        final items = _showAllReminders
            ? all
            : all.take(3).toList(growable: false);

        return Card(
          margin: const EdgeInsets.all(12),
          color: cs.inversePrimary,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.alarm, color: cs.tertiary),
                    const SizedBox(width: 8),
                    Text(
                      'Recordatorios de hoy',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...items.map((item) {
                  final reminderTime = DateTime(
                    now.year,
                    now.month,
                    now.day,
                    item.hour,
                    item.minute,
                  );
                  final isPast = reminderTime.isBefore(now);

                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      children: [
                        Icon(
                          isPast
                              ? Icons.check_circle_outline
                              : Icons.notifications_active,
                          size: 16,
                          color: isPast ? m2 : cs.tertiary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${item.hour.toString().padLeft(2, '0')}:${item.minute.toString().padLeft(2, '0')}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isPast ? m1 : null,
                            decoration: isPast
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            item.label,
                            style: TextStyle(color: isPast ? m1 : null),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                if (snoozes.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Divider(height: 1, color: dividerColor(context)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(
                        Icons.alarm_add,
                        size: 18,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Pospuestos',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ...snoozes.map((item) {
                    final scheduledAt = item['scheduledAt'] as DateTime;
                    final medication = item['medication'] as Medication?;
                    final medicationId = item['medicationId'] as int;
                    final groupName = item['groupName'] as String?;
                    final isPast = scheduledAt.isBefore(now);
                    final timeText = DateFormat(
                      'HH:mm',
                      'es_ES',
                    ).format(scheduledAt);
                    final medName =
                        medication?.name ?? 'Medicamento $medicationId';
                    final label =
                        (groupName != null && groupName.trim().isNotEmpty)
                        ? '${groupName.trim()} — $medName'
                        : medName;

                    return Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        children: [
                          Icon(
                            isPast ? Icons.check_circle_outline : Icons.snooze,
                            size: 16,
                            color: isPast ? m2 : cs.secondary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            timeText,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isPast ? m1 : null,
                              decoration: isPast
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              label,
                              style: TextStyle(color: isPast ? m1 : null),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
                if (all.length > 3)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _showAllReminders = !_showAllReminders;
                        });
                      },
                      child: Text(
                        _showAllReminders
                            ? 'Ver menos'
                            : 'Mostrar todos (${all.length})',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w500,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCalendar(SleepEntryProvider provider) {
    final entriesByDay = <DateTime, SleepEntry>{};
    for (final e in provider.entries) {
      entriesByDay[_dateOnly(e.nightDate)] = e;
    }

    final textScale = MediaQuery.textScalerOf(context).scale(1.0);
    final daysOfWeekHeight = (24.0 * textScale).clamp(24.0, 42.0);

    String formatLabel(CalendarFormat f) {
      switch (f) {
        case CalendarFormat.month:
          return 'Mes';
        case CalendarFormat.twoWeeks:
          return '2 semanas';
        case CalendarFormat.week:
          return 'Semana';
      }
    }

    return TableCalendar(
      firstDay: DateTime(2020, 1, 1),
      lastDay: DateTime.now().add(const Duration(days: 365)),
      focusedDay: _focusedDay,
      locale: 'es_ES',
      startingDayOfWeek: StartingDayOfWeek.sunday,
      calendarFormat: _calendarFormat,
      daysOfWeekHeight: daysOfWeekHeight,
      headerStyle: const HeaderStyle(
        titleCentered: true,
        formatButtonVisible: false,
        formatButtonShowsNext: false,
      ),
      availableCalendarFormats: const {
        CalendarFormat.month: 'Mes',
        CalendarFormat.twoWeeks: '2 semanas',
        CalendarFormat.week: 'Semana',
      },
      selectedDayPredicate: (day) => isSameDay(day, _selectedDay),
      onDaySelected: (selectedDay, focusedDay) {
        setState(() {
          _selectedDay = _dateOnly(selectedDay);
          _focusedDay = _dateOnly(focusedDay);
        });

        _ensureMoodLoadedForMonth(_focusedDay);
        _ensureIntakesLoadedForMonth(_focusedDay);
      },
      onPageChanged: (focusedDay) {
        setState(() {
          _focusedDay = _dateOnly(focusedDay);
        });
        _ensureMoodLoadedForMonth(_focusedDay);
        _ensureIntakesLoadedForMonth(_focusedDay);
      },
      onFormatChanged: (format) {
        setState(() {
          _calendarFormat = format;
        });
      },
      eventLoader: (day) {
        final d = _dateOnly(day);
        return entriesByDay.containsKey(d) ? [entriesByDay[d]!] : [];
      },
      calendarBuilders: CalendarBuilders(
        headerTitleBuilder: (context, day) {
          final title = DateFormat('MMMM yyyy', 'es_ES').format(day);
          final pretty = title.isNotEmpty
              ? '${title[0].toUpperCase()}${title.substring(1)}'
              : title;

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  pretty,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 4),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                runSpacing: 8,
                children: [
                  PopupMenuButton<CalendarFormat>(
                    tooltip: 'Vista',
                    onSelected: (format) {
                      setState(() {
                        _calendarFormat = format;
                      });
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(
                        value: CalendarFormat.month,
                        child: Text('Mes'),
                      ),
                      PopupMenuItem(
                        value: CalendarFormat.twoWeeks,
                        child: Text('2 semanas'),
                      ),
                      PopupMenuItem(
                        value: CalendarFormat.week,
                        child: Text('Semana'),
                      ),
                    ],
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.calendar_view_month, size: 18),
                        const SizedBox(width: 4),
                        Text(
                          formatLabel(_calendarFormat),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<CalendarFilter>(
                    tooltip: 'Filtrar',
                    onSelected: (f) => setState(() => _calendarFilter = f),
                    itemBuilder: (_) => const [
                      PopupMenuItem(
                        value: CalendarFilter.all,
                        child: Text('Todo'),
                      ),
                      PopupMenuItem(
                        value: CalendarFilter.sleep,
                        child: Text('🌙 Sueño'),
                      ),
                      PopupMenuItem(
                        value: CalendarFilter.mood,
                        child: Text('🙂 Ánimo'),
                      ),
                      PopupMenuItem(
                        value: CalendarFilter.medication,
                        child: Text('💊 Medicación'),
                      ),
                    ],
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.filter_list, size: 18),
                        const SizedBox(width: 4),
                        Text(
                          _filterLabel(_calendarFilter),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          );
        },
        markerBuilder: (context, day, events) {
          final d = _dateOnly(day);

          final mood = _moodByDay[d];
          final hasSleep = events.isNotEmpty;
          final intakeCount = _intakesCountByDay[d] ?? 0;

          bool showSleep = false;
          bool showMood = false;
          bool showMeds = false;

          switch (_calendarFilter) {
            case CalendarFilter.all:
              // en modo "Todo" no se muestran meds en calendar
              showSleep = hasSleep;
              showMood = mood != null;
              showMeds = false;
              break;
            case CalendarFilter.sleep:
              showSleep = hasSleep;
              break;
            case CalendarFilter.mood:
              showMood = mood != null;
              break;
            case CalendarFilter.medication:
              showMeds = intakeCount > 0;
              break;
          }

          if (!showSleep && !showMood && !showMeds) {
            return const SizedBox.shrink();
          }

          final cs = Theme.of(context).colorScheme;

          final sleepDot = cs.primary;
          final medsDot = cs.secondary;
          final moodDot = mood == null ? cs.outline : moodColor(context, mood);
          final moodOn = onColorForDot(moodDot);

          return Stack(
            clipBehavior: Clip.none,
            children: [
              if (showSleep)
                Positioned(
                  bottom: 4,
                  right: 4,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: sleepDot,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${(events.first as SleepEntry).sleepQuality}',
                      style: TextStyle(
                        color: cs.onPrimary,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              if (showMood)
                Positioned(
                  bottom: 4,
                  left: 4,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: moodDot,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Icon(moodIcon(mood!), size: 14, color: moodOn),
                  ),
                ),
              if (showMeds)
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: medsDot,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$intakeCount',
                      style: TextStyle(
                        color: cs.onSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSelectedDayPanel({
    required SleepEntryProvider sleepProvider,
    required MedicationProvider medProvider,
    required DateFormat dateFormat,
  }) {
    return FutureBuilder<SleepEntry?>(
      future: sleepProvider.getEntryByDate(_selectedDay),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final entry = snapshot.data;

        return FutureBuilder(
          future: DatabaseHelper.instance.ensureDayEntry(_selectedDay),
          builder: (context, daySnap) {
            if (daySnap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!daySnap.hasData) {
              return const Center(child: Text('No se pudo cargar el día.'));
            }

            final dayEntry = daySnap.data!;
            final int dayEntryId = dayEntry.id as int;

            return FutureBuilder<
              ({List<IntakeEvent> events, int? mood, String? dayNotes})
            >(
              future: () async {
                final events = await sleepProvider.getEventsForDayEntry(
                  dayEntryId,
                );
                final mood = await DatabaseHelper.instance.getDayMoodByDate(
                  _selectedDay,
                );
                final dayNotes = await DatabaseHelper.instance
                    .getDayNotesByDate(_selectedDay);
                return (events: events, mood: mood, dayNotes: dayNotes);
              }(),
              builder: (context, eventsSnapshot) {
                final events =
                    eventsSnapshot.data?.events ?? const <IntakeEvent>[];
                final mood = eventsSnapshot.data?.mood;
                final dayNotes = eventsSnapshot.data?.dayNotes;

                final hasAnyData =
                    entry != null ||
                    events.isNotEmpty ||
                    mood != null ||
                    ((dayNotes ?? '').trim().isNotEmpty);

                final showDay =
                    _calendarFilter == CalendarFilter.all ||
                    _calendarFilter == CalendarFilter.mood;
                final showSleep =
                    _calendarFilter == CalendarFilter.all ||
                    _calendarFilter == CalendarFilter.sleep;
                final showMeds =
                    _calendarFilter == CalendarFilter.all ||
                    _calendarFilter == CalendarFilter.medication;

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Día ${dateFormat.format(_selectedDay)}',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                const SizedBox(height: 10),
                                _buildDayChips(
                                  entry: entry,
                                  mood: mood,
                                  intakesCount: events.length,
                                ),
                              ],
                            ),
                          ),
                          if (hasAnyData)
                            IconButton(
                              tooltip: 'Eliminar registro del día',
                              icon: Icon(
                                Icons.delete,
                                color: Theme.of(context).colorScheme.error,
                              ),
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Eliminar registro'),
                                    content: const Text(
                                      '¿Eliminar el registro COMPLETO de este día?\n\n'
                                      'Se borrarán: sueño, medicación (tomas), ánimo y notas del día.',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, false),
                                        child: const Text('Cancelar'),
                                      ),
                                      ElevatedButton(
                                        onPressed: () =>
                                            Navigator.pop(context, true),
                                        child: const Text('Eliminar'),
                                      ),
                                    ],
                                  ),
                                );

                                if (confirm == true && mounted) {
                                  await DatabaseHelper.instance
                                      .deleteFullDayRecordByDate(_selectedDay);
                                  await sleepProvider.loadEntries();
                                  await _refreshMoodForDay(_selectedDay);
                                  await _refreshIntakesForDay(_selectedDay);
                                }
                              },
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (showDay) ...[
                        _buildDayCard(mood: mood, dayNotes: dayNotes),
                        const SizedBox(height: 16),
                      ],
                      if (showSleep) ...[
                        _buildSleepCard(entry),
                        const SizedBox(height: 16),
                      ],
                      if (showMeds) _buildMedicationCard(events, medProvider),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildDayCard({required int? mood, required String? dayNotes}) {
    final moodValue = mood;
    final notes = (dayNotes ?? '').trim();

    IconData headerIcon = Icons.emoji_emotions_outlined;
    Color? headerColor;
    if (moodValue != null) {
      headerIcon = moodIcon(moodValue);
      headerColor = moodColor(context, moodValue);
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(headerIcon, size: 28, color: headerColor),
                const SizedBox(width: 12),
                const Text(
                  'Día',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (moodValue == null)
              Text(
                'Sin ánimo registrado',
                style: TextStyle(color: muted(context, 0.70)),
              ),
            if (notes.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(notes),
            ] else ...[
              const SizedBox(height: 8),
              Text('Sin notas', style: TextStyle(color: muted(context, 0.60))),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSleepCard(SleepEntry? entry) {
    final m1 = muted(context, 0.70);
    final m2 = muted(context, 0.60);

    if (entry == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              const Icon(Icons.bedtime_outlined, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Sin registro de sueño',
                  style: TextStyle(color: m1),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final notes = (entry.notes ?? '').trim();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.bedtime, size: 28),
                SizedBox(width: 12),
                Text('Sueño', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            if ((entry.sleepDurationMinutes ?? 0) > 0 ||
                (entry.sleepContinuity != null))
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(() {
                  final parts = <String>[];
                  final total = entry.sleepDurationMinutes;
                  if (total != null && total > 0) {
                    final hh = total ~/ 60;
                    final mm = total % 60;
                    parts.add('${hh}h ${mm.toString().padLeft(2, '0')}m');
                  }
                  if (entry.sleepContinuity == 1) parts.add('De corrido');
                  if (entry.sleepContinuity == 2) parts.add('Cortado');
                  return parts.join(' • ');
                }(), style: TextStyle(color: m1, fontSize: 12)),
              ),
            if (notes.isNotEmpty)
              Text(notes)
            else
              Text('Sin notas', style: TextStyle(color: m2)),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicationCard(
    List<IntakeEvent> events,
    MedicationProvider medProvider,
  ) {
    final medsById = <int, Medication>{
      for (final m in medProvider.allMedications)
        if (m.id != null) m.id!: m,
    };

    final m1 = muted(context, 0.70);
    final m2 = muted(context, 0.60);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.medication, size: 28),
                SizedBox(width: 12),
                Text(
                  'Medicaciones',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (events.isEmpty)
              Text('Sin medicaciones registradas', style: TextStyle(color: m1))
            else
              ...events.map((e) {
                final med = medsById[e.medicationId];
                final name = med?.name ?? 'Medicamento ${e.medicationId}';
                final unit = (med?.unit ?? '').trim();
                final unitText = unit.isEmpty ? '' : ' ($unit)';

                final qty =
                    (e.amountNumerator == null || e.amountDenominator == null)
                    ? '—'
                    : FractionHelper.fractionToText(
                        e.amountNumerator!,
                        e.amountDenominator!,
                      );

                final time = DateFormat('HH:mm', 'es_ES').format(e.takenAt);
                final note = (e.note ?? '').trim();

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 56,
                        child: Text(
                          time,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('$name$unitText'),
                            const SizedBox(height: 2),
                            Text('Cantidad: $qty', style: TextStyle(color: m1)),
                            if (note.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(note, style: TextStyle(color: m2)),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
