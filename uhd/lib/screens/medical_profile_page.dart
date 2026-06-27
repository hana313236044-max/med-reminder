import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uhd/models/medical_profile_model.dart';
import 'package:uhd/services/medical_profile_service.dart';
import 'package:uhd/widgets/app_widgets.dart';

class MedicalProfilePage extends StatefulWidget {
  const MedicalProfilePage({super.key});

  @override
  State<MedicalProfilePage> createState() => _MedicalProfilePageState();
}

class _MedicalProfilePageState extends State<MedicalProfilePage> {
  final MedicalProfileService _service = MedicalProfileService();
  late Future<MedicalProfileBundle> _future;
  MedicalProfileBundle? _saved;
  MedicalProfileBundle? _draft;
  bool _isEditing = false;
  bool _isSaving = false;
  bool _isDeleting = false;
  final Map<String, String?> _errors = {};

  final _fullNameController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _doctorNameController = TextEditingController();
  final _doctorSpecialtyController = TextEditingController();
  final _doctorPhoneController = TextEditingController();
  final _doctorEmailController = TextEditingController();
  final _doctorFacilityController = TextEditingController();
  final _doctorAddressController = TextEditingController();
  final _doctorNotesController = TextEditingController();
  final _pharmacyNameController = TextEditingController();
  final _pharmacyPhoneController = TextEditingController();
  final _pharmacyEmailController = TextEditingController();
  final _pharmacyAddressController = TextEditingController();
  final _pharmacyNotesController = TextEditingController();

  DateTime? _dateOfBirth;
  String _bloodType = 'Unknown';
  String _sex = 'Prefer not to say';

  MedicalProfileStrings get _strings {
    final language = _draft?.language ?? _saved?.language ?? 'English';
    return MedicalProfileStrings(language);
  }

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<MedicalProfileBundle> _load() async {
    final bundle = await _service.loadBundle();
    _saved = bundle;
    _draft = bundle;
    _fillControllers(bundle.profile);
    return bundle;
  }

  void _fillControllers(MedicalProfile profile) {
    _fullNameController.text = profile.fullName;
    _heightController.text = profile.heightCm?.toStringAsFixed(0) ?? '';
    _weightController.text = profile.weightKg == null
        ? ''
        : _trimDouble(profile.weightKg!);
    _dateOfBirth = profile.dateOfBirth;
    _bloodType = profile.bloodType;
    _sex = profile.sex;

    final doctor = profile.doctor;
    _doctorNameController.text = doctor?.name ?? '';
    _doctorSpecialtyController.text = doctor?.specialty ?? '';
    _doctorPhoneController.text = doctor?.phoneNumber ?? '';
    _doctorEmailController.text = doctor?.email ?? '';
    _doctorFacilityController.text = doctor?.facilityName ?? '';
    _doctorAddressController.text = doctor?.address ?? '';
    _doctorNotesController.text = doctor?.notes ?? '';

    final pharmacy = profile.pharmacy;
    _pharmacyNameController.text = pharmacy?.name ?? '';
    _pharmacyPhoneController.text = pharmacy?.phoneNumber ?? '';
    _pharmacyEmailController.text = pharmacy?.email ?? '';
    _pharmacyAddressController.text = pharmacy?.address ?? '';
    _pharmacyNotesController.text = pharmacy?.notes ?? '';
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _doctorNameController.dispose();
    _doctorSpecialtyController.dispose();
    _doctorPhoneController.dispose();
    _doctorEmailController.dispose();
    _doctorFacilityController.dispose();
    _doctorAddressController.dispose();
    _doctorNotesController.dispose();
    _pharmacyNameController.dispose();
    _pharmacyPhoneController.dispose();
    _pharmacyEmailController.dispose();
    _pharmacyAddressController.dispose();
    _pharmacyNotesController.dispose();
    super.dispose();
  }

