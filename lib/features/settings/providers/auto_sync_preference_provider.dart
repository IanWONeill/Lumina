import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'auto_sync_preference_provider.g.dart';

@riverpod
class AutoSyncPreference extends _$AutoSyncPreference {
  static const _enabledKey = 'auto_sync_enabled';
  static const _timeKey = 'auto_sync_time';

  @override
  Future<({bool enabled, String? time})> build() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(_enabledKey) ?? false;
    final time = prefs.getString(_timeKey);
    return (enabled: enabled, time: time);
  }

  Future<void> setEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, enabled);
    state = AsyncData((enabled: enabled, time: state.value?.time));
  }

  Future<void> setTime(String time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_timeKey, time);
    state = AsyncData((enabled: state.value?.enabled ?? false, time: time));
  }
} 