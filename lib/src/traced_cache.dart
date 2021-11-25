import 'dart:async';

import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:http/http.dart';

/// The [TracedCacheManager] provides a default implementation of [CacheManager]
/// that automatically traces network calls and publishes the traces to Firebase
/// Performance Monitoring.
class TracedCacheManager extends CacheManager with ImageCacheManager {
  // Note this uses a different key than the [DefaultCacheManager],
  // forcing data to be re-downloaded on the first use.
  static const _key = 'TracedCacheManager';

  // The singleton instance.
  static TracedCacheManager? _instance;

  /// Returns the singleton instance of the [TracedCacheManager].
  factory TracedCacheManager() {
    _instance ??= TracedCacheManager._();
    return _instance!;
  }

  TracedCacheManager._() : super(Config(_key));

  @override
  Stream<FileResponse> getFileStream(String url,
      {String? key, Map<String, String>? headers, bool withProgress = false}) {
    key ??= url;
    final streamController = StreamController<FileResponse>();
    _pushFileToStream(streamController, url, key, headers, withProgress);
    return streamController.stream;
  }

  Future<void> _pushFileToStream(StreamController streamController, String url, String? key,
      Map<String, String>? headers, bool withProgress) async {
    key ??= url;
    FileInfo? cacheFile;
    try {
      cacheFile = await getFileFromCache(key);
      if (cacheFile != null) {
        streamController.add(cacheFile);
        withProgress = false;
      }
    } catch (e) {
      print('TracedCacheManager: Failed to load cached file for $url with error:\n$e');
    }
    if (cacheFile == null || cacheFile.validTill.isBefore(DateTime.now())) {
      final Request req = Request('GET', Uri.parse(url));
      req.headers.addAll(headers ?? {});
      final HttpMetric metric =
          FirebasePerformance.instance.newHttpMetric(req.url.toString(), HttpMethod.Get);
      await metric.start();
      try {
        await for (var response
            in super.webHelper.downloadFile(url, key: key, authHeaders: headers)) {
          if (response is DownloadProgress && withProgress) {
            streamController.add(response);
          }
          if (response is FileInfo) {
            streamController.add(response);
          }
        }
      } catch (e) {
        assert(() {
          print('TracedCacheManager: Failed to download file from $url with error:\n$e');
          return true;
        }());
        if (cacheFile == null && streamController.hasListener) {
          streamController.addError(e);
        }
      } finally {
        metric.stop();
      }
    }
    unawaited(streamController.close());
  }

  Future<FileInfo> downloadFile(String url,
      {String? key, Map<String, String>? authHeaders, bool force = false}) async {
    final Request req = Request('GET', Uri.parse(url));
    req.headers.addAll(authHeaders ?? {});
    final HttpMetric metric =
        FirebasePerformance.instance.newHttpMetric(req.url.toString(), HttpMethod.Get);
    await metric.start();

    try {
      return super.downloadFile(url, key: key, authHeaders: authHeaders, force: force);
    } finally {
      metric.stop();
    }
  }
}
