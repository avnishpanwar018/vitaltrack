import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';

import '../models/reading.dart';

/// Android home screen widget integration.
class HomeWidgetService {
  HomeWidgetService();

  static const _appGroupId = 'group.com.vitaltrack.app';
  static const _bpKey = 'latest_bp';
  static const _pulseKey = 'latest_pulse';
  static const _timeKey = 'latest_time';

  Future<void> initialize() async {
    if (kIsWeb) return;
    try {
      await HomeWidget.setAppGroupId(_appGroupId);
    } catch (_) {
      // Widget may not be configured on all platforms
    }
  }

  Future<void> updateWidget(Reading? reading) async {
    if (kIsWeb) return;
    if (reading == null) {
      await HomeWidget.saveWidgetData<String>(_bpKey, '-- / --');
      await HomeWidget.saveWidgetData<String>(_pulseKey, '--');
      await HomeWidget.saveWidgetData<String>(_timeKey, 'No readings');
    } else {
      await HomeWidget.saveWidgetData<String>(_bpKey, reading.bpDisplay);
      await HomeWidget.saveWidgetData<String>(_pulseKey, '${reading.pulse}');
      await HomeWidget.saveWidgetData<String>(
        _timeKey,
        reading.timestamp.toIso8601String(),
      );
    }
    try {
      await HomeWidget.updateWidget(
        androidName: 'VitalTrackWidget',
        iOSName: 'VitalTrackWidget',
      );
    } catch (_) {}
  }
}
