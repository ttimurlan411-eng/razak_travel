import 'package:flutter/foundation.dart';
// ignore: depend_on_referenced_packages, unnecessary_import
import 'package:postgrest/postgrest.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_config.dart';

class SupabaseService {
  SupabaseService._();

  static final SupabaseService instance = SupabaseService._();

  SupabaseClient get client => Supabase.instance.client;

  SupabaseQueryBuilder get categories =>
      client.from(SupabaseConfig.categoriesTable);
  SupabaseQueryBuilder get tours => client.from(SupabaseConfig.toursTable);
  SupabaseQueryBuilder get departures =>
      client.from(SupabaseConfig.departuresTable);
  SupabaseQueryBuilder get bookings =>
      client.from(SupabaseConfig.bookingsTable);
  SupabaseQueryBuilder get notifications =>
      client.from(SupabaseConfig.notificationsTable);

  Future<List<Map<String, dynamic>>> query(
    SupabaseQueryBuilder table, {
    String? columns,
    String? order,
    bool ascending = true,
    int? limit,
  }) async {
    try {
      PostgrestTransformBuilder<PostgrestList> query =
          table.select(columns ?? '*');
      if (order != null) {
        query = query.order(order, ascending: ascending);
      }
      if (limit != null) {
        query = query.limit(limit);
      }
      final response = await query;
      debugPrint('SupabaseService.query: response count=${response.length}');
      return List<Map<String, dynamic>>.from(response);
    } catch (e, s) {
      debugPrint('SupabaseService.query FAILED: $e');
      debugPrint('SupabaseService.query stack: $s');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> queryEq(
    SupabaseQueryBuilder table,
    String column,
    dynamic value, {
    String? columns,
    String? order,
    bool ascending = true,
    int? limit,
  }) async {
    try {
      PostgrestTransformBuilder<PostgrestList> query =
          table.select(columns ?? '*').eq(column, value);
      if (order != null) {
        query = query.order(order, ascending: ascending);
      }
      if (limit != null) {
        query = query.limit(limit);
      }
      final response = await query;
      debugPrint('SupabaseService.queryEq: response count=${response.length}');
      return List<Map<String, dynamic>>.from(response);
    } catch (e, s) {
      debugPrint('SupabaseService.queryEq FAILED: $e');
      debugPrint('SupabaseService.queryEq stack: $s');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> querySingleEq(
    SupabaseQueryBuilder table,
    String column,
    dynamic value, {
    String? columns,
  }) async {
    try {
      final results = await queryEq(
        table,
        column,
        value,
        columns: columns,
        limit: 1,
      );
      return results.isNotEmpty ? results.first : null;
    } catch (e) {
      debugPrint('SupabaseService.querySingleEq failed: $e');
      rethrow;
    }
  }

  Future<void> upsert(
    SupabaseQueryBuilder table,
    Map<String, dynamic> values,
  ) async {
    try {
      debugPrint('SupabaseService.upsert: table=${table.toString()}');
      await table.upsert(values).select();
      debugPrint('SupabaseService.upsert: OK');
    } catch (e) {
      debugPrint('SupabaseService.upsert failed: $e');
      rethrow;
    }
  }

  Future<void> insert(
    SupabaseQueryBuilder table,
    Map<String, dynamic> values,
  ) async {
    try {
      debugPrint('SupabaseService.insert: table=${table.toString()}');
      debugPrint('SupabaseService.insert: payload=$values');
      final response = await table.insert(values).select();
      debugPrint('SupabaseService.insert: response=$response');
      debugPrint('SupabaseService.insert: OK');
    } catch (e, s) {
      debugPrint('SupabaseService.insert FAILED: $e');
      debugPrint('SupabaseService.insert stack: $s');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> update(
    SupabaseQueryBuilder table,
    Map<String, dynamic> values,
    String column,
    dynamic value,
  ) async {
    try {
      debugPrint(
          'SupabaseService.update: table=${table.toString()} column=$column value=$value');
      debugPrint('SupabaseService.update: payload=$values');
      final response = await table.update(values).eq(column, value).select();
      debugPrint('SupabaseService.update: response=$response');
      debugPrint('SupabaseService.update: OK');
      return List<Map<String, dynamic>>.from(response);
    } catch (e, s) {
      debugPrint('SupabaseService.update FAILED: $e');
      debugPrint('SupabaseService.update stack: $s');
      rethrow;
    }
  }

  Future<void> delete(
    SupabaseQueryBuilder table,
    String column,
    dynamic value,
  ) async {
    try {
      debugPrint(
          'SupabaseService.delete: table=${table.toString()} column=$column value=$value');
      await table.delete().eq(column, value);
      debugPrint('SupabaseService.delete: OK');
    } catch (e, s) {
      debugPrint('SupabaseService.delete FAILED: $e');
      debugPrint('SupabaseService.delete stack: $s');
      rethrow;
    }
  }

  Future<String> uploadFileBinary({
    required String bucket,
    required String path,
    required Uint8List fileBytes,
    String? contentType,
  }) async {
    try {
      debugPrint('SupabaseService.uploadFileBinary: bucket=$bucket path=$path');
      await client.storage.from(bucket).uploadBinary(
            path,
            fileBytes,
            fileOptions: FileOptions(contentType: contentType),
          );
      final url = client.storage.from(bucket).getPublicUrl(path);
      debugPrint('SupabaseService.uploadFileBinary: url=$url');
      return url;
    } catch (e) {
      debugPrint('SupabaseService.uploadFileBinary failed: $e');
      rethrow;
    }
  }

  Future<String> uploadFile({
    required String bucket,
    required String path,
    required dynamic file,
    String? contentType,
  }) async {
    try {
      debugPrint('SupabaseService.uploadFile: bucket=$bucket path=$path');
      await client.storage.from(bucket).upload(
            path,
            file,
            fileOptions: FileOptions(contentType: contentType),
          );
      final url = client.storage.from(bucket).getPublicUrl(path);
      debugPrint('SupabaseService.uploadFile: url=$url');
      return url;
    } catch (e) {
      debugPrint('SupabaseService.uploadFile failed: $e');
      rethrow;
    }
  }
}
