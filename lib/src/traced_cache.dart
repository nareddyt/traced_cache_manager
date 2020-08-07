import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:traced_cache_manager/src/traced_file_service.dart';

/// The TracedCacheManager that can be easily used directly.
/// This supports tracing network calls using Firebase Performance Monitoring.
class TracedCacheManager extends BaseCacheManager {
  static const key = 'libCachedImageData';

  static TracedCacheManager _instance;

  factory TracedCacheManager() {
    _instance ??= TracedCacheManager._();
    return _instance;
  }

  TracedCacheManager._() : super(key, fileService: TracedHttpFileService());

  @override
  Future<String> getFilePath() async {
    var directory = await getTemporaryDirectory();
    return p.join(directory.path, key);
  }
}
