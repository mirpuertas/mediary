class IntakeEvent {
  final int? id;
  final int? dayEntryId;
  final int medicationId;
  final DateTime takenAt;
  final int? amountNumerator;
  final int? amountDenominator;
  final String? note;

  IntakeEvent({
    this.id,
    this.dayEntryId,
    required this.medicationId,
    required this.takenAt,
    this.amountNumerator,
    this.amountDenominator,
    this.note,
  }) : assert(
         (amountNumerator == null && amountDenominator == null) ||
             ((amountNumerator ?? 0) > 0 && (amountDenominator ?? 0) > 0),
       );

  bool get hasKnownDose => amountNumerator != null && amountDenominator != null;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'day_entry_id': dayEntryId,
      'medication_id': medicationId,
      'taken_at': takenAt.toIso8601String(),
      'amount_numerator': amountNumerator,
      'amount_denominator': amountDenominator,
      'note': note,
    };
  }

  factory IntakeEvent.fromMap(Map<String, dynamic> map) {
    return IntakeEvent(
      id: map['id'] as int?,
      dayEntryId: map['day_entry_id'] as int?,
      medicationId: map['medication_id'] as int,
      takenAt: DateTime.parse(map['taken_at'] as String),
      amountNumerator: map['amount_numerator'] as int?,
      amountDenominator: map['amount_denominator'] as int?,
      note: map['note'] as String?,
    );
  }

  IntakeEvent copyWith({
    int? id,
    int? dayEntryId,
    int? medicationId,
    DateTime? takenAt,
    int? amountNumerator,
    int? amountDenominator,
    String? note,
  }) {
    return IntakeEvent(
      id: id ?? this.id,
      dayEntryId: dayEntryId ?? this.dayEntryId,
      medicationId: medicationId ?? this.medicationId,
      takenAt: takenAt ?? this.takenAt,
      amountNumerator: amountNumerator ?? this.amountNumerator,
      amountDenominator: amountDenominator ?? this.amountDenominator,
      note: note ?? this.note,
    );
  }
}
