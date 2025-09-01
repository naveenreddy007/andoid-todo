class Attachment {
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

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Attachment &&
        other.id == id &&
        other.noteId == noteId &&
        other.fileName == fileName &&
        other.filePath == filePath &&
        other.mimeType == mimeType &&
        other.fileSize == fileSize &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      noteId,
      fileName,
      filePath,
      mimeType,
      fileSize,
      createdAt,
    );
  }
}