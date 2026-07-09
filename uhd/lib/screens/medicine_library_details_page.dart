import 'package:flutter/material.dart';
import 'package:uhd/l10n/medicine_library_localizations.dart';
import 'package:uhd/models/medicine_library_model.dart';
import 'package:uhd/models/medicine_models.dart';
import 'package:uhd/screens/add_medicine_screen.dart';
import 'package:uhd/services/medicine_library_repository.dart';
import 'package:uhd/widgets/app_widgets.dart';
import 'package:uhd/widgets/available_pharmacies_section.dart';

class MedicineLibraryDetailsRouteArguments {
  final Future<void> Function(Medicine) onSaveMedicine;

  const MedicineLibraryDetailsRouteArguments({
    required this.onSaveMedicine,
  });
}

class MedicineLibraryDetailsPage extends StatelessWidget {
  final String medicineId;
  final Future<void> Function(Medicine)? onSaveMedicine;

  const MedicineLibraryDetailsPage({
    super.key,
    required this.medicineId,
    this.onSaveMedicine,
  });

  @override
  Widget build(BuildContext context) {
    final strings = MedicineLibraryStrings.of(context);
    return Scaffold(
      backgroundColor: appScaffoldColor(context),
      appBar: AppBar(
        backgroundColor: authPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          strings.t(MedicineLibraryTextKey.title),
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: SafeArea(
        child: FutureBuilder<List<MedicineLibraryMedicine>>(
          future: MedicineLibraryRepository.instance.loadMedicines(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: authPrimary),
              );
            }
            final medicines = snapshot.data ?? const [];
            final medicine = MedicineLibraryRepository.instance.findById(
              medicines,
              medicineId,
            );
            if (medicine == null) {
              return _NotFoundState(onBack: () => _backToLibrary(context));
            }
            return _DetailsContent(
              medicine: medicine,
              onBack: () => _backToLibrary(context),
              onAdd: () => _openAddToMyMedicines(context, medicine),
            );
          },
        ),
      ),
    );
  }

  void _backToLibrary(BuildContext context) {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
      return;
    }
    Navigator.pushReplacementNamed(context, '/medicine-library');
  }

  void _openAddToMyMedicines(
    BuildContext context,
    MedicineLibraryMedicine medicine,
  ) {
    final saveMedicine = onSaveMedicine;
    if (saveMedicine == null) {
      showAuthMessage(
        context,
        MedicineLibraryStrings.of(context).t(MedicineLibraryTextKey.addUnavailable),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddMedicinePage(
          onSaveMedicine: saveMedicine,
          initialName: medicine.name,
          initialCategory: _personalCategoryFor(medicine.category),
          initialForm: _personalFormFor(medicine.primaryForm),
          initialAgeGroup: _personalAgeGroupFor(medicine.ageGroup),
          initialNotes:
              'From Medicine Library: ${medicine.category}. ${medicine.description}\n\nEducational information only. Follow a doctor or pharmacist\'s instructions.',
        ),
      ),
    );
  }

  String _personalCategoryFor(String category) {
    switch (category) {
      case 'Blood Pressure':
      case 'Heart':
        return 'Cardiovascular';
      case 'Cold and Flu':
      case 'Allergy':
      case 'Asthma':
        return 'Respiratory';
      case 'Stomach':
        return 'Digestive';
      case 'Vitamins and Supplements':
        return 'Supplements';
      case 'Skin':
        return 'Skin Care';
      default:
        return category;
    }
  }

  String _personalFormFor(String form) {
    switch (form) {
      case 'Nasal Spray':
        return 'Spray';
      case 'Nebulizer Solution':
      case 'Solution':
      case 'Wash':
      case 'Granules':
        return 'Liquid';
      case 'Lozenge':
        return 'Pills';
      case 'Rectal Gel':
        return 'Gel';
      case 'Tablet':
      case 'Capsule':
      case 'Chewable Tablet':
        return form;
      case 'Drops':
      case 'Eye Drops':
      case 'Ear Drops':
        return form;
      default:
        return form;
    }
  }

  String _personalAgeGroupFor(List<String> ageGroups) {
    if (ageGroups.contains('Adult')) return 'Adults';
    if (ageGroups.contains('Child')) return 'Kids';
    if (ageGroups.contains('Infant')) return 'Infants';
    if (ageGroups.contains('Elderly')) return 'Seniors';
    return 'All ages';
  }
}

class _DetailsContent extends StatelessWidget {
  final MedicineLibraryMedicine medicine;
  final VoidCallback onBack;
  final VoidCallback onAdd;

