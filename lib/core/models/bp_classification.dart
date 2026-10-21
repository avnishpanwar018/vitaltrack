import 'package:flutter/material.dart';

/// AHA blood pressure classification categories.
enum BpCategory {
  normal,
  elevated,
  highStage1,
  highStage2,
  hypertensiveCrisis,
}

/// Classification result with metadata for UI display.
class BpClassification {
  const BpClassification({
    required this.category,
    required this.label,
    required this.color,
    required this.icon,
    required this.explanation,
  });

  final BpCategory category;
  final String label;
  final Color color;
  final IconData icon;
  final String explanation;

  /// Classify blood pressure per AHA guidelines.
  static BpClassification classify(int systolic, int diastolic) {
    if (systolic >= 180 || diastolic >= 120) {
      return _crisis;
    }
    if (systolic >= 140 || diastolic >= 90) {
      return _highStage2;
    }
    if (systolic >= 130 || diastolic >= 80) {
      return _highStage1;
    }
    if (systolic >= 120 && diastolic < 80) {
      return _elevated;
    }
    return _normal;
  }

  static const BpClassification _normal = BpClassification(
    category: BpCategory.normal,
    label: 'Normal',
    color: Color(0xFF2E7D32),
    icon: Icons.check_circle_rounded,
    explanation:
        'Your reading is within the normal range. Continue healthy habits and regular monitoring.',
  );

  static const BpClassification _elevated = BpClassification(
    category: BpCategory.elevated,
    label: 'Elevated',
    color: Color(0xFFF9A825),
    icon: Icons.trending_up_rounded,
    explanation:
        'Systolic is elevated. Lifestyle changes may help. Consult your doctor if readings persist.',
  );

  static const BpClassification _highStage1 = BpClassification(
    category: BpCategory.highStage1,
    label: 'High Stage 1',
    color: Color(0xFFEF6C00),
    icon: Icons.warning_amber_rounded,
    explanation:
        'Stage 1 hypertension. Discuss with your healthcare provider about monitoring and treatment options.',
  );

  static const BpClassification _highStage2 = BpClassification(
    category: BpCategory.highStage2,
    label: 'High Stage 2',
    color: Color(0xFFC62828),
    icon: Icons.error_rounded,
    explanation:
        'Stage 2 hypertension. Seek medical guidance promptly for evaluation and management.',
  );

  static const BpClassification _crisis = BpClassification(
    category: BpCategory.hypertensiveCrisis,
    label: 'Hypertensive Crisis',
    color: Color(0xFF880E4F),
    icon: Icons.emergency_rounded,
    explanation:
        'Crisis-level reading. If you have symptoms, seek emergency medical care immediately.',
  );
}
