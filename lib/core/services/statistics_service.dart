import '../models/reading.dart';

/// Aggregated statistics for blood pressure readings.
class ReadingStatistics {
  const ReadingStatistics({
    required this.count,
    this.avgSystolic,
    this.avgDiastolic,
    this.avgPulse,
    this.maxSystolic,
    this.minSystolic,
    this.maxDiastolic,
    this.minDiastolic,
    this.maxPulse,
    this.minPulse,
    this.highestReading,
    this.lowestReading,
  });

  final int count;
  final double? avgSystolic;
  final double? avgDiastolic;
  final double? avgPulse;
  final int? maxSystolic;
  final int? minSystolic;
  final int? maxDiastolic;
  final int? minDiastolic;
  final int? maxPulse;
  final int? minPulse;
  final Reading? highestReading;
  final Reading? lowestReading;

  static ReadingStatistics fromReadings(List<Reading> readings) {
    if (readings.isEmpty) {
      return const ReadingStatistics(count: 0);
    }

    final systolics = readings.map((r) => r.systolic).toList();
    final diastolics = readings.map((r) => r.diastolic).toList();
    final pulses = readings.map((r) => r.pulse).toList();

    Reading? highest;
    Reading? lowest;
    for (final r in readings) {
      if (highest == null || r.systolic > highest.systolic) highest = r;
      if (lowest == null || r.systolic < lowest.systolic) lowest = r;
    }

    return ReadingStatistics(
      count: readings.length,
      avgSystolic: _avg(systolics),
      avgDiastolic: _avg(diastolics),
      avgPulse: _avg(pulses),
      maxSystolic: systolics.reduce((a, b) => a > b ? a : b),
      minSystolic: systolics.reduce((a, b) => a < b ? a : b),
      maxDiastolic: diastolics.reduce((a, b) => a > b ? a : b),
      minDiastolic: diastolics.reduce((a, b) => a < b ? a : b),
      maxPulse: pulses.reduce((a, b) => a > b ? a : b),
      minPulse: pulses.reduce((a, b) => a < b ? a : b),
      highestReading: highest,
      lowestReading: lowest,
    );
  }

  static double _avg(List<int> values) =>
      values.reduce((a, b) => a + b) / values.length;
}

/// Service for computing reading statistics across time periods.
class StatisticsService {
  StatisticsService();

  ReadingStatistics compute(List<Reading> readings) =>
      ReadingStatistics.fromReadings(readings);

  Map<String, ReadingStatistics> weeklyAverages(List<Reading> readings) {
    final grouped = <String, List<Reading>>{};
    for (final r in readings) {
      final weekStart = _weekKey(r.timestamp);
      grouped.putIfAbsent(weekStart, () => []).add(r);
    }
    return grouped.map((k, v) => MapEntry(k, ReadingStatistics.fromReadings(v)));
  }

  Map<String, ReadingStatistics> monthlyAverages(List<Reading> readings) {
    final grouped = <String, List<Reading>>{};
    for (final r in readings) {
      final key = '${r.timestamp.year}-${r.timestamp.month.toString().padLeft(2, '0')}';
      grouped.putIfAbsent(key, () => []).add(r);
    }
    return grouped.map((k, v) => MapEntry(k, ReadingStatistics.fromReadings(v)));
  }

  Map<String, ReadingStatistics> yearlyAverages(List<Reading> readings) {
    final grouped = <String, List<Reading>>{};
    for (final r in readings) {
      final key = r.timestamp.year.toString();
      grouped.putIfAbsent(key, () => []).add(r);
    }
    return grouped.map((k, v) => MapEntry(k, ReadingStatistics.fromReadings(v)));
  }

  String _weekKey(DateTime date) {
    final weekStart = date.subtract(Duration(days: date.weekday - 1));
    return '${weekStart.year}-W${((weekStart.day / 7).ceil())}';
  }
}
