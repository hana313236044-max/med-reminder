// Profile tab UI for the home screen.
part of 'home_screen.dart';

class _ProfileTab extends StatelessWidget {
  final String userName;
  final String email;
  final String age;
  final String bloodType;

  const _ProfileTab({
    required this.userName,
    required this.email,
    required this.age,
    required this.bloodType,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 96),
      children: [
        Text(
          'Profile',
          style: TextStyle(
            color: appTextColor(context),
            fontSize: 28,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: appSurfaceColor(context),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: appBorderColor(context)),
            boxShadow: [
              BoxShadow(
                color: appShadowColor(context),
                blurRadius: 18,
                offset: const Offset(0, 9),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const CircleAvatar(
                    radius: 30,
                    backgroundColor: Color(0xFFEAF8F6),
                    child: Icon(Icons.person, color: authPrimary, size: 30),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userName,
                        style: TextStyle(
                            color: appTextColor(context),
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          'MediTrack user',
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
              const SizedBox(height: 20),
              LayoutBuilder(
                builder: (context, constraints) {
                  final useTwoColumns = constraints.maxWidth >= 520;
                  final items = [
                    _ProfileInfoData(
                      icon: Icons.badge_outlined,
                      label: 'Name',
                      value: userName,
                    ),
                    _ProfileInfoData(
                      icon: Icons.email_outlined,
                      label: 'Email',
                      value: email,
                    ),
                    _ProfileInfoData(
                      icon: Icons.cake_outlined,
                      label: 'Age',
                      value: age,
                    ),
                    _ProfileInfoData(
                      icon: Icons.bloodtype_outlined,
                      label: 'Blood type',
                      value: bloodType,
                    ),
                  ];

                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: items.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: useTwoColumns ? 2 : 1,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      mainAxisExtent: 86,
                    ),
                    itemBuilder: (context, index) {
                      return _ProfileInfoTile(data: items[index]);
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProfileInfoData {
  final IconData icon;
  final String label;
  final String value;

  const _ProfileInfoData({
    required this.icon,
    required this.label,
    required this.value,
  });
}

class _ProfileInfoTile extends StatelessWidget {
  final _ProfileInfoData data;

  const _ProfileInfoTile({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: appSoftSurfaceColor(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: appBorderColor(context)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: appTintSurfaceColor(context),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(data.icon, color: authPrimary, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  data.label,
                  style: TextStyle(
                    color: appMutedTextColor(context),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  data.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: appTextColor(context),
                    fontSize: 15,
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

class _EmptyMedicineInline extends StatelessWidget {
  const _EmptyMedicineInline();

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
        ],
      ),
    );
  }
}

class _MedicineInlineCard extends StatelessWidget {
  final Medicine medicine;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _MedicineInlineCard({
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
                    _Tag(label: medicine.category),
                    _Tag(label: medicine.form),
                    _Tag(label: medicine.ageGroup),
                  ],
                ),
                if (medicine.notes != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    medicine.notes!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: appMutedTextColor(context),
                      fontWeight: FontWeight.w600,
                    ),
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
