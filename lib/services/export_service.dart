import 'dart:convert';
import 'dart:io';
import 'dart:ui' show Locale;

import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:med_journal/l10n/gen/app_localizations.dart';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../services/database_helper.dart';
import '../features/medication/data/intake_repository.dart';
import '../utils/fraction_helper.dart';
import '../models/intake_event.dart';
import '../models/medication.dart';

class ExportDataRange {
  final DateTime start;
  final DateTime end;

  const ExportDataRange({required this.start, required this.end});
}

class ExportService {
  static final ExportService instance = ExportService._();
  ExportService._();

  AppLocalizations _l10nFor(Locale? locale) {
    final l = locale ?? const Locale('es');
    try {
      return lookupAppLocalizations(l);
    } catch (_) {
      return lookupAppLocalizations(const Locale('es'));
    }
  }

  DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  ({DateTime start, DateTime end})? _normalizeRange(
    DateTime? startDate,
    DateTime? endDate,
  ) {
    if (startDate == null && endDate == null) return null;

    final start = _dateOnly(startDate ?? endDate!);
    final end = _dateOnly(endDate ?? startDate!);
    if (end.isBefore(start)) {
      return (start: end, end: start);
    }
    return (start: start, end: end);
  }

  bool _isInInclusiveRange(DateTime date, DateTime start, DateTime end) {
    final d = _dateOnly(date);
    return !d.isBefore(start) && !d.isAfter(end);
  }

  // Rango global de fechas con datos (sueño, medicación o día).
  Future<ExportDataRange?> getAvailableDataRange() async {
    final db = DatabaseHelper.instance;

    final sleepEntries = await db.getAllSleepEntriesFromDayEntries();
    final intakeRepo = IntakeRepository();
    final events = await intakeRepo.getAllIntakeEvents();

    final sqlDb = await db.database;
    final dayRows = await sqlDb.query('day_entries');
    final Map<int, DateTime> dayDateById = {};
    for (final r in dayRows) {
      final id = r['id'] as int;
      final dateStr = r['entry_date'] as String;
      dayDateById[id] = _dateOnly(DateTime.parse(dateStr));
    }

    DateTime? minDate;
    DateTime? maxDate;

    void consider(DateTime dt) {
      final d = _dateOnly(dt);
      minDate = (minDate == null || d.isBefore(minDate!)) ? d : minDate;
      maxDate = (maxDate == null || d.isAfter(maxDate!)) ? d : maxDate;
    }

    for (final s in sleepEntries) {
      consider(s.nightDate);
    }

    for (final e in events) {
      final dayId = e.dayEntryId;
      final dayDate = (dayId != null && dayDateById.containsKey(dayId))
          ? dayDateById[dayId]!
          : _dateOnly(e.takenAt);
      consider(dayDate);
    }

    // Considerar días con datos en day_entries (mood/hábitos/etc).
    for (final r in dayRows) {
      final dateStr = r['entry_date'] as String?;
      if (dateStr == null) continue;
      final dt = _dateOnly(DateTime.parse(dateStr));

      bool hasAny = false;
      bool nonEmptyText(String? s) => (s ?? '').trim().isNotEmpty;

      // Campos de day_entries que cuentan como "dato".
      if (r['sleep_quality'] != null) hasAny = true;
      if (nonEmptyText(r['sleep_notes'] as String?)) hasAny = true;
      if (r['sleep_duration_minutes'] != null) hasAny = true;
      if (r['sleep_continuity'] != null) hasAny = true;
      if (r['day_mood'] != null) hasAny = true;
      if (r['blocks_walked'] != null) hasAny = true;
      if (nonEmptyText(r['day_notes'] as String?)) hasAny = true;
      if (r['water_count'] != null) hasAny = true;

      if (hasAny) consider(dt);
    }

    if (minDate == null || maxDate == null) return null;
    return ExportDataRange(start: minDate!, end: maxDate!);
  }

  List<int> _utf16LeBytesWithBom(String s) {
    final out = <int>[0xFF, 0xFE];
    for (final unit in s.codeUnits) {
      out.add(unit & 0xFF);
      out.add((unit >> 8) & 0xFF);
    }
    return out;
  }

