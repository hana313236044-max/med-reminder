import 'package:flutter/widgets.dart';
import 'package:uhd/models/medicine_library_filter.dart';
import 'package:uhd/models/medicine_library_model.dart';

enum MedicineLibraryTextKey {
  title,
  subtitle,
  disclaimerShort,
  disclaimerFull,
  searchHint,
  filters,
  category,
  allCategories,
  form,
  allForms,
  prescription,
  allPrescriptions,
  prescriptionRequired,
  noPrescriptionRequired,
  ageGroup,
  allAgeGroups,
  foodInstruction,
  anyFoodInstruction,
  withFood,
  withoutFood,
  withOrWithoutFood,
  beforeFood,
  afterFood,
  warningLevel,
  allWarningLevels,
  generalCaution,
  importantWarnings,
  highCaution,
  alphabet,
  all,
  tag,
  allTags,
  sortBy,
  sortAz,
  sortZa,
  sortCategory,
  sortPrescriptionRequiredFirst,
  sortNoPrescriptionFirst,
  sortMostWarnings,
  sortFewestWarnings,
  resetFilters,
  loading,
  errorTitle,
  retry,
  emptyLibrary,
  emptyFiltersTitle,
  emptyFiltersMessage,
  generic,
  forms,
  tags,
  brandExamples,
  prescriptionBadge,
  noPrescriptionBadge,
  warningCount,
  medicineNotFound,
  backToLibrary,
  addToMyMedicines,
  overview,
  formsAndUsage,
  sideEffects,
  safetyInformation,
  libraryActions,
  description,
  commonUses,
  howTaken,
  foodInstructions,
  availableForms,
  generalUsageNotes,
  missedDose,
  commonSideEffects,
  seriousWarnings,
  whoCareful,
  interactions,
  pregnancyBreastfeeding,
  storage,
  notProvided,
  addUnavailable,
}

class MedicineLibraryStrings {
  final String language;

  const MedicineLibraryStrings._(this.language);

  static MedicineLibraryStrings of(BuildContext context) {
    final localeCode = Localizations.maybeLocaleOf(context)?.languageCode;
    if (localeCode == 'ar') return const MedicineLibraryStrings._('Arabic');
    if (localeCode == 'ku') return const MedicineLibraryStrings._('Kurdish');
    return const MedicineLibraryStrings._('English');
  }

  static const Map<MedicineLibraryTextKey, String> _english = {
    MedicineLibraryTextKey.title: 'Medicine Library',
    MedicineLibraryTextKey.subtitle:
        'Search and explore general medicine information.',
    MedicineLibraryTextKey.disclaimerShort:
        'Educational information only. Not medical advice.',
    MedicineLibraryTextKey.disclaimerFull:
        'This medicine library is for educational information only and is not medical advice. Always follow a doctor or pharmacist\'s instructions.',
    MedicineLibraryTextKey.searchHint: 'Search by medicine name',
    MedicineLibraryTextKey.filters: 'Filters',
    MedicineLibraryTextKey.category: 'Category',
    MedicineLibraryTextKey.allCategories: 'All categories',
    MedicineLibraryTextKey.form: 'Form',
    MedicineLibraryTextKey.allForms: 'All forms',
    MedicineLibraryTextKey.prescription: 'Prescription',
    MedicineLibraryTextKey.allPrescriptions: 'All',
    MedicineLibraryTextKey.prescriptionRequired: 'Prescription required',
    MedicineLibraryTextKey.noPrescriptionRequired: 'No prescription required',
    MedicineLibraryTextKey.ageGroup: 'Age group',
    MedicineLibraryTextKey.allAgeGroups: 'All age groups',
    MedicineLibraryTextKey.foodInstruction: 'Food instruction',
    MedicineLibraryTextKey.anyFoodInstruction: 'Any food instruction',
    MedicineLibraryTextKey.withFood: 'With food',
    MedicineLibraryTextKey.withoutFood: 'Without food',
    MedicineLibraryTextKey.withOrWithoutFood: 'With or without food',
    MedicineLibraryTextKey.beforeFood: 'Before food',
    MedicineLibraryTextKey.afterFood: 'After food',
    MedicineLibraryTextKey.warningLevel: 'Warning level',
    MedicineLibraryTextKey.allWarningLevels: 'All warning levels',
    MedicineLibraryTextKey.generalCaution: 'General caution',
    MedicineLibraryTextKey.importantWarnings: 'Important warnings',
    MedicineLibraryTextKey.highCaution: 'High caution',
    MedicineLibraryTextKey.alphabet: 'Alphabet',
    MedicineLibraryTextKey.all: 'All',
    MedicineLibraryTextKey.tag: 'Tag',
    MedicineLibraryTextKey.allTags: 'All tags',
    MedicineLibraryTextKey.sortBy: 'Sort by',
    MedicineLibraryTextKey.sortAz: 'A to Z',
    MedicineLibraryTextKey.sortZa: 'Z to A',
    MedicineLibraryTextKey.sortCategory: 'Category',
    MedicineLibraryTextKey.sortPrescriptionRequiredFirst:
        'Prescription required first',
    MedicineLibraryTextKey.sortNoPrescriptionFirst: 'No prescription first',
    MedicineLibraryTextKey.sortMostWarnings: 'Most warnings',
    MedicineLibraryTextKey.sortFewestWarnings: 'Fewest warnings',
    MedicineLibraryTextKey.resetFilters: 'Reset Filters',
    MedicineLibraryTextKey.loading: 'Loading medicine library...',
    MedicineLibraryTextKey.errorTitle: 'Could not load the medicine library.',
    MedicineLibraryTextKey.retry: 'Retry',
    MedicineLibraryTextKey.emptyLibrary: 'No medicines are available yet.',
    MedicineLibraryTextKey.emptyFiltersTitle:
        'No medicines match your search and filters.',
    MedicineLibraryTextKey.emptyFiltersMessage:
        'Try changing the search text or resetting filters.',
    MedicineLibraryTextKey.generic: 'Generic',
    MedicineLibraryTextKey.forms: 'Forms',
    MedicineLibraryTextKey.tags: 'Tags',
    MedicineLibraryTextKey.brandExamples: 'Brand examples',
    MedicineLibraryTextKey.prescriptionBadge: 'Prescription required',
    MedicineLibraryTextKey.noPrescriptionBadge: 'No prescription required',
    MedicineLibraryTextKey.warningCount: 'warnings',
    MedicineLibraryTextKey.medicineNotFound: 'Medicine not found.',
    MedicineLibraryTextKey.backToLibrary: 'Back to Medicine Library',
    MedicineLibraryTextKey.addToMyMedicines: 'Add to My Medicines',
    MedicineLibraryTextKey.overview: 'Overview',
    MedicineLibraryTextKey.formsAndUsage: 'Forms and usage',
    MedicineLibraryTextKey.sideEffects: 'Side effects',
    MedicineLibraryTextKey.safetyInformation: 'Safety information',
    MedicineLibraryTextKey.libraryActions: 'Library actions',
    MedicineLibraryTextKey.description: 'Description',
    MedicineLibraryTextKey.commonUses: 'Common uses',
    MedicineLibraryTextKey.howTaken: 'How it is usually taken',
    MedicineLibraryTextKey.foodInstructions: 'Food instructions',
    MedicineLibraryTextKey.availableForms: 'Available forms',
    MedicineLibraryTextKey.generalUsageNotes: 'General usage notes',
    MedicineLibraryTextKey.missedDose: 'Missed dose information',
    MedicineLibraryTextKey.commonSideEffects: 'Common side effects',
    MedicineLibraryTextKey.seriousWarnings: 'Serious warnings',
    MedicineLibraryTextKey.whoCareful: 'Who should be careful',
    MedicineLibraryTextKey.interactions: 'Possible interactions',
    MedicineLibraryTextKey.pregnancyBreastfeeding:
        'Pregnancy / breastfeeding note',
    MedicineLibraryTextKey.storage: 'Storage instructions',
    MedicineLibraryTextKey.notProvided: 'Not provided',
    MedicineLibraryTextKey.addUnavailable:
        'Open this library from your signed-in home screen to add it to My Medicines.',
  };

