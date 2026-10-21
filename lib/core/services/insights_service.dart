import '../models/reading.dart';
import '../utils/constants.dart';

/// AI-style health insights — informational only, never diagnostic.
class HealthInsight {
  const HealthInsight({
    required this.title,
    required this.message,
    required this.icon,
    required this.type,
  });

  final String title;
  final String message;
  final String icon;
  final InsightType type;
}

enum InsightType { positive, neutral, caution, tip }

/// Generates pattern-based health insights from reading history.
class InsightsService {
  InsightsService();

  List<HealthInsight> generateInsights(List<Reading> readings) {
    if (readings.length < 2) {
      return [
        const HealthInsight(
          title: 'Getting Started',
          message:
              'Add more readings to unlock personalized health insights and trends.',
          icon: 'insights',
          type: InsightType.tip,
        ),
        const HealthInsight(
          title: 'Consistency Tip',
          message:
              'Consider measuring your BP at the same time each day for more accurate tracking.',
          icon: 'schedule',
          type: InsightType.tip,
        ),
      ];
    }

    final insights = <HealthInsight>[];
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    final twoWeeksAgo = now.subtract(const Duration(days: 14));

    final thisWeek = readings.where((r) => r.timestamp.isAfter(weekAgo)).toList();
    final lastWeek = readings
        .where((r) =>
            r.timestamp.isAfter(twoWeeksAgo) && r.timestamp.isBefore(weekAgo))
        .toList();

    if (thisWeek.isNotEmpty && lastWeek.isNotEmpty) {
      final thisAvg =
          thisWeek.map((r) => r.systolic).reduce((a, b) => a + b) / thisWeek.length;
      final lastAvg =
          lastWeek.map((r) => r.systolic).reduce((a, b) => a + b) / lastWeek.length;
      final diff = (thisAvg - lastAvg).round();

      if (diff < -2) {
        insights.add(HealthInsight(
          title: 'Systolic Trend',
          message:
              'Your average systolic pressure decreased by ${diff.abs()} mmHg this week.',
          icon: 'trending_down',
          type: InsightType.positive,
        ));
      } else if (diff > 2) {
        insights.add(HealthInsight(
          title: 'Systolic Trend',
          message:
              'Your average systolic pressure increased by $diff mmHg this week. Monitor closely.',
          icon: 'trending_up',
          type: InsightType.caution,
        ));
      }
    }

    // Pulse stability
    if (readings.length >= 5) {
      final recent = readings.take(10).map((r) => r.pulse).toList();
      final avgPulse = recent.reduce((a, b) => a + b) / recent.length;
      final variance = recent.map((p) => (p - avgPulse).abs()).reduce((a, b) => a + b) / recent.length;
      if (variance < 5) {
        insights.add(const HealthInsight(
          title: 'Pulse Stability',
          message: 'Your pulse has remained stable across recent readings.',
          icon: 'favorite',
          type: InsightType.positive,
        ));
      }
    }

    // Weekday vs weekend pattern
    final weekdayReadings = readings.where((r) => r.timestamp.weekday <= 5).toList();
    final weekendReadings = readings.where((r) => r.timestamp.weekday > 5).toList();
    if (weekdayReadings.length >= 3 && weekendReadings.length >= 2) {
      final weekdayAvg = weekdayReadings.map((r) => r.systolic).reduce((a, b) => a + b) /
          weekdayReadings.length;
      final weekendAvg = weekendReadings.map((r) => r.systolic).reduce((a, b) => a + b) /
          weekendReadings.length;
      if (weekdayAvg - weekendAvg > 5) {
        insights.add(const HealthInsight(
          title: 'Weekly Pattern',
          message:
              'Blood pressure appears elevated on weekdays compared to weekends.',
          icon: 'calendar_today',
          type: InsightType.neutral,
        ));
      }
    }

    insights.add(const HealthInsight(
      title: 'Measurement Tip',
      message:
          'Consider measuring your BP at the same time each day for consistent tracking.',
      icon: 'schedule',
      type: InsightType.tip,
    ));

    insights.add(const HealthInsight(
      title: 'Disclaimer',
      message: AppConstants.medicalDisclaimer,
      icon: 'info',
      type: InsightType.neutral,
    ));

    return insights;
  }
}
