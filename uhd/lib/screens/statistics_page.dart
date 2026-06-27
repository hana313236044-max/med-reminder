import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:uhd/models/medicine_performance.dart';
import 'package:uhd/models/statistics_filter.dart';
import 'package:uhd/models/statistics_model.dart';
import 'package:uhd/models/statistics_summary.dart';
import 'package:uhd/services/statistics_service.dart';
import 'package:uhd/widgets/app_widgets.dart';

class StatisticsPage extends StatefulWidget {
  final ValueChanged<String>? onMedicineSelected;

  const StatisticsPage({super.key, this.onMedicineSelected});

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  final StatisticsService _service = StatisticsService();
  late StatisticsFilter _filter;
  late Future<StatisticsReport> _reportFuture;
  int _sortColumnIndex = 0;
  bool _sortAscending = true;

  @override
  void initState() {
    super.initState();
    _filter = StatisticsFilter.initial();
    _reportFuture = _service.loadReport(_filter);
  }

  void _reload() {
    setState(() => _reportFuture = _service.loadReport(_filter));
  }

  void _setFilter(StatisticsFilter filter) {
    setState(() {
      _filter = filter;
      _reportFuture = _service.loadReport(_filter);
    });
  }

  Future<void> _setRangePreset(StatisticsRangePreset preset) async {
    if (preset == StatisticsRangePreset.custom) {
      await _pickCustomRange();
      return;
    }

    _setFilter(
      _filter.copyWith(
        rangePreset: preset,
        dateRange: StatisticsDateRange.forPreset(preset),
      ),
    );
  }

