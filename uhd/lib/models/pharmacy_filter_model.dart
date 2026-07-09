enum PharmacyDeliveryFilter { all, deliveryAvailable }

enum PharmacyOpenFilter { all, open24Hours, not24Hours }

enum PharmacyMedicineAvailabilityFilter {
  all,
  hasSelectedMedicine,
  hasMedicinesInStock,
}

enum PharmacyPrescriptionFilter {
  all,
  prescriptionAvailable,
  noPrescriptionAvailable,
}

enum PharmacySort {
  nameAz,
  nameZa,
  highestRating,
  mostMedicinesAvailable,
  deliveryFirst,
  city,
  area,
}

class PharmacyFilter {
  static const Object _unset = Object();

  final String searchText;
  final String medicineSearchText;
  final String? city;
  final String? area;
  final PharmacyDeliveryFilter deliveryFilter;
  final PharmacyOpenFilter openFilter;
  final PharmacyMedicineAvailabilityFilter medicineAvailabilityFilter;
  final PharmacyPrescriptionFilter prescriptionFilter;
  final String? service;
  final String? paymentMethod;
  final PharmacySort sort;
  final String? selectedMedicineId;

  const PharmacyFilter({
    this.searchText = '',
    this.medicineSearchText = '',
    this.city,
    this.area,
    this.deliveryFilter = PharmacyDeliveryFilter.all,
    this.openFilter = PharmacyOpenFilter.all,
    this.medicineAvailabilityFilter = PharmacyMedicineAvailabilityFilter.all,
    this.prescriptionFilter = PharmacyPrescriptionFilter.all,
    this.service,
    this.paymentMethod,
    this.sort = PharmacySort.nameAz,
    this.selectedMedicineId,
  });

  factory PharmacyFilter.fromJson(Map<String, dynamic> json) {
    return PharmacyFilter(
      searchText: _string(json['searchText']),
      medicineSearchText: _string(json['medicineSearchText']),
      city: _nullableString(json['city']),
      area: _nullableString(json['area']),
      deliveryFilter: _enumValue(
        PharmacyDeliveryFilter.values,
        json['deliveryFilter'],
        PharmacyDeliveryFilter.all,
      ),
      openFilter: _enumValue(
        PharmacyOpenFilter.values,
        json['openFilter'],
        PharmacyOpenFilter.all,
      ),
      medicineAvailabilityFilter: _enumValue(
        PharmacyMedicineAvailabilityFilter.values,
        json['medicineAvailabilityFilter'],
        PharmacyMedicineAvailabilityFilter.all,
      ),
      prescriptionFilter: _enumValue(
        PharmacyPrescriptionFilter.values,
        json['prescriptionFilter'],
        PharmacyPrescriptionFilter.all,
      ),
      service: _nullableString(json['service']),
      paymentMethod: _nullableString(json['paymentMethod']),
      sort: _enumValue(PharmacySort.values, json['sort'], PharmacySort.nameAz),
      selectedMedicineId: _nullableString(json['selectedMedicineId']),
    );
  }

  PharmacyFilter copyWith({
    String? searchText,
    String? medicineSearchText,
    Object? city = _unset,
    Object? area = _unset,
    PharmacyDeliveryFilter? deliveryFilter,
    PharmacyOpenFilter? openFilter,
    PharmacyMedicineAvailabilityFilter? medicineAvailabilityFilter,
    PharmacyPrescriptionFilter? prescriptionFilter,
    Object? service = _unset,
    Object? paymentMethod = _unset,
    PharmacySort? sort,
    Object? selectedMedicineId = _unset,
  }) {
    return PharmacyFilter(
      searchText: searchText ?? this.searchText,
      medicineSearchText: medicineSearchText ?? this.medicineSearchText,
      city: identical(city, _unset) ? this.city : city as String?,
      area: identical(area, _unset) ? this.area : area as String?,
      deliveryFilter: deliveryFilter ?? this.deliveryFilter,
      openFilter: openFilter ?? this.openFilter,
      medicineAvailabilityFilter:
          medicineAvailabilityFilter ?? this.medicineAvailabilityFilter,
      prescriptionFilter: prescriptionFilter ?? this.prescriptionFilter,
      service: identical(service, _unset) ? this.service : service as String?,
      paymentMethod: identical(paymentMethod, _unset)
          ? this.paymentMethod
          : paymentMethod as String?,
      sort: sort ?? this.sort,
      selectedMedicineId: identical(selectedMedicineId, _unset)
          ? this.selectedMedicineId
          : selectedMedicineId as String?,
    );
  }

  bool get hasActiveFilters {
    return searchText.trim().isNotEmpty ||
        medicineSearchText.trim().isNotEmpty ||
        city != null ||
        area != null ||
        deliveryFilter != PharmacyDeliveryFilter.all ||
        openFilter != PharmacyOpenFilter.all ||
        medicineAvailabilityFilter != PharmacyMedicineAvailabilityFilter.all ||
        prescriptionFilter != PharmacyPrescriptionFilter.all ||
        service != null ||
        paymentMethod != null ||
        sort != PharmacySort.nameAz;
  }

  Map<String, dynamic> toJson() {
    return {
      'searchText': searchText,
      'medicineSearchText': medicineSearchText,
      'city': city,
      'area': area,
      'deliveryFilter': deliveryFilter.name,
      'openFilter': openFilter.name,
      'medicineAvailabilityFilter': medicineAvailabilityFilter.name,
      'prescriptionFilter': prescriptionFilter.name,
      'service': service,
      'paymentMethod': paymentMethod,
      'sort': sort.name,
      'selectedMedicineId': selectedMedicineId,
    };
  }

  static String _string(dynamic value) {
    return value?.toString().trim() ?? '';
  }

  static String? _nullableString(dynamic value) {
    final parsed = _string(value);
    return parsed.isEmpty ? null : parsed;
  }

  static T _enumValue<T extends Enum>(
    List<T> values,
    dynamic rawValue,
    T fallback,
  ) {
    final name = rawValue?.toString().trim();
    for (final value in values) {
      if (value.name == name) return value;
    }
    return fallback;
  }
}
