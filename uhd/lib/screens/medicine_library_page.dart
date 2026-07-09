import 'dart:async';

import 'package:flutter/material.dart';
import 'package:uhd/l10n/medicine_library_localizations.dart';
import 'package:uhd/models/medicine_library_filter.dart';
import 'package:uhd/models/medicine_library_model.dart';
import 'package:uhd/services/medicine_library_repository.dart';
import 'package:uhd/widgets/app_widgets.dart';
import 'package:uhd/widgets/medicine_library_card.dart';
import 'package:uhd/widgets/medicine_library_filter_panel.dart';

class MedicineLibraryPage extends StatefulWidget {
  final ValueChanged<String> onMedicineSelected;

  const MedicineLibraryPage({
    super.key,
    required this.onMedicineSelected,
  });

  @override
  State<MedicineLibraryPage> createState() => _MedicineLibraryPageState();
}

class _MedicineLibraryPageState extends State<MedicineLibraryPage> {
  final MedicineLibraryRepository _repository =
      MedicineLibraryRepository.instance;
  final TextEditingController _searchController = TextEditingController();

  late Future<List<MedicineLibraryMedicine>> _medicineFuture;
  MedicineLibraryFilter _filter = const MedicineLibraryFilter();
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _medicineFuture = _repository.loadMedicines();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _retry() {
    _repository.clearCache();
    setState(() => _medicineFuture = _repository.loadMedicines());
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 140), () {
      if (!mounted) return;
      setState(() => _filter = _filter.copyWith(searchText: value));
    });
  }

  void _resetFilters() {
    _searchDebounce?.cancel();
    _searchController.clear();
    setState(() => _filter = const MedicineLibraryFilter());
  }

  @override
  Widget build(BuildContext context) {
    final strings = MedicineLibraryStrings.of(context);
    return FutureBuilder<List<MedicineLibraryMedicine>>(
      future: _medicineFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _LoadingState(message: strings.t(MedicineLibraryTextKey.loading));
        }
        if (snapshot.hasError) {
          return _ErrorState(onRetry: _retry);
        }

        final medicines = snapshot.data ?? const [];
        if (medicines.isEmpty) {
          return _EmptyState(
            icon: Icons.local_library_outlined,
            title: strings.t(MedicineLibraryTextKey.emptyLibrary),
            message: strings.t(MedicineLibraryTextKey.disclaimerShort),
          );
        }

        return _LibraryContent(
          medicines: medicines,
          filter: _filter,
          searchController: _searchController,
          repository: _repository,
          onFilterChanged: (filter) => setState(() => _filter = filter),
          onSearchChanged: _onSearchChanged,
          onResetFilters: _resetFilters,
          onMedicineSelected: widget.onMedicineSelected,
        );
      },
    );
  }
}

class _LibraryContent extends StatelessWidget {
  final List<MedicineLibraryMedicine> medicines;
  final MedicineLibraryFilter filter;
  final TextEditingController searchController;
  final MedicineLibraryRepository repository;
  final ValueChanged<MedicineLibraryFilter> onFilterChanged;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onResetFilters;
  final ValueChanged<String> onMedicineSelected;

  const _LibraryContent({
    required this.medicines,
    required this.filter,
    required this.searchController,
    required this.repository,
    required this.onFilterChanged,
    required this.onSearchChanged,
    required this.onResetFilters,
    required this.onMedicineSelected,
  });

