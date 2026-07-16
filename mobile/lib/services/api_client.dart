import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'token_storage.dart';

class ApiException implements Exception {
  final int statusCode;
  final String message;

  ApiException(this.statusCode, this.message);

  @override
  String toString() => 'ApiException: $statusCode - $message';
}

class ApiClient {
  final TokenStorage _tokenStorage = TokenStorage();

  Future<Map<String, String>> _getHeaders() async {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    final token = await _tokenStorage.getToken();
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  void _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return; // Success
    }

    String errorMessage = 'Something went wrong';
    try {
      final body = jsonDecode(response.body);
      if (body is Map && body.containsKey('detail')) {
        errorMessage = body['detail'].toString();
      }
    } catch (_) {
      // Body is not JSON
      if (response.body.isNotEmpty) {
        errorMessage = response.body;
      }
    }

    throw ApiException(response.statusCode, errorMessage);
  }

  Future<dynamic> get(String path, {Map<String, String>? queryParams}) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$path').replace(queryParameters: queryParams);
    final headers = await _getHeaders();

    final response = await http.get(uri, headers: headers);
    _handleResponse(response);
    
    if (response.body.isEmpty) return null;
    return jsonDecode(response.body);
  }

  Future<dynamic> post(String path, {Map<String, dynamic>? body}) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$path');
    final headers = await _getHeaders();

    final response = await http.post(
      uri,
      headers: headers,
      body: body != null ? jsonEncode(body) : null,
    );
    _handleResponse(response);
    
    if (response.body.isEmpty) return null;
    return jsonDecode(response.body);
  }

  Future<dynamic> patch(String path, {Map<String, dynamic>? body}) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$path');
    final headers = await _getHeaders();

    final response = await http.patch(
      uri,
      headers: headers,
      body: body != null ? jsonEncode(body) : null,
    );
    _handleResponse(response);
    
    if (response.body.isEmpty) return null;
    return jsonDecode(response.body);
  }

  Future<dynamic> delete(String path) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$path');
    final headers = await _getHeaders();

    final response = await http.delete(uri, headers: headers);
    _handleResponse(response);
    
    if (response.body.isEmpty) return null;
    return jsonDecode(response.body);
  }
}
