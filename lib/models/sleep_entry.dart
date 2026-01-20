class SleepEntry {
  final int? id;
  final DateTime nightDate;
  final int sleepQuality; // 1-5 estrellas
  final String? notes;
  final int? sleepDurationMinutes; // opcional
  /// 1 = de corrido, 2 = cortado/con despertares
  final int? sleepContinuity;

  SleepEntry({
    this.id,
    required this.nightDate,
    required this.sleepQuality,
    this.notes,
    this.sleepDurationMinutes,
    this.sleepContinuity,
  }) : assert(
         sleepQuality >= 1 && sleepQuality <= 5,
         'Calidad debe estar entre 1 y 5',
       );

  DateTime get dateOnly => _dateOnly(nightDate);

  static DateTime _dateOnly(DateTime dt) {
    return DateTime(dt.year, dt.month, dt.day);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'night_date': dateOnly.toIso8601String(),
      'sleep_quality': sleepQuality,
      'notes': notes,
      'sleep_duration_minutes': sleepDurationMinutes,
      'sleep_continuity': sleepContinuity,
    };
  }

  factory SleepEntry.fromMap(Map<String, dynamic> map) {
    return SleepEntry(
      id: map['id'] as int?,
      nightDate: DateTime.parse(map['night_date'] as String),
      sleepQuality: map['sleep_quality'] as int,
      notes: map['notes'] as String?,
      sleepDurationMinutes: map['sleep_duration_minutes'] as int?,
      sleepContinuity: map['sleep_continuity'] as int?,
    );
  }

  SleepEntry copyWith({
    int? id,
    DateTime? nightDate,
    int? sleepQuality,
    String? notes,
    int? sleepDurationMinutes,
    int? sleepContinuity,
  }) {
    return SleepEntry(
      id: id ?? this.id,
      nightDate: nightDate ?? this.nightDate,
      sleepQuality: sleepQuality ?? this.sleepQuality,
      notes: notes ?? this.notes,
      sleepDurationMinutes: sleepDurationMinutes ?? this.sleepDurationMinutes,
      sleepContinuity: sleepContinuity ?? this.sleepContinuity,
    );
  }

  @override
  String toString() {
    return 'SleepEntry{id: $id, nightDate: $nightDate, quality: $sleepQuality}';
  }
}
