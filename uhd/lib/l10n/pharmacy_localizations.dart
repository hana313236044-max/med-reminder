import 'package:flutter/widgets.dart';
import 'package:uhd/models/pharmacy_filter_model.dart';

enum PharmacyTextKey {
  title,
  subtitle,
  disclaimer,
  searchHint,
  medicineStoreSearchHint,
  filters,
  city,
  allCities,
  area,
  allAreas,
  delivery,
  all,
  deliveryAvailable,
  open24Hours,
  not24Hours,
  medicineAvailability,
  allPharmacies,
  hasSelectedMedicine,
  hasMedicinesInStock,
  prescription,
  allMedicines,
  prescriptionAvailable,
  noPrescriptionAvailable,
  services,
  allServices,
  paymentMethods,
  allPaymentMethods,
  sortBy,
  nameAz,
  nameZa,
  highestRating,
  mostMedicinesAvailable,
  deliveryFirst,
  sortCity,
  sortArea,
  resetFilters,
  loading,
  errorTitle,
  retry,
  emptyPharmacies,
  emptyFiltersTitle,
  emptyFiltersMessage,
  pharmacyNotFound,
  pharmacyDetails,
  backToPharmacies,
  viewDetails,
  viewPharmacy,
  rating,
  reviews,
  medicinesAvailable,
  pickupAvailable,
  pickupUnavailable,
  notAvailable,
  storeInformation,
  address,
  phone,
  secondaryPhone,
  email,
  openingHours,
  notes,
  medicineList,
  medicineSearchHint,
  inventoryEmpty,
  inventoryNoMatches,
  allCategories,
  allForms,
  inStockOnly,
  prescriptionRequired,
  noPrescriptionRequired,
  generic,
  brand,
  price,
  inStock,
  outOfStock,
  addToCart,
  cart,
  viewCart,
  emptyCartTitle,
  emptyCartMessage,
  clearCart,
  checkout,
  total,
  remove,
  quantity,
  stockQuantity,
  unitPrice,
  itemSubtotal,
  subtotal,
  deliveryFee,
  orderTotal,
  otherPharmacyCartTitle,
  otherPharmacyCartMessage,
  cancel,
  clearAndAdd,
  prescriptionWarning,
  prescriptionAddDisabled,
  addedToCart,
  maxStockReached,
  checkoutTitle,
  checkoutError,
  placingOrder,
  fullName,
  phoneNumber,
  fulfillmentMethod,
  deliveryAddress,
  optionalNotes,
  paymentMethod,
  cardDetails,
  cardholderName,
  cardNumber,
  cardExpiry,
  cardCvv,
  cardNumberInvalid,
  cardExpiryInvalid,
  cardCvvInvalid,
  deliveryOption,
  pickupOption,
  demoOrderNotice,
  placeDemoOrder,
  requiredField,
  successTitle,
  successMessage,
  orderId,
  ok,
  backToCart,
  availableAtPharmacies,
  noPharmaciesForMedicine,
}

class PharmacyStrings {
  final String language;

  const PharmacyStrings._(this.language);

  static PharmacyStrings of(BuildContext context) {
    final localeCode = Localizations.maybeLocaleOf(context)?.languageCode;
    if (localeCode == 'ar') return const PharmacyStrings._('Arabic');
    if (localeCode == 'ku') return const PharmacyStrings._('Kurdish');
    return const PharmacyStrings._('English');
  }