  String _formatDurationMinutes(int? minutes) {
    if (minutes == null || minutes <= 0) return '';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (h <= 0) return '${m}m';
    if (m == 0) return '${h}h';
    return '${h}h ${m}m';
  }

  String _getSleepContinuityLabel(AppLocalizations l10n, int? continuity) {
    switch (continuity) {
      case 1:
        return l10n.exportSleepContinuityContinuous;
      case 2:
        return l10n.exportSleepContinuityBroken;
      default:
        return '';
    }
  }

  Future<File> exportToCSV({
    DateTime? startDate,
    DateTime? endDate,
    Locale? locale,
  }) async {
    final l10n = _l10nFor(locale);
    final db = DatabaseHelper.instance;

    final sleepEntries = await db.getAllSleepEntriesFromDayEntries();
    final range = _normalizeRange(startDate, endDate);
    final filteredSleep = (range == null)
        ? sleepEntries
        : sleepEntries
              .where(
                (e) => _isInInclusiveRange(e.nightDate, range.start, range.end),
              )
              .toList();

    filteredSleep.sort((a, b) => a.nightDate.compareTo(b.nightDate));

    final dateFormat = DateFormat('yyyy-MM-dd');
    final timeFormat = DateFormat('HH:mm');

    /// Sección A: Sueño
    final List<List<dynamic>> sleepRows = [
      [
        l10n.exportSleepHeaderNight,
        l10n.exportSleepHeaderQuality,
        l10n.exportSleepHeaderDescription,
        l10n.exportSleepHeaderHours,
        l10n.exportSleepHeaderHow,
        l10n.exportSleepHeaderComments,
      ],
    ];

    if (filteredSleep.isEmpty) {
      sleepRows.add([l10n.exportNoData, '', '', '', '', '']);
    } else {
      for (final entry in filteredSleep) {
        sleepRows.add([
          dateFormat.format(entry.nightDate),
          entry.sleepQuality,
          _getSleepQualityLabel(l10n, entry.sleepQuality),
          _formatDurationMinutes(entry.sleepDurationMinutes),
          _getSleepContinuityLabel(l10n, entry.sleepContinuity),
          entry.notes ?? '',
        ]);
      }
    }

    /// Sección B: Medicaciones 
    final List<List<dynamic>> medicationRows = [
      [
        l10n.exportMedicationHeaderDay,
        l10n.exportMedicationHeaderTime,
        l10n.exportMedicationHeaderMedication,
        l10n.exportMedicationHeaderUnit,
        l10n.exportMedicationHeaderQuantity,
        l10n.exportMedicationHeaderNote,
      ],
    ];

    final allEvents = await _collectAllMedicationEventsWithDay(
      db,
      startDate: startDate,
      endDate: endDate,
    );

    allEvents.sort((a, b) {
      final d = (a['dayDate'] as DateTime).compareTo(b['dayDate'] as DateTime);
      if (d != 0) return d;
      return (a['event'] as IntakeEvent).takenAt.compareTo(
        (b['event'] as IntakeEvent).takenAt,
      );
    });

    if (allEvents.isEmpty) {
      medicationRows.add([l10n.exportNoData, '', '', '', '', '']);
    } else {
      for (final item in allEvents) {
        final dayDate = item['dayDate'] as DateTime;
        final event = item['event'] as IntakeEvent;
        final medication = item['medication'];

        final isGel =
            medication is Medication && medication.type == MedicationType.gel;
        final quantityText = isGel
            ? l10n.exportMedicationApplication
            : (event.amountNumerator == null || event.amountDenominator == null)
            ? '—'
            : FractionHelper.fractionToText(
                event.amountNumerator!,
                event.amountDenominator!,
              );

        medicationRows.add([
          dateFormat.format(dayDate),
          timeFormat.format(event.takenAt),
          medication?.name ?? l10n.exportMedicationFallback(event.medicationId),
          medication?.unit ?? '',
          quantityText,
          event.note ?? '',
        ]);
      }
    }

    const cols = 6;

    /// Sección C: Día (ánimo/hábitos)
    final dayRows = await _buildDayEntriesCsvRows(
      l10n,
      startDate: startDate,
      endDate: endDate,
    );

    final allRows = <List<dynamic>>[
      List.filled(cols, ''),
      [l10n.exportSectionSleep, ...List.filled(cols - 1, '')],
      ...sleepRows,
      List.filled(cols, ''),
      [l10n.exportSectionMedications, ...List.filled(cols - 1, '')],
      ...medicationRows,
      List.filled(cols, ''),
      [l10n.exportSectionDay, ...List.filled(cols - 1, '')],
      ...dayRows,
    ];

    final csv = const ListToCsvConverter(
      fieldDelimiter: ';',
      eol: '\r\n',
    ).convert(allRows);

    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final path = '${directory.path}/${l10n.exportFileBaseDiary}_$timestamp.csv';
    final file = File(path);
    await file.writeAsBytes(_utf16LeBytesWithBom(csv), flush: true);

    return file;
  }

