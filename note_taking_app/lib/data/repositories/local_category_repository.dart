import 'dart:async';

import 'package:sqflite/sqflite.dart';

import '../../core/constants/database_constants.dart';
import '../../core/errors/app_exceptions.dart' as app_exceptions;
import '../../domain/entities/category.dart';

import '../../domain/repositories/category_repository.dart';
import '../../services/local/database_helper.dart';
import '../models/category_model.dart';

class LocalCategoryRepository implements CategoryRepository {
  final DatabaseHelper _databaseHelper;
  final _categoriesStreamController = StreamController<List<Category>>.broadcast();

  LocalCategoryRepository(this._databaseHelper) {
    _databaseHelper.databaseStream.listen((_) {
      getAllCategories().then((categories) => _categoriesStreamController.add(categories));
    });
  }

  @override
  Future<List<Category>> getAllCategories() async {
    try {
      final db = await _databaseHelper.database;
      final maps = await db.query(
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
      final db = await _databaseHelper.database;
      final maps = await db.query(
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
      final db = await _databaseHelper.database;
      final maps = await db.query(
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
      final db = await _databaseHelper.database;
      final categoryModel = CategoryModel.fromEntity(category);
      await db.insert(
        DatabaseConstants.categoriesTable,
        categoryModel.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      throw app_exceptions.DatabaseException('Failed to save category: $e');
    }
  }

  @override
  Future<void> updateCategory(Category category) async {
    try {
      final db = await _databaseHelper.database;
      final categoryModel = CategoryModel.fromEntity(category);
      final rowsAffected = await db.update(
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
      final db = await _databaseHelper.database;
      final rowsAffected = await db.delete(
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
    getAllCategories().then((categories) => _categoriesStreamController.add(categories));
    return _categoriesStreamController.stream;
  }

  @override
  Future<int> getTodoCountByCategory(String categoryId) async {
    try {
      final db = await _databaseHelper.database;
      final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM ${DatabaseConstants.todosTable} WHERE ${DatabaseConstants.todoCategoryId} = ?',
        [categoryId],
      );

      return result.first['count'] as int;
    } catch (e) {
      throw app_exceptions.DatabaseException('Failed to get todo count by category: $e');
    }
  }

  @override
  Future<bool> isCategoryInUse(String categoryId) async {
    try {
      final db = await _databaseHelper.database;
      final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM ${DatabaseConstants.todosTable} WHERE ${DatabaseConstants.todoCategoryId} = ?',
        [categoryId],
      );

      final count = result.first['count'] as int;
      return count > 0;
    } catch (e) {
      throw app_exceptions.DatabaseException('Failed to check if category is in use: $e');
    }
  }

  @override
  Future<List<Category>> getCategoriesDueForSync() async {
    try {
      final db = await _databaseHelper.database;
      final maps = await db.query(
        DatabaseConstants.categoriesTable,
        orderBy: '${DatabaseConstants.categoryCreatedAt} ASC',
      );

      return maps.map((map) {
        final categoryModel = CategoryModel.fromJson(map);
        return categoryModel.toEntity();
      }).toList();
    } catch (e) {
      throw app_exceptions.DatabaseException('Failed to get categories due for sync: $e');
    }
  }



  void dispose() {
    _categoriesStreamController.close();
  }
}
