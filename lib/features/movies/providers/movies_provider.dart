import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/movie.dart';
import '../../database/providers/database_provider.dart';

part 'movies_provider.g.dart';

@Riverpod(keepAlive: true)
class Movies extends _$Movies {
  @override
  Future<List<Movie>> build() async {
    final db = ref.watch(databaseServiceProvider);
    final movies = await db.getAllMovies();
    return movies.map((map) => Movie.fromMap(map)).toList();
  }

  Future<void> updateProgress(int tmdbId, int progress, int percentage) async {
    final db = ref.read(databaseServiceProvider);
    await db.updateMovieProgress(tmdbId, progress, percentage);
  }
}

@Riverpod(keepAlive: true)
class SelectedMovie extends _$SelectedMovie {
  @override
  Movie? build() => null;

  void select(Movie movie) => state = movie;
} 