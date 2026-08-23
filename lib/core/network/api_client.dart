// Requires the `http` package in pubspec.yaml:
//   dependencies:
//     http: ^1.2.0

import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'api_exception.dart';
import 'app_config.dart';

/// Generic, dependency-light REST client used by every `*ApiService`
/// in the app. Centralizes JSON decoding, timeouts, and error
/// mapping so individual services stay tiny and only describe
/// *which* endpoint they call.
class ApiClient {
  final http.Client _client;
  final String baseUrl;

  ApiClient({required this.baseUrl, http.Client? client})
      : _client = client ?? http.Client();

  bool get isConfigured => baseUrl.isNotEmpty;

  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    if (!isConfigured) throw const ApiNotConfiguredException();

    final uri = _buildUri(path, queryParameters);

    try {
      final response = await _client
          .get(uri, headers: _headers)
          .timeout(AppConfig.requestTimeout);
      return _decode(response);
    } on ApiException {
      rethrow;
    } on SocketException {
      throw const ApiNetworkException();
    } on HttpException {
      throw const ApiNetworkException();
    } catch (_) {
      throw const ApiNetworkException();
    }
  }

  Future<dynamic> post(String path, {Object? body}) async {
    if (!isConfigured) throw const ApiNotConfiguredException();

    final uri = _buildUri(path, null);

    try {
      final response = await _client
          .post(uri, headers: _headers, body: jsonEncode(body))
          .timeout(AppConfig.requestTimeout);
      return _decode(response);
    } on ApiException {
      rethrow;
    } on SocketException {
      throw const ApiNetworkException();
    } on HttpException {
      throw const ApiNetworkException();
    } catch (_) {
      throw const ApiNetworkException();
    }
  }

  Map<String, String> get _headers => const {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  Uri _buildUri(String path, Map<String, dynamic>? query) {
    final normalizedBase =
        baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    final normalizedPath = path.startsWith('/') ? path : '/$path';

    final stringQuery = query == null
        ? null
        : query.map((key, value) => MapEntry(key, '$value'));

    return Uri.parse('$normalizedBase$normalizedPath').replace(
      queryParameters: stringQuery?.isEmpty ?? true ? null : stringQuery,
    );
  }

  dynamic _decode(http.Response response) {
    final statusCode = response.statusCode;

    if (statusCode < 200 || statusCode >= 300) {
      throw ApiServerException(statusCode);
    }

    if (response.body.isEmpty) return null;

    try {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } catch (_) {
      throw const ApiParsingException();
    }
  }

  void dispose() => _client.close();
}
