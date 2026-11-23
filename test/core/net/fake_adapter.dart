import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

import 'package:kust/core/net/api_client.dart';

typedef FakeHandler = FutureOr<ResponseBody> Function(RequestOptions options);

class FakeAdapter implements HttpClientAdapter {
  FakeAdapter(this.handler);

  FakeHandler handler;
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody jsonBody(Object? body, {int status = 200}) =>
    ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: ['application/json; charset=utf-8'],
      },
    );

ResponseBody emptyBody(int status) => ResponseBody.fromString('', status);

ResponseBody textBody(String text, int status) => ResponseBody.fromString(
  text,
  status,
  headers: {
    Headers.contentTypeHeader: ['text/plain'],
  },
);

Never networkDown(RequestOptions options) => throw DioException(
  requestOptions: options,
  type: DioExceptionType.connectionError,
  message: 'down',
);

({ApiClient api, FakeAdapter adapter}) testApi(FakeHandler handler) {
  final adapter = FakeAdapter(handler);
  final dio = Dio(
    BaseOptions(
      baseUrl: 'http://test',
      responseType: ResponseType.json,
      validateStatus: (_) => true,
    ),
  )..httpClientAdapter = adapter;
  return (api: ApiClient(baseUrl: 'http://test', dio: dio), adapter: adapter);
}
