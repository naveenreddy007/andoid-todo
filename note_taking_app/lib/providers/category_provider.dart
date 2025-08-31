import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/local_category_repository.dart';
import '../domain/entities/category.dart';
import '../domain/repositories/category_repository.dart';
import '../services/local/database_helper.dart';
import 'note_provider.dart';

// Category repository provider
final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  final databaseHelper = ref.watch(databaseHelperProvider);
  return LocalCategoryRepository(databaseHelper);
});

// Categories list provider
final categoriesProvider = FutureProvider<List<Category>>((ref) async {
  final repository = ref.watch(categoryRepositoryProvider);
  return repository.getAllCategories();
});

// Individual category provider
final categoryProvider = FutureProvider.family<Category?, String>((
  ref,
  id,
) async {
  final repository = ref.watch(categoryRepositoryProvider);
  return repository.getCategoryById(id);
});

// Category operations notifier
class CategoryOperationsNotifier extends StateNotifier<AsyncValue<void>> {
  final CategoryRepository _repository;

  CategoryOperationsNotifier(this._repository)
    : super(const AsyncValue.data(null));

  Future<void> saveCategory(Category category) async {
    state = const AsyncValue.loading();
    try {
      await _repository.saveCategory(category);
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> updateCategory(Category category) async {
    state = const AsyncValue.loading();
    try {
      await _repository.updateCategory(category);
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> deleteCategory(String id) async {
    state = const AsyncValue.loading();
    try {
      await _repository.deleteCategory(id);
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

final categoryOperationsProvider =
    StateNotifierProvider<CategoryOperationsNotifier, AsyncValue<void>>((ref) {
      final repository = ref.watch(categoryRepositoryProvider);
      return CategoryOperationsNotifier(repository);
    });
