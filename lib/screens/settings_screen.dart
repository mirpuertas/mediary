import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';

import '../services/notification_service.dart';
import '../services/export_service.dart';
import '../services/database_helper.dart';
import '../providers/medication_provider.dart';
import '../providers/sleep_entry_provider.dart';
import '../providers/theme_provider.dart';
import 'welcome_screen.dart';

enum _ExportDateChoice { all, range }

class _ExportDateFilter {
  final DateTime? start;
  final DateTime? end;

  const _ExportDateFilter.all() : start = null, end = null;

  const _ExportDateFilter.range(this.start, this.end);
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = false;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 8, minute: 0);
  bool _isLoading = true;

  Map<String, dynamic> _exportStats = {};
  bool _hasNotificationPermission = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadExportStats();
    _checkNotificationPermission();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;

    setState(() {
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? false;
      final hour = prefs.getInt('reminder_hour') ?? 8;
      final minute = prefs.getInt('reminder_minute') ?? 0;
      _reminderTime = TimeOfDay(hour: hour, minute: minute);
      _isLoading = false;
    });
  }

  Future<void> _loadExportStats() async {
    try {
      final db = DatabaseHelper.instance;
      final entries = await db.getAllSleepEntriesFromDayEntries();
      final events = await db.getAllIntakeEvents();

      final availableRange = await ExportService.instance
          .getAvailableDataRange();

      if (entries.isEmpty && events.isEmpty) {
        if (!mounted) return;
        setState(() {
          _exportStats = {'totalEntries': 0, 'totalEvents': 0, 'dateRange': ''};
        });
        return;
      }

      final total = entries.length;
      final fmt = DateFormat('d MMM yyyy', 'es_ES');
      final range = availableRange == null
          ? ''
          : '${fmt.format(availableRange.start)} → ${fmt.format(availableRange.end)}';

      if (!mounted) return;
      setState(() {
        _exportStats = {
          'totalEntries': total,
          'totalEvents': events.length,
          'dateRange': range,
        };
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _exportStats = {'totalEntries': 0, 'totalEvents': 0, 'dateRange': ''};
      });
    }
  }

  Future<_ExportDateFilter?> _askExportDateFilter() async {
    final currentContext = context;
    final choice = await showDialog<_ExportDateChoice>(
      context: currentContext,
      builder: (context) => AlertDialog(
        title: const Text('Exportar datos'),
        content: const Text(
          '¿Querés exportar todos los datos o elegir un rango de fechas?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, _ExportDateChoice.all),
            child: const Text('Todo'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, _ExportDateChoice.range),
            child: const Text('Elegir rango'),
          ),
        ],
      ),
    );

    if (!currentContext.mounted) return null;

    if (choice == null) return null;
    if (choice == _ExportDateChoice.all) return const _ExportDateFilter.all();

    final available = await ExportService.instance.getAvailableDataRange();
    if (!currentContext.mounted) return null;
    if (available == null) {
      // Sin datos: no hay rango seleccionable.
      return const _ExportDateFilter.all();
    }

    final picked = await showDateRangePicker(
      context: currentContext,
      firstDate: available.start,
      lastDate: available.end,
      initialDateRange: DateTimeRange(
        start: available.start,
        end: available.end,
      ),
      helpText: 'Seleccioná el rango a exportar',
    );

    if (!currentContext.mounted) return null;

    if (picked == null) return null;
    return _ExportDateFilter.range(picked.start, picked.end);
  }

  Future<void> _checkNotificationPermission() async {
    final hasPermission = await NotificationService.instance
        .areNotificationsEnabled();
    if (!mounted) return;
    setState(() {
      _hasNotificationPermission = hasPermission;
    });
  }

  Future<void> _requestNotificationPermission() async {
    final granted = await NotificationService.instance.requestPermissions();

    if (!granted) {
      if (!mounted) return;

      final shouldOpen = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Permiso de notificaciones'),
          content: const Text(
            'Las notificaciones están desactivadas. Para activarlas, ve a Configuración de la aplicación.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Abrir configuración'),
            ),
          ],
        ),
      );

      if (shouldOpen == true) {
        await openAppSettings();
      }
    }

    await _checkNotificationPermission();
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', _notificationsEnabled);
    await prefs.setInt('reminder_hour', _reminderTime.hour);
    await prefs.setInt('reminder_minute', _reminderTime.minute);

    if (_notificationsEnabled) {
      await NotificationService.instance.scheduleDailyReminder(
        hour: _reminderTime.hour,
        minute: _reminderTime.minute,
      );
    } else {
      await NotificationService.instance.cancelDailyReminder();
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _reminderTime) {
      setState(() {
        _reminderTime = picked;
      });
      await _saveSettings();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Recordatorio configurado para las ${_reminderTime.format(context)}',
            ),
          ),
        );
      }
    }
  }

  Future<void> _testNotification() async {
    final currentContext = context;
    final messenger = ScaffoldMessenger.of(currentContext);

    // Asegurarse de tener permisos antes de enviar
    final granted = await NotificationService.instance.requestPermissions();

    if (!currentContext.mounted) return;

    if (!granted) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Permiso denegado: no se pudo enviar la notificación'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // ✅ Este método SÍ existe en tu NotificationService
    await NotificationService.instance.showTestNotification();

    if (!currentContext.mounted) return;

    messenger.showSnackBar(
      const SnackBar(content: Text('Notificación de prueba enviada')),
    );
  }

  Future<void> _exportSleepAnalyticsCsv() async {
    final currentContext = context;
    final filter = await _askExportDateFilter();
    if (filter == null || !currentContext.mounted) return;

    final rootNavigator = Navigator.of(currentContext, rootNavigator: true);
    final messenger = ScaffoldMessenger.of(currentContext);
    bool loadingShown = false;
    try {
      showDialog(
        context: currentContext,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );
      loadingShown = true;

      await ExportService.instance.shareSleepAnalyticsCsv(
        startDate: filter.start,
        endDate: filter.end,
      );

      if (currentContext.mounted) {
        if (loadingShown) rootNavigator.pop();
      }
    } catch (e) {
      if (currentContext.mounted) {
        if (loadingShown) rootNavigator.pop();
        messenger.showSnackBar(
          SnackBar(
            content: Text('Error al exportar sleep.csv: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _exportMedicationsAnalyticsCsv() async {
    final currentContext = context;
    final filter = await _askExportDateFilter();
    if (filter == null || !currentContext.mounted) return;

    final rootNavigator = Navigator.of(currentContext, rootNavigator: true);
    final messenger = ScaffoldMessenger.of(currentContext);
    bool loadingShown = false;
    try {
      showDialog(
        context: currentContext,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );
      loadingShown = true;

      await ExportService.instance.shareMedicationsAnalyticsCsv(
        startDate: filter.start,
        endDate: filter.end,
      );

      if (currentContext.mounted) {
        if (loadingShown) rootNavigator.pop();
      }
    } catch (e) {
      if (currentContext.mounted) {
        if (loadingShown) rootNavigator.pop();
        messenger.showSnackBar(
          SnackBar(
            content: Text('Error al exportar medications.csv: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _exportPDF() async {
    final currentContext = context;
    final filter = await _askExportDateFilter();
    if (filter == null || !currentContext.mounted) return;

    final rootNavigator = Navigator.of(currentContext, rootNavigator: true);
    final messenger = ScaffoldMessenger.of(currentContext);
    bool loadingShown = false;
    try {
      showDialog(
        context: currentContext,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );
      loadingShown = true;

      await ExportService.instance.sharePDF(
        startDate: filter.start,
        endDate: filter.end,
      );

      if (currentContext.mounted) {
        if (loadingShown) rootNavigator.pop(); // cerrar loading
      }
    } catch (e) {
      if (currentContext.mounted) {
        if (loadingShown) rootNavigator.pop(); // cerrar loading
        messenger.showSnackBar(
          SnackBar(
            content: Text('Error al exportar PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _exportXlsx() async {
    final currentContext = context;
    final filter = await _askExportDateFilter();
    if (filter == null || !currentContext.mounted) return;

    final rootNavigator = Navigator.of(currentContext, rootNavigator: true);
    final messenger = ScaffoldMessenger.of(currentContext);
    bool loadingShown = false;
    try {
      showDialog(
        context: currentContext,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );
      loadingShown = true;

      await ExportService.instance.shareXlsx(
        startDate: filter.start,
        endDate: filter.end,
      );

      if (currentContext.mounted) {
        if (loadingShown) rootNavigator.pop();
      }
    } catch (e) {
      if (currentContext.mounted) {
        if (loadingShown) rootNavigator.pop();
        messenger.showSnackBar(
          SnackBar(
            content: Text('Error al exportar Excel: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<bool?> _showWipeAllDataDialog() async {
    bool acknowledged = false;

    return showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Borrado total'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Esto eliminará TODOS tus datos guardados en el dispositivo:',
                  ),
                  const SizedBox(height: 8),
                  const Text('• Medicamentos (activos y archivados)'),
                  const Text('• Recordatorios de medicación'),
                  const Text('• Tomas registradas'),
                  const Text('• Registros de sueño'),
                  const Text('• Configuración y estado de la app'),
                  const SizedBox(height: 12),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: acknowledged,
                    title: const Text(
                      'Entiendo que esta acción es irreversible',
                    ),
                    onChanged: (value) {
                      setState(() {
                        acknowledged = value ?? false;
                      });
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: acknowledged
                      ? () => Navigator.pop(context, true)
                      : null,
                  child: const Text('Eliminar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _wipeAllData() async {
    final confirmed = await _showWipeAllDataDialog();
    if (confirmed != true) return;

    if (!mounted) return;

    // Capturar providers antes de cruzar más async gaps
    final medicationProvider = context.read<MedicationProvider>();
    final sleepProvider = context.read<SleepEntryProvider>();
    final themeProvider = context.read<ThemeProvider>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await NotificationService.instance.cancelAllNotifications();
      await DatabaseHelper.instance.wipeAllData();

      // Reinicio tipo "recién instalada": borrar TODAS las preferencias.
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      // Volver a tema por defecto.
      await themeProvider.setThemeMode(ThemeMode.system);

      // Por defecto, el recordatorio diario de sueño inicia apagado.
      await prefs.setBool('notifications_enabled', false);
      await prefs.setInt('reminder_hour', 8);
      await prefs.setInt('reminder_minute', 0);

      if (mounted) {
        setState(() {
          _notificationsEnabled = false;
          _reminderTime = const TimeOfDay(hour: 8, minute: 0);
        });
      }

      // No reprogramar recordatorio diario: queda apagado.
      await NotificationService.instance.cancelDailyReminder();

      if (!mounted) return;
      Navigator.pop(context);

      try {
        await medicationProvider.loadMedications();
      } catch (_) {}
      try {
        await sleepProvider.loadEntries();
      } catch (_) {}

      await _loadExportStats();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Datos eliminados correctamente')),
      );

      // Ir a onboarding como "primera apertura".
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const WelcomeScreen()),
        (route) => false,
      );
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al borrar datos: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final totalEntries = (_exportStats['totalEntries'] ?? 0) as int;
    final totalEvents = (_exportStats['totalEvents'] ?? 0) as int;
    final hasData = totalEntries > 0 || totalEvents > 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: ListView(
        children: [
          _buildSectionHeader('Apariencia'),
          Builder(
            builder: (context) {
              final themeProvider = context.watch<ThemeProvider>();
              final isSystem = themeProvider.themeMode == ThemeMode.system;
              final effectiveIsDark =
                  Theme.of(context).brightness == Brightness.dark;

              return Column(
                children: [
                  SwitchListTile(
                    title: const Text('Modo oscuro'),
                    subtitle: Text(
                      isSystem
                          ? 'Usando el tema del sistema'
                          : (effectiveIsDark ? 'Oscuro' : 'Claro'),
                    ),
                    value: effectiveIsDark,
                    onChanged: (value) async {
                      await themeProvider.setDarkModeEnabled(value);
                    },
                    secondary: const Icon(Icons.dark_mode),
                  ),
                ],
              );
            },
          ),
          const Divider(),

          _buildSectionHeader('Recordatorios'),

          if (!_hasNotificationPermission) ...[
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                border: Border.all(color: Colors.orange),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning, color: Colors.orange),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Permiso de notificaciones desactivado',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Los recordatorios no funcionarán hasta que actives el permiso.',
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Activar permiso de notificaciones'),
              subtitle: const Text('Abrir configuración del sistema'),
              trailing: const Icon(Icons.open_in_new),
              onTap: _requestNotificationPermission,
            ),
            const Divider(),
          ],

          SwitchListTile(
            title: const Text('Recordatorio diario'),
            subtitle: const Text('Notificación para registrar tu sueño'),
            value: _notificationsEnabled,
            onChanged: (value) {
              setState(() {
                _notificationsEnabled = value;
              });
              _saveSettings();
            },
            secondary: const Icon(Icons.notifications_active),
          ),
          ListTile(
            enabled: _notificationsEnabled,
            leading: const Icon(Icons.access_time),
            title: const Text('Hora del recordatorio'),
            subtitle: Text(_reminderTime.format(context)),
            trailing: const Icon(Icons.edit),
            onTap: _notificationsEnabled ? _selectTime : null,
          ),
          if (kDebugMode)
            ListTile(
              enabled: _notificationsEnabled,
              leading: const Icon(Icons.notifications),
              title: const Text('Probar notificación'),
              subtitle: const Text('Programar notificación de prueba (2s)'),
              onTap: _notificationsEnabled ? _testNotification : null,
            ),
          const Divider(),

          _buildSectionHeader('Exportar Datos'),

          if (hasData) ...[
            ListTile(
              leading: const Icon(Icons.bar_chart),
              title: const Text('Registros de sueño'),
              trailing: Text(
                '$totalEntries',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.medication),
              title: const Text('Tomas registradas'),
              trailing: Text(
                '$totalEvents',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.date_range),
              title: const Text('Rango de fechas'),
              subtitle: Text((_exportStats['dateRange'] ?? '') as String),
            ),
          ],

          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                ElevatedButton.icon(
                  onPressed: hasData ? _exportPDF : null,
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text('Exportar a PDF'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                    minimumSize: const Size(double.infinity, 50),
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: hasData ? _exportXlsx : null,
                  icon: const Icon(Icons.table_view),
                  label: const Text('Exportar a Excel (.xlsx)'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                    minimumSize: const Size(double.infinity, 50),
                  ),
                ),
              ],
            ),
          ),

          _buildSectionHeader('Exportar para analítica'),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                ElevatedButton.icon(
                  onPressed: hasData ? _exportSleepAnalyticsCsv : null,
                  icon: const Icon(Icons.file_present),
                  label: const Text('sleep.csv'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                    minimumSize: const Size(double.infinity, 50),
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: hasData ? _exportMedicationsAnalyticsCsv : null,
                  icon: const Icon(Icons.file_present),
                  label: const Text('medications.csv'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                    minimumSize: const Size(double.infinity, 50),
                  ),
                ),
              ],
            ),
          ),
          if (!hasData)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'No hay datos para exportar. Registrá algunos días primero.',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ),

          const Divider(),

          _buildSectionHeader('Información'),
          const ListTile(
            leading: Icon(Icons.info),
            title: Text('Acerca de'),
            subtitle: Text('Mediary v1.0.0'),
          ),
          const ListTile(
            leading: Icon(Icons.privacy_tip),
            title: Text('Privacidad'),
            subtitle: Text(
              'Todos tus datos se guardan localmente en tu dispositivo',
            ),
          ),

          const Divider(),
          _buildSectionHeader('Zona de peligro'),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text('Borrado total'),
            subtitle: const Text('Eliminar todos los datos del dispositivo'),
            onTap: _wipeAllData,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
