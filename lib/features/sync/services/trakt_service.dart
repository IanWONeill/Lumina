import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../settings/providers/trakt_list_id_provider.dart';
import '../../settings/providers/trakt_username_provider.dart';

class TraktSyncService {
  final String _clientId;
  final Ref _ref;
  static const String _baseUrl = 'https://api.trakt.tv';
  
  List<Map<String, dynamic>>? _cachedItems;

  TraktSyncService(this._clientId, this._ref);

  Future<List<Map<String, dynamic>>> fetchAllItems() async {
    if (_cachedItems != null) {
      return _cachedItems!;
    }
    
    final listId = await _ref.read(traktListIdProvider.future);
    final username = await _ref.read(traktUsernameProvider.future);
    
    if (listId == null || listId.isEmpty) {
      developer.log(
        'No Trakt list ID provided',
        name: 'TraktSyncService',
        level: 1000,
      );
      throw Exception('No Trakt list ID provided');
    }
    
    if (username == null || username.isEmpty) {
      developer.log(
        'No Trakt username provided',
        name: 'TraktSyncService',
        level: 1000,
      );
      throw Exception('No Trakt username provided');
    }
    
    developer.log(
      'Fetching Trakt items',
      name: 'TraktSyncService',
      error: {'username': username, 'listId': listId},
    );

    final response = await http.get(
      Uri.parse('$_baseUrl/users/$username/lists/$listId/items?extended=full'),
      headers: {
        'Content-Type': 'application/json',
        'trakt-api-version': '2',
        'trakt-api-key': _clientId,
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      
      _cachedItems = List<Map<String, dynamic>>.from(data.map((item) {
        final type = item['type'];
        final mediaItem = item[type] as Map<String, dynamic>;
        final ids = mediaItem['ids'] as Map<String, dynamic>;
        
        final baseItem = {
          'tmdb_id': ids['tmdb'],
          'imdb_id': ids['imdb'],
          'tvdb_id': ids['tvdb'],
          'title': mediaItem['title'],
          'year': mediaItem['year'],
          'type': type,
          'show': type == 'show' ? mediaItem : null,
        };
        
        if (type == 'show') {
          final genres = (mediaItem['genres'] as List<dynamic>?) ?? [];
          baseItem['total_episodes'] = mediaItem['aired_episodes'] ?? 0;
          baseItem['is_anime'] = genres.contains('anime') ? 1 : 0;
        }
        
        return baseItem;
      }).where((item) => item['tmdb_id'] != null).toList());
      
      developer.log(
        'Processed Trakt items',
        name: 'TraktSyncService',
        error: {
          'totalCount': _cachedItems!.length,
          'movieCount': _cachedItems!.where((item) => item['type'] == 'movie').length,
          'showCount': _cachedItems!.where((item) => item['type'] == 'show').length,
        },
      );

      return _cachedItems!;
    } else {
      developer.log(
        'Failed to fetch Trakt items',
        name: 'TraktSyncService',
        error: {
          'statusCode': response.statusCode,
          'body': response.body,
        },
        level: 1000,
      );
      throw Exception('Failed to fetch items from Trakt');
    }
  }

  Future<List<Map<String, dynamic>>> getCompletedMovies() async {
    final items = await fetchAllItems();
    
    final movies = items
        .where((item) => item['type'] == 'movie')
        .map((item) => {
          'tmdb_id': item['tmdb_id'],
          'imdb_id': item['imdb_id'],
          'tvdb_id': item['tvdb_id'],
          'title': item['title'],
          'year': item['year'],
        })
        .toList();
    
    developer.log(
      'Filtered Trakt movies',
      name: 'TraktSyncService',
      error: {'movieCount': movies.length},
    );
    
    return movies;
  }

  Future<List<Map<String, dynamic>>> getCompletedTVShows() async {
    final items = await fetchAllItems();
    
    final shows = items
        .where((item) => item['type'] == 'show')
        .map((item) => {
          'tmdb_id': item['tmdb_id'],
          'imdb_id': item['imdb_id'],
          'tvdb_id': item['tvdb_id'],
          'title': item['title'],
          'year': item['year'],
          'total_episodes': item['total_episodes'],
          'is_anime': item['is_anime'],
          'show': item['show'],
        })
        .toList();
    
    developer.log(
      'TV Shows with overview',
      name: 'TraktSyncService',
      error: {
        'showCount': shows.length,
        'showsWithOverview': shows.where((show) => show['show'] != null && show['show']['overview'] != null).length,
        'firstShowOverview': shows.isNotEmpty ? (shows.first['show'] != null ? shows.first['show']['overview'] : null) : null,
      },
    );
    
    developer.log(
      'TV Shows with IMDB IDs',
      name: 'TraktSyncService',
      error: {
        'showCount': shows.length,
        'showsWithImdbIds': shows.where((show) => show['imdb_id'] != null).length,
        'firstShowImdbId': shows.isNotEmpty ? shows.first['imdb_id'] : null,
      },
    );
    
    developer.log(
      'Filtered Trakt TV shows',
      name: 'TraktSyncService',
      error: {
        'showCount': shows.length,
        'animeCount': shows.where((show) => show['is_anime'] == 1).length,
      },
    );
    
    return shows;
  }
  
  void clearCache() {
    _cachedItems = null;
  }
} 