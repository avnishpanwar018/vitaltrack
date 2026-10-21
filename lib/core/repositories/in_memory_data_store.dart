import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/attachment.dart';
import '../models/profile.dart';
import '../models/reading.dart';
import '../models/reminder.dart';

/// Persistent store used by the web repositories.
///
/// SQLite is not available in the browser build, so web data is kept in
/// SharedPreferences (localStorage) instead of process memory. Keeping all
/// collections in one store also lets profile deletion mirror SQLite's
/// foreign-key cascade behavior.
class InMemoryDataStore {
  InMemoryDataStore({Future<SharedPreferences>? preferences})
      : _preferences = preferences ?? SharedPreferences.getInstance();

  static const _profilesKey = 'vitaltrack.web.profiles';
  static const _readingsKey = 'vitaltrack.web.readings';
  static const _remindersKey = 'vitaltrack.web.reminders';
  static const _attachmentsKey = 'vitaltrack.web.attachments';

  final Future<SharedPreferences> _preferences;

  final List<Profile> profiles = [];
  final List<Reading> readings = [];
  final List<Reminder> reminders = [];
  final List<Attachment> attachments = [];

  Future<void>? _loadOperation;
  bool _loaded = false;

  Future<void> ensureLoaded() {
    if (_loaded) return Future<void>.value();
    return _loadOperation ??= _load();
  }

  Future<void> _load() async {
    final prefs = await _preferences;
    profiles
      ..clear()
      ..addAll(_decodeList(prefs.getString(_profilesKey), Profile.fromMap));
    readings
      ..clear()
      ..addAll(_decodeList(prefs.getString(_readingsKey), Reading.fromMap));
    reminders
      ..clear()
      ..addAll(_decodeList(prefs.getString(_remindersKey), Reminder.fromMap));
    attachments
      ..clear()
      ..addAll(_decodeList(prefs.getString(_attachmentsKey), Attachment.fromMap));
    _loaded = true;
  }

  List<T> _decodeList<T>(String? encoded, T Function(Map<String, dynamic>) fromMap) {
    if (encoded == null || encoded.isEmpty) return [];

    try {
      final decoded = jsonDecode(encoded) as List<dynamic>;
      return decoded
          .map((item) => fromMap(Map<String, dynamic>.from(item as Map)))
          .toList();
    } on FormatException {
      return [];
    } on TypeError {
      return [];
    }
  }

  Future<void> saveProfiles() => _save(_profilesKey, profiles.map((p) => p.toMap()));

  Future<void> saveReadings() => _save(_readingsKey, readings.map((r) => r.toMap()));

  Future<void> saveReminders() => _save(_remindersKey, reminders.map((r) => r.toMap()));

  Future<void> saveAttachments() =>
      _save(_attachmentsKey, attachments.map((attachment) => attachment.toMap()));

  Future<void> _save(String key, Iterable<Map<String, dynamic>> values) async {
    await ensureLoaded();
    final prefs = await _preferences;
    await prefs.setString(key, jsonEncode(values.toList()));
  }

  /// Mirrors the SQLite foreign keys on readings and attachments.
  Future<void> deleteProfile(String id) async {
    await ensureLoaded();
    profiles.removeWhere((profile) => profile.id == id);
    readings.removeWhere((reading) => reading.profileId == id);
    attachments.removeWhere((attachment) => attachment.profileId == id);
    await Future.wait([saveProfiles(), saveReadings(), saveAttachments()]);
  }
}
