import '../../../services/notification_service.dart';
import '../../medication/data/intake_repository.dart';

class HomeNotificationsRepository {
  final IntakeRepository intakeRepo;

  HomeNotificationsRepository({IntakeRepository? intakeRepo})
    : intakeRepo = intakeRepo ?? IntakeRepository();

  Future<List<Map<String, dynamic>>> consumePendingCompletesDetailed() {
    return NotificationService.instance.consumePendingCompletesDetailed();
  }

  Future<String?> consumePendingOpenPayload() {
    return NotificationService.instance.consumePendingOpen();
  }

  Future<Set<DateTime>> createIntakeEventsFromNotifications({
    required List<int> medicationIds,
    required DateTime takenAt,
    required String autoLoggedNote,
    required String autoLoggedWithApplicationNote,
    required String autoLoggedWithoutDoseNote,
  }) async {
    final affectedDays = <DateTime>{};

    for (final medicationId in medicationIds) {
      final day = await intakeRepo.createIntakeEventFromNotification(
        medicationId: medicationId,
        takenAt: takenAt,
        autoLoggedNote: autoLoggedNote,
        autoLoggedWithApplicationNote: autoLoggedWithApplicationNote,
        autoLoggedWithoutDoseNote: autoLoggedWithoutDoseNote,
      );
      affectedDays.add(day);
    }

    return affectedDays;
  }
}
