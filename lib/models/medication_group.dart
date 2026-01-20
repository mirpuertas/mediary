class MedicationGroup {
  final int? id;
  final String name;
  final bool isArchived;

  MedicationGroup({this.id, required this.name, this.isArchived = false});

  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name, 'is_archived': isArchived ? 1 : 0};
  }

  factory MedicationGroup.fromMap(Map<String, dynamic> map) {
    return MedicationGroup(
      id: map['id'] as int?,
      name: map['name'] as String,
      isArchived: (map['is_archived'] as int?) == 1,
    );
  }

  MedicationGroup copyWith({int? id, String? name, bool? isArchived}) {
    return MedicationGroup(
      id: id ?? this.id,
      name: name ?? this.name,
      isArchived: isArchived ?? this.isArchived,
    );
  }
}
