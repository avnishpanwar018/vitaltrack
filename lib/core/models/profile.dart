import 'package:equatable/equatable.dart';

/// Family member profile model.
class Profile extends Equatable {
  const Profile({
    required this.id,
    required this.name,
    this.age,
    this.gender,
    this.relationship = 'Self',
    this.photoPath,
    this.isDefault = false,
  });

  final String id;
  final String name;
  final int? age;
  final String? gender;
  final String relationship;
  final String? photoPath;
  final bool isDefault;

  Profile copyWith({
    String? id,
    String? name,
    int? age,
    String? gender,
    String? relationship,
    String? photoPath,
    bool? isDefault,
    bool clearAge = false,
    bool clearGender = false,
    bool clearPhoto = false,
  }) {
    return Profile(
      id: id ?? this.id,
      name: name ?? this.name,
      age: clearAge ? null : (age ?? this.age),
      gender: clearGender ? null : (gender ?? this.gender),
      relationship: relationship ?? this.relationship,
      photoPath: clearPhoto ? null : (photoPath ?? this.photoPath),
      isDefault: isDefault ?? this.isDefault,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'age': age,
        'gender': gender,
        'relationship': relationship,
        'photoPath': photoPath,
        'isDefault': isDefault ? 1 : 0,
      };

  factory Profile.fromMap(Map<String, dynamic> map) => Profile(
        id: map['id'] as String,
        name: map['name'] as String,
        age: map['age'] as int?,
        gender: map['gender'] as String?,
        relationship: map['relationship'] as String? ?? 'Self',
        photoPath: map['photoPath'] as String?,
        isDefault: (map['isDefault'] as int? ?? 0) == 1,
      );

  @override
  List<Object?> get props => [id, name, age, gender, relationship, photoPath, isDefault];
}
