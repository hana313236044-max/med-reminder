import 'package:flutter/material.dart';
import 'package:uhd/l10n/medicine_library_localizations.dart';
import 'package:uhd/models/medicine_library_model.dart';
import 'package:uhd/widgets/app_widgets.dart';

class MedicineLibraryCard extends StatelessWidget {
  final MedicineLibraryMedicine medicine;
  final VoidCallback onTap;

  const MedicineLibraryCard({
    super.key,
    required this.medicine,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final strings = MedicineLibraryStrings.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: appSurfaceColor(context),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: appBorderColor(context)),
          boxShadow: [
            BoxShadow(
              color: appShadowColor(context, 0.05),
              blurRadius: 16,
              offset: const Offset(0, 8),
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
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: appTintSurfaceColor(context),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.medical_services_outlined,
                      color: authPrimary),
                ),
                const SizedBox(width: 12),
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
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${strings.t(MedicineLibraryTextKey.generic)}: ${medicine.genericName}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: appMutedTextColor(context),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: appMutedTextColor(context)),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '${medicine.category} - ${medicine.medicineClass}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: appTextColor(context),
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${strings.t(MedicineLibraryTextKey.forms)}: ${medicine.formsSummary}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: appMutedTextColor(context),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _Badge(
                  label: medicine.prescriptionRequired
                      ? strings.t(MedicineLibraryTextKey.prescriptionBadge)
                      : strings.t(MedicineLibraryTextKey.noPrescriptionBadge),
                  icon: medicine.prescriptionRequired
                      ? Icons.assignment_outlined
                      : Icons.check_circle_outline,
                  color: medicine.prescriptionRequired
                      ? Colors.orange.shade700
                      : authPrimary,
                ),
                _Badge(
                  label: strings.warningLevelLabel(medicine.warningLevel),
                  icon: Icons.warning_amber_outlined,
                  color: _warningColor(medicine.warningLevel),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Text(
                medicine.description,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: appMutedTextColor(context),
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: medicine.tags.take(4).map((tag) {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                  decoration: BoxDecoration(
                    color: appTintSurfaceColor(context),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    tag,
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
        ),
      ),
    );
  }

  Color _warningColor(MedicineLibraryWarningLevel level) {
    switch (level) {
      case MedicineLibraryWarningLevel.generalCaution:
        return authPrimary;
      case MedicineLibraryWarningLevel.importantWarnings:
        return Colors.orange.shade700;
      case MedicineLibraryWarningLevel.highCaution:
        return Colors.redAccent;
    }
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;

  const _Badge({
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(appIsDark(context) ? 0.18 : 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.30)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 15),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
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
