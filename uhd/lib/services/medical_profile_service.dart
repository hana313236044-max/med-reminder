import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uhd/models/medical_profile_model.dart';

class MedicalProfileServiceException implements Exception {
  final String message;

  const MedicalProfileServiceException(this.message);
}

class MedicalProfileService {
  final FirebaseFirestore firestore;
  final FirebaseAuth auth;

  MedicalProfileService({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : firestore = firestore ?? FirebaseFirestore.instance,
        auth = auth ?? FirebaseAuth.instance;

  Future<MedicalProfileBundle> loadBundle() async {
    final user = auth.currentUser;
    if (user == null) {
      throw const MedicalProfileServiceException(
        'Please sign in to view your Medical Profile.',
      );
    }

    final userRef = firestore.collection('users').doc(user.uid);
    final profileRef = _profileRef(user.uid);

    final userSnapshot = await userRef.get();
    final settingsSnapshot = await userRef.collection('settings').doc('app').get();
    final profileSnapshot = await profileRef.get();
    final allergySnapshot = await _allergiesRef(user.uid).orderBy('name').get();
    final conditionSnapshot = await _conditionsRef(user.uid).orderBy('name').get();
    final contactSnapshot = await _contactsRef(user.uid).get();

    final userData = userSnapshot.data() ?? {};
    final language = settingsSnapshot.data()?['language'] as String? ?? 'English';
    final profile = MedicalProfile.fromMap(
      profileSnapshot.data(),
      fallbackName: userData['username'] as String? ?? user.displayName,
      fallbackBloodType: userData['bloodType'] as String?,
      legacyAge: userData['age']?.toString(),
    );

    return MedicalProfileBundle(
      profile: profile,
      allergies: allergySnapshot.docs.map(AllergyRecord.fromFirestore).toList(),
      conditions: conditionSnapshot.docs
          .map(MedicalConditionRecord.fromFirestore)
          .toList(),
      emergencyContacts: _sortedContacts(
        _normalizePrimaryContacts(
          contactSnapshot.docs.map(EmergencyContactRecord.fromFirestore).toList(),
        ),
      ),
      exists: profileSnapshot.exists,
      language: language,
    );
  }

  Future<void> saveBundle(MedicalProfileBundle bundle) async {
    final user = auth.currentUser;
    if (user == null) {
      throw const MedicalProfileServiceException(
        'Please sign in to save your Medical Profile.',
      );
    }

    final profileRef = _profileRef(user.uid);
    final batch = firestore.batch();
    final profileData = bundle.profile.toMap();
    profileData['updatedAt'] = FieldValue.serverTimestamp();
    if (!bundle.exists || bundle.profile.createdAt == null) {
      profileData['createdAt'] = FieldValue.serverTimestamp();
    }
    batch.set(profileRef, profileData, SetOptions(merge: true));

    await _syncAllergies(user.uid, bundle.allergies, batch);
    await _syncConditions(user.uid, bundle.conditions, batch);
    await _syncContacts(
      user.uid,
      _normalizePrimaryContacts(bundle.emergencyContacts),
      batch,
    );

    await batch.commit();
  }

  Future<void> deleteMedicalProfile() async {
    final user = auth.currentUser;
    if (user == null) {
      throw const MedicalProfileServiceException(
        'Please sign in to delete your Medical Profile.',
      );
    }

    final batch = firestore.batch();
    for (final doc in (await _allergiesRef(user.uid).get()).docs) {
      batch.delete(doc.reference);
    }
    for (final doc in (await _conditionsRef(user.uid).get()).docs) {
      batch.delete(doc.reference);
    }
    for (final doc in (await _contactsRef(user.uid).get()).docs) {
      batch.delete(doc.reference);
    }
    batch.delete(_profileRef(user.uid));
    await batch.commit();
  }

  static List<EmergencyContactRecord> enforcePrimaryContact(
    List<EmergencyContactRecord> contacts,
    String primaryId,
  ) {
    return contacts
        .map((contact) => contact.copyWith(isPrimary: contact.id == primaryId))
        .toList();
  }

  static String newLocalId() {
    return DateTime.now().microsecondsSinceEpoch.toString();
  }

  DocumentReference<Map<String, dynamic>> _profileRef(String uid) {
    return firestore
        .collection('users')
        .doc(uid)
        .collection('medicalProfile')
        .doc('profile');
  }

  CollectionReference<Map<String, dynamic>> _allergiesRef(String uid) {
    return _profileRef(uid).collection('allergies');
  }

  CollectionReference<Map<String, dynamic>> _conditionsRef(String uid) {
    return _profileRef(uid).collection('conditions');
  }

  CollectionReference<Map<String, dynamic>> _contactsRef(String uid) {
    return _profileRef(uid).collection('emergencyContacts');
  }

  Future<void> _syncAllergies(
    String uid,
    List<AllergyRecord> records,
    WriteBatch batch,
  ) async {
    final ref = _allergiesRef(uid);
    final existing = await ref.get();
    final currentIds = records.map((record) => record.id).toSet();

    for (final doc in existing.docs) {
      if (!currentIds.contains(doc.id)) {
        batch.delete(doc.reference);
      }
    }

    for (final record in records) {
      final data = record.toMap();
      data['updatedAt'] = FieldValue.serverTimestamp();
      if (record.createdAt == null) {
        data['createdAt'] = FieldValue.serverTimestamp();
      }
      batch.set(ref.doc(record.id), data, SetOptions(merge: true));
    }
  }

  Future<void> _syncConditions(
    String uid,
    List<MedicalConditionRecord> records,
    WriteBatch batch,
  ) async {
    final ref = _conditionsRef(uid);
    final existing = await ref.get();
    final currentIds = records.map((record) => record.id).toSet();

    for (final doc in existing.docs) {
      if (!currentIds.contains(doc.id)) {
        batch.delete(doc.reference);
      }
    }

    for (final record in records) {
      final data = record.toMap();
      data['updatedAt'] = FieldValue.serverTimestamp();
      if (record.createdAt == null) {
        data['createdAt'] = FieldValue.serverTimestamp();
      }
      batch.set(ref.doc(record.id), data, SetOptions(merge: true));
    }
  }

  Future<void> _syncContacts(
    String uid,
    List<EmergencyContactRecord> records,
    WriteBatch batch,
  ) async {
    final ref = _contactsRef(uid);
    final existing = await ref.get();
    final currentIds = records.map((record) => record.id).toSet();

    for (final doc in existing.docs) {
      if (!currentIds.contains(doc.id)) {
        batch.delete(doc.reference);
      }
    }

    for (final record in records) {
      final data = record.toMap();
      data['updatedAt'] = FieldValue.serverTimestamp();
      if (record.createdAt == null) {
        data['createdAt'] = FieldValue.serverTimestamp();
      }
      batch.set(ref.doc(record.id), data, SetOptions(merge: true));
    }
  }

  List<EmergencyContactRecord> _normalizePrimaryContacts(
    List<EmergencyContactRecord> contacts,
  ) {
    var foundPrimary = false;
    return contacts.map((contact) {
      if (!contact.isPrimary) return contact;
      if (!foundPrimary) {
        foundPrimary = true;
        return contact;
      }
      return contact.copyWith(isPrimary: false);
    }).toList();
  }

  List<EmergencyContactRecord> _sortedContacts(
    List<EmergencyContactRecord> contacts,
  ) {
    contacts.sort((a, b) {
      if (a.isPrimary != b.isPrimary) return a.isPrimary ? -1 : 1;
      return a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase());
    });
    return contacts;
  }
}

class MedicalProfileValidation {
  static final RegExp phonePattern = RegExp(r'^[+0-9 ()-]{6,30}$');
  static final RegExp emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static String? optionalName(String value) {
    final trimmed = value.trim();
    if (trimmed.length > 100) return 'Maximum 100 characters.';
    return null;
  }

