import 'dart:async';

import 'package:flutter/material.dart';
import 'package:uhd/l10n/pharmacy_localizations.dart';
import 'package:uhd/models/pharmacy_filter_model.dart';
import 'package:uhd/models/pharmacy_model.dart';
import 'package:uhd/services/cart_service.dart';
import 'package:uhd/services/json_pharmacy_repository.dart';
import 'package:uhd/services/pharmacy_repository.dart';
import 'package:uhd/widgets/app_widgets.dart';
import 'package:uhd/widgets/pharmacy_card.dart';
import 'package:uhd/widgets/pharmacy_filter_panel.dart';

class PharmaciesPage extends StatefulWidget {
  final ValueChanged<String> onPharmacySelected;

  const PharmaciesPage({
    super.key,
    required this.onPharmacySelected,
  });

  @override
  State<PharmaciesPage> createState() => _PharmaciesPageState();
}

class _PharmaciesPageState extends State<PharmaciesPage> {
  final PharmacyRepository _repository = JsonPharmacyRepository.instance;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _medicineSearchController =
      TextEditingController();

  late Future<List<Pharmacy>> _pharmacyFuture;
  PharmacyFilter _filter = const PharmacyFilter();
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _pharmacyFuture = _repository.loadPharmacies();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _medicineSearchController.dispose();
    super.dispose();
  }

  void _retry() {
    _repository.clearCache();
    setState(() => _pharmacyFuture = _repository.loadPharmacies());
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 140), () {
      if (!mounted) return;
      setState(() => _filter = _filter.copyWith(searchText: value));
    });
  }

  void _onMedicineSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 140), () {
      if (!mounted) return;
      setState(() => _filter = _filter.copyWith(medicineSearchText: value));
    });
  }

  void _clearStoreSearch() {
    _searchDebounce?.cancel();
    _searchController.clear();
    setState(() => _filter = _filter.copyWith(searchText: ''));
  }

  void _clearMedicineSearch() {
    _searchDebounce?.cancel();
    _medicineSearchController.clear();
    setState(() => _filter = _filter.copyWith(medicineSearchText: ''));
  }

  void _resetFilters() {
    _searchDebounce?.cancel();
    _searchController.clear();
    _medicineSearchController.clear();
    setState(() => _filter = const PharmacyFilter());
  }

  void _setFilter(PharmacyFilter filter, List<Pharmacy> pharmacies) {
    final area = filter.area;
    if (filter.city != null && area != null) {
      final areas = _repository.availableAreas(pharmacies, filter.city!);
      if (!areas.contains(area)) {
        filter = filter.copyWith(area: null);
      }
    }
    setState(() => _filter = filter);
  }

  @override
  Widget build(BuildContext context) {
    final strings = PharmacyStrings.of(context);
    return FutureBuilder<List<Pharmacy>>(
      future: _pharmacyFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _LoadingState(message: strings.t(PharmacyTextKey.loading));
        }
        if (snapshot.hasError) {
          return _ErrorState(onRetry: _retry);
        }
        final pharmacies = snapshot.data ?? const [];
        if (pharmacies.isEmpty) {
          return _EmptyState(
            icon: Icons.local_pharmacy_outlined,
            title: strings.t(PharmacyTextKey.emptyPharmacies),
            message: strings.t(PharmacyTextKey.disclaimer),
          );
        }

        return _PharmaciesContent(
          pharmacies: pharmacies,
          filter: _filter,
          repository: _repository,
          searchController: _searchController,
          medicineSearchController: _medicineSearchController,
          onSearchChanged: _onSearchChanged,
          onMedicineSearchChanged: _onMedicineSearchChanged,
          onClearStoreSearch: _clearStoreSearch,
          onClearMedicineSearch: _clearMedicineSearch,
          onFilterChanged: (filter) => _setFilter(filter, pharmacies),
          onResetFilters: _resetFilters,
          onPharmacySelected: widget.onPharmacySelected,
        );
      },
    );
  }
}

