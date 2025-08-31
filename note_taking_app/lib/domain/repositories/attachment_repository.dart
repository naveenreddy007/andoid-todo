import '../entities/attachment.dart';

abstract class AttachmentRepository {
  Future<List<Attachment>> getAllAttachments();
  Future<Attachment?> getAttachmentById(String id);
  Future<void> saveAttachment(Attachment attachment);
  Future<void> updateAttachment(Attachment attachment);
  Future<void> deleteAttachment(String id);
  Future<List<Attachment>> getAttachmentsForNote(String noteId);
  Stream<List<Attachment>> watchAttachments();
}