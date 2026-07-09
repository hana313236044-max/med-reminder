import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:uhd/models/medicine_library_filter.dart';
import 'package:uhd/models/medicine_library_model.dart';

class MedicineLibraryRepository {
  MedicineLibraryRepository._();

  static final MedicineLibraryRepository instance = MedicineLibraryRepository._();
  static const String assetPath = 'assets/data/medicine_library.json';

  Future<List<MedicineLibraryMedicine>>? _cachedMedicines;

  Future<List<MedicineLibraryMedicine>> loadMedicines() {
    return _cachedMedicines ??= _loadMedicines();
  }

  void clearCache() {
    _cachedMedicines = null;
  }

  Future<List<MedicineLibraryMedicine>> _loadMedicines() async {
    final rawJson = await rootBundle.loadString(assetPath);
    final decoded = jsonDecode(rawJson);
    final List rawItems;
    if (decoded is List) {
      rawItems = decoded;
    } else if (decoded is Map<String, dynamic> &&
        decoded['medicines'] is List) {
      rawItems = decoded['medicines'] as List;
    } else {
      rawItems = const [];
    }

    final medicines = <MedicineLibraryMedicine>[];
    for (final item in rawItems) {
      if (item is! Map) continue;
      try {
        final medicine = MedicineLibraryMedicine.fromJson(
          Map<String, dynamic>.from(item),
        );
        if (medicine.id.trim().isNotEmpty && medicine.name.trim().isNotEmpty) {
          medicines.add(medicine);
        }
      } catch (_) {
        continue;
      }
    }
    medicines.sort(_compareByName);
    return medicines;
  }

  MedicineLibraryMedicine? findById(
    List<MedicineLibraryMedicine> medicines,
    String id,
  ) {
    final normalizedId = id.trim().toLowerCase();
    for (final medicine in medicines) {
      if (medicine.id.toLowerCase() == normalizedId) return medicine;
    }
    return null;
  }

  List<MedicineLibraryMedicine> queryMedicines(
    List<MedicineLibraryMedicine> medicines,
    MedicineLibraryFilter filter,
  ) {
    final terms = filter.searchText
        .trim()
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((term) => term.isNotEmpty)
        .toList();

    final filtered = medicines.where((medicine) {
      final medicineName = medicine.name.toLowerCase();
      if (terms.isNotEmpty &&
          !terms.every((term) => medicineName.contains(term))) {
        return false;
      }
      if (filter.category != null && medicine.category != filter.category) {
        return false;
      }
      if (filter.form != null && !medicine.forms.contains(filter.form)) {
        return false;
      }
      if (filter.ageGroup != null &&
          !medicine.ageGroup.contains(filter.ageGroup)) {
        return false;
      }
      if (!_matchesPrescription(medicine, filter.prescriptionFilter)) {
        return false;
      }
      if (!_matchesFoodInstruction(medicine, filter.foodFilter)) {
        return false;
      }
      if (filter.warningLevel != null &&
          medicine.warningLevel != filter.warningLevel) {
        return false;
      }
      if (filter.startingLetter != null &&
          !medicine.name.toUpperCase().startsWith(filter.startingLetter!)) {
        return false;
      }
      if (filter.tag != null &&
          !medicine.tags.any(
            (tag) => tag.toLowerCase() == filter.tag!.toLowerCase(),
          )) {
        return false;
      }
      return true;
    }).toList();

    _sortMedicines(filtered, filter.sort);
    return filtered;
  }

  List<String> availableCategories(List<MedicineLibraryMedicine> medicines) {
    return _sortedUnique(medicines.map((medicine) => medicine.category));
  }

  List<String> availableForms(List<MedicineLibraryMedicine> medicines) {
    return _sortedUnique(medicines.expand((medicine) => medicine.forms));
  }

  List<String> availableAgeGroups(List<MedicineLibraryMedicine> medicines) {
    return _sortedUnique(medicines.expand((medicine) => medicine.ageGroup));
  }

  List<String> availableTags(List<MedicineLibraryMedicine> medicines) {
    return _sortedUnique(medicines.expand((medicine) => medicine.tags));
  }

  List<String> _sortedUnique(Iterable<String> values) {
    final uniqueValues = values
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty && value != 'Not provided')
        .toSet()
        .toList();
    uniqueValues.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return uniqueValues;
  }

  bool _matchesPrescription(
    MedicineLibraryMedicine medicine,
    MedicineLibraryPrescriptionFilter filter,
  ) {
    switch (filter) {
      case MedicineLibraryPrescriptionFilter.all:
        return true;
      case MedicineLibraryPrescriptionFilter.prescriptionRequired:
        return medicine.prescriptionRequired;
      case MedicineLibraryPrescriptionFilter.noPrescriptionRequired:
        return !medicine.prescriptionRequired;
    }
  }

  bool _matchesFoodInstruction(
    MedicineLibraryMedicine medicine,
    MedicineLibraryFoodFilter filter,
  ) {
    final food = medicine.foodInstructions.toLowerCase();
    switch (filter) {
      case MedicineLibraryFoodFilter.any:
        return true;
      case MedicineLibraryFoodFilter.withFood:
        return food.contains('with food') &&
            !food.contains('with or without food');
      case MedicineLibraryFoodFilter.withoutFood:
        return food.contains('without food') &&
            !food.contains('with or without food');
      case MedicineLibraryFoodFilter.withOrWithoutFood:
        return food.contains('with or without food');
      case MedicineLibraryFoodFilter.beforeFood:
        return food.contains('before food') ||
            food.contains('before meals') ||
            food.contains('empty stomach');
      case MedicineLibraryFoodFilter.afterFood:
        return food.contains('after food') ||
            food.contains('after meals') ||
            food.contains('with meals');
    }
  }

  void _sortMedicines(
    List<MedicineLibraryMedicine> medicines,
    MedicineLibrarySort sort,
  ) {
    switch (sort) {
      case MedicineLibrarySort.az:
        medicines.sort(_compareByName);
        return;
      case MedicineLibrarySort.za:
        medicines.sort((a, b) => _compareByName(b, a));
        return;
      case MedicineLibrarySort.category:
        medicines.sort((a, b) {
          final categoryCompare = a.category.toLowerCase().compareTo(
            b.category.toLowerCase(),
          );
          return categoryCompare == 0 ? _compareByName(a, b) : categoryCompare;
        });
        return;
      case MedicineLibrarySort.prescriptionRequiredFirst:
        medicines.sort((a, b) {
          if (a.prescriptionRequired == b.prescriptionRequired) {
            return _compareByName(a, b);
          }
          return a.prescriptionRequired ? -1 : 1;
        });
        return;
      case MedicineLibrarySort.noPrescriptionFirst:
        medicines.sort((a, b) {
          if (a.prescriptionRequired == b.prescriptionRequired) {
            return _compareByName(a, b);
          }
          return a.prescriptionRequired ? 1 : -1;
        });
        return;
      case MedicineLibrarySort.mostWarnings:
        medicines.sort((a, b) {
          final warningCompare = b.warningCount.compareTo(a.warningCount);
          return warningCompare == 0 ? _compareByName(a, b) : warningCompare;
        });
        return;
      case MedicineLibrarySort.fewestWarnings:
        medicines.sort((a, b) {
          final warningCompare = a.warningCount.compareTo(b.warningCount);
          return warningCompare == 0 ? _compareByName(a, b) : warningCompare;
        });
        return;
    }
  }

  static int _compareByName(
    MedicineLibraryMedicine a,
    MedicineLibraryMedicine b,
  ) {
    return a.name.toLowerCase().compareTo(b.name.toLowerCase());
  }
}
