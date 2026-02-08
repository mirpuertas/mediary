// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get splashSubtitle => 'Tu registro diario de salud';

  @override
  String get commonCancel => 'Cancelar';

  @override
  String get commonContinue => 'Continuar';

  @override
  String get commonNotNow => 'Ahora no';

  @override
  String get commonUnderstood => 'Entendido';

  @override
  String get commonAdd => 'Agregar';

  @override
  String get commonEdit => 'Editar';

  @override
  String get commonSave => 'Guardar';

  @override
  String get commonAccept => 'Aceptar';

  @override
  String get commonCreate => 'Crear';

  @override
  String get commonArchive => 'Archivar';

  @override
  String get commonUnarchive => 'Desarchivar';

  @override
  String get commonDeletePermanently => 'Eliminar definitivamente';

  @override
  String get commonDelete => 'Eliminar';

  @override
  String get commonAll => 'Todo';

  @override
  String get commonNone => 'Nada';

  @override
  String get commonIgnore => 'Ignorar';

  @override
  String get commonActive => 'Activos';

  @override
  String get commonArchived => 'Archivados';

  @override
  String get commonChooseRange => 'Elegir rango';

  @override
  String get commonAreYouSure => '¿Seguro?';

  @override
  String commonErrorWithMessage(Object error) {
    return 'Error: $error';
  }

  @override
  String get commonNotRecorded => 'Sin registrar';

  @override
  String get commonClear => 'Borrar';

  @override
  String get commonDecrease => 'Bajar';

  @override
  String get commonIncrease => 'Subir';

  @override
  String get commonRefresh => 'Actualizar';

  @override
  String get commonRange => 'Rango';

  @override
  String get commonAverage => 'Promedio';

  @override
  String get commonDaysLabel => 'Días';

  @override
  String get commonEveryDay => 'Todos los días';

  @override
  String get commonDetailsOptional => 'Detalles (opcional)';

  @override
  String get commonNoteSaved => 'Nota guardada';

  @override
  String get commonIncomplete => 'Sin completar';

  @override
  String get commonSelect => 'Seleccionar';

  @override
  String get commonNote => 'Nota';

  @override
  String get commonNoteOptionalLabel => 'Nota (opcional)';

  @override
  String get commonTime => 'Hora';

  @override
  String get commonQuantity => 'Cantidad';

  @override
  String get commonNoMedication => 'Sin medicamento';

  @override
  String get commonNoDose => 'Sin dosis';

  @override
  String get commonNoDoseWithDash => 'Sin dosis (—)';

  @override
  String get commonSleep => 'Sueño';

  @override
  String get commonMood => 'Ánimo';

  @override
  String get commonHabits => 'Hábitos';

  @override
  String get commonMedication => 'Medicación';

  @override
  String get commonMedications => 'Medicamentos';

  @override
  String get commonReminders => 'Recordatorios';

  @override
  String get commonGroup => 'Grupo';

  @override
  String get commonExactAlarm => '⏰ Alarma exacta';

  @override
  String get commonDay => 'Día';

  @override
  String get commonNoNotes => 'Sin notas';

  @override
  String get permissionsNotificationsDisabledTitle =>
      'Notificaciones desactivadas';

  @override
  String get permissionsNotificationsDisabledBody =>
      'Para que los recordatorios funcionen, activa las notificaciones en Ajustes del sistema.\n\nEsto permite mostrar avisos en la hora programada.';

  @override
  String get permissionsExactAlarmsTitle => 'Permitir alarmas exactas';

  @override
  String get permissionsExactAlarmsBody =>
      'Este recordatorio necesita sonar a la hora exacta.\n\nActiva \"Alarmas y recordatorios\" para esta app. Si no lo activas, el aviso puede llegar con demora.';

  @override
  String get permissionsBatteryRecommendationTitle =>
      'Recomendación de batería';

  @override
  String permissionsBatteryRecommendationBody(Object manufacturer) {
    return 'Este equipo ($manufacturer) a veces restringe apps en segundo plano.\n\nSi tus notificaciones no llegan, desactiva la optimización de batería para esta app:\n\nAjustes → Batería → Sin restricciones / No optimizar';
  }

  @override
  String get notificationsDailyChannelName => 'Recordatorio diario';

  @override
  String get notificationsDailyChannelDescription =>
      'Recordatorio para registrar el sueño diariamente';

  @override
  String get notificationsMedicationChannelName =>
      'Recordatorios de medicación';

  @override
  String get notificationsMedicationChannelDescription =>
      'Alarmas para tomar medicamentos';

  @override
  String get notificationsDailySleepTitle => '🌙 Registro de sueño';

  @override
  String get notificationsDailySleepBody =>
      '¿Cómo dormiste anoche? Registra tu sueño';

  @override
  String get notificationsTestTitle => 'Notificación de prueba';

  @override
  String get notificationsTestBody =>
      'Esta es una notificación de prueba. Si la ves, ¡funciona!';

  @override
  String get notificationsMedicationTitle => '💊 Recordatorio de medicación';

  @override
  String get notificationsSnoozedTitle => '💊 Recordatorio (pospuesto)';

  @override
  String get notificationsTapToLogBody => 'Tocar para registrar';

  @override
  String get notificationsMedicationFallbackName => 'medicamento';

  @override
  String notificationsTakeMedicationBody(Object name) {
    return 'Tomar $name';
  }

  @override
  String notificationsTakeMedicationsBody(Object names) {
    return 'Tomar: $names';
  }

  @override
  String notificationsMedicationGroupTitle(Object groupName) {
    return '💊 $groupName';
  }

  @override
  String get notificationsActionChoose => '📝 Elegir';

  @override
  String get notificationsActionSnooze5min => '⏰ Posponer 5 min';

  @override
  String get notificationsActionCompleteTaken => '✅ Hecho';

  @override
  String get notificationsActionCompleteAllTaken => '✅ Hecho';

  @override
  String get notificationsAutoLogged => 'Registrado automáticamente';

  @override
  String get notificationsAutoLoggedWithApplication =>
      'Registrado automáticamente (aplicación)';

  @override
  String get notificationsErrorReminderMissingId =>
      'El recordatorio debe tener un ID de base de datos';

  @override
  String get notificationsErrorGroupReminderMissingId =>
      'El recordatorio de grupo debe tener un ID de DB';

  @override
  String notificationsErrorProcessing(Object error) {
    return 'Error al procesar notificación: $error';
  }

  @override
  String get settingsTitle => 'Configuración';

  @override
  String get settingsSectionAppearance => 'Apariencia';

  @override
  String get settingsSectionSecurity => 'Seguridad';

  @override
  String get settingsSectionReminders => 'Recordatorios';

  @override
  String get settingsSectionExportData => 'Exportar Datos';

  @override
  String get settingsSectionExportAnalytics => 'Exportar para analítica';

  @override
  String get settingsSectionDataBackups => 'Datos y Copias de Seguridad';

  @override
  String get settingsSectionInfo => 'Información';

  @override
  String get settingsSectionDanger => 'Zona de peligro';

  @override
  String get settingsDarkModeTitle => 'Modo oscuro';

  @override
  String get settingsDarkModeUsingSystem => 'Usando el tema del sistema';

  @override
  String get commonDark => 'Oscuro';

  @override
  String get commonLight => 'Claro';

  @override
  String get settingsPinLockTitle => 'Bloqueo con PIN';

  @override
  String get settingsPinLockSubtitle => 'Pide PIN para entrar a la app';

  @override
  String get settingsChangePinTitle => 'Cambiar PIN';

  @override
  String get settingsChangePinSubtitle => 'PIN de 4 dígitos';

  @override
  String get settingsPinUpdated => 'PIN actualizado';

  @override
  String get settingsLockOnReturnTitle => 'Bloquear al volver';

  @override
  String get settingsLockOnReturnDialogTitle =>
      'Bloquear al volver de background';

  @override
  String get settingsLockTimeoutImmediateBack => 'Inmediato al volver';

  @override
  String get settingsLockTimeout30Seconds => '30 segundos';

  @override
  String get settingsLockTimeout2Minutes => '2 minutos';

  @override
  String get settingsLockTimeout5Minutes => '5 minutos';

  @override
  String get settingsLockTimeoutImmediate => 'Inmediato';

  @override
  String settingsLockTimeoutSeconds(Object seconds) {
    return '${seconds}s';
  }

  @override
  String get settingsBiometricTitle => 'Autenticación biométrica';

  @override
  String get settingsBiometricAvailableSubtitle =>
      'Usar huella digital o Face ID';

  @override
  String get settingsBiometricUnavailableSubtitle =>
      'No disponible en este dispositivo';

  @override
  String get settingsBiometricNotSupported =>
      'Tu dispositivo no soporta autenticación biométrica';

  @override
  String get settingsDbEncryptionTitle => 'Cifrado de base de datos';

  @override
  String get settingsDbEncryptionSubtitle =>
      'Protege tus datos locales si te roban el teléfono';

  @override
  String get settingsDbEncryptionStatusOn => 'Activado';

  @override
  String get settingsDbEncryptionStatusOff => 'Desactivado';

  @override
  String get settingsDbEncryptionStatusUnknown => 'Desconocido';

  @override
  String get settingsDbEncryptionRecommendAppLockTitle =>
      'Recomendado: activar Bloqueo de app';

  @override
  String get settingsDbEncryptionRecommendAppLockBody =>
      'El cifrado protege el archivo de la DB, pero si el teléfono está desbloqueado cualquiera podría abrir la app. El Bloqueo agrega una barrera extra.';

  @override
  String get settingsDbEncryptionEnableAppLockAction => 'Activar';

  @override
  String get settingsDisableAppLockWarningTitle =>
      '¿Desactivar el bloqueo de app?';

  @override
  String get settingsDisableAppLockWarningBody =>
      'Tu base de datos está cifrada, pero desactivar el bloqueo puede exponer tus datos a cualquiera que tenga tu teléfono desbloqueado.';

  @override
  String get settingsDisableAppLockWarningDisable => 'Desactivar';

  @override
  String get settingsNotificationsPermissionTitle =>
      'Permiso de notificaciones';

  @override
  String get settingsNotificationsPermissionBody =>
      'Las notificaciones están desactivadas. Para activarlas, ve a Configuración de la aplicación.';

  @override
  String get settingsOpenSettings => 'Abrir configuración';

  @override
  String get settingsNotificationsPermissionDisabledTitle =>
      'Permiso de notificaciones desactivado';

  @override
  String get settingsNotificationsPermissionDisabledBody =>
      'Los recordatorios no funcionarán hasta que actives el permiso.';

  @override
  String get settingsEnableNotificationsPermissionTitle =>
      'Activar permiso de notificaciones';

  @override
  String get settingsEnableNotificationsPermissionSubtitle =>
      'Abrir configuración del sistema';

  @override
  String get settingsExactAlarmsPermissionDisabledTitle =>
      'Permiso de alarmas exactas desactivado';

  @override
  String get settingsExactAlarmsPermissionDisabledBody =>
      'El recordatorio de sueño necesita este permiso para sonar a tiempo en Android 12+.';

  @override
  String get settingsAllowExactAlarmsTitle => 'Permitir alarmas exactas';

  @override
  String get settingsAllowExactAlarmsSubtitle =>
      'Requerido para recordatorios precisos';

  @override
  String get settingsDailyReminderTitle => 'Recordatorio diario';

  @override
  String get settingsDailyReminderSubtitle =>
      'Notificación para registrar tu sueño';

  @override
  String get settingsSectionGeneral => 'General';

  @override
  String get settingsLanguageTitle => 'Idioma';

  @override
  String get settingsLanguageSystem => 'Automático (sistema)';

  @override
  String get settingsLanguageSpanish => 'Español';

  @override
  String get settingsLanguageEnglish => 'English';

  @override
  String get settingsReminderTimeTitle => 'Hora del recordatorio';

  @override
  String settingsReminderSetFor(Object time) {
    return 'Recordatorio configurado para las $time';
  }

  @override
  String get settingsExportDialogTitle => 'Exportar datos';

  @override
  String get settingsExportDialogBody =>
      '¿Quieres exportar todos los datos o elegir un rango de fechas?';

  @override
  String get settingsExportSelectRangeHelpText =>
      'Selecciona el rango a exportar';

  @override
  String get settingsExportPdfButton => 'Exportar a PDF';

  @override
  String get settingsExportExcelButton => 'Exportar a Excel (.xlsx)';

  @override
  String get settingsExportNoData =>
      'No hay datos para exportar. Registra algunos días primero.';

  @override
  String get settingsExportSleepRecordsTitle => 'Registros de sueño';

  @override
  String get settingsExportMedicationEventsTitle => 'Tomas registradas';

  @override
  String get settingsExportDateRangeTitle => 'Rango de fechas';

  @override
  String settingsExportError(Object type, Object error) {
    return 'Error al exportar $type: $error';
  }

  @override
  String get settingsBackupCreateTitle => 'Crear copia de seguridad';

  @override
  String get settingsBackupCreateSubtitle =>
      'Exportar archivo para reinstalación';

  @override
  String get settingsBackupRestoreTitle => 'Restaurar copia de seguridad';

  @override
  String get settingsBackupRestoreSubtitle => 'Importar archivo previo';

  @override
  String settingsBackupCreateError(Object error) {
    return 'Error al crear backup: $error';
  }

  @override
  String get settingsBackupRestoreConfirmTitle =>
      'Restaurar copia de seguridad';

  @override
  String get settingsBackupRestoreConfirmBody =>
      '⚠️ ALERTA: Esto eliminará todos los datos actuales y los reemplazará con los del archivo de respaldo.\n\n¿Deseas continuar?';

  @override
  String get settingsBackupRestoreConfirmYes => 'Sí, restaurar';

  @override
  String get backupPasswordTitleCreate => 'Cifrar backup (opcional)';

  @override
  String get backupPasswordHintCreate => 'Deja vacío para exportar sin cifrar.';

  @override
  String get backupPasswordTitleRestore => 'Contraseña del backup';

  @override
  String get backupPasswordHintRestore =>
      'Ingresa la contraseña usada al crear el backup.';

  @override
  String get backupPasswordLabel => 'Contraseña';

  @override
  String get backupPasswordConfirmLabel => 'Confirmar contraseña';

  @override
  String get backupPasswordMismatch => 'Las contraseñas no coinciden.';

  @override
  String get backupPasswordRequired => 'La contraseña es obligatoria.';

  @override
  String get backupPasswordInvalid => 'Contraseña incorrecta.';

  @override
  String get settingsBackupRestoreCompleted =>
      'Restauración completada. Reiniciando...';

  @override
  String settingsBackupRestoreError(Object error) {
    return 'Error al restaurar: $error';
  }

  @override
  String get settingsAboutTitle => 'Acerca de';

  @override
  String get settingsAboutSubtitle => 'Mediary v2.0.0';

  @override
  String get settingsPrivacyInfoTitle => 'Privacidad';

  @override
  String get settingsPrivacyInfoSubtitle =>
      'Todos tus datos se guardan localmente en tu dispositivo';

  @override
  String get settingsWipeAllTitle => 'Borrado total';

  @override
  String get settingsWipeAllSubtitle =>
      'Eliminar todos los datos del dispositivo';

  @override
  String get settingsWipeAllDialogBody =>
      'Esto eliminará TODOS tus datos guardados en el dispositivo:';

  @override
  String get settingsWipeAllItemMedications =>
      '• Medicamentos (activos y archivados)';

  @override
  String get settingsWipeAllItemMedicationReminders =>
      '• Recordatorios de medicación';

  @override
  String get settingsWipeAllItemIntakes => '• Tomas registradas';

  @override
  String get settingsWipeAllItemSleepEntries => '• Registros de sueño';

  @override
  String get settingsWipeAllItemAppSettings =>
      '• Configuración y estado de la app';

  @override
  String get settingsWipeAllAcknowledge =>
      'Entiendo que esta acción es irreversible';

  @override
  String get settingsWipeAllSuccess => 'Datos eliminados correctamente';

  @override
  String settingsWipeAllError(Object error) {
    return 'Error al borrar datos: $error';
  }

  @override
  String get medicationsTitle => 'Medicamentos';

  @override
  String get medicationsGroupButton => 'Agrupar';

  @override
  String get medicationsEmptyTitle => 'No hay medicamentos';

  @override
  String get medicationsEmptySubtitle => 'Agrega uno con el botón +';

  @override
  String medicationsArchivedSectionTitle(Object count) {
    return 'Archivados ($count)';
  }

  @override
  String get medicationsUnarchiveButton => 'Reactivar';

  @override
  String get medicationsAddButton => 'Agregar';

  @override
  String get medicationsDialogAddTitle => 'Agregar medicamento';

  @override
  String get medicationsDialogEditTitle => 'Editar medicamento';

  @override
  String get medicationsGenericNameLabel => 'Nombre genérico *';

  @override
  String get medicationsGenericNameHint => 'Ej: Ibuprofeno';

  @override
  String get medicationsGenericNameRequired =>
      'El nombre genérico es obligatorio';

  @override
  String get medicationsBrandNameLabel => 'Nombre comercial (opcional)';

  @override
  String get medicationsBrandNameHint => 'Ej: Ibupirac';

  @override
  String get medicationsBaseUnitLabel => 'Unidad base *';

  @override
  String get medicationsBaseUnitHint => 'Ej: 1mg, 2mg, 10ml';

  @override
  String get medicationsBaseUnitRequired => 'La unidad base es obligatoria';

  @override
  String get medicationsTypeLabel => 'Tipo *';

  @override
  String get medicationsDefaultDoseOptional => 'Dosis habitual (opcional)';

  @override
  String get medicationsDefaultDoseQtyDrops => 'Cantidad habitual (gotas)';

  @override
  String get medicationsDefaultDoseQtyCapsules =>
      'Cantidad habitual (cápsulas)';

  @override
  String get medicationsDefaultDoseQtyLabel => 'Cantidad habitual';

  @override
  String get medicationsDefaultDosePickerTitle => 'Dosis habitual';

  @override
  String get medicationsDefaultDoseCustom => 'Personalizada…';

  @override
  String get medicationsDefaultDoseHelper =>
      'Esta cantidad se precargará al registrar tomas';

  @override
  String get medicationsSavedAdded => 'Medicamento agregado';

  @override
  String get medicationsSavedUpdated => 'Medicamento actualizado';

  @override
  String get medicationsDuplicateWarning =>
      'Ya existe una medicación igual cargada. Puedes editarla desde la lista.';

  @override
  String medicationsDbError(Object error) {
    return 'Error de base de datos: $error';
  }

  @override
  String medicationsError(Object error) {
    return 'Error: $error';
  }

  @override
  String get medicationsManageTitle => 'Gestionar medicamento';

  @override
  String get medicationsManageBody =>
      'Elige qué quieres hacer:\n\n• Archivar: no borra registros históricos y pausa recordatorios.\n• Eliminar definitivamente: borra el medicamento y todos sus registros asociados.';

  @override
  String get medicationsArchivedSnack => 'Medicamento archivado';

  @override
  String medicationsArchiveError(Object error) {
    return 'Error al archivar: $error';
  }

  @override
  String get medicationsHardDeleteTitle => 'Eliminar definitivamente';

  @override
  String medicationsHardDeleteBody(Object name) {
    return 'Esta acción NO se puede deshacer.\n\nSe eliminará:\n• $name\n• todos los registros históricos asociados\n• recordatorios\n\n¿Quieres continuar?';
  }

  @override
  String get medicationsDeletedSnack => 'Medicamento eliminado definitivamente';

  @override
  String medicationsDeleteError(Object error) {
    return 'Error al eliminar: $error';
  }

  @override
  String get medicationsUnarchiveTitle => 'Reactivar medicamento';

  @override
  String get medicationsUnarchiveBody =>
      '¿Reactivar este medicamento?\n\nVolverá a aparecer en la lista y en los selectores.\nLos recordatorios que tuviera configurados se reprogramarán.';

  @override
  String get medicationsUnarchivedSnack => 'Medicamento reactivado';

  @override
  String get medicationsRemindersTitle => 'Recordatorios';

  @override
  String get medicationsNoReminders => 'Sin recordatorios';

  @override
  String get medicationsTooltipViewReminders => 'Ver recordatorios';

  @override
  String get medicationsTooltipAdjustDose => 'Ajustar dosis';

  @override
  String get medicationsTooltipArchiveDelete => 'Archivar / Eliminar';

  @override
  String get medicationsDeleteReminderTitle => 'Eliminar recordatorio';

  @override
  String get medicationsDeleteReminderBody =>
      '¿Estás seguro de eliminar este recordatorio?';

  @override
  String get medicationsReminderDeletedSnack => '🗑️ Recordatorio eliminado';

  @override
  String get fractionPickerTitle => 'Cantidad';

  @override
  String get fractionPickerWholeLabel => 'Enteros';

  @override
  String get fractionPickerFractionLabel => 'Fracción';

  @override
  String get fractionPickerNoFractionSelected => 'Sin fracción';

  @override
  String get fractionPickerPreviewLabel => 'Vista previa:';

  @override
  String medicationDetailLoadError(Object error) {
    return '❌ Error al cargar recordatorios: $error';
  }

  @override
  String get medicationDetailDeleteReminderTitle => 'Eliminar recordatorio';

  @override
  String medicationDetailDeleteReminderBody(Object time) {
    return '¿Eliminar el recordatorio de las $time?';
  }

  @override
  String get medicationDetailReminderDeleted => '✅ Recordatorio eliminado';

  @override
  String medicationDetailDeleteError(Object error) {
    return '❌ Error: $error';
  }

  @override
  String medicationDetailDaysLabel(Object days) {
    return 'Días: $days';
  }

  @override
  String get medicationDetailSchedulesTitle => 'Horarios de toma';

  @override
  String medicationDetailSchedulesCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count horarios',
      one: '1 horario',
    );
    return '$_temp0';
  }

  @override
  String get medicationDetailNoRemindersTitle =>
      'Sin recordatorios configurados';

  @override
  String get medicationDetailNoRemindersSubtitle =>
      'Presiona el botón + para agregar uno';

  @override
  String get medicationDetailAddSchedule => 'Agregar horario';

  @override
  String get medicationGroupsTitle => 'Grupos de medicación';

  @override
  String get medicationGroupsEmpty => 'Todavía no tenés grupos';

  @override
  String get medicationGroupsNewGroupTitle => 'Nuevo grupo';

  @override
  String get medicationGroupsNameLabel => 'Nombre';

  @override
  String get medicationGroupsNameHint => 'Ej: Noche';

  @override
  String get medicationGroupDetailGroupNotFound => 'Grupo no encontrado';

  @override
  String get medicationGroupDetailMembersDialogTitle =>
      'Medicamentos del grupo';

  @override
  String get medicationGroupDetailNewReminderTitle => '➕ Nuevo recordatorio';

  @override
  String get medicationGroupDetailEditReminderTitle => '✏️ Editar recordatorio';

  @override
  String medicationGroupDetailTimeLabel(Object time) {
    return 'Hora: $time';
  }

  @override
  String get medicationGroupDetailExactAlarmTitle =>
      'Este grupo requiere precisión (como despertador)';

  @override
  String get medicationGroupDetailExactAlarmSubtitle =>
      'Suena aunque el celular esté en reposo. Necesita permisos especiales.';

  @override
  String get medicationGroupDetailDndWarning =>
      '⚠️ Si usas \"No Molestar\", este recordatorio puede no sonar. Para que funcione como despertador, asegurate de permitir alarmas para esta app en Ajustes de Sonido.';

  @override
  String get medicationGroupDetailDeleteReminderTitle =>
      'Eliminar recordatorio';

  @override
  String get medicationGroupDetailDeleteGroupTitle => 'Eliminar grupo';

  @override
  String get medicationGroupDetailDeleteGroupBody =>
      'Se eliminarán también sus recordatorios.';

  @override
  String get medicationGroupDetailDeleteGroupTooltip => 'Eliminar grupo';

  @override
  String get medicationGroupDetailNoMembers => 'Sin medicamentos asignados';

  @override
  String get medicationGroupDetailNoReminders => 'Sin recordatorios';

  @override
  String get addReminderSelectMedicationError => '❌ Seleccioná un medicamento';

  @override
  String get addReminderSelectAtLeastOneDayError =>
      '❌ Seleccioná al menos un día';

  @override
  String addReminderCreated(Object icon) {
    return '$icon Recordatorio creado';
  }

  @override
  String addReminderUpdated(Object icon) {
    return '$icon Recordatorio actualizado';
  }

  @override
  String get addReminderTitleNew => '➕ Nuevo recordatorio';

  @override
  String get addReminderTitleEdit => '✏️ Editar recordatorio';

  @override
  String get addReminderMedicationLabel => 'Medicamento';

  @override
  String get addReminderTimeTitle => 'Hora del recordatorio';

  @override
  String get addReminderDaysOfWeekTitle => 'Días de la semana';

  @override
  String get addReminderNoteHint => 'Ej: Después de comer, con agua...';

  @override
  String get addReminderExactAlarmTitle =>
      'Este medicamento requiere precisión (como despertador)';

  @override
  String get addReminderExactAlarmSubtitle =>
      'Suena aunque el celular esté en reposo. Necesita permisos especiales.';

  @override
  String get addReminderDndWarning =>
      '⚠️ Si usas \"No Molestar\", este recordatorio puede no sonar. Para que funcione como despertador, asegurate de permitir alarmas para esta app en Ajustes de Sonido.';

  @override
  String get addReminderSaveButton => 'Guardar recordatorio';

  @override
  String get addReminderUpdateButton => 'Actualizar recordatorio';

  @override
  String get quickIntakeSelectAtLeastOneMedication =>
      'Selecciona al menos un medicamento';

  @override
  String get quickIntakeAutoLoggedWithoutDose =>
      'Registrado automáticamente (sin dosis)';

  @override
  String quickIntakeMissingDefaultDose(Object names) {
    return 'Sin dosis por defecto: $names';
  }

  @override
  String get quickIntakeSaved => '✅ Toma registrada';

  @override
  String get quickIntakeMedicationNotFound => 'Medicamento no encontrado';

  @override
  String quickIntakeSnoozed(Object minutes) {
    return '⏰ Recordatorio pospuesto $minutes min';
  }

  @override
  String quickIntakeAppBarGroup(Object groupName) {
    return '💊 $groupName';
  }

  @override
  String get quickIntakeDefaultGroupName => 'Grupo de medicación';

  @override
  String get quickIntakeAppBarSingle => '💊 Recordatorio';

  @override
  String get quickIntakeNoActiveMeds =>
      'No hay medicamentos activos para este recordatorio';

  @override
  String quickIntakeUnitLabel(Object unit) {
    return 'Unidad: $unit';
  }

  @override
  String get quickIntakeWhatToDo => '¿Qué quieres hacer?';

  @override
  String get quickIntakeIHaveTaken => 'Ya tomé';

  @override
  String get quickIntakeSnooze10m => 'Posponer 10 minutos';

  @override
  String get quickIntakeSnooze1h => 'Posponer 1 hora';

  @override
  String get quickIntakeChooseTaken => 'Elige cuáles tomaste';

  @override
  String quickIntakeSelectedCount(Object selected, Object total) {
    return '$selected/$total seleccionados';
  }

  @override
  String get quickIntakeSaveSelectedClose => 'Guardar seleccionadas (cerrar)';

  @override
  String quickIntakeRemainingHint(Object remaining) {
    return 'Las $remaining restantes no se vuelven a avisar automáticamente. Si quieres que te notifique más tarde, usa “Posponer restantes”.';
  }

  @override
  String get quickIntakeSnoozeRemaining10m => 'Posponer restantes 10m';

  @override
  String get quickIntakeSnoozeRemaining1h => 'Posponer restantes 1h';

  @override
  String get dailyEntryTitle => 'Registrar tu día';

  @override
  String get dailyEntryTabDayOptional => 'Día (opcional)';

  @override
  String get dailyEntryTabSleepOptional => 'Sueño (opcional)';

  @override
  String get dailyEntryTabMedication => 'Medicación';

  @override
  String get dailyEntryMedicationAdded => 'Medicación agregada';

  @override
  String get dailyEntrySaveError => 'Error al guardar';

  @override
  String dailyEntrySaveErrorWithMessage(Object error) {
    return 'Error al guardar: $error';
  }

  @override
  String get dailyEntrySaveSuccess => 'Registro guardado correctamente';

  @override
  String dayTabHeader(Object date) {
    return 'Día $date';
  }

  @override
  String get dayTabOptionalHint =>
      'Opcional. Si no quieres, puedes dejar todo vacío.';

  @override
  String get dayTabMoodTitle => 'Ánimo';

  @override
  String get dayTabMoodQuestion => 'Cómo te sientes hoy?';

  @override
  String get dayTabMoodVeryBad => 'Muy mal';

  @override
  String get dayTabMoodBad => 'Mal';

  @override
  String get dayTabMoodOk => 'Regular';

  @override
  String get dayTabMoodGood => 'Bien';

  @override
  String get dayTabMoodVeryGood => 'Muy bien';

  @override
  String get dayTabDayNotesTitle => 'Notas del día';

  @override
  String get dayTabDayNotesHint => 'Algo para recordar sobre el día...';

  @override
  String get dayTabHabitsTitle => 'Hábitos';

  @override
  String get dayTabWaterTitle => 'Agua';

  @override
  String dayTabWaterCount(Object count) {
    return 'Vasos: $count';
  }

  @override
  String dayTabWaterCountLabel(Object count) {
    return 'Agua: $count';
  }

  @override
  String get dayTabBlocksWalkedTitle => 'Cuadras caminadas';

  @override
  String get dayTabBlocksWalkedHint => 'Ej: 12';

  @override
  String get dayTabBlocksWalkedHelper => '0–1000 aprox.';

  @override
  String sleepTabNightOf(Object date) {
    return 'Noche del $date';
  }

  @override
  String sleepTabNightRange(Object startDay, Object endDay) {
    return '($startDay→$endDay)';
  }

  @override
  String get sleepTabHowDidYouSleep => 'Cómo dormiste?';

  @override
  String get sleepTabHowLongDidYouSleep => '¿Cuánto dormiste?';

  @override
  String get sleepTabHours => 'Horas';

  @override
  String get sleepTabMinutes => 'Minutos';

  @override
  String get sleepTabHowWasSleep => '¿Cómo fue el sueño?';

  @override
  String get sleepTabContinuityStraight => 'De corrido';

  @override
  String get sleepTabContinuityBroken => 'Cortado';

  @override
  String get sleepTabOptionalHint => 'Opcional: si no quieres, déjalo vacío.';

  @override
  String get sleepTabGeneralNotesOptional => 'Notas generales (opcional)';

  @override
  String get sleepTabNotesHint => 'Algo para recordar mañana...';

  @override
  String get medicationTabExpandAll => 'Expandir todo';

  @override
  String get medicationTabCollapseAll => 'Contraer todo';

  @override
  String get medicationTabEmptyTitle => 'Sin medicamentos registrados';

  @override
  String get medicationTabEmptySubtitle => 'Presiona el botón + para agregar';

  @override
  String get medicationTabAddMedication => 'Agregar medicación';

  @override
  String get medicationTabDoseApplication => 'Aplicación';

  @override
  String medicationTabDropsDose(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count gotas',
      one: '1 gota',
    );
    return '$_temp0';
  }

  @override
  String medicationTabCapsulesDose(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count cápsulas',
      one: '1 cápsula',
    );
    return '$_temp0';
  }

  @override
  String get medicationTabCustomQuantityTitle => 'Cantidad personalizada';

  @override
  String get medicationTabMedicationLabel => 'Medicamento';

  @override
  String get medicationTabAddAnotherMedication => '+ Agregar otro';

  @override
  String get medicationTabDoseDropsLabel => 'Cantidad de gotas';

  @override
  String get medicationTabDoseCapsulesLabel => 'Cantidad de cápsulas';

  @override
  String get medicationTabNoteOptionalLabel => 'Nota (opcional)';

  @override
  String get medicationTabNoteHint => 'Efectos, contexto...';

  @override
  String get homeTitle => 'Diario';

  @override
  String get homeTooltipSummary => 'Resumen';

  @override
  String get homeTooltipMedications => 'Medicamentos';

  @override
  String get homeTooltipSettings => 'Ajustes';

  @override
  String get homeCalendarViewTooltip => 'Vista';

  @override
  String get homeCalendarFilterTooltip => 'Filtrar';

  @override
  String get homeCalendarMonth => 'Mes';

  @override
  String get homeCalendarTwoWeeks => '2 semanas';

  @override
  String get homeCalendarWeek => 'Semana';

  @override
  String get homeRemindersTodayTitle => 'Recordatorios de hoy';

  @override
  String get homeRemindersSnoozedHeader => 'Pospuestos';

  @override
  String get summaryTitle => 'Resumen';

  @override
  String get summaryLoadError => 'No se pudo cargar el resumen.';

  @override
  String summaryLastNDays(Object days) {
    return 'Últimos $days días';
  }

  @override
  String get summaryTabStats => 'Estadísticas';

  @override
  String get summaryTabPatterns => 'Patrones';

  @override
  String get summaryViewDayByDay => 'Ver detalle día por día →';

  @override
  String get summaryPatternsRangeHint =>
      'Relaciones disponibles en 30 y 90 días.';

  @override
  String get summarySleepAverageQuality => 'Promedio de calidad de sueño';

  @override
  String get summarySleepNoRecords => 'Sin registros de sueño en este período';

  @override
  String get summaryMoodNoRecords => 'Sin registros de ánimo en este período';

  @override
  String get summaryMoodMostFrequentPrefix => 'El ánimo más frecuente fue';

  @override
  String summaryMedicationDaysWith(Object withCount, Object total) {
    return 'Días con medicación registrada: $withCount de $total';
  }

  @override
  String summaryDaysWithoutRecord(Object days) {
    return 'Días sin registro: $days';
  }

  @override
  String get summaryPatternsStreaks => 'Rachas';

  @override
  String get summaryPatternsGoals => 'Metas';

  @override
  String get summaryPatternsInsights => 'Insights';

  @override
  String summaryStreakCurrent(Object value) {
    return 'Actual: $value';
  }

  @override
  String summaryStreakBest(Object value) {
    return 'Mejor: $value';
  }

  @override
  String summaryGoalDaysProgress(Object achieved, Object total) {
    return '$achieved/$total días';
  }

  @override
  String get summaryInsightsDisclaimer =>
      'Son comparaciones dentro del período (no implican causalidad).';

  @override
  String get summaryInsightStrengthNotEnoughData => 'Sin datos';

  @override
  String get summaryInsightStrengthWeak => 'Débil';

  @override
  String get summaryInsightStrengthPreliminary => 'Preliminar';

  @override
  String get summaryInsightStrengthModerate => 'Moderada';

  @override
  String get summaryInsightStrengthStrong => 'Fuerte';

  @override
  String summaryDaysWithRecordLabel(Object rangeDays) {
    return 'Días con registro (de $rangeDays):';
  }

  @override
  String summaryAvgShortWithValue(Object value) {
    return 'Prom: $value';
  }

  @override
  String summaryBlocksWalkedDays(Object days) {
    return 'Cuadras caminadas: $days';
  }

  @override
  String summaryWaterDays(Object days) {
    return '💧 Agua: $days';
  }

  @override
  String get summarySleepTrendHigherAtEnd =>
      'La calidad de sueño fue más alta hacia el final del período';

  @override
  String get summarySleepTrendHigherAtStart =>
      'La calidad de sueño fue más alta hacia el inicio del período';

  @override
  String get summaryPatternWaterGoal => '💧 Agua ≥6';

  @override
  String get summaryPatternSleepGoal => '🛏️ Sueño ≥4';

  @override
  String get summaryPatternMoodGoal => '😊 Ánimo ≥4';

  @override
  String get summaryMetricSleep => 'sueño';

  @override
  String get summaryMetricMood => 'ánimo';

  @override
  String get summaryMetricWater => 'agua';

  @override
  String get summaryInsightTitleSleepMood => 'Sueño ↔ Ánimo';

  @override
  String get summaryInsightTitleWaterMood => 'Agua ↔ Ánimo';

  @override
  String get summaryInsightDirHigher => 'más alto';

  @override
  String get summaryInsightDirLower => 'más bajo';

  @override
  String summaryInsightBaseMinPairs(Object pairCount, Object minPairs) {
    return 'Base: $pairCount días (mínimo: $minPairs)';
  }

  @override
  String get summaryInsightMessageMinPairs =>
      'Preliminar: hay pocos días con ambos datos cargados para comparar.';

  @override
  String summaryInsightBaseNoGroup(Object pairCount) {
    return 'Base: $pairCount días';
  }

  @override
  String get summaryInsightMessageNoGroup =>
      'Preliminar: no hay suficientes datos para agrupar.';

  @override
  String summaryInsightGroupHintShort(Object xLabel) {
    return 'días con más $xLabel vs menos $xLabel';
  }

  @override
  String summaryInsightGroupHintLong(Object xLabel) {
    return 'mejores vs peores ~30% (según $xLabel)';
  }

  @override
  String summaryInsightBaseTopBottom(
    Object pairCount,
    Object groupHint,
    Object g,
  ) {
    return 'Base: $pairCount días · $groupHint · grupos: $g y $g';
  }

  @override
  String summaryInsightMessageTopBottom(
    Object xLabel,
    Object yLabel,
    Object dirWord,
    Object delta,
  ) {
    return 'En tus días con $xLabel más alto, $yLabel tiende a ser $dirWord (Δ $delta).';
  }

  @override
  String get selectedDayDeleteTooltip => 'Eliminar registro del día';

  @override
  String get selectedDayDeleteDialogTitle => 'Eliminar registro';

  @override
  String get selectedDayDeleteDialogBody =>
      '¿Eliminar el registro COMPLETO de este día?\n\nSe borrarán: sueño, medicación (tomas), ánimo y notas.';

  @override
  String selectedDayChipSleepWithQuality(Object quality) {
    return 'Sueño: $quality/5';
  }

  @override
  String get selectedDayChipSleepEmpty => 'Sueño: —';

  @override
  String selectedDayChipMedicationWithCount(Object count) {
    return 'Medicación: $count';
  }

  @override
  String get selectedDayChipMedicationEmpty => 'Medicación: —';

  @override
  String get selectedDayNoMoodRecorded => 'Sin ánimo registrado';

  @override
  String get selectedDayNoWater => 'Sin agua';

  @override
  String selectedDayBlocksWalkedValue(Object value) {
    return 'Cuadras caminadas: $value';
  }

  @override
  String get selectedDayNoBlocksWalked => 'Sin cuadras caminadas registradas';

  @override
  String get selectedDayNoSleepRecord => 'Sin registro de sueño';

  @override
  String get selectedDayMedicationsTitle => 'Medicaciones';

  @override
  String get selectedDayNoMedications => 'Sin medicaciones registradas';

  @override
  String selectedDayMedicationFallbackName(Object id) {
    return 'Medicamento $id';
  }

  @override
  String get selectedDayMedicationQtyLabelRecord => 'Registro';

  @override
  String get commonBack => 'Atrás';

  @override
  String get commonNext => 'Siguiente';

  @override
  String get commonSkip => 'Omitir';

  @override
  String get commonSaving => 'Guardando…';

  @override
  String get welcomeStart => 'Comenzar';

  @override
  String get welcomePage1Title => 'Tu registro diario, sin esfuerzo';

  @override
  String get welcomePage1Body =>
      'Anota medicación, sueño y notas del día en pocos segundos.';

  @override
  String get welcomePage2Title => 'Recordatorios, si los necesitas';

  @override
  String get welcomePage2Body =>
      'Programa alarmas para tus tomas o úsalo solo para registrar.';

  @override
  String get welcomePage3Title => 'Tu historial en calendario';

  @override
  String get welcomePage3Body =>
      'Vas a poder ver días registrados y detectar patrones con el tiempo.';

  @override
  String get welcomePage4Title => 'Todo queda en tu teléfono';

  @override
  String get welcomePage4Body =>
      'Se guarda localmente. Sin cuentas, sin servidores, sin internet.';

  @override
  String get appLockBiometricReason => 'Autenticación requerida';

  @override
  String get setPinTitleCreate => 'Crear PIN';

  @override
  String get setPinTitleChange => 'Cambiar PIN';

  @override
  String get setPinEnterCurrentPinError => 'Ingresa tu PIN actual (4 dígitos)';

  @override
  String get setPinInvalidPinError => 'El PIN debe tener 4 dígitos';

  @override
  String get setPinPinsDoNotMatch => 'Los PIN no coinciden';

  @override
  String setPinTooManyAttemptsSeconds(Object seconds) {
    return 'Demasiados intentos. Espera ${seconds}s';
  }

  @override
  String get setPinCurrentPinIncorrect => 'PIN actual incorrecto';

  @override
  String get setPinCurrentPinLabel => 'PIN actual';

  @override
  String get setPinNewPinLabel => 'Nuevo PIN (4 dígitos)';

  @override
  String get setPinConfirmNewPinLabel => 'Confirmar nuevo PIN';

  @override
  String get lockScreenEnterPinTitle => 'Ingresa tu PIN';

  @override
  String get lockScreenPinHint => '4 dígitos';

  @override
  String lockScreenLockedOut(Object time) {
    return 'Bloqueado por seguridad. Intenta de nuevo en $time';
  }

  @override
  String lockScreenTooManyAttempts(Object time) {
    return 'Demasiados intentos. Espera $time';
  }

  @override
  String lockScreenPinIncorrectAttemptsLeft(Object left) {
    return 'PIN incorrecto. Intentos restantes: $left';
  }

  @override
  String get lockScreenUseBiometrics => 'Usar huella digital';

  @override
  String get dailyEntryValidationFutureDay =>
      'No se puede registrar un día futuro.';

  @override
  String dailyEntryValidationSelectMedication(Object index) {
    return 'Por favor selecciona el medicamento en el evento $index';
  }

  @override
  String dailyEntryValidationGelNoQuantity(Object index) {
    return 'Para gel no se registra cantidad. Deja “Sin dosis” en el evento $index.';
  }

  @override
  String dailyEntryValidationInvalidQuantityInteger(Object index) {
    return 'La cantidad del evento $index es inválida. Elige “Sin dosis” o un entero válido.';
  }

  @override
  String dailyEntryValidationInvalidQuantityFraction(Object index) {
    return 'La cantidad del evento $index es inválida. Elige “Sin dosis” o una fracción válida.';
  }

  @override
  String get dailyEntryValidationSleepNeedsQuality =>
      'Para guardar el sueño, elige “Cómo dormiste” (1–5) o borra los detalles.';

  @override
  String get medicationTypeTablet => 'comprimido';

  @override
  String get medicationTypeDrops => 'gotas';

  @override
  String get medicationTypeCapsule => 'cápsula';

  @override
  String get medicationTypeGel => 'gel/crema';

  @override
  String backupShareSubject(Object date) {
    return 'Copia de seguridad Mediary ($date)';
  }

  @override
  String get backupShareText => 'Copia de seguridad de mis datos de Mediary.';

  @override
  String get backupInvalidFileFormat => 'Formato de archivo inválido';

  @override
  String get backupNewerThanApp =>
      'Versión de backup más reciente que la app. Actualizá la app.';

  @override
  String get exportNoData => 'NO DATA';

  @override
  String get exportSectionSleep => 'Registro de sueño';

  @override
  String get exportSectionMedications => 'Registro de medicaciones';

  @override
  String get exportSectionDay => 'Registro del día';

  @override
  String get exportSleepHeaderNight => 'Noche';

  @override
  String get exportSleepHeaderQuality => 'Calidad';

  @override
  String get exportSleepHeaderDescription => 'Descripción';

  @override
  String get exportSleepHeaderHours => 'Horas';

  @override
  String get exportSleepHeaderHow => 'Cómo';

  @override
  String get exportSleepHeaderComments => 'Comentarios';

  @override
  String get exportSleepContinuityContinuous => 'Continuo';

  @override
  String get exportSleepContinuityBroken => 'Cortado';

  @override
  String get exportSleepQualityVeryBad => 'Muy mal';

  @override
  String get exportSleepQualityBad => 'Mal';

  @override
  String get exportSleepQualityOk => 'Regular';

  @override
  String get exportSleepQualityGood => 'Bien';

  @override
  String get exportSleepQualityVeryGood => 'Muy bien';

  @override
  String get exportMedicationHeaderDay => 'Día';

  @override
  String get exportMedicationHeaderTime => 'Hora';

  @override
  String get exportMedicationHeaderMedication => 'Medicamento';

  @override
  String get exportMedicationHeaderUnit => 'Unidad';

  @override
  String get exportMedicationHeaderQuantity => 'Cantidad';

  @override
  String get exportMedicationHeaderNote => 'Nota';

  @override
  String get exportMedicationHeaderNotes => 'Notas';

  @override
  String get exportMedicationApplication => 'Aplicación';

  @override
  String exportMedicationFallback(Object id) {
    return 'Medicamento $id';
  }

  @override
  String get exportShareCsv => 'Exportación CSV';

  @override
  String get exportShareSleepAnalyticsCsv =>
      'Exportación para analítica: sleep.csv';

  @override
  String get exportShareMedicationsAnalyticsCsv =>
      'Exportación para analítica: medications.csv';

  @override
  String get exportShareExcel => 'Exportación Excel (.xlsx)';

  @override
  String get exportSharePdf => 'Exportación PDF';

  @override
  String get exportFileBaseDiary => 'diario_medicamentos';

  @override
  String get exportFileBaseSleepAnalytics => 'sleep';

  @override
  String get exportFileBaseMedicationsAnalytics => 'medications';

  @override
  String get exportSheetSleep => 'Sueño';

  @override
  String get exportSheetMedications => 'Medicaciones';

  @override
  String get exportSheetDay => 'Día';

  @override
  String get exportDayHeaderDate => 'Fecha';

  @override
  String get exportDayHeaderMood => 'Ánimo';

  @override
  String get exportDayHeaderBlocksWalked => 'Cuadras caminadas';

  @override
  String get exportDayHeaderWater => 'Agua';

  @override
  String get exportDayHeaderDayNotes => 'Notas del día';

  @override
  String get exportDayHeaderDayNotesAbbrev => 'Notas día';

  @override
  String get exportErrorExcelGeneration =>
      'No se pudo generar el archivo Excel';

  @override
  String get exportPdfTitle => 'Diario (Sueño + Medicación + Día)';

  @override
  String exportPdfExportedAt(Object timestamp) {
    return 'Exportado: $timestamp';
  }

  @override
  String get exportPdfSectionSleep => 'Registro de Sueño';

  @override
  String get exportPdfSectionMedications => 'Diario de Medicaciones';

  @override
  String get exportPdfSectionDay => 'Registro del Día';
}
