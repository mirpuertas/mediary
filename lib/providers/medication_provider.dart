import 'package:flutter/material.dart';
import '../models/medication.dart';
import '../services/database_helper.dart';

class MedicationProvider with ChangeNotifier {
  List<Medication> _activeMedications = [];
  List<Medication> _allMedications = [];

  /// Medicamentos activos (no archivados): usados para listas y selección.
  List<Medication> get medications => _activeMedications;

  // Todos los medicamentos (incluye archivados): usado para mostrar historial.
  List<Medication> get allMedications => _allMedications;

  // Cargar todos los medicamentos (ordenados alfabéticamente case-insensitive)
  Future<void> loadMedications() async {
    // Se cargan ambas listas para evitar inconsistencias en UI.
    _allMedications = await DatabaseHelper.instance.getAllMedications();
    _activeMedications = _allMedications.where((m) => !m.isArchived).toList();
    notifyListeners();
  }

  // Agregar nuevo medicamento
  Future<void> addMedication(
    String name,
    String unit, {
    String? brandName,
    MedicationType type = MedicationType.tablet,
    int? defaultDoseNumerator,
    int? defaultDoseDenominator,
  }) async {
    final medication = Medication(
      name: name,
      unit: unit,
      brandName: brandName,
      type: type,
      defaultDoseNumerator: defaultDoseNumerator,
      defaultDoseDenominator: defaultDoseDenominator,
      isArchived: false,
    );
    final created = await DatabaseHelper.instance.createMedication(medication);
    _allMedications.add(created);
    _activeMedications.add(created);

    _allMedications.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );
    _activeMedications.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );
    notifyListeners();
  }

  // Actualizar medicamento
  Future<void> updateMedication(Medication medication) async {
    await DatabaseHelper.instance.updateMedication(medication);

    final allIndex = _allMedications.indexWhere((m) => m.id == medication.id);
    if (allIndex != -1) {
      _allMedications[allIndex] = medication;
    }

    // Recalcular activos desde all para reflejar cambios de archivado.
    _activeMedications = _allMedications.where((m) => !m.isArchived).toList();

    _allMedications.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );
    _activeMedications.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );

    notifyListeners();
  }

  // Archivar medicamento (no borra historial).
  Future<void> archiveMedication(int id) async {
    await DatabaseHelper.instance.archiveMedication(id);
    await loadMedications();
  }

  // Desarchivar medicamento.
  Future<void> unarchiveMedication(int id) async {
    await DatabaseHelper.instance.unarchiveMedication(id);
    await loadMedications();
  }

  // Eliminar medicamento
  Future<void> deleteMedication(int id) async {
    await DatabaseHelper.instance.deleteMedication(id);
    _allMedications.removeWhere((m) => m.id == id);
    _activeMedications.removeWhere((m) => m.id == id);
    notifyListeners();
  }

  // Obtener medicamento por ID
  Medication? getMedicationById(int id) {
    try {
      return _allMedications.firstWhere((m) => m.id == id);
    } catch (e) {
      return null;
    }
  }
}
