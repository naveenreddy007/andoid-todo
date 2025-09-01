import '../entities/tag.dart';
import '../repositories/tag_repository.dart';
import '../repositories/todo_repository.dart';

class ManageTagsUseCase {
  final TagRepository _tagRepository;
  final TodoRepository _todoRepository;

  ManageTagsUseCase(
    this._tagRepository,
    this._todoRepository,
  );

  Future<String> createTag({
    required String name,
    String? color,
  }) async {
    // Check if tag with same name already exists
    final existingTag = await _tagRepository.getTagByName(name);
    if (existingTag != null) {
      throw Exception('Tag with name "$name" already exists');
    }

    final tag = Tag(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      color: color ?? '#FF9800',
      createdAt: DateTime.now(),
    );

    await _tagRepository.saveTag(tag);
    return tag.id;
  }

  Future<void> updateTag({
    required String id,
    String? name,
    String? color,
  }) async {
    final existingTag = await _tagRepository.getTagById(id);
    if (existingTag == null) {
      throw Exception('Tag not found');
    }

    // Check if new name conflicts with existing tag
    if (name != null && name != existingTag.name) {
      final conflictingTag = await _tagRepository.getTagByName(name);
      if (conflictingTag != null) {
        throw Exception('Tag with name "$name" already exists');
      }
    }

    final updatedTag = existingTag.copyWith(
      name: name,
      color: color,
    );

    await _tagRepository.updateTag(updatedTag);
  }

  Future<void> deleteTag(String id) async {
    final tag = await _tagRepository.getTagById(id);
    if (tag == null) {
      throw Exception('Tag not found');
    }

    // Check if tag is in use
    final isInUse = await _tagRepository.isTagInUse(id);
    if (isInUse) {
      throw Exception('Cannot delete tag that is in use by todos');
    }

    await _tagRepository.deleteTag(id);
  }

  Future<void> addTagToTodo(String todoId, String tagId) async {
    // Verify todo exists
    final todo = await _todoRepository.getTodoById(todoId);
    if (todo == null) {
      throw Exception('Todo not found');
    }

    // Verify tag exists
    final tag = await _tagRepository.getTagById(tagId);
    if (tag == null) {
      throw Exception('Tag not found');
    }

    // Check if tag is already associated with todo
    if (todo.tagIds.contains(tagId)) {
      return; // Already associated
    }

    // Add tag to todo
    await _tagRepository.addTagToTodo(todoId, tagId);

    // Update todo entity
    final updatedTodo = todo.copyWith(
      tagIds: [...todo.tagIds, tagId],
      updatedAt: DateTime.now(),
    );
    await _todoRepository.updateTodo(updatedTodo);
  }

  Future<void> removeTagFromTodo(String todoId, String tagId) async {
    // Verify todo exists
    final todo = await _todoRepository.getTodoById(todoId);
    if (todo == null) {
      throw Exception('Todo not found');
    }

    // Remove tag from todo
    await _tagRepository.removeTagFromTodo(todoId, tagId);

    // Update todo entity
    final updatedTagIds = todo.tagIds.where((id) => id != tagId).toList();
    final updatedTodo = todo.copyWith(
      tagIds: updatedTagIds,
      updatedAt: DateTime.now(),
    );
    await _todoRepository.updateTodo(updatedTodo);
  }

  Future<List<Tag>> getAllTags() async {
    return await _tagRepository.getAllTags();
  }

  Future<List<Tag>> getTagsForTodo(String todoId) async {
    return await _tagRepository.getTagsForTodo(todoId);
  }

  Future<List<Tag>> getPopularTags({int limit = 10}) async {
    return await _tagRepository.getPopularTags(limit);
  }

  Future<int> getTodoCountForTag(String tagId) async {
    return await _tagRepository.getTodoCountByTag(tagId);
  }

  Stream<List<Tag>> watchTags() {
    return _tagRepository.watchTags();
  }
}