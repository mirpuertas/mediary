class MedicationReminder {
  final int? id;
  final int medicationId;
  final int hour;
  final int minute;
  final List<int> daysOfWeek;
  final String? note;
  final bool requiresExactAlarm;

  MedicationReminder({
    this.id,
    required this.medicationId,
    required this.hour,
    required this.minute,
    this.daysOfWeek = const [1, 2, 3, 4, 5, 6, 7],
    this.note,
    this.requiresExactAlarm = false,
  });

  bool get isDaily => daysOfWeek.length == 7;

  String get daysText {
    if (isDaily) return 'Todos los días';

    const dayNames = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
    return daysOfWeek.map((d) => dayNames[d - 1]).join(' ');
  }

  String get timeText {
    final h = hour.toString().padLeft(2, '0');
    final m = minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'medication_id': medicationId,
      'hour': hour,
      'minute': minute,
      'days_pattern': daysOfWeek.join(','),
      'note': note,
      'requires_exact_alarm': requiresExactAlarm ? 1 : 0,
    };
  }

  factory MedicationReminder.fromMap(Map<String, dynamic> map) {
    final pattern = (map['days_pattern'] as String?) ?? '1,2,3,4,5,6,7';
    final days = pattern
        .split(',')
        .where((s) => s.isNotEmpty)
        .map((s) => int.parse(s))
        .toList();

    return MedicationReminder(
      id: map['id'] as int?,
      medicationId: map['medication_id'] as int,
      hour: map['hour'] as int,
      minute: map['minute'] as int,
      daysOfWeek: days,
      note: map['note'] as String?,
      requiresExactAlarm: (map['requires_exact_alarm'] as int?) == 1,
    );
  }

  MedicationReminder copyWith({
    int? id,
    int? medicationId,
    int? hour,
    int? minute,
    List<int>? daysOfWeek,
    String? note,
    bool? requiresExactAlarm,
  }) {
    return MedicationReminder(
      id: id ?? this.id,
      medicationId: medicationId ?? this.medicationId,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      daysOfWeek: daysOfWeek ?? this.daysOfWeek,
      note: note ?? this.note,
      requiresExactAlarm: requiresExactAlarm ?? this.requiresExactAlarm,
    );
  }

  @override
  String toString() {
    return 'MedicationReminder{id: $id, medicationId: $medicationId, time: $timeText, days: $daysText}';
  }
}
