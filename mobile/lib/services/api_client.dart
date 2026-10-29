import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'token_storage.dart';
import 'retry_service.dart';

/// Hard timeout for every HTTP request.
/// Chosen to be longer than Gemini's max retry window (~12s) but short enough
/// to give meaningful feedback on slow campus Wi-Fi during 45-student mass testing.
const Duration _kRequestTimeout = Duration(seconds: 65);

class ApiException implements Exception {
  final int statusCode;
  final String message;

  ApiException(this.statusCode, this.message);

  @override
  String toString() => 'ApiException: $statusCode - $message';
}

class ApiClient {
  final TokenStorage _tokenStorage = TokenStorage();
  final int _maxRetries = 3;

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
        final detail = body['detail'];
        if (detail is String) {
          errorMessage = detail;
        } else if (detail is List && detail.isNotEmpty) {
          final List<String> errorList = [];
          for (final item in detail) {
            if (item is Map && item.containsKey('msg')) {
              final msg = item['msg']?.toString() ?? '';
              final loc = item['loc'];
              String? field;
              if (loc is List && loc.isNotEmpty) {
                final last = loc.last.toString();
                if (last != 'body' && last != '__root__') {
                  field = last;
                }
              }
              if (field != null &&
                  field.isNotEmpty &&
                  !msg.toLowerCase().contains(field.toLowerCase())) {
                final capitalized = field[0].toUpperCase() +
                    field.substring(1).replaceAll('_', ' ');
                errorList.add('$capitalized: $msg');
              } else {
                errorList.add(msg);
              }
            } else if (item != null) {
              errorList.add(item.toString());
            }
          }
          if (errorList.isNotEmpty) {
            errorMessage = errorList.join('\n');
          } else {
            errorMessage = detail.toString();
          }
        } else {
          errorMessage = detail.toString();
        }
      } else if (body is Map && body.containsKey('message')) {
        errorMessage = body['message'].toString();
      }
    } catch (_) {
      // Body is not JSON
      if (response.body.isNotEmpty) {
        errorMessage = response.body;
      }
    }

    throw ApiException(response.statusCode, errorMessage);
  }

  bool _shouldRetry(Exception e) {
    if (e is SocketException || e is http.ClientException) return true;
    if (e is TimeoutException) return true; // Hard 30s timeout — retry on slow network
    if (e is ApiException) {
      // Retry on server errors or timeouts, but NOT on 429 (rate limit) or 4xx client errors
      return e.statusCode >= 500 || e.statusCode == 408;
    }
    return false;
  }

  Future<http.Response> _executeWithRetry(
    Future<http.Response> Function() requestFunc, {
    bool silent = false,
  }) async {
    int attempts = 0;
    while (true) {
      try {
        attempts++;
        final response = await requestFunc();
        // If it succeeded and wasn't silent, clear retry banner
        if (attempts > 1 && !silent) RetryService().stopRetry();
        return response;
      } catch (e) {
        if (attempts >= _maxRetries || !_shouldRetry(e as Exception)) {
          if (!silent) RetryService().stopRetry();
          rethrow;
        }
        
        // Tell UI we are retrying only if not silent
        if (!silent) {
          RetryService().startRetry('Retrying... ($attempts/$_maxRetries)');
        }
        
        // Exponential backoff: 1s, 2s, 4s
        final delayMs = 1000 * (1 << (attempts - 1));
        await Future.delayed(Duration(milliseconds: delayMs));
      }
    }
  }

  Future<dynamic> get(String path, {Map<String, String>? queryParams, bool silent = false}) async {
    final baseUri = Uri.parse('${ApiConfig.baseUrl}$path');
    final uri = (queryParams != null && queryParams.isNotEmpty)
        ? baseUri.replace(
            queryParameters: {
              ...baseUri.queryParameters,
              ...queryParams,
            },
          )
        : baseUri;
    
    final response = await _executeWithRetry(() async {
      final headers = await _getHeaders();
      return http.get(uri, headers: headers).timeout(_kRequestTimeout);
    }, silent: silent);

    _handleResponse(response);
    
    if (response.body.isEmpty) return null;
    return jsonDecode(response.body);
  }

  Future<dynamic> post(String path, {Map<String, dynamic>? body, bool silent = false}) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$path');
    
    final response = await _executeWithRetry(() async {
      final headers = await _getHeaders();
      return http.post(
        uri,
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      ).timeout(_kRequestTimeout);
    }, silent: silent);

    _handleResponse(response);
    
    if (response.body.isEmpty) return null;
    return jsonDecode(response.body);
  }

  Future<dynamic> put(String path, {Map<String, dynamic>? body, bool silent = false}) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$path');
    
    final response = await _executeWithRetry(() async {
      final headers = await _getHeaders();
      return http.put(
        uri,
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      ).timeout(_kRequestTimeout);
    }, silent: silent);

    _handleResponse(response);
    
    if (response.body.isEmpty) return null;
    return jsonDecode(response.body);
  }

  Future<dynamic> patch(String path, {Map<String, dynamic>? body, bool silent = false}) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$path');
    
    final response = await _executeWithRetry(() async {
      final headers = await _getHeaders();
      return http.patch(
        uri,
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      ).timeout(_kRequestTimeout);
    }, silent: silent);

    _handleResponse(response);
    
    if (response.body.isEmpty) return null;
    return jsonDecode(response.body);
  }

  Future<dynamic> delete(String path, {bool silent = false}) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$path');
    
    final response = await _executeWithRetry(() async {
      final headers = await _getHeaders();
      return http.delete(uri, headers: headers).timeout(_kRequestTimeout);
    }, silent: silent);

    _handleResponse(response);
    
    if (response.body.isEmpty) return null;
    return jsonDecode(response.body);
  }
}
