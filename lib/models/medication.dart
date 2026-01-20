enum MedicationType {
  tablet, // comprimido
  drops, // gotas
  capsule; // cápsula

  String get displayName {
    switch (this) {
      case MedicationType.tablet:
        return 'comprimido';
      case MedicationType.drops:
        return 'gotas';
      case MedicationType.capsule:
        return 'cápsula';
    }
  }

  static MedicationType fromString(String value) {
    switch (value) {
      case 'tablet':
        return MedicationType.tablet;
      case 'drops':
        return MedicationType.drops;
      case 'capsule':
        return MedicationType.capsule;
      default:
        return MedicationType.tablet;
    }
  }
}

// Sentinel para copyWith
const _sentinelInt = -999999;

class Medication {
  final int? id;
  final String name; // Nombre genérico (obligatorio)
  final String? brandName; // Nombre comercial (opcional)
  final String unit; // Unidad base (obligatoria)
  final MedicationType type; // Tipo de medicación
  final int? defaultDoseNumerator; // Dosis por defecto (opcional)
  final int? defaultDoseDenominator; // Dosis por defecto (opcional)
  final bool isArchived; // Archivado (no se muestra para elegir)

  Medication({
    this.id,
    required this.name,
    this.brandName,
    required this.unit,
    this.type = MedicationType.tablet,
    this.defaultDoseNumerator,
    this.defaultDoseDenominator,
    this.isArchived = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'brand_name': brandName,
      'unit': unit,
      'type': type.name,
      'default_dose_numerator': defaultDoseNumerator,
      'default_dose_denominator': defaultDoseDenominator,
      'is_archived': isArchived ? 1 : 0,
    };
  }

  factory Medication.fromMap(Map<String, dynamic> map) {
    return Medication(
      id: map['id'] as int?,
      name: map['name'] as String,
      brandName: map['brand_name'] as String?,
      unit: map['unit'] as String,
      type: MedicationType.fromString(map['type'] as String? ?? 'tablet'),
      defaultDoseNumerator: map['default_dose_numerator'] as int?,
      defaultDoseDenominator: map['default_dose_denominator'] as int?,
      isArchived: ((map['is_archived'] as int?) ?? 0) == 1,
    );
  }

  Medication copyWith({
    int? id,
    String? name,
    String? brandName,
    String? unit,
    MedicationType? type,
    int? defaultDoseNumerator = _sentinelInt,
    int? defaultDoseDenominator = _sentinelInt,
    bool? isArchived,
  }) {
    return Medication(
      id: id ?? this.id,
      name: name ?? this.name,
      brandName: brandName ?? this.brandName,
      unit: unit ?? this.unit,
      type: type ?? this.type,
      defaultDoseNumerator: defaultDoseNumerator == _sentinelInt
          ? this.defaultDoseNumerator
          : defaultDoseNumerator,
      defaultDoseDenominator: defaultDoseDenominator == _sentinelInt
          ? this.defaultDoseDenominator
          : defaultDoseDenominator,
      isArchived: isArchived ?? this.isArchived,
    );
  }

  @override
  String toString() {
    return 'Medication{id: $id, name: $name, brandName: $brandName, unit: $unit, type: ${type.displayName}}';
  }

  String get displayName {
    if (brandName != null && brandName!.isNotEmpty) {
      return '$name ($brandName)';
    }
    return name;
  }

  String get fullDescription {
    return '$name $unit ${type.displayName}';
  }
}
