import 'dart:io';
import 'package:path/path.dart';
import 'dart:developer' as developer;

class ApiKeysService {
  static const _fileName = 'api_keys.txt';
  static const _orionPrefix = 'orion_app_key = ';
  static const _simklPrefix = 'simkl_api_key = ';
  static const _tmdbPrefix = 'tmdb_api_key = ';
  static const _premiumizePrefix = 'premiumize_api_key = ';
  static const _traktPrefix = 'trakt_client_id = ';
  static const _tvdbPrefix = 'tvdb_api_key = ';
  
  static Future<String> get _filePath async {
    final dbDir = Directory('/storage/emulated/0/Debrid_Player');
    await dbDir.create(recursive: true);
    return join(dbDir.path, _fileName);
  }

  static Future<Map<String, String>> readApiKeys() async {
    try {
      final file = File(await _filePath);
      
      if (!await file.exists()) {
        developer.log(
          'API keys file not found',
          name: 'ApiKeysService',
          error: {'path': await _filePath},
          level: 900,
        );
        return {};
      }

      final lines = await file.readAsLines();
      final keys = <String, String>{};

      for (final line in lines) {
        if (line.startsWith(_orionPrefix)) {
          keys['orion'] = line.substring(_orionPrefix.length).trim();
        } else if (line.startsWith(_simklPrefix)) {
          keys['simkl'] = line.substring(_simklPrefix.length).trim();
        } else if (line.startsWith(_tmdbPrefix)) {
          keys['tmdb'] = line.substring(_tmdbPrefix.length).trim();
        } else if (line.startsWith(_premiumizePrefix)) {
          keys['premiumize'] = line.substring(_premiumizePrefix.length).trim();
        } else if (line.startsWith(_traktPrefix)) {
          keys['trakt'] = line.substring(_traktPrefix.length).trim();
        } else if (line.startsWith(_tvdbPrefix)) {
          keys['tvdb'] = line.substring(_tvdbPrefix.length).trim();
        }
      }

      return keys;
    } catch (e, stackTrace) {
      developer.log(
        'Error reading API keys',
        name: 'ApiKeysService',
        error: e,
        stackTrace: stackTrace,
        level: 1000,
      );
      return {};
    }
  }
} 