import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:ui' show Locale;

import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cryptography/cryptography.dart';
import 'package:med_journal/l10n/gen/app_localizations.dart';

import 'database_helper.dart';
import 'error_logger.dart';
import '../features/medication/data/intake_repository.dart';
import '../models/day_entry.dart';
import '../models/intake_event.dart';
import '../models/medication.dart';
import '../models/medication_group.dart';
import '../models/medication_group_reminder.dart';
import '../models/medication_reminder.dart';

class BackupFileInfo {
  final File file;
  final Map<String, dynamic> json;
  final bool isEncrypted;

  const BackupFileInfo({
    required this.file,
    required this.json,
    required this.isEncrypted,
  });
}

class BackupService {
  static final BackupService instance = BackupService._init();
  BackupService._init();

  static const int _backupFormatVersion = 1;
  static const int _kPbkdf2Iterations = 100000;
  static const int _kSaltBytes = 16;
  static const int _kNonceBytes = 12;

  AppLocalizations _l10nFor(Locale? locale) {
    final l = locale ?? const Locale('es');
    try {
      return lookupAppLocalizations(l);
    } catch (_) {
      return lookupAppLocalizations(const Locale('es'));
    }
  }

  Future<void> createBackup({Locale? locale, String? password}) async {
    final l10n = _l10nFor(locale);
    try {
      final db = DatabaseHelper.instance;

      // 1. Cargar todos los datos
      final medications = await db.getAllMedications();
      final medicationGroups = await db.getAllMedicationGroups(
        includeArchived: true,
      );
      final medicationReminders = await db.getAllReminders();
      final groupReminders = await db.getAllGroupReminders();
      final dayEntries = await db.getAllDayEntries();
      final intakeRepo = IntakeRepository();
      final intakeEvents = await intakeRepo.getAllIntakeEvents();

      // Relaciones de grupos
      final groupMembers = <Map<String, dynamic>>[];
      for (final group in medicationGroups) {
        if (group.id == null) continue;
        final drugIds = await db.getMedicationGroupMemberIds(group.id!);
        if (drugIds.isNotEmpty) {
          groupMembers.add({'group_id': group.id, 'medication_ids': drugIds});
        }
      }

      // 2. Construir objeto JSON
      final backupMeta = {
        'format_version': _backupFormatVersion,
        'timestamp': DateTime.now().toIso8601String(),
        'platform': defaultTargetPlatform.toString(),
      };

      final backupData = {
        'meta': backupMeta,
        'data': {
          'medications': medications.map((m) => m.toMap()).toList(),
          'medication_groups': medicationGroups.map((g) => g.toMap()).toList(),
          'medication_group_members': groupMembers,
          'medication_reminders': medicationReminders
              .map((r) => r.toMap())
              .toList(),
          'medication_group_reminders': groupReminders
              .map((r) => r.toMap())
              .toList(),
          'day_entries': dayEntries.map((d) => d.toMap()).toList(),
          'intake_events': intakeEvents.map((i) => i.toMap()).toList(),
        },
      };

      // 3. Escribir a archivo temporal
      final normalizedPassword = password?.trim();
      final jsonString = jsonEncode(backupData);
      final fileJson =
          (normalizedPassword != null && normalizedPassword.isNotEmpty)
          ? await _encryptBackupJson(
              jsonString,
              normalizedPassword,
              meta: backupMeta,
            )
          : backupData;

      final fileContent = jsonEncode(fileJson);
      final tempDir = await getTemporaryDirectory();
      final dateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final fileName = 'mediary_backup_$dateStr.json';
      final file = File('${tempDir.path}/$fileName');

      await file.writeAsString(fileContent);

      // 4. Compartir/Guardar archivo
      final result = await Share.shareXFiles(
        [XFile(file.path)],
        subject: l10n.backupShareSubject(dateStr),
        text: l10n.backupShareText,
      );

      if (result.status == ShareResultStatus.dismissed) {
        if (kDebugMode) {
          debugPrint('Backup share dismissed');
        }
      }
    } catch (e, st) {
      ErrorLogger.instance.logBackupError(
        e,
        stackTrace: st,
        operation: 'Create backup',
      );
      rethrow;
    }
  }