  const _DetailsContent({
    required this.medicine,
    required this.onBack,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final strings = MedicineLibraryStrings.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final twoColumns = constraints.maxWidth >= 920;
        return ListView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 32),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _DetailsHeader(medicine: medicine),
                    const SizedBox(height: 14),
                    _Disclaimer(text: strings.t(MedicineLibraryTextKey.disclaimerFull)),
                    const SizedBox(height: 14),
                    if (twoColumns)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _OverviewSection(medicine: medicine)),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              children: [
                                _UsageSection(medicine: medicine),
                                const SizedBox(height: 14),
                                _ActionsSection(onAdd: onAdd, onBack: onBack),
                              ],
                            ),
                          ),
                        ],
                      )
                    else ...[
                      _OverviewSection(medicine: medicine),
                      const SizedBox(height: 14),
                      _UsageSection(medicine: medicine),
                      const SizedBox(height: 14),
                      _ActionsSection(onAdd: onAdd, onBack: onBack),
                    ],
                    const SizedBox(height: 14),
                    AvailablePharmaciesSection(medicineId: medicine.id),
                    const SizedBox(height: 14),
                    if (twoColumns)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _SideEffectsSection(medicine: medicine)),
                          const SizedBox(width: 14),
                          Expanded(child: _SafetySection(medicine: medicine)),
                        ],
                      )
                    else ...[
                      _SideEffectsSection(medicine: medicine),
                      const SizedBox(height: 14),
                      _SafetySection(medicine: medicine),
                    ],
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _DetailsHeader extends StatelessWidget {
  final MedicineLibraryMedicine medicine;

  const _DetailsHeader({required this.medicine});

  @override
  Widget build(BuildContext context) {
    final strings = MedicineLibraryStrings.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: appSurfaceColor(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: appBorderColor(context)),
        boxShadow: [
          BoxShadow(
            color: appShadowColor(context, 0.06),
            blurRadius: 18,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: appTintSurfaceColor(context),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.local_library_outlined,
                    color: authPrimary, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      medicine.name,
                      style: TextStyle(
                        color: appTextColor(context),
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${strings.t(MedicineLibraryTextKey.generic)}: ${medicine.genericName}',
                      style: TextStyle(
                        color: appMutedTextColor(context),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            '${medicine.category} - ${medicine.medicineClass}',
            style: TextStyle(
              color: appTextColor(context),
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InfoChip(
                icon: medicine.prescriptionRequired
                    ? Icons.assignment_outlined
                    : Icons.check_circle_outline,
                label: medicine.prescriptionRequired
                    ? strings.t(MedicineLibraryTextKey.prescriptionBadge)
                    : strings.t(MedicineLibraryTextKey.noPrescriptionBadge),
              ),
              _InfoChip(
                icon: Icons.warning_amber_outlined,
                label: strings.warningLevelLabel(medicine.warningLevel),
              ),
              _InfoChip(
                icon: Icons.business_outlined,
                label:
                    '${strings.t(MedicineLibraryTextKey.brandExamples)}: ${medicine.brandSummary}',
              ),
            ],
          ),
          const SizedBox(height: 12),
          _ChipWrap(
            icon: Icons.medication_liquid_outlined,
            label: strings.t(MedicineLibraryTextKey.forms),
            values: medicine.forms,
          ),
          const SizedBox(height: 10),
          _ChipWrap(
            icon: Icons.sell_outlined,
            label: strings.t(MedicineLibraryTextKey.tags),
            values: medicine.tags,
          ),
        ],
      ),
    );
  }
}

class _OverviewSection extends StatelessWidget {
  final MedicineLibraryMedicine medicine;

  const _OverviewSection({required this.medicine});

  @override
  Widget build(BuildContext context) {
    final strings = MedicineLibraryStrings.of(context);
    return _InfoSection(
      icon: Icons.article_outlined,
      title: strings.t(MedicineLibraryTextKey.overview),
      children: [
        _TextBlock(
          title: strings.t(MedicineLibraryTextKey.description),
          text: medicine.description,
        ),
        _ListBlock(
          title: strings.t(MedicineLibraryTextKey.commonUses),
          values: medicine.commonUses,
        ),
        _TextBlock(
          title: strings.t(MedicineLibraryTextKey.howTaken),
          text: medicine.howItIsUsuallyTaken,
        ),
        _TextBlock(
          title: strings.t(MedicineLibraryTextKey.foodInstructions),
          text: medicine.foodInstructions,
        ),
      ],
    );
  }
}

class _UsageSection extends StatelessWidget {
  final MedicineLibraryMedicine medicine;

  const _UsageSection({required this.medicine});

  @override
  Widget build(BuildContext context) {
    final strings = MedicineLibraryStrings.of(context);
    return _InfoSection(
      icon: Icons.medication_outlined,
      title: strings.t(MedicineLibraryTextKey.formsAndUsage),
      children: [
        _ListBlock(
          title: strings.t(MedicineLibraryTextKey.availableForms),
          values: medicine.forms,
        ),
        _TextBlock(
          title: strings.t(MedicineLibraryTextKey.generalUsageNotes),
          text: medicine.howItIsUsuallyTaken,
        ),
        _TextBlock(
          title: strings.t(MedicineLibraryTextKey.missedDose),
          text: medicine.missedDoseInfo,
        ),
      ],
    );
  }
}

class _SideEffectsSection extends StatelessWidget {
  final MedicineLibraryMedicine medicine;

  const _SideEffectsSection({required this.medicine});