  static String? requiredName(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return 'This field is required.';
    if (trimmed.length > 100) return 'Maximum 100 characters.';
    return null;
  }

  static String? dateOfBirth(DateTime? value) {
    if (value == null) return null;
    final today = DateTime.now();
    if (value.isAfter(today)) return 'Date cannot be in the future.';
    final age = MedicalProfile(dateOfBirth: value).calculatedAge(now: today);
    if (age == null || age < 0 || age > 130) {
      return 'Choose a realistic date of birth.';
    }
    return null;
  }

  static String? pastDate(DateTime? value) {
    if (value == null) return null;
    if (value.isAfter(DateTime.now())) return 'Date cannot be in the future.';
    return null;
  }

  static String? optionalHeight(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    final number = double.tryParse(trimmed);
    if (number == null || number <= 0) return 'Enter a positive number.';
    if (number < 30 || number > 260) return 'Enter a realistic height.';
    return null;
  }

  static String? optionalWeight(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    final number = double.tryParse(trimmed);
    if (number == null || number <= 0) return 'Enter a positive number.';
    if (number < 1 || number > 500) return 'Enter a realistic weight.';
    return null;
  }

  static String? optionalPhone(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    if (!phonePattern.hasMatch(trimmed)) return 'Enter a valid phone number.';
    return null;
  }

  static String? requiredPhoneEither(String primary, String secondary) {
    if (primary.trim().isEmpty && secondary.trim().isEmpty) {
      return 'At least one phone number is required.';
    }
    return optionalPhone(primary) ?? optionalPhone(secondary);
  }

  static String? optionalEmail(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    if (!emailPattern.hasMatch(trimmed)) return 'Enter a valid email address.';
    return null;
  }

  static String? notes(String value, {int max = 500}) {
    if (value.trim().length > max) return 'Maximum $max characters.';
    return null;
  }

  static bool hasDuplicateName<T>({
    required List<T> records,
    required String id,
    required String name,
    required String Function(T record) idOf,
    required String Function(T record) nameOf,
  }) {
    final normalized = _normalize(name);
    return records.any(
      (record) => idOf(record) != id && _normalize(nameOf(record)) == normalized,
    );
  }

  static String _normalize(String value) {
    return value.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();
  }
}
