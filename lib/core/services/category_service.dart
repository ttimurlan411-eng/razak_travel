import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:razak_travel/data/models/category_model.dart';
import 'package:razak_travel/data/repositories/category_repository.dart';

class CategoryService {
  CategoryService({CategoryRepository? repository})
      : _repository = repository ?? CategoryRepository();

  final CategoryRepository _repository;

  Duration get _timeout => const Duration(seconds: 15);

  Future<List<CategoryModel>> getCategories() async {
    debugPrint('CategoryService.getCategories');
    try {
      return await _repository.getCategories().timeout(_timeout);
    } catch (e) {
      debugPrint('CategoryService.getCategories failed: $e');
      rethrow;
    }
  }

  Future<void> addCategory(CategoryModel category) async {
    debugPrint(
      'CategoryService.addCategory: id=${category.id} name=${category.name}',
    );
    try {
      await _repository.addCategory(category).timeout(_timeout);
      debugPrint('CategoryService.addCategory: OK');
    } catch (e) {
      debugPrint('CategoryService.addCategory failed: $e');
      rethrow;
    }
  }

  Future<void> updateCategory(CategoryModel category) async {
    debugPrint(
      'CategoryService.updateCategory: id=${category.id} name=${category.name}',
    );
    try {
      await _repository.updateCategory(category).timeout(_timeout);
      debugPrint('CategoryService.updateCategory: OK');
    } catch (e) {
      debugPrint('CategoryService.updateCategory failed: $e');
      rethrow;
    }
  }

  Future<void> deleteCategory(String id) async {
    debugPrint('CategoryService.deleteCategory: id=$id');
    try {
      await _repository.deleteCategory(id).timeout(_timeout);
      debugPrint('CategoryService.deleteCategory: OK');
    } catch (e) {
      debugPrint('CategoryService.deleteCategory failed: $e');
      rethrow;
    }
  }
}
