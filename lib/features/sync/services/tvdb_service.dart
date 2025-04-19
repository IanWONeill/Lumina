import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:debrid_player/features/sync/services/database_service.dart';

class TVDBService {
  final String _apiKey;
  final DatabaseService _databaseService;
  String? _authToken;
  
  static const String _baseUrl = 'https://api4.thetvdb.com/v4';
  static const String _imageBaseUrl = 'https://artworks.thetvdb.com';

  TVDBService(this._apiKey, this._databaseService);

  Map<String, String> get _headers {
    if (_authToken == null) {
      throw Exception('Not authenticated with TVDB. Call authenticate() first.');
    }
    
    return {
      'Authorization': 'Bearer $_authToken',
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
  }

  Future<String> authenticate() async {
    developer.log('Authenticating with TVDB', name: 'TVDBService');
    
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/login'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'apikey': _apiKey}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['status'] == 'success' && 
            data['data'] != null && 
            data['data']['token'] != null) {
          _authToken = data['data']['token'];
          return _authToken!;
        }
        throw Exception('Invalid TVDB authentication response format');
      }
      throw Exception('TVDB authentication failed: ${response.statusCode}');
    } catch (e, st) {
      developer.log(
        'TVDB authentication error',
        name: 'TVDBService',
        error: e.toString(),
        stackTrace: st,
        level: 1000,
      );
      rethrow;
    }
  }

  Future<bool> _imageExists(String type, String id, String imageType) async {
    final metadataDir = Directory('/storage/emulated/0/Debrid_Player/metadata/$type/$id');
    final fileName = type == 'actors' 
        ? '$id.webp'
        : type.contains('backdrop') 
            ? 'backdrop.webp' 
            : 'poster.webp';
            
    final file = File('${metadataDir.path}/$fileName');
    return file.exists();
  }

  Future<String?> downloadImage(String path, String type, String id, [String imageType = 'poster']) async {
    return _downloadImage(path, type, id, imageType);
  }

  Future<String?> _downloadImage(String path, String type, String id, String imageType) async {
    final url = path.startsWith('http') ? path : '$_imageBaseUrl$path';
    
    try {
      if (await _imageExists(type, id, imageType)) {
        developer.log(
          'Image already exists, skipping download',
          name: 'TVDBService',
          error: {
            'type': type,
            'id': id,
            'imageType': imageType,
          },
        );
        
        final metadataDir = Directory('/storage/emulated/0/Debrid_Player/metadata/$type/$id');
        final fileName = type == 'actors' 
            ? '$id.webp'
            : type.contains('backdrop') 
                ? 'backdrop.webp' 
                : 'poster.webp';
        return '${metadataDir.path}/$fileName';
      }
      
      developer.log(
        'Downloading TVDB image',
        name: 'TVDBService',
        error: {'url': url, 'type': type, 'id': id},
      );
      
      final response = await http.get(
        Uri.parse(url),
        headers: _authToken != null 
            ? {'Authorization': 'Bearer $_authToken'} 
            : null,
      );
      
      if (response.statusCode == 200) {
        final metadataDir = Directory('/storage/emulated/0/Debrid_Player/metadata/$type/$id');
        await metadataDir.create(recursive: true);
        
        final fileName = type == 'actors' 
            ? '$id.webp'
            : type.contains('backdrop') 
                ? 'backdrop.webp' 
                : 'poster.webp';
            
        final file = File('${metadataDir.path}/$fileName');
        
        final compressedImage = await FlutterImageCompress.compressWithList(
          response.bodyBytes,
          format: CompressFormat.webp,
          quality: 75,
        );

        await file.writeAsBytes(compressedImage);
        
        developer.log(
          'TVDB image processed',
          name: 'TVDBService',
          error: {
            'path': file.path,
            'originalSize': response.bodyBytes.length,
            'compressedSize': compressedImage.length,
          },
        );
        
        return file.path;
      }
      
      throw Exception('Failed to download TVDB image: ${response.statusCode}');
    } catch (e, st) {
      developer.log(
        'TVDB image error',
        name: 'TVDBService',
        error: {'url': url, 'error': e.toString()},
        stackTrace: st,
        level: 1000,
      );
      return null;
    }
  }

  Future<Map<String, dynamic>> getAnimeDetails(int tvdbId, int tmdbId) async {
    if (_authToken == null) {
      await authenticate();
    }
    
    developer.log(
      'Fetching anime details',
      name: 'TVDBService',
      error: {'tvdbId': tvdbId, 'tmdbId': tmdbId},
    );
    
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/series/$tvdbId/episodes/default/eng'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        developer.log(
          'TVDB API Response',
          name: 'TVDBService',
          error: {
            'data_structure': data.keys.toList(),
            'has_data': data['data'] != null,
            'raw_response': response.body.substring(0, 500),
          },
        );
        
        if (data['status'] != 'success' || data['data'] == null) {
          throw Exception('Invalid TVDB response format');
        }

        developer.log(
          'TVDB Data Structure',
          name: 'TVDBService',
          error: {
            'data_keys': data['data'].keys.toList(),
            'has_series': data['data']['series'] != null,
            'has_episodes': data['data']['episodes'] != null,
          },
        );

        final seriesData = data['data'];
        final episodes = data['data']['episodes'] as List;

        final Map<int, List<Map<String, dynamic>>> seasonEpisodes = {};
        for (final episode in episodes) {
          final seasonNum = episode['seasonNumber'] as int;
          seasonEpisodes.putIfAbsent(seasonNum, () => []);
          seasonEpisodes[seasonNum]!.add({
            'id': tmdbId,
            'episode_number': episode['number'],
            'name': episode['name'] ?? '',
            'overview': episode['overview'] ?? '',
            'still_path': episode['image'],
            'air_date': episode['aired'],
            'runtime': episode['runtime'],
            'season_number': seasonNum,
            'tvdb_id': episode['id'],
            'tmdb_id': tmdbId,
            'show_id': tmdbId,
          });
        }

        final List<Map<String, dynamic>> seasons = [];
        seasonEpisodes.forEach((seasonNum, episodes) {
          seasons.add({
            'id': tmdbId,
            'season_number': seasonNum,
            'name': 'Season $seasonNum',
            'overview': '',
            'air_date': episodes.first['air_date'],
            'episodes': episodes,
            'tmdb_id': tmdbId,
            'show_id': tmdbId,
            'poster_path': null,
          });
        });

        developer.log(
          'Checking season and episode IDs',
          name: 'TVDBService',
          error: {
            'first_season_tmdb_id': seasons.first['tmdb_id'],
            'first_episode_tmdb_id': seasons.first['episodes'].first['tmdb_id'],
            'show_tmdb_id': tmdbId,
          },
        );

        final List<Map<String, dynamic>> processedSeasons = [];
        for (final season in seasons) {
          final List<Map<String, dynamic>> processedEpisodes = [];
          for (final episode in season['episodes']) {
            processedEpisodes.add({
              ...episode,
              'tmdb_id': tmdbId,
              'show_id': tmdbId,
            });
          }
          processedSeasons.add({
            ...season,
            'tmdb_id': tmdbId,
            'show_id': tmdbId,
            'episodes': processedEpisodes,
          });
        }

        final showData = {
          'tvdb_id': tvdbId,
          'tmdb_id': tmdbId,
          'overview': '',
          'first_air_date': seriesData['firstAired'],
          'last_air_date': seriesData['lastAired'],
          'number_of_episodes': episodes.length,
          'total_episodes_count': episodes.length,
          'number_of_seasons': seasons.length,
          'status': seriesData['status']['name'],
          'average_runtime': seriesData['averageRuntime'],
          'original_language': seriesData['originalLanguage'],
          'original_country': seriesData['originalCountry'],
          'is_anime': 1,
          'seasons': processedSeasons,
          'poster_path': seriesData['image'],
          'last_updated': DateTime.now().toIso8601String(),
          'cast': [
            {
              'id': 1,
              'name': 'N/A',
              'profile_path': null,
            }
          ],
        };

        developer.log(
          'Final data structure check',
          name: 'TVDBService',
          error: {
            'show_tmdb_id': showData['tmdb_id'],
            'first_season_tmdb_id': showData['seasons'].first['tmdb_id'],
            'first_episode_tmdb_id': showData['seasons'].first['episodes'].first['tmdb_id'],
          },
        );

        if (seriesData['image'] != null) {
          developer.log(
            'Processing anime image',
            name: 'TVDBService',
            error: {
              'tvdbId': tvdbId,
              'tmdbId': tmdbId,
              'imagePath': seriesData['image'],
            },
          );
          
          await _downloadImage(
            seriesData['image'],
            'tv/posters',
            tmdbId.toString(),
            'poster',
          );
        }

        developer.log(
          'Anime details processed',
          name: 'TVDBService',
          error: {
            'tvdbId': tvdbId,
            'name': seriesData['name'],
            'seasonCount': seasons.length,
            'episodeCount': episodes.length,
          },
        );

        return showData;
      }
      
      throw Exception('Failed to fetch anime details: ${response.statusCode}');
    } catch (e, st) {
      developer.log(
        'Anime details error',
        name: 'TVDBService',
        error: {'tvdbId': tvdbId, 'error': e.toString()},
        stackTrace: st,
        level: 1000,
      );
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getEpisodeCount(int tvdbId) async {
    if (_authToken == null) {
      await authenticate();
    }
    
    developer.log(
      'Fetching episode count',
      name: 'TVDBService',
      error: {'tvdbId': tvdbId},
    );
    
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/series/$tvdbId/episodes/default/eng'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['status'] != 'success' || data['data'] == null) {
          throw Exception('Invalid TVDB response format');
        }

        final episodes = data['data']['episodes'] as List;
        
        return {
          'number_of_episodes': episodes.length,
        };
      }
      
      throw Exception('Failed to fetch episode count: ${response.statusCode}');
    } catch (e, st) {
      developer.log(
        'Episode count error',
        name: 'TVDBService',
        error: {'tvdbId': tvdbId, 'error': e.toString()},
        stackTrace: st,
        level: 1000,
      );
      rethrow;
    }
  }

  void dispose() {
    _authToken = null;
  }
} 