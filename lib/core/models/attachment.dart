import 'package:equatable/equatable.dart';

/// File attachment model (prescriptions, lab reports, etc.).
class Attachment extends Equatable {
  const Attachment({
    required this.id,
    required this.filePath,
    required this.fileName,
    required this.fileType,
    required this.timestamp,
    required this.profileId,
    this.description,
  });

  final String id;
  final String filePath;
  final String fileName;
  final String fileType;
  final String? description;
  final DateTime timestamp;
  final String profileId;

  Map<String, dynamic> toMap() => {
        'id': id,
        'filePath': filePath,
        'fileName': fileName,
        'fileType': fileType,
        'description': description,
        'timestamp': timestamp.millisecondsSinceEpoch,
        'profileId': profileId,
      };

  factory Attachment.fromMap(Map<String, dynamic> map) => Attachment(
        id: map['id'] as String,
        filePath: map['filePath'] as String,
        fileName: map['fileName'] as String,
        fileType: map['fileType'] as String,
        description: map['description'] as String?,
        timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
        profileId: map['profileId'] as String,
      );

  @override
  List<Object?> get props =>
      [id, filePath, fileName, fileType, description, timestamp, profileId];
}
