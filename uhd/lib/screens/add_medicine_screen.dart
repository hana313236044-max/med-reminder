// This screen adds or updates a saved medicine.
import 'package:flutter/material.dart';
import 'package:uhd/widgets/app_widgets.dart';
import 'package:uhd/models/medicine_models.dart';

class AddMedicinePage extends StatefulWidget {
  final Medicine? medicine;
  final Future<void> Function(Medicine) onSaveMedicine;

  const AddMedicinePage({
    super.key,
    this.medicine,
    required this.onSaveMedicine,
  });

  @override
  State<AddMedicinePage> createState() => _AddMedicinePageState();
}

class _AddMedicinePageState extends State<AddMedicinePage> {
  final _nameController = TextEditingController();
  final _notesController = TextEditingController();

  final List<String> _categories = const [
    'Supplements',
    'Respiratory',
    'Antibiotics',
    'Pain Relief',
    'Cardiovascular',
    'Diabetes',
    'Digestive',
    'Mental Health',
    'Skin Care',
    'Hormonal',
  ];

  final List<String> _forms = const [
    'Pills',
    'Syrup',
    'Eye drops',
    'Nose drops',
    'Injection',
    'Inhaler',
    'Cream',
    'Gel',
    'Powder',
    'Spray',
  ];

  final List<String> _ageGroups = const [
    'Adults',
    'Kids',
    'Infants',
    'Teens',
    'Seniors',
    'All ages',
  ];

  String? _category;
  String? _form;
  String? _ageGroup;
  String? _nameError;
  String? _categoryError;
  String? _formError;
  String? _ageError;
  bool _isSaving = false;

  bool get _isEditing => widget.medicine != null;

  @override
  void initState() {
    super.initState();
    final medicine = widget.medicine;
    if (medicine != null) {
      _nameController.text = medicine.name;
      _notesController.text = medicine.notes ?? '';
      _category = medicine.category;
      _form = medicine.form;
      _ageGroup = medicine.ageGroup;
    }
  }

  Future<void> _save() async {
    if (_isSaving) return;

    final name = _nameController.text.trim();
    setState(() {
      _nameError = name.length <= 3 ? 'Name must be more than 3 letters' : null;
      _categoryError = _category == null ? 'Select what it is for' : null;
      _formError = _form == null ? 'Select medicine type' : null;
      _ageError = _ageGroup == null ? 'Select suitable age group' : null;
    });

    if (_nameError != null ||
        _categoryError != null ||
        _formError != null ||
        _ageError != null) {
      return;
    }

    final medicine = Medicine(
      id: widget.medicine?.id ?? DateTime.now().microsecondsSinceEpoch,
      name: name,
      category: _category!,
      form: _form!,
      ageGroup: _ageGroup!,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    );

    setState(() => _isSaving = true);
    try {
      await widget.onSaveMedicine(medicine);
      if (!mounted) return;
      Navigator.pop(context);
    } catch (_) {
      if (!mounted) return;
      showAuthMessage(
        context,
        'Could not save medicine. Please try again.',
        backgroundColor: Colors.redAccent,
      );
      setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appScaffoldColor(context),
      appBar: AppBar(
        backgroundColor: authPrimary,
        foregroundColor: authInk,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        title: Text(
          _isEditing ? 'Update Medicine' : 'Add Medicine',
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
          children: [
            Text(
              _isEditing ? 'Update medicine' : 'Add medicine',
              style: TextStyle(
                color: appTextColor(context),
                fontSize: 28,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Save medicine details once, then reuse them in reminders.',
              style: TextStyle(
                color: appMutedTextColor(context),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 20),
            AuthTextField(
              controller: _nameController,
              hintText: 'Medicine name',
              icon: Icons.medication_outlined,
              errorText: _nameError,
              onChanged: (value) {
                if (_nameError != null) {
                  setState(() {
                    _nameError = value.trim().length <= 3
                        ? 'Name must be more than 3 letters'
                        : null;
                  });
                }
              },
            ),
            const SizedBox(height: 14),
            _AuthDropdown(
              value: _category,
              hintText: 'What is it for?',
              icon: Icons.local_hospital_outlined,
              items: _categories,
              errorText: _categoryError,
              onChanged: (value) {
                setState(() {
                  _category = value;
                  _categoryError = null;
                });
              },
            ),
            const SizedBox(height: 14),
            _AuthDropdown(
              value: _form,
              hintText: 'What is it?',
              icon: Icons.category_outlined,
              items: _forms,
              errorText: _formError,
              onChanged: (value) {
                setState(() {
                  _form = value;
                  _formError = null;
                });
              },
            ),
            const SizedBox(height: 14),
            _AuthDropdown(
              value: _ageGroup,
              hintText: 'Suitable age',
              icon: Icons.groups_outlined,
              items: _ageGroups,
              errorText: _ageError,
              onChanged: (value) {
                setState(() {
                  _ageGroup = value;
                  _ageError = null;
                });
              },
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: authInputDecoration(
                context: context,
                hintText: 'Notes optional',
                icon: Icons.notes_outlined,
              ),
            ),
            const SizedBox(height: 22),
            AuthPrimaryButton(
              label: _isSaving
                  ? 'Saving...'
                  : _isEditing
                  ? 'Update Medicine'
                  : 'Add Medicine',
              icon: _isEditing ? Icons.save_outlined : Icons.add,
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }
}

class _AuthDropdown extends StatelessWidget {
  final String? value;
  final String hintText;
  final IconData icon;
  final List<String> items;
  final String? errorText;
  final ValueChanged<String?> onChanged;

  const _AuthDropdown({
    required this.value,
    required this.hintText,
    required this.icon,
    required this.items,
    required this.onChanged,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: authInputDecoration(
        context: context,
        hintText: hintText,
        icon: icon,
        errorText: errorText,
      ),
      items: items
          .map((item) => DropdownMenuItem(value: item, child: Text(item)))
          .toList(),
      onChanged: onChanged,
    );
  }
}
