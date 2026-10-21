import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vitaltrack/main.dart';
import 'package:vitaltrack/core/providers/providers.dart';
import 'package:vitaltrack/core/models/profile.dart';
import 'package:vitaltrack/core/models/reading.dart';
import 'package:vitaltrack/core/models/reminder.dart';
import 'package:vitaltrack/core/repositories/profile_repository.dart';
import 'package:vitaltrack/core/repositories/reading_repository.dart';
import 'package:vitaltrack/core/services/notification_service.dart';
import 'package:vitaltrack/core/services/home_widget_service.dart';
import 'package:vitaltrack/core/database/database_helper.dart';

class FakeProfileRepository extends ProfileRepository {
  FakeProfileRepository() : super(DatabaseHelper.instance);

  static const Profile _defaultProfile = Profile(
    id: 'default-profile-id',
    name: 'Me',
    relationship: 'Self',
    isDefault: true,
  );

  @override
  Future<Profile> ensureDefaultProfile() async => _defaultProfile;

  @override
  Future<Profile?> getById(String id) async => _defaultProfile;

  @override
  Future<List<Profile>> getAll() async => [_defaultProfile];

  @override
  Future<Profile?> getDefault() async => _defaultProfile;

  @override
  Future<void> insert(Profile profile) async {}
  @override
  Future<void> update(Profile profile) async {}
  @override
  Future<void> delete(String id) async {}
  @override
  Future<void> setDefault(String id) async {}
}

class FakeReadingRepository extends ReadingRepository {
  FakeReadingRepository() : super(DatabaseHelper.instance);

  @override
  Future<void> insert(Reading reading) async {}
  @override
  Future<void> update(Reading reading) async {}
  @override
  Future<void> delete(String id) async {}

  @override
  Future<Reading?> getById(String id) async => null;

  @override
  Future<Reading?> getLatest(String profileId) async => null;

  @override
  Future<List<Reading>> getAll({
    required String profileId,
    int? limit,
    int? offset,
    bool newestFirst = true,
  }) async => [];

  @override
  Future<List<Reading>> getByDateRange({
    required String profileId,
    required DateTime start,
    required DateTime end,
  }) async => [];

  @override
  Future<List<Reading>> search({
    required String profileId,
    String? query,
    int? minSystolic,
    int? maxSystolic,
    int? minDiastolic,
    int? maxDiastolic,
    int? minPulse,
    int? maxPulse,
    DateTime? startDate,
    DateTime? endDate,
  }) async => [];

  @override
  Future<int> count(String profileId) async => 0;
}

class FakeNotificationService extends NotificationService {
  @override
  Future<void> initialize() async {}

  @override
  Future<bool> requestPermissions() async => true;

  @override
  Future<void> scheduleReminder(Reminder reminder) async {}

  @override
  Future<void> scheduleAllReminders(List<Reminder> reminders) async {}

  @override
  Future<void> cancelReminder(String id) async {}

  @override
  Future<void> cancelAll() async {}

  @override
  Future<void> showMissedReminderNotification() async {}
}

class FakeHomeWidgetService extends HomeWidgetService {
  @override
  Future<void> initialize() async {}

  @override
  Future<void> updateWidget(Reading? reading) async {}
}

void main() {
  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('VitalTrack app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          profileRepositoryProvider.overrideWithValue(FakeProfileRepository()),
          readingRepositoryProvider.overrideWithValue(FakeReadingRepository()),
          notificationServiceProvider.overrideWithValue(FakeNotificationService()),
          homeWidgetServiceProvider.overrideWithValue(FakeHomeWidgetService()),
        ],
        child: const VitalTrackApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Good'), findsOneWidget);
  });
}
