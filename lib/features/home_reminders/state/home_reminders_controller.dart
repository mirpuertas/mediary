import 'package:flutter/foundation.dart';

import '../data/home_reminders_repository.dart';

class HomeRemindersController extends ChangeNotifier {
  final HomeRemindersRepository _repo;

  HomeRemindersController({required HomeRemindersRepository repo})
    : _repo = repo;

  bool _isLoading = false;
  Object? _error;
  TodayRemindersBundle? _data;

  bool get isLoading => _isLoading;
  Object? get error => _error;
  TodayRemindersBundle? get data => _data;

  Future<void> loadToday({bool force = false}) async {
    if (_isLoading) return;
    if (!force && _data != null) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (kDebugMode) {
        debugPrint('📥 HomeRemindersController: Loading today reminders...');
      }
      _data = await _repo.loadToday();
      if (kDebugMode) {
        debugPrint(
          '✅ HomeRemindersController: Loaded ${_data?.reminders.length} reminders',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ HomeRemindersController Error: $e');
      }
      _error = e;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() => loadToday(force: true);
}
