import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../app/navigation.dart';
import '../../../../l10n/l10n.dart';
import '../../../medication/state/medication_controller.dart';
import '../../../sleep/state/sleep_controller.dart';
import '../../../daily_entry/presentation/screens/daily_entry_screen.dart';
import '../../../medication/presentation/screens/medications_screen.dart';
import '../../../medication/presentation/screens/quick_intake_screen.dart';
import '../../../settings/presentation/screens/settings_screen.dart';
import '../../../summary/presentation/screens/summary_screen.dart';
import '../../data/home_repository.dart';
import '../sections/home_calendar_section.dart';
import '../sections/selected_day_panel_section.dart';
import '../../state/home_controller.dart';
import '../../../home_notifications/data/home_notifications_repository.dart';
import '../../../home_notifications/state/home_notifications_controller.dart';
import '../../../home_reminders/data/home_reminders_repository.dart';
import '../../../home_reminders/presentation/sections/today_reminders_card_section.dart';
import '../../../home_reminders/state/home_reminders_controller.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  static Widget withProvider({Key? key}) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => HomeController(repo: HomeRepository()),
        ),
        ChangeNotifierProvider(
          create: (_) =>
              HomeRemindersController(repo: HomeRemindersRepository()),
        ),
        ChangeNotifierProvider(
          create: (_) =>
              HomeNotificationsController(repo: HomeNotificationsRepository()),
        ),
      ],
      child: HomeScreen(key: key),
    );
  }

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with WidgetsBindingObserver, RouteAware {
  PageRoute<dynamic>? _route;

  Future<void> _refreshHome() async {
    if (!mounted) return;

    final home = context.read<HomeController>();
    final sleepController = context.read<SleepController>();
    final reminders = context.read<HomeRemindersController>();
    final notif = context.read<HomeNotificationsController>();
    notif.updateDependencies(home: home, sleepController: sleepController);

    await notif.processPendingCompletes();

    await Future.wait([
      sleepController.loadEntries(),
      home.loadSelectedDay(home.selectedDay),
      reminders.refresh(),
    ]);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      final sleepController = context.read<SleepController>();
      final medicationController = context.read<MedicationController>();
      final home = context.read<HomeController>();

      await Future.wait([
        sleepController.loadEntries(),
        medicationController.loadMedications(),
      ]);

      await home.ensureMoodLoadedForMonth(home.focusedDay);
      await home.ensureIntakesLoadedForMonth(home.focusedDay);
      await home.ensureHabitsLoadedForMonth(home.focusedDay);
      await home.ensureBlocksWalkedLoadedForMonth(home.focusedDay);
      await home.loadSelectedDay(home.selectedDay);
      if (!mounted) return;
      await context.read<HomeRemindersController>().loadToday();

      // Procesar "Tomé todo" pendientes (app estaba cerrada, sin UI)
      if (!mounted) return;
      final notif = context.read<HomeNotificationsController>();
      notif.updateDependencies(home: home, sleepController: sleepController);
      await notif.processPendingCompletes();

      // Si la app se abrió desde una notificación (tap / "Elegir")
      final nav = await notif.consumePendingNotificationNavigation();
      if (!mounted || nav == null) return;

      if (nav is HomeNotificationNavSleep) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) =>
                DailyEntryScreen.withProvider(selectedDate: nav.date),
          ),
        );
        return;
      }

      if (nav is HomeNotificationNavQuickIntake) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => QuickIntakeScreen(
              reminderId: nav.reminderId,
              medicationIds: nav.medicationIds,
              groupName: nav.groupName,
            ),
          ),
        );
        return;
      }
    });
  }

  @override
  void dispose() {
    if (_route != null) {
      routeObserver.unsubscribe(this);
      _route = null;
    }
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final route = ModalRoute.of(context);
    if (route is PageRoute<dynamic> && route != _route) {
      if (_route != null) {
        routeObserver.unsubscribe(this);
      }
      _route = route;
      routeObserver.subscribe(this, route);
    }
  }

  @override
  void didPopNext() {
    // Volvemos a Home desde otra pantalla: rehidratar el día seleccionado y recordatorios.
    unawaited(_refreshHome());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Esperar a que pending completes se procesen ANTES de rebuild.
      // Usar addPostFrameCallback para asegurar que la UI se sincronice correctamente.
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        await _refreshHome();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final sleepController = context.watch<SleepController>();
    final medicationController = context.watch<MedicationController>();

    final localeName = Localizations.localeOf(context).toString();
    final dateFormat = DateFormat('d MMMM yyyy', localeName);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.homeTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart_sharp),
            tooltip: l10n.homeTooltipSummary,
            onPressed: () async {
              final home = context.read<HomeController>();
              final goToCalendar = await Navigator.push<bool>(
                context,
                MaterialPageRoute(builder: (_) => const SummaryScreen()),
              );

              if (!mounted) return;
              if (goToCalendar != true) return;
              await home.resetToToday();
            },
          ),
          IconButton(
            icon: const Icon(Icons.medication),
            tooltip: l10n.homeTooltipMedications,
            onPressed: () async {
              final medicationController = context.read<MedicationController>();
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MedicationsScreen()),
              );
              if (mounted) {
                await medicationController.loadMedications();
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: l10n.homeTooltipSettings,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: sleepController.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                const TodayRemindersCardSection(),
                HomeCalendarSection(provider: sleepController),
                const Divider(height: 1),
                Expanded(
                  child: SelectedDayPanelSection(
                    sleepController: sleepController,
                    medicationController: medicationController,
                    dateFormat: dateFormat,
                  ),
                ),
              ],
            ),
    );
  }
}
