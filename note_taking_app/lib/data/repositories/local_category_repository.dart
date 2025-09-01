import 'dart:async';


import '../../core/constants/database_constants.dart';
import '../../core/errors/app_exceptions.dart' as app_exceptions;
import '../../domain/entities/category.dart';
import '../../domain/repositories/category_repository.dart';
import '../../services/local/database_helper.dart';
import '../models/category_model.dart';

class LocalCategoryRepository implements CategoryRepository {
  final DatabaseHelper _databaseHelper;

  LocalCategoryRepository(this._databaseHelper);

  @override
  Future<List<Category>> getAllCategories() async {
    try {
      final maps = await _databaseHelper.query(
        DatabaseConstants.categoriesTable,
        orderBy: '${DatabaseConstants.categoryCreatedAt} ASC',
      );

      return maps.map((map) {
        final categoryModel = CategoryModel.fromJson(map);
        return categoryModel.toEntity();
      }).toList();
    } catch (e) {
      throw app_exceptions.DatabaseException('Failed to get all categories: $e');
    }
  }

  @override
  Future<Category?> getCategoryById(String id) async {
    try {
      final maps = await _databaseHelper.query(
        DatabaseConstants.categoriesTable,
        where: '${DatabaseConstants.categoryId} = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (maps.isEmpty) return null;

      final categoryModel = CategoryModel.fromJson(maps.first);
      return categoryModel.toEntity();
    } catch (e) {
      throw app_exceptions.DatabaseException('Failed to get category by id: $e');
    }
  }

  @override
  Future<Category?> getCategoryByName(String name) async {
    try {
      final maps = await _databaseHelper.query(
        DatabaseConstants.categoriesTable,
        where: '${DatabaseConstants.categoryName} = ?',
        whereArgs: [name],
        limit: 1,
      );

      if (maps.isEmpty) return null;

      final categoryModel = CategoryModel.fromJson(maps.first);
      return categoryModel.toEntity();
    } catch (e) {
      throw app_exceptions.DatabaseException('Failed to get category by name: $e');
    }
  }

  @override
  Future<void> saveCategory(Category category) async {
    try {
      final categoryModel = CategoryModel.fromEntity(category);
      await _databaseHelper.insert(
        DatabaseConstants.categoriesTable,
        categoryModel.toJson(),
      );
    } catch (e) {
      throw app_exceptions.DatabaseException('Failed to save category: $e');
    }
  }

  @override
  Future<void> updateCategory(Category category) async {
    try {
      final categoryModel = CategoryModel.fromEntity(category);
      final rowsAffected = await _databaseHelper.update(
        DatabaseConstants.categoriesTable,
        categoryModel.toJson(),
        where: '${DatabaseConstants.categoryId} = ?',
        whereArgs: [category.id],
      );

      if (rowsAffected == 0) {
        throw app_exceptions.DatabaseException('Category not found for update');
      }
    } catch (e) {
      throw app_exceptions.DatabaseException('Failed to update category: $e');
    }
  }

  @override
  Future<void> deleteCategory(String id) async {
    try {
      final rowsAffected = await _databaseHelper.delete(
        DatabaseConstants.categoriesTable,
        where: '${DatabaseConstants.categoryId} = ?',
        whereArgs: [id],
      );

      if (rowsAffected == 0) {
        throw app_exceptions.DatabaseException('Category not found for deletion');
      }
    } catch (e) {
      throw app_exceptions.DatabaseException('Failed to delete category: $e');
    }
  }

  @override
  Stream<List<Category>> watchCategories() {
    late StreamController<List<Category>> controller;
    Timer? timer;

    controller = StreamController<List<Category>>(
      onListen: () {
        _loadAndEmitCategories(controller);
        timer = Timer.periodic(const Duration(seconds: 2), (_) {
          _loadAndEmitCategories(controller);
        });
      },
      onCancel: () {
        timer?.cancel();
      },
    );

    return controller.stream;
  }

  void _loadAndEmitCategories(StreamController<List<Category>> controller) {
    getAllCategories()
        .then((categories) {
          if (!controller.isClosed) {
            controller.add(categories);
          }
        })
        .catchError((error) {
          if (!controller.isClosed) {
            controller.addError(error);
          }
        });
  }

  @override
  Future<int> getNoteCountByCategory(String categoryId) async {
    try {
      final maps = await _databaseHelper.rawQuery(
        '''
        SELECT COUNT(*) as count FROM ${DatabaseConstants.notesTable}
        WHERE ${DatabaseConstants.noteCategoryId} = ? AND ${DatabaseConstants.noteIsDeleted} = 0
      ''',
        [categoryId],
      );

      return maps.first['count'] as int;
    } catch (e) {
      throw app_exceptions.DatabaseException('Failed to get note count by category: $e');
    }
  }
}
