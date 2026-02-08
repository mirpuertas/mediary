import 'dart:async';
import 'dart:ui' show Locale;

import 'package:flutter/foundation.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum LocaleOverride { system, es, en }

class AppPreferencesController extends ChangeNotifier {
  static const _keyLocaleOverride = 'locale_override';

  bool _loaded = false;
  LocaleOverride _localeOverride = LocaleOverride.system;

  bool get loaded => _loaded;
  LocaleOverride get localeOverride => _localeOverride;

  Locale? get locale {
    switch (_localeOverride) {
      case LocaleOverride.system:
        return null;
      case LocaleOverride.es:
        return const Locale('es');
      case LocaleOverride.en:
        return const Locale('en');
    }
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final rawLocale = prefs.getString(_keyLocaleOverride) ?? 'system';

    _localeOverride = switch (rawLocale) {
      'es' => LocaleOverride.es,
      'en' => LocaleOverride.en,
      _ => LocaleOverride.system,
    };

    _loaded = true;
    notifyListeners();

    final resolved = locale;
    if (resolved != null) {
      unawaited(initializeDateFormatting(resolved.toString(), null));
    }
  }

  Future<void> setLocaleOverride(LocaleOverride value) async {
    if (_localeOverride == value) return;
    _localeOverride = value;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    final raw = switch (value) {
      LocaleOverride.system => 'system',
      LocaleOverride.es => 'es',
      LocaleOverride.en => 'en',
    };
    await prefs.setString(_keyLocaleOverride, raw);

    final resolved = locale;
    if (resolved != null) {
      unawaited(initializeDateFormatting(resolved.toString(), null));
    }
  }
}
