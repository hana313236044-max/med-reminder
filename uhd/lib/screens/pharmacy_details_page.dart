import 'package:flutter/material.dart';
import 'package:uhd/l10n/pharmacy_localizations.dart';
import 'package:uhd/models/pharmacy_model.dart';
import 'package:uhd/services/cart_service.dart';
import 'package:uhd/services/json_pharmacy_repository.dart';
import 'package:uhd/widgets/app_widgets.dart';
import 'package:uhd/widgets/pharmacy_cart_actions.dart';
import 'package:uhd/widgets/pharmacy_inventory_list.dart';

class PharmacyDetailsPage extends StatelessWidget {
  final String pharmacyId;

  const PharmacyDetailsPage({
    super.key,
    required this.pharmacyId,
  });

  @override
  Widget build(BuildContext context) {
    final strings = PharmacyStrings.of(context);
    final repository = JsonPharmacyRepository.instance;
    return Scaffold(
      backgroundColor: appScaffoldColor(context),
      appBar: AppBar(
        backgroundColor: authPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          strings.t(PharmacyTextKey.pharmacyDetails),
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        actions: [
          _CartButton(),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: FutureBuilder<List<Pharmacy>>(
          future: repository.loadPharmacies(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: authPrimary),
              );
            }
            if (snapshot.hasError) {
              return _NotFoundState(
                title: strings.t(PharmacyTextKey.errorTitle),
                onBack: () => _backToPharmacies(context),
              );
            }
            final pharmacy = repository.findById(
              snapshot.data ?? const [],
              pharmacyId,
            );
            if (pharmacy == null) {
              return _NotFoundState(
                title: strings.t(PharmacyTextKey.pharmacyNotFound),
                onBack: () => _backToPharmacies(context),
              );
            }
            return _DetailsContent(
              pharmacy: pharmacy,
              onBack: () => _backToPharmacies(context),
            );
          },
        ),
      ),
    );
  }

  void _backToPharmacies(BuildContext context) {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
      return;
    }
    Navigator.pushReplacementNamed(context, '/pharmacies');
  }
}

class _DetailsContent extends StatelessWidget {
  final Pharmacy pharmacy;
  final VoidCallback onBack;

