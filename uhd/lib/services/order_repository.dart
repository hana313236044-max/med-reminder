import 'package:uhd/models/cart_item_model.dart';
import 'package:uhd/models/demo_order_model.dart';

abstract class OrderRepository {
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
  });

  Future<List<DemoOrder>> loadDemoOrders();
}
