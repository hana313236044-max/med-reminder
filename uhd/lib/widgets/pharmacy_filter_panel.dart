import 'package:flutter/material.dart';
import 'package:uhd/l10n/pharmacy_localizations.dart';
import 'package:uhd/models/pharmacy_filter_model.dart';
import 'package:uhd/widgets/app_widgets.dart';

class PharmacyFilterPanel extends StatelessWidget {
  final PharmacyFilter filter;
  final List<String> cities;
  final List<String> areas;
  final List<String> services;
  final List<String> paymentMethods;
  final ValueChanged<PharmacyFilter> onChanged;
  final VoidCallback onReset;
  final bool framed;

  const PharmacyFilterPanel({
    super.key,
    required this.filter,
    required this.cities,
    required this.areas,
    required this.services,
    required this.paymentMethods,
    required this.onChanged,
    required this.onReset,
    this.framed = true,
  });

  @override
  Widget build(BuildContext context) {
    final strings = PharmacyStrings.of(context);
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                strings.t(PharmacyTextKey.filters),
                style: TextStyle(
                  color: appTextColor(context),
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            TextButton.icon(
              onPressed: onReset,
              icon: const Icon(Icons.restart_alt, size: 18),
              label: Text(strings.t(PharmacyTextKey.resetFilters)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _NullableDropdown<String>(
          label: strings.t(PharmacyTextKey.city),
          hint: strings.t(PharmacyTextKey.allCities),
          value: filter.city,
          icon: Icons.location_city_outlined,
          options: cities,
          optionLabel: (value) => value,
          onChanged: (city) {
            onChanged(filter.copyWith(city: city, area: null));
          },
        ),
        const SizedBox(height: 12),
        _NullableDropdown<String>(
          label: strings.t(PharmacyTextKey.area),
          hint: strings.t(PharmacyTextKey.allAreas),
          value: filter.area,
          icon: Icons.place_outlined,
          options: areas,
          enabled: filter.city != null,
          optionLabel: (value) => value,
          onChanged: (area) => onChanged(filter.copyWith(area: area)),
        ),
        const SizedBox(height: 12),
        _EnumDropdown<PharmacyDeliveryFilter>(
          label: strings.t(PharmacyTextKey.delivery),
          value: filter.deliveryFilter,
          icon: Icons.delivery_dining_outlined,
          options: PharmacyDeliveryFilter.values,
          optionLabel: strings.deliveryFilterLabel,
          onChanged: (value) {
            if (value != null) onChanged(filter.copyWith(deliveryFilter: value));
          },
        ),
        const SizedBox(height: 12),
        _EnumDropdown<PharmacyOpenFilter>(
          label: strings.t(PharmacyTextKey.open24Hours),
          value: filter.openFilter,
          icon: Icons.schedule_outlined,
          options: PharmacyOpenFilter.values,
          optionLabel: strings.openFilterLabel,
          onChanged: (value) {
            if (value != null) onChanged(filter.copyWith(openFilter: value));
          },
        ),
        const SizedBox(height: 12),
        _EnumDropdown<PharmacyMedicineAvailabilityFilter>(
          label: strings.t(PharmacyTextKey.medicineAvailability),
          value: filter.medicineAvailabilityFilter,
          icon: Icons.medication_outlined,
          options: PharmacyMedicineAvailabilityFilter.values,
          optionLabel: strings.availabilityFilterLabel,
          onChanged: (value) {
            if (value != null) {
              onChanged(filter.copyWith(medicineAvailabilityFilter: value));
            }
          },
        ),
        const SizedBox(height: 12),
        _EnumDropdown<PharmacyPrescriptionFilter>(
          label: strings.t(PharmacyTextKey.prescription),
          value: filter.prescriptionFilter,
          icon: Icons.assignment_outlined,
          options: PharmacyPrescriptionFilter.values,
          optionLabel: strings.prescriptionFilterLabel,
          onChanged: (value) {
            if (value != null) {
              onChanged(filter.copyWith(prescriptionFilter: value));
            }
          },
        ),
        const SizedBox(height: 12),
        _NullableDropdown<String>(
          label: strings.t(PharmacyTextKey.services),
          hint: strings.t(PharmacyTextKey.allServices),
          value: filter.service,
          icon: Icons.medical_services_outlined,
          options: services,
          optionLabel: (value) => value,
          onChanged: (value) => onChanged(filter.copyWith(service: value)),
        ),
        const SizedBox(height: 12),
        _NullableDropdown<String>(
          label: strings.t(PharmacyTextKey.paymentMethods),
          hint: strings.t(PharmacyTextKey.allPaymentMethods),
          value: filter.paymentMethod,
          icon: Icons.payments_outlined,
          options: paymentMethods,
          optionLabel: (value) => value,
          onChanged: (value) =>
              onChanged(filter.copyWith(paymentMethod: value)),
        ),
        const SizedBox(height: 12),
        _EnumDropdown<PharmacySort>(
          label: strings.t(PharmacyTextKey.sortBy),
          value: filter.sort,
          icon: Icons.sort_by_alpha,
          options: PharmacySort.values,
          optionLabel: strings.sortLabel,
          onChanged: (value) {
            if (value != null) onChanged(filter.copyWith(sort: value));
          },
        ),
      ],
    );

    if (!framed) return content;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: appSurfaceColor(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: appBorderColor(context)),
      ),
      child: content,
    );
  }
}

class _NullableDropdown<T> extends StatelessWidget {
  final String label;
  final String hint;
  final T? value;
  final IconData icon;
  final List<T> options;
  final String Function(T) optionLabel;
  final ValueChanged<T?> onChanged;
  final bool enabled;

  const _NullableDropdown({
    required this.label,
    required this.hint,
    required this.value,
    required this.icon,
    required this.options,
    required this.optionLabel,
    required this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T?>(
      value: enabled ? value : null,
      isExpanded: true,
      decoration: authInputDecoration(
        context: context,
        hintText: label,
        icon: icon,
      ),
      items: [
        DropdownMenuItem<T?>(
          value: null,
          child: Text(hint, overflow: TextOverflow.ellipsis),
        ),
        ...options.map(
          (option) => DropdownMenuItem<T?>(
            value: option,
            child: Text(optionLabel(option), overflow: TextOverflow.ellipsis),
          ),
        ),
      ],
      onChanged: enabled ? onChanged : null,
    );
  }
}

class _EnumDropdown<T> extends StatelessWidget {
  final String label;
  final T value;
  final IconData icon;
  final List<T> options;
  final String Function(T) optionLabel;
  final ValueChanged<T?> onChanged;

  const _EnumDropdown({
    required this.label,
    required this.value,
    required this.icon,
    required this.options,
    required this.optionLabel,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      value: value,
      isExpanded: true,
      decoration: authInputDecoration(
        context: context,
        hintText: label,
        icon: icon,
      ),
      items: options
          .map(
            (option) => DropdownMenuItem<T>(
              value: option,
              child: Text(optionLabel(option), overflow: TextOverflow.ellipsis),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }
}
