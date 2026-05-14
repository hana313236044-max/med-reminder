import 'package:flutter/material.dart';

class Medicine {
  final int id;
  String name;
  String department;
  String? description;

  Medicine({
    required this.id,
    required this.name,
    required this.department,
    this.description,
  });
}

class AddMedicinePage extends StatefulWidget {
  final Function(String, String, String) onAddMedicine;

  const AddMedicinePage({super.key, required this.onAddMedicine});

  @override
  _AddMedicinePageState createState() => _AddMedicinePageState();
}

class _AddMedicinePageState extends State<AddMedicinePage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  String? _selectedDepartment;

  final List<String> _departments = [
    'Pain Relief',
    'Cardiovascular',
    'Antibiotics',
    'Diabetes',
    'Respiratory',
    'Mental Health',
    'Digestive',
    'Hormonal',
    'Skin Care',
    'Vitamins & Supplements',
    'Other'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Medicine'),
        backgroundColor: Colors.blueGrey,
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Medicine Name',
                hintText: 'e.g. Ibuprofen',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _selectedDepartment,
              decoration: InputDecoration(
                labelText: 'Department',
                border: OutlineInputBorder(),
              ),
              items: _departments.map((department) {
                return DropdownMenuItem<String>(
                  value: department,
                  child: Text(department),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedDepartment = value;
                });
              },
            ),
            SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Description (Optional)',
                hintText: 'Brief description of the medicine and its uses',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                final name = _nameController.text.trim();
                final department = _selectedDepartment;
                final description = _descriptionController.text.trim();
                if (name.isNotEmpty && department != null) {
                  widget.onAddMedicine(name, department, description);
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Please enter medicine name and select department')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 50),
              ),
              child: Text('Add Medicine'),
            ),
          ],
        ),
      ),
    );
  }
}