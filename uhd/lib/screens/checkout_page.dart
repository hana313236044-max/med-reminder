import 'package:flutter/material.dart';
import 'package:uhd/l10n/pharmacy_localizations.dart';
import 'package:uhd/models/demo_order_model.dart';
import 'package:uhd/models/pharmacy_model.dart';
import 'package:uhd/services/cart_service.dart';
import 'package:uhd/services/demo_order_repository.dart';
import 'package:uhd/services/demo_checkout_pricing.dart';
import 'package:uhd/widgets/app_widgets.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();
  final _cardNameController = TextEditingController();
  final _cardNumberController = TextEditingController();
  final _cardExpiryController = TextEditingController();
  final _cardCvvController = TextEditingController();
  String _paymentMethod = 'Cash';
  bool _placingOrder = false;

  bool get _isCardPayment => _paymentMethod == 'Card';

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    _cardNameController.dispose();
    _cardNumberController.dispose();
    _cardExpiryController.dispose();
    _cardCvvController.dispose();
    super.dispose();
  }

  Future<void> _placeOrder() async {
    final cart = CartService.instance.cart;
    if (cart.isEmpty || _placingOrder) return;
    if (_formKey.currentState?.validate() != true) return;

    setState(() => _placingOrder = true);
    try {
      final order = await DemoOrderRepository.instance.createDemoOrder(
        cart: cart,
        fullName: _nameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        fulfillmentMethod: 'Delivery',
        deliveryAddress: _addressController.text.trim(),
        paymentMethod: _paymentMethod,
        deliveryFee: DemoCheckoutPricing.deliveryFee,
        totalPrice: DemoCheckoutPricing.totalWithDelivery(cart.totalPrice),
        cardLastFour: _isCardPayment ? _cardLastFour : '',
        notes: _notesController.text.trim(),
      );
      if (!mounted) return;
      await _showSuccess(order);
      if (!mounted) return;
      CartService.instance.clear();
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/pharmacies',
        (route) => false,
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _placingOrder = false);
      showAuthMessage(
        context,
        PharmacyStrings.of(context).t(PharmacyTextKey.checkoutError),
        backgroundColor: Colors.redAccent,
      );
    }
  }

  Future<void> _showSuccess(DemoOrder order) async {
    final strings = PharmacyStrings.of(context);
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(strings.t(PharmacyTextKey.successTitle)),
          content: Text(
            '${strings.t(PharmacyTextKey.orderId)}: ${order.id}\n'
            '${strings.t(PharmacyTextKey.total)}: '
            '${PharmacyInventoryItem.formatPrice(order.totalPrice)} ${order.currency}',
          ),
          actions: [
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: authPrimary),
              onPressed: () => Navigator.pop(context),
              child: Text(strings.t(PharmacyTextKey.ok)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = PharmacyStrings.of(context);
    final cart = CartService.instance.cart;
    return Scaffold(
      backgroundColor: appScaffoldColor(context),
      appBar: AppBar(
        backgroundColor: authPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          strings.t(PharmacyTextKey.checkoutTitle),
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: SafeArea(
        child: cart.isEmpty
            ? const CartPageEmptyRedirect()
            : ListView(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
                children: [
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 720),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              strings.t(PharmacyTextKey.checkoutTitle),
                              style: TextStyle(
                                color: appTextColor(context),
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              strings.t(PharmacyTextKey.demoOrderNotice),
                              style: TextStyle(
                                color: appMutedTextColor(context),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _SummaryCard(),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _nameController,
                              decoration: authInputDecoration(
                                context: context,
                                hintText: strings.t(PharmacyTextKey.fullName),
                                icon: Icons.person_outline,
                              ),
                              validator: _requiredValidator,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              decoration: authInputDecoration(
                                context: context,
                                hintText: strings.t(PharmacyTextKey.phoneNumber),
                                icon: Icons.phone_outlined,
                              ),
                              validator: _requiredValidator,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _addressController,
                              maxLines: 2,
                              decoration: authInputDecoration(
                                context: context,
                                hintText:
                                    strings.t(PharmacyTextKey.deliveryAddress),
                                icon: Icons.home_outlined,
                              ),
                              validator: _requiredValidator,
                            ),
                            const SizedBox(height: 12),
                            _Dropdown<String>(
                              value: _paymentMethod,
                              items: const ['Cash', 'Card'],
                              icon: Icons.payments_outlined,
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() => _paymentMethod = value);
                                }
                              },
                            ),
                            const SizedBox(height: 12),
                            if (_isCardPayment) ...[
                              _CardDetailsSection(
                                cardNameController: _cardNameController,
                                cardNumberController: _cardNumberController,
                                cardExpiryController: _cardExpiryController,
                                cardCvvController: _cardCvvController,
                                requiredValidator: _requiredValidator,
                                cardNumberValidator: _cardNumberValidator,
                                expiryValidator: _expiryValidator,
                                cvvValidator: _cvvValidator,
                              ),
                              const SizedBox(height: 12),
                            ],
                            TextField(
                              controller: _notesController,
                              maxLines: 3,
                              decoration: authInputDecoration(
                                context: context,
                                hintText: strings.t(PharmacyTextKey.optionalNotes),
                                icon: Icons.notes_outlined,
                              ),
                            ),
                            const SizedBox(height: 18),
                            AuthPrimaryButton(
                              label: _placingOrder
                                  ? strings.t(PharmacyTextKey.placingOrder)
                                  : strings.t(PharmacyTextKey.placeDemoOrder),
                              icon: Icons.check_circle_outline,
                              onPressed: _placeOrder,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return PharmacyStrings.of(context).t(PharmacyTextKey.requiredField);
    }
    return null;
  }

  String get _cardLastFour {
    final digits = _cardNumberController.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length <= 4) return digits;
    return digits.substring(digits.length - 4);
  }

  String? _cardNumberValidator(String? value) {
    if (!_isCardPayment) return null;
    final digits = value?.replaceAll(RegExp(r'\D'), '') ?? '';
    if (digits.length < 13 || digits.length > 19) {
      return PharmacyStrings.of(context).t(PharmacyTextKey.cardNumberInvalid);
    }
    return null;
  }

  String? _expiryValidator(String? value) {
    if (!_isCardPayment) return null;
    final text = value?.trim() ?? '';
    final match = RegExp(r'^(0[1-9]|1[0-2])\/\d{2}$').hasMatch(text);
    if (!match) {
      return PharmacyStrings.of(context).t(PharmacyTextKey.cardExpiryInvalid);
    }
    return null;
  }

  String? _cvvValidator(String? value) {
    if (!_isCardPayment) return null;
    final digits = value?.replaceAll(RegExp(r'\D'), '') ?? '';
    if (digits.length < 3 || digits.length > 4) {
      return PharmacyStrings.of(context).t(PharmacyTextKey.cardCvvInvalid);
    }
    return null;
  }
}

class _SummaryCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final strings = PharmacyStrings.of(context);
    final cart = CartService.instance.cart;
    final orderTotal = DemoCheckoutPricing.totalWithDelivery(cart.totalPrice);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: appTintSurfaceColor(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: appBorderColor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            cart.pharmacyName ?? '',
            style: TextStyle(
              color: appTextColor(context),
              fontWeight: FontWeight.w900,
              fontSize: 17,
            ),
          ),
          const SizedBox(height: 8),
          for (final item in cart.items)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                '${item.medicine.medicineName} ${item.medicine.strength} - ${item.quantity} x ${item.medicine.priceLabel}',
                style: TextStyle(
                  color: appMutedTextColor(context),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          const Divider(height: 22),
          _CheckoutSummaryRow(
            label: strings.t(PharmacyTextKey.subtotal),
            value:
                '${PharmacyInventoryItem.formatPrice(cart.totalPrice)} ${cart.currency}',
          ),
          const SizedBox(height: 6),
          _CheckoutSummaryRow(
            label: strings.t(PharmacyTextKey.deliveryFee),
            value:
                '${PharmacyInventoryItem.formatPrice(DemoCheckoutPricing.deliveryFee)} ${cart.currency}',
          ),
          const SizedBox(height: 8),
          _CheckoutSummaryRow(
            label: strings.t(PharmacyTextKey.orderTotal),
            value:
                '${PharmacyInventoryItem.formatPrice(orderTotal)} ${cart.currency}',
            large: true,
          ),
        ],
      ),
    );
  }
}

