import 'dart:io';
import '../entities/attachment.dart';
import '../entities/todo.dart';
import '../repositories/attachment_repository.dart';
import '../repositories/todo_repository.dart';

class ManageAttachmentsUseCase {
  final AttachmentRepository _attachmentRepository;
  final TodoRepository _todoRepository;

  ManageAttachmentsUseCase(
    this._attachmentRepository,
    this._todoRepository,
  );

  Future<String> addAttachmentToTodo({
    required String todoId,
    required String fileName,
    required String filePath,
    required int fileSize,
    String? mimeType,
  }) async {
    // Verify todo exists
    final todo = await _todoRepository.getTodoById(todoId);
    if (todo == null) {
      throw Exception('Todo not found');
    }

    // Verify file exists
    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('File does not exist at path: $filePath');
    }

    // Create attachment
    final attachment = Attachment(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      todoId: todoId,
      fileName: fileName,
      filePath: filePath,
      fileSize: fileSize,
      mimeType: mimeType ?? _getMimeTypeFromExtension(fileName),
      createdAt: DateTime.now(),
    );

    await _attachmentRepository.saveAttachment(attachment);

    // Update todo's attachment list
    final updatedAttachmentIds = [...todo.attachmentIds, attachment.id];
    final updatedTodo = todo.copyWith(
      attachmentIds: updatedAttachmentIds,
      updatedAt: DateTime.now(),
    );
    await _todoRepository.updateTodo(updatedTodo);

    return attachment.id;
  }

  Future<void> removeAttachmentFromTodo(String attachmentId) async {
    final attachment = await _attachmentRepository.getAttachmentById(attachmentId);
    if (attachment == null) {
      throw Exception('Attachment not found');
    }

    // Get associated todo
    final todo = await _todoRepository.getTodoById(attachment.todoId);
    if (todo != null) {
      // Remove attachment from todo's list
      final updatedAttachmentIds = todo.attachmentIds
          .where((id) => id != attachmentId)
          .toList();
      final updatedTodo = todo.copyWith(
        attachmentIds: updatedAttachmentIds,
        updatedAt: DateTime.now(),
      );
      await _todoRepository.updateTodo(updatedTodo);
    }

    // Delete the attachment file if it exists
    try {
      final file = File(attachment.filePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      // Log error but don't fail the operation
      print('Failed to delete attachment file: $e');
    }

    // Delete attachment record
    await _attachmentRepository.deleteAttachment(attachmentId);
  }

  Future<List<Attachment>> getAttachmentsForTodo(String todoId) async {
    return await _attachmentRepository.getAttachmentsForTodo(todoId);
  }

  Future<Attachment?> getAttachmentById(String attachmentId) async {
    return await _attachmentRepository.getAttachmentById(attachmentId);
  }

  Future<void> updateAttachment({
    required String attachmentId,
    String? fileName,
    String? filePath,
  }) async {
    final existingAttachment = await _attachmentRepository.getAttachmentById(attachmentId);
    if (existingAttachment == null) {
      throw Exception('Attachment not found');
    }

    // If file path is being updated, verify the new file exists
    if (filePath != null && filePath != existingAttachment.filePath) {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('New file does not exist at path: $filePath');
      }
    }

    final updatedAttachment = existingAttachment.copyWith(
      fileName: fileName,
      filePath: filePath,
      mimeType: fileName != null ? _getMimeTypeFromExtension(fileName) : null,
    );

    await _attachmentRepository.updateAttachment(updatedAttachment);
  }

  Future<void> deleteAllAttachmentsForTodo(String todoId) async {
    final attachments = await _attachmentRepository.getAttachmentsForTodo(todoId);
    
    for (final attachment in attachments) {
      // Delete the attachment file if it exists
      try {
        final file = File(attachment.filePath);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        // Log error but continue with other attachments
        print('Failed to delete attachment file ${attachment.fileName}: $e');
      }
    }

    // Delete all attachment records for the todo
    await _attachmentRepository.deleteAttachmentsForTodo(todoId);
  }

  Stream<List<Attachment>> watchAttachmentsForTodo(String todoId) {
    return _attachmentRepository.watchAttachmentsForTodo(todoId);
  }

  Future<int> getTotalAttachmentSize(String todoId) async {
    final attachments = await _attachmentRepository.getAttachmentsForTodo(todoId);
    return attachments.fold(0, (total, attachment) => total + attachment.fileSize);
  }

  Future<bool> isAttachmentAccessible(String attachmentId) async {
    final attachment = await _attachmentRepository.getAttachmentById(attachmentId);
    if (attachment == null) {
      return false;
    }

    final file = File(attachment.filePath);
    return await file.exists();
  }

  String _getMimeTypeFromExtension(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'pdf':
        return 'application/pdf';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'txt':
        return 'text/plain';
      case 'mp3':
        return 'audio/mpeg';
      case 'mp4':
        return 'video/mp4';
      case 'zip':
        return 'application/zip';
      default:
        return 'application/octet-stream';
    }
  }
}