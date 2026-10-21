import '../models/reading.dart';

/// Abstract interface for future wearable and health platform integrations.
///
/// Implementations planned for:
/// - Google Fit
/// - Apple Health (HealthKit)
/// - Bluetooth BP monitors
abstract class WearableIntegrationService {
  Future<bool> isAvailable();
  Future<List<Reading>> importReadings({DateTime? since});
  Future<void> syncLatestReading(Reading reading);
}

/// Placeholder stub until platform integrations are implemented.
class WearableIntegrationStub implements WearableIntegrationService {
  @override
  Future<bool> isAvailable() async => false;

  @override
  Future<List<Reading>> importReadings({DateTime? since}) async => [];

  @override
  Future<void> syncLatestReading(Reading reading) async {}
}
