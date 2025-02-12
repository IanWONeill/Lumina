import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../database/providers/database_provider.dart';

part 'collection_provider.g.dart';

@riverpod
Future<Map<String, dynamic>?> collection(CollectionRef ref, int movieId) async {
  final db = ref.read(databaseServiceProvider);
  
  final collections = await db.getCollectionsForMovie(movieId);

  if (collections.isEmpty) return null;

  final collectionId = collections.first['collection_id'] as int;
  final collectionMovies = await db.getMoviesInCollection(collectionId);

  return {
    'collection': collections.first,
    'movies': collectionMovies.map((movie) => {
      'tmdb_id': movie['tmdb_id'],
      'original_title': movie['original_title'],
      'status': 'present',
    }).toList(),
  };
} 