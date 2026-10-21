import '../database/database_helper.dart';
import '../models/profile.dart';
import '../models/reading.dart';
import '../models/reminder.dart';
import '../models/attachment.dart';
import 'profile_repository.dart';
import 'reading_repository.dart';
import 'reminder_repository.dart';
import 'attachment_repository.dart';
import 'in_memory_data_store.dart';

class InMemoryProfileRepository extends ProfileRepository {
  InMemoryProfileRepository([InMemoryDataStore? store])
      : _store = store ?? InMemoryDataStore(),
        super(DatabaseHelper.instance);

  final InMemoryDataStore _store;

  @override
  Future<void> insert(Profile profile) async {
    await _store.ensureLoaded();
    if (profile.isDefault) {
      for (var i = 0; i < _store.profiles.length; i++) {
        _store.profiles[i] = _store.profiles[i].copyWith(isDefault: false);
      }
    }
    _store.profiles.add(profile);
    await _store.saveProfiles();
  }

  @override
  Future<void> update(Profile profile) async {
    await _store.ensureLoaded();
    final idx = _store.profiles.indexWhere((p) => p.id == profile.id);
    if (idx != -1) {
      if (profile.isDefault) {
        for (var i = 0; i < _store.profiles.length; i++) {
          _store.profiles[i] = _store.profiles[i].copyWith(isDefault: false);
        }
      }
      _store.profiles[idx] = profile;
      await _store.saveProfiles();
    }
  }

  @override
  Future<void> delete(String id) async {
    await _store.deleteProfile(id);
  }

  @override
  Future<List<Profile>> getAll() async {
    await _store.ensureLoaded();
    final result = List<Profile>.from(_store.profiles);
    result.sort((a, b) {
      final defaultComparison = (b.isDefault ? 1 : 0).compareTo(a.isDefault ? 1 : 0);
      return defaultComparison == 0
          ? a.name.toLowerCase().compareTo(b.name.toLowerCase())
          : defaultComparison;
    });
    return result;
  }

  @override
  Future<Profile?> getById(String id) async {
    await _store.ensureLoaded();
    final found = _store.profiles.where((p) => p.id == id).toList();
    return found.isNotEmpty ? found.first : null;
  }

  @override
  Future<Profile?> getDefault() async {
    await _store.ensureLoaded();
    final defaultProfiles = _store.profiles.where((p) => p.isDefault).toList();
    if (defaultProfiles.isNotEmpty) return defaultProfiles.first;
    return _store.profiles.isNotEmpty ? _store.profiles.first : null;
  }

  @override
  Future<Profile> ensureDefaultProfile() async {
    final existing = await getDefault();
    if (existing != null) return existing;

    const profile = Profile(
      id: 'default-profile-web',
      name: 'Me',
      relationship: 'Self',
      isDefault: true,
    );
    await insert(profile);
    return profile;
  }

  @override
  Future<void> setDefault(String id) async {
    await _store.ensureLoaded();
    for (var i = 0; i < _store.profiles.length; i++) {
      _store.profiles[i] =
          _store.profiles[i].copyWith(isDefault: _store.profiles[i].id == id);
    }
    await _store.saveProfiles();
  }
}

class InMemoryReadingRepository extends ReadingRepository {
  InMemoryReadingRepository([InMemoryDataStore? store])
      : _store = store ?? InMemoryDataStore(),
        super(DatabaseHelper.instance);

  final InMemoryDataStore _store;

  @override
  Future<void> insert(Reading reading) async {
    await _store.ensureLoaded();
    _store.readings.add(reading);
    await _store.saveReadings();
  }

  @override
  Future<void> update(Reading reading) async {
    await _store.ensureLoaded();
    final idx = _store.readings.indexWhere((r) => r.id == reading.id);
    if (idx != -1) {
      _store.readings[idx] = reading;
      await _store.saveReadings();
    }
  }

  @override
  Future<void> delete(String id) async {
    await _store.ensureLoaded();
    _store.readings.removeWhere((r) => r.id == id);
    await _store.saveReadings();
  }

  @override
  Future<Reading?> getById(String id) async {
    await _store.ensureLoaded();
    final found = _store.readings.where((r) => r.id == id).toList();
    return found.isNotEmpty ? found.first : null;
  }

  @override
  Future<Reading?> getLatest(String profileId) async {
    await _store.ensureLoaded();
    final profileReadings =
        _store.readings.where((r) => r.profileId == profileId).toList();
    if (profileReadings.isEmpty) return null;
    profileReadings.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return profileReadings.first;
  }