  @override
  Widget build(BuildContext context) {
    final strings = MedicineLibraryStrings.of(context);
    final results = repository.queryMedicines(medicines, filter);
    final categories = repository.availableCategories(medicines);
    final forms = repository.availableForms(medicines);
    final ageGroups = repository.availableAgeGroups(medicines);
    final tags = repository.availableTags(medicines);

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
                    Text(
                      strings.t(MedicineLibraryTextKey.title),
                      style: TextStyle(
                        color: appTextColor(context),
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      strings.t(MedicineLibraryTextKey.subtitle),
                      style: TextStyle(
                        color: appMutedTextColor(context),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _DisclaimerBanner(
                      text: strings.t(MedicineLibraryTextKey.disclaimerFull),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: searchController,
                      onChanged: onSearchChanged,
                      decoration: authInputDecoration(
                        context: context,
                        hintText: strings.t(MedicineLibraryTextKey.searchHint),
                        icon: Icons.search,
                        suffixIcon: searchController.text.isEmpty
                            ? null
                            : IconButton(
                                tooltip:
                                    strings.t(MedicineLibraryTextKey.resetFilters),
                                onPressed: onResetFilters,
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
                            width: 310,
                            child: MedicineLibraryFilterPanel(
                              filter: filter,
                              categories: categories,
                              forms: forms,
                              ageGroups: ageGroups,
                              tags: tags,
                              onChanged: onFilterChanged,
                              onReset: onResetFilters,
                            ),
                          ),
                          const SizedBox(width: 18),
                          Expanded(
                            child: _ResultsArea(
                              medicines: medicines,
                              results: results,
                              onMedicineSelected: onMedicineSelected,
                            ),
                          ),
                        ],
                      )
                    else ...[
                      _ExpandableFilters(
                        filter: filter,
                        categories: categories,
                        forms: forms,
                        ageGroups: ageGroups,
                        tags: tags,
                        onChanged: onFilterChanged,
                        onReset: onResetFilters,
                      ),
                      const SizedBox(height: 16),
                      _ResultsArea(
                        medicines: medicines,
                        results: results,
                        onMedicineSelected: onMedicineSelected,
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
  final MedicineLibraryFilter filter;
  final List<String> categories;
  final List<String> forms;
  final List<String> ageGroups;
  final List<String> tags;
  final ValueChanged<MedicineLibraryFilter> onChanged;
  final VoidCallback onReset;

  const _ExpandableFilters({
    required this.filter,
    required this.categories,
    required this.forms,
    required this.ageGroups,
    required this.tags,
    required this.onChanged,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    final strings = MedicineLibraryStrings.of(context);
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
            strings.t(MedicineLibraryTextKey.filters),
            style: TextStyle(
              color: appTextColor(context),
              fontWeight: FontWeight.w900,
            ),
          ),
          children: [
            MedicineLibraryFilterPanel(
              filter: filter,
              categories: categories,
              forms: forms,
              ageGroups: ageGroups,
              tags: tags,
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
  final List<MedicineLibraryMedicine> medicines;
  final List<MedicineLibraryMedicine> results;
  final ValueChanged<String> onMedicineSelected;

  const _ResultsArea({
    required this.medicines,
    required this.results,
    required this.onMedicineSelected,
  });

  @override
  Widget build(BuildContext context) {
    final strings = MedicineLibraryStrings.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ResultCount(text: strings.showingCount(results.length, medicines.length)),
        const SizedBox(height: 12),
        if (results.isEmpty)
          _EmptyState(
            icon: Icons.search_off_outlined,
            title: strings.t(MedicineLibraryTextKey.emptyFiltersTitle),
            message: strings.t(MedicineLibraryTextKey.emptyFiltersMessage),
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final count = constraints.maxWidth >= 930
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
                  mainAxisExtent: 318,
                ),
                itemBuilder: (context, index) {
                  final medicine = results[index];
                  return MedicineLibraryCard(
                    medicine: medicine,
                    onTap: () => onMedicineSelected(medicine.id),
                  );
                },
              );
            },
          ),
      ],
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

class _ResultCount extends StatelessWidget {
  final String text;

  const _ResultCount({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: appMutedTextColor(context),
        fontWeight: FontWeight.w900,
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
    final strings = MedicineLibraryStrings.of(context);
    return _EmptyState(
      icon: Icons.error_outline,
      title: strings.t(MedicineLibraryTextKey.errorTitle),
      message: MedicineLibraryRepository.assetPath,
      action: FilledButton.icon(
        style: FilledButton.styleFrom(backgroundColor: authPrimary),
        onPressed: onRetry,
        icon: const Icon(Icons.refresh),
        label: Text(strings.t(MedicineLibraryTextKey.retry)),
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