  @override
  Widget build(BuildContext context) {
    final strings = MedicineLibraryStrings.of(context);
    return _InfoSection(
      icon: Icons.health_and_safety_outlined,
      title: strings.t(MedicineLibraryTextKey.sideEffects),
      children: [
        _ListBlock(
          title: strings.t(MedicineLibraryTextKey.commonSideEffects),
          values: medicine.commonSideEffects,
        ),
        _ListBlock(
          title: strings.t(MedicineLibraryTextKey.seriousWarnings),
          values: medicine.seriousWarnings,
          danger: true,
        ),
      ],
    );
  }
}

class _SafetySection extends StatelessWidget {
  final MedicineLibraryMedicine medicine;

  const _SafetySection({required this.medicine});

  @override
  Widget build(BuildContext context) {
    final strings = MedicineLibraryStrings.of(context);
    return _InfoSection(
      icon: Icons.verified_user_outlined,
      title: strings.t(MedicineLibraryTextKey.safetyInformation),
      children: [
        _ListBlock(
          title: strings.t(MedicineLibraryTextKey.whoCareful),
          values: medicine.whoShouldBeCareful,
        ),
        _ListBlock(
          title: strings.t(MedicineLibraryTextKey.interactions),
          values: medicine.possibleInteractions,
        ),
        _TextBlock(
          title: strings.t(MedicineLibraryTextKey.pregnancyBreastfeeding),
          text: medicine.pregnancyBreastfeedingNote,
        ),
        _TextBlock(
          title: strings.t(MedicineLibraryTextKey.storage),
          text: medicine.storage,
        ),
      ],
    );
  }
}

class _ActionsSection extends StatelessWidget {
  final VoidCallback onAdd;
  final VoidCallback onBack;

  const _ActionsSection({
    required this.onAdd,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final strings = MedicineLibraryStrings.of(context);
    return _InfoSection(
      icon: Icons.touch_app_outlined,
      title: strings.t(MedicineLibraryTextKey.libraryActions),
      children: [
        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: authPrimary,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          onPressed: onAdd,
          icon: const Icon(Icons.add),
          label: Text(
            strings.t(MedicineLibraryTextKey.addToMyMedicines),
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: authPrimary,
            minimumSize: const Size.fromHeight(50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back),
          label: Text(
            strings.t(MedicineLibraryTextKey.backToLibrary),
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
      ],
    );
  }
}

class _InfoSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<Widget> children;

  const _InfoSection({
    required this.icon,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: appSurfaceColor(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: appBorderColor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: authPrimary),
              const SizedBox(width: 8),
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
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}

class _TextBlock extends StatelessWidget {
  final String title;
  final String text;

  const _TextBlock({
    required this.title,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
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
          const SizedBox(height: 6),
          Text(
            text,
            style: TextStyle(
              color: appMutedTextColor(context),
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ListBlock extends StatelessWidget {
  final String title;
  final List<String> values;
  final bool danger;

  const _ListBlock({
    required this.title,
    required this.values,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final items = values.isEmpty
        ? [MedicineLibraryStrings.of(context).t(MedicineLibraryTextKey.notProvided)]
        : values;
    final color = danger ? Colors.redAccent : authPrimary;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
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
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: items.map((item) {
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: color.withOpacity(appIsDark(context) ? 0.16 : 0.09),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withOpacity(0.22)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      danger
                          ? Icons.warning_amber_outlined
                          : Icons.check_circle_outline,
                      color: color,
                      size: 15,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        item,
                        style: TextStyle(
                          color: danger ? color : appTextColor(context),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: appTintSurfaceColor(context),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: authPrimary, size: 15),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: authPrimary,
                fontWeight: FontWeight.w900,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChipWrap extends StatelessWidget {
  final IconData icon;
  final String label;
  final List<String> values;

  const _ChipWrap({
    required this.icon,
    required this.label,
    required this.values,
  });

  @override
  Widget build(BuildContext context) {
    final strings = MedicineLibraryStrings.of(context);
    final items = values.isEmpty ? [strings.t(MedicineLibraryTextKey.notProvided)] : values;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: authPrimary, size: 18),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: appTextColor(context),
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: items.map((item) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: appTintSurfaceColor(context),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                item,
                style: const TextStyle(
                  color: authPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _Disclaimer extends StatelessWidget {
  final String text;

  const _Disclaimer({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: appTintSurfaceColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: appBorderColor(context)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: authPrimary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: appTextColor(context),
                height: 1.35,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotFoundState extends StatelessWidget {
  final VoidCallback onBack;

  const _NotFoundState({required this.onBack});

  @override
  Widget build(BuildContext context) {
    final strings = MedicineLibraryStrings.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 480),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: appTintSurfaceColor(context),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: appBorderColor(context)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.search_off_outlined,
                  color: authPrimary, size: 44),
              const SizedBox(height: 10),
              Text(
                strings.t(MedicineLibraryTextKey.medicineNotFound),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: appTextColor(context),
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: authPrimary),
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back),
                label: Text(strings.t(MedicineLibraryTextKey.backToLibrary)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
