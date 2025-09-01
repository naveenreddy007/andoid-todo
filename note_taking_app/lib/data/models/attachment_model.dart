import '../../domain/entities/attachment.dart';

class AttachmentModel {
  final String id;
  final String noteId;
  final String fileName;
  final String filePath;
  final String? mimeType;
  final int? fileSize;
  final String createdAt;

  const AttachmentModel({
    required this.id,
    required this.noteId,
    required this.fileName,
    required this.filePath,
    this.mimeType,
    this.fileSize,
    required this.createdAt,
  });

  factory AttachmentModel.fromJson(Map<String, dynamic> json) {
    return AttachmentModel(
      id: json['id'] as String,
      noteId: json['note_id'] as String,
      fileName: json['file_name'] as String,
      filePath: json['file_path'] as String,
      mimeType: json['mime_type'] as String?,
      fileSize: json['file_size'] as int?,
      createdAt: json['created_at'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'note_id': noteId,
      'file_name': fileName,
      'file_path': filePath,
      'mime_type': mimeType,
      'file_size': fileSize,
      'created_at': createdAt,
    };
  }

  Attachment toEntity() {
    return Attachment(
      id: id,
      noteId: noteId,
      fileName: fileName,
      filePath: filePath,
      mimeType: mimeType,
      fileSize: fileSize,
      createdAt: DateTime.parse(createdAt),
    );
  }

  static AttachmentModel fromEntity(Attachment attachment) {
    return AttachmentModel(
      id: attachment.id,
      noteId: attachment.noteId,
      fileName: attachment.fileName,
      filePath: attachment.filePath,
      mimeType: attachment.mimeType,
      fileSize: attachment.fileSize,
      createdAt: attachment.createdAt.toIso8601String(),
    );
  }
}