import '../entities/tag.dart';

abstract class TagRepository {
  Future<List<Tag>> getAllTags();
  Future<Tag?> getTagById(String id);
  Future<Tag?> getTagByName(String name);
  Future<void> saveTag(Tag tag);
  Future<void> updateTag(Tag tag);
  Future<void> deleteTag(String id);
  Stream<List<Tag>> watchTags();
  Future<List<Tag>> getTagsForNote(String noteId);
  Future<void> addTagToNote(String noteId, String tagId);
  Future<void> removeTagFromNote(String noteId, String tagId);
  Future<List<Tag>> getPopularTags(int limit);
}