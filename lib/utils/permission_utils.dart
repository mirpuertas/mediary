import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// NOTIFICACIONES
Future<bool> ensureNotificationPermission(BuildContext context) async {
  final status = await Permission.notification.status;

  if (status.isGranted) return true;

  final result = await Permission.notification.request();
  if (result.isGranted) return true;

  // Mostrar popup si sigue denegado
  if (context.mounted) {
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Notificaciones desactivadas'),
        content: const Text(
          'Para que los recordatorios funcionen, activá las notificaciones en '
          'Ajustes del sistema.\n\n'
          'Esto permite mostrar avisos en la hora programada.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              await openAppSettings();
              if (context.mounted) {
                Navigator.pop(context);
              }
            },
            child: const Text('Abrir Ajustes'),
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
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Permitir alarmas exactas'),
        content: const Text(
          'Este recordatorio necesita sonar a la hora exacta.\n\n'
          'Activá "Alarmas y recordatorios" para esta app. '
          'Si no lo activás, el aviso puede llegar con demora.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Ahora no'),
          ),
          TextButton(
            onPressed: () async {
              await openAppSettings();
              if (context.mounted) {
                Navigator.pop(context);
              }
            },
            child: const Text('Abrir Ajustes'),
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
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Recomendación de batería'),
          content: Text(
            'Este equipo (${info.manufacturer}) a veces restringe apps en segundo plano.\n\n'
            'Si tus notificaciones no llegan, desactivá la optimización de batería para esta app:\n\n'
            'Ajustes → Batería → Sin restricciones / No optimizar',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Entendido'),
            ),
          ],
        ),
      );
    }
  }

  return true;
}
