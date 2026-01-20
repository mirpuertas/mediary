DateTime parseDateOnly(String? raw, {DateTime? fallback}) {
  if (raw == null) return fallback ?? DateTime.now();

  final parts = raw.trim().split('-');
  if (parts.length != 3) return fallback ?? DateTime.now();

  final y = int.tryParse(parts[0]);
  final m = int.tryParse(parts[1]);
  final d = int.tryParse(parts[2]);

  if (y == null || m == null || d == null) return fallback ?? DateTime.now();
  return DateTime(y, m, d);
}
