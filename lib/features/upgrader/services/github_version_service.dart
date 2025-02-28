import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import '../models/version_info.dart';

class GithubVersionService {
  static const String versionUrl = 'https://raw.githubusercontent.com/Spark-NV/lumina/refs/heads/main/version.json';

  Future<VersionInfo> getLatestVersion() async {
    try {
      final response = await http.get(Uri.parse(versionUrl));
      if (response.statusCode == 200) {
        return VersionInfo.fromJson(jsonDecode(response.body));
      }
      throw Exception('Failed to fetch version info');
    } catch (e) {
      throw Exception('Error checking for updates: $e');
    }
  }

  Future<bool> isUpdateAvailable() async {
    try {
      final currentVersion = await PackageInfo.fromPlatform();
      final latestVersion = await getLatestVersion();
      
      return _compareVersions(currentVersion.version, latestVersion.version);
    } catch (e) {
      return false;
    }
  }

  bool _compareVersions(String currentVersion, String latestVersion) {
    List<int> current = currentVersion.split('.').map(int.parse).toList();
    List<int> latest = latestVersion.split('.').map(int.parse).toList();

    for (int i = 0; i < 3; i++) {
      if (latest[i] > current[i]) return true;
      if (latest[i] < current[i]) return false;
    }
    return false;
  }
} 