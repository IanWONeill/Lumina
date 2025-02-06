import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/movie.dart';

part 'alphabet_navigation_provider.g.dart';

@riverpod
class AlphabetNavigation extends _$AlphabetNavigation {
  @override
  int? build() => null;

  void jumpToLetter(String letter, List<Movie> movies) {
    final index = movies.indexWhere(
      (movie) => movie.originalTitle.toUpperCase().startsWith(letter),
    );
    if (index != -1) {
      state = index;
    }
  }
} 