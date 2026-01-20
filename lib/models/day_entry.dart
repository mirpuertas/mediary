class DayEntry {
  final int? id;
  final DateTime entryDate;
  final int? sleepQuality;
  final String? sleepNotes;
  final int? sleepDurationMinutes;
  final int? sleepContinuity;
  final int? dayMood;
  final String? dayNotes;

  DayEntry({
    this.id,
    required this.entryDate,
    this.sleepQuality,
    this.sleepNotes,
    this.sleepDurationMinutes,
    this.sleepContinuity,
    this.dayMood,
    this.dayNotes,
  });

  DateTime get dateOnly =>
      DateTime(entryDate.year, entryDate.month, entryDate.day);

  Map<String, dynamic> toMap() => {
    'id': id,
    'entry_date': dateOnly.toIso8601String(),
    'sleep_quality': sleepQuality,
    'sleep_notes': sleepNotes,
    'sleep_duration_minutes': sleepDurationMinutes,
    'sleep_continuity': sleepContinuity,
    'day_mood': dayMood,
    'day_notes': dayNotes,
  };

  factory DayEntry.fromMap(Map<String, dynamic> map) => DayEntry(
    id: map['id'] as int?,
    entryDate: DateTime.parse(map['entry_date'] as String),
    sleepQuality: map['sleep_quality'] as int?,
    sleepNotes: map['sleep_notes'] as String?,
    sleepDurationMinutes: map['sleep_duration_minutes'] as int?,
    sleepContinuity: map['sleep_continuity'] as int?,
    dayMood: map['day_mood'] as int?,
    dayNotes: map['day_notes'] as String?,
  );

  DayEntry copyWith({
    int? id,
    DateTime? entryDate,
    int? sleepQuality,
    String? sleepNotes,
    int? sleepDurationMinutes,
    int? sleepContinuity,
    int? dayMood,
    String? dayNotes,
  }) {
    return DayEntry(
      id: id ?? this.id,
      entryDate: entryDate ?? this.entryDate,
      sleepQuality: sleepQuality ?? this.sleepQuality,
      sleepNotes: sleepNotes ?? this.sleepNotes,
      sleepDurationMinutes: sleepDurationMinutes ?? this.sleepDurationMinutes,
      sleepContinuity: sleepContinuity ?? this.sleepContinuity,
      dayMood: dayMood ?? this.dayMood,
      dayNotes: dayNotes ?? this.dayNotes,
    );
  }
}
