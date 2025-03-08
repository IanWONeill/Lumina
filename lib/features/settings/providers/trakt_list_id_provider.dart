import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'trakt_list_id_provider.g.dart';

@riverpod
class TraktListId extends _$TraktListId {
  static const _key = 'trakt_list_id';

  @override
  Future<String?> build() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_key);
  }

  Future<void> setListId(String listId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, listId);
    state = AsyncData(listId);
  }
} 