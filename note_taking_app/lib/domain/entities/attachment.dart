import 'package:equatable/equatable.dart';

class Attachment extends Equatable {
  final String id;
  final String noteId;
  final String fileName;
  final String filePath;
  final String? mimeType;
  final int? fileSize;
  final DateTime createdAt;

  const Attachment({
    required this.id,
    required this.noteId,
    required this.fileName,
    required this.filePath,
    this.mimeType,
    this.fileSize,
    required this.createdAt,
  });

  Attachment copyWith({
    String? id,
    String? noteId,
    String? fileName,
    String? filePath,
    String? mimeType,
    int? fileSize,
    DateTime? createdAt,
  }) {
    return Attachment(
      id: id ?? this.id,
      noteId: noteId ?? this.noteId,
      fileName: fileName ?? this.fileName,
      filePath: filePath ?? this.filePath,
      mimeType: mimeType ?? this.mimeType,
      fileSize: fileSize ?? this.fileSize,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        noteId,
        fileName,
        filePath,
        mimeType,
        fileSize,
        createdAt,
      ];
}