import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../../l10n/l10n.dart';
import '../../../sleep/state/sleep_controller.dart';
import '../../../../models/sleep_entry.dart';
import '../../../../ui/theme_helpers.dart';
import '../../state/calendar_filter.dart';
import '../../state/home_controller.dart';

class HomeCalendarSection extends StatelessWidget {
  final SleepController provider;

  const HomeCalendarSection({super.key, required this.provider});

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
  DateTime _today() => _dateOnly(DateTime.now());

  String _filterLabel(BuildContext context, CalendarFilter f) {
    final l10n = context.l10n;
    switch (f) {
      case CalendarFilter.all:
        return l10n.commonAll;
      case CalendarFilter.sleep:
        return l10n.commonSleep;
      case CalendarFilter.mood:
        return l10n.commonMood;
      case CalendarFilter.habits:
        return l10n.commonHabits;
      case CalendarFilter.medication:
        return l10n.commonMedication;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context);
    final localeTag = locale.toString();

    final entriesByDay = <DateTime, SleepEntry>{};
    for (final e in provider.entries) {
      entriesByDay[_dateOnly(e.nightDate)] = e;
    }

    final textScale = MediaQuery.textScalerOf(context).scale(1.0);
    final daysOfWeekHeight = (24.0 * textScale).clamp(24.0, 42.0);

    String formatLabel(CalendarFormat f) {
      switch (f) {
        case CalendarFormat.month:
          return l10n.homeCalendarMonth;
        case CalendarFormat.twoWeeks:
          return l10n.homeCalendarTwoWeeks;
        case CalendarFormat.week:
          return l10n.homeCalendarWeek;
      }
    }

    final home = context.watch<HomeController>();

    return TableCalendar(
      firstDay: DateTime(2020, 1, 1),
      lastDay: _today(),
      focusedDay: home.focusedDay,
      locale: localeTag,
      startingDayOfWeek: StartingDayOfWeek.sunday,
      calendarFormat: home.calendarFormat,
      daysOfWeekHeight: daysOfWeekHeight,
      headerStyle: const HeaderStyle(
        titleCentered: true,
        formatButtonVisible: false,
        formatButtonShowsNext: false,
      ),
      availableCalendarFormats: {
        CalendarFormat.month: l10n.homeCalendarMonth,
        CalendarFormat.twoWeeks: l10n.homeCalendarTwoWeeks,
        CalendarFormat.week: l10n.homeCalendarWeek,
      },
      selectedDayPredicate: (day) => isSameDay(day, home.selectedDay),
      onDaySelected: (selectedDay, focusedDay) {
        home.selectDay(selectedDay, focusedDay);
      },
      onPageChanged: (focusedDay) {
        home.setFocusedDay(focusedDay);
      },
      onFormatChanged: (format) {
        home.setCalendarFormat(format);
      },
      eventLoader: (day) {
        final d = _dateOnly(day);
        return entriesByDay.containsKey(d) ? [entriesByDay[d]!] : [];
      },
      calendarBuilders: CalendarBuilders(
        headerTitleBuilder: (context, day) {
          final title = DateFormat('MMMM yyyy', localeTag).format(day);
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
                    tooltip: l10n.homeCalendarViewTooltip,
                    onSelected: home.setCalendarFormat,
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        value: CalendarFormat.month,
                        child: Text(l10n.homeCalendarMonth),
                      ),
                      PopupMenuItem(
                        value: CalendarFormat.twoWeeks,
                        child: Text(l10n.homeCalendarTwoWeeks),
                      ),
                      PopupMenuItem(
                        value: CalendarFormat.week,
                        child: Text(l10n.homeCalendarWeek),
                      ),
                    ],
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.calendar_view_month, size: 18),
                        const SizedBox(width: 4),
                        Text(
                          formatLabel(home.calendarFormat),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<CalendarFilter>(
                    tooltip: l10n.homeCalendarFilterTooltip,
                    onSelected: home.setCalendarFilter,
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        value: CalendarFilter.all,
                        child: Text(l10n.commonAll),
                      ),
                      PopupMenuItem(
                        value: CalendarFilter.mood,
                        child: Text('🙂 ${l10n.commonMood}'),
                      ),
                      PopupMenuItem(
                        value: CalendarFilter.habits,
                        child: Text('🚶💧 ${l10n.commonHabits}'),
                      ),
                      PopupMenuItem(
                        value: CalendarFilter.sleep,
                        child: Text('🌙 ${l10n.commonSleep}'),
                      ),
                      PopupMenuItem(
                        value: CalendarFilter.medication,
                        child: Text('💊 ${l10n.commonMedication}'),
                      ),
                    ],
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.filter_list, size: 18),
                        const SizedBox(width: 4),
                        Text(
                          _filterLabel(context, home.calendarFilter),
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

          final mood = context.watch<HomeController>().moodByDay[d];
          final hasSleep = events.isNotEmpty;
          final intakeCount =
              context.watch<HomeController>().intakesCountByDay[d] ?? 0;
          final habits = context.watch<HomeController>().habitsByDay[d];
          final blocksWalked = context
              .watch<HomeController>()
              .blocksWalkedByDay[d];

          bool showSleep = false;
          bool showMood = false;
          bool showMeds = false;
          bool showHabits = false;

          final filter = context.watch<HomeController>().calendarFilter;
          switch (filter) {
            case CalendarFilter.all:
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
            case CalendarFilter.habits:
              showHabits =
                  ((blocksWalked ?? 0) > 0) ||
                  ((habits?.waterCount ?? 0) > 0);
              break;

            case CalendarFilter.medication:
              showMeds = intakeCount > 0;
              break;
          }

          if (!showSleep && !showMood && !showMeds && !showHabits) {
            return const SizedBox.shrink();
          }

          final cs = Theme.of(context).colorScheme;

          final sleepDot = cs.primary;
          final medsDot = cs.secondary;
          final moodDot = mood == null ? cs.outline : moodColor(context, mood);
          final moodOn = onColorForDot(moodDot);

          Widget habitDot({
            IconData? icon,
            int? value,
            required Color bg,
            required Color fg,
          }) {
            const double size = 18;
            final isTwoDigits = (value ?? 0) >= 10;

            return Container(
              width: size,
              height: size,
              decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
              alignment: Alignment.center,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (icon != null)
                    Icon(icon, size: 14, color: fg.withValues(alpha: 0.95)),
                  if (value != null)
                    Text(
                      '$value',
                      style: TextStyle(
                        color: fg,
                        fontSize: isTwoDigits ? 10 : 11,
                        fontWeight: FontWeight.w800,
                        height: 1.0,
                      ),
                    ),
                ],
              ),
            );
          }

          return SizedBox.expand(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                if (showHabits && (blocksWalked ?? 0) > 0)
                  Positioned(
                    bottom: 4,
                    left: 4,
                    child: habitDot(
                      icon: Icons.directions_walk,
                      bg: cs.tertiary,
                      fg: cs.onTertiary,
                    ),
                  ),
                if (showHabits &&
                    habits != null &&
                    ((habits.waterCount ?? 0) > 0))
                  Positioned(
                    bottom: 4,
                    right: 4,
                    child: habitDot(
                      icon: Icons.water_drop,
                      bg: cs.primary,
                      fg: cs.onPrimary,
                    ),
                  ),

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
                        '${events.isNotEmpty ? (events.first as SleepEntry).sleepQuality : 0}',
                        style: TextStyle(
                          color: cs.onPrimary,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          height: 1.0,
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
                    bottom: 4,
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
            ),
          );
        },
      ),
    );
  }
}