  Future<void> shareCSV({
    DateTime? startDate,
    DateTime? endDate,
    Locale? locale,
  }) async {
    final l10n = _l10nFor(locale);
    final file = await exportToCSV(
      startDate: startDate,
      endDate: endDate,
      locale: locale,
    );
    await Share.shareXFiles([XFile(file.path)], text: l10n.exportShareCsv);
  }

  /// CSV para analítica (UTF-8, coma, una tabla por archivo)

  Future<File> exportSleepAnalyticsCsv({
    DateTime? startDate,
    DateTime? endDate,
    Locale? locale,
  }) async {
    final l10n = _l10nFor(locale);
    final db = DatabaseHelper.instance;

    final sleepEntries = await db.getAllSleepEntriesFromDayEntries();

    final range = _normalizeRange(startDate, endDate);
    final filteredSleep = (range == null)
        ? sleepEntries
        : sleepEntries
              .where(
                (e) => _isInInclusiveRange(e.nightDate, range.start, range.end),
              )
              .toList();

    filteredSleep.sort((a, b) => a.nightDate.compareTo(b.nightDate));

    final dateFormat = DateFormat('yyyy-MM-dd');

    final rows = <List<dynamic>>[
      [
        l10n.exportSleepHeaderNight,
        l10n.exportSleepHeaderQuality,
        l10n.exportSleepHeaderDescription,
        l10n.exportSleepHeaderHours,
        l10n.exportSleepHeaderHow,
        l10n.exportSleepHeaderComments,
      ],
      ...filteredSleep.map(
        (e) => [
          dateFormat.format(e.nightDate),
          e.sleepQuality,
          _getSleepQualityLabel(l10n, e.sleepQuality),
          _formatDurationMinutes(e.sleepDurationMinutes),
          _getSleepContinuityLabel(l10n, e.sleepContinuity),
          e.notes ?? '',
        ],
      ),
    ];

    if (filteredSleep.isEmpty) {
      rows.add([l10n.exportNoData, '', '', '', '', '']);
    }

    final csv = const ListToCsvConverter(
      fieldDelimiter: ',',
      eol: '\n',
    ).convert(rows);

    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final path =
        '${directory.path}/${l10n.exportFileBaseSleepAnalytics}_$timestamp.csv';
    final file = File(path);
    await file.writeAsBytes(utf8.encode(csv), flush: true);
    return file;
  }

  Future<void> shareSleepAnalyticsCsv({
    DateTime? startDate,
    DateTime? endDate,
    Locale? locale,
  }) async {
    final l10n = _l10nFor(locale);
    final file = await exportSleepAnalyticsCsv(
      startDate: startDate,
      endDate: endDate,
      locale: locale,
    );
    await Share.shareXFiles([
      XFile(file.path),
    ], text: l10n.exportShareSleepAnalyticsCsv);
  }

