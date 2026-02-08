// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get splashSubtitle => 'Your daily health journal';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonContinue => 'Continue';

  @override
  String get commonNotNow => 'Not now';

  @override
  String get commonUnderstood => 'Understood';

  @override
  String get commonAdd => 'Add';

  @override
  String get commonEdit => 'Edit';

  @override
  String get commonSave => 'Save';

  @override
  String get commonAccept => 'Accept';

  @override
  String get commonCreate => 'Create';

  @override
  String get commonArchive => 'Archive';

  @override
  String get commonUnarchive => 'Unarchive';

  @override
  String get commonDeletePermanently => 'Delete permanently';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonAll => 'All';

  @override
  String get commonNone => 'None';

  @override
  String get commonIgnore => 'Ignore';

  @override
  String get commonActive => 'Active';

  @override
  String get commonArchived => 'Archived';

  @override
  String get commonChooseRange => 'Choose range';

  @override
  String get commonAreYouSure => 'Are you sure?';

  @override
  String commonErrorWithMessage(Object error) {
    return 'Error: $error';
  }

  @override
  String get commonNotRecorded => 'Not recorded';

  @override
  String get commonClear => 'Clear';

  @override
  String get commonDecrease => 'Decrease';

  @override
  String get commonIncrease => 'Increase';

  @override
  String get commonRefresh => 'Refresh';

  @override
  String get commonRange => 'Range';

  @override
  String get commonAverage => 'Average';

  @override
  String get commonDaysLabel => 'Days';

  @override
  String get commonEveryDay => 'Every day';

  @override
  String get commonDetailsOptional => 'Details (optional)';

  @override
  String get commonNoteSaved => 'Note saved';

  @override
  String get commonIncomplete => 'Incomplete';

  @override
  String get commonSelect => 'Select';

  @override
  String get commonNote => 'Note';

  @override
  String get commonNoteOptionalLabel => 'Note (optional)';

  @override
  String get commonTime => 'Time';

  @override
  String get commonQuantity => 'Quantity';

  @override
  String get commonNoMedication => 'No medication';

  @override
  String get commonNoDose => 'No dose';

  @override
  String get commonNoDoseWithDash => 'No dose (—)';

  @override
  String get commonSleep => 'Sleep';

  @override
  String get commonMood => 'Mood';

  @override
  String get commonHabits => 'Habits';

  @override
  String get commonMedication => 'Medication';

  @override
  String get commonMedications => 'Medications';

  @override
  String get commonReminders => 'Reminders';

  @override
  String get commonGroup => 'Group';

  @override
  String get commonExactAlarm => '⏰ Exact alarm';

  @override
  String get commonDay => 'Day';

  @override
  String get commonNoNotes => 'No notes';

  @override
  String get permissionsNotificationsDisabledTitle => 'Notifications disabled';

  @override
  String get permissionsNotificationsDisabledBody =>
      'To make reminders work, enable notifications in your system settings.\n\nThis allows alerts to be shown at the scheduled time.';

  @override
  String get permissionsExactAlarmsTitle => 'Allow exact alarms';

  @override
  String get permissionsExactAlarmsBody =>
      'This reminder needs to ring at the exact time.\n\nEnable \"Alarms & reminders\" for this app. If you don\'t, the alert may arrive late.';

  @override
  String get permissionsBatteryRecommendationTitle => 'Battery recommendation';

  @override
  String permissionsBatteryRecommendationBody(Object manufacturer) {
    return 'This device ($manufacturer) may restrict apps running in the background.\n\nIf your notifications don’t arrive, disable battery optimization for this app:\n\nSettings → Battery → Unrestricted / Don’t optimize';
  }

  @override
  String get notificationsDailyChannelName => 'Daily reminder';

  @override
  String get notificationsDailyChannelDescription =>
      'Reminder to log your sleep every day';

  @override
  String get notificationsMedicationChannelName => 'Medication reminders';

  @override
  String get notificationsMedicationChannelDescription =>
      'Alarms to take medications';

  @override
  String get notificationsDailySleepTitle => '🌙 Sleep log';

  @override
  String get notificationsDailySleepBody =>
      'How did you sleep last night? Log your sleep';

  @override
  String get notificationsTestTitle => 'Test notification';

  @override
  String get notificationsTestBody =>
      'This is a test notification. If you see it, it works!';

  @override
  String get notificationsMedicationTitle => '💊 Medication reminder';

  @override
  String get notificationsSnoozedTitle => '💊 Reminder (snoozed)';

  @override
  String get notificationsTapToLogBody => 'Tap to log';

  @override
  String get notificationsMedicationFallbackName => 'medication';

  @override
  String notificationsTakeMedicationBody(Object name) {
    return 'Take $name';
  }

  @override
  String notificationsTakeMedicationsBody(Object names) {
    return 'Take: $names';
  }

  @override
  String notificationsMedicationGroupTitle(Object groupName) {
    return '💊 $groupName';
  }

  @override
  String get notificationsActionChoose => '📝 Choose';

  @override
  String get notificationsActionSnooze5min => '⏰ Snooze 5 min';

  @override
  String get notificationsActionCompleteTaken => '✅ Done';

  @override
  String get notificationsActionCompleteAllTaken => '✅ All done';

  @override
  String get notificationsAutoLogged => 'Logged automatically';

  @override
  String get notificationsAutoLoggedWithApplication =>
      'Logged automatically (application)';

  @override
  String get notificationsErrorReminderMissingId =>
      'The reminder must have a database ID';

  @override
  String get notificationsErrorGroupReminderMissingId =>
      'The group reminder must have a DB ID';

  @override
  String notificationsErrorProcessing(Object error) {
    return 'Error processing notification: $error';
  }

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsSectionAppearance => 'Appearance';

  @override
  String get settingsSectionSecurity => 'Security';

  @override
  String get settingsSectionReminders => 'Reminders';

  @override
  String get settingsSectionExportData => 'Export Data';

  @override
  String get settingsSectionExportAnalytics => 'Export for Analytics';

  @override
  String get settingsSectionDataBackups => 'Data & Backups';

  @override
  String get settingsSectionInfo => 'Information';

  @override
  String get settingsSectionDanger => 'Danger Zone';

  @override
  String get settingsDarkModeTitle => 'Dark Mode';

  @override
  String get settingsDarkModeUsingSystem => 'Using system theme';

  @override
  String get commonDark => 'Dark';

  @override
  String get commonLight => 'Light';

  @override
  String get settingsPinLockTitle => 'PIN Lock';

  @override
  String get settingsPinLockSubtitle => 'Require PIN to enter the app';

  @override
  String get settingsChangePinTitle => 'Change PIN';

  @override
  String get settingsChangePinSubtitle => '4-digit PIN';

  @override
  String get settingsPinUpdated => 'PIN updated';

  @override
  String get settingsLockOnReturnTitle => 'Lock on return';

  @override
  String get settingsLockOnReturnDialogTitle =>
      'Lock when returning from background';

  @override
  String get settingsLockTimeoutImmediateBack => 'Immediate on return';

  @override
  String get settingsLockTimeout30Seconds => '30 seconds';

  @override
  String get settingsLockTimeout2Minutes => '2 minutes';

  @override
  String get settingsLockTimeout5Minutes => '5 minutes';

  @override
  String get settingsLockTimeoutImmediate => 'Immediate';

  @override
  String settingsLockTimeoutSeconds(Object seconds) {
    return '${seconds}s';
  }

  @override
  String get settingsBiometricTitle => 'Biometric authentication';

  @override
  String get settingsBiometricAvailableSubtitle => 'Use fingerprint or Face ID';

  @override
  String get settingsBiometricUnavailableSubtitle =>
      'Not available on this device';

  @override
  String get settingsBiometricNotSupported =>
      'Your device doesn’t support biometric authentication';

  @override
  String get settingsDbEncryptionTitle => 'Database encryption';

  @override
  String get settingsDbEncryptionSubtitle =>
      'Protects your local data if the phone is stolen';

  @override
  String get settingsDbEncryptionStatusOn => 'On';

  @override
  String get settingsDbEncryptionStatusOff => 'Off';

  @override
  String get settingsDbEncryptionStatusUnknown => 'Unknown';

  @override
  String get settingsDbEncryptionRecommendAppLockTitle =>
      'Recommended: enable App Lock';

  @override
  String get settingsDbEncryptionRecommendAppLockBody =>
      'Encryption protects the DB file, but anyone with your unlocked phone could open the app. App Lock adds a second barrier.';

  @override
  String get settingsDbEncryptionEnableAppLockAction => 'Enable';

  @override
  String get settingsDisableAppLockWarningTitle => 'Disable App Lock?';

  @override
  String get settingsDisableAppLockWarningBody =>
      'Your database is encrypted, but disabling App Lock may expose your data to anyone who has your unlocked phone.';

  @override
  String get settingsDisableAppLockWarningDisable => 'Disable';

  @override
  String get settingsNotificationsPermissionTitle => 'Notifications permission';

  @override
  String get settingsNotificationsPermissionBody =>
      'Notifications are disabled. To enable them, go to the app settings.';

  @override
  String get settingsOpenSettings => 'Open settings';

  @override
  String get settingsNotificationsPermissionDisabledTitle =>
      'Notifications permission disabled';

  @override
  String get settingsNotificationsPermissionDisabledBody =>
      'Reminders won’t work until you enable the permission.';

  @override
  String get settingsEnableNotificationsPermissionTitle =>
      'Enable notifications permission';

  @override
  String get settingsEnableNotificationsPermissionSubtitle =>
      'Open system settings';

  @override
  String get settingsExactAlarmsPermissionDisabledTitle =>
      'Exact alarms permission disabled';

  @override
  String get settingsExactAlarmsPermissionDisabledBody =>
      'The sleep reminder needs this permission to ring on time on Android 12+.';

  @override
  String get settingsAllowExactAlarmsTitle => 'Allow exact alarms';

  @override
  String get settingsAllowExactAlarmsSubtitle =>
      'Required for precise reminders';

  @override
  String get settingsDailyReminderTitle => 'Daily reminder';

  @override
  String get settingsDailyReminderSubtitle => 'Notification to log your sleep';

  @override
  String get settingsSectionGeneral => 'General';

  @override
  String get settingsLanguageTitle => 'Language';

  @override
  String get settingsLanguageSystem => 'Automatic (system)';

  @override
  String get settingsLanguageSpanish => 'Español';

  @override
  String get settingsLanguageEnglish => 'English';

  @override
  String get settingsReminderTimeTitle => 'Reminder time';

  @override
  String settingsReminderSetFor(Object time) {
    return 'Reminder set for $time';
  }

  @override
  String get settingsExportDialogTitle => 'Export data';

  @override
  String get settingsExportDialogBody =>
      'Do you want to export all data or choose a date range?';

  @override
  String get settingsExportSelectRangeHelpText => 'Select the range to export';

  @override
  String get settingsExportPdfButton => 'Export to PDF';

  @override
  String get settingsExportExcelButton => 'Export to Excel (.xlsx)';

  @override
  String get settingsExportNoData => 'No data to export. Log a few days first.';

  @override
  String get settingsExportSleepRecordsTitle => 'Sleep records';

  @override
  String get settingsExportMedicationEventsTitle => 'Logged intakes';

  @override
  String get settingsExportDateRangeTitle => 'Date range';

  @override
  String settingsExportError(Object type, Object error) {
    return 'Error exporting $type: $error';
  }

  @override
  String get settingsBackupCreateTitle => 'Create backup';

  @override
  String get settingsBackupCreateSubtitle => 'Export a file for reinstall';

  @override
  String get settingsBackupRestoreTitle => 'Restore backup';

  @override
  String get settingsBackupRestoreSubtitle => 'Import a previous file';

  @override
  String settingsBackupCreateError(Object error) {
    return 'Error creating backup: $error';
  }

  @override
  String get settingsBackupRestoreConfirmTitle => 'Restore backup';

  @override
  String get settingsBackupRestoreConfirmBody =>
      '⚠️ WARNING: This will delete all current data and replace it with the backup file.\n\nDo you want to continue?';

  @override
  String get settingsBackupRestoreConfirmYes => 'Yes, restore';

  @override
  String get backupPasswordTitleCreate => 'Encrypt backup (optional)';

  @override
  String get backupPasswordHintCreate =>
      'Leave empty to export without encryption.';

  @override
  String get backupPasswordTitleRestore => 'Backup password';

  @override
  String get backupPasswordHintRestore =>
      'Enter the password used when the backup was created.';

  @override
  String get backupPasswordLabel => 'Password';

  @override
  String get backupPasswordConfirmLabel => 'Confirm password';

  @override
  String get backupPasswordMismatch => 'Passwords do not match.';

  @override
  String get backupPasswordRequired => 'Password required.';

  @override
  String get backupPasswordInvalid => 'Incorrect password.';

  @override
  String get settingsBackupRestoreCompleted =>
      'Restore completed. Restarting...';

  @override
  String settingsBackupRestoreError(Object error) {
    return 'Error restoring: $error';
  }

  @override
  String get settingsAboutTitle => 'About';

  @override
  String get settingsAboutSubtitle => 'Mediary v2.0.0';

  @override
  String get settingsPrivacyInfoTitle => 'Privacy';

  @override
  String get settingsPrivacyInfoSubtitle =>
      'All your data is stored locally on your device';

  @override
  String get settingsWipeAllTitle => 'Factory reset';

  @override
  String get settingsWipeAllSubtitle => 'Delete all data from this device';

  @override
  String get settingsWipeAllDialogBody =>
      'This will delete ALL data stored on this device:';

  @override
  String get settingsWipeAllItemMedications =>
      '• Medications (active and archived)';

  @override
  String get settingsWipeAllItemMedicationReminders => '• Medication reminders';

  @override
  String get settingsWipeAllItemIntakes => '• Logged intakes';

  @override
  String get settingsWipeAllItemSleepEntries => '• Sleep records';

  @override
  String get settingsWipeAllItemAppSettings => '• App settings and state';

  @override
  String get settingsWipeAllAcknowledge =>
      'I understand this action is irreversible';

  @override
  String get settingsWipeAllSuccess => 'Data deleted successfully';

  @override
  String settingsWipeAllError(Object error) {
    return 'Error deleting data: $error';
  }

  @override
  String get medicationsTitle => 'Medications';

  @override
  String get medicationsGroupButton => 'Group';

  @override
  String get medicationsEmptyTitle => 'No medications';

  @override
  String get medicationsEmptySubtitle => 'Add one using the + button';

  @override
  String medicationsArchivedSectionTitle(Object count) {
    return 'Archived ($count)';
  }

  @override
  String get medicationsUnarchiveButton => 'Restore';

  @override
  String get medicationsAddButton => 'Add';

  @override
  String get medicationsDialogAddTitle => 'Add medication';

  @override
  String get medicationsDialogEditTitle => 'Edit medication';

  @override
  String get medicationsGenericNameLabel => 'Generic name *';

  @override
  String get medicationsGenericNameHint => 'e.g. Ibuprofen';

  @override
  String get medicationsGenericNameRequired => 'Generic name is required';

  @override
  String get medicationsBrandNameLabel => 'Brand name (optional)';

  @override
  String get medicationsBrandNameHint => 'e.g. Advil';

  @override
  String get medicationsBaseUnitLabel => 'Base unit *';

  @override
  String get medicationsBaseUnitHint => 'e.g. 1 mg, 2 mg, 10 ml';

  @override
  String get medicationsBaseUnitRequired => 'Base unit is required';

  @override
  String get medicationsTypeLabel => 'Type *';

  @override
  String get medicationsDefaultDoseOptional => 'Default dose (optional)';

  @override
  String get medicationsDefaultDoseQtyDrops => 'Default amount (drops)';

  @override
  String get medicationsDefaultDoseQtyCapsules => 'Default amount (capsules)';

  @override
  String get medicationsDefaultDoseQtyLabel => 'Default amount';

  @override
  String get medicationsDefaultDosePickerTitle => 'Default dose';

  @override
  String get medicationsDefaultDoseCustom => 'Custom…';

  @override
  String get medicationsDefaultDoseHelper =>
      'This amount will be prefilled when logging intakes';

  @override
  String get medicationsSavedAdded => 'Medication added';

  @override
  String get medicationsSavedUpdated => 'Medication updated';

  @override
  String get medicationsDuplicateWarning =>
      'A similar medication already exists. You can edit it from the list.';

  @override
  String medicationsDbError(Object error) {
    return 'Database error: $error';
  }

  @override
  String medicationsError(Object error) {
    return 'Error: $error';
  }

  @override
  String get medicationsManageTitle => 'Manage medication';

  @override
  String get medicationsManageBody =>
      'Choose what you want to do:\n\n• Archive: keeps historical records and pauses reminders.\n• Delete permanently: deletes the medication and all associated records.';

  @override
  String get medicationsArchivedSnack => 'Medication archived';

  @override
  String medicationsArchiveError(Object error) {
    return 'Error archiving: $error';
  }

  @override
  String get medicationsHardDeleteTitle => 'Delete permanently';

  @override
  String medicationsHardDeleteBody(Object name) {
    return 'This action CANNOT be undone.\n\nThe following will be deleted:\n• $name\n• all associated history\n• reminders\n\nDo you want to continue?';
  }

  @override
  String get medicationsDeletedSnack => 'Medication deleted permanently';

  @override
  String medicationsDeleteError(Object error) {
    return 'Error deleting: $error';
  }

  @override
  String get medicationsUnarchiveTitle => 'Restore medication';

  @override
  String get medicationsUnarchiveBody =>
      'Restore this medication?\n\nIt will appear again in the list and selectors.\nAny configured reminders will be rescheduled.';

  @override
  String get medicationsUnarchivedSnack => 'Medication restored';

  @override
  String get medicationsRemindersTitle => 'Reminders';

  @override
  String get medicationsNoReminders => 'No reminders';

  @override
  String get medicationsTooltipViewReminders => 'View reminders';

  @override
  String get medicationsTooltipAdjustDose => 'Adjust dose';

  @override
  String get medicationsTooltipArchiveDelete => 'Archive / Delete';

  @override
  String get medicationsDeleteReminderTitle => 'Delete reminder';

  @override
  String get medicationsDeleteReminderBody =>
      'Are you sure you want to delete this reminder?';

  @override
  String get medicationsReminderDeletedSnack => '🗑️ Reminder deleted';

  @override
  String get fractionPickerTitle => 'Amount';

  @override
  String get fractionPickerWholeLabel => 'Whole';

  @override
  String get fractionPickerFractionLabel => 'Fraction';

  @override
  String get fractionPickerNoFractionSelected => 'No fraction';

  @override
  String get fractionPickerPreviewLabel => 'Preview:';

  @override
  String medicationDetailLoadError(Object error) {
    return '❌ Error loading reminders: $error';
  }

  @override
  String get medicationDetailDeleteReminderTitle => 'Delete reminder';

  @override
  String medicationDetailDeleteReminderBody(Object time) {
    return 'Delete the $time reminder?';
  }

  @override
  String get medicationDetailReminderDeleted => '✅ Reminder deleted';

  @override
  String medicationDetailDeleteError(Object error) {
    return '❌ Error: $error';
  }

  @override
  String medicationDetailDaysLabel(Object days) {
    return 'Days: $days';
  }

  @override
  String get medicationDetailSchedulesTitle => 'Schedule times';

  @override
  String medicationDetailSchedulesCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count times',
      one: '1 time',
    );
    return '$_temp0';
  }

  @override
  String get medicationDetailNoRemindersTitle => 'No reminders set';

  @override
  String get medicationDetailNoRemindersSubtitle =>
      'Press the + button to add one';

  @override
  String get medicationDetailAddSchedule => 'Add time';

  @override
  String get medicationGroupsTitle => 'Medication groups';

  @override
  String get medicationGroupsEmpty => 'You don’t have any groups yet';

  @override
  String get medicationGroupsNewGroupTitle => 'New group';

  @override
  String get medicationGroupsNameLabel => 'Name';

  @override
  String get medicationGroupsNameHint => 'e.g. Night';

  @override
  String get medicationGroupDetailGroupNotFound => 'Group not found';

  @override
  String get medicationGroupDetailMembersDialogTitle => 'Group medications';

  @override
  String get medicationGroupDetailNewReminderTitle => '➕ New reminder';

  @override
  String get medicationGroupDetailEditReminderTitle => '✏️ Edit reminder';

  @override
  String medicationGroupDetailTimeLabel(Object time) {
    return 'Time: $time';
  }

  @override
  String get medicationGroupDetailExactAlarmTitle =>
      'This group requires precision (like an alarm clock)';

  @override
  String get medicationGroupDetailExactAlarmSubtitle =>
      'It rings even if the phone is idle. Special permissions are required.';

  @override
  String get medicationGroupDetailDndWarning =>
      '⚠️ If you use \"Do Not Disturb\", this reminder may not ring. To make it work like an alarm clock, make sure alarms are allowed for this app in Sound settings.';

  @override
  String get medicationGroupDetailDeleteReminderTitle => 'Delete reminder';

  @override
  String get medicationGroupDetailDeleteGroupTitle => 'Delete group';

  @override
  String get medicationGroupDetailDeleteGroupBody =>
      'Its reminders will also be deleted.';

  @override
  String get medicationGroupDetailDeleteGroupTooltip => 'Delete group';

  @override
  String get medicationGroupDetailNoMembers => 'No medications assigned';

  @override
  String get medicationGroupDetailNoReminders => 'No reminders';

  @override
  String get addReminderSelectMedicationError => '❌ Select a medication';

  @override
  String get addReminderSelectAtLeastOneDayError => '❌ Select at least one day';

  @override
  String addReminderCreated(Object icon) {
    return '$icon Reminder created';
  }

  @override
  String addReminderUpdated(Object icon) {
    return '$icon Reminder updated';
  }

  @override
  String get addReminderTitleNew => '➕ New reminder';

  @override
  String get addReminderTitleEdit => '✏️ Edit reminder';

  @override
  String get addReminderMedicationLabel => 'Medication';

  @override
  String get addReminderTimeTitle => 'Reminder time';

  @override
  String get addReminderDaysOfWeekTitle => 'Days of the week';

  @override
  String get addReminderNoteHint => 'e.g. After eating, with water...';

  @override
  String get addReminderExactAlarmTitle =>
      'This medication requires precision (like an alarm clock)';

  @override
  String get addReminderExactAlarmSubtitle =>
      'It rings even if the phone is idle. Special permissions are required.';

  @override
  String get addReminderDndWarning =>
      '⚠️ If you use \"Do Not Disturb\", this reminder may not ring. To make it work like an alarm clock, make sure alarms are allowed for this app in Sound settings.';

  @override
  String get addReminderSaveButton => 'Save reminder';

  @override
  String get addReminderUpdateButton => 'Update reminder';

  @override
  String get quickIntakeSelectAtLeastOneMedication =>
      'Select at least one medication';

  @override
  String get quickIntakeAutoLoggedWithoutDose =>
      'Logged automatically (no dose)';

  @override
  String quickIntakeMissingDefaultDose(Object names) {
    return 'No default dose: $names';
  }

  @override
  String get quickIntakeSaved => '✅ Intake logged';

  @override
  String get quickIntakeMedicationNotFound => 'Medication not found';

  @override
  String quickIntakeSnoozed(Object minutes) {
    return '⏰ Reminder snoozed $minutes min';
  }

  @override
  String quickIntakeAppBarGroup(Object groupName) {
    return '💊 $groupName';
  }

  @override
  String get quickIntakeDefaultGroupName => 'Medication group';

  @override
  String get quickIntakeAppBarSingle => '💊 Reminder';

  @override
  String get quickIntakeNoActiveMeds =>
      'No active medications for this reminder';

  @override
  String quickIntakeUnitLabel(Object unit) {
    return 'Unit: $unit';
  }

  @override
  String get quickIntakeWhatToDo => 'What would you like to do?';

  @override
  String get quickIntakeIHaveTaken => 'I’ve taken it';

  @override
  String get quickIntakeSnooze10m => 'Snooze 10 minutes';

  @override
  String get quickIntakeSnooze1h => 'Snooze 1 hour';

  @override
  String get quickIntakeChooseTaken => 'Choose what you took';

  @override
  String quickIntakeSelectedCount(Object selected, Object total) {
    return '$selected/$total selected';
  }

  @override
  String get quickIntakeSaveSelectedClose => 'Save selected (close)';

  @override
  String quickIntakeRemainingHint(Object remaining) {
    return 'The remaining $remaining won’t be notified again automatically. If you want another alert later, use “Snooze remaining”.';
  }

  @override
  String get quickIntakeSnoozeRemaining10m => 'Snooze remaining 10m';

  @override
  String get quickIntakeSnoozeRemaining1h => 'Snooze remaining 1h';

  @override
  String get dailyEntryTitle => 'Log your day';

  @override
  String get dailyEntryTabDayOptional => 'Day (optional)';

  @override
  String get dailyEntryTabSleepOptional => 'Sleep (optional)';

  @override
  String get dailyEntryTabMedication => 'Medication';

  @override
  String get dailyEntryMedicationAdded => 'Medication added';

  @override
  String get dailyEntrySaveError => 'Error saving';

  @override
  String dailyEntrySaveErrorWithMessage(Object error) {
    return 'Error saving: $error';
  }

  @override
  String get dailyEntrySaveSuccess => 'Entry saved successfully';

  @override
  String dayTabHeader(Object date) {
    return 'Day $date';
  }

  @override
  String get dayTabOptionalHint =>
      'Optional. If you prefer, you can leave everything empty.';

  @override
  String get dayTabMoodTitle => 'Mood';

  @override
  String get dayTabMoodQuestion => 'How are you feeling today?';

  @override
  String get dayTabMoodVeryBad => 'Very bad';

  @override
  String get dayTabMoodBad => 'Bad';

  @override
  String get dayTabMoodOk => 'Okay';

  @override
  String get dayTabMoodGood => 'Good';

  @override
  String get dayTabMoodVeryGood => 'Very good';

  @override
  String get dayTabDayNotesTitle => 'Day notes';

  @override
  String get dayTabDayNotesHint => 'Something to remember about the day...';

  @override
  String get dayTabHabitsTitle => 'Habits';

  @override
  String get dayTabWaterTitle => 'Water';

  @override
  String dayTabWaterCount(Object count) {
    return 'Glasses: $count';
  }

  @override
  String dayTabWaterCountLabel(Object count) {
    return 'Water: $count';
  }

  @override
  String get dayTabBlocksWalkedTitle => 'Blocks walked';

  @override
  String get dayTabBlocksWalkedHint => 'e.g. 12';

  @override
  String get dayTabBlocksWalkedHelper => 'Approx. 0–1000';

  @override
  String sleepTabNightOf(Object date) {
    return 'Night of $date';
  }

  @override
  String sleepTabNightRange(Object startDay, Object endDay) {
    return '($startDay→$endDay)';
  }

  @override
  String get sleepTabHowDidYouSleep => 'How did you sleep?';

  @override
  String get sleepTabHowLongDidYouSleep => 'How long did you sleep?';

  @override
  String get sleepTabHours => 'Hours';

  @override
  String get sleepTabMinutes => 'Minutes';

  @override
  String get sleepTabHowWasSleep => 'How was your sleep?';

  @override
  String get sleepTabContinuityStraight => 'Uninterrupted';

  @override
  String get sleepTabContinuityBroken => 'Interrupted';

  @override
  String get sleepTabOptionalHint => 'Optional: if you prefer, leave it empty.';

  @override
  String get sleepTabGeneralNotesOptional => 'General notes (optional)';

  @override
  String get sleepTabNotesHint => 'Something to remember tomorrow...';

  @override
  String get medicationTabExpandAll => 'Expand all';

  @override
  String get medicationTabCollapseAll => 'Collapse all';

  @override
  String get medicationTabEmptyTitle => 'No medications logged';

  @override
  String get medicationTabEmptySubtitle => 'Press the + button to add one';

  @override
  String get medicationTabAddMedication => 'Add medication';

  @override
  String get medicationTabDoseApplication => 'Application';

  @override
  String medicationTabDropsDose(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count drops',
      one: '1 drop',
    );
    return '$_temp0';
  }

  @override
  String medicationTabCapsulesDose(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count capsules',
      one: '1 capsule',
    );
    return '$_temp0';
  }

  @override
  String get medicationTabCustomQuantityTitle => 'Custom amount';

  @override
  String get medicationTabMedicationLabel => 'Medication';

  @override
  String get medicationTabAddAnotherMedication => '+ Add another';

  @override
  String get medicationTabDoseDropsLabel => 'Number of drops';

  @override
  String get medicationTabDoseCapsulesLabel => 'Number of capsules';

  @override
  String get medicationTabNoteOptionalLabel => 'Note (optional)';

  @override
  String get medicationTabNoteHint => 'Effects, context...';

  @override
  String get homeTitle => 'Journal';

  @override
  String get homeTooltipSummary => 'Summary';

  @override
  String get homeTooltipMedications => 'Medications';

  @override
  String get homeTooltipSettings => 'Settings';

  @override
  String get homeCalendarViewTooltip => 'View';

  @override
  String get homeCalendarFilterTooltip => 'Filter';

  @override
  String get homeCalendarMonth => 'Month';

  @override
  String get homeCalendarTwoWeeks => '2 weeks';

  @override
  String get homeCalendarWeek => 'Week';

  @override
  String get homeRemindersTodayTitle => 'Today\'s reminders';

  @override
  String get homeRemindersSnoozedHeader => 'Snoozed';

  @override
  String get summaryTitle => 'Summary';

  @override
  String get summaryLoadError => 'Could not load the summary.';

  @override
  String summaryLastNDays(Object days) {
    return 'Last $days days';
  }

  @override
  String get summaryTabStats => 'Stats';

  @override
  String get summaryTabPatterns => 'Patterns';

  @override
  String get summaryViewDayByDay => 'View day-by-day details →';

  @override
  String get summaryPatternsRangeHint =>
      'Relationships available over 30 and 90 days.';

  @override
  String get summarySleepAverageQuality => 'Average sleep quality';

  @override
  String get summarySleepNoRecords => 'No sleep records in this period';

  @override
  String get summaryMoodNoRecords => 'No mood records in this period';

  @override
  String get summaryMoodMostFrequentPrefix => 'The most frequent mood was';

  @override
  String summaryMedicationDaysWith(Object withCount, Object total) {
    return 'Days with medication logged: $withCount out of $total';
  }

  @override
  String summaryDaysWithoutRecord(Object days) {
    return 'Days without a record: $days';
  }

  @override
  String get summaryPatternsStreaks => 'Streaks';

  @override
  String get summaryPatternsGoals => 'Goals';

  @override
  String get summaryPatternsInsights => 'Insights';

  @override
  String summaryStreakCurrent(Object value) {
    return 'Current: $value';
  }

  @override
  String summaryStreakBest(Object value) {
    return 'Best: $value';
  }

  @override
  String summaryGoalDaysProgress(Object achieved, Object total) {
    return '$achieved/$total days';
  }

  @override
  String get summaryInsightsDisclaimer =>
      'These are comparisons within the selected period (they do not imply causation).';

  @override
  String get summaryInsightStrengthNotEnoughData => 'Not enough data';

  @override
  String get summaryInsightStrengthWeak => 'Weak';

  @override
  String get summaryInsightStrengthPreliminary => 'Preliminary';

  @override
  String get summaryInsightStrengthModerate => 'Moderate';

  @override
  String get summaryInsightStrengthStrong => 'Strong';

  @override
  String summaryDaysWithRecordLabel(Object rangeDays) {
    return 'Days with a record (of $rangeDays):';
  }

  @override
  String summaryAvgShortWithValue(Object value) {
    return 'Avg: $value';
  }

  @override
  String summaryBlocksWalkedDays(Object days) {
    return 'Blocks walked: $days';
  }

  @override
  String summaryWaterDays(Object days) {
    return '💧 Water: $days';
  }

  @override
  String get summarySleepTrendHigherAtEnd =>
      'Sleep quality was higher toward the end of the period';

  @override
  String get summarySleepTrendHigherAtStart =>
      'Sleep quality was higher toward the beginning of the period';

  @override
  String get summaryPatternWaterGoal => '💧 Water ≥6';

  @override
  String get summaryPatternSleepGoal => '🛏️ Sleep ≥4';

  @override
  String get summaryPatternMoodGoal => '😊 Mood ≥4';

  @override
  String get summaryMetricSleep => 'sleep';

  @override
  String get summaryMetricMood => 'mood';

  @override
  String get summaryMetricWater => 'water';

  @override
  String get summaryInsightTitleSleepMood => 'Sleep ↔ Mood';

  @override
  String get summaryInsightTitleWaterMood => 'Water ↔ Mood';

  @override
  String get summaryInsightDirHigher => 'higher';

  @override
  String get summaryInsightDirLower => 'lower';

  @override
  String summaryInsightBaseMinPairs(Object pairCount, Object minPairs) {
    return 'Base: $pairCount days (minimum: $minPairs)';
  }

  @override
  String get summaryInsightMessageMinPairs =>
      'Preliminary: there are too few days with both data points logged to compare.';

  @override
  String summaryInsightBaseNoGroup(Object pairCount) {
    return 'Base: $pairCount days';
  }

  @override
  String get summaryInsightMessageNoGroup =>
      'Preliminary: there isn’t enough data to group.';

  @override
  String summaryInsightGroupHintShort(Object xLabel) {
    return 'days with more $xLabel vs less $xLabel';
  }

  @override
  String summaryInsightGroupHintLong(Object xLabel) {
    return 'best vs worst ~30% (by $xLabel)';
  }

  @override
  String summaryInsightBaseTopBottom(
    Object pairCount,
    Object groupHint,
    Object g,
  ) {
    return 'Base: $pairCount days · $groupHint · groups: $g and $g';
  }

  @override
  String summaryInsightMessageTopBottom(
    Object xLabel,
    Object yLabel,
    Object dirWord,
    Object delta,
  ) {
    return 'On your days with higher $xLabel, $yLabel tends to be $dirWord (Δ $delta).';
  }

  @override
  String get selectedDayDeleteTooltip => 'Delete day entry';

  @override
  String get selectedDayDeleteDialogTitle => 'Delete entry';

  @override
  String get selectedDayDeleteDialogBody =>
      'Delete the FULL entry for this day?\n\nThis will delete: sleep, medication (intakes), mood, and notes.';

  @override
  String selectedDayChipSleepWithQuality(Object quality) {
    return 'Sleep: $quality/5';
  }

  @override
  String get selectedDayChipSleepEmpty => 'Sleep: —';

  @override
  String selectedDayChipMedicationWithCount(Object count) {
    return 'Medication: $count';
  }

  @override
  String get selectedDayChipMedicationEmpty => 'Medication: —';

  @override
  String get selectedDayNoMoodRecorded => 'No mood recorded';

  @override
  String get selectedDayNoWater => 'No water';

  @override
  String selectedDayBlocksWalkedValue(Object value) {
    return 'Blocks walked: $value';
  }

  @override
  String get selectedDayNoBlocksWalked => 'No blocks walked recorded';

  @override
  String get selectedDayNoSleepRecord => 'No sleep record';

  @override
  String get selectedDayMedicationsTitle => 'Medications';

  @override
  String get selectedDayNoMedications => 'No medications logged';

  @override
  String selectedDayMedicationFallbackName(Object id) {
    return 'Medication $id';
  }

  @override
  String get selectedDayMedicationQtyLabelRecord => 'Record';

  @override
  String get commonBack => 'Back';

  @override
  String get commonNext => 'Next';

  @override
  String get commonSkip => 'Skip';

  @override
  String get commonSaving => 'Saving…';

  @override
  String get welcomeStart => 'Get started';

  @override
  String get welcomePage1Title => 'Your daily journal, effortlessly';

  @override
  String get welcomePage1Body =>
      'Log medication, sleep, and day notes in seconds.';

  @override
  String get welcomePage2Title => 'Reminders, if you need them';

  @override
  String get welcomePage2Body =>
      'Schedule alarms for your doses, or just use it to log.';

  @override
  String get welcomePage3Title => 'Your history in a calendar';

  @override
  String get welcomePage3Body =>
      'You’ll be able to see logged days and spot patterns over time.';

  @override
  String get welcomePage4Title => 'Everything stays on your phone';

  @override
  String get welcomePage4Body =>
      'Stored locally. No accounts, no servers, no internet.';

  @override
  String get appLockBiometricReason => 'Authentication required';

  @override
  String get setPinTitleCreate => 'Create PIN';

  @override
  String get setPinTitleChange => 'Change PIN';

  @override
  String get setPinEnterCurrentPinError => 'Enter your current PIN (4 digits)';

  @override
  String get setPinInvalidPinError => 'Your PIN must be 4 digits';

  @override
  String get setPinPinsDoNotMatch => 'PINs do not match';

  @override
  String setPinTooManyAttemptsSeconds(Object seconds) {
    return 'Too many attempts. Wait ${seconds}s';
  }

  @override
  String get setPinCurrentPinIncorrect => 'Current PIN is incorrect';

  @override
  String get setPinCurrentPinLabel => 'Current PIN';

  @override
  String get setPinNewPinLabel => 'New PIN (4 digits)';

  @override
  String get setPinConfirmNewPinLabel => 'Confirm new PIN';

  @override
  String get lockScreenEnterPinTitle => 'Enter your PIN';

  @override
  String get lockScreenPinHint => '4 digits';

  @override
  String lockScreenLockedOut(Object time) {
    return 'Locked for security. Try again at $time';
  }

  @override
  String lockScreenTooManyAttempts(Object time) {
    return 'Too many attempts. Wait $time';
  }

  @override
  String lockScreenPinIncorrectAttemptsLeft(Object left) {
    return 'Incorrect PIN. Attempts left: $left';
  }

  @override
  String get lockScreenUseBiometrics => 'Use fingerprint';

  @override
  String get dailyEntryValidationFutureDay => 'You can’t log a future day.';

  @override
  String dailyEntryValidationSelectMedication(Object index) {
    return 'Please select the medication in event $index';
  }

  @override
  String dailyEntryValidationGelNoQuantity(Object index) {
    return 'Gel entries don’t record a quantity. Leave “No dose” for event $index.';
  }

  @override
  String dailyEntryValidationInvalidQuantityInteger(Object index) {
    return 'The quantity in event $index is invalid. Choose “No dose” or a valid integer.';
  }

  @override
  String dailyEntryValidationInvalidQuantityFraction(Object index) {
    return 'The quantity in event $index is invalid. Choose “No dose” or a valid fraction.';
  }

  @override
  String get dailyEntryValidationSleepNeedsQuality =>
      'To save sleep, choose “How did you sleep” (1–5) or clear the details.';

  @override
  String get medicationTypeTablet => 'tablet';

  @override
  String get medicationTypeDrops => 'drops';

  @override
  String get medicationTypeCapsule => 'capsule';

  @override
  String get medicationTypeGel => 'gel/cream';

  @override
  String backupShareSubject(Object date) {
    return 'Mediary backup ($date)';
  }

  @override
  String get backupShareText => 'Mediary data backup.';

  @override
  String get backupInvalidFileFormat => 'Invalid file format';

  @override
  String get backupNewerThanApp =>
      'This backup was created with a newer app version. Please update the app.';

  @override
  String get exportNoData => 'NO DATA';

  @override
  String get exportSectionSleep => 'Sleep log';

  @override
  String get exportSectionMedications => 'Medication log';

  @override
  String get exportSectionDay => 'Day log';

  @override
  String get exportSleepHeaderNight => 'Night';

  @override
  String get exportSleepHeaderQuality => 'Quality';

  @override
  String get exportSleepHeaderDescription => 'Description';

  @override
  String get exportSleepHeaderHours => 'Hours';

  @override
  String get exportSleepHeaderHow => 'How';

  @override
  String get exportSleepHeaderComments => 'Comments';

  @override
  String get exportSleepContinuityContinuous => 'Continuous';

  @override
  String get exportSleepContinuityBroken => 'Interrupted';

  @override
  String get exportSleepQualityVeryBad => 'Very bad';

  @override
  String get exportSleepQualityBad => 'Bad';

  @override
  String get exportSleepQualityOk => 'Okay';

  @override
  String get exportSleepQualityGood => 'Good';

  @override
  String get exportSleepQualityVeryGood => 'Very good';

  @override
  String get exportMedicationHeaderDay => 'Day';

  @override
  String get exportMedicationHeaderTime => 'Time';

  @override
  String get exportMedicationHeaderMedication => 'Medication';

  @override
  String get exportMedicationHeaderUnit => 'Unit';

  @override
  String get exportMedicationHeaderQuantity => 'Quantity';

  @override
  String get exportMedicationHeaderNote => 'Note';

  @override
  String get exportMedicationHeaderNotes => 'Notes';

  @override
  String get exportMedicationApplication => 'Application';

  @override
  String exportMedicationFallback(Object id) {
    return 'Medication $id';
  }

  @override
  String get exportShareCsv => 'CSV export';

  @override
  String get exportShareSleepAnalyticsCsv => 'Analytics export: sleep.csv';

  @override
  String get exportShareMedicationsAnalyticsCsv =>
      'Analytics export: medications.csv';

  @override
  String get exportShareExcel => 'Excel export (.xlsx)';

  @override
  String get exportSharePdf => 'PDF export';

  @override
  String get exportFileBaseDiary => 'journal_medications';

  @override
  String get exportFileBaseSleepAnalytics => 'sleep';

  @override
  String get exportFileBaseMedicationsAnalytics => 'medications';

  @override
  String get exportSheetSleep => 'Sleep';

  @override
  String get exportSheetMedications => 'Medications';

  @override
  String get exportSheetDay => 'Day';

  @override
  String get exportDayHeaderDate => 'Date';

  @override
  String get exportDayHeaderMood => 'Mood';

  @override
  String get exportDayHeaderBlocksWalked => 'Blocks walked';

  @override
  String get exportDayHeaderWater => 'Water';

  @override
  String get exportDayHeaderDayNotes => 'Day notes';

  @override
  String get exportDayHeaderDayNotesAbbrev => 'Day notes';

  @override
  String get exportErrorExcelGeneration => 'Could not generate the Excel file';

  @override
  String get exportPdfTitle => 'Journal (Sleep + Medication + Day)';

  @override
  String exportPdfExportedAt(Object timestamp) {
    return 'Exported: $timestamp';
  }

  @override
  String get exportPdfSectionSleep => 'Sleep log';

  @override
  String get exportPdfSectionMedications => 'Medication journal';

  @override
  String get exportPdfSectionDay => 'Day log';
}
