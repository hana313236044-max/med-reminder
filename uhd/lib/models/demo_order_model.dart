import 'package:uhd/models/cart_item_model.dart';

class DemoOrder {
  final String id;
  final String pharmacyId;
  final String pharmacyName;
  final String fullName;
  final String phoneNumber;
  final String fulfillmentMethod;
  final String deliveryAddress;
  final String paymentMethod;
  final int deliveryFee;
  final String cardLastFour;
  final String notes;
  final List<CartItem> items;
  final int totalPrice;
  final String currency;
  final DateTime createdAt;

  const DemoOrder({
    required this.id,
    required this.pharmacyId,
    required this.pharmacyName,
    required this.fullName,
    required this.phoneNumber,
    required this.fulfillmentMethod,
    required this.deliveryAddress,
    required this.paymentMethod,
    required this.deliveryFee,
    required this.cardLastFour,
    required this.notes,
    required this.items,
    required this.totalPrice,
    required this.currency,
    required this.createdAt,
  });

  factory DemoOrder.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    final items = rawItems is List
        ? rawItems
            .whereType<Map>()
            .map((item) => CartItem.fromJson(Map<String, dynamic>.from(item)))
            .toList()
        : const <CartItem>[];
    return DemoOrder(
      id: _string(json['id']),
      pharmacyId: _string(json['pharmacyId']),
      pharmacyName: _string(json['pharmacyName']),
      fullName: _string(json['fullName']),
      phoneNumber: _string(json['phoneNumber']),
      fulfillmentMethod: _string(json['fulfillmentMethod']),
      deliveryAddress: _string(json['deliveryAddress']),
      paymentMethod: _string(json['paymentMethod']),
      deliveryFee: _int(json['deliveryFee']),
      cardLastFour: _string(json['cardLastFour']),
      notes: _string(json['notes']),
      items: items,
      totalPrice: _int(json['totalPrice']),
      currency: _string(json['currency'], fallback: 'IQD'),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pharmacyId': pharmacyId,
      'pharmacyName': pharmacyName,
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'fulfillmentMethod': fulfillmentMethod,
      'deliveryAddress': deliveryAddress,
      'paymentMethod': paymentMethod,
      'deliveryFee': deliveryFee,
      'cardLastFour': cardLastFour,
      'notes': notes,
      'items': items
          .map(
            (item) => {
              'medicineId': item.medicine.medicineId,
              'medicineName': item.medicine.medicineName,
              'strength': item.medicine.strength,
              'form': item.medicine.form,
              'unitPrice': item.medicine.price,
              'quantity': item.quantity,
              'subtotal': item.subtotal,
            },
          )
          .toList(),
      'totalPrice': totalPrice,
      'currency': currency,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  static String _string(dynamic value, {String fallback = ''}) {
    final parsed = value?.toString().trim() ?? '';
    return parsed.isEmpty ? fallback : parsed;
  }

  static int _int(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