  Future<bool> _confirmDiscardIfNeeded() async {
    if (!_isEditing || !_hasUnsavedChanges()) return true;
    final strings = _strings;
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(strings.t('discardTitle')),
        content: Text(strings.t('discardMessage')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(strings.t('keepEditing')),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(context, true),
            child: Text(strings.t('discard')),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  bool _hasUnsavedChanges() {
    final saved = _saved;
    final draft = _draft;
    if (saved == null || draft == null) return false;
    return saved.profile != _profileFromControllers() ||
        !_sameList(saved.allergies, draft.allergies) ||
        !_sameList(saved.conditions, draft.conditions) ||
        !_sameList(saved.emergencyContacts, draft.emergencyContacts);
  }

  bool _sameList<T>(List<T> first, List<T> second) {
    if (first.length != second.length) return false;
    for (var i = 0; i < first.length; i++) {
      if (first[i] != second[i]) return false;
    }
    return true;
  }

  void _startEditing() {
    final saved = _saved;
    if (saved == null) return;
    setState(() {
      _draft = saved.copyWith(
        allergies: [...saved.allergies],
        conditions: [...saved.conditions],
        emergencyContacts: [...saved.emergencyContacts],
      );
      _fillControllers(saved.profile);
      _errors.clear();
      _isEditing = true;
    });
  }

  Future<void> _cancelEditing() async {
    if (!await _confirmDiscardIfNeeded()) return;
    final saved = _saved;
    if (saved == null) return;
    setState(() {
      _draft = saved;
      _fillControllers(saved.profile);
      _errors.clear();
      _isEditing = false;
    });
  }

  Future<void> _save() async {
    if (_isSaving) return;
    final draft = _draft;
    if (draft == null) return;
    final profile = _profileFromControllers();
    if (!_validate(profile)) return;

    setState(() => _isSaving = true);
    try {
      final normalized = draft.copyWith(
        profile: profile,
        allergies: profile.noKnownAllergies ? [] : draft.allergies,
        conditions: profile.noKnownConditions ? [] : draft.conditions,
        emergencyContacts: MedicalProfileService.enforcePrimaryContact(
          draft.emergencyContacts,
          draft.emergencyContacts
              .firstWhere(
                (contact) => contact.isPrimary,
                orElse: () => const EmergencyContactRecord(id: '', fullName: ''),
              )
              .id,
        ),
      );
      await _service.saveBundle(normalized);
      if (!mounted) return;
      final reloaded = await _service.loadBundle();
      if (!mounted) return;
      setState(() {
        _saved = reloaded;
        _draft = reloaded;
        _fillControllers(reloaded.profile);
        _isEditing = false;
        _errors.clear();
      });
      showAuthMessage(context, _strings.t('savedMessage'));
    } catch (_) {
      if (!mounted) return;
      showAuthMessage(
        context,
        _strings.t('saveError'),
        backgroundColor: Colors.redAccent,
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  MedicalProfile _profileFromControllers() {
    final doctor = HealthcareProvider(
      providerType: HealthcareProviderType.doctor,
      name: _doctorNameController.text.trim(),
      specialty: _doctorSpecialtyController.text.trim(),
      phoneNumber: _doctorPhoneController.text.trim(),
      email: _doctorEmailController.text.trim(),
      facilityName: _doctorFacilityController.text.trim(),
      address: _doctorAddressController.text.trim(),
      notes: _doctorNotesController.text.trim(),
    );
    final pharmacy = HealthcareProvider(
      providerType: HealthcareProviderType.pharmacy,
      name: _pharmacyNameController.text.trim(),
      phoneNumber: _pharmacyPhoneController.text.trim(),
      email: _pharmacyEmailController.text.trim(),
      address: _pharmacyAddressController.text.trim(),
      notes: _pharmacyNotesController.text.trim(),
    );

    return (_draft?.profile ?? const MedicalProfile()).copyWith(
      fullName: _fullNameController.text.trim(),
      dateOfBirth: _dateOfBirth,
      bloodType: _bloodType,
      sex: _sex,
      heightCm: _heightController.text.trim().isEmpty
          ? null
          : double.tryParse(_heightController.text.trim()),
      weightKg: _weightController.text.trim().isEmpty
          ? null
          : double.tryParse(_weightController.text.trim()),
      doctor: doctor.hasAnyValue ? doctor : null,
      pharmacy: pharmacy.hasAnyValue ? pharmacy : null,
    );
  }

  bool _validate(MedicalProfile profile) {
    final errors = <String, String?>{
      'fullName': MedicalProfileValidation.optionalName(profile.fullName),
      'dateOfBirth': MedicalProfileValidation.dateOfBirth(profile.dateOfBirth),
      'height': MedicalProfileValidation.optionalHeight(_heightController.text),
      'weight': MedicalProfileValidation.optionalWeight(_weightController.text),
      'doctorPhone':
          MedicalProfileValidation.optionalPhone(_doctorPhoneController.text),
      'doctorEmail':
          MedicalProfileValidation.optionalEmail(_doctorEmailController.text),
      'doctorNotes':
          MedicalProfileValidation.notes(_doctorNotesController.text, max: 1000),
      'pharmacyPhone':
          MedicalProfileValidation.optionalPhone(_pharmacyPhoneController.text),
      'pharmacyEmail':
          MedicalProfileValidation.optionalEmail(_pharmacyEmailController.text),
      'pharmacyNotes':
          MedicalProfileValidation.notes(_pharmacyNotesController.text, max: 1000),
    };

    setState(() {
      _errors
        ..clear()
        ..addAll(errors);
    });
    return errors.values.every((error) => error == null);
  }

  Future<void> _pickBirthDate() async {
    final initial = _dateOfBirth ?? DateTime.now().subtract(const Duration(days: 365 * 25));
    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isAfter(DateTime.now()) ? DateTime.now() : initial,
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 130)),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _dateOfBirth = DateTime(picked.year, picked.month, picked.day));
    }
  }

  Future<void> _toggleNoKnownAllergies(bool value) async {
    final draft = _draft;
    if (draft == null) return;
    if (value && draft.allergies.isNotEmpty) {
      final confirmed = await _confirmAction(
        title: _strings.t('clearAllergiesTitle'),
        message: _strings.t('clearAllergiesMessage'),
        confirmLabel: _strings.t('clear'),
        danger: true,
      );
      if (!confirmed) return;
    }
    setState(() {
      _draft = draft.copyWith(
        profile: draft.profile.copyWith(noKnownAllergies: value),
        allergies: value ? [] : draft.allergies,
      );
    });
  }

  Future<void> _toggleNoKnownConditions(bool value) async {
    final draft = _draft;
    if (draft == null) return;
    if (value && draft.conditions.isNotEmpty) {
      final confirmed = await _confirmAction(
        title: _strings.t('clearConditionsTitle'),
        message: _strings.t('clearConditionsMessage'),
        confirmLabel: _strings.t('clear'),
        danger: true,
      );
      if (!confirmed) return;
    }
    setState(() {
      _draft = draft.copyWith(
        profile: draft.profile.copyWith(noKnownConditions: value),
        conditions: value ? [] : draft.conditions,
      );
    });
  }

  Future<void> _deleteProfile() async {
    final confirmed = await _confirmAction(
      title: _strings.t('deleteProfileTitle'),
      message: _strings.t('deleteProfileMessage'),
      confirmLabel: _strings.t('deleteProfile'),
      danger: true,
    );
    if (!confirmed || _isDeleting) return;

    setState(() => _isDeleting = true);
    try {
      await _service.deleteMedicalProfile();
      if (!mounted) return;
      final reloaded = await _service.loadBundle();
      if (!mounted) return;
      setState(() {
        _saved = reloaded;
        _draft = reloaded;
        _fillControllers(reloaded.profile);
        _isEditing = false;
        _errors.clear();
      });
      showAuthMessage(context, _strings.t('deletedMessage'));
    } catch (_) {
      if (!mounted) return;
      showAuthMessage(
        context,
        _strings.t('deleteError'),
        backgroundColor: Colors.redAccent,
      );
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  Future<bool> _confirmAction({
    required String title,
    required String message,
    required String confirmLabel,
    bool danger = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(_strings.t('cancel')),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: danger ? Colors.redAccent : authPrimary,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _addOrEditAllergy([AllergyRecord? record]) async {
    final draft = _draft;
    if (draft == null) return;
    final result = await showDialog<AllergyRecord>(
      context: context,
      builder: (_) => _AllergyDialog(
        record: record,
        existing: draft.allergies,
        strings: _strings,
      ),
    );
    if (result == null) return;
    setState(() {
      final list = [...draft.allergies];
      final index = list.indexWhere((item) => item.id == result.id);
      if (index == -1) {
        list.add(result);
      } else {
        list[index] = result;
      }
      list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      _draft = draft.copyWith(allergies: list);
    });
  }

  Future<void> _deleteAllergy(AllergyRecord record) async {
    if (!await _confirmAction(
      title: _strings.t('deleteAllergyTitle'),
      message: _strings.t('deleteItemMessage'),
      confirmLabel: _strings.t('delete'),
      danger: true,
    )) {
      return;
    }
    final draft = _draft;
    if (draft == null) return;
    setState(() {
      _draft = draft.copyWith(
        allergies: draft.allergies.where((item) => item.id != record.id).toList(),
      );
    });
  }

  Future<void> _addOrEditCondition([MedicalConditionRecord? record]) async {
    final draft = _draft;
    if (draft == null) return;
    final result = await showDialog<MedicalConditionRecord>(
      context: context,
      builder: (_) => _ConditionDialog(
        record: record,
        existing: draft.conditions,
        strings: _strings,
      ),
    );
    if (result == null) return;
    setState(() {
      final list = [...draft.conditions];
      final index = list.indexWhere((item) => item.id == result.id);
      if (index == -1) {
        list.add(result);
      } else {
        list[index] = result;
      }
      list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      _draft = draft.copyWith(conditions: list);
    });
  }

  Future<void> _deleteCondition(MedicalConditionRecord record) async {
    if (!await _confirmAction(
      title: _strings.t('deleteConditionTitle'),
      message: _strings.t('deleteItemMessage'),
      confirmLabel: _strings.t('delete'),
      danger: true,
    )) {
      return;
    }
    final draft = _draft;
    if (draft == null) return;
    setState(() {
      _draft = draft.copyWith(
        conditions: draft.conditions.where((item) => item.id != record.id).toList(),
      );
    });
  }

  Future<void> _addOrEditContact([EmergencyContactRecord? record]) async {
    final draft = _draft;
    if (draft == null) return;
    final result = await showDialog<EmergencyContactRecord>(
      context: context,
      builder: (_) => _ContactDialog(record: record, strings: _strings),
    );
    if (result == null) return;
    setState(() {
      var list = [...draft.emergencyContacts];
      final index = list.indexWhere((item) => item.id == result.id);
      if (index == -1) {
        list.add(result);
      } else {
        list[index] = result;
      }
      if (result.isPrimary) {
        list = MedicalProfileService.enforcePrimaryContact(list, result.id);
      }
      list.sort((a, b) {
        if (a.isPrimary != b.isPrimary) return a.isPrimary ? -1 : 1;
        return a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase());
      });
      _draft = draft.copyWith(emergencyContacts: list);
    });
  }

  Future<void> _deleteContact(EmergencyContactRecord record) async {
    if (!await _confirmAction(
      title: _strings.t('deleteContactTitle'),
      message: _strings.t('deleteItemMessage'),
      confirmLabel: _strings.t('delete'),
      danger: true,
    )) {
      return;
    }
    final draft = _draft;
    if (draft == null) return;
    setState(() {
      _draft = draft.copyWith(
        emergencyContacts:
            draft.emergencyContacts.where((item) => item.id != record.id).toList(),
      );
    });
  }

  Future<void> _launchContact(String value, bool isEmail) async {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return;
    final uri = Uri(
      scheme: isEmail ? 'mailto' : 'tel',
      path: trimmed,
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (mounted) {
      showAuthMessage(
        context,
        _strings.t('openUnsupported'),
        backgroundColor: Colors.redAccent,
      );
    }
  }

  void _clearDoctor() {
    setState(() {
      _doctorNameController.clear();
      _doctorSpecialtyController.clear();
      _doctorPhoneController.clear();
      _doctorEmailController.clear();
      _doctorFacilityController.clear();
      _doctorAddressController.clear();
      _doctorNotesController.clear();
    });
  }

  void _clearPharmacy() {
    setState(() {
      _pharmacyNameController.clear();
      _pharmacyPhoneController.clear();
      _pharmacyEmailController.clear();
      _pharmacyAddressController.clear();
      _pharmacyNotesController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _confirmDiscardIfNeeded,
      child: Scaffold(
        backgroundColor: appScaffoldColor(context),
        appBar: AppBar(
          backgroundColor: authPrimary,
          foregroundColor: Colors.white,
          title: Text(
            _strings.t('title'),
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          actions: [
            if (_isEditing) ...[
              TextButton(
                onPressed: _isSaving ? null : _cancelEditing,
                child: Text(
                  _strings.t('cancel'),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              TextButton.icon(
                onPressed: _isSaving ? null : _save,
                icon: _isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save_outlined, color: Colors.white),
                label: Text(
                  _isSaving ? _strings.t('saving') : _strings.t('save'),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ] else
              IconButton(
                tooltip: _strings.t('edit'),
                onPressed: _startEditing,
                icon: const Icon(Icons.edit_outlined),
              ),
          ],
        ),
        body: FutureBuilder<MedicalProfileBundle>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: authPrimary),
              );
            }
            if (snapshot.hasError) {
              return _LoadError(
                message: _strings.t('loadError'),
                retryLabel: _strings.t('retry'),
                onRetry: () {
                  setState(() => _future = _load());
                },
              );
            }
            final bundle = _draft ?? snapshot.data;
            if (bundle == null) {
              return _LoadError(
                message: _strings.t('loadError'),
                retryLabel: _strings.t('retry'),
                onRetry: () {
                  setState(() => _future = _load());
                },
              );
            }
            return _buildContent(bundle);
          },
        ),
      ),
    );
  }

  Widget _buildContent(MedicalProfileBundle bundle) {
    final strings = _strings;
    final profile = _profileFromControllers();
    final completion = profile.completionPercent(
      hasAllergyStatus: profile.noKnownAllergies || bundle.allergies.isNotEmpty,
      hasConditionStatus:
          profile.noKnownConditions || bundle.conditions.isNotEmpty,
      hasEmergencyContact: bundle.emergencyContacts.isNotEmpty,
    );

    return SafeArea(
      top: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 32),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1040),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _HeaderCard(
                    title: strings.t('title'),
                    subtitle: strings.t('subtitle'),
                    completion: completion,
                    isEditing: _isEditing,
                    onEdit: _startEditing,
                    onSave: _save,
                    onCancel: _cancelEditing,
                    isSaving: _isSaving,
                    strings: strings,
                  ),
                  if (!bundle.exists) ...[
                    const SizedBox(height: 14),
                    _EmptyInline(
                      text: strings.t('profileNotCompleted'),
                      action: _isEditing ? null : strings.t('completeProfile'),
                      onAction: _isEditing ? null : _startEditing,
                    ),
                  ],
                  const SizedBox(height: 14),
                  _SectionCard(
                    title: strings.t('basicInfo'),
                    icon: Icons.health_and_safety_outlined,
                    child: _basicSection(profile),
                  ),
                  const SizedBox(height: 14),
                  _SectionCard(
                    title: strings.t('allergies'),
                    icon: Icons.warning_amber_outlined,
                    action: _isEditing && !bundle.profile.noKnownAllergies
                        ? _SectionAction(
                            label: strings.t('addAllergy'),
                            icon: Icons.add,
                            onPressed: () => _addOrEditAllergy(),
                          )
                        : null,
                    child: _allergySection(bundle),
                  ),
                  const SizedBox(height: 14),
                  _SectionCard(
                    title: strings.t('conditions'),
                    icon: Icons.monitor_heart_outlined,
                    action: _isEditing && !bundle.profile.noKnownConditions
                        ? _SectionAction(
                            label: strings.t('addCondition'),
                            icon: Icons.add,
                            onPressed: () => _addOrEditCondition(),
                          )
                        : null,
                    child: _conditionSection(bundle),
                  ),
                  const SizedBox(height: 14),
                  _SectionCard(
                    title: strings.t('emergencyContacts'),
                    icon: Icons.contact_phone_outlined,
                    action: _isEditing
                        ? _SectionAction(
                            label: strings.t('addContact'),
                            icon: Icons.add,
                            onPressed: () => _addOrEditContact(),
                          )
                        : null,
                    child: _contactsSection(bundle),
                  ),
                  const SizedBox(height: 14),
                  _SectionCard(
                    title: strings.t('providers'),
                    icon: Icons.medical_services_outlined,
                    child: _providersSection(profile),
                  ),
                  const SizedBox(height: 14),
                  _DeleteProfileCard(
                    strings: strings,
                    onDelete: _isDeleting ? null : _deleteProfile,
                    isDeleting: _isDeleting,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _basicSection(MedicalProfile profile) {
    final strings = _strings;
    if (!_isEditing) {
      final age = profile.calculatedAge();
      return _InfoGrid(
        children: [
          _InfoTile(icon: Icons.badge_outlined, label: strings.t('fullName'), value: _value(profile.fullName)),
          _InfoTile(icon: Icons.cake_outlined, label: strings.t('dateOfBirth'), value: profile.dateOfBirth == null ? _value('') : _formatDate(profile.dateOfBirth!)),
          _InfoTile(icon: Icons.timeline_outlined, label: strings.t('age'), value: age == null ? (profile.legacyAge == null ? _value('') : '${profile.legacyAge} ${strings.t('years')}') : '$age ${strings.t('years')}'),
          _InfoTile(icon: Icons.bloodtype_outlined, label: strings.t('bloodType'), value: profile.bloodType),
          _InfoTile(icon: Icons.person_outline, label: strings.t('sex'), value: profile.sex),
          _InfoTile(icon: Icons.height, label: strings.t('height'), value: profile.heightCm == null ? _value('') : '${_trimDouble(profile.heightCm!)} cm'),
          _InfoTile(icon: Icons.monitor_weight_outlined, label: strings.t('weight'), value: profile.weightKg == null ? _value('') : '${_trimDouble(profile.weightKg!)} kg'),
        ],
      );
    }

    final age = MedicalProfile(dateOfBirth: _dateOfBirth).calculatedAge();
    return Column(
      children: [
        _ResponsiveFields(
          children: [
            _FieldBox(
              child: TextField(
                controller: _fullNameController,
                decoration: authInputDecoration(
                  context: context,
                  hintText: strings.t('fullName'),
                  icon: Icons.badge_outlined,
                  errorText: _errors['fullName'],
                ),
              ),
            ),
            _FieldBox(
              child: _DatePickerTile(
                label: strings.t('dateOfBirth'),
                value: _dateOfBirth == null ? strings.t('notAdded') : _formatDate(_dateOfBirth!),
                errorText: _errors['dateOfBirth'],
                onTap: _pickBirthDate,
              ),
            ),
            _FieldBox(
              child: _ReadOnlyField(
                label: strings.t('age'),
                value: age == null ? strings.t('notCalculated') : '$age ${strings.t('years')}',
                icon: Icons.timeline_outlined,
              ),
            ),
            _FieldBox(
              child: DropdownButtonFormField<String>(
                value: _bloodType,
                decoration: authInputDecoration(
                  context: context,
                  hintText: strings.t('bloodType'),
                  icon: Icons.bloodtype_outlined,
                ),
                items: const ['Unknown', 'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-']
                    .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                    .toList(),
                onChanged: (value) => setState(() => _bloodType = value ?? 'Unknown'),
              ),
            ),
            _FieldBox(
              child: DropdownButtonFormField<String>(
                value: _sex,
                decoration: authInputDecoration(
                  context: context,
                  hintText: strings.t('sex'),
                  icon: Icons.person_outline,
                ),
                items: const ['Prefer not to say', 'Male', 'Female', 'Other']
                    .map((value) => DropdownMenuItem(value: value, child: Text(strings.option(value))))
                    .toList(),
                onChanged: (value) => setState(() => _sex = value ?? 'Prefer not to say'),
              ),
            ),
            _FieldBox(
              child: TextField(
                controller: _heightController,
                keyboardType: TextInputType.number,
                decoration: authInputDecoration(
                  context: context,
                  hintText: strings.t('heightCm'),
                  icon: Icons.height,
                  errorText: _errors['height'],
                ),
              ),
            ),
            _FieldBox(
              child: TextField(
                controller: _weightController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: authInputDecoration(
                  context: context,
                  hintText: strings.t('weightKg'),
                  icon: Icons.monitor_weight_outlined,
                  errorText: _errors['weight'],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _allergySection(MedicalProfileBundle bundle) {
    final strings = _strings;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          activeColor: authPrimary,
          title: Text(strings.t('noKnownAllergies')),
          value: bundle.profile.noKnownAllergies,
          onChanged: _isEditing ? _toggleNoKnownAllergies : null,
        ),
        if (bundle.profile.noKnownAllergies)
          _InlineNote(text: strings.t('noKnownAllergiesSelected'))
        else if (bundle.allergies.isEmpty)
          _EmptyInline(
            text: strings.t('emptyAllergies'),
            action: _isEditing ? strings.t('addAllergy') : null,
            onAction: _isEditing ? () => _addOrEditAllergy() : null,
          )
        else
          ...bundle.allergies.map(
            (allergy) => _RecordTile(
              icon: Icons.warning_amber_outlined,
              title: allergy.name,
              subtitle: '${strings.option(allergy.severity)}${allergy.notes.trim().isEmpty ? '' : ' - ${allergy.notes.trim()}'}',
              isEditing: _isEditing,
              strings: strings,
              onEdit: () => _addOrEditAllergy(allergy),
              onDelete: () => _deleteAllergy(allergy),
            ),
          ),
      ],
    );
  }

  Widget _conditionSection(MedicalProfileBundle bundle) {
    final strings = _strings;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          activeColor: authPrimary,
          title: Text(strings.t('noKnownConditions')),
          value: bundle.profile.noKnownConditions,
          onChanged: _isEditing ? _toggleNoKnownConditions : null,
        ),
        if (bundle.profile.noKnownConditions)
          _InlineNote(text: strings.t('noKnownConditionsSelected'))
        else if (bundle.conditions.isEmpty)
          _EmptyInline(
            text: strings.t('emptyConditions'),
            action: _isEditing ? strings.t('addCondition') : null,
            onAction: _isEditing ? () => _addOrEditCondition() : null,
          )
        else
          ...bundle.conditions.map(
            (condition) {
              final date = condition.diagnosisDate == null
                  ? ''
                  : ' - ${_formatDate(condition.diagnosisDate!)}';
              return _RecordTile(
                icon: Icons.monitor_heart_outlined,
                title: condition.name,
                subtitle:
                    '${strings.option(condition.status)}$date${condition.notes.trim().isEmpty ? '' : ' - ${condition.notes.trim()}'}',
                isEditing: _isEditing,
                strings: strings,
                onEdit: () => _addOrEditCondition(condition),
                onDelete: () => _deleteCondition(condition),
              );
            },
          ),
      ],
    );
  }

  Widget _contactsSection(MedicalProfileBundle bundle) {
    final strings = _strings;
    if (bundle.emergencyContacts.isEmpty) {
      return _EmptyInline(
        text: strings.t('emptyContacts'),
        action: _isEditing ? strings.t('addContact') : null,
        onAction: _isEditing ? () => _addOrEditContact() : null,
      );
    }

    return Column(
      children: bundle.emergencyContacts.map((contact) {
        return _ContactCard(
          contact: contact,
          strings: strings,
          isEditing: _isEditing,
          onEdit: () => _addOrEditContact(contact),
          onDelete: () => _deleteContact(contact),
          onCall: kIsWeb || contact.phoneNumber.trim().isEmpty
              ? null
              : () => _launchContact(contact.phoneNumber, false),
        );
      }).toList(),
    );
  }

  Widget _providersSection(MedicalProfile profile) {
    final strings = _strings;
    if (!_isEditing) {
      return Column(
        children: [
          _ProviderView(
            title: strings.t('doctorInfo'),
            provider: profile.doctor,
            emptyText: strings.t('emptyDoctor'),
            strings: strings,
            onCall: profile.doctor?.phoneNumber.trim().isEmpty ?? true
                ? null
                : () => _launchContact(profile.doctor!.phoneNumber, false),
            onEmail: profile.doctor?.email.trim().isEmpty ?? true
                ? null
                : () => _launchContact(profile.doctor!.email, true),
          ),
          const SizedBox(height: 12),
          _ProviderView(
            title: strings.t('pharmacyInfo'),
            provider: profile.pharmacy,
            emptyText: strings.t('emptyPharmacy'),
            strings: strings,
            onCall: profile.pharmacy?.phoneNumber.trim().isEmpty ?? true
                ? null
                : () => _launchContact(profile.pharmacy!.phoneNumber, false),
            onEmail: profile.pharmacy?.email.trim().isEmpty ?? true
                ? null
                : () => _launchContact(profile.pharmacy!.email, true),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(strings.t('doctorInfo'), style: _sectionSubheadingStyle(context)),
        const SizedBox(height: 10),
        _ResponsiveFields(
          children: [
            _FieldBox(child: _textField(_doctorNameController, strings.t('doctorName'), Icons.person_outline)),
            _FieldBox(child: _textField(_doctorSpecialtyController, strings.t('specialty'), Icons.local_hospital_outlined)),
            _FieldBox(child: _textField(_doctorPhoneController, strings.t('phone'), Icons.phone_outlined, errorKey: 'doctorPhone')),
            _FieldBox(child: _textField(_doctorEmailController, strings.t('email'), Icons.email_outlined, errorKey: 'doctorEmail', keyboardType: TextInputType.emailAddress)),
            _FieldBox(child: _textField(_doctorFacilityController, strings.t('clinic'), Icons.business_outlined)),
            _FieldBox(child: _textField(_doctorAddressController, strings.t('address'), Icons.location_on_outlined)),
          ],
        ),
        const SizedBox(height: 10),
        _textField(_doctorNotesController, strings.t('notes'), Icons.notes_outlined, errorKey: 'doctorNotes', maxLines: 3),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: _clearDoctor,
            icon: const Icon(Icons.clear),
            label: Text(strings.t('removeDoctor')),
          ),
        ),
        const SizedBox(height: 18),
        Text(strings.t('pharmacyInfo'), style: _sectionSubheadingStyle(context)),
        const SizedBox(height: 10),
        _ResponsiveFields(
          children: [
            _FieldBox(child: _textField(_pharmacyNameController, strings.t('pharmacyName'), Icons.local_pharmacy_outlined)),
            _FieldBox(child: _textField(_pharmacyPhoneController, strings.t('phone'), Icons.phone_outlined, errorKey: 'pharmacyPhone')),
            _FieldBox(child: _textField(_pharmacyEmailController, strings.t('email'), Icons.email_outlined, errorKey: 'pharmacyEmail', keyboardType: TextInputType.emailAddress)),
            _FieldBox(child: _textField(_pharmacyAddressController, strings.t('address'), Icons.location_on_outlined)),
          ],
        ),
        const SizedBox(height: 10),
        _textField(_pharmacyNotesController, strings.t('notes'), Icons.notes_outlined, errorKey: 'pharmacyNotes', maxLines: 3),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: _clearPharmacy,
            icon: const Icon(Icons.clear),
            label: Text(strings.t('removePharmacy')),
          ),
        ),
      ],
    );
  }

  Widget _textField(
    TextEditingController controller,
    String hint,
    IconData icon, {
    String? errorKey,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: authInputDecoration(
        context: context,
        hintText: hint,
        icon: icon,
        errorText: errorKey == null ? null : _errors[errorKey],
      ),
    );
  }

  TextStyle _sectionSubheadingStyle(BuildContext context) {
    return TextStyle(
      color: appTextColor(context),
      fontSize: 16,
      fontWeight: FontWeight.w900,
    );
  }

  String _formatDate(DateTime date) {
    return MaterialLocalizations.of(context).formatMediumDate(date);
  }

  String _value(String value) {
    return value.trim().isEmpty ? _strings.t('notAdded') : value.trim();
  }

  String _trimDouble(double value) {
    if (value == value.roundToDouble()) return value.toStringAsFixed(0);
    return value.toStringAsFixed(1);
  }
}

class _HeaderCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final int completion;
  final bool isEditing;
  final bool isSaving;
  final VoidCallback onEdit;
  final VoidCallback onSave;
  final VoidCallback onCancel;
  final MedicalProfileStrings strings;

  const _HeaderCard({
    required this.title,
    required this.subtitle,
    required this.completion,
    required this.isEditing,
    required this.isSaving,
    required this.onEdit,
    required this.onSave,
    required this.onCancel,
    required this.strings,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: appSurfaceColor(context),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: appBorderColor(context)),
        boxShadow: [
          BoxShadow(
            color: appShadowColor(context, 0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: appTintSurfaceColor(context),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.health_and_safety_outlined, color: authPrimary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: appTextColor(context),
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: appMutedTextColor(context),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 10,
              value: completion / 100,
              backgroundColor: appSoftSurfaceColor(context),
              valueColor: const AlwaysStoppedAnimation(authPrimary),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${strings.t('completion')} $completion%',
            style: TextStyle(
              color: appMutedTextColor(context),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: isEditing
                ? [
                    OutlinedButton.icon(
                      onPressed: isSaving ? null : onCancel,
                      icon: const Icon(Icons.close),
                      label: Text(strings.t('cancel')),
                    ),
                    FilledButton.icon(
                      onPressed: isSaving ? null : onSave,
                      icon: isSaving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.save_outlined),
                      label: Text(isSaving ? strings.t('saving') : strings.t('save')),
                      style: FilledButton.styleFrom(backgroundColor: authPrimary),
                    ),
                  ]
                : [
                    FilledButton.icon(
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit_outlined),
                      label: Text(strings.t('edit')),
                      style: FilledButton.styleFrom(backgroundColor: authPrimary),
                    ),
                  ],
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final _SectionAction? action;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: appSurfaceColor(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: appBorderColor(context)),
        boxShadow: [
          BoxShadow(
            color: appShadowColor(context, 0.05),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: appTintSurfaceColor(context),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: authPrimary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: appTextColor(context),
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (action != null)
                TextButton.icon(
                  onPressed: action!.onPressed,
                  icon: Icon(action!.icon, size: 18),
                  label: Text(action!.label),
                ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _SectionAction {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  const _SectionAction({
    required this.label,
    required this.icon,
    required this.onPressed,
  });
}

class _ResponsiveFields extends StatelessWidget {
  final List<Widget> children;

  const _ResponsiveFields({required this.children});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth >= 720
            ? (constraints.maxWidth - 12) / 2
            : constraints.maxWidth;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: children
              .map((child) => SizedBox(width: width, child: child))
              .toList(),
        );
      },
    );
  }
}

class _FieldBox extends StatelessWidget {
  final Widget child;

  const _FieldBox({required this.child});

  @override
  Widget build(BuildContext context) => child;
}

class _ReadOnlyField extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _ReadOnlyField({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: appSoftSurfaceColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: appBorderColor(context)),
      ),
      child: Row(
        children: [
          Icon(icon, color: authPrimary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: appMutedTextColor(context),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    color: appTextColor(context),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DatePickerTile extends StatelessWidget {
  final String label;
  final String value;
  final String? errorText;
  final VoidCallback onTap;

  const _DatePickerTile({
    required this.label,
    required this.value,
    required this.errorText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            height: 58,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: appSoftSurfaceColor(context),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: errorText == null ? appBorderColor(context) : Colors.redAccent,
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.cake_outlined, color: authPrimary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    value,
                    style: TextStyle(
                      color: appTextColor(context),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Icon(Icons.calendar_today_outlined, color: appMutedTextColor(context)),
              ],
            ),
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 5),
          Text(
            errorText!,
            style: const TextStyle(
              color: Colors.redAccent,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ],
    );
  }
}

class _InfoGrid extends StatelessWidget {
  final List<_InfoTile> children;

  const _InfoGrid({required this.children});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth >= 720 ? 2 : 1;
        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: crossAxisCount == 1 ? 3.6 : 3.2,
          children: children,
        );
      },
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: appSoftSurfaceColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: appBorderColor(context)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: appTintSurfaceColor(context),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: authPrimary, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: appMutedTextColor(context),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: appTextColor(context),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RecordTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isEditing;
  final MedicalProfileStrings strings;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _RecordTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isEditing,
    required this.strings,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: appSoftSurfaceColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: appBorderColor(context)),
      ),
      child: Row(
        children: [
          Icon(icon, color: authPrimary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: appTextColor(context),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (subtitle.trim().isNotEmpty)
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: appMutedTextColor(context),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),
          if (isEditing) ...[
            IconButton(
              tooltip: strings.t('edit'),
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined, color: authPrimary),
            ),
            IconButton(
              tooltip: strings.t('delete'),
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            ),
          ],
        ],
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  final EmergencyContactRecord contact;
  final MedicalProfileStrings strings;
  final bool isEditing;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onCall;

  const _ContactCard({
    required this.contact,
    required this.strings,
    required this.isEditing,
    required this.onEdit,
    required this.onDelete,
    required this.onCall,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: appSoftSurfaceColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: appBorderColor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.contact_phone_outlined, color: authPrimary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  contact.fullName,
                  style: TextStyle(
                    color: appTextColor(context),
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
              ),
              if (contact.isPrimary)
                _SmallPill(label: strings.t('primary')),
              if (isEditing) ...[
                IconButton(
                  tooltip: strings.t('edit'),
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined, color: authPrimary),
                ),
                IconButton(
                  tooltip: strings.t('delete'),
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          _ContactLine(label: strings.t('relationship'), value: contact.relationship),
          _ContactLine(label: strings.t('phone'), value: contact.phoneNumber),
          _ContactLine(label: strings.t('secondaryPhone'), value: contact.secondaryPhoneNumber),
          if (contact.notes.trim().isNotEmpty)
            _ContactLine(label: strings.t('notes'), value: contact.notes),
          if (onCall != null) ...[
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: onCall,
              icon: const Icon(Icons.call_outlined),
              label: Text(strings.t('call')),
            ),
          ],
        ],
      ),
    );
  }
}

class _ContactLine extends StatelessWidget {
  final String label;
  final String value;

  const _ContactLine({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    if (value.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 3),
      child: Text(
        '$label: $value',
        style: TextStyle(
          color: appMutedTextColor(context),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ProviderView extends StatelessWidget {
  final String title;
  final HealthcareProvider? provider;
  final String emptyText;
  final MedicalProfileStrings strings;
  final VoidCallback? onCall;
  final VoidCallback? onEmail;

  const _ProviderView({
    required this.title,
    required this.provider,
    required this.emptyText,
    required this.strings,
    required this.onCall,
    required this.onEmail,
  });

  @override
  Widget build(BuildContext context) {
    final provider = this.provider;
    if (provider == null || !provider.hasAnyValue) {
      return _EmptyInline(text: emptyText);
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: appSoftSurfaceColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: appBorderColor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: appTextColor(context),
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          _ContactLine(label: strings.t('name'), value: provider.name),
          _ContactLine(label: strings.t('specialty'), value: provider.specialty),
          _ContactLine(label: strings.t('phone'), value: provider.phoneNumber),
          _ContactLine(label: strings.t('email'), value: provider.email),
          _ContactLine(label: strings.t('clinic'), value: provider.facilityName),
          _ContactLine(label: strings.t('address'), value: provider.address),
          _ContactLine(label: strings.t('notes'), value: provider.notes),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              if (!kIsWeb && onCall != null)
                OutlinedButton.icon(
                  onPressed: onCall,
                  icon: const Icon(Icons.call_outlined),
                  label: Text(strings.t('call')),
                ),
              if (onEmail != null)
                OutlinedButton.icon(
                  onPressed: onEmail,
                  icon: const Icon(Icons.email_outlined),
                  label: Text(strings.t('email')),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SmallPill extends StatelessWidget {
  final String label;

  const _SmallPill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: appTintSurfaceColor(context),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: authPrimary,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _EmptyInline extends StatelessWidget {
  final String text;
  final String? action;
  final VoidCallback? onAction;

  const _EmptyInline({required this.text, this.action, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: appSoftSurfaceColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: appBorderColor(context)),
      ),
      child: Column(
        children: [
          Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: appMutedTextColor(context),
              fontWeight: FontWeight.w700,
            ),
          ),
          if (action != null && onAction != null) ...[
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.add),
              label: Text(action!),
            ),
          ],
        ],
      ),
    );
  }
}

class _InlineNote extends StatelessWidget {
  final String text;

  const _InlineNote({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: appTintSurfaceColor(context),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: appTextColor(context),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _DeleteProfileCard extends StatelessWidget {
  final MedicalProfileStrings strings;
  final VoidCallback? onDelete;
  final bool isDeleting;

  const _DeleteProfileCard({
    required this.strings,
    required this.onDelete,
    required this.isDeleting,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: appSurfaceColor(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: appBorderColor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            strings.t('privacyText'),
            style: TextStyle(
              color: appMutedTextColor(context),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: onDelete,
            icon: isDeleting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.delete_outline),
            label: Text(
              isDeleting ? strings.t('deleting') : strings.t('deleteProfile'),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.redAccent,
              side: const BorderSide(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadError extends StatelessWidget {
  final String message;
  final String retryLabel;
  final VoidCallback onRetry;

  const _LoadError({
    required this.message,
    required this.retryLabel,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 44),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: appTextColor(context),
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: Text(retryLabel),
              style: FilledButton.styleFrom(backgroundColor: authPrimary),
            ),
          ],
        ),
      ),
    );
  }
}

class _AllergyDialog extends StatefulWidget {
  final AllergyRecord? record;
  final List<AllergyRecord> existing;
  final MedicalProfileStrings strings;

  const _AllergyDialog({
    required this.record,
    required this.existing,
    required this.strings,
  });

  @override
  State<_AllergyDialog> createState() => _AllergyDialogState();
}

class _AllergyDialogState extends State<_AllergyDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _notesController;
  String _severity = 'Unknown';
  String? _nameError;
  String? _notesError;

  @override
  void initState() {
    super.initState();
    final record = widget.record;
    _nameController = TextEditingController(text: record?.name ?? '');
    _notesController = TextEditingController(text: record?.notes ?? '');
    _severity = record?.severity ?? 'Unknown';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _save() {
    final name = _nameController.text.trim();
    final id = widget.record?.id ?? MedicalProfileService.newLocalId();
    final duplicate = MedicalProfileValidation.hasDuplicateName<AllergyRecord>(
      records: widget.existing,
      id: id,
      name: name,
      idOf: (record) => record.id,
      nameOf: (record) => record.name,
    );
    setState(() {
      _nameError = MedicalProfileValidation.requiredName(name);
      if (_nameError == null && duplicate) {
        _nameError = widget.strings.t('duplicateAllergy');
      }
      _notesError = MedicalProfileValidation.notes(_notesController.text);
    });
    if (_nameError != null || _notesError != null) return;
    Navigator.pop(
      context,
      AllergyRecord(
        id: id,
        name: name,
        severity: _severity,
        notes: _notesController.text.trim(),
        createdAt: widget.record?.createdAt,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = widget.strings;
    return AlertDialog(
      title: Text(widget.record == null ? strings.t('addAllergy') : strings.t('editAllergy')),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: authInputDecoration(
                context: context,
                hintText: strings.t('allergyName'),
                icon: Icons.warning_amber_outlined,
                errorText: _nameError,
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _severity,
              decoration: authInputDecoration(
                context: context,
                hintText: strings.t('severity'),
                icon: Icons.report_problem_outlined,
              ),
              items: const ['Mild', 'Moderate', 'Severe', 'Unknown']
                  .map((value) => DropdownMenuItem(value: value, child: Text(strings.option(value))))
                  .toList(),
              onChanged: (value) => setState(() => _severity = value ?? 'Unknown'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: authInputDecoration(
                context: context,
                hintText: strings.t('notes'),
                icon: Icons.notes_outlined,
                errorText: _notesError,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(strings.t('cancel')),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: authPrimary),
          onPressed: _save,
          child: Text(strings.t('save')),
        ),
      ],
    );
  }
}

class _ConditionDialog extends StatefulWidget {
  final MedicalConditionRecord? record;
  final List<MedicalConditionRecord> existing;
  final MedicalProfileStrings strings;

  const _ConditionDialog({
    required this.record,
    required this.existing,
    required this.strings,
  });

  @override
  State<_ConditionDialog> createState() => _ConditionDialogState();
}

class _ConditionDialogState extends State<_ConditionDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _notesController;
  DateTime? _diagnosisDate;
  String _status = 'Unknown';
  String? _nameError;
  String? _dateError;
  String? _notesError;

  @override
  void initState() {
    super.initState();
    final record = widget.record;
    _nameController = TextEditingController(text: record?.name ?? '');
    _notesController = TextEditingController(text: record?.notes ?? '');
    _diagnosisDate = record?.diagnosisDate;
    _status = record?.status ?? 'Unknown';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _diagnosisDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 130)),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _diagnosisDate = DateTime(picked.year, picked.month, picked.day));
    }
  }

  void _save() {
    final name = _nameController.text.trim();
    final id = widget.record?.id ?? MedicalProfileService.newLocalId();
    final duplicate =
        MedicalProfileValidation.hasDuplicateName<MedicalConditionRecord>(
      records: widget.existing,
      id: id,
      name: name,
      idOf: (record) => record.id,
      nameOf: (record) => record.name,
    );
    setState(() {
      _nameError = MedicalProfileValidation.requiredName(name);
      if (_nameError == null && duplicate) {
        _nameError = widget.strings.t('duplicateCondition');
      }
      _dateError = MedicalProfileValidation.pastDate(_diagnosisDate);
      _notesError = MedicalProfileValidation.notes(_notesController.text);
    });
    if (_nameError != null || _dateError != null || _notesError != null) return;
    Navigator.pop(
      context,
      MedicalConditionRecord(
        id: id,
        name: name,
        diagnosisDate: _diagnosisDate,
        status: _status,
        notes: _notesController.text.trim(),
        createdAt: widget.record?.createdAt,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = widget.strings;
    return AlertDialog(
      title: Text(widget.record == null ? strings.t('addCondition') : strings.t('editCondition')),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: authInputDecoration(
                context: context,
                hintText: strings.t('conditionName'),
                icon: Icons.monitor_heart_outlined,
                errorText: _nameError,
              ),
            ),
            const SizedBox(height: 12),
            _DatePickerTile(
              label: strings.t('diagnosisDate'),
              value: _diagnosisDate == null
                  ? strings.t('diagnosisDate')
                  : MaterialLocalizations.of(context).formatMediumDate(_diagnosisDate!),
              errorText: _dateError,
              onTap: _pickDate,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _status,
              decoration: authInputDecoration(
                context: context,
                hintText: strings.t('status'),
                icon: Icons.info_outline,
              ),
              items: const ['Active', 'Managed', 'Resolved', 'Unknown']
                  .map((value) => DropdownMenuItem(value: value, child: Text(strings.option(value))))
                  .toList(),
              onChanged: (value) => setState(() => _status = value ?? 'Unknown'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: authInputDecoration(
                context: context,
                hintText: strings.t('notes'),
                icon: Icons.notes_outlined,
                errorText: _notesError,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(strings.t('cancel')),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: authPrimary),
          onPressed: _save,
          child: Text(strings.t('save')),
        ),
      ],
    );
  }
}

class _ContactDialog extends StatefulWidget {
  final EmergencyContactRecord? record;
  final MedicalProfileStrings strings;

  const _ContactDialog({required this.record, required this.strings});

  @override
  State<_ContactDialog> createState() => _ContactDialogState();
}

class _ContactDialogState extends State<_ContactDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _relationshipController;
  late final TextEditingController _phoneController;
  late final TextEditingController _secondaryPhoneController;
  late final TextEditingController _notesController;
  bool _isPrimary = false;
  String? _nameError;
  String? _phoneError;
  String? _notesError;

  @override
  void initState() {
    super.initState();
    final record = widget.record;
    _nameController = TextEditingController(text: record?.fullName ?? '');
    _relationshipController =
        TextEditingController(text: record?.relationship ?? '');
    _phoneController = TextEditingController(text: record?.phoneNumber ?? '');
    _secondaryPhoneController =
        TextEditingController(text: record?.secondaryPhoneNumber ?? '');
    _notesController = TextEditingController(text: record?.notes ?? '');
    _isPrimary = record?.isPrimary ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _relationshipController.dispose();
    _phoneController.dispose();
    _secondaryPhoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _save() {
    setState(() {
      _nameError = MedicalProfileValidation.requiredName(_nameController.text);
      _phoneError = MedicalProfileValidation.requiredPhoneEither(
        _phoneController.text,
        _secondaryPhoneController.text,
      );
      _notesError = MedicalProfileValidation.notes(_notesController.text);
    });
    if (_nameError != null || _phoneError != null || _notesError != null) {
      return;
    }
    Navigator.pop(
      context,
      EmergencyContactRecord(
        id: widget.record?.id ?? MedicalProfileService.newLocalId(),
        fullName: _nameController.text.trim(),
        relationship: _relationshipController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        secondaryPhoneNumber: _secondaryPhoneController.text.trim(),
        isPrimary: _isPrimary,
        notes: _notesController.text.trim(),
        createdAt: widget.record?.createdAt,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = widget.strings;
    return AlertDialog(
      title: Text(widget.record == null ? strings.t('addContact') : strings.t('editContact')),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: authInputDecoration(
                context: context,
                hintText: strings.t('fullName'),
                icon: Icons.person_outline,
                errorText: _nameError,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _relationshipController,
              decoration: authInputDecoration(
                context: context,
                hintText: strings.t('relationship'),
                icon: Icons.group_outlined,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: authInputDecoration(
                context: context,
                hintText: strings.t('phone'),
                icon: Icons.phone_outlined,
                errorText: _phoneError,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _secondaryPhoneController,
              keyboardType: TextInputType.phone,
              decoration: authInputDecoration(
                context: context,
                hintText: strings.t('secondaryPhone'),
                icon: Icons.phone_android_outlined,
              ),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              activeColor: authPrimary,
              title: Text(strings.t('primaryContact')),
              value: _isPrimary,
              onChanged: (value) => setState(() => _isPrimary = value),
            ),
            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: authInputDecoration(
                context: context,
                hintText: strings.t('notes'),
                icon: Icons.notes_outlined,
                errorText: _notesError,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(strings.t('cancel')),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: authPrimary),
          onPressed: _save,
          child: Text(strings.t('save')),
        ),
      ],
    );
  }
}

class MedicalProfileStrings {
  final String language;

  MedicalProfileStrings(this.language);

  static const Map<String, String> _en = {
    'title': 'Medical Profile',
    'subtitle': 'Store optional health and emergency information in one place.',
    'completion': 'Medical Profile complete',
    'edit': 'Edit',
    'save': 'Save',
    'saving': 'Saving...',
    'cancel': 'Cancel',
    'retry': 'Retry',
    'discard': 'Discard',
    'keepEditing': 'Keep editing',
    'discardTitle': 'Discard unsaved changes?',
    'discardMessage': 'Your Medical Profile changes have not been saved.',
    'savedMessage': 'Medical Profile saved.',
    'saveError': 'Could not save Medical Profile. Please try again.',
    'loadError': 'Could not load your Medical Profile. Please try again.',
    'basicInfo': 'Basic Health Information',
    'fullName': 'Full name',
    'name': 'Name',
    'dateOfBirth': 'Date of birth',
    'age': 'Age',
    'years': 'years',
    'notAdded': 'Not added',
    'notCalculated': 'Not calculated',
    'bloodType': 'Blood type',
    'sex': 'Sex',
    'height': 'Height',
    'weight': 'Weight',
    'heightCm': 'Height (cm)',
    'weightKg': 'Weight (kg)',
    'allergies': 'Allergies',
    'addAllergy': 'Add allergy',
    'editAllergy': 'Edit allergy',
    'allergyName': 'Allergy name',
    'severity': 'Severity',
    'emptyAllergies': 'No allergies have been added.',
    'noKnownAllergies': 'I have no known allergies',
    'noKnownAllergiesSelected': 'No known allergies has been selected.',
    'clearAllergiesTitle': 'Clear allergy records?',
    'clearAllergiesMessage': 'Selecting this will remove saved allergy records when you save.',
    'duplicateAllergy': 'This allergy is already listed.',
    'deleteAllergyTitle': 'Delete allergy?',
    'conditions': 'Medical Conditions',
    'addCondition': 'Add condition',
    'editCondition': 'Edit condition',
    'conditionName': 'Condition name',
    'diagnosisDate': 'Diagnosis date',
    'status': 'Status',
    'emptyConditions': 'No medical conditions added.',
    'noKnownConditions': 'No known medical conditions',
    'noKnownConditionsSelected': 'No known medical conditions has been selected.',
    'clearConditionsTitle': 'Clear condition records?',
    'clearConditionsMessage': 'Selecting this will remove saved condition records when you save.',
    'duplicateCondition': 'This condition is already listed.',
    'deleteConditionTitle': 'Delete condition?',
    'emergencyContacts': 'Emergency Contacts',
    'addContact': 'Add emergency contact',
    'editContact': 'Edit emergency contact',
    'emptyContacts': 'No emergency contacts added.',
    'relationship': 'Relationship',
    'phone': 'Phone number',
    'secondaryPhone': 'Secondary phone number',
    'primary': 'Primary',
    'primaryContact': 'Primary emergency contact',
    'deleteContactTitle': 'Delete emergency contact?',
    'providers': 'Healthcare Providers',
    'doctorInfo': 'Doctor information',
    'doctorName': 'Doctor name',
    'specialty': 'Specialty',
    'clinic': 'Clinic or hospital',
    'pharmacyInfo': 'Pharmacy information',
    'pharmacyName': 'Pharmacy name',
    'email': 'Email',
    'address': 'Address',
    'notes': 'Notes',
    'emptyDoctor': 'No doctor information added.',
    'emptyPharmacy': 'No pharmacy information added.',
    'removeDoctor': 'Remove doctor information',
    'removePharmacy': 'Remove pharmacy information',
    'call': 'Call',
    'openUnsupported': 'This action is not supported on this device.',
    'delete': 'Delete',
    'clear': 'Clear',
    'deleteItemMessage': 'This item will be removed after you save changes.',
    'deleteProfile': 'Delete Medical Profile',
    'deleting': 'Deleting...',
    'deleteProfileTitle': 'Delete Medical Profile?',
    'deleteProfileMessage': 'This will permanently remove your saved health information, allergies, medical conditions, emergency contacts, doctor information, and pharmacy information. Your account and medicine reminders will not be deleted.',
    'deletedMessage': 'Medical Profile deleted.',
    'deleteError': 'Could not delete Medical Profile. Please try again.',
    'privacyText': 'Medical information is optional. It is stored under your account and can be deleted without deleting medicines, reminders, or your Firebase account.',
    'profileNotCompleted': 'Your Medical Profile has not been completed yet.',
    'completeProfile': 'Complete profile',
    'profileTileSubtitle': 'Manage your health and emergency information',
    'Prefer not to say': 'Prefer not to say',
    'Male': 'Male',
    'Female': 'Female',
    'Other': 'Other',
    'Mild': 'Mild',
    'Moderate': 'Moderate',
    'Severe': 'Severe',
    'Unknown': 'Unknown',
    'Active': 'Active',
    'Managed': 'Managed',
    'Resolved': 'Resolved',
  };

  static const Map<String, String> _ku = {
    'title': 'پرۆفایلی پزیشکی',
    'subtitle': 'زانیاری تەندروستی و فریاکەوتن بە شێوەی ئارەزوومەندانە لێرە هەڵبگرە.',
    'completion': 'تەواوبوونی پرۆفایلی پزیشکی',
    'edit': 'دەستکاری',
    'save': 'پاشەکەوت',
    'saving': 'پاشەکەوت دەکرێت...',
    'cancel': 'هەڵوەشاندنەوە',
    'delete': 'سڕینەوە',
    'basicInfo': 'زانیاری تەندروستی بنەڕەتی',
    'allergies': 'هەستیارییەکان',
    'conditions': 'بارودۆخە پزیشکییەکان',
    'emergencyContacts': 'پەیوەندییەکانی فریاکەوتن',
    'providers': 'دابینکەرانی چاودێری تەندروستی',
    'fullName': 'ناوی تەواو',
    'dateOfBirth': 'رۆژی لەدایکبوون',
    'age': 'تەمەن',
    'bloodType': 'جۆری خوێن',
    'sex': 'رەگەز',
    'height': 'بەرزی',
    'weight': 'کێش',
    'notAdded': 'زیاد نەکراوە',
    'savedMessage': 'پرۆفایلی پزیشکی پاشەکەوت کرا.',
  };

  static const Map<String, String> _ar = {
    'title': 'الملف الطبي',
    'subtitle': 'احفظ معلومات الصحة والطوارئ الاختيارية في مكان واحد.',
    'completion': 'اكتمال الملف الطبي',
    'edit': 'تعديل',
    'save': 'حفظ',
    'saving': 'جار الحفظ...',
    'cancel': 'إلغاء',
    'delete': 'حذف',
    'basicInfo': 'المعلومات الصحية الأساسية',
    'allergies': 'الحساسية',
    'conditions': 'الحالات الطبية',
    'emergencyContacts': 'جهات اتصال الطوارئ',
    'providers': 'مقدمو الرعاية الصحية',
    'fullName': 'الاسم الكامل',
    'dateOfBirth': 'تاريخ الميلاد',
    'age': 'العمر',
    'bloodType': 'فصيلة الدم',
    'sex': 'الجنس',
    'height': 'الطول',
    'weight': 'الوزن',
    'notAdded': 'غير مضاف',
    'savedMessage': 'تم حفظ الملف الطبي.',
  };

  String t(String key) {
    final selected = language == 'Arabic'
        ? _ar
        : language == 'Kurdish'
            ? _ku
            : _en;
    return selected[key] ?? _en[key] ?? key;
  }

  String option(String value) {
    return t(value) == value ? value : t(value);
  }
}