class _PharmaciesContent extends StatelessWidget {
  final List<Pharmacy> pharmacies;
  final PharmacyFilter filter;
  final PharmacyRepository repository;
  final TextEditingController searchController;
  final TextEditingController medicineSearchController;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onMedicineSearchChanged;
  final VoidCallback onClearStoreSearch;
  final VoidCallback onClearMedicineSearch;
  final ValueChanged<PharmacyFilter> onFilterChanged;
  final VoidCallback onResetFilters;
  final ValueChanged<String> onPharmacySelected;

  const _PharmaciesContent({
    required this.pharmacies,
    required this.filter,
    required this.repository,
    required this.searchController,
    required this.medicineSearchController,
    required this.onSearchChanged,
    required this.onMedicineSearchChanged,
    required this.onClearStoreSearch,
    required this.onClearMedicineSearch,
    required this.onFilterChanged,
    required this.onResetFilters,
    required this.onPharmacySelected,
  });

  @override
  Widget build(BuildContext context) {
    final strings = PharmacyStrings.of(context);
    final results = repository.queryPharmacies(pharmacies, filter);
    final cities = repository.availableCities(pharmacies);
    final areas = filter.city == null
        ? const <String>[]
        : repository.availableAreas(pharmacies, filter.city!);
    final services = repository.availableServices(pharmacies);
    final payments = repository.availablePaymentMethods(pharmacies);

    return LayoutBuilder(
      builder: (context, constraints) {
        final useSidePanel = constraints.maxWidth >= 920;
        return ListView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 104),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1240),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                strings.t(PharmacyTextKey.title),
                                style: TextStyle(
                                  color: appTextColor(context),
                                  fontSize: 28,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                strings.t(PharmacyTextKey.subtitle),
                                style: TextStyle(
                                  color: appMutedTextColor(context),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        _CartButton(),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _DisclaimerBanner(text: strings.t(PharmacyTextKey.disclaimer)),
                    const SizedBox(height: 16),
                    TextField(
                      controller: searchController,
                      onChanged: onSearchChanged,
                      decoration: authInputDecoration(
                        context: context,
                        hintText: strings.t(PharmacyTextKey.searchHint),
                        icon: Icons.search,
                        suffixIcon: searchController.text.isEmpty
                            ? null
                            : IconButton(
                                onPressed: onClearStoreSearch,
                                icon: const Icon(Icons.close),
                              ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: medicineSearchController,
                      onChanged: onMedicineSearchChanged,
                      decoration: authInputDecoration(
                        context: context,
                        hintText:
                            strings.t(PharmacyTextKey.medicineStoreSearchHint),
                        icon: Icons.medication_outlined,
                        suffixIcon: medicineSearchController.text.isEmpty
                            ? null
                            : IconButton(
                                onPressed: onClearMedicineSearch,
                                icon: const Icon(Icons.close),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (useSidePanel)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 320,
                            child: PharmacyFilterPanel(
                              filter: filter,
                              cities: cities,
                              areas: areas,
                              services: services,
                              paymentMethods: payments,
                              onChanged: onFilterChanged,
                              onReset: onResetFilters,
                            ),
                          ),
                          const SizedBox(width: 18),
                          Expanded(
                            child: _ResultsArea(
                              pharmacies: pharmacies,
                              results: results,
                              onPharmacySelected: onPharmacySelected,
                            ),
                          ),
                        ],
                      )
                    else ...[
                      _ExpandableFilters(
                        filter: filter,
                        cities: cities,
                        areas: areas,
                        services: services,
                        paymentMethods: payments,
                        onChanged: onFilterChanged,
                        onReset: onResetFilters,
                      ),
                      const SizedBox(height: 16),
                      _ResultsArea(
                        pharmacies: pharmacies,
                        results: results,
                        onPharmacySelected: onPharmacySelected,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ExpandableFilters extends StatelessWidget {
  final PharmacyFilter filter;
  final List<String> cities;
  final List<String> areas;
  final List<String> services;
  final List<String> paymentMethods;
  final ValueChanged<PharmacyFilter> onChanged;
  final VoidCallback onReset;

  const _ExpandableFilters({
    required this.filter,
    required this.cities,
    required this.areas,
    required this.services,
    required this.paymentMethods,
    required this.onChanged,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    final strings = PharmacyStrings.of(context);
    return Container(
      decoration: BoxDecoration(
        color: appSurfaceColor(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: appBorderColor(context)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          initiallyExpanded: filter.hasActiveFilters,
          leading: const Icon(Icons.tune, color: authPrimary),
          title: Text(
            strings.t(PharmacyTextKey.filters),
            style: TextStyle(
              color: appTextColor(context),
              fontWeight: FontWeight.w900,
            ),
          ),
          children: [
            PharmacyFilterPanel(
              filter: filter,
              cities: cities,
              areas: areas,
              services: services,
              paymentMethods: paymentMethods,
              onChanged: onChanged,
              onReset: onReset,
              framed: false,
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultsArea extends StatelessWidget {
  final List<Pharmacy> pharmacies;
  final List<Pharmacy> results;
  final ValueChanged<String> onPharmacySelected;

  const _ResultsArea({
    required this.pharmacies,
    required this.results,
    required this.onPharmacySelected,
  });

  @override
  Widget build(BuildContext context) {
    final strings = PharmacyStrings.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          strings.showingCount(results.length, pharmacies.length),
          style: TextStyle(
            color: appMutedTextColor(context),
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 12),
        if (results.isEmpty)
          _EmptyState(
            icon: Icons.search_off_outlined,
            title: strings.t(PharmacyTextKey.emptyFiltersTitle),
            message: strings.t(PharmacyTextKey.emptyFiltersMessage),
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final count = constraints.maxWidth >= 920
                  ? 3
                  : constraints.maxWidth >= 620
                  ? 2
                  : 1;
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: results.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: count,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  mainAxisExtent: 310,
                ),
                itemBuilder: (context, index) {
                  final pharmacy = results[index];
                  return PharmacyCard(
                    pharmacy: pharmacy,
                    onViewDetails: () => onPharmacySelected(pharmacy.id),
                  );
                },
              );
            },
          ),
      ],
    );
  }
}

class _CartButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final strings = PharmacyStrings.of(context);
    return AnimatedBuilder(
      animation: CartService.instance,
      builder: (context, _) {
        final cart = CartService.instance.cart;
        return Badge(
          isLabelVisible: cart.totalQuantity > 0,
          label: Text(cart.totalQuantity.toString()),
          child: IconButton.filled(
            tooltip: strings.t(PharmacyTextKey.viewCart),
            style: IconButton.styleFrom(backgroundColor: authPrimary),
            onPressed: () => Navigator.pushNamed(context, '/cart'),
            icon: const Icon(Icons.shopping_cart_outlined, color: Colors.white),
          ),
        );
      },
    );
  }
}

class _DisclaimerBanner extends StatelessWidget {
  final String text;

  const _DisclaimerBanner({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: appTintSurfaceColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: appBorderColor(context)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: authPrimary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: appTextColor(context),
                height: 1.35,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  final String message;

  const _LoadingState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: authPrimary),
          const SizedBox(height: 14),
          Text(
            message,
            style: TextStyle(
              color: appMutedTextColor(context),
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;

  const _ErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final strings = PharmacyStrings.of(context);
    return _EmptyState(
      icon: Icons.error_outline,
      title: strings.t(PharmacyTextKey.errorTitle),
      message: JsonPharmacyRepository.assetPath,
      action: FilledButton.icon(
        style: FilledButton.styleFrom(backgroundColor: authPrimary),
        onPressed: onRetry,
        icon: const Icon(Icons.refresh),
        label: Text(strings.t(PharmacyTextKey.retry)),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: appTintSurfaceColor(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: appBorderColor(context)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: authPrimary, size: 40),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: appTextColor(context),
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: appMutedTextColor(context),
              fontWeight: FontWeight.w700,
            ),
          ),
          if (action != null) ...[
            const SizedBox(height: 14),
            action!,
          ],
        ],
      ),
    );
  }
}
