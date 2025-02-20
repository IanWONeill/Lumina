import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../database/providers/database_provider.dart';
import 'dart:developer' as developer;

part 'collection_provider.g.dart';

@riverpod
Future<List<Map<String, dynamic>>?> collection(CollectionRef ref, int movieId) async {
  final db = ref.read(databaseServiceProvider);
  
  final collections = await db.getCollectionsForMovie(movieId);

  if (collections.isEmpty) return null;

  final collectionsWithMovies = await Future.wait(
    collections.map((collection) async {
      final movies = await db.getMoviesInCollection(collection['collection_id'] as int);
      
      return {
        'collection': collection,
        'movies': movies.map((movie) => {
          'tmdb_id': movie['tmdb_id'],
          'imdb_id': movie['imdb_id'],
          'original_title': movie['original_title'],
          'status': movie['status'],
          'release_date': movie['release_date'],
        }).toList(),
      };
    }),
  );

  developer.log(
    'Fetched collections with movies',
    name: 'CollectionProvider',
    error: {
      'movieId': movieId,
      'collectionsCount': collectionsWithMovies.length,
      'collections': collectionsWithMovies.map((c) {
        final collection = c['collection'] as Map<String, dynamic>;
        final movies = c['movies'] as List<dynamic>;
        return {
          'name': collection['name'],
          'source': collection['source'],
          'movieCount': movies.length,
        };
      }).toList(),
    },
  );

  return collectionsWithMovies;
} 