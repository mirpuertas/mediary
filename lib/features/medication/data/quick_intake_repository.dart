import '../../../models/day_entry.dart';
import '../../../models/intake_event.dart';
import '../../../models/medication.dart';
import '../../../services/database_helper.dart';
import 'intake_repository.dart';

class QuickIntakeRepository {
  final DatabaseHelper _db;
  final IntakeRepository _intakeRepo;

  QuickIntakeRepository({DatabaseHelper? db, IntakeRepository? intakeRepo})
    : _db = db ?? DatabaseHelper.instance,
      _intakeRepo = intakeRepo ?? IntakeRepository();

  Future<List<Medication>> getActiveMedicationsByIds(
    List<int> medicationIds,
  ) async {
    final meds = <Medication>[];
    for (final id in medicationIds) {
      final m = await _db.getMedication(id);
      if (m != null && !m.isArchived) {
        meds.add(m);
      }
    }
    meds.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return meds;
  }

  Future<DayEntry> ensureDayEntry(DateTime date) => _db.ensureDayEntry(date);

  Future<void> replaceIntakeEvents({
    required int dayEntryId,
    required List<IntakeEvent> events,
  }) async {
    await _intakeRepo.replaceForDayEntry(dayEntryId, events);
  }

  Future<Medication?> getMedication(int id) => _db.getMedication(id);
}
