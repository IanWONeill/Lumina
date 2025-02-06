import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'sync_list_preference_provider.g.dart';

enum SimklListType {
  completed,
  planToWatch,
}

@riverpod
class SimklListPreference extends _$SimklListPreference {
  static const _key = 'simkl_list_type';

  @override
  Future<SimklListType> build() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey(_key)) {
      await prefs.setString(_key, SimklListType.planToWatch.name);
      return SimklListType.planToWatch;
    }
    
    final value = prefs.getString(_key);
    return value == SimklListType.completed.name 
        ? SimklListType.completed 
        : SimklListType.planToWatch;
  }

  Future<void> setListType(SimklListType type) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, type.name);
    state = AsyncData(type);
  }
} 