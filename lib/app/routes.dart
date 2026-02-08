import 'package:flutter/material.dart';

import '../features/app_start/presentation/screens/splash_screen.dart';
import '../features/home/presentation/screens/home_screen.dart';
import '../features/medication/presentation/screens/medications_screen.dart';
import '../features/settings/presentation/screens/settings_screen.dart';
import '../features/summary/presentation/screens/summary_screen.dart';
import '../features/daily_entry/presentation/screens/daily_entry_screen.dart';
import '../features/medication/presentation/screens/quick_intake_screen.dart';

class AppRoutes {
  static const home = '/home';
  static const medications = '/medications';
  static const settings = '/settings';
  static const summary = '/summary';
  static const dailyEntry = '/daily-entry';
  static const quickIntake = '/quick-intake';
  static const splash = '/splash';

  static final routes = <String, WidgetBuilder>{
    splash: (_) => const SplashScreen(),
    home: (_) => HomeScreen.withProvider(),
    medications: (_) => const MedicationsScreen(),
    settings: (_) => const SettingsScreen(),
    summary: (_) => const SummaryScreen(),
  };

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case dailyEntry:
        final args = settings.arguments;
        if (args is DailyEntryRouteArgs) {
          return MaterialPageRoute(
            settings: settings,
            builder: (_) => DailyEntryScreen.withProvider(
              selectedDate: args.selectedDate,
              initialTabIndex: args.initialTabIndex,
              initialDaySection: args.initialDaySection,
            ),
          );
        }
        throw ArgumentError(
          'Missing/invalid arguments for $dailyEntry. Expected DailyEntryRouteArgs.',
        );

      case quickIntake:
        final args = settings.arguments;
        if (args is QuickIntakeRouteArgs) {
          return MaterialPageRoute(
            settings: settings,
            builder: (_) => QuickIntakeScreen(
              reminderId: args.reminderId,
              medicationIds: args.medicationIds,
              groupName: args.groupName,
            ),
          );
        }
        throw ArgumentError(
          'Missing/invalid arguments for $quickIntake. Expected QuickIntakeRouteArgs.',
        );
    }

    return null;
  }
}

class DailyEntryRouteArgs {
  final DateTime selectedDate;
  final int initialTabIndex;
  final DailyEntryDaySection? initialDaySection;

  const DailyEntryRouteArgs({
    required this.selectedDate,
    this.initialTabIndex = 1,
    this.initialDaySection,
  });
}

class QuickIntakeRouteArgs {
  final int? reminderId;
  final List<int> medicationIds;
  final String? groupName;

  const QuickIntakeRouteArgs({
    required this.reminderId,
    required this.medicationIds,
    this.groupName,
  });
}