  Future<void> _pickCustomRange() async {
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(
        start: _filter.dateRange.startDate,
        end: _filter.dateRange.endDate,
      ),
      firstDate: DateTime.now().subtract(const Duration(days: 1095)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: authPrimary,
                  secondary: authAccent,
                ),
          ),
          child: child!,
        );
      },
    );

    if (picked == null) return;
    if (picked.end.isBefore(picked.start)) {
      if (!mounted) return;
      showAuthMessage(
        context,
        'Choose an end date after the start date.',
        backgroundColor: Colors.redAccent,
      );
      return;
    }

    _setFilter(
      _filter.copyWith(
        rangePreset: StatisticsRangePreset.custom,
        dateRange: StatisticsDateRange(
          startDate: picked.start,
          endDate: picked.end,
        ),
      ),
    );
  }

  void _sortTable(int columnIndex, bool ascending) {
    setState(() {
      _sortColumnIndex = columnIndex;
      _sortAscending = ascending;
    });
  }

  List<MedicinePerformance> _sortedPerformance(StatisticsReport report) {
    final rows = [...report.medicinePerformance];
    rows.sort((a, b) {
      int result;
      switch (_sortColumnIndex) {
        case 1:
          result = a.scheduledCount.compareTo(b.scheduledCount);
          break;
        case 2:
          result = a.completedCount.compareTo(b.completedCount);
          break;
        case 3:
          result = a.unsuccessfulCount.compareTo(b.unsuccessfulCount);
          break;
        case 4:
          result = a.adherencePercent.compareTo(b.adherencePercent);
          break;
        case 0:
        default:
          result = a.medicineName.toLowerCase().compareTo(
                b.medicineName.toLowerCase(),
              );
          break;
      }
      return _sortAscending ? result : -result;
    });
    return rows;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<StatisticsReport>(
      future: _reportFuture,
      builder: (context, snapshot) {
        final report = snapshot.data;
        final isLoading = snapshot.connectionState == ConnectionState.waiting;

        return SafeArea(
          top: false,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return ListView(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 96),
                children: [
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1160),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _PageIntro(),
                          const SizedBox(height: 16),
                          _RangeSelector(
                            filter: _filter,
                            onSelected: _setRangePreset,
                          ),
                          const SizedBox(height: 14),
                          if (report != null)
                            _FilterSection(
                              filter: _filter,
                              medicineOptions: report.medicineOptions,
                              onMedicineChanged: (medicineId) => _setFilter(
                                _filter.copyWith(medicineId: medicineId),
                              ),
                              onStatusChanged: (status) => _setFilter(
                                _filter.copyWith(status: status),
                              ),
                              onScheduleTypeChanged: (type) => _setFilter(
                                _filter.copyWith(scheduleType: type),
                              ),
                              onReset: () => _setFilter(
                                _filter.resetFilters(),
                              ),
                            )
                          else
                            _FilterSkeleton(filter: _filter),
                          const SizedBox(height: 16),
                          if (isLoading)
                            const _LoadingState()
                          else if (snapshot.hasError)
                            _ErrorState(onRetry: _reload)
                          else if (report == null)
                            _ErrorState(onRetry: _reload)
                          else
                            _ReportContent(
                              report: report,
                              sortedPerformance: _sortedPerformance(report),
                              sortColumnIndex: _sortColumnIndex,
                              sortAscending: _sortAscending,
                              onSort: _sortTable,
                              onResetFilters: () => _setFilter(
                                _filter.resetFilters(),
                              ),
                              onMedicineSelected: widget.onMedicineSelected,
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

class _PageIntro extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: appTintSurfaceColor(context),
            borderRadius: BorderRadius.circular(15),
          ),
          child: const Icon(Icons.insights_outlined, color: authPrimary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Statistics / Insights',
                style: TextStyle(
                  color: appTextColor(context),
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'Track adherence, missed doses, and medicine performance.',
                style: TextStyle(
                  color: appMutedTextColor(context),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RangeSelector extends StatelessWidget {
  final StatisticsFilter filter;
  final ValueChanged<StatisticsRangePreset> onSelected;

  const _RangeSelector({
    required this.filter,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: appSurfaceColor(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: appBorderColor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: StatisticsRangePreset.values.map((preset) {
                final selected = filter.rangePreset == preset;
                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: ChoiceChip(
                    selected: selected,
                    onSelected: (_) => onSelected(preset),
                    backgroundColor: appSoftSurfaceColor(context),
                    selectedColor: authPrimary,
                    side: BorderSide(
                      color: selected ? authPrimary : appBorderColor(context),
                    ),
                    label: Text(
                      preset.label,
                      style: TextStyle(
                        color: selected ? Colors.white : appTextColor(context),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _rangeLabel(filter.dateRange),
            style: TextStyle(
              color: appMutedTextColor(context),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterSection extends StatelessWidget {
  final StatisticsFilter filter;
  final List<MedicineOption> medicineOptions;
  final ValueChanged<String?> onMedicineChanged;
  final ValueChanged<StatisticsStatusFilter> onStatusChanged;
  final ValueChanged<StatisticsScheduleTypeFilter> onScheduleTypeChanged;
  final VoidCallback onReset;

  const _FilterSection({
    required this.filter,
    required this.medicineOptions,
    required this.onMedicineChanged,
    required this.onStatusChanged,
    required this.onScheduleTypeChanged,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final selectedMedicineMissing =
            filter.medicineId != null &&
            !medicineOptions.any((medicine) => medicine.id == filter.medicineId);
        final itemWidth = constraints.maxWidth >= 920
            ? (constraints.maxWidth - 36) / 4
            : constraints.maxWidth >= 620
                ? (constraints.maxWidth - 12) / 2
                : constraints.maxWidth;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: appSurfaceColor(context),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: appBorderColor(context)),
          ),
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: itemWidth,
                child: DropdownButtonFormField<String>(
                  value: filter.medicineId ?? '__all_medicines__',
                  decoration: authInputDecoration(
                    context: context,
                    hintText: 'Medicine',
                    icon: Icons.medication_outlined,
                  ),
                  items: [
                    const DropdownMenuItem<String>(
                      value: '__all_medicines__',
                      child: Text('All medicines'),
                    ),
                    ...medicineOptions.map(
                      (medicine) => DropdownMenuItem<String>(
                        value: medicine.id,
                        child: Text(
                          medicine.name,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    if (selectedMedicineMissing)
                      DropdownMenuItem<String>(
                        value: filter.medicineId,
                        child: const Text('Unknown medicine'),
                      ),
                  ],
                  onChanged: (value) {
                    onMedicineChanged(
                      value == '__all_medicines__' ? null : value,
                    );
                  },
                ),
              ),
              SizedBox(
                width: itemWidth,
                child: DropdownButtonFormField<StatisticsStatusFilter>(
                  value: filter.status,
                  decoration: authInputDecoration(
                    context: context,
                    hintText: 'Status',
                    icon: Icons.fact_check_outlined,
                  ),
                  items: StatisticsStatusFilter.values
                      .map(
                        (status) => DropdownMenuItem(
                          value: status,
                          child: Text(status.label),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) onStatusChanged(value);
                  },
                ),
              ),
              SizedBox(
                width: itemWidth,
                child: DropdownButtonFormField<StatisticsScheduleTypeFilter>(
                  value: filter.scheduleType,
                  decoration: authInputDecoration(
                    context: context,
                    hintText: 'Type',
                    icon: Icons.repeat_outlined,
                  ),
                  items: StatisticsScheduleTypeFilter.values
                      .map(
                        (type) => DropdownMenuItem(
                          value: type,
                          child: Text(type.label),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) onScheduleTypeChanged(value);
                  },
                ),
              ),
              SizedBox(
                width: itemWidth,
                height: 56,
                child: OutlinedButton.icon(
                  onPressed: filter.hasActiveFilters ? onReset : null,
                  icon: const Icon(Icons.restart_alt_outlined),
                  label: const Text('Reset filters'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: authPrimary,
                    side: BorderSide(color: appBorderColor(context)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FilterSkeleton extends StatelessWidget {
  final StatisticsFilter filter;

  const _FilterSkeleton({required this.filter});

  @override
  Widget build(BuildContext context) {
    return _FilterSection(
      filter: filter,
      medicineOptions: const [],
      onMedicineChanged: (_) {},
      onStatusChanged: (_) {},
      onScheduleTypeChanged: (_) {},
      onReset: () {},
    );
  }
}

class _ReportContent extends StatelessWidget {
  final StatisticsReport report;
  final List<MedicinePerformance> sortedPerformance;
  final int sortColumnIndex;
  final bool sortAscending;
  final void Function(int columnIndex, bool ascending) onSort;
  final VoidCallback onResetFilters;
  final ValueChanged<String>? onMedicineSelected;

  const _ReportContent({
    required this.report,
    required this.sortedPerformance,
    required this.sortColumnIndex,
    required this.sortAscending,
    required this.onSort,
    required this.onResetFilters,
    required this.onMedicineSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (!report.hasAnyRecordsInRange) {
      return const _EmptyState(
        icon: Icons.insights_outlined,
        title: 'No reminders found for this period',
        message:
            'No statistics are available for this period. Complete or miss scheduled reminders to see your insights.',
      );
    }

    if (!report.hasFilteredRecords) {
      return _EmptyState(
        icon: Icons.filter_alt_off_outlined,
        title: 'No records match these filters',
        message: 'Try a different medicine, status, schedule type, or date range.',
        actionLabel: 'Reset filters',
        onAction: onResetFilters,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _InsightCard(message: report.insightMessage),
        const SizedBox(height: 14),
        _SummaryGrid(summary: report.summary),
        const SizedBox(height: 14),
        _SecondaryStatsGrid(summary: report.summary),
        const SizedBox(height: 14),
        _ChartGrid(report: report),
        const SizedBox(height: 14),
        _MedicineBreakdownTable(
          rows: sortedPerformance,
          sortColumnIndex: sortColumnIndex,
          sortAscending: sortAscending,
          onSort: onSort,
          onMedicineSelected: onMedicineSelected,
        ),
      ],
    );
  }
}

class _InsightCard extends StatelessWidget {
  final String message;

  const _InsightCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: appIsDark(context) ? const Color(0xFF14363A) : const Color(0xFFEAF8F6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: authPrimary.withOpacity(0.28)),
        boxShadow: [
          BoxShadow(
            color: appShadowColor(context, 0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: authPrimary,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.auto_graph, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: appTextColor(context),
                fontSize: 16,
                height: 1.35,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryGrid extends StatelessWidget {
  final StatisticsSummary summary;

  const _SummaryGrid({required this.summary});

  @override
  Widget build(BuildContext context) {
    final cards = [
      _StatCard(
        icon: Icons.percent_outlined,
        label: 'Adherence',
        value: summary.hasFinishedData
            ? _percent(summary.adherencePercent)
            : 'No data',
        helper: '${summary.finishedCount} finished doses',
      ),
      _StatCard(
        icon: Icons.check_circle_outline,
        label: 'Taken',
        value: summary.completedCount.toString(),
        helper: 'Includes delayed completions',
      ),
      _StatCard(
        icon: Icons.cancel_outlined,
        label: 'Missed',
        value: summary.missedCount.toString(),
        helper: 'Unsuccessful scheduled doses',
      ),
      _StatCard(
        icon: Icons.schedule_outlined,
        label: 'Delayed',
        value: summary.delayedCount.toString(),
        helper: 'Taken after the on-time window',
      ),
    ];

    return _ResponsiveCardGrid(children: cards);
  }
}

class _SecondaryStatsGrid extends StatelessWidget {
  final StatisticsSummary summary;

  const _SecondaryStatsGrid({required this.summary});

  @override
  Widget build(BuildContext context) {
    final cards = [
      _StatCard(
        icon: Icons.timer_outlined,
        label: 'On-time adherence',
        value: summary.hasFinishedData
            ? _percent(summary.onTimeAdherencePercent)
            : 'No data',
        helper: '${summary.onTimeTakenCount} on-time doses',
      ),
      _StatCard(
        icon: Icons.remove_circle_outline,
        label: 'Skipped',
        value: summary.skippedCount.toString(),
        helper: 'Skipped scheduled doses',
      ),
      _StatCard(
        icon: Icons.medication_outlined,
        label: 'Most missed medicine',
        value: summary.mostMissedMedicine ?? 'No missed doses',
        helper: 'Missed or skipped most often',
      ),
      _StatCard(
        icon: Icons.access_time,
        label: 'Most missed time',
        value: summary.mostMissedTime ?? 'No missed doses',
        helper: 'Scheduled time with most misses',
      ),
      _StatCard(
        icon: Icons.local_fire_department_outlined,
        label: 'Successful-day streak',
        value: summary.currentStreakDays.toString(),
        helper: 'Consecutive perfect scheduled days',
      ),
    ];

    return _ResponsiveCardGrid(children: cards);
  }
}

class _ResponsiveCardGrid extends StatelessWidget {
  final List<Widget> children;

  const _ResponsiveCardGrid({required this.children});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 920
            ? 4
            : constraints.maxWidth >= 620
                ? 2
                : 1;
        return GridView.count(
          crossAxisCount: columns,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: columns == 1 ? 3.4 : 2.35,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: children,
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String helper;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.helper,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: appSurfaceColor(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: appBorderColor(context)),
        boxShadow: [
          BoxShadow(
            color: appShadowColor(context, 0.05),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: appTintSurfaceColor(context),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(icon, color: authPrimary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: appMutedTextColor(context),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                FittedBox(
                  alignment: Alignment.centerLeft,
                  fit: BoxFit.scaleDown,
                  child: Text(
                    value,
                    style: TextStyle(
                      color: appTextColor(context),
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  helper,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: appMutedTextColor(context),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartGrid extends StatelessWidget {
  final StatisticsReport report;

  const _ChartGrid({required this.report});

  @override
  Widget build(BuildContext context) {
    final charts = [
      _AdherenceBarChart(dailyStatistics: report.dailyStatistics),
      _DistributionPieChart(summary: report.summary),
      _CompletionLineChart(dailyStatistics: report.dailyStatistics),
      _MedicinePerformanceChart(rows: report.medicinePerformance),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final twoColumns = constraints.maxWidth >= 860;
        final width = twoColumns ? (constraints.maxWidth - 12) / 2 : constraints.maxWidth;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: charts
              .map(
                (chart) => SizedBox(
                  width: width,
                  child: chart,
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _ChartCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;
  final bool isEmpty;
  final String emptyMessage;

  const _ChartCard({
    required this.title,
    required this.subtitle,
    required this.child,
    this.isEmpty = false,
    this.emptyMessage = 'No chart data for this period.',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 360,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: appSurfaceColor(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: appBorderColor(context)),
        boxShadow: [
          BoxShadow(
            color: appShadowColor(context, 0.05),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: appTextColor(context),
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            style: TextStyle(
              color: appMutedTextColor(context),
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: isEmpty
                ? Center(
                    child: Text(
                      emptyMessage,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: appMutedTextColor(context),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  )
                : child,
          ),
        ],
      ),
    );
  }
}

class _AdherenceBarChart extends StatelessWidget {
  final List<DailyStatistic> dailyStatistics;

  const _AdherenceBarChart({required this.dailyStatistics});

  @override
  Widget build(BuildContext context) {
    final hasData = dailyStatistics.any((day) => day.scheduledCount > 0);
    return _ChartCard(
      title: 'Adherence by day',
      subtitle: 'Finished scheduled doses completed each day',
      isEmpty: !hasData,
      child: BarChart(
        BarChartData(
          minY: 0,
          maxY: 100,
          gridData: _gridData(context),
          borderData: FlBorderData(show: false),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => appTextColor(context),
              fitInsideHorizontally: true,
              fitInsideVertically: true,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final day = dailyStatistics[group.x];
                return BarTooltipItem(
                  '${_shortDate(day.date)}\n${rod.toY.round()}%',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                );
              },
            ),
          ),
          titlesData: _titlesData(
            context,
            dailyStatistics,
            bottomLabel: (day) => _tinyDate(day.date),
          ),
          barGroups: [
            for (var index = 0; index < dailyStatistics.length; index++)
              BarChartGroupData(
                x: index,
                barRods: [
                  BarChartRodData(
                    toY: dailyStatistics[index]
                        .adherencePercent
                        .clamp(0, 100)
                        .toDouble(),
                    width: dailyStatistics.length > 20 ? 8 : 14,
                    borderRadius: BorderRadius.circular(6),
                    color: authPrimary,
                    backDrawRodData: BackgroundBarChartRodData(
                      show: true,
                      toY: 100,
                      color: appSoftSurfaceColor(context),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _DistributionPieChart extends StatelessWidget {
  final StatisticsSummary summary;

  const _DistributionPieChart({required this.summary});

  @override
  Widget build(BuildContext context) {
    final slices = [
      _Slice('Taken', summary.takenCount, authPrimary),
      _Slice('Delayed', summary.delayedCount, const Color(0xFFF59E0B)),
      _Slice('Missed', summary.missedCount, Colors.redAccent),
      _Slice('Skipped', summary.skippedCount, const Color(0xFF64748B)),
    ];
    final total = slices.fold<int>(0, (sum, slice) => sum + slice.count);

    return _ChartCard(
      title: 'Taken vs missed',
      subtitle: 'Distribution of finished reminder outcomes',
      isEmpty: total == 0,
      child: Row(
        children: [
          Expanded(
            child: PieChart(
              PieChartData(
                centerSpaceRadius: 42,
                sectionsSpace: 3,
                sections: slices.where((slice) => slice.count > 0).map((slice) {
                  final percent = slice.count / total * 100;
                  return PieChartSectionData(
                    value: slice.count.toDouble(),
                    color: slice.color,
                    radius: 58,
                    title: '${percent.round()}%',
                    titleStyle: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 118,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: slices.map((slice) {
                final percent = total == 0 ? 0 : slice.count / total * 100;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _LegendItem(
                    color: slice.color,
                    label: slice.label,
                    value: '${slice.count} (${percent.round()}%)',
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompletionLineChart extends StatelessWidget {
  final List<DailyStatistic> dailyStatistics;

  const _CompletionLineChart({required this.dailyStatistics});

  @override
  Widget build(BuildContext context) {
    final hasData = dailyStatistics.any((day) => day.scheduledCount > 0);
    final spots = [
      for (var index = 0; index < dailyStatistics.length; index++)
        FlSpot(index.toDouble(), dailyStatistics[index].adherencePercent),
    ];

    return _ChartCard(
      title: 'Daily completion',
      subtitle: 'Completion percentage across the selected range',
      isEmpty: !hasData,
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: math.max(1, dailyStatistics.length - 1).toDouble(),
          minY: 0,
          maxY: 100,
          gridData: _gridData(context),
          borderData: FlBorderData(show: false),
          titlesData: _titlesData(
            context,
            dailyStatistics,
            bottomLabel: (day) => _tinyDate(day.date),
          ),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => appTextColor(context),
              fitInsideHorizontally: true,
              fitInsideVertically: true,
              getTooltipItems: (spots) {
                return spots.map((spot) {
                  final index = spot.x
                      .round()
                      .clamp(0, dailyStatistics.length - 1)
                      .toInt();
                  return LineTooltipItem(
                    '${_shortDate(dailyStatistics[index].date)}\n${spot.y.round()}%',
                    const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  );
                }).toList();
              },
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: dailyStatistics.length > 2,
              color: authPrimary,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(show: dailyStatistics.length <= 14),
              belowBarData: BarAreaData(
                show: true,
                color: authPrimary.withOpacity(0.12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MedicinePerformanceChart extends StatelessWidget {
  final List<MedicinePerformance> rows;

  const _MedicinePerformanceChart({required this.rows});

  @override
  Widget build(BuildContext context) {
    return _ChartCard(
      title: 'Medicine performance',
      subtitle: 'Adherence for each included medicine',
      isEmpty: rows.isEmpty,
      child: SingleChildScrollView(
        child: Column(
          children: rows.map((row) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          row.medicineName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: appTextColor(context),
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _percent(row.adherencePercent),
                        style: const TextStyle(
                          color: authPrimary,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 7),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      minHeight: 10,
                      value: (row.adherencePercent / 100)
                          .clamp(0, 1)
                          .toDouble(),
                      backgroundColor: appSoftSurfaceColor(context),
                      valueColor: const AlwaysStoppedAnimation(authPrimary),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Scheduled ${row.scheduledCount} | Completed ${row.completedCount} | Missed ${row.unsuccessfulCount}',
                    style: TextStyle(
                      color: appMutedTextColor(context),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _MedicineBreakdownTable extends StatelessWidget {
  final List<MedicinePerformance> rows;
  final int sortColumnIndex;
  final bool sortAscending;
  final void Function(int columnIndex, bool ascending) onSort;
  final ValueChanged<String>? onMedicineSelected;

  const _MedicineBreakdownTable({
    required this.rows,
    required this.sortColumnIndex,
    required this.sortAscending,
    required this.onSort,
    required this.onMedicineSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: appSurfaceColor(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: appBorderColor(context)),
        boxShadow: [
          BoxShadow(
            color: appShadowColor(context, 0.05),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Medicine breakdown',
            style: TextStyle(
              color: appTextColor(context),
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          if (rows.isEmpty)
            Text(
              'No medicine rows are available for this period.',
              style: TextStyle(
                color: appMutedTextColor(context),
                fontWeight: FontWeight.w700,
              ),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                sortColumnIndex: sortColumnIndex,
                sortAscending: sortAscending,
                headingTextStyle: TextStyle(
                  color: appTextColor(context),
                  fontWeight: FontWeight.w900,
                ),
                dataTextStyle: TextStyle(
                  color: appTextColor(context),
                  fontWeight: FontWeight.w700,
                ),
                columns: [
                  DataColumn(
                    label: const Text('Medicine'),
                    onSort: onSort,
                  ),
                  DataColumn(
                    numeric: true,
                    label: const Text('Scheduled'),
                    onSort: onSort,
                  ),
                  DataColumn(
                    numeric: true,
                    label: const Text('Taken'),
                    onSort: onSort,
                  ),
                  DataColumn(
                    numeric: true,
                    label: const Text('Missed'),
                    onSort: onSort,
                  ),
                  DataColumn(
                    numeric: true,
                    label: const Text('Adherence'),
                    onSort: onSort,
                  ),
                ],
                rows: rows.map((row) {
                  return DataRow(
                    onSelectChanged: onMedicineSelected == null
                        ? null
                        : (_) => onMedicineSelected!(row.medicineId),
                    cells: [
                      DataCell(
                        ConstrainedBox(
                          constraints: const BoxConstraints(minWidth: 150, maxWidth: 230),
                          child: Text(
                            row.medicineName,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      DataCell(Text(row.scheduledCount.toString())),
                      DataCell(Text(row.completedCount.toString())),
                      DataCell(Text(row.unsuccessfulCount.toString())),
                      DataCell(Text(_percent(row.adherencePercent))),
                    ],
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: appSurfaceColor(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: appBorderColor(context)),
      ),
      child: const Column(
        children: [
          CircularProgressIndicator(color: authPrimary),
          SizedBox(height: 14),
          Text(
            'Loading your statistics...',
            style: TextStyle(fontWeight: FontWeight.w800),
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
    return _EmptyState(
      icon: Icons.error_outline,
      title: 'Could not load statistics',
      message: 'Please check your connection and try again.',
      actionLabel: 'Retry',
      onAction: onRetry,
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: appSurfaceColor(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: appBorderColor(context)),
      ),
      child: Column(
        children: [
          Icon(icon, color: authPrimary, size: 46),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: appTextColor(context),
              fontSize: 20,
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
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.refresh),
              label: Text(actionLabel!),
              style: FilledButton.styleFrom(backgroundColor: authPrimary),
            ),
          ],
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final String value;

  const _LegendItem({
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 10,
          height: 10,
          margin: const EdgeInsets.only(top: 4),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: appTextColor(context),
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  color: appMutedTextColor(context),
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Slice {
  final String label;
  final int count;
  final Color color;

  const _Slice(this.label, this.count, this.color);
}

FlGridData _gridData(BuildContext context) {
  return FlGridData(
    drawVerticalLine: false,
    horizontalInterval: 25,
    getDrawingHorizontalLine: (_) => FlLine(
      color: appBorderColor(context),
      strokeWidth: 1,
    ),
  );
}

FlTitlesData _titlesData(
  BuildContext context,
  List<DailyStatistic> days, {
  required String Function(DailyStatistic day) bottomLabel,
}) {
  final labelEvery = math.max(1, (days.length / 6).ceil());
  return FlTitlesData(
    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    leftTitles: AxisTitles(
      sideTitles: SideTitles(
        showTitles: true,
        reservedSize: 38,
        interval: 25,
        getTitlesWidget: (value, meta) {
          return SideTitleWidget(
            meta: meta,
            child: Text(
              '${value.round()}%',
              style: TextStyle(
                color: appMutedTextColor(context),
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          );
        },
      ),
    ),
    bottomTitles: AxisTitles(
      sideTitles: SideTitles(
        showTitles: true,
        reservedSize: 34,
        getTitlesWidget: (value, meta) {
          final index = value.round();
          if (index < 0 || index >= days.length || index % labelEvery != 0) {
            return const SizedBox.shrink();
          }
          return SideTitleWidget(
            meta: meta,
            child: Text(
              bottomLabel(days[index]),
              style: TextStyle(
                color: appMutedTextColor(context),
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          );
        },
      ),
    ),
  );
}

String _percent(double value) => '${value.round()}%';

String _rangeLabel(StatisticsDateRange range) {
  if (range.startDate == range.endDate) {
    return _shortDate(range.startDate);
  }
  return '${_shortDate(range.startDate)} - ${_shortDate(range.endDate)}';
}

String _shortDate(DateTime date) => '${date.year}/${date.month}/${date.day}';

String _tinyDate(DateTime date) => '${date.month}/${date.day}';
