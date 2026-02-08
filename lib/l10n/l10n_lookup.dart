import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/widgets.dart';

import 'l10n.dart';

AppLocalizations lookupL10n([Locale? locale]) {
  final resolved = locale ?? PlatformDispatcher.instance.locale;
  try {
    return lookupAppLocalizations(resolved);
  } catch (_) {
    try {
      return lookupAppLocalizations(const Locale('es'));
    } catch (_) {
      return lookupAppLocalizations(AppLocalizations.supportedLocales.first);
    }
  }
}

