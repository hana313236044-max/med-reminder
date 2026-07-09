class OpeningHours {
  final String saturday;
  final String sunday;
  final String monday;
  final String tuesday;
  final String wednesday;
  final String thursday;
  final String friday;

  const OpeningHours({
    this.saturday = 'Not provided',
    this.sunday = 'Not provided',
    this.monday = 'Not provided',
    this.tuesday = 'Not provided',
    this.wednesday = 'Not provided',
    this.thursday = 'Not provided',
    this.friday = 'Not provided',
  });

  factory OpeningHours.fromJson(Map<String, dynamic>? json) {
    final data = json ?? const {};
    return OpeningHours(
      saturday: _string(data['saturday']),
      sunday: _string(data['sunday']),
      monday: _string(data['monday']),
      tuesday: _string(data['tuesday']),
      wednesday: _string(data['wednesday']),
      thursday: _string(data['thursday']),
      friday: _string(data['friday']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'saturday': saturday,
      'sunday': sunday,
      'monday': monday,
      'tuesday': tuesday,
      'wednesday': wednesday,
      'thursday': thursday,
      'friday': friday,
    };
  }

  List<MapEntry<String, String>> get entries {
    return [
      MapEntry('Saturday', saturday),
      MapEntry('Sunday', sunday),
      MapEntry('Monday', monday),
      MapEntry('Tuesday', tuesday),
      MapEntry('Wednesday', wednesday),
      MapEntry('Thursday', thursday),
      MapEntry('Friday', friday),
    ];
  }

  String get summary => saturday;

  static String _string(dynamic value, {String fallback = 'Not provided'}) {
    final parsed = value?.toString().trim() ?? '';
    return parsed.isEmpty ? fallback : parsed;
  }
}

class PharmacyInventoryItem {
  final String medicineId;
  final String medicineName;
  final String genericName;
  final String category;
  final String form;
  final String strength;
  final String brand;
  final int price;
  final String currency;
  final bool inStock;
  final int stockQuantity;
  final bool requiresPrescription;

  const PharmacyInventoryItem({
    required this.medicineId,
    required this.medicineName,
    required this.genericName,
    required this.category,
    required this.form,
    required this.strength,
    required this.brand,
    required this.price,
    required this.currency,
    required this.inStock,
    required this.stockQuantity,
    required this.requiresPrescription,
  });

  factory PharmacyInventoryItem.fromJson(Map<String, dynamic> json) {
    return PharmacyInventoryItem(
      medicineId: _string(json['medicineId']),
      medicineName: _string(json['medicineName'], fallback: 'Unnamed medicine'),
      genericName: _string(json['genericName']),
      category: _string(json['category']),
      form: _string(json['form']),
      strength: _string(json['strength']),
      brand: _string(json['brand']),
      price: _int(json['price']),
      currency: _string(json['currency'], fallback: 'IQD'),
      inStock: _bool(json['inStock']),
      stockQuantity: _int(json['stockQuantity']),
      requiresPrescription: _bool(json['requiresPrescription']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'medicineId': medicineId,
      'medicineName': medicineName,
      'genericName': genericName,
      'category': category,
      'form': form,
      'strength': strength,
      'brand': brand,
      'price': price,
      'currency': currency,
      'inStock': inStock,
      'stockQuantity': stockQuantity,
      'requiresPrescription': requiresPrescription,
    };
  }

  String get searchableText {
    return [
      medicineId,
      medicineName,
      genericName,
      category,
      form,
      strength,
      brand,
    ].join(' ').toLowerCase();
  }

  String get priceLabel => '${formatPrice(price)} $currency';

  static String formatPrice(int value) {
    final text = value.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < text.length; i++) {
      final fromEnd = text.length - i;
      buffer.write(text[i]);
      if (fromEnd > 1 && fromEnd % 3 == 1) {
        buffer.write(',');
      }
    }
    return buffer.toString();
  }

  static String _string(dynamic value, {String fallback = 'Not provided'}) {
    final parsed = value?.toString().trim() ?? '';
    return parsed.isEmpty ? fallback : parsed;
  }

  static int _int(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static bool _bool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    final normalized = value?.toString().trim().toLowerCase() ?? '';
    return normalized == 'true' ||
        normalized == 'yes' ||
        normalized == 'required';
  }
}

class Pharmacy {
  final String id;
  final String name;
  final String city;
  final String area;
  final String address;
  final String phone;
  final String secondaryPhone;
  final String email;
  final OpeningHours openingHours;
  final bool isOpen24Hours;
  final bool deliveryAvailable;
  final bool pickupAvailable;
  final double rating;
  final int reviewCount;
  final double latitude;
  final double longitude;
  final List<String> services;
  final List<String> paymentMethods;
  final String notes;
  final List<PharmacyInventoryItem> inventory;

  const Pharmacy({
    required this.id,
    required this.name,
    required this.city,
    required this.area,
    required this.address,
    required this.phone,
    required this.secondaryPhone,
    required this.email,
    required this.openingHours,
    required this.isOpen24Hours,
    required this.deliveryAvailable,
    required this.pickupAvailable,
    required this.rating,
    required this.reviewCount,
    required this.latitude,
    required this.longitude,
    required this.services,
    required this.paymentMethods,
    required this.notes,
    required this.inventory,
  });

  factory Pharmacy.fromJson(Map<String, dynamic> json) {
    return Pharmacy(
      id: _string(json['id']),
      name: _string(json['name'], fallback: 'Unnamed pharmacy'),
      city: _string(json['city']),
      area: _string(json['area']),
      address: _string(json['address']),
      phone: _string(json['phone']),
      secondaryPhone: _string(json['secondaryPhone']),
      email: _string(json['email']),
      openingHours: OpeningHours.fromJson(
        json['openingHours'] is Map
            ? Map<String, dynamic>.from(json['openingHours'] as Map)
            : null,
      ),
      isOpen24Hours: _bool(json['isOpen24Hours']),
      deliveryAvailable: _bool(json['deliveryAvailable']),
      pickupAvailable: _bool(json['pickupAvailable']),
      rating: _double(json['rating']),
      reviewCount: _int(json['reviewCount']),
      latitude: _double(json['latitude']),
      longitude: _double(json['longitude']),
      services: _stringList(json['services']),
      paymentMethods: _stringList(json['paymentMethods']),
      notes: _string(json['notes']),
      inventory: _inventoryList(json['inventory']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'city': city,
      'area': area,
      'address': address,
      'phone': phone,
      'secondaryPhone': secondaryPhone,
      'email': email,
      'openingHours': openingHours.toJson(),
      'isOpen24Hours': isOpen24Hours,
      'deliveryAvailable': deliveryAvailable,
      'pickupAvailable': pickupAvailable,
      'rating': rating,
      'reviewCount': reviewCount,
      'latitude': latitude,
      'longitude': longitude,
      'services': services,
      'paymentMethods': paymentMethods,
      'notes': notes,
      'inventory': inventory.map((item) => item.toJson()).toList(),
    };
  }

  int get availableMedicineCount {
    return inventory
        .where((item) => item.inStock && item.stockQuantity > 0)
        .length;
  }

  bool get hasPrescriptionMedicines {
    return inventory.any((item) => item.requiresPrescription);
  }

  bool get hasNoPrescriptionMedicines {
    return inventory.any((item) => !item.requiresPrescription);
  }

  bool get hasInStockMedicine {
    return inventory.any((item) => item.inStock && item.stockQuantity > 0);
  }

  String get searchableText {
    return [
      id,
      name,
      city,
      area,
      address,
      phone,
      secondaryPhone,
      email,
      notes,
      ...services,
      ...paymentMethods,
      ...inventory.expand(
        (item) => [
          item.medicineId,
          item.medicineName,
          item.genericName,
          item.brand,
          item.category,
          item.form,
          item.strength,
        ],
      ),
    ].join(' ').toLowerCase();
  }

  List<PharmacyInventoryItem> inStockByMedicineId(String medicineId) {
    final normalized = medicineId.trim().toLowerCase();
    return inventory
        .where(
          (item) =>
              item.medicineId.toLowerCase() == normalized &&
              item.inStock &&
              item.stockQuantity > 0,
        )
        .toList();
  }

  static List<PharmacyInventoryItem> _inventoryList(dynamic value) {
    if (value is! List) return const [];
    final items = <PharmacyInventoryItem>[];
    for (final item in value) {
      if (item is! Map) continue;
      try {
        items.add(PharmacyInventoryItem.fromJson(Map<String, dynamic>.from(item)));
      } catch (_) {
        continue;
      }
    }
    return items;
  }

  static List<String> _stringList(dynamic value) {
    if (value is List) {
      return value
          .map((item) => item?.toString().trim() ?? '')
          .where((item) => item.isNotEmpty)
          .toList();
    }
    if (value is String && value.trim().isNotEmpty) return [value.trim()];
    return const [];
  }

  static String _string(dynamic value, {String fallback = 'Not provided'}) {
    final parsed = value?.toString().trim() ?? '';
    return parsed.isEmpty ? fallback : parsed;
  }

  static int _int(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static double _double(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static bool _bool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    final normalized = value?.toString().trim().toLowerCase() ?? '';
    return normalized == 'true' ||
        normalized == 'yes' ||
        normalized == 'available';
  }
}
