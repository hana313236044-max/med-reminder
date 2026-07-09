import 'package:uhd/models/pharmacy_model.dart';

class CartItem {
  final String pharmacyId;
  final String pharmacyName;
  final PharmacyInventoryItem medicine;
  final int quantity;

  const CartItem({
    required this.pharmacyId,
    required this.pharmacyName,
    required this.medicine,
    required this.quantity,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    final rawMedicine = json['medicine'];
    final medicineJson = rawMedicine is Map
        ? Map<String, dynamic>.from(rawMedicine)
        : <String, dynamic>{
            'medicineId': json['medicineId'],
            'medicineName': json['medicineName'],
            'genericName': json['genericName'],
            'category': json['category'],
            'form': json['form'],
            'strength': json['strength'],
            'brand': json['brand'],
            'price': json['unitPrice'] ?? json['price'],
            'currency': json['currency'],
            'inStock': true,
            'stockQuantity': json['stockQuantity'] ?? json['quantity'],
            'requiresPrescription': json['requiresPrescription'],
          };
    return CartItem(
      pharmacyId: _string(json['pharmacyId']),
      pharmacyName: _string(json['pharmacyName']),
      medicine: PharmacyInventoryItem.fromJson(medicineJson),
      quantity: _positiveInt(json['quantity']),
    );
  }

  CartItem copyWith({
    String? pharmacyId,
    String? pharmacyName,
    PharmacyInventoryItem? medicine,
    int? quantity,
  }) {
    return CartItem(
      pharmacyId: pharmacyId ?? this.pharmacyId,
      pharmacyName: pharmacyName ?? this.pharmacyName,
      medicine: medicine ?? this.medicine,
      quantity: quantity ?? this.quantity,
    );
  }

  int get subtotal => medicine.price * quantity;

  Map<String, dynamic> toJson() {
    return {
      'pharmacyId': pharmacyId,
      'pharmacyName': pharmacyName,
      'medicine': medicine.toJson(),
      'quantity': quantity,
      'subtotal': subtotal,
    };
  }

  static String _string(dynamic value, {String fallback = ''}) {
    final parsed = value?.toString().trim() ?? '';
    return parsed.isEmpty ? fallback : parsed;
  }

  static int _positiveInt(dynamic value) {
    if (value is num) return value.toInt() < 1 ? 1 : value.toInt();
    final parsed = int.tryParse(value?.toString() ?? '') ?? 1;
    return parsed < 1 ? 1 : parsed;
  }
}

class PharmacyCart {
  final String? pharmacyId;
  final String? pharmacyName;
  final List<CartItem> items;

  const PharmacyCart({
    this.pharmacyId,
    this.pharmacyName,
    this.items = const [],
  });

  factory PharmacyCart.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    return PharmacyCart(
      pharmacyId: CartItem._string(json['pharmacyId'], fallback: ''),
      pharmacyName: CartItem._string(json['pharmacyName'], fallback: ''),
      items: rawItems is List
          ? rawItems
              .whereType<Map>()
              .map((item) => CartItem.fromJson(Map<String, dynamic>.from(item)))
              .toList()
          : const [],
    );
  }

  bool get isEmpty => items.isEmpty;
  bool get isNotEmpty => items.isNotEmpty;

  int get totalQuantity {
    return items.fold(0, (total, item) => total + item.quantity);
  }

  int get totalPrice {
    return items.fold(0, (total, item) => total + item.subtotal);
  }

  String get currency {
    return items.isEmpty ? 'IQD' : items.first.medicine.currency;
  }

  Map<String, dynamic> toJson() {
    return {
      'pharmacyId': pharmacyId,
      'pharmacyName': pharmacyName,
      'items': items.map((item) => item.toJson()).toList(),
      'totalQuantity': totalQuantity,
      'totalPrice': totalPrice,
      'currency': currency,
    };
  }
}