  Future<File> exportMedicationsAnalyticsCsv({
    DateTime? startDate,
    DateTime? endDate,
    Locale? locale,
  }) async {
    final l10n = _l10nFor(locale);
    final db = DatabaseHelper.instance;

    final dateFormat = DateFormat('yyyy-MM-dd');
    final timeFormat = DateFormat('HH:mm');

    final allEvents = await _collectAllMedicationEventsWithDay(
      db,
      startDate: startDate,
      endDate: endDate,
    );
    allEvents.sort((a, b) {
      final d = (a['dayDate'] as DateTime).compareTo(b['dayDate'] as DateTime);
      if (d != 0) return d;
      return (a['event'] as IntakeEvent).takenAt.compareTo(
        (b['event'] as IntakeEvent).takenAt,
      );
    });

    final rows = <List<dynamic>>[
      [
        l10n.exportMedicationHeaderDay,
        l10n.exportMedicationHeaderTime,
        l10n.exportMedicationHeaderMedication,
        l10n.exportMedicationHeaderUnit,
        l10n.exportMedicationHeaderQuantity,
        l10n.exportMedicationHeaderNotes,
      ],
    ];

    if (allEvents.isEmpty) {
      rows.add([l10n.exportNoData, '', '', '', '', '']);
    } else {
      for (final item in allEvents) {
        final dayDate = item['dayDate'] as DateTime;
        final event = item['event'] as IntakeEvent;
        final medication = item['medication'];

        final isGel =
            medication is Medication && medication.type == MedicationType.gel;
        final quantityText = isGel
            ? l10n.exportMedicationApplication
            : (event.amountNumerator == null || event.amountDenominator == null)
            ? '—'
            : FractionHelper.fractionToText(
                event.amountNumerator!,
                event.amountDenominator!,
              );

        rows.add([
          dateFormat.format(dayDate),
          timeFormat.format(event.takenAt),
          medication?.name ?? l10n.exportMedicationFallback(event.medicationId),
          medication?.unit ?? '',
          quantityText,
          event.note ?? '',
        ]);
      }
    }

    final csv = const ListToCsvConverter(
      fieldDelimiter: ',',
      eol: '\n',
    ).convert(rows);

    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final path =
        '${directory.path}/${l10n.exportFileBaseMedicationsAnalytics}_$timestamp.csv';
    final file = File(path);
    await file.writeAsBytes(utf8.encode(csv), flush: true);
    return file;
  }

  Future<void> shareMedicationsAnalyticsCsv({
    DateTime? startDate,
    DateTime? endDate,
    Locale? locale,
  }) async {
    final l10n = _l10nFor(locale);
    final file = await exportMedicationsAnalyticsCsv(
      startDate: startDate,
      endDate: endDate,
      locale: locale,
    );
    await Share.shareXFiles([
      XFile(file.path),
    ], text: l10n.exportShareMedicationsAnalyticsCsv);
  }

