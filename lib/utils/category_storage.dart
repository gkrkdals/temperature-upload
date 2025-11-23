import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CategoryStorage {
  /// 카테고리별 값 저장
  Future<void> saveCategory(String category, Map<String, dynamic> values) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(values);
    await prefs.setString(category, jsonString);
  }

  /// 카테고리별 값 불러오기
  Future<Map<String, dynamic>> loadCategory(String category) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(category);
    if (jsonString == null) return {};
    return jsonDecode(jsonString);
  }

  /// 카테고리 삭제
  Future<void> removeCategory(String category) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(category);
  }

  /// 모든 카테고리 불러오기
  Future<Map<String, Map<String, dynamic>>> loadAllCategories() async {
    final prefs = await SharedPreferences.getInstance();
    final allKeys = prefs.getKeys();
    final result = <String, Map<String, dynamic>>{};
    for (var key in allKeys) {
      try {
        final jsonString = prefs.getString(key);
        if (jsonString != null) {
          result[key] = jsonDecode(jsonString);
        } else {
          result[key] = {};
        }
      } catch (_) {
        result[key] = {};
      }
    }
    return result;
  }
}