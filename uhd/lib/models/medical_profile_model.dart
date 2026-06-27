import 'package:cloud_firestore/cloud_firestore.dart';

class MedicalProfile {
  static const Object _unset = Object();

  final String fullName;
  final DateTime? dateOfBirth;
  final String bloodType;
  final String sex;
  final double? heightCm;
  final double? weightKg;
  final bool noKnownAllergies;
  final bool noKnownConditions;
  final HealthcareProvider? doctor;
  final HealthcareProvider? pharmacy;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? legacyAge;

  const MedicalProfile({
    this.fullName = '',
    this.dateOfBirth,
    this.bloodType = 'Unknown',
    this.sex = 'Prefer not to say',
    this.heightCm,
    this.weightKg,
    this.noKnownAllergies = false,
    this.noKnownConditions = false,
    this.doctor,
    this.pharmacy,
    this.createdAt,
    this.updatedAt,
    this.legacyAge,
  });

  factory MedicalProfile.empty({
    String? fullName,
    String? bloodType,
    String? legacyAge,
  }) {
    return MedicalProfile(
      fullName: fullName?.trim() ?? '',
      bloodType: _normalizeBloodType(bloodType),
      legacyAge: legacyAge,
    );
  }

  factory MedicalProfile.fromMap(
    Map<String, dynamic>? data, {
    String? fallbackName,
    String? fallbackBloodType,
    String? legacyAge,
  }) {
    final map = data ?? {};
    return MedicalProfile(
      fullName: (map['fullName'] as String? ?? fallbackName ?? '').trim(),
      dateOfBirth: _readDate(map['dateOfBirth']),
      bloodType: _normalizeBloodType(
        map['bloodType'] as String? ?? fallbackBloodType,
      ),
      sex: map['sex'] as String? ?? 'Prefer not to say',
      heightCm: _readDouble(map['heightCm']),
      weightKg: _readDouble(map['weightKg']),
      noKnownAllergies: map['noKnownAllergies'] as bool? ?? false,
      noKnownConditions: map['noKnownConditions'] as bool? ?? false,
      doctor: HealthcareProvider.fromMapOrNull(
        _readStringMap(map['doctor']),
        providerType: HealthcareProviderType.doctor,
      ),
      pharmacy: HealthcareProvider.fromMapOrNull(
        _readStringMap(map['pharmacy']),
        providerType: HealthcareProviderType.pharmacy,
      ),
      createdAt: _readDate(map['createdAt']),
      updatedAt: _readDate(map['updatedAt']),
      legacyAge: legacyAge,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fullName': fullName.trim(),
      'dateOfBirth': dateOfBirth == null ? null : Timestamp.fromDate(dateOfBirth!),
      'bloodType': bloodType,
      'sex': sex,
      'heightCm': heightCm,
      'weightKg': weightKg,
      'noKnownAllergies': noKnownAllergies,
      'noKnownConditions': noKnownConditions,
      'doctor': doctor?.toMap(),
      'pharmacy': pharmacy?.toMap(),
    };
  }

  MedicalProfile copyWith({
    String? fullName,
    Object? dateOfBirth = _unset,
    String? bloodType,
    String? sex,
    Object? heightCm = _unset,
    Object? weightKg = _unset,
    bool? noKnownAllergies,
    bool? noKnownConditions,
    Object? doctor = _unset,
    Object? pharmacy = _unset,
    DateTime? createdAt,
    DateTime? updatedAt,
    Object? legacyAge = _unset,
  }) {
    return MedicalProfile(
      fullName: fullName ?? this.fullName,
      dateOfBirth: identical(dateOfBirth, _unset)
          ? this.dateOfBirth
          : dateOfBirth as DateTime?,
      bloodType: bloodType ?? this.bloodType,
      sex: sex ?? this.sex,
      heightCm: identical(heightCm, _unset) ? this.heightCm : heightCm as double?,
      weightKg: identical(weightKg, _unset) ? this.weightKg : weightKg as double?,
      noKnownAllergies: noKnownAllergies ?? this.noKnownAllergies,
      noKnownConditions: noKnownConditions ?? this.noKnownConditions,
      doctor: identical(doctor, _unset) ? this.doctor : doctor as HealthcareProvider?,
      pharmacy: identical(pharmacy, _unset)
          ? this.pharmacy
          : pharmacy as HealthcareProvider?,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      legacyAge: identical(legacyAge, _unset) ? this.legacyAge : legacyAge as String?,
    );
  }

