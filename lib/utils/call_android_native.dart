import 'package:flutter/services.dart';

/// Call this to notice android MediaStore that something has changed at
/// certain [paths].
Future<void> refreshMediaStore(List<String> paths) async {
  try {
    final List<dynamic> result = await _refreshMediaChannel
        .invokeMethod('refreshMediaStore', {'path': paths});
    print(result);
  } on PlatformException catch (e) {
    print(e.message);
  }
}

const _refreshMediaChannel = const MethodChannel('temposcape.flutter/refresh');
