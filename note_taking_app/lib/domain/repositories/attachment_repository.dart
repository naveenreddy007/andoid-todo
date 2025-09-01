import '../entities/attachment.dart';

abstract class AttachmentRepository {
  Future<List<Attachment>> getAllAttachments();
  Future<Attachment?> getAttachmentById(String id);
  Future<void> saveAttachment(Attachment attachment);
  Future<void> updateAttachment(Attachment attachment);
  Future<void> deleteAttachment(String id);
  Future<List<Attachment>> getAttachmentsForTodo(String todoId);
  Future<void> deleteAttachmentsForTodo(String todoId);
  Future<void> deleteAllAttachmentsForTodo(String todoId);
  Stream<List<Attachment>> watchAttachments();
  Stream<List<Attachment>> watchAttachmentsForTodo(String todoId);
  Future<List<Attachment>> getAttachmentsDueForSync();
  Future<bool> isAttachmentAccessible(String attachmentId);
  Future<int> getTotalAttachmentSize();
}