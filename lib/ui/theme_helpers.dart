import 'package:flutter/material.dart';

Color muted(BuildContext context, [double a = 0.70]) =>
    Theme.of(context).colorScheme.onSurface.withValues(alpha: a);

Color dividerColor(BuildContext context, [double a = 0.12]) =>
    Theme.of(context).colorScheme.onSurface.withValues(alpha: a);

IconData moodIcon(int mood) {
  switch (mood) {
    case 1:
      return Icons.sentiment_very_dissatisfied;
    case 2:
      return Icons.sentiment_dissatisfied;
    case 3:
      return Icons.sentiment_neutral;
    case 4:
      return Icons.sentiment_satisfied;
    case 5:
      return Icons.sentiment_very_satisfied;
    default:
      return Icons.sentiment_neutral;
  }
}

double _hueForMood(int mood) {
  // Hues fijos = separación perceptual garantizada en light y dark
  switch (mood) {
    case 1:
      return 2; // rojo
    case 2:
      return 28; // naranja
    case 3:
      return 210; // azul-gris (neutral)
    case 4:
      return 140; // verde
    case 5:
      return 280; // violeta
    default:
      return 210;
  }
}

Color _moodFromHsl(BuildContext context, int mood) {
  final isDark = Theme.of(context).brightness == Brightness.dark;

  final h = _hueForMood(mood);

  // Ajustes por modo: en dark sube saturación y luz un poco para no apagarse.
  final s = isDark ? 0.62 : 0.55;
  final l = isDark ? 0.62 : 0.46;

  return HSLColor.fromAHSL(1.0, h, s, l).toColor();
}

/// Color “semántico” de ánimo (independiente del ColorScheme, pero dark-mode friendly).
Color moodColor(BuildContext context, int mood) => _moodFromHsl(context, mood);

/// Fondo/halo del botón
Color moodBg(BuildContext context, int mood, {required bool selected}) {
  if (!selected) return Colors.transparent;
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final c = moodColor(context, mood);
  return c.withValues(alpha: isDark ? 0.20 : 0.14);
}

/// Borde del botón
Color moodBorder(BuildContext context, int mood, {required bool selected}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final c = moodColor(context, mood);
  if (selected) return c.withValues(alpha: 0.95);
  return c.withValues(alpha: isDark ? 0.60 : 0.45);
}

/// Ícono del botón
Color moodIconColor(BuildContext context, int mood, {required bool selected}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final c = moodColor(context, mood);
  if (selected) return c.withValues(alpha: 0.98);
  return c.withValues(alpha: isDark ? 0.90 : 0.76);
}

Color onColorForDot(Color dot) {
  final b = ThemeData.estimateBrightnessForColor(dot);
  return b == Brightness.dark ? Colors.white : Colors.black;
}
