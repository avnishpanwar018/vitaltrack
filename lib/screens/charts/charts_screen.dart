import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/reading.dart';
import '../../core/providers/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/date_utils.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/vital_card.dart';

enum ChartPeriod {
  days7('7 Days', 7),
  days30('30 Days', 30),
  days90('90 Days', 90),
  months6('6 Months', 180),
  year1('1 Year', 365),
  custom('Custom', 0);

  const ChartPeriod(this.label, this.days);
  final String label;
  final int days;
}

enum ChartMetric { systolic, diastolic, pulse }

class ChartsScreen extends ConsumerStatefulWidget {
  const ChartsScreen({super.key});

  @override
  ConsumerState<ChartsScreen> createState() => _ChartsScreenState();
}

class _ChartsScreenState extends ConsumerState<ChartsScreen> {
  ChartPeriod _period = ChartPeriod.days30;
  ChartMetric _metric = ChartMetric.systolic;
  DateTime? _customStart;
  DateTime? _customEnd;

  List<Reading> _filterReadings(List<Reading> all) {
    if (_period == ChartPeriod.custom) {
      if (_customStart == null || _customEnd == null) return all.toList();
      final start = DateTime(
        _customStart!.year,
        _customStart!.month,
        _customStart!.day,
      );
      final end = DateTime(
        _customEnd!.year,
        _customEnd!.month,
        _customEnd!.day + 1,
      );
      return all
          .where((r) =>
              !r.timestamp.isBefore(start) && r.timestamp.isBefore(end))
          .toList();
    }
    final cutoff = DateTime.now().subtract(Duration(days: _period.days));
    return all.where((r) => r.timestamp.isAfter(cutoff)).toList();
  }

  Future<void> _pickCustomRange() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (range != null) {
      if (!mounted) return;
      setState(() {
        _period = ChartPeriod.custom;
        _customStart = range.start;
        _customEnd = range.end;
      });
    }
  }

  Color _metricColor() {
    switch (_metric) {
      case ChartMetric.systolic:
        return AppColors.systolicColor;
      case ChartMetric.diastolic:
        return AppColors.diastolicColor;
      case ChartMetric.pulse:
        return AppColors.pulseColor;
    }
  }

  double _getValue(Reading r) {
    switch (_metric) {
      case ChartMetric.systolic:
        return r.systolic.toDouble();
      case ChartMetric.diastolic:
        return r.diastolic.toDouble();
      case ChartMetric.pulse:
        return r.pulse.toDouble();
    }
  }

  String _metricLabel() {
    switch (_metric) {
      case ChartMetric.systolic:
        return 'Systolic (mmHg)';
      case ChartMetric.diastolic:
        return 'Diastolic (mmHg)';
      case ChartMetric.pulse:
        return 'Pulse (BPM)';
    }
  }

  @override
  Widget build(BuildContext context) {
    final readingsAsync = ref.watch(readingsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Charts')),
      body: readingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => EmptyStateWidget(
          icon: Icons.error_outline,
          title: 'Error',
          message: e.toString(),
        ),
        data: (allReadings) {
          final readings = _filterReadings(allReadings)..sort((a, b) => a.timestamp.compareTo(b.timestamp));

          final controls = <Widget>[
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ChartPeriod.values.map((p) {
                  final selected = _period == p;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(p.label),
                      selected: selected,
                      onSelected: (_) {
                        if (p == ChartPeriod.custom) {
                          _pickCustomRange();
                        } else {
                          setState(() => _period = p);
                        }
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: ChartMetric.values.map((m) {
                final selected = _metric == m;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ChoiceChip(
                      label: Text(
                        m.name[0].toUpperCase() + m.name.substring(1),
                        style: const TextStyle(fontSize: 12),
                      ),
                      selected: selected,
                      onSelected: (_) => setState(() => _metric = m),
                    ),
                  ),
                );
              }).toList(),
            ),
          ];

          if (readings.isEmpty) {
            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                ...controls,
                const EmptyStateWidget(
                  icon: Icons.show_chart,
                  title: 'No chart data',
                  message: 'Add readings in the selected time period.',
                ),
              ],
            );
          }

          final spots = readings.asMap().entries.map((e) {
            return FlSpot(e.key.toDouble(), _getValue(e.value));
          }).toList();

          final minY = spots.map((s) => s.y).reduce((a, b) => a < b ? a : b) - 10;
          final maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b) + 10;

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              ...controls,
              const SizedBox(height: 20),
              VitalCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _metricLabel(),
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 280,
                      child: LineChart(
                        LineChartData(
                          minY: minY,
                          maxY: maxY,
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            horizontalInterval: 20,
                            getDrawingHorizontalLine: (v) => FlLine(
                              color: theme.colorScheme.outline.withValues(alpha: 0.1),
                              strokeWidth: 1,
                            ),
                          ),
                          titlesData: FlTitlesData(
                            leftTitles: const AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 40,
                                interval: 20,
                              ),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 30,
                                interval: (readings.length / 5).ceilToDouble().clamp(1, 999),
                                getTitlesWidget: (value, meta) {
                                  final idx = value.toInt();
                                  if (idx < 0 || idx >= readings.length) {
                                    return const SizedBox.shrink();
                                  }
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Text(
                                      '${readings[idx].timestamp.day}/${readings[idx].timestamp.month}',
                                      style: const TextStyle(fontSize: 10),
                                    ),
                                  );
                                },
                              ),
                            ),
                            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          ),
                          borderData: FlBorderData(show: false),
                          lineTouchData: LineTouchData(
                            touchTooltipData: LineTouchTooltipData(
                              getTooltipItems: (spots) => spots.map((spot) {
                                final idx = spot.x.toInt();
                                if (idx < 0 || idx >= readings.length) return null;
                                final r = readings[idx];
                                return LineTooltipItem(
                                  '${_getValue(r).toInt()}\n${AppDateUtils.formatDateTime(r.timestamp)}',
                                  const TextStyle(color: Colors.white, fontSize: 12),
                                );
                              }).toList(),
                            ),
                          ),
                          lineBarsData: [
                            LineChartBarData(
                              spots: spots,
                              isCurved: true,
                              color: _metricColor(),
                              barWidth: 3,
                              dotData: FlDotData(
                                show: true,
                                getDotPainter: (spot, percent, bar, index) =>
                                    FlDotCirclePainter(
                                  radius: 4,
                                  color: _metricColor(),
                                  strokeWidth: 2,
                                  strokeColor: Colors.white,
                                ),
                              ),
                              belowBarData: BarAreaData(
                                show: true,
                                color: _metricColor().withValues(alpha: 0.1),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 80),
            ],
          );
        },
      ),
    );
  }
}
