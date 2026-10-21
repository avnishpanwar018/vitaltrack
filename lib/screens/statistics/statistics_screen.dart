import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/providers.dart';
import '../../core/services/statistics_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/date_utils.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/skeleton_loader.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/vital_card.dart';

class StatisticsScreen extends ConsumerWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final readingsAsync = ref.watch(readingsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Statistics')),
      body: readingsAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(20),
          child: SkeletonLoader(height: 400),
        ),
        error: (e, _) => EmptyStateWidget(
          icon: Icons.error_outline,
          title: 'Error loading statistics',
          message: e.toString(),
        ),
        data: (readings) {
          if (readings.isEmpty) {
            return const EmptyStateWidget(
              icon: Icons.analytics_outlined,
              title: 'No data yet',
              message: 'Add readings to see your statistics.',
            );
          }

          final statsService = ref.watch(statisticsServiceProvider);
          final allStats = statsService.compute(readings);
          final weekly = statsService.weeklyAverages(readings);
          final monthly = statsService.monthlyAverages(readings);
          final yearly = statsService.yearlyAverages(readings);

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(readingsProvider),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  'Overview',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.4,
                  children: [
                    StatCard(
                      label: 'Avg Systolic',
                      value: allStats.avgSystolic?.toStringAsFixed(0) ?? '--',
                      unit: 'mmHg',
                      icon: Icons.arrow_upward,
                      color: AppColors.systolicColor,
                    ),
                    StatCard(
                      label: 'Avg Diastolic',
                      value: allStats.avgDiastolic?.toStringAsFixed(0) ?? '--',
                      unit: 'mmHg',
                      icon: Icons.arrow_downward,
                      color: AppColors.diastolicColor,
                    ),
                    StatCard(
                      label: 'Avg Pulse',
                      value: allStats.avgPulse?.toStringAsFixed(0) ?? '--',
                      unit: 'BPM',
                      icon: Icons.favorite,
                      color: AppColors.pulseColor,
                    ),
                    StatCard(
                      label: 'Total Readings',
                      value: '${allStats.count}',
                      icon: Icons.format_list_numbered,
                      color: AppColors.primaryBlue,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  'Extremes',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: VitalCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Highest',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.error,
                                )),
                            const SizedBox(height: 4),
                            Text(
                              allStats.highestReading?.bpDisplay ?? '--',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (allStats.highestReading != null)
                              Text(
                                AppDateUtils.formatDate(allStats.highestReading!.timestamp),
                                style: theme.textTheme.bodySmall,
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: VitalCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Lowest',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: AppColors.success,
                                )),
                            const SizedBox(height: 4),
                            Text(
                              allStats.lowestReading?.bpDisplay ?? '--',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (allStats.lowestReading != null)
                              Text(
                                AppDateUtils.formatDate(allStats.lowestReading!.timestamp),
                                style: theme.textTheme.bodySmall,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _PeriodSection(title: 'Weekly Averages', data: weekly),
                const SizedBox(height: 16),
                _PeriodSection(title: 'Monthly Averages', data: monthly),
                const SizedBox(height: 16),
                _PeriodSection(title: 'Yearly Averages', data: yearly),
                const SizedBox(height: 80),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _PeriodSection extends StatelessWidget {
  const _PeriodSection({required this.title, required this.data});

  final String title;
  final Map<String, ReadingStatistics> data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (data.isEmpty) return const SizedBox.shrink();

    final entries = data.entries.toList().reversed.take(6).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        ...entries.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: VitalCard(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(e.key, style: theme.textTheme.bodyMedium),
                    Text(
                      '${e.value.avgSystolic?.toStringAsFixed(0) ?? '--'} / ${e.value.avgDiastolic?.toStringAsFixed(0) ?? '--'}',
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            )),
      ],
    );
  }
}
