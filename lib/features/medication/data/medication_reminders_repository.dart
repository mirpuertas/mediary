import '../../../models/medication_reminder.dart';
import '../../../services/database_helper.dart';

class MedicationRemindersRepository {
  final DatabaseHelper _db;

  MedicationRemindersRepository({DatabaseHelper? db})
      : _db = db ?? DatabaseHelper.instance;

  Future<List<MedicationReminder>> listByMedication(int medicationId) {
    return _db.getRemindersByMedication(medicationId);
  }

  Future<int> create(MedicationReminder reminder) => _db.createReminder(reminder);

  Future<int> update(MedicationReminder reminder) => _db.updateReminder(reminder);

  Future<int> delete(int id) => _db.deleteReminder(id);
}

