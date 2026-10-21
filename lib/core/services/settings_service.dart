import 'package:shared_preferences/shared_preferences.dart';

/// App settings persisted via SharedPreferences.
class SettingsService {
  SettingsService(this._prefs);

  final SharedPreferences _prefs;

  static const _themeKey = 'theme_mode';
  static const _languageKey = 'language';
  static const _weightUnitKey = 'weight_unit';
  static const _pinEnabledKey = 'pin_enabled';
  static const _patientNameKey = 'patient_name';
  static const _doctorNotesKey = 'doctor_notes';
  static const _activeProfileKey = 'active_profile_id';
  static const _onboardingCompleteKey = 'onboarding_complete';
  static const _remindersOptedInKey = 'reminders_opted_in';

  String get themeMode => _prefs.getString(_themeKey) ?? 'system';
  Future<void> setThemeMode(String mode) => _prefs.setString(_themeKey, mode);

  String get language => _prefs.getString(_languageKey) ?? 'en';
  Future<void> setLanguage(String lang) => _prefs.setString(_languageKey, lang);

  String get weightUnit => _prefs.getString(_weightUnitKey) ?? 'kg';
  Future<void> setWeightUnit(String unit) => _prefs.setString(_weightUnitKey, unit);

  bool get pinEnabled => _prefs.getBool(_pinEnabledKey) ?? false;
  Future<void> setPinEnabled(bool enabled) async {
    await _saveBool(_pinEnabledKey, enabled);
  }

  bool get remindersOptedIn => _prefs.getBool(_remindersOptedInKey) ?? false;
  Future<void> setRemindersOptedIn(bool enabled) =>
      _saveBool(_remindersOptedInKey, enabled);

  Future<void> _saveBool(String key, bool value) async {
    if (!await _prefs.setBool(key, value)) {
      throw StateError('Could not save settings');
    }
  }

  String get patientName => _prefs.getString(_patientNameKey) ?? '';
  Future<void> setPatientName(String name) => _prefs.setString(_patientNameKey, name);

  String get doctorNotes => _prefs.getString(_doctorNotesKey) ?? '';
  Future<void> setDoctorNotes(String notes) => _prefs.setString(_doctorNotesKey, notes);

  String? get activeProfileId => _prefs.getString(_activeProfileKey);
  Future<void> setActiveProfileId(String id) => _prefs.setString(_activeProfileKey, id);

  bool get onboardingComplete => _prefs.getBool(_onboardingCompleteKey) ?? false;
  Future<void> setOnboardingComplete(bool complete) =>
      _prefs.setBool(_onboardingCompleteKey, complete);
}