  static const Map<PharmacyTextKey, String> _english = {
    PharmacyTextKey.title: 'Pharmacies',
    PharmacyTextKey.subtitle:
        'Find pharmacies by city, area, medicine, or store name.',
    PharmacyTextKey.disclaimer:
        'Demo information only. Pharmacy availability and prices are sample data and may not be real.',
    PharmacyTextKey.searchHint: 'Search by store name',
    PharmacyTextKey.medicineStoreSearchHint:
        'Search medicines sold by pharmacies',
    PharmacyTextKey.filters: 'Filters',
    PharmacyTextKey.city: 'City',
    PharmacyTextKey.allCities: 'All cities',
    PharmacyTextKey.area: 'Area',
    PharmacyTextKey.allAreas: 'All areas',
    PharmacyTextKey.delivery: 'Delivery',
    PharmacyTextKey.all: 'All',
    PharmacyTextKey.deliveryAvailable: 'Delivery available',
    PharmacyTextKey.open24Hours: 'Open 24 hours',
    PharmacyTextKey.not24Hours: 'Not 24 hours',
    PharmacyTextKey.medicineAvailability: 'Medicine availability',
    PharmacyTextKey.allPharmacies: 'All pharmacies',
    PharmacyTextKey.hasSelectedMedicine: 'Has selected medicine',
    PharmacyTextKey.hasMedicinesInStock: 'Has medicines in stock',
    PharmacyTextKey.prescription: 'Prescription',
    PharmacyTextKey.allMedicines: 'All medicines',
    PharmacyTextKey.prescriptionAvailable:
        'Prescription medicines available',
    PharmacyTextKey.noPrescriptionAvailable:
        'No prescription medicines available',
    PharmacyTextKey.services: 'Services',
    PharmacyTextKey.allServices: 'All services',
    PharmacyTextKey.paymentMethods: 'Payment methods',
    PharmacyTextKey.allPaymentMethods: 'All payment methods',
    PharmacyTextKey.sortBy: 'Sort by',
    PharmacyTextKey.nameAz: 'Name A to Z',
    PharmacyTextKey.nameZa: 'Name Z to A',
    PharmacyTextKey.highestRating: 'Highest rating',
    PharmacyTextKey.mostMedicinesAvailable: 'Most medicines available',
    PharmacyTextKey.deliveryFirst: 'Delivery first',
    PharmacyTextKey.sortCity: 'City',
    PharmacyTextKey.sortArea: 'Area',
    PharmacyTextKey.resetFilters: 'Reset Filters',
    PharmacyTextKey.loading: 'Loading pharmacies...',
    PharmacyTextKey.errorTitle: 'Could not load pharmacies.',
    PharmacyTextKey.retry: 'Retry',
    PharmacyTextKey.emptyPharmacies: 'No pharmacies are available yet.',
    PharmacyTextKey.emptyFiltersTitle:
        'No pharmacies match your search and filters.',
    PharmacyTextKey.emptyFiltersMessage:
        'Try changing the city, area, or search text.',
    PharmacyTextKey.pharmacyNotFound: 'Pharmacy not found.',
    PharmacyTextKey.pharmacyDetails: 'Pharmacy details',
    PharmacyTextKey.backToPharmacies: 'Back to Pharmacies',
    PharmacyTextKey.viewDetails: 'View Details',
    PharmacyTextKey.viewPharmacy: 'View Pharmacy',
    PharmacyTextKey.rating: 'Rating',
    PharmacyTextKey.reviews: 'reviews',
    PharmacyTextKey.medicinesAvailable: 'medicines available',
    PharmacyTextKey.pickupAvailable: 'Pickup available',
    PharmacyTextKey.pickupUnavailable: 'Pickup unavailable',
    PharmacyTextKey.notAvailable: 'Not available',
    PharmacyTextKey.storeInformation: 'Store information',
    PharmacyTextKey.address: 'Address',
    PharmacyTextKey.phone: 'Phone',
    PharmacyTextKey.secondaryPhone: 'Secondary phone',
    PharmacyTextKey.email: 'Email',
    PharmacyTextKey.openingHours: 'Opening hours',
    PharmacyTextKey.notes: 'Notes',
    PharmacyTextKey.medicineList: 'Medicine list',
    PharmacyTextKey.medicineSearchHint:
        'Search medicines by name, generic, brand, category, strength, or form',
    PharmacyTextKey.inventoryEmpty:
        'This pharmacy has no listed medicines.',
    PharmacyTextKey.inventoryNoMatches:
        'No medicines match these filters.',
    PharmacyTextKey.allCategories: 'All categories',
    PharmacyTextKey.allForms: 'All forms',
    PharmacyTextKey.inStockOnly: 'In stock only',
    PharmacyTextKey.prescriptionRequired: 'Prescription required',
    PharmacyTextKey.noPrescriptionRequired: 'No prescription required',
    PharmacyTextKey.generic: 'Generic',
    PharmacyTextKey.brand: 'Brand',
    PharmacyTextKey.price: 'Price',
    PharmacyTextKey.inStock: 'In stock',
    PharmacyTextKey.outOfStock: 'Out of stock',
    PharmacyTextKey.addToCart: 'Add to cart',
    PharmacyTextKey.cart: 'Cart',
    PharmacyTextKey.viewCart: 'View cart',
    PharmacyTextKey.emptyCartTitle: 'Your cart is empty.',
    PharmacyTextKey.emptyCartMessage:
        'Add medicines from a pharmacy to begin a demo order.',
    PharmacyTextKey.clearCart: 'Clear cart',
    PharmacyTextKey.checkout: 'Checkout',
    PharmacyTextKey.total: 'Total',
    PharmacyTextKey.remove: 'Remove',
    PharmacyTextKey.quantity: 'Quantity',
    PharmacyTextKey.stockQuantity: 'Stock quantity',
    PharmacyTextKey.unitPrice: 'Unit price',
    PharmacyTextKey.itemSubtotal: 'Subtotal',
    PharmacyTextKey.subtotal: 'Subtotal',
    PharmacyTextKey.deliveryFee: 'Delivery fee',
    PharmacyTextKey.orderTotal: 'Order total',
    PharmacyTextKey.otherPharmacyCartTitle: 'Clear current cart?',
    PharmacyTextKey.otherPharmacyCartMessage:
        'Your cart contains items from another pharmacy. Clear the cart and add this item instead?',
    PharmacyTextKey.cancel: 'Cancel',
    PharmacyTextKey.clearAndAdd: 'Clear and add',
    PharmacyTextKey.prescriptionWarning:
        'This medicine is marked as prescription required. This demo app does not verify prescriptions.',
    PharmacyTextKey.prescriptionAddDisabled:
        'Prescription medicines cannot be added to the demo cart.',
    PharmacyTextKey.addedToCart: 'Added to cart.',
    PharmacyTextKey.maxStockReached: 'Quantity cannot exceed available stock.',
    PharmacyTextKey.checkoutTitle: 'Demo checkout',
    PharmacyTextKey.checkoutError:
        'Could not place the demo order. Please try again.',
    PharmacyTextKey.placingOrder: 'Placing...',
    PharmacyTextKey.fullName: 'Full name',
    PharmacyTextKey.phoneNumber: 'Phone number',
    PharmacyTextKey.fulfillmentMethod: 'Delivery or pickup',
    PharmacyTextKey.deliveryAddress: 'Delivery address',
    PharmacyTextKey.optionalNotes: 'Optional notes',
    PharmacyTextKey.paymentMethod: 'Payment method',
    PharmacyTextKey.cardDetails: 'Card details',
    PharmacyTextKey.cardholderName: 'Cardholder name',
    PharmacyTextKey.cardNumber: 'Card number',
    PharmacyTextKey.cardExpiry: 'Expiry date (MM/YY)',
    PharmacyTextKey.cardCvv: 'CVV',
    PharmacyTextKey.cardNumberInvalid: 'Enter a valid card number',
    PharmacyTextKey.cardExpiryInvalid: 'Use MM/YY',
    PharmacyTextKey.cardCvvInvalid: 'Enter a valid CVV',
    PharmacyTextKey.deliveryOption: 'Delivery',
    PharmacyTextKey.pickupOption: 'Pickup',
    PharmacyTextKey.demoOrderNotice:
        'This is a demo order. No real payment or pharmacy request will be sent.',
    PharmacyTextKey.placeDemoOrder: 'Place demo order',
    PharmacyTextKey.requiredField: 'Required',
    PharmacyTextKey.successTitle: 'Demo order placed successfully.',
    PharmacyTextKey.successMessage: 'Demo order placed successfully.',
    PharmacyTextKey.orderId: 'Order ID',
    PharmacyTextKey.ok: 'OK',
    PharmacyTextKey.backToCart: 'Back to cart',
    PharmacyTextKey.availableAtPharmacies: 'Available at Pharmacies',
    PharmacyTextKey.noPharmaciesForMedicine:
        'No pharmacies in the demo dataset currently list this medicine.',
  };

