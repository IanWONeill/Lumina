import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/tv_show.dart';

part 'alphabet_navigation_provider.g.dart';

@riverpod
class AlphabetNavigation extends _$AlphabetNavigation {
  String _getNormalizedTitle(String title) {
    if (title.toLowerCase().startsWith('the ')) {
      return title.substring(4);
    }
    return title;
  }

  @override
  int? build() => null;

  void jumpToLetter(String letter, List<TVShow> shows) {
    final index = shows.indexWhere(
      (show) => _getNormalizedTitle(show.originalName).toUpperCase().startsWith(letter),
    );
    if (index != -1) {
      state = index;
    }
  }
} 