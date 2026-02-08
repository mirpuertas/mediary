import 'package:flutter/material.dart';
import '../../../models/medication.dart';
import '../data/medication_repository.dart';

/// Removes diacritics (accents) from a string for proper Spanish sorting.
/// E.g., "Ácido" becomes "Acido" so it sorts near "Alprazolam".
String _removeDiacritics(String str) {
  const withDiacritics = 'ÀÁÂÃÄÅàáâãäåÈÉÊËèéêëÌÍÎÏìíîïÒÓÔÕÖØòóôõöøÙÚÛÜùúûüÑñÇç';
  const withoutDiacritics =
      'AAAAAAaaaaaaEEEEeeeeIIIIiiiiOOOOOOooooooUUUUuuuuNnCc';

  return str.split('').map((char) {
    final index = withDiacritics.indexOf(char);
    return index != -1 ? withoutDiacritics[index] : char;
  }).join();
}

/// Compare two medication names ignoring case and diacritics (Spanish-friendly).
int _compareMedicationNames(Medication a, Medication b) {
  final nameA = _removeDiacritics(a.name.toLowerCase());
  final nameB = _removeDiacritics(b.name.toLowerCase());
  return nameA.compareTo(nameB);
}

/// Controller for medication state management.
class MedicationController extends ChangeNotifier {
  final MedicationRepository _repo;

  List<Medication> _activeMedications = [];
  List<Medication> _allMedications = [];

  MedicationController({required MedicationRepository repo}) : _repo = repo;

  /// Active medications (not archived): used for lists and selection.
  List<Medication> get medications => _activeMedications;

  /// All medications (includes archived): used for showing history.
  List<Medication> get allMedications => _allMedications;

  /// Load all medications (sorted alphabetically case-insensitive, diacritics-aware).
  Future<void> loadMedications() async {
    _allMedications = await _repo.getAllMedications();
    _allMedications.sort(_compareMedicationNames);
    _activeMedications = _allMedications.where((m) => !m.isArchived).toList();
    notifyListeners();
  }

  /// Add a new medication.
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
    final created = await _repo.createMedication(medication);
    _allMedications.add(created);
    _activeMedications.add(created);

    _allMedications.sort(_compareMedicationNames);
    _activeMedications.sort(_compareMedicationNames);
    notifyListeners();
  }

  /// Update an existing medication.
  Future<void> updateMedication(Medication medication) async {
    await _repo.updateMedication(medication);

    final allIndex = _allMedications.indexWhere((m) => m.id == medication.id);
    if (allIndex != -1) {
      _allMedications[allIndex] = medication;
    }

    // Recalculate active medications to reflect archival changes.
    _activeMedications = _allMedications.where((m) => !m.isArchived).toList();

    _allMedications.sort(_compareMedicationNames);
    _activeMedications.sort(_compareMedicationNames);

    notifyListeners();
  }

  /// Archive a medication (does not delete history).
  Future<void> archiveMedication(int id) async {
    await _repo.archiveMedication(id);
    await loadMedications();
  }

  /// Unarchive a medication.
  Future<void> unarchiveMedication(int id) async {
    await _repo.unarchiveMedication(id);
    await loadMedications();
  }

  /// Delete a medication permanently.
  Future<void> deleteMedication(int id) async {
    await _repo.deleteMedication(id);
    _allMedications.removeWhere((m) => m.id == id);
    _activeMedications.removeWhere((m) => m.id == id);
    notifyListeners();
  }

  /// Get medication by ID.
  Medication? getMedicationById(int id) {
    try {
      return _allMedications.firstWhere((m) => m.id == id);
    } catch (e) {
      return null;
    }
  }
}
