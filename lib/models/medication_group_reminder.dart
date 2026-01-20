class MedicationGroupReminder {
  final int? id;
  final int groupId;
  final int hour;
  final int minute;
  final List<int> daysOfWeek; // 1=Lunes ... 7=Domingo
  final String? note;
  final bool requiresExactAlarm;

  MedicationGroupReminder({
    this.id,
    required this.groupId,
    required this.hour,
    required this.minute,
    this.daysOfWeek = const [1, 2, 3, 4, 5, 6, 7],
    this.note,
    this.requiresExactAlarm = false,
  });

  bool get isDaily => daysOfWeek.length == 7;

  String get timeText {
    final h = hour.toString().padLeft(2, '0');
    final m = minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String get daysText {
    if (isDaily) return 'Todos los días';
    const dayNames = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
    return daysOfWeek.map((d) => dayNames[d - 1]).join(' ');
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'group_id': groupId,
      'hour': hour,
      'minute': minute,
      'days_pattern': daysOfWeek.join(','),
      'note': note,
      'requires_exact_alarm': requiresExactAlarm ? 1 : 0,
    };
  }

  factory MedicationGroupReminder.fromMap(Map<String, dynamic> map) {
    final pattern = (map['days_pattern'] as String?) ?? '1,2,3,4,5,6,7';
    final days = pattern
        .split(',')
        .where((s) => s.isNotEmpty)
        .map((s) => int.parse(s))
        .toList();

    return MedicationGroupReminder(
      id: map['id'] as int?,
      groupId: map['group_id'] as int,
      hour: map['hour'] as int,
      minute: map['minute'] as int,
      daysOfWeek: days,
      note: map['note'] as String?,
      requiresExactAlarm: (map['requires_exact_alarm'] as int?) == 1,
    );
  }

  MedicationGroupReminder copyWith({
    int? id,
    int? groupId,
    int? hour,
    int? minute,
    List<int>? daysOfWeek,
    String? note,
    bool? requiresExactAlarm,
  }) {
    return MedicationGroupReminder(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      daysOfWeek: daysOfWeek ?? this.daysOfWeek,
      note: note ?? this.note,
      requiresExactAlarm: requiresExactAlarm ?? this.requiresExactAlarm,
    );
  }
}
