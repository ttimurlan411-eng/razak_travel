import 'dart:async';

import 'package:flutter/foundation.dart';
// ignore: depend_on_referenced_packages
import 'package:postgrest/postgrest.dart';
import 'package:razak_travel/core/services/admin_access_service.dart';
import 'package:razak_travel/core/services/supabase_service.dart';
import 'package:razak_travel/data/models/category_model.dart';

class CategoryRepository {
  final SupabaseService _supabase = SupabaseService.instance;
  final _adminAccessService = AdminAccessService();

  Duration get _timeout => const Duration(seconds: 15);

  Future<List<CategoryModel>> getCategories() async {
    debugPrint('CategoryRepository.getCategories: fetching...');
    try {
      final data = await _supabase
          .query(
            _supabase.categories,
            order: 'created_at',
            ascending: false,
          )
          .timeout(_timeout);
      final categories = data
          .map((json) => CategoryModel.fromJson(json))
          .toList()
        ..sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );
      debugPrint(
        'CategoryRepository.getCategories: fetched ${categories.length} categories',
      );
      return categories;
    } on PostgrestException catch (e) {
      debugPrint(
        'CategoryRepository.getCategories: PostgrestException '
        'code=${e.code} message=${e.message}',
      );
      rethrow;
    } catch (e) {
      debugPrint('CategoryRepository.getCategories failed: $e');
      rethrow;
    }
  }

  Future<void> addCategory(CategoryModel category) async {
    final payload = category.toJson();
    payload.remove('id');
    debugPrint(
      'CategoryRepository.addCategory: id=${category.id} name=${category.name}',
    );
    debugPrint('CATEGORY INSERT PAYLOAD: $payload');
    try {
      await _adminAccessService.ensureAdminOrOwnerAccess();
      debugPrint('CategoryRepository.addCategory: admin access OK, inserting...');
      await _supabase
          .insert(_supabase.categories, payload)
          .timeout(_timeout);
      debugPrint('CategoryRepository.addCategory: insert OK');
    } on PostgrestException catch (e) {
      debugPrint(
        'CategoryRepository.addCategory: PostgrestException at line 53 '
        'code=${e.code} message=${e.message}',
      );
      rethrow;
    } catch (e, s) {
      debugPrint('CategoryRepository.addCategory failed at line 56: $e');
      debugPrint('CategoryRepository.addCategory stack: $s');
      rethrow;
    }
  }

  Future<void> updateCategory(CategoryModel category) async {
    final json = category.toJson();
    debugPrint(
      'CategoryRepository.updateCategory: id=${category.id} name=${category.name}',
    );
    debugPrint('CategoryRepository.updateCategory: payload=$json');
    try {
      await _adminAccessService.ensureAdminOrOwnerAccess();
      debugPrint('CategoryRepository.updateCategory: admin access OK, updating...');
      await _supabase
          .update(
            _supabase.categories,
            json,
            'id',
            category.id,
          )
          .timeout(_timeout);
      debugPrint('CategoryRepository.updateCategory: update OK');
    } on PostgrestException catch (e) {
      debugPrint(
        'CategoryRepository.updateCategory: PostgrestException at line 80 '
        'code=${e.code} message=${e.message}',
      );
      rethrow;
    } catch (e, s) {
      debugPrint('CategoryRepository.updateCategory failed at line 84: $e');
      debugPrint('CategoryRepository.updateCategory stack: $s');
      rethrow;
    }
  }

  Future<void> deleteCategory(String id) async {
    debugPrint('CategoryRepository.deleteCategory: id=$id');
    try {
      await _adminAccessService.ensureAdminOrOwnerAccess();

      final linkedTours = await _supabase
          .queryEq(
            _supabase.tours,
            'category_id',
            id,
            limit: 1,
          )
          .timeout(_timeout);

      if (linkedTours.isNotEmpty) {
        throw 'category_has_linked_tours';
      }

      await _supabase.delete(_supabase.categories, 'id', id).timeout(_timeout);
      debugPrint('CategoryRepository.deleteCategory: deleted OK');
    } on PostgrestException catch (e) {
      debugPrint(
        'CategoryRepository.deleteCategory: PostgrestException '
        'code=${e.code} message=${e.message}',
      );
      rethrow;
    } catch (e) {
      debugPrint('CategoryRepository.deleteCategory failed: $e');
      rethrow;
    }
  }
}
