import 'package:equatable/equatable.dart';

/// Reminder notification model.
class Reminder extends Equatable {
  const Reminder({
    required this.id,
    required this.title,
    required this.time,
    this.enabled = true,
    this.profileId,
  });

  final String id;
  final String title;
  /// Time of day stored as "HH:mm"
  final String time;
  final bool enabled;
  final String? profileId;

  Reminder copyWith({
    String? id,
    String? title,
    String? time,
    bool? enabled,
    String? profileId,
  }) {
    return Reminder(
      id: id ?? this.id,
      title: title ?? this.title,
      time: time ?? this.time,
      enabled: enabled ?? this.enabled,
      profileId: profileId ?? this.profileId,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'time': time,
        'enabled': enabled ? 1 : 0,
        'profileId': profileId,
      };

  factory Reminder.fromMap(Map<String, dynamic> map) => Reminder(
        id: map['id'] as String,
        title: map['title'] as String,
        time: map['time'] as String,
        enabled: (map['enabled'] as int) == 1,
        profileId: map['profileId'] as String?,
      );

  @override
  List<Object?> get props => [id, title, time, enabled, profileId];
}
