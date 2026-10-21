import 'package:flutter_test/flutter_test.dart';
import 'package:vitaltrack/core/models/bp_classification.dart';
import 'package:vitaltrack/core/utils/validators.dart';

void main() {
  group('ReadingValidator Tests', () {
    test('validateSystolic', () {
      expect(ReadingValidator.validateSystolic(null), 'Systolic is required');
      expect(ReadingValidator.validateSystolic(''), 'Systolic is required');
      expect(ReadingValidator.validateSystolic('  '), 'Systolic is required');
      expect(ReadingValidator.validateSystolic('abc'), 'Enter a valid number');
      expect(ReadingValidator.validateSystolic('59'), 'Systolic must be 60-250 mmHg');
      expect(ReadingValidator.validateSystolic('251'), 'Systolic must be 60-250 mmHg');
      expect(ReadingValidator.validateSystolic('120'), isNull);
    });

    test('validateDiastolic', () {
      expect(ReadingValidator.validateDiastolic(null), 'Diastolic is required');
      expect(ReadingValidator.validateDiastolic(''), 'Diastolic is required');
      expect(ReadingValidator.validateDiastolic('abc'), 'Enter a valid number');
      expect(ReadingValidator.validateDiastolic('39'), 'Diastolic must be 40-150 mmHg');
      expect(ReadingValidator.validateDiastolic('151'), 'Diastolic must be 40-150 mmHg');
      expect(ReadingValidator.validateDiastolic('80'), isNull);
    });

    test('validatePulse', () {
      expect(ReadingValidator.validatePulse(null), 'Pulse is required');
      expect(ReadingValidator.validatePulse(''), 'Pulse is required');
      expect(ReadingValidator.validatePulse('abc'), 'Enter a valid number');
      expect(ReadingValidator.validatePulse('29'), 'Pulse must be 30-220 BPM');
      expect(ReadingValidator.validatePulse('221'), 'Pulse must be 30-220 BPM');
      expect(ReadingValidator.validatePulse('72'), isNull);
    });

    test('validateWeight', () {
      expect(ReadingValidator.validateWeight(null), isNull);
      expect(ReadingValidator.validateWeight(''), isNull);
      expect(ReadingValidator.validateWeight('  '), isNull);
      expect(ReadingValidator.validateWeight('abc'), 'Enter a valid weight');
      expect(ReadingValidator.validateWeight('19.9'), 'Weight must be 20.0-300.0 kg');
      expect(ReadingValidator.validateWeight('300.1'), 'Weight must be 20.0-300.0 kg');
      expect(ReadingValidator.validateWeight('70.5'), isNull);
    });

    test('validateBpRelationship', () {
      expect(
        ReadingValidator.validateBpRelationship(120, 120),
        'Diastolic must be lower than systolic',
      );
      expect(
        ReadingValidator.validateBpRelationship(120, 130),
        'Diastolic must be lower than systolic',
      );
      expect(
        ReadingValidator.validateBpRelationship(120, 115),
        'Pulse pressure seems too narrow. Please verify readings.',
      );
      expect(
        ReadingValidator.validateBpRelationship(120, 80),
        isNull,
      );
    });
  });

  group('BpClassification Tests', () {
    test('Normal classification', () {
      final res = BpClassification.classify(115, 75);
      expect(res.category, BpCategory.normal);
      expect(res.label, 'Normal');
    });

    test('Elevated classification', () {
      final res = BpClassification.classify(125, 75);
      expect(res.category, BpCategory.elevated);
      expect(res.label, 'Elevated');
    });

    test('High Stage 1 classification', () {
      final resSys = BpClassification.classify(135, 75);
      final resDia = BpClassification.classify(115, 85);
      expect(resSys.category, BpCategory.highStage1);
      expect(resDia.category, BpCategory.highStage1);
    });

    test('High Stage 2 classification', () {
      final resSys = BpClassification.classify(145, 75);
      final resDia = BpClassification.classify(115, 95);
      expect(resSys.category, BpCategory.highStage2);
      expect(resDia.category, BpCategory.highStage2);
    });

    test('Hypertensive Crisis classification', () {
      final resSys = BpClassification.classify(185, 75);
      final resDia = BpClassification.classify(115, 125);
      expect(resSys.category, BpCategory.hypertensiveCrisis);
      expect(resDia.category, BpCategory.hypertensiveCrisis);
    });
  });
}
