import 'dart:convert';
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../services/database_helper.dart';
import '../utils/fraction_helper.dart';
import '../models/intake_event.dart';

class ExportDataRange {
  final DateTime start;
  final DateTime end;

  const ExportDataRange({required this.start, required this.end});
}

class ExportService {
  static final ExportService instance = ExportService._();
  ExportService._();

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

  // Rango global de fechas con datos (sueño o medicación).
  // Útil para limitar el selector de fechas en UI.
  Future<ExportDataRange?> getAvailableDataRange() async {
    final db = DatabaseHelper.instance;

    final sleepEntries = await db.getAllSleepEntriesFromDayEntries();
    final events = await db.getAllIntakeEvents();

    if (sleepEntries.isEmpty && events.isEmpty) return null;

    final sqlDb = await db.database;
    final dayRows = await sqlDb.query(
      'day_entries',
      columns: ['id', 'entry_date'],
    );
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

  String _getSleepContinuityLabel(int? continuity) {
    switch (continuity) {
      case 1:
        return 'Continuo';
      case 2:
        return 'Cortado';
      default:
        return '';
    }
  }

  Future<File> exportToCSV({DateTime? startDate, DateTime? endDate}) async {
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
      ['Noche', 'Calidad', 'Descripción', 'Horas', 'Cómo', 'Comentarios'],
    ];

    if (filteredSleep.isEmpty) {
      sleepRows.add(['NO DATA', '', '', '', '', '']);
    } else {
      for (final entry in filteredSleep) {
        sleepRows.add([
          dateFormat.format(entry.nightDate),
          entry.sleepQuality,
          _getSleepQualityLabel(entry.sleepQuality),
          _formatDurationMinutes(entry.sleepDurationMinutes),
          _getSleepContinuityLabel(entry.sleepContinuity),
          entry.notes ?? '',
        ]);
      }
    }

    /// Sección B: Medicaciones (NUEVO: day_entry_id)
    final List<List<dynamic>> medicationRows = [
      ['Día', 'Hora', 'Medicamento', 'Unidad', 'Cantidad', 'Nota'],
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
      medicationRows.add(['NO DATA', '', '', '', '', '']);
    } else {
      for (final item in allEvents) {
        final dayDate = item['dayDate'] as DateTime;
        final event = item['event'] as IntakeEvent;
        final medication = item['medication'];

        final quantityText =
            (event.amountNumerator == null || event.amountDenominator == null)
            ? '—'
            : FractionHelper.fractionToText(
                event.amountNumerator!,
                event.amountDenominator!,
              );

        medicationRows.add([
          dateFormat.format(dayDate),
          timeFormat.format(event.takenAt),
          medication?.name ?? 'Medicamento ${event.medicationId}',
          medication?.unit ?? '',
          quantityText,
          event.note ?? '',
        ]);
      }
    }

    const cols = 6;
    final allRows = <List<dynamic>>[
      List.filled(cols, ''),
      ['Registro de sueño', ...List.filled(cols - 1, '')],
      ...sleepRows,
      List.filled(cols, ''),
      ['Registro de medicaciones', ...List.filled(cols - 1, '')],
      ...medicationRows,
    ];

    final csv = const ListToCsvConverter(
      fieldDelimiter: ';',
      eol: '\r\n',
    ).convert(allRows);

    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final path = '${directory.path}/diario_medicamentos_$timestamp.csv';
    final file = File(path);
    await file.writeAsBytes(_utf16LeBytesWithBom(csv), flush: true);

    return file;
  }

  Future<void> shareCSV({DateTime? startDate, DateTime? endDate}) async {
    final file = await exportToCSV(startDate: startDate, endDate: endDate);
    await Share.shareXFiles([XFile(file.path)], text: 'Exportación CSV');
  }

  /// CSV para analítica (UTF-8, coma, una tabla por archivo)

  Future<File> exportSleepAnalyticsCsv({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
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
      ['Noche', 'Calidad', 'Descripción', 'Horas', 'Cómo', 'Comentarios'],
      ...filteredSleep.map(
        (e) => [
          dateFormat.format(e.nightDate),
          e.sleepQuality,
          _getSleepQualityLabel(e.sleepQuality),
          _formatDurationMinutes(e.sleepDurationMinutes),
          _getSleepContinuityLabel(e.sleepContinuity),
          e.notes ?? '',
        ],
      ),
    ];

    if (filteredSleep.isEmpty) {
      rows.add(['NO DATA', '', '', '', '', '']);
    }

    final csv = const ListToCsvConverter(
      fieldDelimiter: ',',
      eol: '\n',
    ).convert(rows);

    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final path = '${directory.path}/sleep_$timestamp.csv';
    final file = File(path);
    await file.writeAsBytes(utf8.encode(csv), flush: true);
    return file;
  }

