import 'package:uhd/models/pharmacy_filter_model.dart';
import 'package:uhd/models/pharmacy_model.dart';

abstract class PharmacyRepository {
  Future<List<Pharmacy>> loadPharmacies();
  void clearCache();
  Pharmacy? findById(List<Pharmacy> pharmacies, String id);
  List<Pharmacy> findPharmaciesWithMedicine(
    List<Pharmacy> pharmacies,
    String medicineId, {
    int limit = 10,
  });
  List<Pharmacy> queryPharmacies(
    List<Pharmacy> pharmacies,
    PharmacyFilter filter,
  );
  List<String> availableCities(List<Pharmacy> pharmacies);
  List<String> availableAreas(List<Pharmacy> pharmacies, String city);
  List<String> availableServices(List<Pharmacy> pharmacies);
  List<String> availablePaymentMethods(List<Pharmacy> pharmacies);
  List<String> availableInventoryCategories(Pharmacy pharmacy);
  List<String> availableInventoryForms(Pharmacy pharmacy);
}
