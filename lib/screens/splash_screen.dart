import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import '../app/navigation.dart';
import '../utils/date_parse.dart';
import '../services/notification_service.dart';
import 'quick_intake_screen.dart';
import 'daily_entry_screen.dart';

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

    // 1) Ir a home como base
    navigatorKey.currentState?.pushReplacementNamed('/home');

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
    const background = Color(0xFFF7F6F3);
    const sun = Color(0xFFF2C94C);
    const title = Color(0xFF2F2F2F);
    const subtitle = Color(0xFF8A8A8A);

    return Scaffold(
      body: Container(
        color: background,
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
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 18,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.wb_sunny_rounded,
                      color: sun,
                      size: 120,
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'Mediary',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: title,
                      height: 1.2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Your everyday health record',
                    style: TextStyle(fontSize: 16, color: subtitle),
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
