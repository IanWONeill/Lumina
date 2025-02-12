import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../database/providers/database_provider.dart';
import '../../settings/providers/sort_settings_provider.dart';
import '../models/movie.dart';

part 'movies_provider.g.dart';

@riverpod
class Movies extends _$Movies {
  String _getNormalizedTitle(String title) {
    if (title.toLowerCase().startsWith('the ')) {
      return title.substring(4);
    }
    return title;
  }

  @override
  Future<List<Movie>> build() async {
    final sortField = ref.watch(sortFieldProvider);
    final sortAscending = ref.watch(sortAscendingProvider);
    
    final db = ref.watch(databaseServiceProvider);
    final orderBy = switch (sortField) {
      SortField.title => 'original_title',
      SortField.releaseDate => 'release_date',
      SortField.dateAdded => 'last_updated',
    };
    final orderDir = sortAscending ? 'ASC' : 'DESC';

    final movies = await db.getAllMovies();
    final sortedMovies = List<Map<String, dynamic>>.from(movies);
    
    sortedMovies.sort((a, b) {
      final aValue = a[orderBy];
      final bValue = b[orderBy];
      
      if (aValue == null || bValue == null) return 0;
      
      int comparison;
      if (orderBy == 'original_title' && aValue is String && bValue is String) {
        final normalizedA = _getNormalizedTitle(aValue);
        final normalizedB = _getNormalizedTitle(bValue);
        comparison = normalizedA.compareTo(normalizedB);
      } else if (aValue is String && bValue is String) {
        comparison = aValue.compareTo(bValue);
      } else if (aValue is num && bValue is num) {
        comparison = aValue.compareTo(bValue);
      } else {
        comparison = 0;
      }
      
      return sortAscending ? comparison : -comparison;
    });

    return sortedMovies.map((movie) => Movie.fromMap(movie)).toList();
  }

  Future<void> updateProgress(int tmdbId, int progress, int percentage) async {
    final db = ref.read(databaseServiceProvider);
    await db.updateMovieProgress(tmdbId, progress, percentage);
  }
}

@Riverpod(keepAlive: true)
Future<List<String>> movieGenres(MovieGenresRef ref, int movieId) async {
  final db = ref.watch(databaseServiceProvider);
  final genres = await db.getMovieGenres(movieId);
  return genres.map((g) => g['name'] as String).toList();
}

@Riverpod(keepAlive: true)
class SelectedMovie extends _$SelectedMovie {
  @override
  Movie? build() => null;

  void select(Movie movie) => state = movie;
}