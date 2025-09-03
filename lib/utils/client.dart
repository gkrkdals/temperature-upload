import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class Client {
  static const _baseUrl = 'http://subul.co.kr';
  // static const _baseUrl = 'http://192.168.0.3:8080';

  static final _client = http.Client();
  static final _storage = FlutterSecureStorage();

  /// JWT 토큰 읽기
  static Future<String?> _getToken() async {
    return await _storage.read(key: 'jwt');
  }

  /// 공통 헤더 생성
  static Future<Map<String, String>> _getHeaders({Map<String, String>? extraHeaders}) async {
    final token = await _getToken();
    final headers = {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    if (extraHeaders != null) {
      headers.addAll(extraHeaders);
    }

    return headers;
  }

  /// GET 요청
  static Future<http.Response> get(String endpoint) async {
    final headers = await _getHeaders();
    final url = Uri.parse('$_baseUrl$endpoint');
    return _client.get(url, headers: headers);
  }

  /// POST 요청
  static Future<http.Response> post(String endpoint, {Object? body}) async {
    final headers = await _getHeaders();
    final url = Uri.parse('$_baseUrl$endpoint');
    return _client.post(url, headers: headers, body: jsonEncode(body ?? {}));
  }

  /// PUT 요청
  static Future<http.Response> put(String endpoint, {Object? body}) async {
    final headers = await _getHeaders();
    final url = Uri.parse('$_baseUrl$endpoint');
    return _client.put(url, headers: headers, body: jsonEncode(body ?? {}));
  }

  /// DELETE 요청
  static Future<http.Response> delete(String endpoint) async {
    final headers = await _getHeaders();
    final url = Uri.parse('$_baseUrl$endpoint');
    return _client.delete(url, headers: headers);
  }
}