  static const Map<String, Map<PharmacyTextKey, String>> _values = {
    'English': _english,
    'Kurdish': _english,
    'Arabic': _english,
  };

  String t(PharmacyTextKey key) {
    return _values[language]?[key] ?? _english[key] ?? key.name;
  }

  String showingCount(int shown, int total) =>
      'Showing $shown of $total pharmacies';

  String deliveryFilterLabel(PharmacyDeliveryFilter value) {
    switch (value) {
      case PharmacyDeliveryFilter.all:
        return t(PharmacyTextKey.all);
      case PharmacyDeliveryFilter.deliveryAvailable:
        return t(PharmacyTextKey.deliveryAvailable);
    }
  }

  String openFilterLabel(PharmacyOpenFilter value) {
    switch (value) {
      case PharmacyOpenFilter.all:
        return t(PharmacyTextKey.all);
      case PharmacyOpenFilter.open24Hours:
        return t(PharmacyTextKey.open24Hours);
      case PharmacyOpenFilter.not24Hours:
        return t(PharmacyTextKey.not24Hours);
    }
  }

  String availabilityFilterLabel(PharmacyMedicineAvailabilityFilter value) {
    switch (value) {
      case PharmacyMedicineAvailabilityFilter.all:
        return t(PharmacyTextKey.allPharmacies);
      case PharmacyMedicineAvailabilityFilter.hasSelectedMedicine:
        return t(PharmacyTextKey.hasSelectedMedicine);
      case PharmacyMedicineAvailabilityFilter.hasMedicinesInStock:
        return t(PharmacyTextKey.hasMedicinesInStock);
    }
  }

  String prescriptionFilterLabel(PharmacyPrescriptionFilter value) {
    switch (value) {
      case PharmacyPrescriptionFilter.all:
        return t(PharmacyTextKey.allMedicines);
      case PharmacyPrescriptionFilter.prescriptionAvailable:
        return t(PharmacyTextKey.prescriptionAvailable);
      case PharmacyPrescriptionFilter.noPrescriptionAvailable:
        return t(PharmacyTextKey.noPrescriptionAvailable);
    }
  }

  String sortLabel(PharmacySort value) {
    switch (value) {
      case PharmacySort.nameAz:
        return t(PharmacyTextKey.nameAz);
      case PharmacySort.nameZa:
        return t(PharmacyTextKey.nameZa);
      case PharmacySort.highestRating:
        return t(PharmacyTextKey.highestRating);
      case PharmacySort.mostMedicinesAvailable:
        return t(PharmacyTextKey.mostMedicinesAvailable);
      case PharmacySort.deliveryFirst:
        return t(PharmacyTextKey.deliveryFirst);
      case PharmacySort.city:
        return t(PharmacyTextKey.sortCity);
      case PharmacySort.area:
        return t(PharmacyTextKey.sortArea);
    }
  }
}
