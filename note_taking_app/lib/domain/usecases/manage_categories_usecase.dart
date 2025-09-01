import '../entities/category.dart';
import '../repositories/category_repository.dart';

class ManageCategoriesUseCase {
  final CategoryRepository _categoryRepository;

  ManageCategoriesUseCase(this._categoryRepository);

  Future<String> createCategory({
    required String name,
    String? icon,
    String? color,
  }) async {
    // Check if category with same name already exists
    final existingCategory = await _categoryRepository.getCategoryByName(name);
    if (existingCategory != null) {
      throw Exception('Category with name "$name" already exists');
    }

    final category = Category(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      icon: icon ?? 'folder',
      color: color ?? '#2196F3',
      createdAt: DateTime.now(),
    );

    await _categoryRepository.saveCategory(category);
    return category.id;
  }

  Future<void> updateCategory({
    required String id,
    String? name,
    String? icon,
    String? color,
  }) async {
    final existingCategory = await _categoryRepository.getCategoryById(id);
    if (existingCategory == null) {
      throw Exception('Category not found');
    }

    // Check if new name conflicts with existing category
    if (name != null && name != existingCategory.name) {
      final conflictingCategory = await _categoryRepository.getCategoryByName(name);
      if (conflictingCategory != null) {
        throw Exception('Category with name "$name" already exists');
      }
    }

    final updatedCategory = existingCategory.copyWith(
      name: name,
      icon: icon,
      color: color,
    );

    await _categoryRepository.updateCategory(updatedCategory);
  }

  Future<void> deleteCategory(String id) async {
    final category = await _categoryRepository.getCategoryById(id);
    if (category == null) {
      throw Exception('Category not found');
    }

    // Check if category is in use
    final isInUse = await _categoryRepository.isCategoryInUse(id);
    if (isInUse) {
      throw Exception('Cannot delete category that is in use by todos');
    }

    await _categoryRepository.deleteCategory(id);
  }

  Future<List<Category>> getAllCategories() async {
    return await _categoryRepository.getAllCategories();
  }

  Future<Category?> getCategoryById(String id) async {
    return await _categoryRepository.getCategoryById(id);
  }

  Future<int> getTodoCountForCategory(String categoryId) async {
    return await _categoryRepository.getTodoCountByCategory(categoryId);
  }

  Stream<List<Category>> watchCategories() {
    return _categoryRepository.watchCategories();
  }
}