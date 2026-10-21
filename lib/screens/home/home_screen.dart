import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/bp_classification.dart';
import '../../core/providers/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/app_router.dart';
import '../../core/utils/date_utils.dart';
import '../../widgets/bp_status_badge.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/skeleton_loader.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/vital_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(activeProfileProvider);
    final latestAsync = ref.watch(latestReadingProvider);
    final statsAsync = ref.watch(dashboardStatsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(latestReadingProvider);
            ref.invalidate(dashboardStatsProvider);
          },
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppDateUtils.getGreeting(),
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      profileAsync.when(
                        data: (profile) => Text(
                          profile?.name ?? 'Welcome',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => const SizedBox.shrink(),
                      ),
                      const SizedBox(height: 8),
                      const DisclaimerBanner(compact: true),
                    ],
                  ),
                ),
              ),
              latestAsync.when(
                loading: () => const SliverToBoxAdapter(child: DashboardSkeleton()),
                error: (e, _) => SliverToBoxAdapter(
                  child: EmptyStateWidget(
                    icon: Icons.error_outline,
                    title: 'Something went wrong',
                    message: e.toString(),
                  ),
                ),
                data: (reading) {
                  if (reading == null) {
                    return SliverFillRemaining(
                      hasScrollBody: false,
                      child: EmptyStateWidget(
                        icon: Icons.monitor_heart_outlined,
                        title: 'No readings yet',
                        message:
                            'Start tracking your blood pressure by adding your first reading.',
                        actionLabel: 'Add Reading',
                        onAction: () => context.push(AppRoutes.addReading),
                      ),
                    );
                  }

                  final classification =
                      BpClassification.classify(reading.systolic, reading.diastolic);

                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          VitalCard(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.primaryGreen,
                                AppColors.primaryGreen.withValues(alpha: 0.8),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Health Summary',
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        color: Colors.white.withValues(alpha: 0.9),
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () => context.push(AppRoutes.insights),
                                      icon: const Icon(Icons.insights, color: Colors.white),
                                      tooltip: 'Health Insights',
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _SummaryItem(
                                        label: 'Blood Pressure',
                                        value: reading.bpDisplay,
                                        unit: 'mmHg',
                                      ),
                                    ),
                                    Container(
                                      width: 1,
                                      height: 50,
                                      color: Colors.white.withValues(alpha: 0.2),
                                    ),
                                    Expanded(
                                      child: _SummaryItem(
                                        label: 'Pulse',
                                        value: '${reading.pulse}',
                                        unit: 'BPM',
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    BpStatusBadge(
                                      classification: classification,
                                      compact: true,
                                    ),
                                    Text(
                                      AppDateUtils.formatRelative(reading.timestamp),
                                      style: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.8),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          statsAsync.when(
                            loading: () => const SkeletonLoader(height: 90),
                            error: (_, __) => const SizedBox.shrink(),
                            data: (stats) => Row(
                              children: [
                                Expanded(
                                  child: StatCard(
                                    label: 'Weekly Avg',
                                    value: stats.weekly.avgSystolic?.toStringAsFixed(0) ?? '--',
                                    unit: '/ ${stats.weekly.avgDiastolic?.toStringAsFixed(0) ?? '--'}',
                                    icon: Icons.date_range,
                                    color: AppColors.primaryBlue,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: StatCard(
                                    label: 'Monthly Avg',
                                    value: stats.monthly.avgSystolic?.toStringAsFixed(0) ?? '--',
                                    unit: '/ ${stats.monthly.avgDiastolic?.toStringAsFixed(0) ?? '--'}',
                                    icon: Icons.calendar_month,
                                    color: AppColors.accentTeal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          VitalCard(
                            onTap: () => context.push(AppRoutes.reports),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryBlue.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(Icons.description_outlined,
                                      color: AppColors.primaryBlue),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Generate Report',
                                          style: theme.textTheme.titleSmall
                                              ?.copyWith(fontWeight: FontWeight.w600)),
                                      Text(
                                        'Export PDF or CSV for your doctor',
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: theme.colorScheme.onSurface
                                              .withValues(alpha: 0.5),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.chevron_right),
                              ],
                            ),
                          ),
                          const SizedBox(height: 80),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({
    required this.label,
    required this.value,
    required this.unit,
  });

  final String label;
  final String value;
  final String unit;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          unit,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