  Future<void> shareSleepAnalyticsCsv({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final file = await exportSleepAnalyticsCsv(
      startDate: startDate,
      endDate: endDate,
    );
    await Share.shareXFiles([
      XFile(file.path),
    ], text: 'Exportación para analítica: sleep.csv');
  }

  Future<File> exportMedicationsAnalyticsCsv({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
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
      ['Día', 'Hora', 'Medicamento', 'Unidad', 'Cantidad', 'Notas'],
    ];

    if (allEvents.isEmpty) {
      rows.add(['NO DATA', '', '', '', '', '']);
    } else {
      for (final item in allEvents) {
        final dayDate = item['dayDate'] as DateTime;
        final event = item['event'] as IntakeEvent;
        final medication = item['medication'];

        final quantityText =
            (event.amountNumerator == null || event.amountDenominator == null)
            ? '—'
            : FractionHelper.fractionToText(
                event.amountNumerator!,
                event.amountDenominator!,
              );

        rows.add([
          dateFormat.format(dayDate),
          timeFormat.format(event.takenAt),
          medication?.name ?? 'Medicamento ${event.medicationId}',
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
    final path = '${directory.path}/medications_$timestamp.csv';
    final file = File(path);
    await file.writeAsBytes(utf8.encode(csv), flush: true);
    return file;
  }

  Future<void> shareMedicationsAnalyticsCsv({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final file = await exportMedicationsAnalyticsCsv(
      startDate: startDate,
      endDate: endDate,
    );
    await Share.shareXFiles([
      XFile(file.path),
    ], text: 'Exportación para analítica: medications.csv');
  }

  Future<File> exportToXlsx({DateTime? startDate, DateTime? endDate}) async {
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
    if (defaultSheet != null && defaultSheet != 'Sueño') {
      excel.rename(defaultSheet, 'Sueño');
    }

    final sleepSheet = excel['Sueño'];
    final medsSheet = excel['Medicaciones'];

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

    // Headers
    sleepSheet.appendRow([
      TextCellValue('Noche'),
      TextCellValue('Calidad'),
      TextCellValue('Descripción'),
      TextCellValue('Horas'),
      TextCellValue('Cómo'),
      TextCellValue('Comentarios'),
    ]);

    if (filteredSleep.isEmpty) {
      sleepSheet.appendRow([
        TextCellValue('NO DATA'),
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
          TextCellValue(_getSleepQualityLabel(entry.sleepQuality)),
          TextCellValue(_formatDurationMinutes(entry.sleepDurationMinutes)),
          TextCellValue(_getSleepContinuityLabel(entry.sleepContinuity)),
          TextCellValue(entry.notes ?? ''),
        ]);
      }
    }

    medsSheet.appendRow([
      TextCellValue('Día'),
      TextCellValue('Hora'),
      TextCellValue('Medicamento'),
      TextCellValue('Unidad'),
      TextCellValue('Cantidad'),
      TextCellValue('Nota'),
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
        TextCellValue('NO DATA'),
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

        final quantityText =
            (event.amountNumerator == null || event.amountDenominator == null)
            ? '—'
            : FractionHelper.fractionToText(
                event.amountNumerator!,
                event.amountDenominator!,
              );

        medsSheet.appendRow([
          TextCellValue(dateFormat.format(dayDate)),
          TextCellValue(timeFormat.format(event.takenAt)),
          TextCellValue(
            medication?.name ?? 'Medicamento ${event.medicationId}',
          ),
          TextCellValue(medication?.unit ?? ''),
          TextCellValue(quantityText),
          TextCellValue(event.note ?? ''),
        ]);
      }
    }

    excel.setDefaultSheet('Sueño');

    final bytes = excel.encode();
    if (bytes == null) {
      throw Exception('No se pudo generar el archivo Excel');
    }

    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final path = '${directory.path}/diario_medicamentos_$timestamp.xlsx';
    final file = File(path);
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  Future<void> shareXlsx({DateTime? startDate, DateTime? endDate}) async {
    final file = await exportToXlsx(startDate: startDate, endDate: endDate);
    await Share.shareXFiles([
      XFile(file.path),
    ], text: 'Exportación Excel (.xlsx)');
  }

  Future<File> exportToPDF({DateTime? startDate, DateTime? endDate}) async {
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
      db,
      dateFormat,
      timeFormat,
      startDate: startDate,
      endDate: endDate,
    );

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Text(
            'Diario (Sueño + Medicación)',
            style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            'Exportado: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}',
            style: const pw.TextStyle(fontSize: 10),
          ),
          pw.SizedBox(height: 24),

          pw.Text(
            'Registro de Sueño',
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
              'Noche',
              'Calidad',
              'Descripción',
              'Horas',
              'Cómo',
              'Comentarios',
            ],
            data: filteredSleep.isEmpty
                ? [
                    ['NO DATA', '', '', '', '', ''],
                  ]
                : filteredSleep
                      .map(
                        (e) => [
                          dateFormat.format(e.nightDate),
                          e.sleepQuality.toString(),
                          _getSleepQualityLabel(e.sleepQuality),
                          _formatDurationMinutes(e.sleepDurationMinutes),
                          _getSleepContinuityLabel(e.sleepContinuity),
                          e.notes ?? '',
                        ],
                      )
                      .toList(),
          ),
          pw.SizedBox(height: 24),

          pw.Text(
            'Diario de Medicaciones',
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
              'Día',
              'Hora',
              'Medicamento',
              'Unidad',
              'Cantidad',
              'Nota',
            ],
            data: medData.isEmpty
                ? [
                    ['NO DATA', '', '', '', '', ''],
                  ]
                : medData,
          ),
        ],
      ),
    );

    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final path = '${directory.path}/diario_medicamentos_$timestamp.pdf';
    final file = File(path);
    await file.writeAsBytes(await doc.save());

    return file;
  }

  Future<void> sharePDF({DateTime? startDate, DateTime? endDate}) async {
    final file = await exportToPDF(startDate: startDate, endDate: endDate);
    await Share.shareXFiles([XFile(file.path)], text: 'Exportación PDF');
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

    final events = await db.getAllIntakeEvents();

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

      data.add([
        dateFormat.format(dayDate),
        timeFormat.format(event.takenAt),
        medication?.name ?? 'Medicamento ${event.medicationId}',
        medication?.unit ?? '',
        (event.amountNumerator == null || event.amountDenominator == null)
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

  String _getSleepQualityLabel(int quality) {
    switch (quality) {
      case 1:
        return 'Muy mal';
      case 2:
        return 'Mal';
      case 3:
        return 'Regular';
      case 4:
        return 'Bien';
      case 5:
        return 'Muy bien';
      default:
        return '';
    }
  }
}
