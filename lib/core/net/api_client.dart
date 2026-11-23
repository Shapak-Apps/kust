import 'dart:async';

import 'package:dio/dio.dart';

class ApiException implements Exception {
  const ApiException({
    required this.code,
    required this.message,
    this.status,
    this.retryAfter,
  });

  static const String networkCode = 'network';
  static const String badResponseCode = 'bad_response';

  final String code;
  final String message;
  final int? status;
  final int? retryAfter;

  bool get isNetwork => code == networkCode;

  @override
  String toString() => 'ApiException($code, status: $status): $message';
}

class ApiClient {
  ApiClient({
    required String baseUrl,
    Dio? dio,
    Duration timeout = const Duration(seconds: 10),
  }) : _dio =
           dio ??
           Dio(
             BaseOptions(
               baseUrl: baseUrl,
               connectTimeout: timeout,
               sendTimeout: timeout,
               receiveTimeout: timeout,
               responseType: ResponseType.json,
               validateStatus: (_) => true,
               headers: const {'Accept': 'application/json'},
             ),
           );

  final Dio _dio;

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, String>? query,
    String? token,
  }) => _send('GET', path, query: query, token: token);

  Future<Map<String, dynamic>> post(
    String path, {
    Object? body,
    String? token,
  }) => _send('POST', path, body: body, token: token);

  Future<Map<String, dynamic>> patch(
    String path, {
    Object? body,
    String? token,
  }) => _send('PATCH', path, body: body, token: token);

  Future<Map<String, dynamic>> put(
    String path, {
    Object? body,
    String? token,
  }) => _send('PUT', path, body: body, token: token);

  /// Sends [bytes] as the whole body, such as a photo.
  Future<Map<String, dynamic>> putBytes(
    String path, {
    required List<int> bytes,
    required String contentType,
    String? token,
  }) => _send(
    'PUT',
    path,
    body: Stream.value(bytes),
    token: token,
    headers: {
      'Content-Type': contentType,
      Headers.contentLengthHeader: bytes.length,
    },
  );

  Future<Map<String, dynamic>> delete(String path, {String? token}) =>
      _send('DELETE', path, token: token);

  Future<bool> ping({Duration timeout = const Duration(seconds: 5)}) async {
    try {
      final response = await _dio.get<dynamic>('/healthz').timeout(timeout);
      return response.statusCode == 200;
    } on Exception {
      return false;
    }
  }

  void close() => _dio.close(force: true);

  Future<Map<String, dynamic>> _send(
    String method,
    String path, {
    Map<String, String>? query,
    Object? body,
    String? token,
    Map<String, Object>? headers,
  }) async {
    final Response<dynamic> response;
    try {
      response = await _dio.request<dynamic>(
        path,
        data: body,
        queryParameters: query,
        options: Options(
          method: method,
          headers: {
            ...?headers,
            if (token != null) 'Authorization': 'Bearer $token',
          },
        ),
      );
    } on DioException catch (e) {
      if (e.error is FormatException) {
        throw const ApiException(
          code: ApiException.badResponseCode,
          message: 'The server sent something unexpected.',
        );
      }
      throw ApiException(
        code: ApiException.networkCode,
        message: e.message ?? 'Could not reach the server.',
      );
    }
    return _decode(response);
  }

  Map<String, dynamic> _decode(Response<dynamic> response) {
    final status = response.statusCode ?? 0;
    final data = response.data;
    final ok = status >= 200 && status < 300;

    if (ok) {
      if (data == null || (data is String && data.isEmpty)) return const {};
      if (data is Map<String, dynamic>) return data;
      throw ApiException(
        code: ApiException.badResponseCode,
        message: 'The server sent something unexpected.',
        status: status,
      );
    }

    if (data is Map<String, dynamic> && data['error'] is Map) {
      final error = data['error'] as Map;
      throw ApiException(
        code: error['code'] is String
            ? error['code'] as String
            : 'http_$status',
        message: error['message'] is String
            ? error['message'] as String
            : 'Request failed.',
        status: status,
        retryAfter: error['retry_after'] is int
            ? error['retry_after'] as int
            : null,
      );
    }
    throw ApiException(
      code: 'http_$status',
      message: 'Request failed ($status).',
      status: status,
    );
  }
}
