import 'package:flutter/material.dart';
import 'Home.dart'; // to access MedicationReminder

class AddReminderPage extends StatefulWidget {
  final List<Medicine> medicines;
  final Function(String, String, String, String) onAddReminder;

  const AddReminderPage({super.key, required this.medicines, required this.onAddReminder});

  @override
  _AddReminderPageState createState() => _AddReminderPageState();
}

class _AddReminderPageState extends State<AddReminderPage> {
  String? _selectedMedicine;
  TimeOfDay? _selectedTime;
  final TextEditingController _notesController = TextEditingController();
  String? _selectedCondition;

  final List<String> _conditions = [
    'Pain Relief',
    'Headache',
    'Fever',
    'Infection',
    'Blood Pressure',
    'Diabetes',
    'Allergy',
    'Digestive Issues',
    'Mental Health',
    'Other'
  ];

  List<Medicine> _getSuggestedMedicines() {
    if (_selectedCondition == null) return widget.medicines;

    switch (_selectedCondition) {
      case 'Pain Relief':
      case 'Headache':
        return widget.medicines.where((med) => med.department == 'Pain Relief').toList();
      case 'Fever':
        return widget.medicines.where((med) =>
            med.department == 'Pain Relief' || med.department == 'Antibiotics').toList();
      case 'Infection':
        return widget.medicines.where((med) => med.department == 'Antibiotics').toList();
      case 'Blood Pressure':
        return widget.medicines.where((med) => med.department == 'Cardiovascular').toList();
      case 'Diabetes':
        return widget.medicines.where((med) => med.department == 'Diabetes').toList();
      case 'Allergy':
        return widget.medicines.where((med) =>
            med.department == 'Respiratory' || med.department == 'Skin Care').toList();
      case 'Digestive Issues':
        return widget.medicines.where((med) => med.department == 'Digestive').toList();
      case 'Mental Health':
        return widget.medicines.where((med) => med.department == 'Mental Health').toList();
      default:
        return widget.medicines;
    }
  }

  Color _getDepartmentColor(String department) {
    switch (department) {
      case 'Pain Relief':
        return Colors.red[400]!;
      case 'Cardiovascular':
        return Colors.blue[400]!;
      case 'Antibiotics':
        return Colors.green[400]!;
      case 'Diabetes':
        return Colors.orange[400]!;
      case 'Respiratory':
        return Colors.cyan[400]!;
      case 'Mental Health':
        return Colors.purple[400]!;
      case 'Digestive':
        return Colors.brown[400]!;
      case 'Hormonal':
        return Colors.pink[400]!;
      case 'Skin Care':
        return Colors.teal[400]!;
      case 'Vitamins & Supplements':
        return Colors.yellow[600]!;
      default:
        return Colors.grey[400]!;
    }
  }

  @override
  Widget build(BuildContext context) {
    final suggestedMedicines = _getSuggestedMedicines();

    return Scaffold(
      appBar: AppBar(
        title: Text('Add Reminder'),
        backgroundColor: Colors.blueGrey,
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              initialValue: _selectedCondition,
              decoration: InputDecoration(
                labelText: 'Condition/Purpose',
                hintText: 'Select the condition this medication addresses',
                border: OutlineInputBorder(),
              ),
              items: _conditions.map((condition) {
                return DropdownMenuItem<String>(
                  value: condition,
                  child: Text(condition),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCondition = value;
                  _selectedMedicine = null; // Reset medicine selection when condition changes
                });
              },
            ),
            SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _selectedMedicine,
              decoration: InputDecoration(
                labelText: 'Select Medicine',
                hintText: _selectedCondition != null
                    ? 'Medicines suggested for $_selectedCondition'
                    : 'Select a condition first for suggestions',
                border: OutlineInputBorder(),
              ),
              items: suggestedMedicines.map((medicine) {
                return DropdownMenuItem<String>(
                  value: medicine.name,
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _getDepartmentColor(medicine.department),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          medicine.department,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          medicine.name,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedMedicine = value;
                });
              },
            ),
            SizedBox(height: 16),
            InkWell(
              onTap: () async {
                final TimeOfDay? pickedTime = await showTimePicker(
                  context: context,
                  initialTime: _selectedTime ?? TimeOfDay.now(),
                );
                if (pickedTime != null) {
                  setState(() {
                    _selectedTime = pickedTime;
                  });
                }
              },
              child: Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    Icon(Icons.access_time, color: Colors.blueGrey),
                    SizedBox(width: 12),
                    Text(
                      _selectedTime != null
                          ? _selectedTime!.format(context)
                          : 'Select Time',
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _notesController,
              decoration: InputDecoration(
                labelText: 'Notes',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                final medicine = _selectedMedicine;
                final time = _selectedTime;
                final condition = _selectedCondition;
                final notes = _notesController.text.trim();
                if (medicine != null && time != null && condition != null) {
                  final timeStr = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
                  widget.onAddReminder(medicine, timeStr, notes, condition);
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Please select condition, medicine and time')),
                  );
                }
              },
              child: Text('Add Reminder'),
            ),
          ],
        ),
      ),
    );
  }
}