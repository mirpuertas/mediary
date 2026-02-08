import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../l10n/l10n.dart';

// NOTIFICACIONES
Future<bool> ensureNotificationPermission(BuildContext context) async {
  final status = await Permission.notification.status;

  if (status.isGranted) return true;

  final result = await Permission.notification.request();
  if (result.isGranted) return true;

  // Mostrar popup si sigue denegado
  if (context.mounted) {
    final l10n = context.l10n;
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l10n.permissionsNotificationsDisabledTitle),
        content: Text(l10n.permissionsNotificationsDisabledBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () async {
              await openAppSettings();
              if (context.mounted) {
                Navigator.pop(context);
              }
            },
            child: Text(l10n.settingsOpenSettings),
          ),
        ],
      ),
    );
  }

  return false;
}

// ALARMA EXACTA
Future<bool> ensureExactAlarmPermission(BuildContext context) async {
  // Este status puede variar según fabricante/OS, pero sirve como primer check.
  final status = await Permission.scheduleExactAlarm.status;
  if (status.isGranted) return true;

  // Camino recomendado en Flutter: pedirlo a través del plugin (abre pantalla correcta).
  final fln = FlutterLocalNotificationsPlugin();
  final android = fln
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  if (android != null) {
    final granted = await android.requestExactAlarmsPermission();
    if (granted == true) return true;
  }

  // Si sigue denegado, guiar al usuario
  if (context.mounted) {
    final l10n = context.l10n;
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l10n.permissionsExactAlarmsTitle),
        content: Text(l10n.permissionsExactAlarmsBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.commonNotNow),
          ),
          TextButton(
            onPressed: () async {
              await openAppSettings();
              if (context.mounted) {
                Navigator.pop(context);
              }
            },
            child: Text(l10n.settingsOpenSettings),
          ),
        ],
      ),
    );
  }

  return false;
}

// OPTIMIZACIÓN DE BATERÍA
Future<bool> checkBatteryRestrictions(BuildContext context) async {
  final info = await DeviceInfoPlugin().androidInfo;

  // Fabricantes conocidos por restricciones agresivas
  final sospechosos = ['xiaomi', 'oppo', 'vivo', 'huawei', 'samsung'];

  if (sospechosos.contains(info.manufacturer.toLowerCase())) {
    if (context.mounted) {
      final l10n = context.l10n;
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text(l10n.permissionsBatteryRecommendationTitle),
          content: Text(
            l10n.permissionsBatteryRecommendationBody(info.manufacturer),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.commonUnderstood),
            ),
          ],
        ),
      );
    }
  }

  return true;
}
