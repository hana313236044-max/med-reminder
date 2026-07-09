import 'package:flutter/material.dart';
import 'package:uhd/l10n/pharmacy_localizations.dart';
import 'package:uhd/models/pharmacy_model.dart';
import 'package:uhd/services/json_pharmacy_repository.dart';
import 'package:uhd/widgets/app_widgets.dart';
import 'package:uhd/widgets/pharmacy_cart_actions.dart';

class AvailablePharmaciesSection extends StatelessWidget {
  final String medicineId;

  const AvailablePharmaciesSection({
    super.key,
    required this.medicineId,
  });

  @override
  Widget build(BuildContext context) {
    final strings = PharmacyStrings.of(context);
    final repository = JsonPharmacyRepository.instance;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: appSurfaceColor(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: appBorderColor(context)),
      ),
      child: FutureBuilder<List<Pharmacy>>(
        future: repository.loadPharmacies(),
        builder: (context, snapshot) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.local_pharmacy_outlined,
                      color: authPrimary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      strings.t(PharmacyTextKey.availableAtPharmacies),
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
              if (snapshot.connectionState == ConnectionState.waiting)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(color: authPrimary),
                  ),
                )
              else if (snapshot.hasError)
                _Message(text: strings.t(PharmacyTextKey.errorTitle))
              else
                _MatchesList(
                  pharmacies: repository.findPharmaciesWithMedicine(
                    snapshot.data ?? const [],
                    medicineId,
                    limit: 10,
                  ),
                  medicineId: medicineId,
                ),
            ],
          );
        },
      ),
    );
  }
}

class _MatchesList extends StatelessWidget {
  final List<Pharmacy> pharmacies;
  final String medicineId;

  const _MatchesList({
    required this.pharmacies,
    required this.medicineId,
  });

  @override
  Widget build(BuildContext context) {
    final strings = PharmacyStrings.of(context);
    if (pharmacies.isEmpty) {
      return _Message(text: strings.t(PharmacyTextKey.noPharmaciesForMedicine));
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final twoColumns = constraints.maxWidth >= 740;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: pharmacies.map((pharmacy) {
            final item = pharmacy.inStockByMedicineId(medicineId).first;
            return SizedBox(
              width: twoColumns
                  ? (constraints.maxWidth - 12) / 2
                  : constraints.maxWidth,
              child: _PharmacyMedicineCard(
                pharmacy: pharmacy,
                item: item,
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _PharmacyMedicineCard extends StatelessWidget {
  final Pharmacy pharmacy;
  final PharmacyInventoryItem item;

  const _PharmacyMedicineCard({
    required this.pharmacy,
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    final strings = PharmacyStrings.of(context);
    final canAddToCart = !item.requiresPrescription;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: appSoftSurfaceColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: appBorderColor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            pharmacy.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: appTextColor(context),
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${pharmacy.city} - ${pharmacy.area}',
            style: TextStyle(
              color: appMutedTextColor(context),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${item.brand} ${item.strength} - ${item.priceLabel}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: appTextColor(context),
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Badge(
                icon: Icons.delivery_dining_outlined,
                label: pharmacy.deliveryAvailable
                    ? strings.t(PharmacyTextKey.deliveryAvailable)
                    : strings.t(PharmacyTextKey.notAvailable),
              ),
              _Badge(
                icon: Icons.inventory_2_outlined,
                label:
                    '${strings.t(PharmacyTextKey.stockQuantity)}: ${item.stockQuantity}',
              ),
              if (item.requiresPrescription)
                _Badge(
                  icon: Icons.assignment_outlined,
                  label: strings.t(PharmacyTextKey.prescriptionRequired),
                  color: Colors.orange.shade700,
                ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: () => Navigator.pushNamed(
                  context,
                  '/pharmacies/${Uri.encodeComponent(pharmacy.id)}',
                ),
                icon: const Icon(Icons.storefront_outlined),
                label: Text(strings.t(PharmacyTextKey.viewPharmacy)),
              ),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor:
                      canAddToCart ? authPrimary : appMutedTextColor(context),
                  foregroundColor: Colors.white,
                ),
                onPressed: canAddToCart
                    ? () => addPharmacyMedicineToCart(
                          context: context,
                          pharmacy: pharmacy,
                          item: item,
                        )
                    : null,
                icon: const Icon(Icons.add_shopping_cart),
                label: Text(
                  item.requiresPrescription
                      ? strings.t(PharmacyTextKey.prescriptionRequired)
                      : strings.t(PharmacyTextKey.addToCart),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _Badge({
    required this.icon,
    required this.label,
    this.color = authPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(appIsDark(context) ? 0.18 : 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
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

class _Message extends StatelessWidget {
  final String text;

  const _Message({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: appTintSurfaceColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: appBorderColor(context)),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: appMutedTextColor(context),
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
