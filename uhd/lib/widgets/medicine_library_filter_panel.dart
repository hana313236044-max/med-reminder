import 'package:flutter/material.dart';
import 'package:uhd/l10n/medicine_library_localizations.dart';
import 'package:uhd/models/medicine_library_filter.dart';
import 'package:uhd/models/medicine_library_model.dart';
import 'package:uhd/widgets/app_widgets.dart';

class MedicineLibraryFilterPanel extends StatelessWidget {
  final MedicineLibraryFilter filter;
  final List<String> categories;
  final List<String> forms;
  final List<String> ageGroups;
  final List<String> tags;
  final ValueChanged<MedicineLibraryFilter> onChanged;
  final VoidCallback onReset;
  final bool framed;

  const MedicineLibraryFilterPanel({
    super.key,
    required this.filter,
    required this.categories,
    required this.forms,
    required this.ageGroups,
    required this.tags,
    required this.onChanged,
    required this.onReset,
    this.framed = true,
  });

  @override
  Widget build(BuildContext context) {
    final strings = MedicineLibraryStrings.of(context);
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                strings.t(MedicineLibraryTextKey.filters),
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
              label: Text(strings.t(MedicineLibraryTextKey.resetFilters)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _NullableDropdown<String>(
          label: strings.t(MedicineLibraryTextKey.category),
          hint: strings.t(MedicineLibraryTextKey.allCategories),
          value: filter.category,
          icon: Icons.category_outlined,
          options: categories,
          optionLabel: (value) => value,
          onChanged: (value) => onChanged(filter.copyWith(category: value)),
        ),
        const SizedBox(height: 12),
        _NullableDropdown<String>(
          label: strings.t(MedicineLibraryTextKey.form),
          hint: strings.t(MedicineLibraryTextKey.allForms),
          value: filter.form,
          icon: Icons.medication_liquid_outlined,
          options: forms,
          optionLabel: (value) => value,
          onChanged: (value) => onChanged(filter.copyWith(form: value)),
        ),
        const SizedBox(height: 12),
        _EnumDropdown<MedicineLibraryPrescriptionFilter>(
          label: strings.t(MedicineLibraryTextKey.prescription),
          value: filter.prescriptionFilter,
          icon: Icons.assignment_outlined,
          options: MedicineLibraryPrescriptionFilter.values,
          optionLabel: strings.prescriptionFilterLabel,
          onChanged: (value) {
            if (value != null) {
              onChanged(filter.copyWith(prescriptionFilter: value));
            }
          },
        ),
        const SizedBox(height: 12),
        _NullableDropdown<String>(
          label: strings.t(MedicineLibraryTextKey.ageGroup),
          hint: strings.t(MedicineLibraryTextKey.allAgeGroups),
          value: filter.ageGroup,
          icon: Icons.groups_outlined,
          options: ageGroups,
          optionLabel: (value) => value,
          onChanged: (value) => onChanged(filter.copyWith(ageGroup: value)),
        ),
        const SizedBox(height: 12),
        _EnumDropdown<MedicineLibraryFoodFilter>(
          label: strings.t(MedicineLibraryTextKey.foodInstruction),
          value: filter.foodFilter,
          icon: Icons.restaurant_outlined,
          options: MedicineLibraryFoodFilter.values,
          optionLabel: strings.foodFilterLabel,
          onChanged: (value) {
            if (value != null) {
              onChanged(filter.copyWith(foodFilter: value));
            }
          },
        ),
        const SizedBox(height: 12),
        _NullableDropdown<MedicineLibraryWarningLevel>(
          label: strings.t(MedicineLibraryTextKey.warningLevel),
          hint: strings.t(MedicineLibraryTextKey.allWarningLevels),
          value: filter.warningLevel,
          icon: Icons.warning_amber_outlined,
          options: MedicineLibraryWarningLevel.values,
          optionLabel: strings.warningLevelLabel,
          onChanged: (value) =>
              onChanged(filter.copyWith(warningLevel: value)),
        ),
        const SizedBox(height: 14),
        _AlphabetFilter(filter: filter, onChanged: onChanged),
        const SizedBox(height: 14),
        _NullableDropdown<String>(
          label: strings.t(MedicineLibraryTextKey.tag),
          hint: strings.t(MedicineLibraryTextKey.allTags),
          value: filter.tag,
          icon: Icons.sell_outlined,
          options: tags,
          optionLabel: (value) => value,
          onChanged: (value) => onChanged(filter.copyWith(tag: value)),
        ),
        const SizedBox(height: 12),
        _EnumDropdown<MedicineLibrarySort>(
          label: strings.t(MedicineLibraryTextKey.sortBy),
          value: filter.sort,
          icon: Icons.sort_by_alpha,
          options: MedicineLibrarySort.values,
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

class _AlphabetFilter extends StatelessWidget {
  final MedicineLibraryFilter filter;
  final ValueChanged<MedicineLibraryFilter> onChanged;

  const _AlphabetFilter({
    required this.filter,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final strings = MedicineLibraryStrings.of(context);
    final letters = List.generate(26, (index) => String.fromCharCode(65 + index));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          strings.t(MedicineLibraryTextKey.alphabet),
          style: TextStyle(
            color: appTextColor(context),
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 7,
          runSpacing: 7,
          children: [
            ChoiceChip(
              label: Text(strings.t(MedicineLibraryTextKey.all)),
              selected: filter.startingLetter == null,
              onSelected: (_) => onChanged(
                filter.copyWith(startingLetter: null),
              ),
              selectedColor: appTintSurfaceColor(context),
              side: BorderSide(color: appBorderColor(context)),
            ),
            for (final letter in letters)
              ChoiceChip(
                label: Text(letter),
                selected: filter.startingLetter == letter,
                onSelected: (_) => onChanged(
                  filter.copyWith(startingLetter: letter),
                ),
                selectedColor: appTintSurfaceColor(context),
                side: BorderSide(color: appBorderColor(context)),
              ),
          ],
        ),
      ],
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

  const _NullableDropdown({
    required this.label,
    required this.hint,
    required this.value,
    required this.icon,
    required this.options,
    required this.optionLabel,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T?>(
      value: value,
      isExpanded: true,
      hint: Text(hint, overflow: TextOverflow.ellipsis),
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
      onChanged: onChanged,
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
