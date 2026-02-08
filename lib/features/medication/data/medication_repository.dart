import '../../../services/database_helper.dart';
import '../../../models/medication.dart';

class MedicationRepository {
  final DatabaseHelper _db;

  MedicationRepository({DatabaseHelper? db})
    : _db = db ?? DatabaseHelper.instance;

  Future<List<Medication>> getAllMedications() async {
    return _db.getAllMedications();
  }

  Future<Medication?> getMedication(int id) => _db.getMedication(id);

  Future<Medication> createMedication(Medication medication) async {
    return _db.createMedication(medication);
  }

  Future<void> updateMedication(Medication medication) async {
    await _db.updateMedication(medication);
  }

  Future<void> archiveMedication(int id) async {
    await _db.archiveMedication(id);
  }

  Future<void> unarchiveMedication(int id) async {
    await _db.unarchiveMedication(id);
  }

  Future<void> deleteMedication(int id) async {
    await _db.deleteMedication(id);
  }
}
