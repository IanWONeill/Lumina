import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart';

class DownloadService {
  static const platform = MethodChannel('app_channel');

  Future<void> downloadAndInstallApk(
    String url,
    void Function(double) onProgress,
    void Function() onComplete,
    void Function(String) onError,
  ) async {
    try {
      await _cleanupOldApks();

      final client = http.Client();
      final request = http.Request('GET', Uri.parse(url));
      final response = await client.send(request);
      
      final contentLength = response.contentLength ?? 0;
      int received = 0;
      
      final directory = await getExternalStorageDirectory();
      if (directory == null) {
        onError('Cannot access storage');
        return;
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${directory.path}/update_$timestamp.apk');
      final sink = file.openWrite();

      await response.stream.forEach((chunk) {
        sink.add(chunk);
        received += chunk.length;
        if (contentLength > 0) {
          onProgress(received / contentLength);
        }
      });

      await sink.close();
      client.close();
      
      await file.setLastModified(DateTime.now());
      
      onComplete();

      try {
        await platform.invokeMethod('installApk', {
          'filePath': file.path,
        });
      } catch (e) {
        onError('Failed to launch installer: $e');
      }
    } catch (e) {
      onError(e.toString());
    }
  }

  Future<void> _cleanupOldApks() async {
    try {
      final directory = await getExternalStorageDirectory();
      if (directory == null) return;

      final files = directory.listSync();
      for (var entity in files) {
        if (entity is File && entity.path.endsWith('.apk')) {
          final fileAge = DateTime.now().difference(entity.lastModifiedSync());
          if (fileAge.inHours > 24) {
            await entity.delete();
          }
        }
      }
    } catch (e) {
      print('Cleanup error: $e');
    }
  }
} 