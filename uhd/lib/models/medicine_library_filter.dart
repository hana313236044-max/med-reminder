import 'package:uhd/models/medicine_library_model.dart';

enum MedicineLibraryPrescriptionFilter {
  all,
  prescriptionRequired,
  noPrescriptionRequired,
}

enum MedicineLibraryFoodFilter {
  any,
  withFood,
  withoutFood,
  withOrWithoutFood,
  beforeFood,
  afterFood,
}

enum MedicineLibrarySort {
  az,
  za,
  category,
  prescriptionRequiredFirst,
  noPrescriptionFirst,
  mostWarnings,
  fewestWarnings,
}

class MedicineLibraryFilter {
  static const Object _unset = Object();

  final String searchText;
  final String? category;
  final String? form;
  final MedicineLibraryPrescriptionFilter prescriptionFilter;
  final String? ageGroup;
  final MedicineLibraryFoodFilter foodFilter;
  final MedicineLibraryWarningLevel? warningLevel;
  final String? startingLetter;
  final String? tag;
  final MedicineLibrarySort sort;

  const MedicineLibraryFilter({
    this.searchText = '',
    this.category,
    this.form,
    this.prescriptionFilter = MedicineLibraryPrescriptionFilter.all,
    this.ageGroup,
    this.foodFilter = MedicineLibraryFoodFilter.any,
    this.warningLevel,
    this.startingLetter,
    this.tag,
    this.sort = MedicineLibrarySort.az,
  });

  MedicineLibraryFilter copyWith({
    String? searchText,
    Object? category = _unset,
    Object? form = _unset,
    MedicineLibraryPrescriptionFilter? prescriptionFilter,
    Object? ageGroup = _unset,
    MedicineLibraryFoodFilter? foodFilter,
    Object? warningLevel = _unset,
    Object? startingLetter = _unset,
    Object? tag = _unset,
    MedicineLibrarySort? sort,
  }) {
    return MedicineLibraryFilter(
      searchText: searchText ?? this.searchText,
      category: identical(category, _unset) ? this.category : category as String?,
      form: identical(form, _unset) ? this.form : form as String?,
      prescriptionFilter: prescriptionFilter ?? this.prescriptionFilter,
      ageGroup: identical(ageGroup, _unset) ? this.ageGroup : ageGroup as String?,
      foodFilter: foodFilter ?? this.foodFilter,
      warningLevel: identical(warningLevel, _unset)
          ? this.warningLevel
          : warningLevel as MedicineLibraryWarningLevel?,
      startingLetter: identical(startingLetter, _unset)
          ? this.startingLetter
          : startingLetter as String?,
      tag: identical(tag, _unset) ? this.tag : tag as String?,
      sort: sort ?? this.sort,
    );
  }

  bool get hasActiveFilters {
    return searchText.trim().isNotEmpty ||
        category != null ||
        form != null ||
        prescriptionFilter != MedicineLibraryPrescriptionFilter.all ||
        ageGroup != null ||
        foodFilter != MedicineLibraryFoodFilter.any ||
        warningLevel != null ||
        startingLetter != null ||
        tag != null ||
        sort != MedicineLibrarySort.az;
  }
}
