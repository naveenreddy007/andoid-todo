import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/local_attachment_repository.dart';
import '../domain/entities/attachment.dart';
import '../domain/repositories/attachment_repository.dart';
import 'todo_provider.dart';

// Attachment repository provider
final attachmentRepositoryProvider = Provider<AttachmentRepository>((ref) {
  final databaseHelper = ref.watch(databaseHelperProvider);
  return LocalAttachmentRepository(databaseHelper);
});

// Attachments list provider
final attachmentsProvider = FutureProvider<List<Attachment>>((ref) async {
  final repository = ref.watch(attachmentRepositoryProvider);
  return repository.getAllAttachments();
});

// Individual attachment provider
final attachmentProvider = FutureProvider.family<Attachment?, String>((ref, id) async {
  final repository = ref.watch(attachmentRepositoryProvider);
  return repository.getAttachmentById(id);
});

// Attachments for todo provider
final attachmentsForTodoProvider = FutureProvider.family<List<Attachment>, String>((
  ref,
  todoId,
) async {
  final repository = ref.watch(attachmentRepositoryProvider);
  return repository.getAttachmentsForTodo(todoId);
});

// Attachments stream for todo provider
final attachmentsStreamForTodoProvider = StreamProvider.family<List<Attachment>, String>((
  ref,
  todoId,
) {
  final repository = ref.watch(attachmentRepositoryProvider);
  return repository.watchAttachmentsForTodo(todoId);
});

// Total attachment size provider
final totalAttachmentSizeProvider = FutureProvider<int>((ref) async {
  final repository = ref.watch(attachmentRepositoryProvider);
  return repository.getTotalAttachmentSize();
});

// Attachment accessibility provider
final attachmentAccessibilityProvider = FutureProvider.family<bool, String>((ref, attachmentId) async {
  final repository = ref.watch(attachmentRepositoryProvider);
  return repository.isAttachmentAccessible(attachmentId);
});

// Attachment operations notifier
class AttachmentOperationsNotifier extends StateNotifier<AsyncValue<void>> {
  final AttachmentRepository _repository;

  AttachmentOperationsNotifier(this._repository) : super(const AsyncValue.data(null));

  Future<void> saveAttachment(Attachment attachment) async {
    state = const AsyncValue.loading();
    try {
      await _repository.saveAttachment(attachment);
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> updateAttachment(Attachment attachment) async {
    state = const AsyncValue.loading();
    try {
      await _repository.updateAttachment(attachment);
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> deleteAttachment(String id) async {
    state = const AsyncValue.loading();
    try {
      await _repository.deleteAttachment(id);
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> deleteAllAttachmentsForTodo(String todoId) async {
    state = const AsyncValue.loading();
    try {
      await _repository.deleteAllAttachmentsForTodo(todoId);
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

final attachmentOperationsProvider =
    StateNotifierProvider<AttachmentOperationsNotifier, AsyncValue<void>>((ref) {
      final repository = ref.watch(attachmentRepositoryProvider);
      return AttachmentOperationsNotifier(repository);
    });