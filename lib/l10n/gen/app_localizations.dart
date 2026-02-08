import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
  ];

  /// Texto secundario en la pantalla de splash.
  ///
  /// In es, this message translates to:
  /// **'Tu registro diario de salud'**
  String get splashSubtitle;

  /// No description provided for @commonCancel.
  ///
  /// In es, this message translates to:
  /// **'Cancelar'**
  String get commonCancel;

  /// No description provided for @commonContinue.
  ///
  /// In es, this message translates to:
  /// **'Continuar'**
  String get commonContinue;

  /// No description provided for @commonNotNow.
  ///
  /// In es, this message translates to:
  /// **'Ahora no'**
  String get commonNotNow;

  /// No description provided for @commonUnderstood.
  ///
  /// In es, this message translates to:
  /// **'Entendido'**
  String get commonUnderstood;

  /// No description provided for @commonAdd.
  ///
  /// In es, this message translates to:
  /// **'Agregar'**
  String get commonAdd;

  /// No description provided for @commonEdit.
  ///
  /// In es, this message translates to:
  /// **'Editar'**
  String get commonEdit;

  /// No description provided for @commonSave.
  ///
  /// In es, this message translates to:
  /// **'Guardar'**
  String get commonSave;

  /// No description provided for @commonAccept.
  ///
  /// In es, this message translates to:
  /// **'Aceptar'**
  String get commonAccept;

  /// No description provided for @commonCreate.
  ///
  /// In es, this message translates to:
  /// **'Crear'**
  String get commonCreate;

  /// No description provided for @commonArchive.
  ///
  /// In es, this message translates to:
  /// **'Archivar'**
  String get commonArchive;

  /// No description provided for @commonUnarchive.
  ///
  /// In es, this message translates to:
  /// **'Desarchivar'**
  String get commonUnarchive;

  /// No description provided for @commonDeletePermanently.
  ///
  /// In es, this message translates to:
  /// **'Eliminar definitivamente'**
  String get commonDeletePermanently;

  /// No description provided for @commonDelete.
  ///
  /// In es, this message translates to:
  /// **'Eliminar'**
  String get commonDelete;

  /// No description provided for @commonAll.
  ///
  /// In es, this message translates to:
  /// **'Todo'**
  String get commonAll;

  /// No description provided for @commonNone.
  ///
  /// In es, this message translates to:
  /// **'Nada'**
  String get commonNone;

  /// No description provided for @commonIgnore.
  ///
  /// In es, this message translates to:
  /// **'Ignorar'**
  String get commonIgnore;

  /// No description provided for @commonActive.
  ///
  /// In es, this message translates to:
  /// **'Activos'**
  String get commonActive;

  /// No description provided for @commonArchived.
  ///
  /// In es, this message translates to:
  /// **'Archivados'**
  String get commonArchived;

  /// No description provided for @commonChooseRange.
  ///
  /// In es, this message translates to:
  /// **'Elegir rango'**
  String get commonChooseRange;

  /// No description provided for @commonAreYouSure.
  ///
  /// In es, this message translates to:
  /// **'¿Seguro?'**
  String get commonAreYouSure;

  /// No description provided for @commonErrorWithMessage.
  ///
  /// In es, this message translates to:
  /// **'Error: {error}'**
  String commonErrorWithMessage(Object error);

  /// No description provided for @commonNotRecorded.
  ///
  /// In es, this message translates to:
  /// **'Sin registrar'**
  String get commonNotRecorded;

  /// No description provided for @commonClear.
  ///
  /// In es, this message translates to:
  /// **'Borrar'**
  String get commonClear;

  /// No description provided for @commonDecrease.
  ///
  /// In es, this message translates to:
  /// **'Bajar'**
  String get commonDecrease;

  /// No description provided for @commonIncrease.
  ///
  /// In es, this message translates to:
  /// **'Subir'**
  String get commonIncrease;

  /// No description provided for @commonRefresh.
  ///
  /// In es, this message translates to:
  /// **'Actualizar'**
  String get commonRefresh;

  /// No description provided for @commonRange.
  ///
  /// In es, this message translates to:
  /// **'Rango'**
  String get commonRange;

  /// No description provided for @commonAverage.
  ///
  /// In es, this message translates to:
  /// **'Promedio'**
  String get commonAverage;

  /// No description provided for @commonDaysLabel.
  ///
  /// In es, this message translates to:
  /// **'Días'**
  String get commonDaysLabel;

  /// No description provided for @commonEveryDay.
  ///
  /// In es, this message translates to:
  /// **'Todos los días'**
  String get commonEveryDay;

  /// No description provided for @commonDetailsOptional.
  ///
  /// In es, this message translates to:
  /// **'Detalles (opcional)'**
  String get commonDetailsOptional;

  /// No description provided for @commonNoteSaved.
  ///
  /// In es, this message translates to:
  /// **'Nota guardada'**
  String get commonNoteSaved;

  /// No description provided for @commonIncomplete.
  ///
  /// In es, this message translates to:
  /// **'Sin completar'**
  String get commonIncomplete;

  /// No description provided for @commonSelect.
  ///
  /// In es, this message translates to:
  /// **'Seleccionar'**
  String get commonSelect;

  /// No description provided for @commonNote.
  ///
  /// In es, this message translates to:
  /// **'Nota'**
  String get commonNote;

  /// No description provided for @commonNoteOptionalLabel.
  ///
  /// In es, this message translates to:
  /// **'Nota (opcional)'**
  String get commonNoteOptionalLabel;

  /// No description provided for @commonTime.
  ///
  /// In es, this message translates to:
  /// **'Hora'**
  String get commonTime;

  /// No description provided for @commonQuantity.
  ///
  /// In es, this message translates to:
  /// **'Cantidad'**
  String get commonQuantity;

  /// No description provided for @commonNoMedication.
  ///
  /// In es, this message translates to:
  /// **'Sin medicamento'**
  String get commonNoMedication;

  /// No description provided for @commonNoDose.
  ///
  /// In es, this message translates to:
  /// **'Sin dosis'**
  String get commonNoDose;

  /// No description provided for @commonNoDoseWithDash.
  ///
  /// In es, this message translates to:
  /// **'Sin dosis (—)'**
  String get commonNoDoseWithDash;

  /// No description provided for @commonSleep.
  ///
  /// In es, this message translates to:
  /// **'Sueño'**
  String get commonSleep;

  /// No description provided for @commonMood.
  ///
  /// In es, this message translates to:
  /// **'Ánimo'**
  String get commonMood;

  /// No description provided for @commonHabits.
  ///
  /// In es, this message translates to:
  /// **'Hábitos'**
  String get commonHabits;

  /// No description provided for @commonMedication.
  ///
  /// In es, this message translates to:
  /// **'Medicación'**
  String get commonMedication;

  /// No description provided for @commonMedications.
  ///
  /// In es, this message translates to:
  /// **'Medicamentos'**
  String get commonMedications;

  /// No description provided for @commonReminders.
  ///
  /// In es, this message translates to:
  /// **'Recordatorios'**
  String get commonReminders;

  /// No description provided for @commonGroup.
  ///
  /// In es, this message translates to:
  /// **'Grupo'**
  String get commonGroup;

  /// No description provided for @commonExactAlarm.
  ///
  /// In es, this message translates to:
  /// **'⏰ Alarma exacta'**
  String get commonExactAlarm;

  /// No description provided for @commonDay.
  ///
  /// In es, this message translates to:
  /// **'Día'**
  String get commonDay;

  /// No description provided for @commonNoNotes.
  ///
  /// In es, this message translates to:
  /// **'Sin notas'**
  String get commonNoNotes;

  /// No description provided for @permissionsNotificationsDisabledTitle.
  ///
  /// In es, this message translates to:
  /// **'Notificaciones desactivadas'**
  String get permissionsNotificationsDisabledTitle;

  /// No description provided for @permissionsNotificationsDisabledBody.
  ///
  /// In es, this message translates to:
  /// **'Para que los recordatorios funcionen, activa las notificaciones en Ajustes del sistema.\n\nEsto permite mostrar avisos en la hora programada.'**
  String get permissionsNotificationsDisabledBody;

  /// No description provided for @permissionsExactAlarmsTitle.
  ///
  /// In es, this message translates to:
  /// **'Permitir alarmas exactas'**
  String get permissionsExactAlarmsTitle;

  /// No description provided for @permissionsExactAlarmsBody.
  ///
  /// In es, this message translates to:
  /// **'Este recordatorio necesita sonar a la hora exacta.\n\nActiva \"Alarmas y recordatorios\" para esta app. Si no lo activas, el aviso puede llegar con demora.'**
  String get permissionsExactAlarmsBody;

  /// No description provided for @permissionsBatteryRecommendationTitle.
  ///
  /// In es, this message translates to:
  /// **'Recomendación de batería'**
  String get permissionsBatteryRecommendationTitle;

  /// No description provided for @permissionsBatteryRecommendationBody.
  ///
  /// In es, this message translates to:
  /// **'Este equipo ({manufacturer}) a veces restringe apps en segundo plano.\n\nSi tus notificaciones no llegan, desactiva la optimización de batería para esta app:\n\nAjustes → Batería → Sin restricciones / No optimizar'**
  String permissionsBatteryRecommendationBody(Object manufacturer);

  /// No description provided for @notificationsDailyChannelName.
  ///
  /// In es, this message translates to:
  /// **'Recordatorio diario'**
  String get notificationsDailyChannelName;

  /// No description provided for @notificationsDailyChannelDescription.
  ///
  /// In es, this message translates to:
  /// **'Recordatorio para registrar el sueño diariamente'**
  String get notificationsDailyChannelDescription;

  /// No description provided for @notificationsMedicationChannelName.
  ///
  /// In es, this message translates to:
  /// **'Recordatorios de medicación'**
  String get notificationsMedicationChannelName;

  /// No description provided for @notificationsMedicationChannelDescription.
  ///
  /// In es, this message translates to:
  /// **'Alarmas para tomar medicamentos'**
  String get notificationsMedicationChannelDescription;

  /// No description provided for @notificationsDailySleepTitle.
  ///
  /// In es, this message translates to:
  /// **'🌙 Registro de sueño'**
  String get notificationsDailySleepTitle;

  /// No description provided for @notificationsDailySleepBody.
  ///
  /// In es, this message translates to:
  /// **'¿Cómo dormiste anoche? Registra tu sueño'**
  String get notificationsDailySleepBody;

  /// No description provided for @notificationsTestTitle.
  ///
  /// In es, this message translates to:
  /// **'Notificación de prueba'**
  String get notificationsTestTitle;

  /// No description provided for @notificationsTestBody.
  ///
  /// In es, this message translates to:
  /// **'Esta es una notificación de prueba. Si la ves, ¡funciona!'**
  String get notificationsTestBody;

  /// No description provided for @notificationsMedicationTitle.
  ///
  /// In es, this message translates to:
  /// **'💊 Recordatorio de medicación'**
  String get notificationsMedicationTitle;

  /// No description provided for @notificationsSnoozedTitle.
  ///
  /// In es, this message translates to:
  /// **'💊 Recordatorio (pospuesto)'**
  String get notificationsSnoozedTitle;

  /// No description provided for @notificationsTapToLogBody.
  ///
  /// In es, this message translates to:
  /// **'Tocar para registrar'**
  String get notificationsTapToLogBody;

  /// No description provided for @notificationsMedicationFallbackName.
  ///
  /// In es, this message translates to:
  /// **'medicamento'**
  String get notificationsMedicationFallbackName;

  /// No description provided for @notificationsTakeMedicationBody.
  ///
  /// In es, this message translates to:
  /// **'Tomar {name}'**
  String notificationsTakeMedicationBody(Object name);

  /// No description provided for @notificationsTakeMedicationsBody.
  ///
  /// In es, this message translates to:
  /// **'Tomar: {names}'**
  String notificationsTakeMedicationsBody(Object names);

  /// No description provided for @notificationsMedicationGroupTitle.
  ///
  /// In es, this message translates to:
  /// **'💊 {groupName}'**
  String notificationsMedicationGroupTitle(Object groupName);

  /// No description provided for @notificationsActionChoose.
  ///
  /// In es, this message translates to:
  /// **'📝 Elegir'**
  String get notificationsActionChoose;

  /// No description provided for @notificationsActionSnooze5min.
  ///
  /// In es, this message translates to:
  /// **'⏰ Posponer 5 min'**
  String get notificationsActionSnooze5min;

  /// No description provided for @notificationsActionCompleteTaken.
  ///
  /// In es, this message translates to:
  /// **'✅ Hecho'**
  String get notificationsActionCompleteTaken;

  /// No description provided for @notificationsActionCompleteAllTaken.
  ///
  /// In es, this message translates to:
  /// **'✅ Hecho'**
  String get notificationsActionCompleteAllTaken;

  /// No description provided for @notificationsAutoLogged.
  ///
  /// In es, this message translates to:
  /// **'Registrado automáticamente'**
  String get notificationsAutoLogged;

  /// No description provided for @notificationsAutoLoggedWithApplication.
  ///
  /// In es, this message translates to:
  /// **'Registrado automáticamente (aplicación)'**
  String get notificationsAutoLoggedWithApplication;

  /// No description provided for @notificationsErrorReminderMissingId.
  ///
  /// In es, this message translates to:
  /// **'El recordatorio debe tener un ID de base de datos'**
  String get notificationsErrorReminderMissingId;

  /// No description provided for @notificationsErrorGroupReminderMissingId.
  ///
  /// In es, this message translates to:
  /// **'El recordatorio de grupo debe tener un ID de DB'**
  String get notificationsErrorGroupReminderMissingId;

  /// No description provided for @notificationsErrorProcessing.
  ///
  /// In es, this message translates to:
  /// **'Error al procesar notificación: {error}'**
  String notificationsErrorProcessing(Object error);

  /// No description provided for @settingsTitle.
  ///
  /// In es, this message translates to:
  /// **'Configuración'**
  String get settingsTitle;

  /// No description provided for @settingsSectionAppearance.
  ///
  /// In es, this message translates to:
  /// **'Apariencia'**
  String get settingsSectionAppearance;

  /// No description provided for @settingsSectionSecurity.
  ///
  /// In es, this message translates to:
  /// **'Seguridad'**
  String get settingsSectionSecurity;

  /// No description provided for @settingsSectionReminders.
  ///
  /// In es, this message translates to:
  /// **'Recordatorios'**
  String get settingsSectionReminders;

  /// No description provided for @settingsSectionExportData.
  ///
  /// In es, this message translates to:
  /// **'Exportar Datos'**
  String get settingsSectionExportData;

  /// No description provided for @settingsSectionExportAnalytics.
  ///
  /// In es, this message translates to:
  /// **'Exportar para analítica'**
  String get settingsSectionExportAnalytics;

  /// No description provided for @settingsSectionDataBackups.
  ///
  /// In es, this message translates to:
  /// **'Datos y Copias de Seguridad'**
  String get settingsSectionDataBackups;

  /// No description provided for @settingsSectionInfo.
  ///
  /// In es, this message translates to:
  /// **'Información'**
  String get settingsSectionInfo;

  /// No description provided for @settingsSectionDanger.
  ///
  /// In es, this message translates to:
  /// **'Zona de peligro'**
  String get settingsSectionDanger;

  /// No description provided for @settingsDarkModeTitle.
  ///
  /// In es, this message translates to:
  /// **'Modo oscuro'**
  String get settingsDarkModeTitle;

  /// No description provided for @settingsDarkModeUsingSystem.
  ///
  /// In es, this message translates to:
  /// **'Usando el tema del sistema'**
  String get settingsDarkModeUsingSystem;

  /// No description provided for @commonDark.
  ///
  /// In es, this message translates to:
  /// **'Oscuro'**
  String get commonDark;

  /// No description provided for @commonLight.
  ///
  /// In es, this message translates to:
  /// **'Claro'**
  String get commonLight;

  /// No description provided for @settingsPinLockTitle.
  ///
  /// In es, this message translates to:
  /// **'Bloqueo con PIN'**
  String get settingsPinLockTitle;

  /// No description provided for @settingsPinLockSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Pide PIN para entrar a la app'**
  String get settingsPinLockSubtitle;

  /// No description provided for @settingsChangePinTitle.
  ///
  /// In es, this message translates to:
  /// **'Cambiar PIN'**
  String get settingsChangePinTitle;

  /// No description provided for @settingsChangePinSubtitle.
  ///
  /// In es, this message translates to:
  /// **'PIN de 4 dígitos'**
  String get settingsChangePinSubtitle;

  /// No description provided for @settingsPinUpdated.
  ///
  /// In es, this message translates to:
  /// **'PIN actualizado'**
  String get settingsPinUpdated;

  /// No description provided for @settingsLockOnReturnTitle.
  ///
  /// In es, this message translates to:
  /// **'Bloquear al volver'**
  String get settingsLockOnReturnTitle;

  /// No description provided for @settingsLockOnReturnDialogTitle.
  ///
  /// In es, this message translates to:
  /// **'Bloquear al volver de background'**
  String get settingsLockOnReturnDialogTitle;

  /// No description provided for @settingsLockTimeoutImmediateBack.
  ///
  /// In es, this message translates to:
  /// **'Inmediato al volver'**
  String get settingsLockTimeoutImmediateBack;

  /// No description provided for @settingsLockTimeout30Seconds.
  ///
  /// In es, this message translates to:
  /// **'30 segundos'**
  String get settingsLockTimeout30Seconds;

  /// No description provided for @settingsLockTimeout2Minutes.
  ///
  /// In es, this message translates to:
  /// **'2 minutos'**
  String get settingsLockTimeout2Minutes;

  /// No description provided for @settingsLockTimeout5Minutes.
  ///
  /// In es, this message translates to:
  /// **'5 minutos'**
  String get settingsLockTimeout5Minutes;

  /// No description provided for @settingsLockTimeoutImmediate.
  ///
  /// In es, this message translates to:
  /// **'Inmediato'**
  String get settingsLockTimeoutImmediate;

  /// No description provided for @settingsLockTimeoutSeconds.
  ///
  /// In es, this message translates to:
  /// **'{seconds}s'**
  String settingsLockTimeoutSeconds(Object seconds);

  /// No description provided for @settingsBiometricTitle.
  ///
  /// In es, this message translates to:
  /// **'Autenticación biométrica'**
  String get settingsBiometricTitle;

  /// No description provided for @settingsBiometricAvailableSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Usar huella digital o Face ID'**
  String get settingsBiometricAvailableSubtitle;

  /// No description provided for @settingsBiometricUnavailableSubtitle.
  ///
  /// In es, this message translates to:
  /// **'No disponible en este dispositivo'**
  String get settingsBiometricUnavailableSubtitle;

  /// No description provided for @settingsBiometricNotSupported.
  ///
  /// In es, this message translates to:
  /// **'Tu dispositivo no soporta autenticación biométrica'**
  String get settingsBiometricNotSupported;

  /// No description provided for @settingsDbEncryptionTitle.
  ///
  /// In es, this message translates to:
  /// **'Cifrado de base de datos'**
  String get settingsDbEncryptionTitle;

  /// No description provided for @settingsDbEncryptionSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Protege tus datos locales si te roban el teléfono'**
  String get settingsDbEncryptionSubtitle;

  /// No description provided for @settingsDbEncryptionStatusOn.
  ///
  /// In es, this message translates to:
  /// **'Activado'**
  String get settingsDbEncryptionStatusOn;

  /// No description provided for @settingsDbEncryptionStatusOff.
  ///
  /// In es, this message translates to:
  /// **'Desactivado'**
  String get settingsDbEncryptionStatusOff;

  /// No description provided for @settingsDbEncryptionStatusUnknown.
  ///
  /// In es, this message translates to:
  /// **'Desconocido'**
  String get settingsDbEncryptionStatusUnknown;

  /// No description provided for @settingsDbEncryptionRecommendAppLockTitle.
  ///
  /// In es, this message translates to:
  /// **'Recomendado: activar Bloqueo de app'**
  String get settingsDbEncryptionRecommendAppLockTitle;

  /// No description provided for @settingsDbEncryptionRecommendAppLockBody.
  ///
  /// In es, this message translates to:
  /// **'El cifrado protege el archivo de la DB, pero si el teléfono está desbloqueado cualquiera podría abrir la app. El Bloqueo agrega una barrera extra.'**
  String get settingsDbEncryptionRecommendAppLockBody;

  /// No description provided for @settingsDbEncryptionEnableAppLockAction.
  ///
  /// In es, this message translates to:
  /// **'Activar'**
  String get settingsDbEncryptionEnableAppLockAction;

  /// No description provided for @settingsDisableAppLockWarningTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Desactivar el bloqueo de app?'**
  String get settingsDisableAppLockWarningTitle;

  /// No description provided for @settingsDisableAppLockWarningBody.
  ///
  /// In es, this message translates to:
  /// **'Tu base de datos está cifrada, pero desactivar el bloqueo puede exponer tus datos a cualquiera que tenga tu teléfono desbloqueado.'**
  String get settingsDisableAppLockWarningBody;

  /// No description provided for @settingsDisableAppLockWarningDisable.
  ///
  /// In es, this message translates to:
  /// **'Desactivar'**
  String get settingsDisableAppLockWarningDisable;

  /// No description provided for @settingsNotificationsPermissionTitle.
  ///
  /// In es, this message translates to:
  /// **'Permiso de notificaciones'**
  String get settingsNotificationsPermissionTitle;

  /// No description provided for @settingsNotificationsPermissionBody.
  ///
  /// In es, this message translates to:
  /// **'Las notificaciones están desactivadas. Para activarlas, ve a Configuración de la aplicación.'**
  String get settingsNotificationsPermissionBody;

  /// No description provided for @settingsOpenSettings.
  ///
  /// In es, this message translates to:
  /// **'Abrir configuración'**
  String get settingsOpenSettings;

  /// No description provided for @settingsNotificationsPermissionDisabledTitle.
  ///
  /// In es, this message translates to:
  /// **'Permiso de notificaciones desactivado'**
  String get settingsNotificationsPermissionDisabledTitle;

  /// No description provided for @settingsNotificationsPermissionDisabledBody.
  ///
  /// In es, this message translates to:
  /// **'Los recordatorios no funcionarán hasta que actives el permiso.'**
  String get settingsNotificationsPermissionDisabledBody;

  /// No description provided for @settingsEnableNotificationsPermissionTitle.
  ///
  /// In es, this message translates to:
  /// **'Activar permiso de notificaciones'**
  String get settingsEnableNotificationsPermissionTitle;

  /// No description provided for @settingsEnableNotificationsPermissionSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Abrir configuración del sistema'**
  String get settingsEnableNotificationsPermissionSubtitle;

  /// No description provided for @settingsExactAlarmsPermissionDisabledTitle.
  ///
  /// In es, this message translates to:
  /// **'Permiso de alarmas exactas desactivado'**
  String get settingsExactAlarmsPermissionDisabledTitle;

  /// No description provided for @settingsExactAlarmsPermissionDisabledBody.
  ///
  /// In es, this message translates to:
  /// **'El recordatorio de sueño necesita este permiso para sonar a tiempo en Android 12+.'**
  String get settingsExactAlarmsPermissionDisabledBody;

  /// No description provided for @settingsAllowExactAlarmsTitle.
  ///
  /// In es, this message translates to:
  /// **'Permitir alarmas exactas'**
  String get settingsAllowExactAlarmsTitle;

  /// No description provided for @settingsAllowExactAlarmsSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Requerido para recordatorios precisos'**
  String get settingsAllowExactAlarmsSubtitle;

  /// No description provided for @settingsDailyReminderTitle.
  ///
  /// In es, this message translates to:
  /// **'Recordatorio diario'**
  String get settingsDailyReminderTitle;

  /// No description provided for @settingsDailyReminderSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Notificación para registrar tu sueño'**
  String get settingsDailyReminderSubtitle;

  /// No description provided for @settingsSectionGeneral.
  ///
  /// In es, this message translates to:
  /// **'General'**
  String get settingsSectionGeneral;

  /// No description provided for @settingsLanguageTitle.
  ///
  /// In es, this message translates to:
  /// **'Idioma'**
  String get settingsLanguageTitle;

  /// No description provided for @settingsLanguageSystem.
  ///
  /// In es, this message translates to:
  /// **'Automático (sistema)'**
  String get settingsLanguageSystem;

  /// No description provided for @settingsLanguageSpanish.
  ///
  /// In es, this message translates to:
  /// **'Español'**
  String get settingsLanguageSpanish;

  /// No description provided for @settingsLanguageEnglish.
  ///
  /// In es, this message translates to:
  /// **'English'**
  String get settingsLanguageEnglish;

  /// No description provided for @settingsReminderTimeTitle.
  ///
  /// In es, this message translates to:
  /// **'Hora del recordatorio'**
  String get settingsReminderTimeTitle;

  /// No description provided for @settingsReminderSetFor.
  ///
  /// In es, this message translates to:
  /// **'Recordatorio configurado para las {time}'**
  String settingsReminderSetFor(Object time);

  /// No description provided for @settingsExportDialogTitle.
  ///
  /// In es, this message translates to:
  /// **'Exportar datos'**
  String get settingsExportDialogTitle;

  /// No description provided for @settingsExportDialogBody.
  ///
  /// In es, this message translates to:
  /// **'¿Quieres exportar todos los datos o elegir un rango de fechas?'**
  String get settingsExportDialogBody;

  /// No description provided for @settingsExportSelectRangeHelpText.
  ///
  /// In es, this message translates to:
  /// **'Selecciona el rango a exportar'**
  String get settingsExportSelectRangeHelpText;

  /// No description provided for @settingsExportPdfButton.
  ///
  /// In es, this message translates to:
  /// **'Exportar a PDF'**
  String get settingsExportPdfButton;

  /// No description provided for @settingsExportExcelButton.
  ///
  /// In es, this message translates to:
  /// **'Exportar a Excel (.xlsx)'**
  String get settingsExportExcelButton;

  /// No description provided for @settingsExportNoData.
  ///
  /// In es, this message translates to:
  /// **'No hay datos para exportar. Registra algunos días primero.'**
  String get settingsExportNoData;

  /// No description provided for @settingsExportSleepRecordsTitle.
  ///
  /// In es, this message translates to:
  /// **'Registros de sueño'**
  String get settingsExportSleepRecordsTitle;

  /// No description provided for @settingsExportMedicationEventsTitle.
  ///
  /// In es, this message translates to:
  /// **'Tomas registradas'**
  String get settingsExportMedicationEventsTitle;

  /// No description provided for @settingsExportDateRangeTitle.
  ///
  /// In es, this message translates to:
  /// **'Rango de fechas'**
  String get settingsExportDateRangeTitle;

  /// No description provided for @settingsExportError.
  ///
  /// In es, this message translates to:
  /// **'Error al exportar {type}: {error}'**
  String settingsExportError(Object type, Object error);

  /// No description provided for @settingsBackupCreateTitle.
  ///
  /// In es, this message translates to:
  /// **'Crear copia de seguridad'**
  String get settingsBackupCreateTitle;

  /// No description provided for @settingsBackupCreateSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Exportar archivo para reinstalación'**
  String get settingsBackupCreateSubtitle;

  /// No description provided for @settingsBackupRestoreTitle.
  ///
  /// In es, this message translates to:
  /// **'Restaurar copia de seguridad'**
  String get settingsBackupRestoreTitle;

  /// No description provided for @settingsBackupRestoreSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Importar archivo previo'**
  String get settingsBackupRestoreSubtitle;

  /// No description provided for @settingsBackupCreateError.
  ///
  /// In es, this message translates to:
  /// **'Error al crear backup: {error}'**
  String settingsBackupCreateError(Object error);

  /// No description provided for @settingsBackupRestoreConfirmTitle.
  ///
  /// In es, this message translates to:
  /// **'Restaurar copia de seguridad'**
  String get settingsBackupRestoreConfirmTitle;

  /// No description provided for @settingsBackupRestoreConfirmBody.
  ///
  /// In es, this message translates to:
  /// **'⚠️ ALERTA: Esto eliminará todos los datos actuales y los reemplazará con los del archivo de respaldo.\n\n¿Deseas continuar?'**
  String get settingsBackupRestoreConfirmBody;

  /// No description provided for @settingsBackupRestoreConfirmYes.
  ///
  /// In es, this message translates to:
  /// **'Sí, restaurar'**
  String get settingsBackupRestoreConfirmYes;

  /// No description provided for @backupPasswordTitleCreate.
  ///
  /// In es, this message translates to:
  /// **'Cifrar backup (opcional)'**
  String get backupPasswordTitleCreate;

  /// No description provided for @backupPasswordHintCreate.
  ///
  /// In es, this message translates to:
  /// **'Deja vacío para exportar sin cifrar.'**
  String get backupPasswordHintCreate;

  /// No description provided for @backupPasswordTitleRestore.
  ///
  /// In es, this message translates to:
  /// **'Contraseña del backup'**
  String get backupPasswordTitleRestore;

  /// No description provided for @backupPasswordHintRestore.
  ///
  /// In es, this message translates to:
  /// **'Ingresa la contraseña usada al crear el backup.'**
  String get backupPasswordHintRestore;

  /// No description provided for @backupPasswordLabel.
  ///
  /// In es, this message translates to:
  /// **'Contraseña'**
  String get backupPasswordLabel;

  /// No description provided for @backupPasswordConfirmLabel.
  ///
  /// In es, this message translates to:
  /// **'Confirmar contraseña'**
  String get backupPasswordConfirmLabel;

  /// No description provided for @backupPasswordMismatch.
  ///
  /// In es, this message translates to:
  /// **'Las contraseñas no coinciden.'**
  String get backupPasswordMismatch;

  /// No description provided for @backupPasswordRequired.
  ///
  /// In es, this message translates to:
  /// **'La contraseña es obligatoria.'**
  String get backupPasswordRequired;

  /// No description provided for @backupPasswordInvalid.
  ///
  /// In es, this message translates to:
  /// **'Contraseña incorrecta.'**
  String get backupPasswordInvalid;

  /// No description provided for @settingsBackupRestoreCompleted.
  ///
  /// In es, this message translates to:
  /// **'Restauración completada. Reiniciando...'**
  String get settingsBackupRestoreCompleted;

  /// No description provided for @settingsBackupRestoreError.
  ///
  /// In es, this message translates to:
  /// **'Error al restaurar: {error}'**
  String settingsBackupRestoreError(Object error);

  /// No description provided for @settingsAboutTitle.
  ///
  /// In es, this message translates to:
  /// **'Acerca de'**
  String get settingsAboutTitle;

  /// No description provided for @settingsAboutSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Mediary v2.0.0'**
  String get settingsAboutSubtitle;

  /// No description provided for @settingsPrivacyInfoTitle.
  ///
  /// In es, this message translates to:
  /// **'Privacidad'**
  String get settingsPrivacyInfoTitle;

  /// No description provided for @settingsPrivacyInfoSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Todos tus datos se guardan localmente en tu dispositivo'**
  String get settingsPrivacyInfoSubtitle;

  /// No description provided for @settingsWipeAllTitle.
  ///
  /// In es, this message translates to:
  /// **'Borrado total'**
  String get settingsWipeAllTitle;

  /// No description provided for @settingsWipeAllSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Eliminar todos los datos del dispositivo'**
  String get settingsWipeAllSubtitle;

  /// No description provided for @settingsWipeAllDialogBody.
  ///
  /// In es, this message translates to:
  /// **'Esto eliminará TODOS tus datos guardados en el dispositivo:'**
  String get settingsWipeAllDialogBody;

  /// No description provided for @settingsWipeAllItemMedications.
  ///
  /// In es, this message translates to:
  /// **'• Medicamentos (activos y archivados)'**
  String get settingsWipeAllItemMedications;

  /// No description provided for @settingsWipeAllItemMedicationReminders.
  ///
  /// In es, this message translates to:
  /// **'• Recordatorios de medicación'**
  String get settingsWipeAllItemMedicationReminders;

  /// No description provided for @settingsWipeAllItemIntakes.
  ///
  /// In es, this message translates to:
  /// **'• Tomas registradas'**
  String get settingsWipeAllItemIntakes;

  /// No description provided for @settingsWipeAllItemSleepEntries.
  ///
  /// In es, this message translates to:
  /// **'• Registros de sueño'**
  String get settingsWipeAllItemSleepEntries;

  /// No description provided for @settingsWipeAllItemAppSettings.
  ///
  /// In es, this message translates to:
  /// **'• Configuración y estado de la app'**
  String get settingsWipeAllItemAppSettings;

  /// No description provided for @settingsWipeAllAcknowledge.
  ///
  /// In es, this message translates to:
  /// **'Entiendo que esta acción es irreversible'**
  String get settingsWipeAllAcknowledge;

  /// No description provided for @settingsWipeAllSuccess.
  ///
  /// In es, this message translates to:
  /// **'Datos eliminados correctamente'**
  String get settingsWipeAllSuccess;

  /// No description provided for @settingsWipeAllError.
  ///
  /// In es, this message translates to:
  /// **'Error al borrar datos: {error}'**
  String settingsWipeAllError(Object error);

  /// No description provided for @medicationsTitle.
  ///
  /// In es, this message translates to:
  /// **'Medicamentos'**
  String get medicationsTitle;

  /// No description provided for @medicationsGroupButton.
  ///
  /// In es, this message translates to:
  /// **'Agrupar'**
  String get medicationsGroupButton;

  /// No description provided for @medicationsEmptyTitle.
  ///
  /// In es, this message translates to:
  /// **'No hay medicamentos'**
  String get medicationsEmptyTitle;

  /// No description provided for @medicationsEmptySubtitle.
  ///
  /// In es, this message translates to:
  /// **'Agrega uno con el botón +'**
  String get medicationsEmptySubtitle;

  /// No description provided for @medicationsArchivedSectionTitle.
  ///
  /// In es, this message translates to:
  /// **'Archivados ({count})'**
  String medicationsArchivedSectionTitle(Object count);

  /// No description provided for @medicationsUnarchiveButton.
  ///
  /// In es, this message translates to:
  /// **'Reactivar'**
  String get medicationsUnarchiveButton;

  /// No description provided for @medicationsAddButton.
  ///
  /// In es, this message translates to:
  /// **'Agregar'**
  String get medicationsAddButton;

  /// No description provided for @medicationsDialogAddTitle.
  ///
  /// In es, this message translates to:
  /// **'Agregar medicamento'**
  String get medicationsDialogAddTitle;

  /// No description provided for @medicationsDialogEditTitle.
  ///
  /// In es, this message translates to:
  /// **'Editar medicamento'**
  String get medicationsDialogEditTitle;

  /// No description provided for @medicationsGenericNameLabel.
  ///
  /// In es, this message translates to:
  /// **'Nombre genérico *'**
  String get medicationsGenericNameLabel;

  /// No description provided for @medicationsGenericNameHint.
  ///
  /// In es, this message translates to:
  /// **'Ej: Ibuprofeno'**
  String get medicationsGenericNameHint;

  /// No description provided for @medicationsGenericNameRequired.
  ///
  /// In es, this message translates to:
  /// **'El nombre genérico es obligatorio'**
  String get medicationsGenericNameRequired;

  /// No description provided for @medicationsBrandNameLabel.
  ///
  /// In es, this message translates to:
  /// **'Nombre comercial (opcional)'**
  String get medicationsBrandNameLabel;

  /// No description provided for @medicationsBrandNameHint.
  ///
  /// In es, this message translates to:
  /// **'Ej: Ibupirac'**
  String get medicationsBrandNameHint;

  /// No description provided for @medicationsBaseUnitLabel.
  ///
  /// In es, this message translates to:
  /// **'Unidad base *'**
  String get medicationsBaseUnitLabel;

  /// No description provided for @medicationsBaseUnitHint.
  ///
  /// In es, this message translates to:
  /// **'Ej: 1mg, 2mg, 10ml'**
  String get medicationsBaseUnitHint;

  /// No description provided for @medicationsBaseUnitRequired.
  ///
  /// In es, this message translates to:
  /// **'La unidad base es obligatoria'**
  String get medicationsBaseUnitRequired;

  /// No description provided for @medicationsTypeLabel.
  ///
  /// In es, this message translates to:
  /// **'Tipo *'**
  String get medicationsTypeLabel;

  /// No description provided for @medicationsDefaultDoseOptional.
  ///
  /// In es, this message translates to:
  /// **'Dosis habitual (opcional)'**
  String get medicationsDefaultDoseOptional;

  /// No description provided for @medicationsDefaultDoseQtyDrops.
  ///
  /// In es, this message translates to:
  /// **'Cantidad habitual (gotas)'**
  String get medicationsDefaultDoseQtyDrops;

  /// No description provided for @medicationsDefaultDoseQtyCapsules.
  ///
  /// In es, this message translates to:
  /// **'Cantidad habitual (cápsulas)'**
  String get medicationsDefaultDoseQtyCapsules;

  /// No description provided for @medicationsDefaultDoseQtyLabel.
  ///
  /// In es, this message translates to:
  /// **'Cantidad habitual'**
  String get medicationsDefaultDoseQtyLabel;

  /// No description provided for @medicationsDefaultDosePickerTitle.
  ///
  /// In es, this message translates to:
  /// **'Dosis habitual'**
  String get medicationsDefaultDosePickerTitle;

  /// No description provided for @medicationsDefaultDoseCustom.
  ///
  /// In es, this message translates to:
  /// **'Personalizada…'**
  String get medicationsDefaultDoseCustom;

  /// No description provided for @medicationsDefaultDoseHelper.
  ///
  /// In es, this message translates to:
  /// **'Esta cantidad se precargará al registrar tomas'**
  String get medicationsDefaultDoseHelper;

  /// No description provided for @medicationsSavedAdded.
  ///
  /// In es, this message translates to:
  /// **'Medicamento agregado'**
  String get medicationsSavedAdded;

  /// No description provided for @medicationsSavedUpdated.
  ///
  /// In es, this message translates to:
  /// **'Medicamento actualizado'**
  String get medicationsSavedUpdated;

  /// No description provided for @medicationsDuplicateWarning.
  ///
  /// In es, this message translates to:
  /// **'Ya existe una medicación igual cargada. Puedes editarla desde la lista.'**
  String get medicationsDuplicateWarning;

  /// No description provided for @medicationsDbError.
  ///
  /// In es, this message translates to:
  /// **'Error de base de datos: {error}'**
  String medicationsDbError(Object error);

  /// No description provided for @medicationsError.
  ///
  /// In es, this message translates to:
  /// **'Error: {error}'**
  String medicationsError(Object error);

  /// No description provided for @medicationsManageTitle.
  ///
  /// In es, this message translates to:
  /// **'Gestionar medicamento'**
  String get medicationsManageTitle;

  /// No description provided for @medicationsManageBody.
  ///
  /// In es, this message translates to:
  /// **'Elige qué quieres hacer:\n\n• Archivar: no borra registros históricos y pausa recordatorios.\n• Eliminar definitivamente: borra el medicamento y todos sus registros asociados.'**
  String get medicationsManageBody;

  /// No description provided for @medicationsArchivedSnack.
  ///
  /// In es, this message translates to:
  /// **'Medicamento archivado'**
  String get medicationsArchivedSnack;

  /// No description provided for @medicationsArchiveError.
  ///
  /// In es, this message translates to:
  /// **'Error al archivar: {error}'**
  String medicationsArchiveError(Object error);

  /// No description provided for @medicationsHardDeleteTitle.
  ///
  /// In es, this message translates to:
  /// **'Eliminar definitivamente'**
  String get medicationsHardDeleteTitle;

  /// No description provided for @medicationsHardDeleteBody.
  ///
  /// In es, this message translates to:
  /// **'Esta acción NO se puede deshacer.\n\nSe eliminará:\n• {name}\n• todos los registros históricos asociados\n• recordatorios\n\n¿Quieres continuar?'**
  String medicationsHardDeleteBody(Object name);

  /// No description provided for @medicationsDeletedSnack.
  ///
  /// In es, this message translates to:
  /// **'Medicamento eliminado definitivamente'**
  String get medicationsDeletedSnack;

  /// No description provided for @medicationsDeleteError.
  ///
  /// In es, this message translates to:
  /// **'Error al eliminar: {error}'**
  String medicationsDeleteError(Object error);

  /// No description provided for @medicationsUnarchiveTitle.
  ///
  /// In es, this message translates to:
  /// **'Reactivar medicamento'**
  String get medicationsUnarchiveTitle;

  /// No description provided for @medicationsUnarchiveBody.
  ///
  /// In es, this message translates to:
  /// **'¿Reactivar este medicamento?\n\nVolverá a aparecer en la lista y en los selectores.\nLos recordatorios que tuviera configurados se reprogramarán.'**
  String get medicationsUnarchiveBody;

  /// No description provided for @medicationsUnarchivedSnack.
  ///
  /// In es, this message translates to:
  /// **'Medicamento reactivado'**
  String get medicationsUnarchivedSnack;

  /// No description provided for @medicationsRemindersTitle.
  ///
  /// In es, this message translates to:
  /// **'Recordatorios'**
  String get medicationsRemindersTitle;

  /// No description provided for @medicationsNoReminders.
  ///
  /// In es, this message translates to:
  /// **'Sin recordatorios'**
  String get medicationsNoReminders;

  /// No description provided for @medicationsTooltipViewReminders.
  ///
  /// In es, this message translates to:
  /// **'Ver recordatorios'**
  String get medicationsTooltipViewReminders;

  /// No description provided for @medicationsTooltipAdjustDose.
  ///
  /// In es, this message translates to:
  /// **'Ajustar dosis'**
  String get medicationsTooltipAdjustDose;

  /// No description provided for @medicationsTooltipArchiveDelete.
  ///
  /// In es, this message translates to:
  /// **'Archivar / Eliminar'**
  String get medicationsTooltipArchiveDelete;

  /// No description provided for @medicationsDeleteReminderTitle.
  ///
  /// In es, this message translates to:
  /// **'Eliminar recordatorio'**
  String get medicationsDeleteReminderTitle;

  /// No description provided for @medicationsDeleteReminderBody.
  ///
  /// In es, this message translates to:
  /// **'¿Estás seguro de eliminar este recordatorio?'**
  String get medicationsDeleteReminderBody;

  /// No description provided for @medicationsReminderDeletedSnack.
  ///
  /// In es, this message translates to:
  /// **'🗑️ Recordatorio eliminado'**
  String get medicationsReminderDeletedSnack;

  /// No description provided for @fractionPickerTitle.
  ///
  /// In es, this message translates to:
  /// **'Cantidad'**
  String get fractionPickerTitle;

  /// No description provided for @fractionPickerWholeLabel.
  ///
  /// In es, this message translates to:
  /// **'Enteros'**
  String get fractionPickerWholeLabel;

  /// No description provided for @fractionPickerFractionLabel.
  ///
  /// In es, this message translates to:
  /// **'Fracción'**
  String get fractionPickerFractionLabel;

  /// No description provided for @fractionPickerNoFractionSelected.
  ///
  /// In es, this message translates to:
  /// **'Sin fracción'**
  String get fractionPickerNoFractionSelected;

  /// No description provided for @fractionPickerPreviewLabel.
  ///
  /// In es, this message translates to:
  /// **'Vista previa:'**
  String get fractionPickerPreviewLabel;

  /// No description provided for @medicationDetailLoadError.
  ///
  /// In es, this message translates to:
  /// **'❌ Error al cargar recordatorios: {error}'**
  String medicationDetailLoadError(Object error);

  /// No description provided for @medicationDetailDeleteReminderTitle.
  ///
  /// In es, this message translates to:
  /// **'Eliminar recordatorio'**
  String get medicationDetailDeleteReminderTitle;

  /// No description provided for @medicationDetailDeleteReminderBody.
  ///
  /// In es, this message translates to:
  /// **'¿Eliminar el recordatorio de las {time}?'**
  String medicationDetailDeleteReminderBody(Object time);

  /// No description provided for @medicationDetailReminderDeleted.
  ///
  /// In es, this message translates to:
  /// **'✅ Recordatorio eliminado'**
  String get medicationDetailReminderDeleted;

  /// No description provided for @medicationDetailDeleteError.
  ///
  /// In es, this message translates to:
  /// **'❌ Error: {error}'**
  String medicationDetailDeleteError(Object error);

  /// No description provided for @medicationDetailDaysLabel.
  ///
  /// In es, this message translates to:
  /// **'Días: {days}'**
  String medicationDetailDaysLabel(Object days);

  /// No description provided for @medicationDetailSchedulesTitle.
  ///
  /// In es, this message translates to:
  /// **'Horarios de toma'**
  String get medicationDetailSchedulesTitle;

  /// No description provided for @medicationDetailSchedulesCount.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, one{1 horario} other{{count} horarios}}'**
  String medicationDetailSchedulesCount(num count);

  /// No description provided for @medicationDetailNoRemindersTitle.
  ///
  /// In es, this message translates to:
  /// **'Sin recordatorios configurados'**
  String get medicationDetailNoRemindersTitle;

  /// No description provided for @medicationDetailNoRemindersSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Presiona el botón + para agregar uno'**
  String get medicationDetailNoRemindersSubtitle;

  /// No description provided for @medicationDetailAddSchedule.
  ///
  /// In es, this message translates to:
  /// **'Agregar horario'**
  String get medicationDetailAddSchedule;

  /// No description provided for @medicationGroupsTitle.
  ///
  /// In es, this message translates to:
  /// **'Grupos de medicación'**
  String get medicationGroupsTitle;

  /// No description provided for @medicationGroupsEmpty.
  ///
  /// In es, this message translates to:
  /// **'Todavía no tenés grupos'**
  String get medicationGroupsEmpty;

  /// No description provided for @medicationGroupsNewGroupTitle.
  ///
  /// In es, this message translates to:
  /// **'Nuevo grupo'**
  String get medicationGroupsNewGroupTitle;

  /// No description provided for @medicationGroupsNameLabel.
  ///
  /// In es, this message translates to:
  /// **'Nombre'**
  String get medicationGroupsNameLabel;

  /// No description provided for @medicationGroupsNameHint.
  ///
  /// In es, this message translates to:
  /// **'Ej: Noche'**
  String get medicationGroupsNameHint;

  /// No description provided for @medicationGroupDetailGroupNotFound.
  ///
  /// In es, this message translates to:
  /// **'Grupo no encontrado'**
  String get medicationGroupDetailGroupNotFound;

  /// No description provided for @medicationGroupDetailMembersDialogTitle.
  ///
  /// In es, this message translates to:
  /// **'Medicamentos del grupo'**
  String get medicationGroupDetailMembersDialogTitle;

  /// No description provided for @medicationGroupDetailNewReminderTitle.
  ///
  /// In es, this message translates to:
  /// **'➕ Nuevo recordatorio'**
  String get medicationGroupDetailNewReminderTitle;

  /// No description provided for @medicationGroupDetailEditReminderTitle.
  ///
  /// In es, this message translates to:
  /// **'✏️ Editar recordatorio'**
  String get medicationGroupDetailEditReminderTitle;

  /// No description provided for @medicationGroupDetailTimeLabel.
  ///
  /// In es, this message translates to:
  /// **'Hora: {time}'**
  String medicationGroupDetailTimeLabel(Object time);

  /// No description provided for @medicationGroupDetailExactAlarmTitle.
  ///
  /// In es, this message translates to:
  /// **'Este grupo requiere precisión (como despertador)'**
  String get medicationGroupDetailExactAlarmTitle;

  /// No description provided for @medicationGroupDetailExactAlarmSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Suena aunque el celular esté en reposo. Necesita permisos especiales.'**
  String get medicationGroupDetailExactAlarmSubtitle;

  /// No description provided for @medicationGroupDetailDndWarning.
  ///
  /// In es, this message translates to:
  /// **'⚠️ Si usas \"No Molestar\", este recordatorio puede no sonar. Para que funcione como despertador, asegurate de permitir alarmas para esta app en Ajustes de Sonido.'**
  String get medicationGroupDetailDndWarning;

  /// No description provided for @medicationGroupDetailDeleteReminderTitle.
  ///
  /// In es, this message translates to:
  /// **'Eliminar recordatorio'**
  String get medicationGroupDetailDeleteReminderTitle;

  /// No description provided for @medicationGroupDetailDeleteGroupTitle.
  ///
  /// In es, this message translates to:
  /// **'Eliminar grupo'**
  String get medicationGroupDetailDeleteGroupTitle;

  /// No description provided for @medicationGroupDetailDeleteGroupBody.
  ///
  /// In es, this message translates to:
  /// **'Se eliminarán también sus recordatorios.'**
  String get medicationGroupDetailDeleteGroupBody;

  /// No description provided for @medicationGroupDetailDeleteGroupTooltip.
  ///
  /// In es, this message translates to:
  /// **'Eliminar grupo'**
  String get medicationGroupDetailDeleteGroupTooltip;

  /// No description provided for @medicationGroupDetailNoMembers.
  ///
  /// In es, this message translates to:
  /// **'Sin medicamentos asignados'**
  String get medicationGroupDetailNoMembers;

  /// No description provided for @medicationGroupDetailNoReminders.
  ///
  /// In es, this message translates to:
  /// **'Sin recordatorios'**
  String get medicationGroupDetailNoReminders;

  /// No description provided for @addReminderSelectMedicationError.
  ///
  /// In es, this message translates to:
  /// **'❌ Seleccioná un medicamento'**
  String get addReminderSelectMedicationError;

  /// No description provided for @addReminderSelectAtLeastOneDayError.
  ///
  /// In es, this message translates to:
  /// **'❌ Seleccioná al menos un día'**
  String get addReminderSelectAtLeastOneDayError;

  /// No description provided for @addReminderCreated.
  ///
  /// In es, this message translates to:
  /// **'{icon} Recordatorio creado'**
  String addReminderCreated(Object icon);

  /// No description provided for @addReminderUpdated.
  ///
  /// In es, this message translates to:
  /// **'{icon} Recordatorio actualizado'**
  String addReminderUpdated(Object icon);

  /// No description provided for @addReminderTitleNew.
  ///
  /// In es, this message translates to:
  /// **'➕ Nuevo recordatorio'**
  String get addReminderTitleNew;

  /// No description provided for @addReminderTitleEdit.
  ///
  /// In es, this message translates to:
  /// **'✏️ Editar recordatorio'**
  String get addReminderTitleEdit;

  /// No description provided for @addReminderMedicationLabel.
  ///
  /// In es, this message translates to:
  /// **'Medicamento'**
  String get addReminderMedicationLabel;

  /// No description provided for @addReminderTimeTitle.
  ///
  /// In es, this message translates to:
  /// **'Hora del recordatorio'**
  String get addReminderTimeTitle;

  /// No description provided for @addReminderDaysOfWeekTitle.
  ///
  /// In es, this message translates to:
  /// **'Días de la semana'**
  String get addReminderDaysOfWeekTitle;

  /// No description provided for @addReminderNoteHint.
  ///
  /// In es, this message translates to:
  /// **'Ej: Después de comer, con agua...'**
  String get addReminderNoteHint;

  /// No description provided for @addReminderExactAlarmTitle.
  ///
  /// In es, this message translates to:
  /// **'Este medicamento requiere precisión (como despertador)'**
  String get addReminderExactAlarmTitle;

  /// No description provided for @addReminderExactAlarmSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Suena aunque el celular esté en reposo. Necesita permisos especiales.'**
  String get addReminderExactAlarmSubtitle;

  /// No description provided for @addReminderDndWarning.
  ///
  /// In es, this message translates to:
  /// **'⚠️ Si usas \"No Molestar\", este recordatorio puede no sonar. Para que funcione como despertador, asegurate de permitir alarmas para esta app en Ajustes de Sonido.'**
  String get addReminderDndWarning;

  /// No description provided for @addReminderSaveButton.
  ///
  /// In es, this message translates to:
  /// **'Guardar recordatorio'**
  String get addReminderSaveButton;

  /// No description provided for @addReminderUpdateButton.
  ///
  /// In es, this message translates to:
  /// **'Actualizar recordatorio'**
  String get addReminderUpdateButton;

  /// No description provided for @quickIntakeSelectAtLeastOneMedication.
  ///
  /// In es, this message translates to:
  /// **'Selecciona al menos un medicamento'**
  String get quickIntakeSelectAtLeastOneMedication;

  /// No description provided for @quickIntakeAutoLoggedWithoutDose.
  ///
  /// In es, this message translates to:
  /// **'Registrado automáticamente (sin dosis)'**
  String get quickIntakeAutoLoggedWithoutDose;

  /// No description provided for @quickIntakeMissingDefaultDose.
  ///
  /// In es, this message translates to:
  /// **'Sin dosis por defecto: {names}'**
  String quickIntakeMissingDefaultDose(Object names);

  /// No description provided for @quickIntakeSaved.
  ///
  /// In es, this message translates to:
  /// **'✅ Toma registrada'**
  String get quickIntakeSaved;

  /// No description provided for @quickIntakeMedicationNotFound.
  ///
  /// In es, this message translates to:
  /// **'Medicamento no encontrado'**
  String get quickIntakeMedicationNotFound;

  /// No description provided for @quickIntakeSnoozed.
  ///
  /// In es, this message translates to:
  /// **'⏰ Recordatorio pospuesto {minutes} min'**
  String quickIntakeSnoozed(Object minutes);

  /// No description provided for @quickIntakeAppBarGroup.
  ///
  /// In es, this message translates to:
  /// **'💊 {groupName}'**
  String quickIntakeAppBarGroup(Object groupName);

  /// No description provided for @quickIntakeDefaultGroupName.
  ///
  /// In es, this message translates to:
  /// **'Grupo de medicación'**
  String get quickIntakeDefaultGroupName;

  /// No description provided for @quickIntakeAppBarSingle.
  ///
  /// In es, this message translates to:
  /// **'💊 Recordatorio'**
  String get quickIntakeAppBarSingle;

  /// No description provided for @quickIntakeNoActiveMeds.
  ///
  /// In es, this message translates to:
  /// **'No hay medicamentos activos para este recordatorio'**
  String get quickIntakeNoActiveMeds;

  /// No description provided for @quickIntakeUnitLabel.
  ///
  /// In es, this message translates to:
  /// **'Unidad: {unit}'**
  String quickIntakeUnitLabel(Object unit);

  /// No description provided for @quickIntakeWhatToDo.
  ///
  /// In es, this message translates to:
  /// **'¿Qué quieres hacer?'**
  String get quickIntakeWhatToDo;

  /// No description provided for @quickIntakeIHaveTaken.
  ///
  /// In es, this message translates to:
  /// **'Ya tomé'**
  String get quickIntakeIHaveTaken;

  /// No description provided for @quickIntakeSnooze10m.
  ///
  /// In es, this message translates to:
  /// **'Posponer 10 minutos'**
  String get quickIntakeSnooze10m;

  /// No description provided for @quickIntakeSnooze1h.
  ///
  /// In es, this message translates to:
  /// **'Posponer 1 hora'**
  String get quickIntakeSnooze1h;

  /// No description provided for @quickIntakeChooseTaken.
  ///
  /// In es, this message translates to:
  /// **'Elige cuáles tomaste'**
  String get quickIntakeChooseTaken;

  /// No description provided for @quickIntakeSelectedCount.
  ///
  /// In es, this message translates to:
  /// **'{selected}/{total} seleccionados'**
  String quickIntakeSelectedCount(Object selected, Object total);

  /// No description provided for @quickIntakeSaveSelectedClose.
  ///
  /// In es, this message translates to:
  /// **'Guardar seleccionadas (cerrar)'**
  String get quickIntakeSaveSelectedClose;

  /// No description provided for @quickIntakeRemainingHint.
  ///
  /// In es, this message translates to:
  /// **'Las {remaining} restantes no se vuelven a avisar automáticamente. Si quieres que te notifique más tarde, usa “Posponer restantes”.'**
  String quickIntakeRemainingHint(Object remaining);

  /// No description provided for @quickIntakeSnoozeRemaining10m.
  ///
  /// In es, this message translates to:
  /// **'Posponer restantes 10m'**
  String get quickIntakeSnoozeRemaining10m;

  /// No description provided for @quickIntakeSnoozeRemaining1h.
  ///
  /// In es, this message translates to:
  /// **'Posponer restantes 1h'**
  String get quickIntakeSnoozeRemaining1h;

  /// No description provided for @dailyEntryTitle.
  ///
  /// In es, this message translates to:
  /// **'Registrar tu día'**
  String get dailyEntryTitle;

  /// No description provided for @dailyEntryTabDayOptional.
  ///
  /// In es, this message translates to:
  /// **'Día (opcional)'**
  String get dailyEntryTabDayOptional;

  /// No description provided for @dailyEntryTabSleepOptional.
  ///
  /// In es, this message translates to:
  /// **'Sueño (opcional)'**
  String get dailyEntryTabSleepOptional;

  /// No description provided for @dailyEntryTabMedication.
  ///
  /// In es, this message translates to:
  /// **'Medicación'**
  String get dailyEntryTabMedication;

  /// No description provided for @dailyEntryMedicationAdded.
  ///
  /// In es, this message translates to:
  /// **'Medicación agregada'**
  String get dailyEntryMedicationAdded;

  /// No description provided for @dailyEntrySaveError.
  ///
  /// In es, this message translates to:
  /// **'Error al guardar'**
  String get dailyEntrySaveError;

  /// No description provided for @dailyEntrySaveErrorWithMessage.
  ///
  /// In es, this message translates to:
  /// **'Error al guardar: {error}'**
  String dailyEntrySaveErrorWithMessage(Object error);

  /// No description provided for @dailyEntrySaveSuccess.
  ///
  /// In es, this message translates to:
  /// **'Registro guardado correctamente'**
  String get dailyEntrySaveSuccess;

  /// No description provided for @dayTabHeader.
  ///
  /// In es, this message translates to:
  /// **'Día {date}'**
  String dayTabHeader(Object date);

  /// No description provided for @dayTabOptionalHint.
  ///
  /// In es, this message translates to:
  /// **'Opcional. Si no quieres, puedes dejar todo vacío.'**
  String get dayTabOptionalHint;

  /// No description provided for @dayTabMoodTitle.
  ///
  /// In es, this message translates to:
  /// **'Ánimo'**
  String get dayTabMoodTitle;

  /// No description provided for @dayTabMoodQuestion.
  ///
  /// In es, this message translates to:
  /// **'Cómo te sientes hoy?'**
  String get dayTabMoodQuestion;

  /// No description provided for @dayTabMoodVeryBad.
  ///
  /// In es, this message translates to:
  /// **'Muy mal'**
  String get dayTabMoodVeryBad;

  /// No description provided for @dayTabMoodBad.
  ///
  /// In es, this message translates to:
  /// **'Mal'**
  String get dayTabMoodBad;

  /// No description provided for @dayTabMoodOk.
  ///
  /// In es, this message translates to:
  /// **'Regular'**
  String get dayTabMoodOk;

  /// No description provided for @dayTabMoodGood.
  ///
  /// In es, this message translates to:
  /// **'Bien'**
  String get dayTabMoodGood;

  /// No description provided for @dayTabMoodVeryGood.
  ///
  /// In es, this message translates to:
  /// **'Muy bien'**
  String get dayTabMoodVeryGood;

  /// No description provided for @dayTabDayNotesTitle.
  ///
  /// In es, this message translates to:
  /// **'Notas del día'**
  String get dayTabDayNotesTitle;

  /// No description provided for @dayTabDayNotesHint.
  ///
  /// In es, this message translates to:
  /// **'Algo para recordar sobre el día...'**
  String get dayTabDayNotesHint;

  /// No description provided for @dayTabHabitsTitle.
  ///
  /// In es, this message translates to:
  /// **'Hábitos'**
  String get dayTabHabitsTitle;

  /// No description provided for @dayTabWaterTitle.
  ///
  /// In es, this message translates to:
  /// **'Agua'**
  String get dayTabWaterTitle;

  /// No description provided for @dayTabWaterCount.
  ///
  /// In es, this message translates to:
  /// **'Vasos: {count}'**
  String dayTabWaterCount(Object count);

  /// No description provided for @dayTabWaterCountLabel.
  ///
  /// In es, this message translates to:
  /// **'Agua: {count}'**
  String dayTabWaterCountLabel(Object count);

  /// No description provided for @dayTabBlocksWalkedTitle.
  ///
  /// In es, this message translates to:
  /// **'Cuadras caminadas'**
  String get dayTabBlocksWalkedTitle;

  /// No description provided for @dayTabBlocksWalkedHint.
  ///
  /// In es, this message translates to:
  /// **'Ej: 12'**
  String get dayTabBlocksWalkedHint;

  /// No description provided for @dayTabBlocksWalkedHelper.
  ///
  /// In es, this message translates to:
  /// **'0–1000 aprox.'**
  String get dayTabBlocksWalkedHelper;

  /// No description provided for @sleepTabNightOf.
  ///
  /// In es, this message translates to:
  /// **'Noche del {date}'**
  String sleepTabNightOf(Object date);

  /// No description provided for @sleepTabNightRange.
  ///
  /// In es, this message translates to:
  /// **'({startDay}→{endDay})'**
  String sleepTabNightRange(Object startDay, Object endDay);

  /// No description provided for @sleepTabHowDidYouSleep.
  ///
  /// In es, this message translates to:
  /// **'Cómo dormiste?'**
  String get sleepTabHowDidYouSleep;

  /// No description provided for @sleepTabHowLongDidYouSleep.
  ///
  /// In es, this message translates to:
  /// **'¿Cuánto dormiste?'**
  String get sleepTabHowLongDidYouSleep;

  /// No description provided for @sleepTabHours.
  ///
  /// In es, this message translates to:
  /// **'Horas'**
  String get sleepTabHours;

  /// No description provided for @sleepTabMinutes.
  ///
  /// In es, this message translates to:
  /// **'Minutos'**
  String get sleepTabMinutes;

  /// No description provided for @sleepTabHowWasSleep.
  ///
  /// In es, this message translates to:
  /// **'¿Cómo fue el sueño?'**
  String get sleepTabHowWasSleep;

  /// No description provided for @sleepTabContinuityStraight.
  ///
  /// In es, this message translates to:
  /// **'De corrido'**
  String get sleepTabContinuityStraight;

  /// No description provided for @sleepTabContinuityBroken.
  ///
  /// In es, this message translates to:
  /// **'Cortado'**
  String get sleepTabContinuityBroken;

  /// No description provided for @sleepTabOptionalHint.
  ///
  /// In es, this message translates to:
  /// **'Opcional: si no quieres, déjalo vacío.'**
  String get sleepTabOptionalHint;

  /// No description provided for @sleepTabGeneralNotesOptional.
  ///
  /// In es, this message translates to:
  /// **'Notas generales (opcional)'**
  String get sleepTabGeneralNotesOptional;

  /// No description provided for @sleepTabNotesHint.
  ///
  /// In es, this message translates to:
  /// **'Algo para recordar mañana...'**
  String get sleepTabNotesHint;

  /// No description provided for @medicationTabExpandAll.
  ///
  /// In es, this message translates to:
  /// **'Expandir todo'**
  String get medicationTabExpandAll;

  /// No description provided for @medicationTabCollapseAll.
  ///
  /// In es, this message translates to:
  /// **'Contraer todo'**
  String get medicationTabCollapseAll;

  /// No description provided for @medicationTabEmptyTitle.
  ///
  /// In es, this message translates to:
  /// **'Sin medicamentos registrados'**
  String get medicationTabEmptyTitle;

  /// No description provided for @medicationTabEmptySubtitle.
  ///
  /// In es, this message translates to:
  /// **'Presiona el botón + para agregar'**
  String get medicationTabEmptySubtitle;

  /// No description provided for @medicationTabAddMedication.
  ///
  /// In es, this message translates to:
  /// **'Agregar medicación'**
  String get medicationTabAddMedication;

  /// No description provided for @medicationTabDoseApplication.
  ///
  /// In es, this message translates to:
  /// **'Aplicación'**
  String get medicationTabDoseApplication;

  /// No description provided for @medicationTabDropsDose.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, one{1 gota} other{{count} gotas}}'**
  String medicationTabDropsDose(num count);

  /// No description provided for @medicationTabCapsulesDose.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, one{1 cápsula} other{{count} cápsulas}}'**
  String medicationTabCapsulesDose(num count);

  /// No description provided for @medicationTabCustomQuantityTitle.
  ///
  /// In es, this message translates to:
  /// **'Cantidad personalizada'**
  String get medicationTabCustomQuantityTitle;

  /// No description provided for @medicationTabMedicationLabel.
  ///
  /// In es, this message translates to:
  /// **'Medicamento'**
  String get medicationTabMedicationLabel;

  /// No description provided for @medicationTabAddAnotherMedication.
  ///
  /// In es, this message translates to:
  /// **'+ Agregar otro'**
  String get medicationTabAddAnotherMedication;

  /// No description provided for @medicationTabDoseDropsLabel.
  ///
  /// In es, this message translates to:
  /// **'Cantidad de gotas'**
  String get medicationTabDoseDropsLabel;

  /// No description provided for @medicationTabDoseCapsulesLabel.
  ///
  /// In es, this message translates to:
  /// **'Cantidad de cápsulas'**
  String get medicationTabDoseCapsulesLabel;

  /// No description provided for @medicationTabNoteOptionalLabel.
  ///
  /// In es, this message translates to:
  /// **'Nota (opcional)'**
  String get medicationTabNoteOptionalLabel;

  /// No description provided for @medicationTabNoteHint.
  ///
  /// In es, this message translates to:
  /// **'Efectos, contexto...'**
  String get medicationTabNoteHint;

  /// No description provided for @homeTitle.
  ///
  /// In es, this message translates to:
  /// **'Diario'**
  String get homeTitle;

  /// No description provided for @homeTooltipSummary.
  ///
  /// In es, this message translates to:
  /// **'Resumen'**
  String get homeTooltipSummary;

  /// No description provided for @homeTooltipMedications.
  ///
  /// In es, this message translates to:
  /// **'Medicamentos'**
  String get homeTooltipMedications;

  /// No description provided for @homeTooltipSettings.
  ///
  /// In es, this message translates to:
  /// **'Ajustes'**
  String get homeTooltipSettings;

  /// No description provided for @homeCalendarViewTooltip.
  ///
  /// In es, this message translates to:
  /// **'Vista'**
  String get homeCalendarViewTooltip;

  /// No description provided for @homeCalendarFilterTooltip.
  ///
  /// In es, this message translates to:
  /// **'Filtrar'**
  String get homeCalendarFilterTooltip;

  /// No description provided for @homeCalendarMonth.
  ///
  /// In es, this message translates to:
  /// **'Mes'**
  String get homeCalendarMonth;

  /// No description provided for @homeCalendarTwoWeeks.
  ///
  /// In es, this message translates to:
  /// **'2 semanas'**
  String get homeCalendarTwoWeeks;

  /// No description provided for @homeCalendarWeek.
  ///
  /// In es, this message translates to:
  /// **'Semana'**
  String get homeCalendarWeek;

  /// No description provided for @homeRemindersTodayTitle.
  ///
  /// In es, this message translates to:
  /// **'Recordatorios de hoy'**
  String get homeRemindersTodayTitle;

  /// No description provided for @homeRemindersSnoozedHeader.
  ///
  /// In es, this message translates to:
  /// **'Pospuestos'**
  String get homeRemindersSnoozedHeader;

  /// No description provided for @summaryTitle.
  ///
  /// In es, this message translates to:
  /// **'Resumen'**
  String get summaryTitle;

  /// No description provided for @summaryLoadError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo cargar el resumen.'**
  String get summaryLoadError;

  /// No description provided for @summaryLastNDays.
  ///
  /// In es, this message translates to:
  /// **'Últimos {days} días'**
  String summaryLastNDays(Object days);

  /// No description provided for @summaryTabStats.
  ///
  /// In es, this message translates to:
  /// **'Estadísticas'**
  String get summaryTabStats;

  /// No description provided for @summaryTabPatterns.
  ///
  /// In es, this message translates to:
  /// **'Patrones'**
  String get summaryTabPatterns;

  /// No description provided for @summaryViewDayByDay.
  ///
  /// In es, this message translates to:
  /// **'Ver detalle día por día →'**
  String get summaryViewDayByDay;

  /// No description provided for @summaryPatternsRangeHint.
  ///
  /// In es, this message translates to:
  /// **'Relaciones disponibles en 30 y 90 días.'**
  String get summaryPatternsRangeHint;

  /// No description provided for @summarySleepAverageQuality.
  ///
  /// In es, this message translates to:
  /// **'Promedio de calidad de sueño'**
  String get summarySleepAverageQuality;

  /// No description provided for @summarySleepNoRecords.
  ///
  /// In es, this message translates to:
  /// **'Sin registros de sueño en este período'**
  String get summarySleepNoRecords;

  /// No description provided for @summaryMoodNoRecords.
  ///
  /// In es, this message translates to:
  /// **'Sin registros de ánimo en este período'**
  String get summaryMoodNoRecords;

  /// No description provided for @summaryMoodMostFrequentPrefix.
  ///
  /// In es, this message translates to:
  /// **'El ánimo más frecuente fue'**
  String get summaryMoodMostFrequentPrefix;

  /// No description provided for @summaryMedicationDaysWith.
  ///
  /// In es, this message translates to:
  /// **'Días con medicación registrada: {withCount} de {total}'**
  String summaryMedicationDaysWith(Object withCount, Object total);

  /// No description provided for @summaryDaysWithoutRecord.
  ///
  /// In es, this message translates to:
  /// **'Días sin registro: {days}'**
  String summaryDaysWithoutRecord(Object days);

  /// No description provided for @summaryPatternsStreaks.
  ///
  /// In es, this message translates to:
  /// **'Rachas'**
  String get summaryPatternsStreaks;

  /// No description provided for @summaryPatternsGoals.
  ///
  /// In es, this message translates to:
  /// **'Metas'**
  String get summaryPatternsGoals;

  /// No description provided for @summaryPatternsInsights.
  ///
  /// In es, this message translates to:
  /// **'Insights'**
  String get summaryPatternsInsights;

  /// No description provided for @summaryStreakCurrent.
  ///
  /// In es, this message translates to:
  /// **'Actual: {value}'**
  String summaryStreakCurrent(Object value);

  /// No description provided for @summaryStreakBest.
  ///
  /// In es, this message translates to:
  /// **'Mejor: {value}'**
  String summaryStreakBest(Object value);

  /// No description provided for @summaryGoalDaysProgress.
  ///
  /// In es, this message translates to:
  /// **'{achieved}/{total} días'**
  String summaryGoalDaysProgress(Object achieved, Object total);

  /// No description provided for @summaryInsightsDisclaimer.
  ///
  /// In es, this message translates to:
  /// **'Son comparaciones dentro del período (no implican causalidad).'**
  String get summaryInsightsDisclaimer;

  /// No description provided for @summaryInsightStrengthNotEnoughData.
  ///
  /// In es, this message translates to:
  /// **'Sin datos'**
  String get summaryInsightStrengthNotEnoughData;

  /// No description provided for @summaryInsightStrengthWeak.
  ///
  /// In es, this message translates to:
  /// **'Débil'**
  String get summaryInsightStrengthWeak;

  /// No description provided for @summaryInsightStrengthPreliminary.
  ///
  /// In es, this message translates to:
  /// **'Preliminar'**
  String get summaryInsightStrengthPreliminary;

  /// No description provided for @summaryInsightStrengthModerate.
  ///
  /// In es, this message translates to:
  /// **'Moderada'**
  String get summaryInsightStrengthModerate;

  /// No description provided for @summaryInsightStrengthStrong.
  ///
  /// In es, this message translates to:
  /// **'Fuerte'**
  String get summaryInsightStrengthStrong;

  /// No description provided for @summaryDaysWithRecordLabel.
  ///
  /// In es, this message translates to:
  /// **'Días con registro (de {rangeDays}):'**
  String summaryDaysWithRecordLabel(Object rangeDays);

  /// No description provided for @summaryAvgShortWithValue.
  ///
  /// In es, this message translates to:
  /// **'Prom: {value}'**
  String summaryAvgShortWithValue(Object value);

  /// No description provided for @summaryBlocksWalkedDays.
  ///
  /// In es, this message translates to:
  /// **'Cuadras caminadas: {days}'**
  String summaryBlocksWalkedDays(Object days);

  /// No description provided for @summaryWaterDays.
  ///
  /// In es, this message translates to:
  /// **'💧 Agua: {days}'**
  String summaryWaterDays(Object days);

  /// No description provided for @summarySleepTrendHigherAtEnd.
  ///
  /// In es, this message translates to:
  /// **'La calidad de sueño fue más alta hacia el final del período'**
  String get summarySleepTrendHigherAtEnd;

  /// No description provided for @summarySleepTrendHigherAtStart.
  ///
  /// In es, this message translates to:
  /// **'La calidad de sueño fue más alta hacia el inicio del período'**
  String get summarySleepTrendHigherAtStart;

  /// No description provided for @summaryPatternWaterGoal.
  ///
  /// In es, this message translates to:
  /// **'💧 Agua ≥6'**
  String get summaryPatternWaterGoal;

  /// No description provided for @summaryPatternSleepGoal.
  ///
  /// In es, this message translates to:
  /// **'🛏️ Sueño ≥4'**
  String get summaryPatternSleepGoal;

  /// No description provided for @summaryPatternMoodGoal.
  ///
  /// In es, this message translates to:
  /// **'😊 Ánimo ≥4'**
  String get summaryPatternMoodGoal;

  /// No description provided for @summaryMetricSleep.
  ///
  /// In es, this message translates to:
  /// **'sueño'**
  String get summaryMetricSleep;

  /// No description provided for @summaryMetricMood.
  ///
  /// In es, this message translates to:
  /// **'ánimo'**
  String get summaryMetricMood;

  /// No description provided for @summaryMetricWater.
  ///
  /// In es, this message translates to:
  /// **'agua'**
  String get summaryMetricWater;

  /// No description provided for @summaryInsightTitleSleepMood.
  ///
  /// In es, this message translates to:
  /// **'Sueño ↔ Ánimo'**
  String get summaryInsightTitleSleepMood;

  /// No description provided for @summaryInsightTitleWaterMood.
  ///
  /// In es, this message translates to:
  /// **'Agua ↔ Ánimo'**
  String get summaryInsightTitleWaterMood;

  /// No description provided for @summaryInsightDirHigher.
  ///
  /// In es, this message translates to:
  /// **'más alto'**
  String get summaryInsightDirHigher;

  /// No description provided for @summaryInsightDirLower.
  ///
  /// In es, this message translates to:
  /// **'más bajo'**
  String get summaryInsightDirLower;

  /// No description provided for @summaryInsightBaseMinPairs.
  ///
  /// In es, this message translates to:
  /// **'Base: {pairCount} días (mínimo: {minPairs})'**
  String summaryInsightBaseMinPairs(Object pairCount, Object minPairs);

  /// No description provided for @summaryInsightMessageMinPairs.
  ///
  /// In es, this message translates to:
  /// **'Preliminar: hay pocos días con ambos datos cargados para comparar.'**
  String get summaryInsightMessageMinPairs;

  /// No description provided for @summaryInsightBaseNoGroup.
  ///
  /// In es, this message translates to:
  /// **'Base: {pairCount} días'**
  String summaryInsightBaseNoGroup(Object pairCount);

  /// No description provided for @summaryInsightMessageNoGroup.
  ///
  /// In es, this message translates to:
  /// **'Preliminar: no hay suficientes datos para agrupar.'**
  String get summaryInsightMessageNoGroup;

  /// No description provided for @summaryInsightGroupHintShort.
  ///
  /// In es, this message translates to:
  /// **'días con más {xLabel} vs menos {xLabel}'**
  String summaryInsightGroupHintShort(Object xLabel);

  /// No description provided for @summaryInsightGroupHintLong.
  ///
  /// In es, this message translates to:
  /// **'mejores vs peores ~30% (según {xLabel})'**
  String summaryInsightGroupHintLong(Object xLabel);

  /// No description provided for @summaryInsightBaseTopBottom.
  ///
  /// In es, this message translates to:
  /// **'Base: {pairCount} días · {groupHint} · grupos: {g} y {g}'**
  String summaryInsightBaseTopBottom(
    Object pairCount,
    Object groupHint,
    Object g,
  );

  /// No description provided for @summaryInsightMessageTopBottom.
  ///
  /// In es, this message translates to:
  /// **'En tus días con {xLabel} más alto, {yLabel} tiende a ser {dirWord} (Δ {delta}).'**
  String summaryInsightMessageTopBottom(
    Object xLabel,
    Object yLabel,
    Object dirWord,
    Object delta,
  );

  /// No description provided for @selectedDayDeleteTooltip.
  ///
  /// In es, this message translates to:
  /// **'Eliminar registro del día'**
  String get selectedDayDeleteTooltip;

  /// No description provided for @selectedDayDeleteDialogTitle.
  ///
  /// In es, this message translates to:
  /// **'Eliminar registro'**
  String get selectedDayDeleteDialogTitle;

  /// No description provided for @selectedDayDeleteDialogBody.
  ///
  /// In es, this message translates to:
  /// **'¿Eliminar el registro COMPLETO de este día?\n\nSe borrarán: sueño, medicación (tomas), ánimo y notas.'**
  String get selectedDayDeleteDialogBody;

  /// No description provided for @selectedDayChipSleepWithQuality.
  ///
  /// In es, this message translates to:
  /// **'Sueño: {quality}/5'**
  String selectedDayChipSleepWithQuality(Object quality);

  /// No description provided for @selectedDayChipSleepEmpty.
  ///
  /// In es, this message translates to:
  /// **'Sueño: —'**
  String get selectedDayChipSleepEmpty;

  /// No description provided for @selectedDayChipMedicationWithCount.
  ///
  /// In es, this message translates to:
  /// **'Medicación: {count}'**
  String selectedDayChipMedicationWithCount(Object count);

  /// No description provided for @selectedDayChipMedicationEmpty.
  ///
  /// In es, this message translates to:
  /// **'Medicación: —'**
  String get selectedDayChipMedicationEmpty;

  /// No description provided for @selectedDayNoMoodRecorded.
  ///
  /// In es, this message translates to:
  /// **'Sin ánimo registrado'**
  String get selectedDayNoMoodRecorded;

  /// No description provided for @selectedDayNoWater.
  ///
  /// In es, this message translates to:
  /// **'Sin agua'**
  String get selectedDayNoWater;

  /// No description provided for @selectedDayBlocksWalkedValue.
  ///
  /// In es, this message translates to:
  /// **'Cuadras caminadas: {value}'**
  String selectedDayBlocksWalkedValue(Object value);

  /// No description provided for @selectedDayNoBlocksWalked.
  ///
  /// In es, this message translates to:
  /// **'Sin cuadras caminadas registradas'**
  String get selectedDayNoBlocksWalked;

  /// No description provided for @selectedDayNoSleepRecord.
  ///
  /// In es, this message translates to:
  /// **'Sin registro de sueño'**
  String get selectedDayNoSleepRecord;

  /// No description provided for @selectedDayMedicationsTitle.
  ///
  /// In es, this message translates to:
  /// **'Medicaciones'**
  String get selectedDayMedicationsTitle;

  /// No description provided for @selectedDayNoMedications.
  ///
  /// In es, this message translates to:
  /// **'Sin medicaciones registradas'**
  String get selectedDayNoMedications;

  /// No description provided for @selectedDayMedicationFallbackName.
  ///
  /// In es, this message translates to:
  /// **'Medicamento {id}'**
  String selectedDayMedicationFallbackName(Object id);

  /// No description provided for @selectedDayMedicationQtyLabelRecord.
  ///
  /// In es, this message translates to:
  /// **'Registro'**
  String get selectedDayMedicationQtyLabelRecord;

  /// No description provided for @commonBack.
  ///
  /// In es, this message translates to:
  /// **'Atrás'**
  String get commonBack;

  /// No description provided for @commonNext.
  ///
  /// In es, this message translates to:
  /// **'Siguiente'**
  String get commonNext;

  /// No description provided for @commonSkip.
  ///
  /// In es, this message translates to:
  /// **'Omitir'**
  String get commonSkip;

  /// No description provided for @commonSaving.
  ///
  /// In es, this message translates to:
  /// **'Guardando…'**
  String get commonSaving;

  /// No description provided for @welcomeStart.
  ///
  /// In es, this message translates to:
  /// **'Comenzar'**
  String get welcomeStart;

  /// No description provided for @welcomePage1Title.
  ///
  /// In es, this message translates to:
  /// **'Tu registro diario, sin esfuerzo'**
  String get welcomePage1Title;

  /// No description provided for @welcomePage1Body.
  ///
  /// In es, this message translates to:
  /// **'Anota medicación, sueño y notas del día en pocos segundos.'**
  String get welcomePage1Body;

  /// No description provided for @welcomePage2Title.
  ///
  /// In es, this message translates to:
  /// **'Recordatorios, si los necesitas'**
  String get welcomePage2Title;

  /// No description provided for @welcomePage2Body.
  ///
  /// In es, this message translates to:
  /// **'Programa alarmas para tus tomas o úsalo solo para registrar.'**
  String get welcomePage2Body;

  /// No description provided for @welcomePage3Title.
  ///
  /// In es, this message translates to:
  /// **'Tu historial en calendario'**
  String get welcomePage3Title;

  /// No description provided for @welcomePage3Body.
  ///
  /// In es, this message translates to:
  /// **'Vas a poder ver días registrados y detectar patrones con el tiempo.'**
  String get welcomePage3Body;

  /// No description provided for @welcomePage4Title.
  ///
  /// In es, this message translates to:
  /// **'Todo queda en tu teléfono'**
  String get welcomePage4Title;

  /// No description provided for @welcomePage4Body.
  ///
  /// In es, this message translates to:
  /// **'Se guarda localmente. Sin cuentas, sin servidores, sin internet.'**
  String get welcomePage4Body;

  /// No description provided for @appLockBiometricReason.
  ///
  /// In es, this message translates to:
  /// **'Autenticación requerida'**
  String get appLockBiometricReason;

  /// No description provided for @setPinTitleCreate.
  ///
  /// In es, this message translates to:
  /// **'Crear PIN'**
  String get setPinTitleCreate;

  /// No description provided for @setPinTitleChange.
  ///
  /// In es, this message translates to:
  /// **'Cambiar PIN'**
  String get setPinTitleChange;

  /// No description provided for @setPinEnterCurrentPinError.
  ///
  /// In es, this message translates to:
  /// **'Ingresa tu PIN actual (4 dígitos)'**
  String get setPinEnterCurrentPinError;

  /// No description provided for @setPinInvalidPinError.
  ///
  /// In es, this message translates to:
  /// **'El PIN debe tener 4 dígitos'**
  String get setPinInvalidPinError;

  /// No description provided for @setPinPinsDoNotMatch.
  ///
  /// In es, this message translates to:
  /// **'Los PIN no coinciden'**
  String get setPinPinsDoNotMatch;

  /// No description provided for @setPinTooManyAttemptsSeconds.
  ///
  /// In es, this message translates to:
  /// **'Demasiados intentos. Espera {seconds}s'**
  String setPinTooManyAttemptsSeconds(Object seconds);

  /// No description provided for @setPinCurrentPinIncorrect.
  ///
  /// In es, this message translates to:
  /// **'PIN actual incorrecto'**
  String get setPinCurrentPinIncorrect;

  /// No description provided for @setPinCurrentPinLabel.
  ///
  /// In es, this message translates to:
  /// **'PIN actual'**
  String get setPinCurrentPinLabel;

  /// No description provided for @setPinNewPinLabel.
  ///
  /// In es, this message translates to:
  /// **'Nuevo PIN (4 dígitos)'**
  String get setPinNewPinLabel;

  /// No description provided for @setPinConfirmNewPinLabel.
  ///
  /// In es, this message translates to:
  /// **'Confirmar nuevo PIN'**
  String get setPinConfirmNewPinLabel;

  /// No description provided for @lockScreenEnterPinTitle.
  ///
  /// In es, this message translates to:
  /// **'Ingresa tu PIN'**
  String get lockScreenEnterPinTitle;

  /// No description provided for @lockScreenPinHint.
  ///
  /// In es, this message translates to:
  /// **'4 dígitos'**
  String get lockScreenPinHint;

  /// No description provided for @lockScreenLockedOut.
  ///
  /// In es, this message translates to:
  /// **'Bloqueado por seguridad. Intenta de nuevo en {time}'**
  String lockScreenLockedOut(Object time);

  /// No description provided for @lockScreenTooManyAttempts.
  ///
  /// In es, this message translates to:
  /// **'Demasiados intentos. Espera {time}'**
  String lockScreenTooManyAttempts(Object time);

  /// No description provided for @lockScreenPinIncorrectAttemptsLeft.
  ///
  /// In es, this message translates to:
  /// **'PIN incorrecto. Intentos restantes: {left}'**
  String lockScreenPinIncorrectAttemptsLeft(Object left);

  /// No description provided for @lockScreenUseBiometrics.
  ///
  /// In es, this message translates to:
  /// **'Usar huella digital'**
  String get lockScreenUseBiometrics;

  /// No description provided for @dailyEntryValidationFutureDay.
  ///
  /// In es, this message translates to:
  /// **'No se puede registrar un día futuro.'**
  String get dailyEntryValidationFutureDay;

  /// No description provided for @dailyEntryValidationSelectMedication.
  ///
  /// In es, this message translates to:
  /// **'Por favor selecciona el medicamento en el evento {index}'**
  String dailyEntryValidationSelectMedication(Object index);

  /// No description provided for @dailyEntryValidationGelNoQuantity.
  ///
  /// In es, this message translates to:
  /// **'Para gel no se registra cantidad. Deja “Sin dosis” en el evento {index}.'**
  String dailyEntryValidationGelNoQuantity(Object index);

  /// No description provided for @dailyEntryValidationInvalidQuantityInteger.
  ///
  /// In es, this message translates to:
  /// **'La cantidad del evento {index} es inválida. Elige “Sin dosis” o un entero válido.'**
  String dailyEntryValidationInvalidQuantityInteger(Object index);

  /// No description provided for @dailyEntryValidationInvalidQuantityFraction.
  ///
  /// In es, this message translates to:
  /// **'La cantidad del evento {index} es inválida. Elige “Sin dosis” o una fracción válida.'**
  String dailyEntryValidationInvalidQuantityFraction(Object index);

  /// No description provided for @dailyEntryValidationSleepNeedsQuality.
  ///
  /// In es, this message translates to:
  /// **'Para guardar el sueño, elige “Cómo dormiste” (1–5) o borra los detalles.'**
  String get dailyEntryValidationSleepNeedsQuality;

  /// No description provided for @medicationTypeTablet.
  ///
  /// In es, this message translates to:
  /// **'comprimido'**
  String get medicationTypeTablet;

  /// No description provided for @medicationTypeDrops.
  ///
  /// In es, this message translates to:
  /// **'gotas'**
  String get medicationTypeDrops;

  /// No description provided for @medicationTypeCapsule.
  ///
  /// In es, this message translates to:
  /// **'cápsula'**
  String get medicationTypeCapsule;

  /// No description provided for @medicationTypeGel.
  ///
  /// In es, this message translates to:
  /// **'gel/crema'**
  String get medicationTypeGel;

  /// No description provided for @backupShareSubject.
  ///
  /// In es, this message translates to:
  /// **'Copia de seguridad Mediary ({date})'**
  String backupShareSubject(Object date);

  /// No description provided for @backupShareText.
  ///
  /// In es, this message translates to:
  /// **'Copia de seguridad de mis datos de Mediary.'**
  String get backupShareText;

  /// No description provided for @backupInvalidFileFormat.
  ///
  /// In es, this message translates to:
  /// **'Formato de archivo inválido'**
  String get backupInvalidFileFormat;

  /// No description provided for @backupNewerThanApp.
  ///
  /// In es, this message translates to:
  /// **'Versión de backup más reciente que la app. Actualizá la app.'**
  String get backupNewerThanApp;

  /// No description provided for @exportNoData.
  ///
  /// In es, this message translates to:
  /// **'NO DATA'**
  String get exportNoData;

  /// No description provided for @exportSectionSleep.
  ///
  /// In es, this message translates to:
  /// **'Registro de sueño'**
  String get exportSectionSleep;

  /// No description provided for @exportSectionMedications.
  ///
  /// In es, this message translates to:
  /// **'Registro de medicaciones'**
  String get exportSectionMedications;

  /// No description provided for @exportSectionDay.
  ///
  /// In es, this message translates to:
  /// **'Registro del día'**
  String get exportSectionDay;

  /// No description provided for @exportSleepHeaderNight.
  ///
  /// In es, this message translates to:
  /// **'Noche'**
  String get exportSleepHeaderNight;

  /// No description provided for @exportSleepHeaderQuality.
  ///
  /// In es, this message translates to:
  /// **'Calidad'**
  String get exportSleepHeaderQuality;

  /// No description provided for @exportSleepHeaderDescription.
  ///
  /// In es, this message translates to:
  /// **'Descripción'**
  String get exportSleepHeaderDescription;

  /// No description provided for @exportSleepHeaderHours.
  ///
  /// In es, this message translates to:
  /// **'Horas'**
  String get exportSleepHeaderHours;

  /// No description provided for @exportSleepHeaderHow.
  ///
  /// In es, this message translates to:
  /// **'Cómo'**
  String get exportSleepHeaderHow;

  /// No description provided for @exportSleepHeaderComments.
  ///
  /// In es, this message translates to:
  /// **'Comentarios'**
  String get exportSleepHeaderComments;

  /// No description provided for @exportSleepContinuityContinuous.
  ///
  /// In es, this message translates to:
  /// **'Continuo'**
  String get exportSleepContinuityContinuous;

  /// No description provided for @exportSleepContinuityBroken.
  ///
  /// In es, this message translates to:
  /// **'Cortado'**
  String get exportSleepContinuityBroken;

  /// No description provided for @exportSleepQualityVeryBad.
  ///
  /// In es, this message translates to:
  /// **'Muy mal'**
  String get exportSleepQualityVeryBad;

  /// No description provided for @exportSleepQualityBad.
  ///
  /// In es, this message translates to:
  /// **'Mal'**
  String get exportSleepQualityBad;

  /// No description provided for @exportSleepQualityOk.
  ///
  /// In es, this message translates to:
  /// **'Regular'**
  String get exportSleepQualityOk;

  /// No description provided for @exportSleepQualityGood.
  ///
  /// In es, this message translates to:
  /// **'Bien'**
  String get exportSleepQualityGood;

  /// No description provided for @exportSleepQualityVeryGood.
  ///
  /// In es, this message translates to:
  /// **'Muy bien'**
  String get exportSleepQualityVeryGood;

  /// No description provided for @exportMedicationHeaderDay.
  ///
  /// In es, this message translates to:
  /// **'Día'**
  String get exportMedicationHeaderDay;

  /// No description provided for @exportMedicationHeaderTime.
  ///
  /// In es, this message translates to:
  /// **'Hora'**
  String get exportMedicationHeaderTime;

  /// No description provided for @exportMedicationHeaderMedication.
  ///
  /// In es, this message translates to:
  /// **'Medicamento'**
  String get exportMedicationHeaderMedication;

  /// No description provided for @exportMedicationHeaderUnit.
  ///
  /// In es, this message translates to:
  /// **'Unidad'**
  String get exportMedicationHeaderUnit;

  /// No description provided for @exportMedicationHeaderQuantity.
  ///
  /// In es, this message translates to:
  /// **'Cantidad'**
  String get exportMedicationHeaderQuantity;

  /// No description provided for @exportMedicationHeaderNote.
  ///
  /// In es, this message translates to:
  /// **'Nota'**
  String get exportMedicationHeaderNote;

  /// No description provided for @exportMedicationHeaderNotes.
  ///
  /// In es, this message translates to:
  /// **'Notas'**
  String get exportMedicationHeaderNotes;

  /// No description provided for @exportMedicationApplication.
  ///
  /// In es, this message translates to:
  /// **'Aplicación'**
  String get exportMedicationApplication;

  /// No description provided for @exportMedicationFallback.
  ///
  /// In es, this message translates to:
  /// **'Medicamento {id}'**
  String exportMedicationFallback(Object id);

  /// No description provided for @exportShareCsv.
  ///
  /// In es, this message translates to:
  /// **'Exportación CSV'**
  String get exportShareCsv;

  /// No description provided for @exportShareSleepAnalyticsCsv.
  ///
  /// In es, this message translates to:
  /// **'Exportación para analítica: sleep.csv'**
  String get exportShareSleepAnalyticsCsv;

  /// No description provided for @exportShareMedicationsAnalyticsCsv.
  ///
  /// In es, this message translates to:
  /// **'Exportación para analítica: medications.csv'**
  String get exportShareMedicationsAnalyticsCsv;

  /// No description provided for @exportShareExcel.
  ///
  /// In es, this message translates to:
  /// **'Exportación Excel (.xlsx)'**
  String get exportShareExcel;

  /// No description provided for @exportSharePdf.
  ///
  /// In es, this message translates to:
  /// **'Exportación PDF'**
  String get exportSharePdf;

  /// No description provided for @exportFileBaseDiary.
  ///
  /// In es, this message translates to:
  /// **'diario_medicamentos'**
  String get exportFileBaseDiary;

  /// No description provided for @exportFileBaseSleepAnalytics.
  ///
  /// In es, this message translates to:
  /// **'sleep'**
  String get exportFileBaseSleepAnalytics;

  /// No description provided for @exportFileBaseMedicationsAnalytics.
  ///
  /// In es, this message translates to:
  /// **'medications'**
  String get exportFileBaseMedicationsAnalytics;

  /// No description provided for @exportSheetSleep.
  ///
  /// In es, this message translates to:
  /// **'Sueño'**
  String get exportSheetSleep;

  /// No description provided for @exportSheetMedications.
  ///
  /// In es, this message translates to:
  /// **'Medicaciones'**
  String get exportSheetMedications;

  /// No description provided for @exportSheetDay.
  ///
  /// In es, this message translates to:
  /// **'Día'**
  String get exportSheetDay;

  /// No description provided for @exportDayHeaderDate.
  ///
  /// In es, this message translates to:
  /// **'Fecha'**
  String get exportDayHeaderDate;

  /// No description provided for @exportDayHeaderMood.
  ///
  /// In es, this message translates to:
  /// **'Ánimo'**
  String get exportDayHeaderMood;

  /// No description provided for @exportDayHeaderBlocksWalked.
  ///
  /// In es, this message translates to:
  /// **'Cuadras caminadas'**
  String get exportDayHeaderBlocksWalked;

  /// No description provided for @exportDayHeaderWater.
  ///
  /// In es, this message translates to:
  /// **'Agua'**
  String get exportDayHeaderWater;

  /// No description provided for @exportDayHeaderDayNotes.
  ///
  /// In es, this message translates to:
  /// **'Notas del día'**
  String get exportDayHeaderDayNotes;

  /// No description provided for @exportDayHeaderDayNotesAbbrev.
  ///
  /// In es, this message translates to:
  /// **'Notas día'**
  String get exportDayHeaderDayNotesAbbrev;

  /// No description provided for @exportErrorExcelGeneration.
  ///
  /// In es, this message translates to:
  /// **'No se pudo generar el archivo Excel'**
  String get exportErrorExcelGeneration;

  /// No description provided for @exportPdfTitle.
  ///
  /// In es, this message translates to:
  /// **'Diario (Sueño + Medicación + Día)'**
  String get exportPdfTitle;

  /// No description provided for @exportPdfExportedAt.
  ///
  /// In es, this message translates to:
  /// **'Exportado: {timestamp}'**
  String exportPdfExportedAt(Object timestamp);

  /// No description provided for @exportPdfSectionSleep.
  ///
  /// In es, this message translates to:
  /// **'Registro de Sueño'**
  String get exportPdfSectionSleep;

  /// No description provided for @exportPdfSectionMedications.
  ///
  /// In es, this message translates to:
  /// **'Diario de Medicaciones'**
  String get exportPdfSectionMedications;

  /// No description provided for @exportPdfSectionDay.
  ///
  /// In es, this message translates to:
  /// **'Registro del Día'**
  String get exportPdfSectionDay;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
