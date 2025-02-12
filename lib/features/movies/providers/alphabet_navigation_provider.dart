import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/movie.dart';

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

  void jumpToLetter(String letter, List<Movie> movies) {
    final index = movies.indexWhere(
      (movie) => _getNormalizedTitle(movie.originalTitle).toUpperCase().startsWith(letter),
    );
    if (index != -1) {
      state = index;
    }
  }
} 