import 'package:equatable/equatable.dart';

/// Blood pressure reading model.
class Reading extends Equatable {
  const Reading({
    required this.id,
    required this.systolic,
    required this.diastolic,
    required this.pulse,
    required this.timestamp,
    required this.profileId,
    this.weight,
    this.notes,
    this.medicationTaken = false,
    this.symptoms = const [],
    this.mood,
  });

  final String id;
  final int systolic;
  final int diastolic;
  final int pulse;
  final double? weight;
  final String? notes;
  final bool medicationTaken;
  final List<String> symptoms;
  final String? mood;
  final DateTime timestamp;
  final String profileId;

  String get bpDisplay => '$systolic / $diastolic';

  Reading copyWith({
    String? id,
    int? systolic,
    int? diastolic,
    int? pulse,
    double? weight,
    String? notes,
    bool? medicationTaken,
    List<String>? symptoms,
    String? mood,
    DateTime? timestamp,
    String? profileId,
    bool clearWeight = false,
    bool clearNotes = false,
    bool clearMood = false,
  }) {
    return Reading(
      id: id ?? this.id,
      systolic: systolic ?? this.systolic,
      diastolic: diastolic ?? this.diastolic,
      pulse: pulse ?? this.pulse,
      weight: clearWeight ? null : (weight ?? this.weight),
      notes: clearNotes ? null : (notes ?? this.notes),
      medicationTaken: medicationTaken ?? this.medicationTaken,
      symptoms: symptoms ?? this.symptoms,
      mood: clearMood ? null : (mood ?? this.mood),
      timestamp: timestamp ?? this.timestamp,
      profileId: profileId ?? this.profileId,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'systolic': systolic,
        'diastolic': diastolic,
        'pulse': pulse,
        'weight': weight,
        'notes': notes,
        'medicationTaken': medicationTaken ? 1 : 0,
        'symptoms': symptoms.join('|'),
        'mood': mood,
        'timestamp': timestamp.millisecondsSinceEpoch,
        'profileId': profileId,
      };

  factory Reading.fromMap(Map<String, dynamic> map) => Reading(
        id: map['id'] as String,
        systolic: map['systolic'] as int,
        diastolic: map['diastolic'] as int,
        pulse: map['pulse'] as int,
        weight: map['weight'] as double?,
        notes: map['notes'] as String?,
        medicationTaken: (map['medicationTaken'] as int) == 1,
        symptoms: (map['symptoms'] as String?)?.split('|').where((s) => s.isNotEmpty).toList() ?? [],
        mood: map['mood'] as String?,
        timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
        profileId: map['profileId'] as String,
      );

  @override
  List<Object?> get props => [
        id,
        systolic,
        diastolic,
        pulse,
        weight,
        notes,
        medicationTaken,
        symptoms,
        mood,
        timestamp,
        profileId,
      ];
}
