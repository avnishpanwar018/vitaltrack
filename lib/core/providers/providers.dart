import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../database/database_helper.dart';
import '../repositories/attachment_repository.dart';
import '../repositories/profile_repository.dart';
import '../repositories/reading_repository.dart';
import '../repositories/reminder_repository.dart';
import '../repositories/in_memory_repositories.dart';
import '../repositories/in_memory_data_store.dart';
import '../services/encryption_service.dart';
import '../services/home_widget_service.dart';
import '../services/insights_service.dart';
import '../services/notification_service.dart';
import '../services/report_service.dart';
import '../services/security_service.dart';
import '../services/settings_service.dart';
import '../services/statistics_service.dart';
import '../models/profile.dart';
import '../models/reading.dart';
import '../models/reminder.dart';

// ── Core Dependencies ──

final databaseHelperProvider = Provider<DatabaseHelper>((ref) {
  return DatabaseHelper.instance;
});

final sharedPreferencesProvider = FutureProvider<SharedPreferences>((ref) async {
  return SharedPreferences.getInstance();
});

final settingsServiceProvider = FutureProvider<SettingsService>((ref) async {
  final prefs = await ref.watch(sharedPreferencesProvider.future);
  return SettingsService(prefs);
});

// ── In-Memory singletons for Web environment ──
final _inMemoryDataStoreProvider = Provider<InMemoryDataStore>((ref) {
  return InMemoryDataStore();
});

final _inMemoryReadingRepositoryProvider = Provider<InMemoryReadingRepository>((ref) {
  return InMemoryReadingRepository(ref.watch(_inMemoryDataStoreProvider));
});

final _inMemoryProfileRepositoryProvider = Provider<InMemoryProfileRepository>((ref) {
  return InMemoryProfileRepository(ref.watch(_inMemoryDataStoreProvider));
});

final _inMemoryReminderRepositoryProvider = Provider<InMemoryReminderRepository>((ref) {
  return InMemoryReminderRepository(ref.watch(_inMemoryDataStoreProvider));
});

final _inMemoryAttachmentRepositoryProvider = Provider<InMemoryAttachmentRepository>((ref) {
  return InMemoryAttachmentRepository(ref.watch(_inMemoryDataStoreProvider));
});

// ── Providers with Web Failsafes ──
final readingRepositoryProvider = Provider<ReadingRepository>((ref) {
  if (kIsWeb) {
    return ref.watch(_inMemoryReadingRepositoryProvider);
  }
  return ReadingRepository(ref.watch(databaseHelperProvider));
});

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  if (kIsWeb) {
    return ref.watch(_inMemoryProfileRepositoryProvider);
  }
  return ProfileRepository(ref.watch(databaseHelperProvider));
});

final reminderRepositoryProvider = Provider<ReminderRepository>((ref) {
  if (kIsWeb) {
    return ref.watch(_inMemoryReminderRepositoryProvider);
  }
  return ReminderRepository(ref.watch(databaseHelperProvider));
});

final attachmentRepositoryProvider = Provider<AttachmentRepository>((ref) {
  if (kIsWeb) {
    return ref.watch(_inMemoryAttachmentRepositoryProvider);
  }
  return AttachmentRepository(ref.watch(databaseHelperProvider));
});

final statisticsServiceProvider = Provider<StatisticsService>((ref) {
  return StatisticsService();
});

final insightsServiceProvider = Provider<InsightsService>((ref) {
  return InsightsService();
});

final reportServiceProvider = Provider<ReportService>((ref) {
  return ReportService(ref.watch(statisticsServiceProvider));
});

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

final homeWidgetServiceProvider = Provider<HomeWidgetService>((ref) {
  return HomeWidgetService();
});

final encryptionServiceProvider = Provider<EncryptionService>((ref) {
  return EncryptionService();
});

final securityServiceProvider = Provider<SecurityService>((ref) {
  return SecurityService(ref.watch(encryptionServiceProvider));
});

// ── App State ──

final activeProfileProvider = StateNotifierProvider<ActiveProfileNotifier, AsyncValue<Profile?>>((ref) {
  return ActiveProfileNotifier(ref);
});

class ActiveProfileNotifier extends StateNotifier<AsyncValue<Profile?>> {
  ActiveProfileNotifier(this._ref) : super(const AsyncValue.loading()) {
    _init();
  }

  final Ref _ref;

