import '../entities/tag.dart';

abstract class TagRepository {
  Future<List<Tag>> getAllTags();
  Future<Tag?> getTagById(String id);
  Future<Tag?> getTagByName(String name);
  Future<void> saveTag(Tag tag);
  Future<void> updateTag(Tag tag);
  Future<void> deleteTag(String id);
  Stream<List<Tag>> watchTags();
  Future<List<Tag>> getTagsForTodo(String todoId);
  Future<void> addTagToTodo(String todoId, String tagId);
  Future<void> removeTagFromTodo(String todoId, String tagId);
  Future<List<Tag>> getPopularTags(int limit);
  Future<int> getTodoCountByTag(String tagId);
  Future<bool> isTagInUse(String tagId);
  Future<List<Tag>> getTagsDueForSync();
}