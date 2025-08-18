import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'stream_providers_settings_provider.g.dart';

@Riverpod(keepAlive: true)
class OrionoidEnabledProvider extends _$OrionoidEnabledProvider {
  static const _key = 'orionoid_enabled';

  @override
  Future<bool> build() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key) ?? false;
  }

  Future<void> toggle() async {
    final prefs = await SharedPreferences.getInstance();
    final newValue = !(await future);
    await prefs.setBool(_key, newValue);
    state = AsyncValue.data(newValue);
  }
}

@Riverpod(keepAlive: true)
class TorrentioEnabledProvider extends _$TorrentioEnabledProvider {
  static const _key = 'torrentio_enabled';

  @override
  Future<bool> build() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key) ?? true;
  }

  Future<void> toggle() async {
    final prefs = await SharedPreferences.getInstance();
    final newValue = !(await future);
    await prefs.setBool(_key, newValue);
    state = AsyncValue.data(newValue);
  }
}

@Riverpod(keepAlive: true)
class AioStreamsEnabledProvider extends _$AioStreamsEnabledProvider {
  static const _key = 'aio_streams_enabled';

  @override
  Future<bool> build() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key) ?? false;
  }

  Future<void> toggle() async {
    final prefs = await SharedPreferences.getInstance();
    final newValue = !(await future);
    await prefs.setBool(_key, newValue);
    state = AsyncValue.data(newValue);
  }
} 