  static const Map<String, Map<MedicineLibraryTextKey, String>> _values = {
    'English': _english,
    'Kurdish': _english,
    'Arabic': _english,
  };

  String t(MedicineLibraryTextKey key) {
    return _values[language]?[key] ?? _english[key] ?? key.name;
  }

  String showingCount(int shown, int total) =>
      'Showing $shown of $total medicines';

  String warningCount(int count) =>
      count == 1 ? '1 warning' : '$count ${t(MedicineLibraryTextKey.warningCount)}';

  String prescriptionFilterLabel(
    MedicineLibraryPrescriptionFilter filter,
  ) {
    switch (filter) {
      case MedicineLibraryPrescriptionFilter.all:
        return t(MedicineLibraryTextKey.allPrescriptions);
      case MedicineLibraryPrescriptionFilter.prescriptionRequired:
        return t(MedicineLibraryTextKey.prescriptionRequired);
      case MedicineLibraryPrescriptionFilter.noPrescriptionRequired:
        return t(MedicineLibraryTextKey.noPrescriptionRequired);
    }
  }

  String foodFilterLabel(MedicineLibraryFoodFilter filter) {
    switch (filter) {
      case MedicineLibraryFoodFilter.any:
        return t(MedicineLibraryTextKey.anyFoodInstruction);
      case MedicineLibraryFoodFilter.withFood:
        return t(MedicineLibraryTextKey.withFood);
      case MedicineLibraryFoodFilter.withoutFood:
        return t(MedicineLibraryTextKey.withoutFood);
      case MedicineLibraryFoodFilter.withOrWithoutFood:
        return t(MedicineLibraryTextKey.withOrWithoutFood);
      case MedicineLibraryFoodFilter.beforeFood:
        return t(MedicineLibraryTextKey.beforeFood);
      case MedicineLibraryFoodFilter.afterFood:
        return t(MedicineLibraryTextKey.afterFood);
    }
  }

  String warningLevelLabel(MedicineLibraryWarningLevel level) {
    switch (level) {
      case MedicineLibraryWarningLevel.generalCaution:
        return t(MedicineLibraryTextKey.generalCaution);
      case MedicineLibraryWarningLevel.importantWarnings:
        return t(MedicineLibraryTextKey.importantWarnings);
      case MedicineLibraryWarningLevel.highCaution:
        return t(MedicineLibraryTextKey.highCaution);
    }
  }

  String sortLabel(MedicineLibrarySort sort) {
    switch (sort) {
      case MedicineLibrarySort.az:
        return t(MedicineLibraryTextKey.sortAz);
      case MedicineLibrarySort.za:
        return t(MedicineLibraryTextKey.sortZa);
      case MedicineLibrarySort.category:
        return t(MedicineLibraryTextKey.sortCategory);
      case MedicineLibrarySort.prescriptionRequiredFirst:
        return t(MedicineLibraryTextKey.sortPrescriptionRequiredFirst);
      case MedicineLibrarySort.noPrescriptionFirst:
        return t(MedicineLibraryTextKey.sortNoPrescriptionFirst);
      case MedicineLibrarySort.mostWarnings:
        return t(MedicineLibraryTextKey.sortMostWarnings);
      case MedicineLibrarySort.fewestWarnings:
        return t(MedicineLibraryTextKey.sortFewestWarnings);
    }
  }
}
