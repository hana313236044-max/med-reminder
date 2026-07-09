import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:uhd/models/pharmacy_filter_model.dart';
import 'package:uhd/models/pharmacy_model.dart';
import 'package:uhd/services/pharmacy_repository.dart';

class JsonPharmacyRepository implements PharmacyRepository {
  JsonPharmacyRepository._();

  static final JsonPharmacyRepository instance = JsonPharmacyRepository._();
  static const String assetPath = 'assets/data/pharmacies.json';

  Future<List<Pharmacy>>? _cachedPharmacies;

  @override
  Future<List<Pharmacy>> loadPharmacies() {
    return _cachedPharmacies ??= _loadPharmacies();
  }

  @override
  void clearCache() {
    _cachedPharmacies = null;
  }

  Future<List<Pharmacy>> _loadPharmacies() async {
    final rawJson = await rootBundle.loadString(assetPath);
    final decoded = jsonDecode(rawJson);
    final List rawItems;
    if (decoded is List) {
      rawItems = decoded;
    } else if (decoded is Map<String, dynamic> &&
        decoded['pharmacies'] is List) {
      rawItems = decoded['pharmacies'] as List;
    } else {
      rawItems = const [];
    }

    final pharmacies = <Pharmacy>[];
    for (final item in rawItems) {
      if (item is! Map) continue;
      try {
        final pharmacy = Pharmacy.fromJson(Map<String, dynamic>.from(item));
        if (pharmacy.id.trim().isNotEmpty &&
            pharmacy.name.trim().isNotEmpty) {
          pharmacies.add(pharmacy);
        }
      } catch (_) {
        continue;
      }
    }
    pharmacies.sort(_compareByName);
    return pharmacies;
  }

  @override
  Pharmacy? findById(List<Pharmacy> pharmacies, String id) {
    final normalized = id.trim().toLowerCase();
    for (final pharmacy in pharmacies) {
      if (pharmacy.id.toLowerCase() == normalized) return pharmacy;
    }
    return null;
  }

  @override
  List<Pharmacy> findPharmaciesWithMedicine(
    List<Pharmacy> pharmacies,
    String medicineId, {
    int limit = 10,
  }) {
    final normalized = medicineId.trim().toLowerCase();
    final matches = pharmacies.where((pharmacy) {
      return pharmacy.inventory.any(
        (item) =>
            item.medicineId.toLowerCase() == normalized &&
            item.inStock &&
            item.stockQuantity > 0,
      );
    }).toList();
    matches.sort((a, b) {
      final ratingCompare = b.rating.compareTo(a.rating);
      return ratingCompare == 0 ? _compareByName(a, b) : ratingCompare;
    });
    return matches.take(limit).toList();
  }

  @override
  List<Pharmacy> queryPharmacies(
    List<Pharmacy> pharmacies,
    PharmacyFilter filter,
  ) {
    final terms = filter.searchText
        .trim()
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((term) => term.isNotEmpty)
        .toList();
    final medicineTerms = filter.medicineSearchText
        .trim()
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((term) => term.isNotEmpty)
        .toList();

    final filtered = pharmacies.where((pharmacy) {
      if (terms.isNotEmpty &&
          !terms.every((term) => pharmacy.name.toLowerCase().contains(term))) {
        return false;
      }
      if (medicineTerms.isNotEmpty &&
          !_matchesMedicineSearch(pharmacy, medicineTerms)) {
        return false;
      }
      if (filter.city != null && pharmacy.city != filter.city) return false;
      if (filter.area != null && pharmacy.area != filter.area) return false;
      if (!_matchesDelivery(pharmacy, filter.deliveryFilter)) return false;
      if (!_matchesOpen(pharmacy, filter.openFilter)) return false;
      if (!_matchesAvailability(pharmacy, filter)) return false;
      if (!_matchesPrescription(pharmacy, filter.prescriptionFilter)) {
        return false;
      }
      if (filter.service != null &&
          !pharmacy.services.any(
            (service) =>
                service.toLowerCase() == filter.service!.toLowerCase(),
          )) {
        return false;
      }
      if (filter.paymentMethod != null &&
          !pharmacy.paymentMethods.any(
            (method) =>
                method.toLowerCase() == filter.paymentMethod!.toLowerCase(),
          )) {
        return false;
      }
      return true;
    }).toList();

    _sort(filtered, filter.sort);
    return filtered;
  }

  @override
  List<String> availableCities(List<Pharmacy> pharmacies) {
    return _sortedUnique(pharmacies.map((pharmacy) => pharmacy.city));
  }

  @override
  List<String> availableAreas(List<Pharmacy> pharmacies, String city) {
    return _sortedUnique(
      pharmacies
          .where((pharmacy) => pharmacy.city == city)
          .map((pharmacy) => pharmacy.area),
    );
  }