  Future<void> _init() async {
    try {
      final profileRepo = _ref.read(profileRepositoryProvider);
      final settings = await _ref.read(settingsServiceProvider.future);
      final defaultProfile = await profileRepo.ensureDefaultProfile();

      final savedId = settings.activeProfileId;
      Profile? active;
      if (savedId != null) {
        active = await profileRepo.getById(savedId);
      }
      active ??= defaultProfile;
      await settings.setActiveProfileId(active.id);
      state = AsyncValue.data(active);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> setProfile(Profile profile) async {
    state = AsyncValue.data(profile);
    final settings = await _ref.read(settingsServiceProvider.future);
    await settings.setActiveProfileId(profile.id);
    _ref.invalidate(readingsProvider);
    _ref.invalidate(latestReadingProvider);
    _ref.invalidate(dashboardStatsProvider);
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    await _init();
  }
}

final profilesProvider = FutureProvider<List<Profile>>((ref) async {
  final repo = ref.watch(profileRepositoryProvider);
  return repo.getAll();
});

final readingsProvider = FutureProvider<List<Reading>>((ref) async {
  final profileState = ref.watch(activeProfileProvider);
  if (profileState.hasError) {
    throw profileState.error!;
  }
  final profile = profileState.valueOrNull;
  if (profile == null) return [];
  final repo = ref.watch(readingRepositoryProvider);
  return repo.getAll(profileId: profile.id);
});

final latestReadingProvider = FutureProvider<Reading?>((ref) async {
  final profileState = ref.watch(activeProfileProvider);
  if (profileState.hasError) {
    throw profileState.error!;
  }
  final profile = profileState.valueOrNull;
  if (profile == null) return null;
  final repo = ref.watch(readingRepositoryProvider);
  return repo.getLatest(profile.id);
});

final remindersProvider = FutureProvider<List<Reminder>>((ref) async {
  final repo = ref.watch(reminderRepositoryProvider);
  return repo.getAll();
});

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, String>((ref) {
  return ThemeModeNotifier(ref);
});

class ThemeModeNotifier extends StateNotifier<String> {
  ThemeModeNotifier(this._ref) : super('system') {
    _load();
  }

  final Ref _ref;

  Future<void> _load() async {
    final settings = await _ref.read(settingsServiceProvider.future);
    state = settings.themeMode;
  }

  Future<void> setMode(String mode) async {
    state = mode;
    final settings = await _ref.read(settingsServiceProvider.future);
    await settings.setThemeMode(mode);
  }
}

final dashboardStatsProvider = FutureProvider<DashboardStats>((ref) async {
  final profileState = ref.watch(activeProfileProvider);
  if (profileState.hasError) {
    throw profileState.error!;
  }
  final profile = profileState.valueOrNull;
  if (profile == null) return DashboardStats.empty();

  final repo = ref.watch(readingRepositoryProvider);
  final statsService = ref.watch(statisticsServiceProvider);
  final now = DateTime.now();

  final weekStart = DateTime(now.year, now.month, now.day)
      .subtract(Duration(days: now.weekday - 1));
  final monthStart = DateTime(now.year, now.month, 1);
  final todayStart = DateTime(now.year, now.month, now.day);

  final weekReadings = await repo.getByDateRange(
    profileId: profile.id,
    start: weekStart,
    end: now,
  );
  final monthReadings = await repo.getByDateRange(
    profileId: profile.id,
    start: monthStart,
    end: now,
  );
  final todayReadings = await repo.getByDateRange(
    profileId: profile.id,
    start: todayStart,
    end: now,
  );

  return DashboardStats(
    weekly: statsService.compute(weekReadings),
    monthly: statsService.compute(monthReadings),
    todayCount: todayReadings.length,
  );
});

class DashboardStats {
  const DashboardStats({
    required this.weekly,
    required this.monthly,
    required this.todayCount,
  });

  final ReadingStatistics weekly;
  final ReadingStatistics monthly;
  final int todayCount;

  factory DashboardStats.empty() => DashboardStats(
        weekly: ReadingStatistics.fromReadings([]),
        monthly: ReadingStatistics.fromReadings([]),
        todayCount: 0,
      );
}

// Reading actions notifier
final readingActionsProvider = Provider<ReadingActions>((ref) {
  return ReadingActions(ref);
});

class ReadingActions {
  ReadingActions(this._ref);
  final Ref _ref;

  Future<void> addReading(Reading reading) async {
    final repo = _ref.read(readingRepositoryProvider);
    await repo.insert(reading);
    await _ref.read(homeWidgetServiceProvider).updateWidget(reading);
    _ref.invalidate(readingsProvider);
    _ref.invalidate(latestReadingProvider);
    _ref.invalidate(dashboardStatsProvider);
  }

  Future<void> updateReading(Reading reading) async {
    final repo = _ref.read(readingRepositoryProvider);
    await repo.update(reading);
    _ref.invalidate(readingsProvider);
    _ref.invalidate(latestReadingProvider);
    _ref.invalidate(dashboardStatsProvider);
  }

  Future<void> deleteReading(String id) async {
    final repo = _ref.read(readingRepositoryProvider);
    await repo.delete(id);
    final latest = await _ref.read(latestReadingProvider.future);
    await _ref.read(homeWidgetServiceProvider).updateWidget(latest);
    _ref.invalidate(readingsProvider);
    _ref.invalidate(latestReadingProvider);
    _ref.invalidate(dashboardStatsProvider);
  }
}