class _CardDetailsSection extends StatelessWidget {
  final TextEditingController cardNameController;
  final TextEditingController cardNumberController;
  final TextEditingController cardExpiryController;
  final TextEditingController cardCvvController;
  final FormFieldValidator<String> requiredValidator;
  final FormFieldValidator<String> cardNumberValidator;
  final FormFieldValidator<String> expiryValidator;
  final FormFieldValidator<String> cvvValidator;

  const _CardDetailsSection({
    required this.cardNameController,
    required this.cardNumberController,
    required this.cardExpiryController,
    required this.cardCvvController,
    required this.requiredValidator,
    required this.cardNumberValidator,
    required this.expiryValidator,
    required this.cvvValidator,
  });

  @override
  Widget build(BuildContext context) {
    final strings = PharmacyStrings.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: appTintSurfaceColor(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: appBorderColor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            strings.t(PharmacyTextKey.cardDetails),
            style: TextStyle(
              color: appTextColor(context),
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: cardNameController,
            decoration: authInputDecoration(
              context: context,
              hintText: strings.t(PharmacyTextKey.cardholderName),
              icon: Icons.person_outline,
            ),
            validator: requiredValidator,
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: cardNumberController,
            keyboardType: TextInputType.number,
            decoration: authInputDecoration(
              context: context,
              hintText: strings.t(PharmacyTextKey.cardNumber),
              icon: Icons.credit_card,
            ),
            validator: cardNumberValidator,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: cardExpiryController,
                  keyboardType: TextInputType.datetime,
                  decoration: authInputDecoration(
                    context: context,
                    hintText: strings.t(PharmacyTextKey.cardExpiry),
                    icon: Icons.event_outlined,
                  ),
                  validator: expiryValidator,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  controller: cardCvvController,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  decoration: authInputDecoration(
                    context: context,
                    hintText: strings.t(PharmacyTextKey.cardCvv),
                    icon: Icons.lock_outline,
                  ),
                  validator: cvvValidator,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CheckoutSummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool large;

  const _CheckoutSummaryRow({
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
              fontSize: large ? 16 : 14,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: appTextColor(context),
            fontSize: large ? 16 : 14,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _Dropdown<T> extends StatelessWidget {
  final T value;
  final List<T> items;
  final IconData icon;
  final ValueChanged<T?> onChanged;

  const _Dropdown({
    required this.value,
    required this.items,
    required this.icon,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      value: value,
      isExpanded: true,
      decoration: authInputDecoration(
        context: context,
        hintText: '',
        icon: icon,
      ),
      items: items
          .map(
            (item) => DropdownMenuItem<T>(
              value: item,
              child: Text(item.toString()),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }
}

class CartPageEmptyRedirect extends StatelessWidget {
  const CartPageEmptyRedirect({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = PharmacyStrings.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Text(
          strings.t(PharmacyTextKey.emptyCartTitle),
          style: TextStyle(
            color: appMutedTextColor(context),
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