  @override
  List<String> availableServices(List<Pharmacy> pharmacies) {
    return _sortedUnique(pharmacies.expand((pharmacy) => pharmacy.services));
  }

  @override
  List<String> availablePaymentMethods(List<Pharmacy> pharmacies) {
    return _sortedUnique(
      pharmacies.expand((pharmacy) => pharmacy.paymentMethods),
    );
  }

  @override
  List<String> availableInventoryCategories(Pharmacy pharmacy) {
    return _sortedUnique(pharmacy.inventory.map((item) => item.category));
  }

  @override
  List<String> availableInventoryForms(Pharmacy pharmacy) {
    return _sortedUnique(pharmacy.inventory.map((item) => item.form));
  }

  bool _matchesDelivery(
    Pharmacy pharmacy,
    PharmacyDeliveryFilter filter,
  ) {
    switch (filter) {
      case PharmacyDeliveryFilter.all:
        return true;
      case PharmacyDeliveryFilter.deliveryAvailable:
        return pharmacy.deliveryAvailable;
    }
  }

  bool _matchesMedicineSearch(Pharmacy pharmacy, List<String> terms) {
    return pharmacy.inventory.any((item) {
      if (!item.inStock || item.stockQuantity <= 0) return false;
      return terms.every((term) => item.searchableText.contains(term));
    });
  }

  bool _matchesOpen(Pharmacy pharmacy, PharmacyOpenFilter filter) {
    switch (filter) {
      case PharmacyOpenFilter.all:
        return true;
      case PharmacyOpenFilter.open24Hours:
        return pharmacy.isOpen24Hours;
      case PharmacyOpenFilter.not24Hours:
        return !pharmacy.isOpen24Hours;
    }
  }

  bool _matchesAvailability(Pharmacy pharmacy, PharmacyFilter filter) {
    switch (filter.medicineAvailabilityFilter) {
      case PharmacyMedicineAvailabilityFilter.all:
        return true;
      case PharmacyMedicineAvailabilityFilter.hasSelectedMedicine:
        final medicineId = filter.selectedMedicineId;
        if (medicineId == null || medicineId.trim().isEmpty) {
          return pharmacy.hasInStockMedicine;
        }
        return pharmacy.inStockByMedicineId(medicineId).isNotEmpty;
      case PharmacyMedicineAvailabilityFilter.hasMedicinesInStock:
        return pharmacy.hasInStockMedicine;
    }
  }

  bool _matchesPrescription(
    Pharmacy pharmacy,
    PharmacyPrescriptionFilter filter,
  ) {
    switch (filter) {
      case PharmacyPrescriptionFilter.all:
        return true;
      case PharmacyPrescriptionFilter.prescriptionAvailable:
        return pharmacy.hasPrescriptionMedicines;
      case PharmacyPrescriptionFilter.noPrescriptionAvailable:
        return pharmacy.hasNoPrescriptionMedicines;
    }
  }

  void _sort(List<Pharmacy> pharmacies, PharmacySort sort) {
    switch (sort) {
      case PharmacySort.nameAz:
        pharmacies.sort(_compareByName);
        return;
      case PharmacySort.nameZa:
        pharmacies.sort((a, b) => _compareByName(b, a));
        return;
      case PharmacySort.highestRating:
        pharmacies.sort((a, b) {
          final ratingCompare = b.rating.compareTo(a.rating);
          return ratingCompare == 0 ? _compareByName(a, b) : ratingCompare;
        });
        return;
      case PharmacySort.mostMedicinesAvailable:
        pharmacies.sort((a, b) {
          final countCompare =
              b.availableMedicineCount.compareTo(a.availableMedicineCount);
          return countCompare == 0 ? _compareByName(a, b) : countCompare;
        });
        return;
      case PharmacySort.deliveryFirst:
        pharmacies.sort((a, b) {
          if (a.deliveryAvailable == b.deliveryAvailable) {
            return _compareByName(a, b);
          }
          return a.deliveryAvailable ? -1 : 1;
        });
        return;
      case PharmacySort.city:
        pharmacies.sort((a, b) {
          final cityCompare = a.city.compareTo(b.city);
          return cityCompare == 0 ? _compareByName(a, b) : cityCompare;
        });
        return;
      case PharmacySort.area:
        pharmacies.sort((a, b) {
          final areaCompare = a.area.compareTo(b.area);
          return areaCompare == 0 ? _compareByName(a, b) : areaCompare;
        });
        return;
    }
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

  static int _compareByName(Pharmacy a, Pharmacy b) {
    return a.name.toLowerCase().compareTo(b.name.toLowerCase());
  }
}
