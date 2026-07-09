import 'package:flutter/material.dart';
import 'package:uhd/l10n/pharmacy_localizations.dart';
import 'package:uhd/models/pharmacy_model.dart';
import 'package:uhd/widgets/app_widgets.dart';

enum PharmacyInventoryPrescriptionFilter {
  all,
  prescriptionRequired,
  noPrescriptionRequired,
}

class PharmacyInventoryList extends StatefulWidget {
  final Pharmacy pharmacy;
  final void Function(PharmacyInventoryItem item) onAddToCart;

  const PharmacyInventoryList({
    super.key,
    required this.pharmacy,
    required this.onAddToCart,
  });

  @override
  State<PharmacyInventoryList> createState() => _PharmacyInventoryListState();
}

class _PharmacyInventoryListState extends State<PharmacyInventoryList> {
  final TextEditingController _searchController = TextEditingController();
  String _searchText = '';
  String? _category;
  String? _form;
  bool _inStockOnly = false;
  PharmacyInventoryPrescriptionFilter _prescriptionFilter =
      PharmacyInventoryPrescriptionFilter.all;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = PharmacyStrings.of(context);
    final categories = _unique(widget.pharmacy.inventory.map((i) => i.category));
    final forms = _unique(widget.pharmacy.inventory.map((i) => i.form));
    final results = _filteredInventory;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: appSurfaceColor(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: appBorderColor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.medication_outlined, color: authPrimary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  strings.t(PharmacyTextKey.medicineList),
                  style: TextStyle(
                    color: appTextColor(context),
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _searchController,
            onChanged: (value) => setState(() => _searchText = value),
            decoration: authInputDecoration(
              context: context,
              hintText: strings.t(PharmacyTextKey.medicineSearchHint),
              icon: Icons.search,
              suffixIcon: _searchController.text.isEmpty
                  ? null
                  : IconButton(
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchText = '');
                      },
                      icon: const Icon(Icons.close),
                    ),
            ),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final twoColumns = constraints.maxWidth >= 640;
              final controls = [
                _NullableDropdown<String>(
                  label: strings.t(PharmacyTextKey.allCategories),
                  value: _category,
                  options: categories,
                  onChanged: (value) => setState(() => _category = value),
                ),
                _NullableDropdown<String>(
                  label: strings.t(PharmacyTextKey.allForms),
                  value: _form,
                  options: forms,
                  onChanged: (value) => setState(() => _form = value),
                ),
                _EnumDropdown<PharmacyInventoryPrescriptionFilter>(
                  value: _prescriptionFilter,
                  options: PharmacyInventoryPrescriptionFilter.values,
                  optionLabel: (value) => _prescriptionLabel(strings, value),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _prescriptionFilter = value);
                    }
                  },
                ),
                CheckboxListTile(
                  value: _inStockOnly,
                  contentPadding: EdgeInsets.zero,
                  activeColor: authPrimary,
                  title: Text(
                    strings.t(PharmacyTextKey.inStockOnly),
                    style: TextStyle(
                      color: appTextColor(context),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  controlAffinity: ListTileControlAffinity.leading,
                  onChanged: (value) {
                    setState(() => _inStockOnly = value ?? false);
                  },
                ),
              ];
              if (!twoColumns) {
                return Column(
                  children: controls
                      .map(
                        (control) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: control,
                        ),
                      )
                      .toList(),
                );
              }
              return Wrap(
                spacing: 10,
                runSpacing: 10,
                children: controls
                    .map(
                      (control) => SizedBox(
                        width: (constraints.maxWidth - 10) / 2,
                        child: control,
                      ),
                    )
                    .toList(),
              );
            },
          ),
          const SizedBox(height: 12),
          if (widget.pharmacy.inventory.isEmpty)
            _EmptyInventory(message: strings.t(PharmacyTextKey.inventoryEmpty))
          else if (results.isEmpty)
            _EmptyInventory(
              message: strings.t(PharmacyTextKey.inventoryNoMatches),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final count = constraints.maxWidth >= 760 ? 2 : 1;
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: results.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: count,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    mainAxisExtent: 270,
                  ),
                  itemBuilder: (context, index) {
                    final item = results[index];
                    return _InventoryItemCard(
                      item: item,
                      onAddToCart: () => widget.onAddToCart(item),
                    );
                  },
                );
              },
            ),
        ],
      ),
    );
  }

  List<PharmacyInventoryItem> get _filteredInventory {
    final terms = _searchText
        .trim()
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((term) => term.isNotEmpty)
        .toList();
    return widget.pharmacy.inventory.where((item) {
      if (terms.isNotEmpty &&
          !terms.every((term) => item.searchableText.contains(term))) {
        return false;
      }
      if (_category != null && item.category != _category) return false;
      if (_form != null && item.form != _form) return false;
      if (_inStockOnly && (!item.inStock || item.stockQuantity <= 0)) {
        return false;
      }
      switch (_prescriptionFilter) {
        case PharmacyInventoryPrescriptionFilter.all:
          return true;
        case PharmacyInventoryPrescriptionFilter.prescriptionRequired:
          return item.requiresPrescription;
        case PharmacyInventoryPrescriptionFilter.noPrescriptionRequired:
          return !item.requiresPrescription;
      }
    }).toList();
  }

  List<String> _unique(Iterable<String> values) {
    final unique = values
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty && value != 'Not provided')
        .toSet()
        .toList();
    unique.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return unique;
  }

  String _prescriptionLabel(
    PharmacyStrings strings,
    PharmacyInventoryPrescriptionFilter value,
  ) {
    switch (value) {
      case PharmacyInventoryPrescriptionFilter.all:
        return strings.t(PharmacyTextKey.allMedicines);
      case PharmacyInventoryPrescriptionFilter.prescriptionRequired:
        return strings.t(PharmacyTextKey.prescriptionRequired);
      case PharmacyInventoryPrescriptionFilter.noPrescriptionRequired:
        return strings.t(PharmacyTextKey.noPrescriptionRequired);
    }
  }
}

