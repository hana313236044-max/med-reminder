import 'package:uhd/models/cart_item_model.dart';
import 'package:uhd/models/demo_order_model.dart';
import 'package:uhd/services/order_repository.dart';

class DemoOrderRepository implements OrderRepository {
  DemoOrderRepository._();

  static final DemoOrderRepository instance = DemoOrderRepository._();
  final List<DemoOrder> _orders = [];

  @override
  Future<DemoOrder> createDemoOrder({
    required PharmacyCart cart,
    required String fullName,
    required String phoneNumber,
    required String fulfillmentMethod,
    required String deliveryAddress,
    required String paymentMethod,
    required int deliveryFee,
    required int totalPrice,
    required String cardLastFour,
    required String notes,
  }) async {
    final now = DateTime.now();
    final order = DemoOrder(
      id: _orderId(now, _orders.length + 1),
      pharmacyId: cart.pharmacyId ?? '',
      pharmacyName: cart.pharmacyName ?? '',
      fullName: fullName,
      phoneNumber: phoneNumber,
      fulfillmentMethod: fulfillmentMethod,
      deliveryAddress: deliveryAddress,
      paymentMethod: paymentMethod,
      deliveryFee: deliveryFee,
      cardLastFour: cardLastFour,
      notes: notes,
      items: List.unmodifiable(cart.items),
      totalPrice: totalPrice,
      currency: cart.currency,
      createdAt: now,
    );
    _orders.add(order);
    return order;
  }

  @override
  Future<List<DemoOrder>> loadDemoOrders() async {
    return List.unmodifiable(_orders);
  }

  String _orderId(DateTime date, int sequence) {
    final year = date.year.toString();
    final number = sequence.toString().padLeft(4, '0');
    return 'DEMO-$year-$number';
  }
}