  @override
  Future<List<Reading>> getAll({
    required String profileId,
    int? limit,
    int? offset,
    bool newestFirst = true,
  }) async {
    await _store.ensureLoaded();
    final list = _store.readings.where((r) => r.profileId == profileId).toList();
    list.sort((a, b) => newestFirst 
      ? b.timestamp.compareTo(a.timestamp) 
      : a.timestamp.compareTo(b.timestamp));
    
    var result = list;
    if (offset != null) {
      if (offset >= result.length) return [];
      result = result.sublist(offset);
    }
    if (limit != null && limit < result.length) {
      result = result.sublist(0, limit);
    }
    return result;
  }

  @override
  Future<List<Reading>> getByDateRange({
    required String profileId,
    required DateTime start,
    required DateTime end,
  }) async {
    await _store.ensureLoaded();
    final list = _store.readings.where((r) =>
      r.profileId == profileId && 
      !r.timestamp.isBefore(start) &&
      !r.timestamp.isAfter(end)
    ).toList();
    list.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return list;
  }

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
  }) async {
    await _store.ensureLoaded();
    var list = _store.readings.where((r) => r.profileId == profileId).toList();
    if (minSystolic != null) list = list.where((r) => r.systolic >= minSystolic).toList();
    if (maxSystolic != null) list = list.where((r) => r.systolic <= maxSystolic).toList();
    if (minDiastolic != null) list = list.where((r) => r.diastolic >= minDiastolic).toList();
    if (maxDiastolic != null) list = list.where((r) => r.diastolic <= maxDiastolic).toList();
    if (minPulse != null) list = list.where((r) => r.pulse >= minPulse).toList();
    if (maxPulse != null) list = list.where((r) => r.pulse <= maxPulse).toList();
    if (startDate != null) list = list.where((r) => !r.timestamp.isBefore(startDate)).toList();
    if (endDate != null) list = list.where((r) => !r.timestamp.isAfter(endDate)).toList();
    if (query != null && query.isNotEmpty) {
      final q = query.toLowerCase();
      list = list.where((r) => 
        (r.notes?.toLowerCase().contains(q) ?? false) || 
        r.symptoms.any((s) => s.toLowerCase().contains(q)) || 
        (r.mood?.toLowerCase().contains(q) ?? false)
      ).toList();
    }
    list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return list;
  }

  @override
  Future<int> count(String profileId) async {
    await _store.ensureLoaded();
    return _store.readings.where((r) => r.profileId == profileId).length;
  }
}

class InMemoryReminderRepository extends ReminderRepository {
  InMemoryReminderRepository([InMemoryDataStore? store])
      : _store = store ?? InMemoryDataStore(),
        super(DatabaseHelper.instance);

  final InMemoryDataStore _store;

  @override
  Future<void> insert(Reminder reminder) async {
    await _store.ensureLoaded();
    _store.reminders.add(reminder);
    await _store.saveReminders();
  }

  @override
  Future<void> update(Reminder reminder) async {
    await _store.ensureLoaded();
    final idx = _store.reminders.indexWhere((r) => r.id == reminder.id);
    if (idx != -1) {
      _store.reminders[idx] = reminder;
      await _store.saveReminders();
    }
  }

  @override
  Future<void> delete(String id) async {
    await _store.ensureLoaded();
    _store.reminders.removeWhere((r) => r.id == id);
    await _store.saveReminders();
  }

  @override
  Future<List<Reminder>> getAll() async {
    await _store.ensureLoaded();
    final result = List<Reminder>.from(_store.reminders);
    result.sort((a, b) => a.time.compareTo(b.time));
    return result;
  }

  @override
  Future<List<Reminder>> getEnabled() async {
    await _store.ensureLoaded();
    return _store.reminders.where((r) => r.enabled).toList()
      ..sort((a, b) => a.time.compareTo(b.time));
  }
}

class InMemoryAttachmentRepository extends AttachmentRepository {
  InMemoryAttachmentRepository([InMemoryDataStore? store])
      : _store = store ?? InMemoryDataStore(),
        super(DatabaseHelper.instance);

  final InMemoryDataStore _store;

  @override
  Future<void> insert(Attachment attachment) async {
    await _store.ensureLoaded();
    _store.attachments.add(attachment);
    await _store.saveAttachments();
  }

  @override
  Future<void> delete(String id) async {
    await _store.ensureLoaded();
    _store.attachments.removeWhere((a) => a.id == id);
    await _store.saveAttachments();
  }

  @override
  Future<List<Attachment>> getByProfile(String profileId) async {
    await _store.ensureLoaded();
    final result = _store.attachments.where((a) => a.profileId == profileId).toList();
    result.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return result;
  }
}
