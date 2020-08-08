import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:traced_cache_manager/src/traced_file_service.dart';

/// The [TracedCacheManager] provides a default implementation of a [BaseCacheManager]
/// that automatically traces network calls and publishes the traces to Firebase
/// Performance Monitoring.
class TracedCacheManager extends BaseCacheManager {
  // Note this uses a different key than the [DefaultCacheManager],
  // forcing data to be re-downloaded on the first use.
  static const _key = 'libTracedCachedImageData';

  // The singleton instance.
  static TracedCacheManager _instance;

  /// Returns the singleton instance of the [TracedCacheManager].
  factory TracedCacheManager() {
    _instance ??= TracedCacheManager._();
    return _instance;
  }

  TracedCacheManager._() : super(_key, fileService: TracedHttpFileService());

  @override
  Future<String> getFilePath() async {
    var directory = await getTemporaryDirectory();
    return p.join(directory.path, _key);
  }
}