class _InventoryItemCard extends StatelessWidget {
  final PharmacyInventoryItem item;
  final VoidCallback onAddToCart;

  const _InventoryItemCard({
    required this.item,
    required this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    final strings = PharmacyStrings.of(context);
    final stockAvailable = item.inStock && item.stockQuantity > 0;
    final canAddToCart = stockAvailable && !item.requiresPrescription;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: appSoftSurfaceColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: appBorderColor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.medicineName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: appTextColor(context),
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${strings.t(PharmacyTextKey.generic)}: ${item.genericName}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: appMutedTextColor(context),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${item.brand} - ${item.form} - ${item.strength}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: appTextColor(context),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Badge(
                label: item.priceLabel,
                icon: Icons.payments_outlined,
                color: authPrimary,
              ),
              _Badge(
                label: stockAvailable
                    ? strings.t(PharmacyTextKey.inStock)
                    : strings.t(PharmacyTextKey.outOfStock),
                icon: stockAvailable
                    ? Icons.check_circle_outline
                    : Icons.highlight_off,
                color: stockAvailable ? authPrimary : Colors.redAccent,
              ),
              _Badge(
                label:
                    '${strings.t(PharmacyTextKey.stockQuantity)}: ${item.stockQuantity}',
                icon: Icons.inventory_2_outlined,
                color: authPrimary,
              ),
              if (item.requiresPrescription)
                _Badge(
                  label: strings.t(PharmacyTextKey.prescriptionRequired),
                  icon: Icons.assignment_outlined,
                color: Colors.orange.shade700,
              ),
            ],
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor:
                    canAddToCart ? authPrimary : appMutedTextColor(context),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: canAddToCart ? onAddToCart : null,
              icon: const Icon(Icons.add_shopping_cart),
              label: Text(
                item.requiresPrescription
                    ? strings.t(PharmacyTextKey.prescriptionRequired)
                    : strings.t(PharmacyTextKey.addToCart),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;

  const _Badge({
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(appIsDark(context) ? 0.18 : 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w900,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyInventory extends StatelessWidget {
  final String message;

  const _EmptyInventory({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: appTintSurfaceColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: appBorderColor(context)),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: appMutedTextColor(context),
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _NullableDropdown<T> extends StatelessWidget {
  final String label;
  final T? value;
  final List<T> options;
  final ValueChanged<T?> onChanged;

  const _NullableDropdown({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T?>(
      value: value,
      isExpanded: true,
      decoration: authInputDecoration(
        context: context,
        hintText: label,
        icon: Icons.filter_list,
      ),
      items: [
        DropdownMenuItem<T?>(
          value: null,
          child: Text(label, overflow: TextOverflow.ellipsis),
        ),
        ...options.map(
          (option) => DropdownMenuItem<T?>(
            value: option,
            child: Text(option.toString(), overflow: TextOverflow.ellipsis),
          ),
        ),
      ],
      onChanged: onChanged,
    );
  }
}

class _EnumDropdown<T> extends StatelessWidget {
  final T value;
  final List<T> options;
  final String Function(T) optionLabel;
  final ValueChanged<T?> onChanged;

  const _EnumDropdown({
    required this.value,
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
        hintText: PharmacyStrings.of(context).t(PharmacyTextKey.prescription),
        icon: Icons.assignment_outlined,
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
