enum MedicineLibraryWarningLevel {
  generalCaution,
  importantWarnings,
  highCaution,
}

class MedicineLibraryMedicine {
  final String id;
  final String name;
  final String genericName;
  final List<String> brandExamples;
  final String category;
  final String medicineClass;
  final List<String> forms;
  final List<String> commonUses;
  final String description;
  final String howItIsUsuallyTaken;
  final String foodInstructions;
  final List<String> commonSideEffects;
  final List<String> seriousWarnings;
  final List<String> whoShouldBeCareful;
  final List<String> possibleInteractions;
  final String storage;
  final String missedDoseInfo;
  final String pregnancyBreastfeedingNote;
  final List<String> ageGroup;
  final bool prescriptionRequired;
  final List<String> tags;

  MedicineLibraryMedicine({
    required this.id,
    required this.name,
    required this.genericName,
    required this.brandExamples,
    required this.category,
    required this.medicineClass,
    required this.forms,
    required this.commonUses,
    required this.description,
    required this.howItIsUsuallyTaken,
    required this.foodInstructions,
    required this.commonSideEffects,
    required this.seriousWarnings,
    required this.whoShouldBeCareful,
    required this.possibleInteractions,
    required this.storage,
    required this.missedDoseInfo,
    required this.pregnancyBreastfeedingNote,
    required this.ageGroup,
    required this.prescriptionRequired,
    required this.tags,
  });

  factory MedicineLibraryMedicine.fromJson(Map<String, dynamic> json) {
    final parsedName = _string(
      json['name'],
      fallback: _string(json['genericName'], fallback: 'Unnamed medicine'),
    );
    return MedicineLibraryMedicine(
      id: _string(json['id'], fallback: _slugFor(parsedName)),
      name: parsedName,
      genericName: _string(json['genericName']),
      brandExamples: _stringList(json['brandExamples']),
      category: _string(json['category']),
      medicineClass: _string(json['medicineClass']),
      forms: _stringList(json['forms']),
      commonUses: _stringList(json['commonUses']),
      description: _string(json['description']),
      howItIsUsuallyTaken: _string(json['howItIsUsuallyTaken']),
      foodInstructions: _string(json['foodInstructions']),
      commonSideEffects: _stringList(json['commonSideEffects']),
      seriousWarnings: _stringList(json['seriousWarnings']),
      whoShouldBeCareful: _stringList(json['whoShouldBeCareful']),
      possibleInteractions: _stringList(json['possibleInteractions']),
      storage: _string(json['storage']),
      missedDoseInfo: _string(json['missedDoseInfo']),
      pregnancyBreastfeedingNote: _string(json['pregnancyBreastfeedingNote']),
      ageGroup: _stringList(json['ageGroup']),
      prescriptionRequired: _bool(json['prescriptionRequired']),
      tags: _stringList(json['tags']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'genericName': genericName,
      'brandExamples': brandExamples,
      'category': category,
      'medicineClass': medicineClass,
      'forms': forms,
      'commonUses': commonUses,
      'description': description,
      'howItIsUsuallyTaken': howItIsUsuallyTaken,
      'foodInstructions': foodInstructions,
      'commonSideEffects': commonSideEffects,
      'seriousWarnings': seriousWarnings,
      'whoShouldBeCareful': whoShouldBeCareful,
      'possibleInteractions': possibleInteractions,
      'storage': storage,
      'missedDoseInfo': missedDoseInfo,
      'pregnancyBreastfeedingNote': pregnancyBreastfeedingNote,
      'ageGroup': ageGroup,
      'prescriptionRequired': prescriptionRequired,
      'tags': tags,
    };
  }

  int get warningCount => seriousWarnings
      .where((warning) => warning.trim().isNotEmpty && warning != 'Not provided')
      .length;

  MedicineLibraryWarningLevel get warningLevel {
    if (warningCount >= 4) return MedicineLibraryWarningLevel.highCaution;
    if (warningCount >= 2) return MedicineLibraryWarningLevel.importantWarnings;
    return MedicineLibraryWarningLevel.generalCaution;
  }

  String get primaryForm => forms.isEmpty ? 'Not provided' : forms.first;

  String get brandSummary =>
      brandExamples.isEmpty ? 'Not provided' : brandExamples.join(', ');

  String get formsSummary =>
      forms.isEmpty ? 'Not provided' : forms.take(4).join(', ');

  String get tagsSummary => tags.isEmpty ? 'Not provided' : tags.join(', ');

  String get searchableText {
    return [
      id,
      name,
      genericName,
      category,
      medicineClass,
      description,
      howItIsUsuallyTaken,
      foodInstructions,
      ...brandExamples,
      ...forms,
      ...commonUses,
      ...commonSideEffects,
      ...seriousWarnings,
      ...whoShouldBeCareful,
      ...possibleInteractions,
      ...ageGroup,
      ...tags,
    ].join(' ').toLowerCase();
  }

  static String _string(dynamic value, {String fallback = 'Not provided'}) {
    if (value == null) return fallback;
    final parsed = value.toString().trim();
    return parsed.isEmpty ? fallback : parsed;
  }

  static List<String> _stringList(dynamic value) {
    if (value is List) {
      return value
          .map((item) => item?.toString().trim() ?? '')
          .where((item) => item.isNotEmpty)
          .toList();
    }
    if (value is String && value.trim().isNotEmpty) {
      return [value.trim()];
    }
    return const [];
  }

  static bool _bool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      return normalized == 'true' ||
          normalized == 'yes' ||
          normalized == 'required' ||
          normalized == 'prescription';
    }
    return false;
  }

  static String _slugFor(String value) {
    final slug = value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    return slug.isEmpty ? 'medicine' : slug;
  }
}
