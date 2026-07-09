import 'package:flutter/material.dart';
import 'package:uhd/l10n/pharmacy_localizations.dart';
import 'package:uhd/models/pharmacy_model.dart';
import 'package:uhd/services/cart_service.dart';
import 'package:uhd/widgets/app_widgets.dart';

Future<bool> addPharmacyMedicineToCart({
  required BuildContext context,
  required Pharmacy pharmacy,
  required PharmacyInventoryItem item,
}) async {
  final strings = PharmacyStrings.of(context);
  if (!item.inStock || item.stockQuantity <= 0) {
    showAuthMessage(
      context,
      strings.t(PharmacyTextKey.outOfStock),
      backgroundColor: Colors.redAccent,
    );
    return false;
  }
  if (item.requiresPrescription) {
    showAuthMessage(
      context,
      strings.t(PharmacyTextKey.prescriptionAddDisabled),
      backgroundColor: Colors.orange.shade700,
    );
    return false;
  }

  final cart = CartService.instance;
  if (cart.hasDifferentPharmacy(pharmacy.id)) {
    final shouldClear = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(strings.t(PharmacyTextKey.otherPharmacyCartTitle)),
          content: Text(strings.t(PharmacyTextKey.otherPharmacyCartMessage)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(strings.t(PharmacyTextKey.cancel)),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: authPrimary),
              onPressed: () => Navigator.pop(context, true),
              child: Text(strings.t(PharmacyTextKey.clearAndAdd)),
            ),
          ],
        );
      },
    );
    if (shouldClear != true) return false;
    cart.clear();
  }

  final error = cart.addItem(pharmacy: pharmacy, medicine: item);
  if (error != null) {
    showAuthMessage(
      context,
      _cartErrorMessage(strings, error),
      backgroundColor: Colors.orange.shade700,
    );
    return false;
  }

  if (item.requiresPrescription) {
    showAuthMessage(
      context,
      strings.t(PharmacyTextKey.prescriptionWarning),
      backgroundColor: Colors.orange.shade700,
    );
  } else {
    showAuthMessage(context, strings.t(PharmacyTextKey.addedToCart));
  }
  return true;
}

String _cartErrorMessage(PharmacyStrings strings, String error) {
  if (error == 'This medicine is out of stock.') {
    return strings.t(PharmacyTextKey.outOfStock);
  }
  if (error == 'Quantity cannot exceed available stock.') {
    return strings.t(PharmacyTextKey.maxStockReached);
  }
  if (error == 'Cart contains another pharmacy.') {
    return strings.t(PharmacyTextKey.otherPharmacyCartMessage);
  }
  if (error == 'Prescription medicines cannot be added.') {
    return strings.t(PharmacyTextKey.prescriptionAddDisabled);
  }
  return error;
}
