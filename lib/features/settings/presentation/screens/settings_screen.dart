import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';

import '../../../../l10n/l10n.dart';
import '../../../../services/notification_service.dart';
import '../../../../services/export_service.dart';
import '../../../../services/app_lock_service.dart';
import '../../../../services/backup_service.dart';
import '../../../../services/database_helper.dart';
import '../../../../utils/permission_utils.dart';
import '../../../medication/state/medication_controller.dart';
import '../../../sleep/state/sleep_controller.dart';
import '../../../../ui/app_theme_tokens.dart';
import '../../../../providers/theme_controller.dart';
import '../../../../providers/app_preferences_controller.dart';
import '../../../../utils/ui_feedback.dart';
import '../../../app_start/presentation/screens/welcome_screen.dart';
import '../../../security/presentation/screens/set_pin_screen.dart';
import '../../../security/presentation/screens/lock_screen.dart';
import '../../data/settings_repository.dart';

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
  final SettingsRepository _repo = SettingsRepository();

  bool _notificationsEnabled = false;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 8, minute: 0);
  bool _isLoading = true;

  Map<String, dynamic> _exportStats = {};
  bool _hasNotificationPermission = true;

  bool _appLockEnabled = false;
  int _appLockTimeoutSeconds = 0;
  bool _biometricEnabled = false;
  bool _biometricAvailable = false;

  bool? _dbEncryptedAtRest;
  bool _hasExactAlarmPermission =
      true; // Asumimos true por defecto (pre-Android 12)

  String _localeLabel(AppLocalizations l10n, LocaleOverride value) {
    switch (value) {
      case LocaleOverride.system:
        return l10n.settingsLanguageSystem;
      case LocaleOverride.es:
        return l10n.settingsLanguageSpanish;
      case LocaleOverride.en:
        return l10n.settingsLanguageEnglish;
    }
  }

  Future<void> _pickLanguage(AppPreferencesController prefs) async {
    final l10n = context.l10n;
    final selected = prefs.localeOverride;

    final choice = await showDialog<LocaleOverride>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(l10n.settingsLanguageTitle),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, LocaleOverride.system),
            child: Row(
              children: [
                Expanded(child: Text(l10n.settingsLanguageSystem)),
                if (selected == LocaleOverride.system)
                  const Icon(Icons.check, size: 18),
              ],
            ),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, LocaleOverride.es),
            child: Row(
              children: [
                Expanded(child: Text(l10n.settingsLanguageSpanish)),
                if (selected == LocaleOverride.es)
                  const Icon(Icons.check, size: 18),
              ],
            ),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, LocaleOverride.en),
            child: Row(
              children: [
                Expanded(child: Text(l10n.settingsLanguageEnglish)),
                if (selected == LocaleOverride.en)
                  const Icon(Icons.check, size: 18),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(l10n.commonCancel),
              ),
            ),
          ),
        ],
      ),
    );

    if (!mounted) return;
    if (choice == null) return;
    await prefs.setLocaleOverride(choice);
  }

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadExportStats();
    _checkNotificationPermission();
    _loadDbEncryptionStatus();
  }

  Future<void> _loadDbEncryptionStatus() async {
    try {
      final status = await DatabaseHelper.instance.isDatabaseEncryptedAtRest();
      if (!mounted) return;
      setState(() => _dbEncryptedAtRest = status);
    } catch (_) {
      if (!mounted) return;
      setState(() => _dbEncryptedAtRest = null);
    }
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;

    setState(() {
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? false;
      final hour = prefs.getInt('reminder_hour') ?? 8;
      final minute = prefs.getInt('reminder_minute') ?? 0;
      _reminderTime = TimeOfDay(hour: hour, minute: minute);
      _appLockEnabled = prefs.getBool('app_lock_enabled') ?? false;
      _appLockTimeoutSeconds = prefs.getInt('app_lock_timeout_seconds') ?? 0;
      _isLoading = false;
    });

    _loadSecuritySettings();
  }

  Future<void> _loadExportStats() async {
    try {
      final counts = await _repo.loadExportCounts();

      final availableRange = await ExportService.instance
          .getAvailableDataRange();

      if (availableRange == null) {
        if (!mounted) return;
        setState(() {
          _exportStats = {
            'totalEntries': 0,
            'totalEvents': 0,
            'totalDays': 0,
            'dateRange': '',
          };
        });
        return;
      }

      final totalDays = counts.totalDays;
      final total = counts.totalEntries;
      final localeName = PlatformDispatcher.instance.locale.toString();
      final fmt = DateFormat('d MMM yyyy', localeName);
      final range =
          '${fmt.format(availableRange.start)} → ${fmt.format(availableRange.end)}';

      if (!mounted) return;
      setState(() {
        _exportStats = {
          'totalEntries': total,
          'totalEvents': counts.totalEvents,
          'totalDays': totalDays,
          'dateRange': range,
        };
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _exportStats = {
          'totalEntries': 0,
          'totalEvents': 0,
          'totalDays': 0,
          'dateRange': '',
        };
      });
    }
  }

  Future<_ExportDateFilter?> _askExportDateFilter() async {
    final currentContext = context;
    final choice = await showDialog<_ExportDateChoice>(
      context: currentContext,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.settingsExportDialogTitle),
        content: Text(context.l10n.settingsExportDialogBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, _ExportDateChoice.all),
            child: Text(context.l10n.commonAll),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, _ExportDateChoice.range),
            child: Text(context.l10n.commonChooseRange),
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
      helpText: currentContext.l10n.settingsExportSelectRangeHelpText,
    );

    if (!currentContext.mounted) return null;

    if (picked == null) return null;
    return _ExportDateFilter.range(picked.start, picked.end);
  }

  Future<void> _checkNotificationPermission() async {
    final hasPermission = await NotificationService.instance
        .areNotificationsEnabled();

    bool hasExactAlarm = true;
    if (Platform.isAndroid) {
      // Android 12+ (API 31+) requiere permiso explícito para alarmas exactas
      final version = await DeviceInfoPlugin().androidInfo;
      if (version.version.sdkInt >= 31) {
        hasExactAlarm = await Permission.scheduleExactAlarm.status.isGranted;
      }
    }

    if (!mounted) return;
    setState(() {
      _hasNotificationPermission = hasPermission;
      _hasExactAlarmPermission = hasExactAlarm;
    });
  }

  Future<void> _requestNotificationPermission() async {
    final granted = await NotificationService.instance.requestPermissions();

    if (!granted) {
      if (!mounted) return;

      final shouldOpen = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(context.l10n.settingsNotificationsPermissionTitle),
          content: Text(context.l10n.settingsNotificationsPermissionBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(context.l10n.commonCancel),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(context.l10n.settingsOpenSettings),
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

  Future<void> _requestExactAlarmPermission() async {
    if (Platform.isAndroid) {
      await Permission.scheduleExactAlarm.request();
    }
    await _checkNotificationPermission();
  }

  Future<void> _saveSettings() async {
    if (kDebugMode) {
      debugPrint(
        '💾 Saving settings. Enabled: $_notificationsEnabled, Time: ${_reminderTime.hour}:${_reminderTime.minute}',
      );
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', _notificationsEnabled);
    await prefs.setInt('reminder_hour', _reminderTime.hour);
    await prefs.setInt('reminder_minute', _reminderTime.minute);

    if (_notificationsEnabled) {
      if (kDebugMode) {
        debugPrint(
          '🕒 Calling scheduleDailyReminder with hour: ${_reminderTime.hour}, minute: ${_reminderTime.minute}',
        );
      }
      await NotificationService.instance.scheduleDailyReminder(
        hour: _reminderTime.hour,
        minute: _reminderTime.minute,
      );
    } else {
      if (kDebugMode) {
        debugPrint('🔕 Cancelling daily sleep reminder');
      }
      await NotificationService.instance.cancelDailyReminder();
    }
  }

  Future<void> _toggleAppLock(bool enable) async {
    final prefs = await SharedPreferences.getInstance();

    if (enable) {
      final hasPin = await AppLockService.instance.hasPin();
      if (!mounted) return;

      // Si no hay PIN, pedir crearlo.
      if (!hasPin) {
        final ok = await Navigator.of(context).push<bool>(
          MaterialPageRoute(
            builder: (_) => const SetPinScreen(isChange: false),
          ),
        );
        if (ok != true) return;
      }

      await AppLockService.instance.setEnabled(true);
      await prefs.setBool('app_lock_enabled', true);
      if (!mounted) return;
      setState(() => _appLockEnabled = true);
      return;
    }

    if (!mounted) return;

    if (_dbEncryptedAtRest == true) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(context.l10n.settingsDisableAppLockWarningTitle),
          content: Text(context.l10n.settingsDisableAppLockWarningBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(context.l10n.commonCancel),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(context.l10n.settingsDisableAppLockWarningDisable),
            ),
          ],
        ),
      );
      if (proceed != true) return;
      if (!mounted) return;
    }

    final ok = await LockScreen.show(context);
    if (ok != true) return;
    await AppLockService.instance.setEnabled(false);
    await prefs.setBool('app_lock_enabled', false);
    if (!mounted) return;
    setState(() => _appLockEnabled = false);
  }

  Future<void> _changePin() async {
    final ok = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) =>
            const SetPinScreen(isChange: true, requireCurrentPin: true),
      ),
    );
    if (ok == true && mounted) {
      UIFeedback.showSuccess(context, context.l10n.settingsPinUpdated);
    }
  }

  Future<void> _setLockTimeout() async {
    final l10n = context.l10n;
    final options = <int, String>{
      0: l10n.settingsLockTimeoutImmediateBack,
      30: l10n.settingsLockTimeout30Seconds,
      120: l10n.settingsLockTimeout2Minutes,
      300: l10n.settingsLockTimeout5Minutes,
    };

    final chosen = await showDialog<int>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(context.l10n.settingsLockOnReturnDialogTitle),
        children: [
          for (final e in options.entries)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, e.key),
              child: Row(
                children: [
                  Icon(
                    _appLockTimeoutSeconds == e.key
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(e.value)),
                ],
              ),
            ),
        ],
      ),
    );

    if (chosen == null) return;
    await AppLockService.instance.setTimeoutSeconds(chosen);
    if (!mounted) return;
    setState(() => _appLockTimeoutSeconds = chosen);
  }

  Future<void> _loadSecuritySettings() async {
    final biometricEnabled = await AppLockService.instance.isBiometricEnabled();

    final canCheck = await AppLockService.instance.canCheckBiometrics();
    final isSupported = await AppLockService.instance.isDeviceSupported();
    final availableBiometrics = await AppLockService.instance
        .getAvailableBiometrics();
    final biometricAvailable =
        canCheck && isSupported && availableBiometrics.isNotEmpty;

    if (Platform.isAndroid) {
      await DeviceInfoPlugin().androidInfo;
    }

    if (!mounted) return;
    setState(() {
      _biometricEnabled = biometricEnabled;
      _biometricAvailable = biometricAvailable;
    });
  }

  Future<void> _toggleBiometric(bool enable) async {
    if (enable && !_biometricAvailable) {
      if (!mounted) return;
      UIFeedback.showWarning(
        context,
        context.l10n.settingsBiometricNotSupported,
      );
      return;
    }

    await AppLockService.instance.setBiometricEnabled(enable);
    if (!mounted) return;
    setState(() => _biometricEnabled = enable);
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
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
        UIFeedback.showInfo(
          context,
          context.l10n.settingsReminderSetFor(_reminderTime.format(context)),
        );
      }
    }
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
        locale: Localizations.localeOf(currentContext),
      );

      if (currentContext.mounted) {
        if (loadingShown) rootNavigator.pop();
      }
    } catch (e) {
      if (currentContext.mounted) {
        if (loadingShown) rootNavigator.pop();
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              currentContext.l10n.settingsExportError(
                'sleep.csv',
                e.toString(),
              ),
            ),
            backgroundColor: currentContext.statusColors.danger,
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
        locale: Localizations.localeOf(currentContext),
      );

      if (currentContext.mounted) {
        if (loadingShown) rootNavigator.pop();
      }
    } catch (e) {
      if (currentContext.mounted) {
        if (loadingShown) rootNavigator.pop();
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              currentContext.l10n.settingsExportError(
                'medications.csv',
                e.toString(),
              ),
            ),
            backgroundColor: currentContext.statusColors.danger,
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
        locale: Localizations.localeOf(currentContext),
      );

      if (currentContext.mounted) {
        if (loadingShown) rootNavigator.pop();
      }
    } catch (e) {
      if (currentContext.mounted) {
        if (loadingShown) rootNavigator.pop();
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              currentContext.l10n.settingsExportError('PDF', e.toString()),
            ),
            backgroundColor: currentContext.statusColors.danger,
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
        locale: Localizations.localeOf(currentContext),
      );

      if (currentContext.mounted) {
        if (loadingShown) rootNavigator.pop();
      }
    } catch (e) {
      if (currentContext.mounted) {
        if (loadingShown) rootNavigator.pop();
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              currentContext.l10n.settingsExportError('Excel', e.toString()),
            ),
            backgroundColor: currentContext.statusColors.danger,
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
              title: Text(context.l10n.settingsWipeAllTitle),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(context.l10n.settingsWipeAllDialogBody),
                  const SizedBox(height: 8),
                  Text(context.l10n.settingsWipeAllItemMedications),
                  Text(context.l10n.settingsWipeAllItemMedicationReminders),
                  Text(context.l10n.settingsWipeAllItemIntakes),
                  Text(context.l10n.settingsWipeAllItemSleepEntries),
                  Text(context.l10n.settingsWipeAllItemAppSettings),
                  const SizedBox(height: 12),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: acknowledged,
                    title: Text(context.l10n.settingsWipeAllAcknowledge),
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
                  child: Text(context.l10n.commonCancel),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.statusColors.danger,
                    foregroundColor: context.statusColors.onDanger,
                  ),
                  onPressed: acknowledged
                      ? () => Navigator.pop(context, true)
                      : null,
                  child: Text(context.l10n.commonDelete),
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

    final medicationController = context.read<MedicationController>();
    final sleepController = context.read<SleepController>();
    final themeController = context.read<ThemeController>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await NotificationService.instance.cancelAllNotifications();
      await _repo.wipeAllData();

      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      await themeController.setThemeMode(ThemeMode.system);

      await prefs.setBool('notifications_enabled', false);
      await prefs.setInt('reminder_hour', 8);
      await prefs.setInt('reminder_minute', 0);

      if (mounted) {
        setState(() {
          _notificationsEnabled = false;
          _reminderTime = const TimeOfDay(hour: 8, minute: 0);
        });
      }

      await NotificationService.instance.cancelDailyReminder();

      if (!mounted) return;
      Navigator.pop(context);

      try {
        await medicationController.loadMedications();
      } catch (e, st) {
        if (kDebugMode) {
          debugPrint('SettingsScreen: loadMedications failed: $e');
          debugPrint('$st');
        }
      }
      try {
        await sleepController.loadEntries();
      } catch (e, st) {
        if (kDebugMode) {
          debugPrint('SettingsScreen: loadEntries failed: $e');
          debugPrint('$st');
        }
      }

      await _loadExportStats();

      if (!mounted) return;

      UIFeedback.showSuccess(context, context.l10n.settingsWipeAllSuccess);

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const WelcomeScreen()),
        (route) => false,
      );
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        UIFeedback.showError(
          context,
          context.l10n.settingsWipeAllError(e.toString()),
        );
      }
    }
  }

  Future<void> _createBackup() async {
    try {
      final password = await _askBackupPassword(
        title: context.l10n.backupPasswordTitleCreate,
        hint: context.l10n.backupPasswordHintCreate,
        confirm: true,
        allowEmpty: true,
      );

      if (!mounted) return;
      if (password == null) return;

      if (!mounted) return;
      showDialog(
        context: context,
        useRootNavigator: true,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      await BackupService.instance.createBackup(
        locale: Localizations.localeOf(context),
        password: password.trim().isEmpty ? null : password,
      );

      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop();
      UIFeedback.showError(
        context,
        context.l10n.settingsBackupCreateError(e.toString()),
      );
    }
  }

  Future<void> _restoreBackup() async {
    final locale = Localizations.localeOf(context);
    final medicationController = context.read<MedicationController>();
    final sleepController = context.read<SleepController>();

    final confirm = await showDialog<bool>(
      context: context,
      useRootNavigator: true,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.settingsBackupRestoreConfirmTitle),
        content: Text(context.l10n.settingsBackupRestoreConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.commonCancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: context.statusColors.danger,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              context.l10n.settingsBackupRestoreConfirmYes,
              style: TextStyle(color: context.statusColors.onDanger),
            ),
          ),
        ],
      ),
    );

    if (!mounted) return;
    if (confirm != true) return;

    try {

      final fileInfo = await BackupService.instance.pickBackupFile(
        locale: locale,
      );

      if (!mounted) return;
      if (fileInfo == null) return;

      String? password;
      if (fileInfo.isEncrypted) {
        password = await _askBackupPassword(
          title: context.l10n.backupPasswordTitleRestore,
          hint: context.l10n.backupPasswordHintRestore,
          confirm: false,
          allowEmpty: false,
        );

        if (!mounted) return;
        if (password == null) return;
      }

      final success = await BackupService.instance.restoreBackupFromFile(
        fileInfo,
        locale: locale,
        password: password,
      );

      if (!mounted) return;
      if (!success) {
        return;
      }

      if (!mounted) return;

      UIFeedback.showSuccess(
        context,
        context.l10n.settingsBackupRestoreCompleted,
      );

      try {
        await medicationController.loadMedications();
        await sleepController.loadEntries();
        await _loadExportStats();
      } catch (e, st) {
        if (kDebugMode) {
          debugPrint('SettingsScreen: refresh after action failed: $e');
          debugPrint('$st');
        }
      }


      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const WelcomeScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      UIFeedback.showError(
        context,
        context.l10n.settingsBackupRestoreError(e.toString()),
      );
    }
  }

  Future<String?> _askBackupPassword({
    required String title,
    required String hint,
    required bool confirm,
    required bool allowEmpty,
  }) async {
    if (!mounted) return null;
    return showDialog<String>(
      context: context,
      useRootNavigator: true,
      builder: (context) => _BackupPasswordDialog(
        title: title,
        hint: hint,
        confirm: confirm,
        allowEmpty: allowEmpty,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final l10n = context.l10n;
    final prefs = context.watch<AppPreferencesController>();

    final totalEntries = (_exportStats['totalEntries'] ?? 0) as int;
    final totalEvents = (_exportStats['totalEvents'] ?? 0) as int;
    final totalDays = (_exportStats['totalDays'] ?? 0) as int;
    final hasData = totalEntries > 0 || totalEvents > 0 || totalDays > 0;
    final hasSleepData = totalEntries > 0;
    final hasMedicationData = totalEvents > 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settingsTitle),
        backgroundColor: context.surfaces.accentSurface,
      ),
      body: ListView(
        children: [
          _buildSectionHeader(l10n.settingsSectionAppearance),
          Builder(
            builder: (context) {
              final l10n = context.l10n;
              final themeController = context.watch<ThemeController>();
              final isSystem = themeController.themeMode == ThemeMode.system;
              final effectiveIsDark =
                  Theme.of(context).brightness == Brightness.dark;

              return Column(
                children: [
                  SwitchListTile(
                    title: Text(l10n.settingsDarkModeTitle),
                    subtitle: Text(
                      isSystem
                          ? l10n.settingsDarkModeUsingSystem
                          : (effectiveIsDark
                                ? l10n.commonDark
                                : l10n.commonLight),
                    ),
                    value: effectiveIsDark,
                    onChanged: (value) async {
                      await themeController.setDarkModeEnabled(value);
                    },
                    secondary: const Icon(Icons.dark_mode),
                  ),
                ],
              );
            },
          ),
          const Divider(),

          _buildSectionHeader(l10n.settingsSectionGeneral),
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(l10n.settingsLanguageTitle),
            subtitle: Text(_localeLabel(l10n, prefs.localeOverride)),
            onTap: () => _pickLanguage(prefs),
          ),
          const Divider(),

          _buildSectionHeader(l10n.settingsSectionSecurity),
          ListTile(
            leading: const Icon(Icons.storage_rounded),
            title: Text(l10n.settingsDbEncryptionTitle),
            subtitle: Text(l10n.settingsDbEncryptionSubtitle),
            trailing: Text(
              () {
                final v = _dbEncryptedAtRest;
                if (v == true) return l10n.settingsDbEncryptionStatusOn;
                if (v == false) return l10n.settingsDbEncryptionStatusOff;
                return l10n.settingsDbEncryptionStatusUnknown;
              }(),
              style: TextStyle(
                color: _dbEncryptedAtRest == true
                    ? context.statusColors.success
                    : (_dbEncryptedAtRest == false
                          ? context.statusColors.warning
                          : Theme.of(context).hintColor),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          if (_dbEncryptedAtRest == true && !_appLockEnabled) ...[
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.lock_outline,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.settingsDbEncryptionRecommendAppLockTitle,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.settingsDbEncryptionRecommendAppLockBody,
                          style: const TextStyle(fontSize: 12),
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton(
                            onPressed: () => _toggleAppLock(true),
                            child: Text(
                              l10n.settingsDbEncryptionEnableAppLockAction,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          SwitchListTile(
            title: Text(l10n.settingsPinLockTitle),
            subtitle: Text(l10n.settingsPinLockSubtitle),
            value: _appLockEnabled,
            onChanged: (v) => _toggleAppLock(v),
            secondary: const Icon(Icons.lock),
          ),
          ListTile(
            enabled: _appLockEnabled,
            leading: const Icon(Icons.pin),
            title: Text(l10n.settingsChangePinTitle),
            subtitle: Text(l10n.settingsChangePinSubtitle),
            onTap: _appLockEnabled ? _changePin : null,
          ),
          ListTile(
            enabled: _appLockEnabled,
            leading: const Icon(Icons.timer_outlined),
            title: Text(l10n.settingsLockOnReturnTitle),
            subtitle: Text(() {
              switch (_appLockTimeoutSeconds) {
                case 0:
                  return l10n.settingsLockTimeoutImmediate;
                case 30:
                  return l10n.settingsLockTimeout30Seconds;
                case 120:
                  return l10n.settingsLockTimeout2Minutes;
                case 300:
                  return l10n.settingsLockTimeout5Minutes;
                default:
                  return l10n.settingsLockTimeoutSeconds(
                    _appLockTimeoutSeconds,
                  );
              }
            }()),
            onTap: _appLockEnabled ? _setLockTimeout : null,
          ),
          SwitchListTile(
            title: Text(l10n.settingsBiometricTitle),
            subtitle: Text(
              _biometricAvailable
                  ? l10n.settingsBiometricAvailableSubtitle
                  : l10n.settingsBiometricUnavailableSubtitle,
            ),
            value: _biometricEnabled && _appLockEnabled,
            onChanged: _appLockEnabled ? _toggleBiometric : null,
            secondary: const Icon(Icons.fingerprint),
          ),
          const Divider(),

          _buildSectionHeader(l10n.settingsSectionReminders),

          if (!_hasNotificationPermission) ...[
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                border: Border.all(color: context.statusColors.warning),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning, color: context.statusColors.warning),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.settingsNotificationsPermissionDisabledTitle,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.settingsNotificationsPermissionDisabledBody,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: Text(l10n.settingsEnableNotificationsPermissionTitle),
              subtitle: Text(
                l10n.settingsEnableNotificationsPermissionSubtitle,
              ),
              trailing: const Icon(Icons.open_in_new),
              onTap: _requestNotificationPermission,
            ),
            const Divider(),
          ],

          if (!_hasExactAlarmPermission) ...[
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                border: Border.all(color: context.statusColors.danger),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.alarm_off, color: context.statusColors.danger),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.settingsExactAlarmsPermissionDisabledTitle,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.settingsExactAlarmsPermissionDisabledBody,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.schedule),
              title: Text(l10n.settingsAllowExactAlarmsTitle),
              subtitle: Text(l10n.settingsAllowExactAlarmsSubtitle),
              trailing: const Icon(Icons.check_circle_outline),
              onTap: _requestExactAlarmPermission,
            ),
            const Divider(),
          ],

          SwitchListTile(
            title: Text(l10n.settingsDailyReminderTitle),
            subtitle: Text(l10n.settingsDailyReminderSubtitle),
            value: _notificationsEnabled,
            onChanged: (value) async {
              setState(() {
                _notificationsEnabled = value;
              });
              _saveSettings();

              // Mostrar aviso de restricciones de batería si es necesario
              if (value && mounted) {
                await checkBatteryRestrictions(context);
              }
            },
            secondary: const Icon(Icons.notifications_active),
          ),
          ListTile(
            enabled: _notificationsEnabled,
            leading: const Icon(Icons.access_time),
            title: Text(l10n.settingsReminderTimeTitle),
            subtitle: Text(_reminderTime.format(context)),
            trailing: const Icon(Icons.edit),
            onTap: _notificationsEnabled ? _selectTime : null,
          ),
          const Divider(),

          _buildSectionHeader(l10n.settingsSectionExportData),

          if (hasData) ...[
            ListTile(
              leading: const Icon(Icons.bar_chart),
              title: Text(l10n.settingsExportSleepRecordsTitle),
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
              title: Text(l10n.settingsExportMedicationEventsTitle),
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
              title: Text(l10n.settingsExportDateRangeTitle),
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
                  label: Text(l10n.settingsExportPdfButton),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                    minimumSize: const Size(double.infinity, 50),
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: hasData ? _exportXlsx : null,
                  icon: const Icon(Icons.table_view),
                  label: Text(l10n.settingsExportExcelButton),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                    minimumSize: const Size(double.infinity, 50),
                  ),
                ),
              ],
            ),
          ),

          _buildSectionHeader(l10n.settingsSectionExportAnalytics),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                ElevatedButton.icon(
                  onPressed: hasSleepData ? _exportSleepAnalyticsCsv : null,
                  icon: const Icon(Icons.file_present),
                  label: const Text('sleep.csv'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                    minimumSize: const Size(double.infinity, 50),
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: hasMedicationData
                      ? _exportMedicationsAnalyticsCsv
                      : null,
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
                l10n.settingsExportNoData,
                style: TextStyle(
                  color: context.neutralColors.grey600,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ),

          const Divider(),
          _buildSectionHeader(l10n.settingsSectionDataBackups),
          ListTile(
            leading: const Icon(Icons.save_alt),
            title: Text(l10n.settingsBackupCreateTitle),
            subtitle: Text(l10n.settingsBackupCreateSubtitle),
            onTap: _createBackup,
          ),
          ListTile(
            leading: const Icon(Icons.settings_backup_restore),
            title: Text(l10n.settingsBackupRestoreTitle),
            subtitle: Text(l10n.settingsBackupRestoreSubtitle),
            onTap: _restoreBackup,
          ),

          const Divider(),

          _buildSectionHeader(l10n.settingsSectionInfo),
          ListTile(
            leading: const Icon(Icons.info),
            title: Text(l10n.settingsAboutTitle),
            subtitle: Text(l10n.settingsAboutSubtitle),
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip),
            title: Text(l10n.settingsPrivacyInfoTitle),
            subtitle: Text(l10n.settingsPrivacyInfoSubtitle),
          ),

          const Divider(),
          _buildSectionHeader(l10n.settingsSectionDanger),
          ListTile(
            leading: Icon(
              Icons.delete_forever,
              color: context.statusColors.danger,
            ),
            title: Text(l10n.settingsWipeAllTitle),
            subtitle: Text(l10n.settingsWipeAllSubtitle),
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

class _BackupPasswordDialog extends StatefulWidget {
  final String title;
  final String hint;
  final bool confirm;
  final bool allowEmpty;

  const _BackupPasswordDialog({
    required this.title,
    required this.hint,
    required this.confirm,
    required this.allowEmpty,
  });

  @override
  State<_BackupPasswordDialog> createState() => _BackupPasswordDialogState();
}

class _BackupPasswordDialogState extends State<_BackupPasswordDialog> {
  late final TextEditingController _passwordController;
  late final TextEditingController _confirmController;
  String? _error;

  @override
  void initState() {
    super.initState();
    _passwordController = TextEditingController();
    _confirmController = TextEditingController();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _submit(AppLocalizations l10n) {
    final password = _passwordController.text.trim();
    final confirmText = _confirmController.text.trim();

    if (!widget.allowEmpty && password.isEmpty) {
      setState(() => _error = l10n.backupPasswordRequired);
      return;
    }

    if (widget.confirm && password != confirmText) {
      setState(() => _error = l10n.backupPasswordMismatch);
      return;
    }

    FocusManager.instance.primaryFocus?.unfocus();
    Navigator.of(context, rootNavigator: true).pop(_passwordController.text);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(widget.hint),
          const SizedBox(height: 12),
          TextField(
            controller: _passwordController,
            obscureText: true,
            decoration: InputDecoration(labelText: l10n.backupPasswordLabel),
            onSubmitted: (_) => _submit(l10n),
          ),
          if (widget.confirm) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _confirmController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: l10n.backupPasswordConfirmLabel,
              ),
              onSubmitted: (_) => _submit(l10n),
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: TextStyle(color: context.statusColors.danger)),
          ],
        ],
      ),
      actions: [
        CupertinoButton(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          onPressed: () {
            FocusManager.instance.primaryFocus?.unfocus();
            Navigator.of(context, rootNavigator: true).pop();
          },
          child: Text(l10n.commonCancel),
        ),
        CupertinoButton.filled(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          onPressed: () => _submit(l10n),
          child: Text(l10n.commonContinue),
        ),
      ],
    );
  }
}