  Future<File> exportToXlsx({
    DateTime? startDate,
    DateTime? endDate,
    Locale? locale,
  }) async {
    final l10n = _l10nFor(locale);
    final db = DatabaseHelper.instance;

    final sleepEntries = await db.getAllSleepEntriesFromDayEntries();

    final range = _normalizeRange(startDate, endDate);
    final filteredSleep = (range == null)
        ? sleepEntries
        : sleepEntries
              .where(
                (e) => _isInInclusiveRange(e.nightDate, range.start, range.end),
              )
              .toList();

    filteredSleep.sort((a, b) => a.nightDate.compareTo(b.nightDate));

    final dateFormat = DateFormat('yyyy-MM-dd');
    final timeFormat = DateFormat('HH:mm');

    final excel = Excel.createExcel();

    final defaultSheet = excel.getDefaultSheet();
    if (defaultSheet != null && defaultSheet != l10n.exportSheetSleep) {
      excel.rename(defaultSheet, l10n.exportSheetSleep);
    }

    final sleepSheet = excel[l10n.exportSheetSleep];
    final medsSheet = excel[l10n.exportSheetMedications];
    final daySheet = excel[l10n.exportSheetDay];

    // Ancho de columnas para legibilidad
    sleepSheet.setColumnWidth(0, 14); // Noche
    sleepSheet.setColumnWidth(1, 10); // Calidad
    sleepSheet.setColumnWidth(2, 18); // Descripción
    sleepSheet.setColumnWidth(3, 10); // Horas
    sleepSheet.setColumnWidth(4, 12); // Cómo
    sleepSheet.setColumnWidth(5, 40); // Comentarios

    medsSheet.setColumnWidth(0, 14); // Día
    medsSheet.setColumnWidth(1, 10); // Hora
    medsSheet.setColumnWidth(2, 28); // Medicamento
    medsSheet.setColumnWidth(3, 14); // Unidad
    medsSheet.setColumnWidth(4, 14); // Cantidad
    medsSheet.setColumnWidth(5, 40); // Nota

    // Día
    daySheet.setColumnWidth(0, 14); // Fecha
    daySheet.setColumnWidth(1, 10); // Ánimo
    daySheet.setColumnWidth(2, 14); // Cuadras caminadas
    daySheet.setColumnWidth(3, 10); // Agua
    daySheet.setColumnWidth(4, 40); // Notas del día

    // Headers
    sleepSheet.appendRow([
      TextCellValue(l10n.exportSleepHeaderNight),
      TextCellValue(l10n.exportSleepHeaderQuality),
      TextCellValue(l10n.exportSleepHeaderDescription),
      TextCellValue(l10n.exportSleepHeaderHours),
      TextCellValue(l10n.exportSleepHeaderHow),
      TextCellValue(l10n.exportSleepHeaderComments),
    ]);

    if (filteredSleep.isEmpty) {
      sleepSheet.appendRow([
        TextCellValue(l10n.exportNoData),
        TextCellValue(''),
        TextCellValue(''),
        TextCellValue(''),
        TextCellValue(''),
        TextCellValue(''),
      ]);
    } else {
      for (final entry in filteredSleep) {
        sleepSheet.appendRow([
          TextCellValue(dateFormat.format(entry.nightDate)),
          TextCellValue(entry.sleepQuality.toString()),
          TextCellValue(_getSleepQualityLabel(l10n, entry.sleepQuality)),
          TextCellValue(_formatDurationMinutes(entry.sleepDurationMinutes)),
          TextCellValue(_getSleepContinuityLabel(l10n, entry.sleepContinuity)),
          TextCellValue(entry.notes ?? ''),
        ]);
      }
    }

    medsSheet.appendRow([
      TextCellValue(l10n.exportMedicationHeaderDay),
      TextCellValue(l10n.exportMedicationHeaderTime),
      TextCellValue(l10n.exportMedicationHeaderMedication),
      TextCellValue(l10n.exportMedicationHeaderUnit),
      TextCellValue(l10n.exportMedicationHeaderQuantity),
      TextCellValue(l10n.exportMedicationHeaderNote),
    ]);

    final allEvents = await _collectAllMedicationEventsWithDay(
      db,
      startDate: startDate,
      endDate: endDate,
    );
    allEvents.sort((a, b) {
      final d = (a['dayDate'] as DateTime).compareTo(b['dayDate'] as DateTime);
      if (d != 0) return d;
      return (a['event'] as IntakeEvent).takenAt.compareTo(
        (b['event'] as IntakeEvent).takenAt,
      );
    });

    if (allEvents.isEmpty) {
      medsSheet.appendRow([
        TextCellValue(l10n.exportNoData),
        TextCellValue(''),
        TextCellValue(''),
        TextCellValue(''),
        TextCellValue(''),
        TextCellValue(''),
      ]);
    } else {
      for (final item in allEvents) {
        final dayDate = item['dayDate'] as DateTime;
        final event = item['event'] as IntakeEvent;
        final medication = item['medication'];

        final isGel =
            medication is Medication && medication.type == MedicationType.gel;
        final quantityText = isGel
            ? l10n.exportMedicationApplication
            : (event.amountNumerator == null || event.amountDenominator == null)
            ? '—'
            : FractionHelper.fractionToText(
                event.amountNumerator!,
                event.amountDenominator!,
              );

        medsSheet.appendRow([
          TextCellValue(dateFormat.format(dayDate)),
          TextCellValue(timeFormat.format(event.takenAt)),
          TextCellValue(
            medication?.name ??
                l10n.exportMedicationFallback(event.medicationId),
          ),
          TextCellValue(medication?.unit ?? ''),
          TextCellValue(quantityText),
          TextCellValue(event.note ?? ''),
        ]);
      }
    }

    excel.setDefaultSheet(l10n.exportSheetSleep);

    // Sheet Día
    final dayHeaders = <TextCellValue>[
      TextCellValue(l10n.exportDayHeaderDate),
      TextCellValue(l10n.exportDayHeaderMood),
      TextCellValue(l10n.exportDayHeaderBlocksWalked),
      TextCellValue(l10n.exportDayHeaderWater),
      TextCellValue(l10n.exportDayHeaderDayNotes),
    ];
    daySheet.appendRow(dayHeaders);

    final dayData = await _buildDayEntriesTabularData(
      l10n,
      startDate: startDate,
      endDate: endDate,
    );
    if (dayData.isEmpty) {
      daySheet.appendRow([TextCellValue(l10n.exportNoData)]);
    } else {
      for (final row in dayData) {
        daySheet.appendRow(row.map(TextCellValue.new).toList(growable: false));
      }
    }

    final bytes = excel.encode();
    if (bytes == null) {
      throw Exception(l10n.exportErrorExcelGeneration);
    }

    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final path =
        '${directory.path}/${l10n.exportFileBaseDiary}_$timestamp.xlsx';
    final file = File(path);
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  Future<void> shareXlsx({
    DateTime? startDate,
    DateTime? endDate,
    Locale? locale,
  }) async {
    final l10n = _l10nFor(locale);
    final file = await exportToXlsx(
      startDate: startDate,
      endDate: endDate,
      locale: locale,
    );
    await Share.shareXFiles([XFile(file.path)], text: l10n.exportShareExcel);
  }

  Future<File> exportToPDF({
    DateTime? startDate,
    DateTime? endDate,
    Locale? locale,
  }) async {
    final l10n = _l10nFor(locale);
    final db = DatabaseHelper.instance;

    final sleepEntries = await db.getAllSleepEntriesFromDayEntries();

    final range = _normalizeRange(startDate, endDate);
    final filteredSleep = (range == null)
        ? sleepEntries
        : sleepEntries
              .where(
                (e) => _isInInclusiveRange(e.nightDate, range.start, range.end),
              )
              .toList();

    filteredSleep.sort((a, b) => a.nightDate.compareTo(b.nightDate));

    final dateFormat = DateFormat('yyyy-MM-dd');
    final timeFormat = DateFormat('HH:mm');

    final doc = pw.Document();

    /// Preparar data para tabla medicaciones
    final medData = await _buildMedicationTableData(
      l10n,
      db,
      dateFormat,
      timeFormat,
      startDate: startDate,
      endDate: endDate,
    );

    final dayData = await _buildDayEntriesTabularData(
      l10n,
      startDate: startDate,
      endDate: endDate,
    );

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Text(
            l10n.exportPdfTitle,
            style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            l10n.exportPdfExportedAt(
              DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now()),
            ),
            style: const pw.TextStyle(fontSize: 10),
          ),
          pw.SizedBox(height: 24),

          pw.Text(
            l10n.exportPdfSectionSleep,
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 10),
          pw.TableHelper.fromTextArray(
            columnWidths: {
              0: const pw.FixedColumnWidth(70),
              1: const pw.FixedColumnWidth(35),
              2: const pw.FlexColumnWidth(2),
              3: const pw.FixedColumnWidth(45),
              4: const pw.FixedColumnWidth(55),
              5: const pw.FlexColumnWidth(3),
            },
            headerStyle: pw.TextStyle(
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey),
            cellStyle: const pw.TextStyle(fontSize: 9),
            cellAlignment: pw.Alignment.centerLeft,
            headers: [
              l10n.exportSleepHeaderNight,
              l10n.exportSleepHeaderQuality,
              l10n.exportSleepHeaderDescription,
              l10n.exportSleepHeaderHours,
              l10n.exportSleepHeaderHow,
              l10n.exportSleepHeaderComments,
            ],
            data: filteredSleep.isEmpty
                ? [
                    [l10n.exportNoData, '', '', '', '', ''],
                  ]
                : filteredSleep
                      .map(
                        (e) => [
                          dateFormat.format(e.nightDate),
                          e.sleepQuality.toString(),
                          _getSleepQualityLabel(l10n, e.sleepQuality),
                          _formatDurationMinutes(e.sleepDurationMinutes),
                          _getSleepContinuityLabel(l10n, e.sleepContinuity),
                          e.notes ?? '',
                        ],
                      )
                      .toList(),
          ),
          pw.SizedBox(height: 24),

          pw.Text(
            l10n.exportPdfSectionMedications,
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 10),
          pw.TableHelper.fromTextArray(
            columnWidths: {
              0: const pw.FixedColumnWidth(70),
              1: const pw.FixedColumnWidth(40),
              2: const pw.FlexColumnWidth(3),
              3: const pw.FixedColumnWidth(55),
              4: const pw.FixedColumnWidth(55),
              5: const pw.FlexColumnWidth(3),
            },
            headerStyle: pw.TextStyle(
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey),
            cellStyle: const pw.TextStyle(fontSize: 9),
            cellAlignment: pw.Alignment.centerLeft,
            headers: [
              l10n.exportMedicationHeaderDay,
              l10n.exportMedicationHeaderTime,
              l10n.exportMedicationHeaderMedication,
              l10n.exportMedicationHeaderUnit,
              l10n.exportMedicationHeaderQuantity,
              l10n.exportMedicationHeaderNote,
            ],
            data: medData.isEmpty
                ? [
                    [l10n.exportNoData, '', '', '', '', ''],
                  ]
                : medData,
          ),

          pw.SizedBox(height: 24),
          pw.Text(
            l10n.exportPdfSectionDay,
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 10),
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey),
            cellStyle: const pw.TextStyle(fontSize: 9),
            cellAlignment: pw.Alignment.centerLeft,
            headers: [
              l10n.exportDayHeaderDate,
              l10n.exportDayHeaderMood,
              l10n.exportDayHeaderBlocksWalked,
              l10n.exportDayHeaderWater,
              l10n.exportDayHeaderDayNotesAbbrev,
            ],
            data: dayData.isEmpty
                ? [
                    [l10n.exportNoData],
                  ]
                : dayData,
          ),
        ],
      ),
    );

    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final path = '${directory.path}/${l10n.exportFileBaseDiary}_$timestamp.pdf';
    final file = File(path);
    await file.writeAsBytes(await doc.save());

    return file;
  }

  Future<void> sharePDF({
    DateTime? startDate,
    DateTime? endDate,
    Locale? locale,
  }) async {
    final l10n = _l10nFor(locale);
    final file = await exportToPDF(
      startDate: startDate,
      endDate: endDate,
      locale: locale,
    );
    await Share.shareXFiles([XFile(file.path)], text: l10n.exportSharePdf);
  }

  Future<List<List<dynamic>>> _buildDayEntriesCsvRows(
    AppLocalizations l10n, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final rows = await _buildDayEntriesTabularData(
      l10n,
      startDate: startDate,
      endDate: endDate,
    );

    final headers = [
      l10n.exportDayHeaderDate,
      l10n.exportDayHeaderMood,
      l10n.exportDayHeaderBlocksWalked,
      l10n.exportDayHeaderWater,
      l10n.exportDayHeaderDayNotes,
    ];

    if (rows.isEmpty) {
      return [
        headers,
        [l10n.exportNoData, ...List.filled(headers.length - 1, '')],
      ];
    }

    return [headers, ...rows];
  }

  Future<List<List<String>>> _buildDayEntriesTabularData(
    AppLocalizations l10n, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = DatabaseHelper.instance;
    final sqlDb = await db.database;
    final dateFormat = DateFormat('yyyy-MM-dd');

    final range = _normalizeRange(startDate, endDate);
    final where = (range == null)
        ? null
        : 'entry_date >= ? AND entry_date <= ?';
    final whereArgs = (range == null)
        ? null
        : [
            _dateOnly(range.start).toIso8601String(),
            _dateOnly(range.end).toIso8601String(),
          ];

    final dayRows = await sqlDb.query(
      'day_entries',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'entry_date ASC',
    );

    bool nonEmptyText(String? s) => (s ?? '').trim().isNotEmpty;

    final out = <List<String>>[];

    for (final r in dayRows) {
      final dateStr = r['entry_date'] as String?;
      if (dateStr == null) continue;
      final dt = _dateOnly(DateTime.parse(dateStr));

      final mood = r['day_mood'] as int?;
      final blocksWalked = r['blocks_walked'] as int?;
      final water = r['water_count'] as int?;
      final dayNotes = (r['day_notes'] as String?)?.trim();

      // Consideramos como "fila exportable" si hay algo (evita filas vacías creadas por ensureDayEntry).
      final hasAny =
          mood != null ||
          blocksWalked != null ||
          water != null ||
          nonEmptyText(dayNotes);

      if (!hasAny) continue;

      out.add([
        dateFormat.format(dt),
        mood?.toString() ?? '',
        blocksWalked?.toString() ?? '',
        water?.toString() ?? '',
        dayNotes ?? '',
      ]);
    }

    return out;
  }

  /// helpers

  Future<List<Map<String, dynamic>>> _collectAllMedicationEventsWithDay(
    DatabaseHelper db, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final sqlDb = await db.database;

    // Map day_entry_id -> entry_date
    final dayRows = await sqlDb.query('day_entries');
    final Map<int, DateTime> dayDateById = {};
    for (final r in dayRows) {
      final id = r['id'] as int;
      final dateStr = r['entry_date'] as String;
      dayDateById[id] = DateTime.parse(dateStr);
    }

    final intakeRepo = IntakeRepository();
    final events = await intakeRepo.getAllIntakeEvents();

    final range = _normalizeRange(startDate, endDate);

    final List<Map<String, dynamic>> out = [];
    for (final e in events) {
      final dayId = e.dayEntryId;
      final dayDate = (dayId != null && dayDateById.containsKey(dayId))
          ? dayDateById[dayId]!
          : DateTime(e.takenAt.year, e.takenAt.month, e.takenAt.day);

      if (range != null &&
          !_isInInclusiveRange(dayDate, range.start, range.end)) {
        continue;
      }

      final medication = await db.getMedication(e.medicationId);

      out.add({'dayDate': dayDate, 'event': e, 'medication': medication});
    }

    return out;
  }

  Future<List<List<String>>> _buildMedicationTableData(
    AppLocalizations l10n,
    DatabaseHelper db,
    DateFormat dateFormat,
    DateFormat timeFormat, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final allEvents = await _collectAllMedicationEventsWithDay(
      db,
      startDate: startDate,
      endDate: endDate,
    );

    allEvents.sort((a, b) {
      final d = (a['dayDate'] as DateTime).compareTo(b['dayDate'] as DateTime);
      if (d != 0) return d;
      return (a['event'] as IntakeEvent).takenAt.compareTo(
        (b['event'] as IntakeEvent).takenAt,
      );
    });

    final data = <List<String>>[];

    for (final item in allEvents) {
      final dayDate = item['dayDate'] as DateTime;
      final event = item['event'] as IntakeEvent;
      final medication = item['medication'];
      final isGel =
          medication is Medication && medication.type == MedicationType.gel;

      data.add([
        dateFormat.format(dayDate),
        timeFormat.format(event.takenAt),
        medication?.name ?? l10n.exportMedicationFallback(event.medicationId),
        medication?.unit ?? '',
        isGel
            ? l10n.exportMedicationApplication
            : (event.amountNumerator == null || event.amountDenominator == null)
            ? '—'
            : FractionHelper.fractionToText(
                event.amountNumerator!,
                event.amountDenominator!,
              ),
        event.note ?? '',
      ]);
    }

    return data;
  }

  String _getSleepQualityLabel(AppLocalizations l10n, int quality) {
    switch (quality) {
      case 1:
        return l10n.exportSleepQualityVeryBad;
      case 2:
        return l10n.exportSleepQualityBad;
      case 3:
        return l10n.exportSleepQualityOk;
      case 4:
        return l10n.exportSleepQualityGood;
      case 5:
        return l10n.exportSleepQualityVeryGood;
      default:
        return '';
    }
  }
}
