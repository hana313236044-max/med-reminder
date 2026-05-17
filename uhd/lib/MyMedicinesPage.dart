import 'package:flutter/material.dart';
import 'package:uhd/AddMedicinePage.dart';
import 'package:uhd/auth_widgets.dart';
import 'package:uhd/med_models.dart';

class MyMedicinesPage extends StatefulWidget {
  final List<Medicine> medicines;
  final Future<void> Function(Medicine) onSaveMedicine;
  final Future<void> Function(int) onDeleteMedicine;

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
  Future<void> _saveMedicine(Medicine medicine) async {
    await widget.onSaveMedicine(medicine);
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _deleteMedicine(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete medicine?'),
          content: const Text(
            'Do you want to delete this medicine? Related reminders may be removed too.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
    if (confirmed != true) return;

    await widget.onDeleteMedicine(id);
    if (!mounted) return;
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
      backgroundColor: appScaffoldColor(context),
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
            Text(
              'My medicines',
              style: TextStyle(
                color: appTextColor(context),
                fontSize: 28,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Saved medicine storage for future reminders.',
              style: TextStyle(
                color: appMutedTextColor(context),
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
                      mainAxisExtent: 220,
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
        color: appTintSurfaceColor(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: appBorderColor(context)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.medication_outlined,
            size: 42,
            color: Colors.teal.shade700,
          ),
          const SizedBox(height: 10),
          Text(
            'No medicines saved yet',
            style: TextStyle(
              color: appTextColor(context),
              fontWeight: FontWeight.w800,
              fontSize: 17,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Add medicines here before creating reminders.',
            textAlign: TextAlign.center,
            style: TextStyle(color: appMutedTextColor(context)),
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
        color: appSurfaceColor(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: appBorderColor(context)),
        boxShadow: [
          BoxShadow(
            color: appShadowColor(context, 0.05),
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
              color: appTintSurfaceColor(context),
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
                  style: TextStyle(
                    color: appTextColor(context),
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
                    style: TextStyle(color: appMutedTextColor(context)),
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
        color: appTintSurfaceColor(context),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: authPrimary,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}
