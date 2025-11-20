import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureCategoryStorage {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  /// 카테고리별 값 저장
  Future<void> saveCategory(String category, Map<String, dynamic> values) async {
    final jsonString = jsonEncode(values);
    await _storage.write(key: category, value: jsonString);
  }

  /// 카테고리별 값 불러오기
  Future<Map<String, dynamic>> loadCategory(String category) async {
    final jsonString = await _storage.read(key: category);
    if (jsonString == null) return {};
    return jsonDecode(jsonString);
  }

  /// 카테고리 삭제
  Future<void> removeCategory(String category) async {
    await _storage.delete(key: category);
  }

  /// 모든 카테고리 불러오기
  Future<Map<String, Map<String, dynamic>>> loadAllCategories() async {
    final all = await _storage.readAll();
    final result = <String, Map<String, dynamic>>{};
    for (var entry in all.entries) {
      try {
        result[entry.key] = jsonDecode(entry.value);
      } catch (_) {
        result[entry.key] = {};
      }
    }
    return result;
  }
}
