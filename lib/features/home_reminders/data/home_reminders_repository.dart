import '../../../services/database_helper.dart';
import '../../../services/notification_service.dart';

typedef TodayRemindersBundle = ({
  List<Map<String, dynamic>> reminders,
  List<Map<String, dynamic>> groupReminders,
  List<Map<String, dynamic>> snoozes,
});

class HomeRemindersRepository {
  final DatabaseHelper _db;

  HomeRemindersRepository({DatabaseHelper? db})
    : _db = db ?? DatabaseHelper.instance;

  Future<TodayRemindersBundle> loadToday() async {
    final reminders = await _db.getTodayReminders();
    final groupReminders = await _db.getTodayGroupReminders();
    final snoozes = await NotificationService.instance
        .getTodaySnoozedReminders();
    return (
      reminders: reminders,
      groupReminders: groupReminders,
      snoozes: snoozes,
    );
  }
}