  int? calculatedAge({DateTime? now}) {
    final dob = dateOfBirth;
    if (dob == null) return null;
    final today = now ?? DateTime.now();
    var age = today.year - dob.year;
    final birthdayThisYear = DateTime(today.year, dob.month, dob.day);
    if (birthdayThisYear.isAfter(DateTime(today.year, today.month, today.day))) {
      age--;
    }
    return age;
  }

  int completionPercent({
    required bool hasAllergyStatus,
    required bool hasConditionStatus,
    required bool hasEmergencyContact,
  }) {
    final checks = [
      dateOfBirth != null,
      bloodType != 'Unknown',
      hasEmergencyContact,
      hasAllergyStatus,
      hasConditionStatus,
      doctor != null && doctor!.hasAnyValue,
      pharmacy != null && pharmacy!.hasAnyValue,
    ];
    final complete = checks.where((value) => value).length;
    return (complete / checks.length * 100).round();
  }

  bool get hasAnyValue {
    return fullName.trim().isNotEmpty ||
        dateOfBirth != null ||
        bloodType != 'Unknown' ||
        sex != 'Prefer not to say' ||
        heightCm != null ||
        weightKg != null ||
        noKnownAllergies ||
        noKnownConditions ||
        (doctor != null && doctor!.hasAnyValue) ||
        (pharmacy != null && pharmacy!.hasAnyValue);
  }

  static String _normalizeBloodType(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty || trimmed == 'Not added') {
      return 'Unknown';
    }
    return trimmed;
  }

  static DateTime? _readDate(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  static double? _readDouble(Object? value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static Map<String, dynamic>? _readStringMap(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, item) => MapEntry(key.toString(), item));
    }
    return null;
  }

  @override
  bool operator ==(Object other) {
    return other is MedicalProfile &&
        other.fullName == fullName &&
        other.dateOfBirth == dateOfBirth &&
        other.bloodType == bloodType &&
        other.sex == sex &&
        other.heightCm == heightCm &&
        other.weightKg == weightKg &&
        other.noKnownAllergies == noKnownAllergies &&
        other.noKnownConditions == noKnownConditions &&
        other.doctor == doctor &&
        other.pharmacy == pharmacy;
  }

  @override
  int get hashCode => Object.hash(
        fullName,
        dateOfBirth,
        bloodType,
        sex,
        heightCm,
        weightKg,
        noKnownAllergies,
        noKnownConditions,
        doctor,
        pharmacy,
      );
}

class AllergyRecord {
  final String id;
  final String name;
  final String severity;
  final String notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const AllergyRecord({
    required this.id,
    required this.name,
    this.severity = 'Unknown',
    this.notes = '',
    this.createdAt,
    this.updatedAt,
  });

