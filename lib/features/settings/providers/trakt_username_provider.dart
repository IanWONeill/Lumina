import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'trakt_username_provider.g.dart';

@riverpod
class TraktUsername extends _$TraktUsername {
  static const _key = 'trakt_username';

  @override
  Future<String?> build() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_key);
  }

  Future<void> setUsername(String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, username);
    state = AsyncData(username);
  }
} 