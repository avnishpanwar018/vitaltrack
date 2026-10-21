import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/providers.dart';
import '../../core/services/insights_service.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/vital_card.dart';

class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});

  IconData _iconForType(InsightType type) {
    switch (type) {
      case InsightType.positive:
        return Icons.trending_down;
      case InsightType.caution:
        return Icons.trending_up;
      case InsightType.tip:
        return Icons.lightbulb_outline;
      case InsightType.neutral:
        return Icons.info_outline;
    }
  }

  Color _colorForType(InsightType type) {
    switch (type) {
      case InsightType.positive:
        return AppColors.success;
      case InsightType.caution:
        return AppColors.warning;
      case InsightType.tip:
        return AppColors.primaryBlue;
      case InsightType.neutral:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final readingsAsync = ref.watch(readingsProvider);
    final insightsService = ref.watch(insightsServiceProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Health Insights')),
      body: readingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (readings) {
          final insights = insightsService.generateInsights(readings);

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              VitalCard(
                color: AppColors.primaryBlue.withValues(alpha: 0.08),
                child: Row(
                  children: [
                    const Icon(Icons.psychology, color: AppColors.primaryBlue),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'These insights are based on your recorded data patterns. '
                        'They are not medical advice.',
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              ...insights.map((insight) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: VitalCard(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: _colorForType(insight.type).withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _iconForType(insight.type),
                              color: _colorForType(insight.type),
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  insight.title,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  insight.message,
                                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  )),
            ],
          );
        },
      ),
    );
  }
}