  factory AllergyRecord.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return AllergyRecord(
      id: doc.id,
      name: data['name'] as String? ?? '',
      severity: data['severity'] as String? ?? 'Unknown',
      notes: data['notes'] as String? ?? '',
      createdAt: MedicalProfile._readDate(data['createdAt']),
      updatedAt: MedicalProfile._readDate(data['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name.trim(),
      'severity': severity,
      'notes': notes.trim(),
    };
  }

  AllergyRecord copyWith({
    String? id,
    String? name,
    String? severity,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AllergyRecord(
      id: id ?? this.id,
      name: name ?? this.name,
      severity: severity ?? this.severity,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is AllergyRecord &&
        other.id == id &&
        other.name == name &&
        other.severity == severity &&
        other.notes == notes;
  }

  @override
  int get hashCode => Object.hash(id, name, severity, notes);
}

class MedicalConditionRecord {
  final String id;
  final String name;
  final DateTime? diagnosisDate;
  final String status;
  final String notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const MedicalConditionRecord({
    required this.id,
    required this.name,
    this.diagnosisDate,
    this.status = 'Unknown',
    this.notes = '',
    this.createdAt,
    this.updatedAt,
  });

  factory MedicalConditionRecord.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    return MedicalConditionRecord(
      id: doc.id,
      name: data['name'] as String? ?? '',
      diagnosisDate: MedicalProfile._readDate(data['diagnosisDate']),
      status: data['status'] as String? ?? 'Unknown',
      notes: data['notes'] as String? ?? '',
      createdAt: MedicalProfile._readDate(data['createdAt']),
      updatedAt: MedicalProfile._readDate(data['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name.trim(),
      'diagnosisDate': diagnosisDate == null ? null : Timestamp.fromDate(diagnosisDate!),
      'status': status,
      'notes': notes.trim(),
    };
  }

  MedicalConditionRecord copyWith({
    String? id,
    String? name,
    Object? diagnosisDate = MedicalProfile._unset,
    String? status,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MedicalConditionRecord(
      id: id ?? this.id,
      name: name ?? this.name,
      diagnosisDate: identical(diagnosisDate, MedicalProfile._unset)
          ? this.diagnosisDate
          : diagnosisDate as DateTime?,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is MedicalConditionRecord &&
        other.id == id &&
        other.name == name &&
        other.diagnosisDate == diagnosisDate &&
        other.status == status &&
        other.notes == notes;
  }

  @override
  int get hashCode => Object.hash(id, name, diagnosisDate, status, notes);
}

class EmergencyContactRecord {
  final String id;
  final String fullName;
  final String relationship;
  final String phoneNumber;
  final String secondaryPhoneNumber;
  final bool isPrimary;
  final String notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const EmergencyContactRecord({
    required this.id,
    required this.fullName,
    this.relationship = '',
    this.phoneNumber = '',
    this.secondaryPhoneNumber = '',
    this.isPrimary = false,
    this.notes = '',
    this.createdAt,
    this.updatedAt,
  });

  factory EmergencyContactRecord.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    return EmergencyContactRecord(
      id: doc.id,
      fullName: data['fullName'] as String? ?? '',
      relationship: data['relationship'] as String? ?? '',
      phoneNumber: data['phoneNumber'] as String? ?? '',
      secondaryPhoneNumber: data['secondaryPhoneNumber'] as String? ?? '',
      isPrimary: data['isPrimary'] as bool? ?? false,
      notes: data['notes'] as String? ?? '',
      createdAt: MedicalProfile._readDate(data['createdAt']),
      updatedAt: MedicalProfile._readDate(data['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fullName': fullName.trim(),
      'relationship': relationship.trim(),
      'phoneNumber': phoneNumber.trim(),
      'secondaryPhoneNumber': secondaryPhoneNumber.trim(),
      'isPrimary': isPrimary,
      'notes': notes.trim(),
    };
  }

  EmergencyContactRecord copyWith({
    String? id,
    String? fullName,
    String? relationship,
    String? phoneNumber,
    String? secondaryPhoneNumber,
    bool? isPrimary,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return EmergencyContactRecord(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      relationship: relationship ?? this.relationship,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      secondaryPhoneNumber: secondaryPhoneNumber ?? this.secondaryPhoneNumber,
      isPrimary: isPrimary ?? this.isPrimary,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is EmergencyContactRecord &&
        other.id == id &&
        other.fullName == fullName &&
        other.relationship == relationship &&
        other.phoneNumber == phoneNumber &&
        other.secondaryPhoneNumber == secondaryPhoneNumber &&
        other.isPrimary == isPrimary &&
        other.notes == notes;
  }

  @override
  int get hashCode => Object.hash(
        id,
        fullName,
        relationship,
        phoneNumber,
        secondaryPhoneNumber,
        isPrimary,
        notes,
      );
}

enum HealthcareProviderType { doctor, pharmacy }

class HealthcareProvider {
  final HealthcareProviderType providerType;
  final String name;
  final String specialty;
  final String phoneNumber;
  final String email;
  final String facilityName;
  final String address;
  final String notes;

  const HealthcareProvider({
    required this.providerType,
    this.name = '',
    this.specialty = '',
    this.phoneNumber = '',
    this.email = '',
    this.facilityName = '',
    this.address = '',
    this.notes = '',
  });

  static HealthcareProvider? fromMapOrNull(
    Map<String, dynamic>? data, {
    required HealthcareProviderType providerType,
  }) {
    if (data == null) return null;
    final provider = HealthcareProvider(
      providerType: providerType,
      name: data['name'] as String? ?? '',
      specialty: data['specialty'] as String? ?? '',
      phoneNumber: data['phoneNumber'] as String? ?? '',
      email: data['email'] as String? ?? '',
      facilityName: data['facilityName'] as String? ?? '',
      address: data['address'] as String? ?? '',
      notes: data['notes'] as String? ?? '',
    );
    return provider.hasAnyValue ? provider : null;
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name.trim(),
      'specialty': specialty.trim(),
      'phoneNumber': phoneNumber.trim(),
      'email': email.trim(),
      'facilityName': facilityName.trim(),
      'address': address.trim(),
      'notes': notes.trim(),
    };
  }

  HealthcareProvider copyWith({
    HealthcareProviderType? providerType,
    String? name,
    String? specialty,
    String? phoneNumber,
    String? email,
    String? facilityName,
    String? address,
    String? notes,
  }) {
    return HealthcareProvider(
      providerType: providerType ?? this.providerType,
      name: name ?? this.name,
      specialty: specialty ?? this.specialty,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      facilityName: facilityName ?? this.facilityName,
      address: address ?? this.address,
      notes: notes ?? this.notes,
    );
  }

  bool get hasAnyValue {
    return name.trim().isNotEmpty ||
        specialty.trim().isNotEmpty ||
        phoneNumber.trim().isNotEmpty ||
        email.trim().isNotEmpty ||
        facilityName.trim().isNotEmpty ||
        address.trim().isNotEmpty ||
        notes.trim().isNotEmpty;
  }

  @override
  bool operator ==(Object other) {
    return other is HealthcareProvider &&
        other.providerType == providerType &&
        other.name == name &&
        other.specialty == specialty &&
        other.phoneNumber == phoneNumber &&
        other.email == email &&
        other.facilityName == facilityName &&
        other.address == address &&
        other.notes == notes;
  }

  @override
  int get hashCode => Object.hash(
        providerType,
        name,
        specialty,
        phoneNumber,
        email,
        facilityName,
        address,
        notes,
      );
}

class MedicalProfileBundle {
  final MedicalProfile profile;
  final List<AllergyRecord> allergies;
  final List<MedicalConditionRecord> conditions;
  final List<EmergencyContactRecord> emergencyContacts;
  final bool exists;
  final String language;

  const MedicalProfileBundle({
    required this.profile,
    required this.allergies,
    required this.conditions,
    required this.emergencyContacts,
    required this.exists,
    required this.language,
  });

  MedicalProfileBundle copyWith({
    MedicalProfile? profile,
    List<AllergyRecord>? allergies,
    List<MedicalConditionRecord>? conditions,
    List<EmergencyContactRecord>? emergencyContacts,
    bool? exists,
    String? language,
  }) {
    return MedicalProfileBundle(
      profile: profile ?? this.profile,
      allergies: allergies ?? this.allergies,
      conditions: conditions ?? this.conditions,
      emergencyContacts: emergencyContacts ?? this.emergencyContacts,
      exists: exists ?? this.exists,
      language: language ?? this.language,
    );
  }
}
