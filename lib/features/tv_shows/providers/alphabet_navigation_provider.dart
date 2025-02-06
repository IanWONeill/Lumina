import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/tv_show.dart';

part 'alphabet_navigation_provider.g.dart';

@riverpod
class AlphabetNavigation extends _$AlphabetNavigation {
  @override
  int? build() => null;

  void jumpToLetter(String letter, List<TVShow> shows) {
    final index = shows.indexWhere(
      (show) => show.originalName.toUpperCase().startsWith(letter),
    );
    if (index != -1) {
      state = index;
    }
  }
} 