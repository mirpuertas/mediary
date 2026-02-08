import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../app/navigation.dart';
import '../../../../app/routes.dart';
import '../../../../l10n/l10n.dart';
import '../../../../services/app_lock_service.dart';
import '../../../../services/notification_service.dart';
import '../../../../ui/app_theme_tokens.dart';
import '../../../../utils/date_parse.dart';
import '../../../daily_entry/presentation/screens/daily_entry_screen.dart';
import '../../../security/presentation/screens/lock_screen.dart';
import '../../../medication/presentation/screens/quick_intake_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _controller.forward();

    _routeAfterSplash();
  }

  Future<void> _routeAfterSplash() async {
    await Future.delayed(const Duration(milliseconds: 950));

    // 0) App Lock gate: si está habilitado, desbloquear ANTES de navegar.
    final shouldLock = await AppLockService.instance.shouldRequireUnlockNow();
    if (shouldLock) {
      final nav = navigatorKey.currentState;
      if (nav != null) {
        final ok = await LockScreen.showWithNavigator(nav);
        if (ok != true) return;
      }
    }

    // 1) Ir a home como base
    navigatorKey.currentState?.pushReplacementNamed(AppRoutes.home);

    // Dejar que se asiente el navigator antes de push encima
    await Future.delayed(Duration.zero);

    // 2) Si hay pending payload, abrir pantalla correspondiente encima
    final payload = await NotificationService.instance.consumePendingOpen();
    if (payload == null || payload.isEmpty) return;

    try {
      final data = jsonDecode(payload) as Map<String, dynamic>;

      if (data['type'] == 'sleep') {
        final raw = data['date'];
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final date = parseDateOnly(raw is String ? raw : null, fallback: today);

        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (_) => DailyEntryScreen.withProvider(selectedDate: date),
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

      navigatorKey.currentState?.push(
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
        debugPrint('SplashScreen: error parsing pending open payload: $e');
        debugPrint('$st');
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;

    return Scaffold(
      body: Container(
        color: brand.splashBackground,
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: context.neutralColors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: context.neutralColors.black.withValues(
                            alpha: 0.06,
                          ),
                          blurRadius: 18,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.wb_sunny_rounded,
                      color: brand.splashSun,
                      size: 120,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Mediary',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: brand.splashTitle,
                      height: 1.2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    context.l10n.splashSubtitle,
                    style: TextStyle(fontSize: 16, color: brand.splashSubtitle),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
