import 'dart:developer';
import 'dart:io';

import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:http/http.dart' as http;

/// A [FileService] that supports tracing network calls using Firebase Performance Monitoring.
///
/// If you are writing a custom cache implementation and want automatic tracing,
/// you can use this [TracedHttpFileService] as an argument to the [BaseCacheManager].
///
/// Otherwise, you can use [TracedCacheManager] directly and not worry about this class.
class TracedHttpFileService implements FileService {
  http.Client _httpClient;

  TracedHttpFileService({http.Client httpClient}) {
    _httpClient = httpClient ?? http.Client();
  }

  @override
  Future<FileServiceResponse> get(String url,
      {Map<String, String> headers = const {}}) async {
    final req = http.Request('GET', Uri.parse(url));
    req.headers.addAll(headers);

    // Start the trace.
    final HttpMetric metric = FirebasePerformance.instance
        .newHttpMetric(req.url.toString(), HttpMethod.Get);
    await metric.start();

    try {
      // The actual request.
      log('TracedCacheManager making HTTP request: ${req.toString()}',
          level: 2);
      final response = await _httpClient.send(req);

      // Handle nulls explicitly, as firebase performance's java plugin does not.
      // https://github.com/FirebaseExtended/flutterfire/issues/1135
      if (response.contentLength != null) {
        metric.responsePayloadSize = response.contentLength;
      }
      if (response.headers.containsKey(HttpHeaders.contentTypeHeader)) {
        metric.responseContentType =
            response.headers[HttpHeaders.contentTypeHeader];
      }
      metric.requestPayloadSize = req.contentLength;
      metric.httpResponseCode = response.statusCode;

      return HttpGetResponse(response);
    } finally {
      // On exceptions or on return, end the trace.
      await metric.stop();
    }
  }
}
