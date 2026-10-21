/// Application-wide constants.
class AppConstants {
  AppConstants._();

  static const String appName = 'VitalTrack';
  static const String databaseName = 'vitaltrack.db';
  static const int databaseVersion = 1;

  // Realistic medical ranges
  static const int minSystolic = 60;
  static const int maxSystolic = 250;
  static const int minDiastolic = 40;
  static const int maxDiastolic = 150;
  static const int minPulse = 30;
  static const int maxPulse = 220;
  static const double minWeight = 20.0;
  static const double maxWeight = 300.0;

  static const String medicalDisclaimer =
      'VitalTrack is for informational purposes only and does not provide '
      'medical advice, diagnosis, or treatment. Always consult a qualified '
      'healthcare provider for medical decisions.';

  static const String measurementDisclaimer =
      'VitalTrack does not measure blood pressure. Readings must be entered '
      'manually or imported from compatible devices.';

  static const List<String> moods = [
    'Great',
    'Good',
    'Neutral',
    'Tired',
    'Stressed',
    'Anxious',
  ];

  static const List<String> symptoms = [
    'Headache',
    'Dizziness',
    'Chest Pain',
    'Shortness of Breath',
    'Fatigue',
    'Nausea',
    'Blurred Vision',
    'None',
  ];

  static const List<String> genders = [
    'Male',
    'Female',
    'Other',
    'Prefer not to say',
  ];

  static const List<String> relationships = [
    'Self',
    'Spouse',
    'Parent',
    'Child',
    'Sibling',
    'Other',
  ];
}
