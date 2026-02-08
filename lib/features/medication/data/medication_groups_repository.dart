import '../../../models/medication.dart';
import '../../../models/medication_group.dart';
import '../../../models/medication_group_reminder.dart';
import '../../../services/database_helper.dart';

class MedicationGroupsRepository {
  final DatabaseHelper _db;

  MedicationGroupsRepository({DatabaseHelper? db})
      : _db = db ?? DatabaseHelper.instance;

  Future<List<MedicationGroup>> listGroups({bool includeArchived = true}) {
    return _db.getAllMedicationGroups(includeArchived: includeArchived);
  }

  Future<MedicationGroup> createGroup(MedicationGroup group) {
    return _db.createMedicationGroup(group);
  }

  Future<MedicationGroup?> getGroup(int id) => _db.getMedicationGroup(id);

  Future<int> updateGroup(MedicationGroup group) => _db.updateMedicationGroup(group);

  Future<int> archiveGroup(int id) => _db.archiveMedicationGroup(id);

  Future<int> unarchiveGroup(int id) => _db.unarchiveMedicationGroup(id);

  Future<int> deleteGroup(int id) => _db.deleteMedicationGroup(id);

  Future<List<Medication>> getGroupMembers(int groupId) {
    return _db.getMedicationGroupMembers(groupId);
  }

  Future<List<int>> getGroupMemberIds(int groupId) {
    return _db.getMedicationGroupMemberIds(groupId);
  }

  Future<void> setGroupMembers({
    required int groupId,
    required List<int> medicationIds,
  }) {
    return _db.setMedicationGroupMembers(groupId: groupId, medicationIds: medicationIds);
  }

  Future<List<MedicationGroupReminder>> listGroupReminders(int groupId) {
    return _db.getGroupRemindersByGroup(groupId);
  }

  Future<int> createGroupReminder(MedicationGroupReminder reminder) {
    return _db.createGroupReminder(reminder);
  }

  Future<int> updateGroupReminder(MedicationGroupReminder reminder) {
    return _db.updateGroupReminder(reminder);
  }

  Future<int> deleteGroupReminder(int id) => _db.deleteGroupReminder(id);
}
