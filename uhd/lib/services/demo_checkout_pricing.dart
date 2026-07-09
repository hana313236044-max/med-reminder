class DemoCheckoutPricing {
  const DemoCheckoutPricing._();

  static const int deliveryFee = 2000;

  static int totalWithDelivery(int subtotal) => subtotal + deliveryFee;
}
