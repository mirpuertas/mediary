import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:med_journal/l10n/gen/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz_lib;
import 'package:flutter_timezone/flutter_timezone.dart';

import 'features/medication/state/medication_controller.dart';
import 'features/medication/data/intake_repository.dart';
import 'features/medication/data/medication_repository.dart';
import 'features/sleep/state/sleep_controller.dart';
import 'features/sleep/data/sleep_repository.dart';
import 'providers/theme_controller.dart';
import 'providers/app_preferences_controller.dart';
import 'ui/app_theme_tokens.dart';

import 'features/app_start/presentation/screens/welcome_screen.dart';
import 'features/app_start/presentation/screens/splash_screen.dart';

import 'services/notification_service.dart';
import 'services/database_helper.dart';
import 'services/error_logger.dart';
import 'widgets/app_lock_listener.dart';

import 'app/navigation.dart';
import 'app/routes.dart';

import 'dart:async';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  tz.initializeTimeZones();
  final String timeZoneName = await FlutterTimezone.getLocalTimezone();
  tz_lib.setLocalLocation(tz_lib.getLocation(timeZoneName));

  final localeName = PlatformDispatcher.instance.locale.toString();
  await initializeDateFormatting(localeName, null);

  await NotificationService.instance.initialize();
  await _captureLaunchNotificationPayload();

  runApp(const MyApp());
  unawaited(_initializeBackgroundTasks());
}

Future<void> _captureLaunchNotificationPayload() async {
  try {
    final details = await FlutterLocalNotificationsPlugin()
        .getNotificationAppLaunchDetails();
    final payload = details?.notificationResponse?.payload;

    if (payload == null || payload.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('pending_notification_payload', payload);
  } catch (e, stackTrace) {
    ErrorLogger.instance.logNotificationError(
      e,
      stackTrace: stackTrace,
      action: 'Capture launch notification payload',
    );
  }
}

Future<void> _initializeBackgroundTasks() async {
  try {
    await NotificationService.instance.requestPermissions();

    final prefs = await SharedPreferences.getInstance();
    final notificationsEnabled =
        prefs.getBool('notifications_enabled') ?? false;
    final hour = prefs.getInt('reminder_hour') ?? 8;
    final minute = prefs.getInt('reminder_minute') ?? 0;

    if (notificationsEnabled) {
      await NotificationService.instance.scheduleDailyReminder(
        hour: hour,
        minute: minute,
      );
    }

    await _rescheduleMedicationReminders();
    await _rescheduleMedicationGroupReminders();
  } catch (e, stackTrace) {
    ErrorLogger.instance.logNotificationError(
      e,
      stackTrace: stackTrace,
      action: 'Background tasks initialization',
    );
  }
}

Future<void> _rescheduleMedicationReminders() async {
  try {
    final db = DatabaseHelper.instance;
    final reminders = await db.getAllReminders();

    for (final reminder in reminders) {
      final medication = await db.getMedication(reminder.medicationId);
      if (medication != null && !medication.isArchived) {
        await NotificationService.instance.scheduleMedicationReminder(
          reminder,
          medication,
        );
      }
    }
  } catch (e) {
    if (kDebugMode) {
      debugPrint('Error rescheduling medication reminders: $e');
    }
  }
}

Future<void> _rescheduleMedicationGroupReminders() async {
  try {
    final db = DatabaseHelper.instance;
    final reminders = await db.getAllGroupReminders();

    for (final reminder in reminders) {
      final group = await db.getMedicationGroup(reminder.groupId);
      if (group == null || group.isArchived) continue;

      final meds = await db.getMedicationGroupMembers(reminder.groupId);
      final activeMeds = meds.where((m) => !m.isArchived).toList();
      if (activeMeds.isEmpty) continue;

      await NotificationService.instance.scheduleMedicationGroupReminder(
        reminder: reminder,
        group: group,
        medicationsSnapshot: activeMeds,
      );
    }
  } catch (e) {
    if (kDebugMode) {
      debugPrint('Error rescheduling group medication reminders: $e');
    }
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => MedicationController(repo: MedicationRepository()),
        ),
        ChangeNotifierProvider(
          create: (_) => SleepController(
            repo: SleepRepository(),
            intakeRepo: IntakeRepository(),
          ),
        ),
        ChangeNotifierProvider(create: (_) => ThemeController()),
        ChangeNotifierProvider(
          create: (_) => AppPreferencesController()..load(),
        ),
      ],
      child: Consumer2<ThemeController, AppPreferencesController>(
        builder: (context, themeController, prefs, _) {
          const seed = Color(0xFF3F51B5);

          final lightScheme =
              ColorScheme.fromSeed(
                seedColor: seed,
                brightness: Brightness.light,
              ).copyWith(
                tertiary: const Color(0xFF355F7C),
                onTertiary: Colors.white,
                tertiaryContainer: const Color(0xFFDCE8F2),
                onTertiaryContainer: const Color(0xFF0F2433),
                inversePrimary: const Color(0xFFC6CCFF),
                error: const Color(0xFFB84C4C),
              );

          final darkScheme =
              ColorScheme.fromSeed(
                seedColor: seed,
                brightness: Brightness.dark,
              ).copyWith(
                tertiary: const Color(0xFF6FA3C8),
                onTertiary: const Color(0xFF071821),
                tertiaryContainer: const Color(0xFF0B2A3F),
                onTertiaryContainer: const Color(0xFFD6ECFF),
                inversePrimary: const Color(0xFF586091),
                error: const Color(0xFFB84C4C),
              );

          final lightThemeData = ThemeData(
            useMaterial3: true,
            colorScheme: lightScheme,
            extensions: <ThemeExtension<dynamic>>[
              AppSurfaceColors.light,
              AppStatusColors.light(),
              AppNeutralColors.standard(),
              AppBrandColors.standard,
            ],
          );

          final darkThemeData = ThemeData(
            useMaterial3: true,
            colorScheme: darkScheme,
            extensions: <ThemeExtension<dynamic>>[
              AppSurfaceColors.dark,
              AppStatusColors.dark(),
              AppNeutralColors.standard(),
              AppBrandColors.standard,
            ],
          );

          return MaterialApp(
            navigatorKey: navigatorKey,
            navigatorObservers: [routeObserver],
            title: 'Mediary',
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: prefs.locale,
            themeMode: themeController.themeMode,
            theme: lightThemeData,
            darkTheme: darkThemeData,
            builder: (context, child) {
              if (child == null) return const SizedBox.shrink();
              return AppLockListener(child: child);
            },
            home: AppInitializer(lightTheme: lightThemeData),
            routes: AppRoutes.routes,
            onGenerateRoute: AppRoutes.onGenerateRoute,
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}

class AppInitializer extends StatelessWidget {
  final ThemeData lightTheme;

  const AppInitializer({super.key, required this.lightTheme});

  Future<bool> _checkOnboardingStatus() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('onboarding_complete') ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _checkOnboardingStatus(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final onboardingComplete = snapshot.data ?? false;

        if (onboardingComplete) {
          return const SplashScreen();
        } else {
          return Theme(data: lightTheme, child: const WelcomeScreen());
        }
      },
    );
  }
}
