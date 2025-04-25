import 'dart:io';
import 'package:path/path.dart';
import 'dart:developer' as developer;
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';

class ApiKeysService {
  static const _fileName = 'api_keys.txt';
  static const _orionPrefix = 'orion_app_key = ';
  static const _simklPrefix = 'simkl_api_key = ';
  static const _tmdbPrefix = 'tmdb_api_key = ';
  static const _premiumizePrefix = 'premiumize_api_key = ';
  static const _traktPrefix = 'trakt_client_id = ';
  static const _tvdbPrefix = 'tvdb_api_key = ';
  
  static const _defaultValue = 'your_key_here';
  
  static const _requiredKeys = [
    'tvdb',
    'tmdb',
    'premiumize',
  ];

  static const _optionalKeys = [
    'simkl',
    'trakt',
  ];
  
  static Future<String> get _filePath async {
    final dbDir = Directory('/storage/emulated/0/Debrid_Player');
    await dbDir.create(recursive: true);
    return join(dbDir.path, _fileName);
  }

  static Future<bool> hasStoragePermission() async {
    try {
      final deviceInfo = await DeviceInfoPlugin().androidInfo;
      final sdkInt = deviceInfo.version.sdkInt;

      if (sdkInt >= 30) {
        if (!await Permission.manageExternalStorage.isGranted) {
          final result = await Permission.manageExternalStorage.request();
          return result.isGranted;
        }
        return true;
      } else if (sdkInt >= 29) {
        if (!await Permission.storage.isGranted) {
          final result = await Permission.storage.request();
          return result.isGranted;
        }
        return true;
      } else {
        if (!await Permission.storage.isGranted) {
          final result = await Permission.storage.request();
          return result.isGranted;
        }
        return true;
      }
    } catch (e, stackTrace) {
      developer.log(
        'Error checking storage permission',
        name: 'ApiKeysService',
        error: e,
        stackTrace: stackTrace,
        level: 1000,
      );
      return false;
    }
  }

  static Future<bool> createApiKeysFileIfNotExists() async {
    try {
      final file = File(await _filePath);
      
      if (!await file.exists()) {
        final template = '''
These 3 keys are required.
$_tvdbPrefix your_key_here
$_tmdbPrefix your_key_here
$_premiumizePrefix your_key_here
Add either of these keys to the services you plan to use.(you must have at least one)
$_simklPrefix your_key_here
$_traktPrefix your_key_here
Add this key if you plan to use orionoid.(this key is optional)
$_orionPrefix your_key_here
''';
        
        await file.writeAsString(template);
        developer.log(
          'Created API keys template file',
          name: 'ApiKeysService',
          level: 800,
        );
        return true;
      }
      return false;
    } catch (e, stackTrace) {
      developer.log(
        'Error creating API keys file',
        name: 'ApiKeysService',
        error: e,
        stackTrace: stackTrace,
        level: 1000,
      );
      return false;
    }
  }

  static Future<Map<String, List<String>>> checkApiKeys() async {
    try {
      final file = File(await _filePath);
      if (!await file.exists()) {
        return {
          'missingRequired': _requiredKeys,
          'missingOptional': _optionalKeys,
        };
      }

      final lines = await file.readAsLines();
      final missingRequired = <String>[];
      final missingOptional = <String>[];
      final hasOptionalKey = <String>[];

      for (final key in _requiredKeys) {
        bool found = false;
        for (final line in lines) {
          if (key == 'tvdb' && line.startsWith(_tvdbPrefix)) {
            found = line.substring(_tvdbPrefix.length).trim() != _defaultValue;
          } else if (key == 'tmdb' && line.startsWith(_tmdbPrefix)) {
            found = line.substring(_tmdbPrefix.length).trim() != _defaultValue;
          } else if (key == 'premiumize' && line.startsWith(_premiumizePrefix)) {
            found = line.substring(_premiumizePrefix.length).trim() != _defaultValue;
          }
          if (found) break;
        }
        if (!found) {
          missingRequired.add(key);
        }
      }

      for (final key in _optionalKeys) {
        bool found = false;
        for (final line in lines) {
          if (key == 'simkl' && line.startsWith(_simklPrefix)) {
            found = line.substring(_simklPrefix.length).trim() != _defaultValue;
          } else if (key == 'trakt' && line.startsWith(_traktPrefix)) {
            found = line.substring(_traktPrefix.length).trim() != _defaultValue;
          }
          if (found) {
            hasOptionalKey.add(key);
            break;
          }
        }
        if (!found) {
          missingOptional.add(key);
        }
      }

      if (hasOptionalKey.isNotEmpty) {
        missingOptional.clear();
      }

      return {
        'missingRequired': missingRequired,
        'missingOptional': missingOptional,
      };
    } catch (e, stackTrace) {
      developer.log(
        'Error checking API keys',
        name: 'ApiKeysService',
        error: e,
        stackTrace: stackTrace,
        level: 1000,
      );
      return {
        'missingRequired': _requiredKeys,
        'missingOptional': _optionalKeys,
      };
    }
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