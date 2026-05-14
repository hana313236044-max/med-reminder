import 'package:flutter/material.dart';
import 'package:uhd/AddMedicinePage.dart';
import 'package:uhd/auth_widgets.dart';
import 'package:uhd/med_models.dart';

class MyMedicinesPage extends StatefulWidget {
  final List<Medicine> medicines;
  final ValueChanged<Medicine> onSaveMedicine;
  final ValueChanged<int> onDeleteMedicine;

  const MyMedicinesPage({
    super.key,
    required this.medicines,
    required this.onSaveMedicine,
    required this.onDeleteMedicine,
  });

  @override
  State<MyMedicinesPage> createState() => _MyMedicinesPageState();
}

class _MyMedicinesPageState extends State<MyMedicinesPage> {
  void _saveMedicine(Medicine medicine) {
    widget.onSaveMedicine(medicine);
    setState(() {});
  }

  void _deleteMedicine(int id) {
    widget.onDeleteMedicine(id);
    setState(() {});
  }

  void _openAddMedicine() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddMedicinePage(onSaveMedicine: _saveMedicine),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: authPrimary,
        foregroundColor: authInk,
        elevation: 0,
        title: const Text(
          'My Medicines',
          style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
          children: [
            const Text(
              'My medicines',
              style: TextStyle(
                color: authInk,
                fontSize: 28,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Saved medicine storage for future reminders.',
              style: TextStyle(
                color: Colors.blueGrey.shade600,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: authPrimary,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: _openAddMedicine,
              icon: const Icon(Icons.add),
              label: const Text(
                'Add Medicine',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(height: 22),
            if (widget.medicines.isEmpty)
              const _EmptyMedicines()
            else
              LayoutBuilder(
                builder: (context, constraints) {
                  final crossAxisCount = constraints.maxWidth >= 560 ? 2 : 1;
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: widget.medicines.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      mainAxisExtent: 190,
                    ),
                    itemBuilder: (context, index) {
                      final medicine = widget.medicines[index];
                      return _MedicineCard(
                        medicine: medicine,
                        onEdit: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AddMedicinePage(
                                medicine: medicine,
                                onSaveMedicine: _saveMedicine,
                              ),
                            ),
                          );
                        },
                        onDelete: () => _deleteMedicine(medicine.id),
                      );
                    },
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _EmptyMedicines extends StatelessWidget {
  const _EmptyMedicines();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF8F6),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.teal.shade100),
      ),
      child: Column(
        children: [
          Icon(
            Icons.medication_outlined,
            size: 42,
            color: Colors.teal.shade700,
          ),
          const SizedBox(height: 10),
          const Text(
            'No medicines saved yet',
            style: TextStyle(
              color: authInk,
              fontWeight: FontWeight.w800,
              fontSize: 17,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Add medicines here before creating reminders.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.blueGrey.shade500),
          ),
        ],
      ),
    );
  }
}

class _MedicineCard extends StatelessWidget {
  final Medicine medicine;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _MedicineCard({
    required this.medicine,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.teal.shade50),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF8F6),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.medication_outlined, color: authPrimary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  medicine.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: authInk,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _Chip(label: medicine.category),
                    _Chip(label: medicine.form),
                    _Chip(label: medicine.ageGroup),
                  ],
                ),
                if (medicine.notes != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    medicine.notes!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.blueGrey.shade500),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            tooltip: 'Edit',
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined, color: authPrimary),
          ),
          IconButton(
            tooltip: 'Delete',
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;

  const _Chip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF8F6),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: authPrimary,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}
