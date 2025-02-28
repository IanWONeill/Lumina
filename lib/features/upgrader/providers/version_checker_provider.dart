import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/version_info.dart';
import '../services/github_version_service.dart';

part 'version_checker_provider.g.dart';

@riverpod
class VersionChecker extends _$VersionChecker {
  final _service = GithubVersionService();

  @override
  Future<VersionInfo?> build() async {
    if (await _service.isUpdateAvailable()) {
      return _service.getLatestVersion();
    }
    return null;
  }
} 