import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../settings/providers/sync_list_preference_provider.dart';

class SimklSyncService {
  final String _token;
  final String _clientId;
  final Ref _ref;
  static const String _baseUrl = 'https://api.simkl.com';

  SimklSyncService(this._token, this._clientId, this._ref);

  Future<List<Map<String, dynamic>>> getCompletedMovies() async {
    final listType = await _ref.read(simklListPreferenceProvider.future);
    final listEndpoint = listType == SimklListType.completed 
        ? 'completed' 
        : 'plantowatch';
    
    developer.log(
      'Fetching SIMKL movies',
      name: 'SimklSyncService',
      error: {'endpoint': listEndpoint},
    );

    final response = await http.get(
      Uri.parse('$_baseUrl/sync/all-items/movies/$listEndpoint'),
      headers: {
        'Authorization': 'Bearer $_token',
        'simkl-api-key': _clientId,
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      
      if (data is Map && data.containsKey('movies')) {
        final movies = data['movies'] as List;
        final processedMovies = movies.map((movie) {
          final movieData = movie['movie'] as Map<String, dynamic>;
          final ids = movieData['ids'] as Map<String, dynamic>;
          
          return {
            'tmdb_id': int.tryParse(ids['tmdb'] ?? ''),
            'imdb_id': ids['imdb'],
            'title': movieData['title'],
            'year': movieData['year'],
            'last_watched_at': movie['last_watched_at'],
          };
        }).where((movie) => movie['tmdb_id'] != null).toList();

        developer.log(
          'Processed SIMKL movies',
          name: 'SimklSyncService',
          error: {'movieCount': processedMovies.length},
        );

        return processedMovies;
      } else {
        developer.log(
          'Unexpected SIMKL response format',
          name: 'SimklSyncService',
          error: {'data': data},
          level: 1000,
        );
        throw Exception('Unexpected response format');
      }
    } else {
      developer.log(
        'Failed to fetch SIMKL movies',
        name: 'SimklSyncService',
        error: {
          'statusCode': response.statusCode,
          'body': response.body,
        },
        level: 1000,
      );
      throw Exception('Failed to fetch completed movies');
    }
  }

  Future<List<Map<String, dynamic>>> getCompletedTVShows() async {
    final listType = await _ref.read(simklListPreferenceProvider.future);
    final listEndpoint = listType == SimklListType.completed 
        ? 'completed' 
        : 'plantowatch';

    developer.log(
      'Fetching SIMKL TV shows',
      name: 'SimklSyncService',
      error: {'endpoint': listEndpoint},
    );

    final response = await http.get(
      Uri.parse('$_baseUrl/sync/all-items/shows/$listEndpoint'),
      headers: {
        'Authorization': 'Bearer $_token',
        'simkl-api-key': _clientId,
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      final shows = data['shows'].where((show) => 
        show['show']['ids']['tmdb'] != null
      ).map((show) => {
        'tmdb_id': int.parse(show['show']['ids']['tmdb']),
        'imdb_id': show['show']['ids']['imdb'],
        'title': show['show']['title'],
        'year': show['show']['year'],
        'last_watched_at': show['last_watched_at'],
        'total_episodes': show['total_episodes_count'],
        'watched_episodes': show['watched_episodes_count'],
      }).toList();

      developer.log(
        'Processed SIMKL TV shows',
        name: 'SimklSyncService',
        error: {'showCount': shows.length},
      );

      return List<Map<String, dynamic>>.from(shows);
    } else {
      developer.log(
        'Failed to fetch SIMKL TV shows',
        name: 'SimklSyncService',
        error: {
          'statusCode': response.statusCode,
          'body': response.body,
        },
        level: 1000,
      );
      throw Exception('Failed to fetch TV shows from SIMKL');
    }
  }
} 