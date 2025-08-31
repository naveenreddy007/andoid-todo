import '../entities/category.dart';

abstract class CategoryRepository {
  Future<List<Category>> getAllCategories();
  Future<Category?> getCategoryById(String id);
  Future<Category?> getCategoryByName(String name);
  Future<void> saveCategory(Category category);
  Future<void> updateCategory(Category category);
  Future<void> deleteCategory(String id);
  Stream<List<Category>> watchCategories();
  Future<int> getNoteCountByCategory(String categoryId);
}