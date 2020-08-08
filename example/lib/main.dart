import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:traced_cache_manager/traced_cache_manager.dart';

// TODO: Make sure to setup Firebase Performance Monitoring.
void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  /// Example usage #2 from the README.
  Future<File> fetchFile(String uri) async {
    return await TracedCacheManager().getSingleFile(uri);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Traced Cache Manager Example',
      home: Container(),
    );
  }
}

/// Example usage #3 from the README.
class MyCustomCacheManager extends BaseCacheManager {
  static const key = 'libMyCustomCachedImageData';

  MyCustomCacheManager() : super(key, fileService: TracedHttpFileService());

  @override
  Future<String> getFilePath() {
    throw UnimplementedError();
  }
}
