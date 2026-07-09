import 'package:flutter/foundation.dart';
import 'package:uhd/models/cart_item_model.dart';
import 'package:uhd/models/pharmacy_model.dart';

class CartService extends ChangeNotifier {
  CartService._();

  static final CartService instance = CartService._();

  String? _pharmacyId;
  String? _pharmacyName;
  final List<CartItem> _items = [];

  PharmacyCart get cart {
    return PharmacyCart(
      pharmacyId: _pharmacyId,
      pharmacyName: _pharmacyName,
      items: List.unmodifiable(_items),
    );
  }

  bool hasDifferentPharmacy(String pharmacyId) {
    return _items.isNotEmpty && _pharmacyId != pharmacyId;
  }

  bool containsMedicine(String pharmacyId, String medicineId) {
    return _items.any(
      (item) =>
          item.pharmacyId == pharmacyId &&
          item.medicine.medicineId == medicineId,
    );
  }

  String? addItem({
    required Pharmacy pharmacy,
    required PharmacyInventoryItem medicine,
    int quantity = 1,
  }) {
    if (!medicine.inStock || medicine.stockQuantity <= 0) {
      return 'This medicine is out of stock.';
    }
    if (medicine.requiresPrescription) {
      return 'Prescription medicines cannot be added.';
    }
    if (hasDifferentPharmacy(pharmacy.id)) {
      return 'Cart contains another pharmacy.';
    }

    _pharmacyId = pharmacy.id;
    _pharmacyName = pharmacy.name;
    final index = _items.indexWhere(
      (item) =>
          item.pharmacyId == pharmacy.id &&
          item.medicine.medicineId == medicine.medicineId &&
          item.medicine.strength == medicine.strength &&
          item.medicine.brand == medicine.brand,
    );
    if (index == -1) {
      final safeQuantity = quantity.clamp(1, medicine.stockQuantity).toInt();
      _items.add(
        CartItem(
          pharmacyId: pharmacy.id,
          pharmacyName: pharmacy.name,
          medicine: medicine,
          quantity: safeQuantity,
        ),
      );
    } else {
      final current = _items[index];
      if (current.quantity >= medicine.stockQuantity) {
        return 'Quantity cannot exceed available stock.';
      }
      final nextQuantity =
          (current.quantity + quantity)
              .clamp(1, medicine.stockQuantity)
              .toInt();
      _items[index] = current.copyWith(quantity: nextQuantity);
    }
    notifyListeners();
    return null;
  }

  void setQuantity(CartItem item, int quantity) {
    final index = _items.indexOf(item);
    if (index == -1) return;
    final safeQuantity =
        quantity.clamp(1, item.medicine.stockQuantity).toInt();
    _items[index] = item.copyWith(quantity: safeQuantity);
    notifyListeners();
  }

  void increase(CartItem item) {
    setQuantity(item, item.quantity + 1);
  }

  void decrease(CartItem item) {
    if (item.quantity <= 1) {
      remove(item);
      return;
    }
    setQuantity(item, item.quantity - 1);
  }

  void remove(CartItem item) {
    _items.remove(item);
    if (_items.isEmpty) {
      _pharmacyId = null;
      _pharmacyName = null;
    }
    notifyListeners();
  }

  void clear() {
    _items.clear();
    _pharmacyId = null;
    _pharmacyName = null;
    notifyListeners();
  }
}
