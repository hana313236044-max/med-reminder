import 'package:flutter/material.dart';
import 'package:uhd/l10n/pharmacy_localizations.dart';
import 'package:uhd/models/pharmacy_model.dart';
import 'package:uhd/widgets/app_widgets.dart';

class PharmacyCard extends StatelessWidget {
  final Pharmacy pharmacy;
  final VoidCallback onViewDetails;

  const PharmacyCard({
    super.key,
    required this.pharmacy,
    required this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    final strings = PharmacyStrings.of(context);
    return Container(
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
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: appTintSurfaceColor(context),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.local_pharmacy_outlined,
                    color: authPrimary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  pharmacy.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: appTextColor(context),
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '${pharmacy.city} - ${pharmacy.area}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: appTextColor(context),
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            pharmacy.address,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: appMutedTextColor(context),
              height: 1.25,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InfoChip(
                icon: Icons.star,
                label:
                    '${strings.t(PharmacyTextKey.rating)}: ${pharmacy.rating.toStringAsFixed(1)}',
              ),
              _InfoChip(
                icon: Icons.medication_outlined,
                label:
                    '${pharmacy.availableMedicineCount} ${strings.t(PharmacyTextKey.medicinesAvailable)}',
              ),
              _InfoChip(
                icon: Icons.schedule,
                label: pharmacy.isOpen24Hours
                    ? strings.t(PharmacyTextKey.open24Hours)
                    : pharmacy.openingHours.summary,
              ),
              _StatusChip(
                active: pharmacy.deliveryAvailable,
                activeLabel: strings.t(PharmacyTextKey.deliveryAvailable),
                inactiveLabel: strings.t(PharmacyTextKey.notAvailable),
                icon: Icons.delivery_dining_outlined,
              ),
            ],
          ),
          const Spacer(),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: authPrimary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: onViewDetails,
              icon: const Icon(Icons.chevron_right),
              label: Text(
                strings.t(PharmacyTextKey.viewDetails),
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: appTintSurfaceColor(context),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: authPrimary),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: authPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final bool active;
  final String activeLabel;
  final String inactiveLabel;
  final IconData icon;

  const _StatusChip({
    required this.active,
    required this.activeLabel,
    required this.inactiveLabel,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final color = active ? authPrimary : appMutedTextColor(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: active
            ? appTintSurfaceColor(context)
            : appSoftSurfaceColor(context),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 5),
          Text(
            active ? activeLabel : inactiveLabel,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
