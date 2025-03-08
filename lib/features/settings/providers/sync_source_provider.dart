import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'sync_source_provider.g.dart';

enum SyncSource {
  simkl,
  trakt,
}

@riverpod
class SyncSourcePreference extends _$SyncSourcePreference {
  static const _key = 'sync_source';

  @override
  Future<SyncSource> build() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey(_key)) {
      await prefs.setString(_key, SyncSource.simkl.name);
      return SyncSource.simkl;
    }
    
    final value = prefs.getString(_key);
    return value == SyncSource.trakt.name 
        ? SyncSource.trakt 
        : SyncSource.simkl;
  }

  Future<void> setSource(SyncSource source) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, source.name);
    state = AsyncData(source);
  }
} 