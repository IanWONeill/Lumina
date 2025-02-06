import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/movie.dart';
import '../../sync/services/database_service.dart';

part 'movie_details_provider.g.dart';

@riverpod
Future<Movie> movieDetails(MovieDetailsRef ref, int tmdbId) async {
  final db = DatabaseService();
  final movieData = await db.getMovie(tmdbId);
  if (movieData == null) {
    throw Exception('Movie not found');
  }
  return Movie.fromMap(movieData);
} 