import '../../../models/intake_event.dart';

const _unset = Object();

class IntakeEventDraft {
  final DateTime takenAt;
  final int? medicationId;
  final int? numerator;
  final int? denominator;
  final String note;

  const IntakeEventDraft({
    required this.takenAt,
    required this.medicationId,
    required this.numerator,
    required this.denominator,
    required this.note,
  });

  factory IntakeEventDraft.newForDay(DateTime day, DateTime now) {
    return IntakeEventDraft(
      takenAt: DateTime(day.year, day.month, day.day, now.hour, now.minute),
      medicationId: null,
      numerator: 1,
      denominator: 1,
      note: '',
    );
  }

  factory IntakeEventDraft.fromModel(IntakeEvent event) {
    return IntakeEventDraft(
      takenAt: event.takenAt,
      medicationId: event.medicationId,
      numerator: event.amountNumerator,
      denominator: event.amountDenominator,
      note: event.note ?? '',
    );
  }

  IntakeEvent toModel({required int dayEntryId}) {
    final cleanedNote = note.trim().isEmpty ? null : note.trim();
    return IntakeEvent(
      id: null,
      dayEntryId: dayEntryId,
      medicationId: medicationId!,
      takenAt: takenAt,
      amountNumerator: numerator,
      amountDenominator: denominator,
      note: cleanedNote,
    );
  }

  IntakeEventDraft copyWith({
    DateTime? takenAt,
    Object? medicationId = _unset,
    Object? numerator = _unset,
    Object? denominator = _unset,
    String? note,
  }) {
    return IntakeEventDraft(
      takenAt: takenAt ?? this.takenAt,
      medicationId: identical(medicationId, _unset)
          ? this.medicationId
          : medicationId as int?,
      numerator:
          identical(numerator, _unset) ? this.numerator : numerator as int?,
      denominator: identical(denominator, _unset)
          ? this.denominator
          : denominator as int?,
      note: note ?? this.note,
    );
  }
}

