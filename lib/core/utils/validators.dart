import '../utils/constants.dart';

/// Validates blood pressure and health reading inputs.
class ReadingValidator {
  ReadingValidator._();

  static String? validateSystolic(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Systolic is required';
    }
    final parsed = int.tryParse(value.trim());
    if (parsed == null) return 'Enter a valid number';
    if (parsed < AppConstants.minSystolic || parsed > AppConstants.maxSystolic) {
      return 'Systolic must be ${AppConstants.minSystolic}-${AppConstants.maxSystolic} mmHg';
    }
    return null;
  }

  static String? validateDiastolic(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Diastolic is required';
    }
    final parsed = int.tryParse(value.trim());
    if (parsed == null) return 'Enter a valid number';
    if (parsed < AppConstants.minDiastolic || parsed > AppConstants.maxDiastolic) {
      return 'Diastolic must be ${AppConstants.minDiastolic}-${AppConstants.maxDiastolic} mmHg';
    }
    return null;
  }

  static String? validatePulse(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Pulse is required';
    }
    final parsed = int.tryParse(value.trim());
    if (parsed == null) return 'Enter a valid number';
    if (parsed < AppConstants.minPulse || parsed > AppConstants.maxPulse) {
      return 'Pulse must be ${AppConstants.minPulse}-${AppConstants.maxPulse} BPM';
    }
    return null;
  }

  static String? validateWeight(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final parsed = double.tryParse(value.trim());
    if (parsed == null) return 'Enter a valid weight';
    if (parsed < AppConstants.minWeight || parsed > AppConstants.maxWeight) {
      return 'Weight must be ${AppConstants.minWeight}-${AppConstants.maxWeight} kg';
    }
    return null;
  }

  /// Ensures diastolic is less than systolic.
  static String? validateBpRelationship(int systolic, int diastolic) {
    if (diastolic >= systolic) {
      return 'Diastolic must be lower than systolic';
    }
    if (systolic - diastolic < 10) {
      return 'Pulse pressure seems too narrow. Please verify readings.';
    }
    return null;
  }

  static String? validatePin(String? value) {
    if (value == null || value.length != 4) {
      return 'PIN must be 4 digits';
    }
    if (!RegExp(r'^\d{4}$').hasMatch(value)) {
      return 'PIN must contain only digits';
    }
    return null;
  }
}
