// Medicine tab UI for the home screen.
part of 'home_screen.dart';

class _MedicineTab extends StatelessWidget {
  final List<Medicine> medicines;
  final VoidCallback onAddMedicine;
  final ValueChanged<Medicine> onEditMedicine;
  final ValueChanged<int> onDeleteMedicine;

  const _MedicineTab({
    required this.medicines,
    required this.onAddMedicine,
    required this.onEditMedicine,
    required this.onDeleteMedicine,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 96),
      children: [
        Text(
          'Medicine',
          style: TextStyle(
            color: appTextColor(context),
            fontSize: 28,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Saved medicines for reminders and tracking.',
          style: TextStyle(
            color: appMutedTextColor(context),
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 16),
        if (medicines.isEmpty)
          const _EmptyMedicineInline()
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = constraints.maxWidth >= 560 ? 2 : 1;
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: medicines.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  mainAxisExtent: 220,
                ),
                itemBuilder: (context, index) {
                  final medicine = medicines[index];
                  return _MedicineInlineCard(
                    medicine: medicine,
                    onEdit: () => onEditMedicine(medicine),
                    onDelete: () => onDeleteMedicine(medicine.id),
                  );
                },
              );
            },
          ),
      ],
    );
  }
}
