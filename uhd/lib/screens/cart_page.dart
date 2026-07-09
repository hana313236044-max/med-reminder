import 'package:flutter/material.dart';
import 'package:uhd/l10n/pharmacy_localizations.dart';
import 'package:uhd/models/cart_item_model.dart';
import 'package:uhd/models/pharmacy_model.dart';
import 'package:uhd/services/cart_service.dart';
import 'package:uhd/services/demo_checkout_pricing.dart';
import 'package:uhd/widgets/app_widgets.dart';

class CartPage extends StatelessWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = PharmacyStrings.of(context);
    return Scaffold(
      backgroundColor: appScaffoldColor(context),
      appBar: AppBar(
        backgroundColor: authPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          strings.t(PharmacyTextKey.cart),
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: CartService.instance,
          builder: (context, _) {
            final cart = CartService.instance.cart;
            if (cart.isEmpty) {
              return _EmptyCart();
            }
            return ListView(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 760),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          strings.t(PharmacyTextKey.cart),
                          style: TextStyle(
                            color: appTextColor(context),
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          cart.pharmacyName ?? '',
                          style: TextStyle(
                            color: appMutedTextColor(context),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 16),
                        for (final item in cart.items) ...[
                          _CartItemTile(item: item),
                          const SizedBox(height: 10),
                        ],
                        _CartSummary(),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _CartItemTile extends StatelessWidget {
  final CartItem item;

  const _CartItemTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final strings = PharmacyStrings.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: appSurfaceColor(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: appBorderColor(context)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: appTintSurfaceColor(context),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.medication_outlined, color: authPrimary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.medicine.medicineName,
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
                  '${item.medicine.form} - ${item.medicine.strength}',
                  style: TextStyle(
                    color: appMutedTextColor(context),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${item.quantity} x ${item.medicine.priceLabel} = ${PharmacyInventoryItem.formatPrice(item.subtotal)} ${item.medicine.currency}',
                  style: TextStyle(
                    color: appTextColor(context),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    IconButton.filledTonal(
                      tooltip: '-',
                      onPressed: () => CartService.instance.decrease(item),
                      icon: const Icon(Icons.remove),
                    ),
                    Text(
                      item.quantity.toString(),
                      style: TextStyle(
                        color: appTextColor(context),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    IconButton.filledTonal(
                      tooltip: '+',
                      onPressed: item.quantity >= item.medicine.stockQuantity
                          ? null
                          : () => CartService.instance.increase(item),
                      icon: const Icon(Icons.add),
                    ),
                    TextButton.icon(
                      onPressed: () => CartService.instance.remove(item),
                      icon: const Icon(Icons.delete_outline),
                      label: Text(strings.t(PharmacyTextKey.remove)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CartSummary extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final strings = PharmacyStrings.of(context);
    final cart = CartService.instance.cart;
    final orderTotal = DemoCheckoutPricing.totalWithDelivery(cart.totalPrice);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: appTintSurfaceColor(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: appBorderColor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SummaryRow(
            label: strings.t(PharmacyTextKey.subtotal),
            value:
                '${PharmacyInventoryItem.formatPrice(cart.totalPrice)} ${cart.currency}',
          ),
          const SizedBox(height: 8),
          _SummaryRow(
            label: strings.t(PharmacyTextKey.deliveryFee),
            value:
                '${PharmacyInventoryItem.formatPrice(DemoCheckoutPricing.deliveryFee)} ${cart.currency}',
          ),
          const Divider(height: 22),
          _SummaryRow(
            label: strings.t(PharmacyTextKey.orderTotal),
            value:
                '${PharmacyInventoryItem.formatPrice(orderTotal)} ${cart.currency}',
            large: true,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: CartService.instance.clear,
                  icon: const Icon(Icons.delete_sweep_outlined),
                  label: Text(strings.t(PharmacyTextKey.clearCart)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: authPrimary,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => Navigator.pushNamed(context, '/checkout'),
                  icon: const Icon(Icons.check_circle_outline),
                  label: Text(strings.t(PharmacyTextKey.checkout)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool large;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.large = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: large ? appTextColor(context) : appMutedTextColor(context),
              fontSize: large ? 18 : 14,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: appTextColor(context),
            fontSize: large ? 18 : 14,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _EmptyCart extends StatelessWidget {
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
              const Icon(Icons.shopping_cart_outlined,
                  color: authPrimary, size: 44),
              const SizedBox(height: 10),
              Text(
                strings.t(PharmacyTextKey.emptyCartTitle),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: appTextColor(context),
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                strings.t(PharmacyTextKey.emptyCartMessage),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: appMutedTextColor(context),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