  const _DetailsContent({
    required this.pharmacy,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final strings = PharmacyStrings.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final twoColumns = constraints.maxWidth >= 980;
        return ListView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 32),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1180),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _DetailsHeader(pharmacy: pharmacy),
                    const SizedBox(height: 14),
                    _DisclaimerBanner(
                      text: strings.t(PharmacyTextKey.disclaimer),
                    ),
                    const SizedBox(height: 14),
                    if (twoColumns)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 4,
                            child: PharmacyInventoryList(
                              pharmacy: pharmacy,
                              onAddToCart: (item) =>
                                  addPharmacyMedicineToCart(
                                context: context,
                                pharmacy: pharmacy,
                                item: item,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 3,
                            child: Column(
                              children: [
                                _StoreInfoSection(pharmacy: pharmacy),
                                const SizedBox(height: 14),
                                _ActionsSection(onBack: onBack),
                              ],
                            ),
                          ),
                        ],
                      )
                    else ...[
                      _StoreInfoSection(pharmacy: pharmacy),
                      const SizedBox(height: 14),
                      PharmacyInventoryList(
                        pharmacy: pharmacy,
                        onAddToCart: (item) => addPharmacyMedicineToCart(
                          context: context,
                          pharmacy: pharmacy,
                          item: item,
                        ),
                      ),
                      const SizedBox(height: 14),
                      _ActionsSection(onBack: onBack),
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
  final Pharmacy pharmacy;

  const _DetailsHeader({required this.pharmacy});

  @override
  Widget build(BuildContext context) {
    final strings = PharmacyStrings.of(context);
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
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: appTintSurfaceColor(context),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.local_pharmacy_outlined,
                  color: authPrimary,
                  size: 30,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pharmacy.name,
                      style: TextStyle(
                        color: appTextColor(context),
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
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
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InfoChip(
                icon: Icons.star,
                label:
                    '${strings.t(PharmacyTextKey.rating)}: ${pharmacy.rating.toStringAsFixed(1)} (${pharmacy.reviewCount} ${strings.t(PharmacyTextKey.reviews)})',
              ),
              _InfoChip(
                icon: Icons.medication_outlined,
                label:
                    '${pharmacy.availableMedicineCount} ${strings.t(PharmacyTextKey.medicinesAvailable)}',
              ),
              _StatusChip(
                active: pharmacy.deliveryAvailable,
                activeLabel: strings.t(PharmacyTextKey.deliveryAvailable),
                inactiveLabel: strings.t(PharmacyTextKey.notAvailable),
                icon: Icons.delivery_dining_outlined,
              ),
              if (pharmacy.isOpen24Hours)
                _InfoChip(
                  icon: Icons.schedule,
                  label: strings.t(PharmacyTextKey.open24Hours),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StoreInfoSection extends StatelessWidget {
  final Pharmacy pharmacy;

  const _StoreInfoSection({required this.pharmacy});

  @override
  Widget build(BuildContext context) {
    final strings = PharmacyStrings.of(context);
    return _InfoSection(
      icon: Icons.storefront_outlined,
      title: strings.t(PharmacyTextKey.storeInformation),
      children: [
        _InfoRow(
          icon: Icons.place_outlined,
          label: strings.t(PharmacyTextKey.address),
          value: pharmacy.address,
        ),
        _InfoRow(
          icon: Icons.phone_outlined,
          label: strings.t(PharmacyTextKey.phone),
          value: pharmacy.phone,
        ),
        _InfoRow(
          icon: Icons.phone_in_talk_outlined,
          label: strings.t(PharmacyTextKey.secondaryPhone),
          value: pharmacy.secondaryPhone,
        ),
        _InfoRow(
          icon: Icons.email_outlined,
          label: strings.t(PharmacyTextKey.email),
          value: pharmacy.email,
        ),
        const SizedBox(height: 8),
        _OpeningHours(hours: pharmacy.openingHours),
        const SizedBox(height: 12),
        _ChipGroup(
          title: strings.t(PharmacyTextKey.services),
          values: pharmacy.services,
        ),
        const SizedBox(height: 12),
        _ChipGroup(
          title: strings.t(PharmacyTextKey.paymentMethods),
          values: pharmacy.paymentMethods,
        ),
        const SizedBox(height: 12),
        _InfoRow(
          icon: Icons.notes_outlined,
          label: strings.t(PharmacyTextKey.notes),
          value: pharmacy.notes,
        ),
      ],
    );
  }
}

class _ActionsSection extends StatelessWidget {
  final VoidCallback onBack;

  const _ActionsSection({required this.onBack});

  @override
  Widget build(BuildContext context) {
    final strings = PharmacyStrings.of(context);
    return _InfoSection(
      icon: Icons.touch_app_outlined,
      title: strings.t(PharmacyTextKey.checkout),
      children: [
        AnimatedBuilder(
          animation: CartService.instance,
          builder: (context, _) {
            final cart = CartService.instance.cart;
            return FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: authPrimary,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: cart.isEmpty
                  ? null
                  : () => Navigator.pushNamed(context, '/cart'),
              icon: const Icon(Icons.shopping_cart_outlined),
              label: Text(
                '${strings.t(PharmacyTextKey.viewCart)} (${cart.totalQuantity})',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            );
          },
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
            strings.t(PharmacyTextKey.backToPharmacies),
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

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: authPrimary, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: appTextColor(context),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: TextStyle(
                    color: appMutedTextColor(context),
                    height: 1.3,
                    fontWeight: FontWeight.w700,
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

class _OpeningHours extends StatelessWidget {
  final OpeningHours hours;

  const _OpeningHours({required this.hours});

  @override
  Widget build(BuildContext context) {
    final strings = PharmacyStrings.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          strings.t(PharmacyTextKey.openingHours),
          style: TextStyle(
            color: appTextColor(context),
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        ...hours.entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 5),
            child: Row(
              children: [
                SizedBox(
                  width: 88,
                  child: Text(
                    entry.key,
                    style: TextStyle(
                      color: appMutedTextColor(context),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    entry.value,
                    style: TextStyle(
                      color: appTextColor(context),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

class _ChipGroup extends StatelessWidget {
  final String title;
  final List<String> values;

  const _ChipGroup({
    required this.title,
    required this.values,
  });

  @override
  Widget build(BuildContext context) {
    final items = values.isEmpty ? ['Not provided'] : values;
    return Column(
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
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: appTintSurfaceColor(context),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                item,
                style: const TextStyle(
                  color: authPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            );
          }).toList(),
        ),
      ],
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: active
            ? appTintSurfaceColor(context)
            : appSoftSurfaceColor(context),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 15),
          const SizedBox(width: 6),
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

class _DisclaimerBanner extends StatelessWidget {
  final String text;

  const _DisclaimerBanner({required this.text});

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

class _CartButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final strings = PharmacyStrings.of(context);
    return AnimatedBuilder(
      animation: CartService.instance,
      builder: (context, _) {
        final cart = CartService.instance.cart;
        return Badge(
          isLabelVisible: cart.totalQuantity > 0,
          label: Text(cart.totalQuantity.toString()),
          child: IconButton(
            tooltip: strings.t(PharmacyTextKey.viewCart),
            onPressed: () => Navigator.pushNamed(context, '/cart'),
            icon: const Icon(Icons.shopping_cart_outlined),
          ),
        );
      },
    );
  }
}

class _NotFoundState extends StatelessWidget {
  final String title;
  final VoidCallback onBack;

  const _NotFoundState({
    required this.title,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final strings = PharmacyStrings.of(context);
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
              const Icon(
                Icons.search_off_outlined,
                color: authPrimary,
                size: 44,
              ),
              const SizedBox(height: 10),
              Text(
                title,
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
                label: Text(strings.t(PharmacyTextKey.backToPharmacies)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