  Future<BackupFileInfo?> pickBackupFile({Locale? locale}) async {
    final l10n = _l10nFor(locale);
    try {
      // 1. Seleccionar archivo
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.isEmpty) return null;

      final path = result.files.single.path;
      if (path == null) return null;

      final file = File(path);
      final content = await file.readAsString();
      final json = jsonDecode(content);

      // 2. Validar estructura básica
      if (json is! Map<String, dynamic> || !json.containsKey('meta')) {
        throw Exception(l10n.backupInvalidFileFormat);
      }

      final meta = json['meta'] as Map<String, dynamic>?;
      final version = (meta?['format_version'] as int?) ?? 0;

      if (version > _backupFormatVersion) {
        throw Exception(l10n.backupNewerThanApp);
      }

      final isEncrypted = (meta?['encrypted'] as bool?) ?? false;

      return BackupFileInfo(file: file, json: json, isEncrypted: isEncrypted);
    } catch (e, st) {
      ErrorLogger.instance.logBackupError(
        e,
        stackTrace: st,
        operation: 'Pick backup file',
      );
      rethrow;
    }
  }

  Future<bool> restoreBackupFromFile(
    BackupFileInfo fileInfo, {
    Locale? locale,
    String? password,
  }) async {
    final l10n = _l10nFor(locale);
    try {
      final backupJson = await _resolveBackupJson(
        fileInfo.json,
        l10n,
        password: password,
      );

      if (!backupJson.containsKey('data')) {
        throw Exception(l10n.backupInvalidFileFormat);
      }

      final data = backupJson['data'] as Map<String, dynamic>;

      final db = DatabaseHelper.instance;
      await db.ensureLatestSchema();

      final medications = (data['medications'] as List)
          .map((m) => Medication.fromMap(m))
          .toList();
      final groups = (data['medication_groups'] as List)
          .map((g) => MedicationGroup.fromMap(g))
          .toList();
      final reminders = (data['medication_reminders'] as List)
          .map((r) => MedicationReminder.fromMap(r))
          .toList();
      final groupReminders = (data['medication_group_reminders'] as List)
          .map((r) => MedicationGroupReminder.fromMap(r))
          .toList();
      final days = (data['day_entries'] as List)
          .map((d) => DayEntry.fromMap(d))
          .toList();
      final intakes = (data['intake_events'] as List)
          .map((i) => IntakeEvent.fromMap(i))
          .toList();

      final groupMembers = data['medication_group_members'] as List?;

      await db.wipeAllData();
      await db.ensureLatestSchema();

      // Insertar Medicamentos
      final dbRaw = await db.database;
      await dbRaw.transaction((txn) async {
        // Batch insert medications
        for (final m in medications) {
          await txn.insert('medications', m.toMap());
        }

        // Batch insert groups
        for (final g in groups) {
          await txn.insert('medication_groups', g.toMap());
        }

        // Group Members
        if (groupMembers != null) {
          for (final item in groupMembers) {
            final groupId = item['group_id'] as int;
            final medIds = (item['medication_ids'] as List).cast<int>();
            for (final mid in medIds) {
              await txn.insert('medication_group_members', {
                'group_id': groupId,
                'medication_id': mid,
              });
            }
          }
        }

        // Reminders
        for (final r in reminders) {
          await txn.insert('medication_reminders', r.toMap());
        }

        // Group Reminders
        for (final r in groupReminders) {
          await txn.insert('medication_group_reminders', r.toMap());
        }

        // Day Entries
        for (final d in days) {
          await txn.insert('day_entries', d.toMap());
        }

        // Intake Events
        for (final i in intakes) {
          await txn.insert('intake_events', i.toMap());
        }
      });

      return true;
    } catch (e, st) {
      ErrorLogger.instance.logBackupError(
        e,
        stackTrace: st,
        operation: 'Restore backup',
      );
      rethrow;
    }
  }

  Future<Map<String, dynamic>> _encryptBackupJson(
    String plainJson,
    String password, {
    required Map<String, dynamic> meta,
  }) async {
    final algorithm = AesGcm.with256bits();
    final kdf = Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: _kPbkdf2Iterations,
      bits: 256,
    );

    final salt = _randomBytes(_kSaltBytes);
    final nonce = _randomBytes(_kNonceBytes);

    final secretKey = await kdf.deriveKey(
      secretKey: SecretKeyData(utf8.encode(password)),
      nonce: salt,
    );

    final secretBox = await algorithm.encrypt(
      utf8.encode(plainJson),
      secretKey: secretKey,
      nonce: nonce,
    );

    return {
      'meta': {
        ...meta,
        'encrypted': true,
        'cipher': 'aes-256-gcm',
        'kdf': 'pbkdf2-sha256',
        'kdf_iterations': _kPbkdf2Iterations,
        'salt': base64Encode(salt),
        'nonce': base64Encode(nonce),
      },
      'payload': base64Encode(secretBox.cipherText),
      'mac': base64Encode(secretBox.mac.bytes),
    };
  }

  Future<Map<String, dynamic>> _resolveBackupJson(
    Map<String, dynamic> rootJson,
    AppLocalizations l10n, {
    String? password,
  }) async {
    final meta = rootJson['meta'] as Map<String, dynamic>?;
    final isEncrypted = (meta?['encrypted'] as bool?) ?? false;

    if (!isEncrypted) {
      return rootJson;
    }

    final normalizedPassword = password?.trim();
    if (normalizedPassword == null || normalizedPassword.isEmpty) {
      throw Exception(l10n.backupPasswordRequired);
    }

    final payload = rootJson['payload'];
    final macValue = rootJson['mac'];
    final saltValue = meta?['salt'];
    final nonceValue = meta?['nonce'];
    final iterations = (meta?['kdf_iterations'] as int?) ?? _kPbkdf2Iterations;

    if (payload is! String ||
        macValue is! String ||
        saltValue is! String ||
        nonceValue is! String) {
      throw Exception(l10n.backupInvalidFileFormat);
    }

    final algorithm = AesGcm.with256bits();
    final kdf = Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: iterations,
      bits: 256,
    );

    final salt = base64Decode(saltValue);
    final nonce = base64Decode(nonceValue);

    final secretKey = await kdf.deriveKey(
      secretKey: SecretKeyData(utf8.encode(normalizedPassword)),
      nonce: salt,
    );

    final secretBox = SecretBox(
      base64Decode(payload),
      nonce: nonce,
      mac: Mac(base64Decode(macValue)),
    );

    List<int> clearBytes;
    try {
      clearBytes = await algorithm.decrypt(secretBox, secretKey: secretKey);
    } on SecretBoxAuthenticationError {
      throw Exception(l10n.backupPasswordInvalid);
    }

    final decoded = jsonDecode(utf8.decode(clearBytes));
    if (decoded is! Map<String, dynamic>) {
      throw Exception(l10n.backupInvalidFileFormat);
    }
    return decoded;
  }

  List<int> _randomBytes(int length) {
    final rnd = Random.secure();
    return List<int>.generate(length, (_) => rnd.nextInt(256));
  }
}
