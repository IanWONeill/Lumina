import 'dart:developer' as developer;
import 'package:debrid_player/features/settings/services/api_keys_service.dart';
import 'package:debrid_player/features/sync/services/database_service.dart';
import 'package:debrid_player/features/sync/services/tmdb_service.dart';
import 'package:debrid_player/features/sync/services/tvdb_service.dart';

class MetadataProviderService {
  late TMDBService _tmdbService;
  TVDBService? _tvdbService;
  final DatabaseService _databaseService;
  
  MetadataProviderService(this._databaseService);
  
  Future<void> initialize() async {
    final apiKeys = await ApiKeysService.readApiKeys();
    
    final tmdbApiKey = apiKeys['tmdb'];
    if (tmdbApiKey == null || tmdbApiKey.isEmpty) {
      developer.log(
        'TMDB API key not found',
        name: 'MetadataProviderService',
        level: 1000,
      );
      throw Exception('TMDB API key not found');
    }
    
    _tmdbService = TMDBService(tmdbApiKey, _databaseService, null);
    
    final tvdbApiKey = apiKeys['tvdb'];
    if (tvdbApiKey != null && tvdbApiKey.isNotEmpty) {
      _tvdbService = TVDBService(tvdbApiKey, _databaseService);
      try {
        await _tvdbService!.authenticate();
        developer.log(
          'TVDB service initialized successfully',
          name: 'MetadataProviderService',
        );
      } catch (e, st) {
        developer.log(
          'Failed to initialize TVDB service',
          name: 'MetadataProviderService',
          error: e.toString(),
          stackTrace: st,
          level: 900,
        );
        _tvdbService = null;
      }
    } else {
      developer.log(
        'TVDB API key not found, TVDB service will not be available',
        name: 'MetadataProviderService',
        level: 900,
      );
    }
  }
  
  bool isAnime(List<String> genres) {
    return genres.any((genre) => 
      genre.toLowerCase() == 'anime' || 
      genre.toLowerCase() == 'animation' && genres.any((g) => g.toLowerCase() == 'japanese')
    );
  }
  
  Future<Map<String, dynamic>> getTVShowDetails({
    required int? tmdbId, 
    required int? tvdbId,
    required List<String> genres,
  }) async {
    final isAnimeShow = isAnime(genres);
    final usesTvdb = isAnimeShow && _tvdbService != null && tvdbId != null;
    
    developer.log(
      'Fetching TV show details',
      name: 'MetadataProviderService',
      error: {
        'tmdbId': tmdbId,
        'tvdbId': tvdbId,
        'isAnime': isAnimeShow,
        'usingTVDB': usesTvdb,
      },
    );
    
    try {
      if (isAnimeShow) {
        if (usesTvdb) {
          final showData = await _tvdbService!.fetchTVShowDetails(tvdbId);
          
          if (showData['tmdb_id'] == null && tmdbId != null) {
            showData['tmdb_id'] = tmdbId;
          }
          
          return showData;
        } else {
          throw Exception('TVDB service not available for anime show');
        }
      } else if (tmdbId != null) {
        return await _tmdbService.fetchTVShowDetails(tmdbId);
      } else {
        throw Exception('No valid ID provided for TV show');
      }
    } catch (e, st) {
      developer.log(
        'Error fetching TV show details',
        name: 'MetadataProviderService',
        error: {
          'tmdbId': tmdbId,
          'tvdbId': tvdbId,
          'isAnime': isAnimeShow,
          'error': e.toString(),
        },
        stackTrace: st,
        level: 1000,
      );
      rethrow;
    }
  }
  
  Future<Map<String, dynamic>> getSeasonDetails({
    required int? tmdbId,
    required int? tvdbId,
    required int seasonNumber,
    required List<String> genres,
  }) async {
    final isAnimeShow = isAnime(genres);
    final usesTvdb = isAnimeShow && _tvdbService != null && tvdbId != null;
    
    developer.log(
      'Fetching season details',
      name: 'MetadataProviderService',
      error: {
        'tmdbId': tmdbId,
        'tvdbId': tvdbId,
        'seasonNumber': seasonNumber,
        'isAnime': isAnimeShow,
        'usingTVDB': usesTvdb,
      },
    );
    
    try {
      if (isAnimeShow) {
        if (usesTvdb) {
          return await _tvdbService!.getSeasonDetails(tvdbId, seasonNumber);
        } else {
          throw Exception('TVDB service not available for anime show season');
        }
      } else if (tmdbId != null) {
        return await _tmdbService.getSeasonDetails(tmdbId, seasonNumber);
      } else {
        throw Exception('No valid ID provided for season');
      }
    } catch (e, st) {
      developer.log(
        'Error fetching season details',
        name: 'MetadataProviderService',
        error: {
          'tmdbId': tmdbId,
          'tvdbId': tvdbId,
          'seasonNumber': seasonNumber,
          'isAnime': isAnimeShow,
          'error': e.toString(),
        },
        stackTrace: st,
        level: 1000,
      );
      rethrow;
    }
  }
  
  void dispose() {
    if (_tvdbService != null) {
      _tvdbService!.dispose();
    }
  }
} 