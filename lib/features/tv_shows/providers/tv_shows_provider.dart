import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'dart:developer' as developer;
import '../models/tv_show.dart';
import '../../sync/services/database_service.dart';
import '../../sync/services/tmdb_service.dart';
import '../../sync/services/tvdb_service.dart';
import '../../settings/services/api_keys_service.dart';

part 'tv_shows_provider.g.dart';

@Riverpod(keepAlive: true)
class TVShows extends _$TVShows {
  late final DatabaseService _dbService;
  late final TMDBService _tmdbService;
  late final TVDBService? _tvdbService;

  @override
  Future<List<TVShow>> build() async {
    _dbService = DatabaseService();
    final apiKeys = await ApiKeysService.readApiKeys();
    
    if (apiKeys['tmdb'] == null) {
      throw Exception('TMDB API key not found');
    }
    
    _tmdbService = TMDBService(apiKeys['tmdb']!, _dbService, null);
    
    if (apiKeys['tvdb'] != null) {
      _tvdbService = TVDBService(apiKeys['tvdb']!, _dbService);
      try {
        await _tvdbService!.authenticate();
      } catch (e) {
        developer.log(
          'Failed to initialize TVDB service',
          name: 'TVShowsProvider',
          error: e.toString(),
          level: 900,
        );
        _tvdbService = null;
      }
    }

    final shows = await _dbService.getAllTVShows();
    return shows.map((map) => TVShow.fromMap(map)).toList();
  }

  Future<void> addTVShow(Map<String, dynamic> showData) async {
    await _dbService.insertTVShow(showData);
    ref.invalidateSelf();
  }

  Future<void> updateTVShow(int id, Map<String, dynamic> data) async {
    await _dbService.updateTVShowDetails(data);
    ref.invalidateSelf();
  }

  Future<int> updateEpisodeMetadata(int showId) async {
    try {
      final show = await _dbService.getTVShowDetails(showId);
      if (show == null) {
        throw Exception('Show not found');
      }

      developer.log(
        'Retrieved show details',
        name: 'TVShowsProvider',
        error: {
          'showId': showId,
          'showData': show,
        },
      );

      final isAnime = show['is_anime'] == 1;
      final tvdbId = show['tvdb_id'];
      int updatedCount = 0;
      
      developer.log(
        'Starting episode metadata update',
        name: 'TVShowsProvider',
        error: {
          'showId': showId,
          'isAnime': isAnime,
          'tvdbId': tvdbId,
          'showName': show['name'],
          'numberOfSeasons': show['number_of_seasons'],
        },
      );

      if (isAnime && tvdbId != null && _tvdbService != null) {
        final animeDetails = await _tvdbService!.getAnimeDetails(tvdbId, showId);
        final seasons = animeDetails['seasons'] as List;
        
        developer.log(
          'Retrieved anime details',
          name: 'TVShowsProvider',
          error: {
            'showId': showId,
            'seasonCount': seasons.length,
          },
        );
        
        for (final season in seasons) {
          final seasonNumber = season['season_number'] as int;
          final episodes = season['episodes'] as List;
          
          final dbSeasons = await _dbService.getSeasonsForShow(showId);
          final dbSeason = dbSeasons.firstWhere(
            (s) => s['season_number'] == seasonNumber,
            orElse: () => throw Exception('Season $seasonNumber not found in database'),
          );
          final seasonId = dbSeason['id'] as int;
          
          developer.log(
            'Processing anime season',
            name: 'TVShowsProvider',
            error: {
              'showId': showId,
              'seasonNumber': seasonNumber,
              'episodeCount': episodes.length,
              'seasonId': seasonId,
            },
          );
          
          final existingEpisodes = await _dbService.getEpisodesForSeason(seasonId);
          final existingEpisodeMap = {
            for (var ep in existingEpisodes)
              ep['episode_number'] as int: ep
          };
          
          developer.log(
            'Retrieved existing anime episodes',
            name: 'TVShowsProvider',
            error: {
              'showId': showId,
              'seasonNumber': seasonNumber,
              'existingEpisodeCount': existingEpisodeMap.length,
            },
          );
          
          for (final episode in episodes) {
            final episodeNumber = episode['episode_number'] as int;
            final existingEpisode = existingEpisodeMap[episodeNumber];
            
            if (existingEpisode != null) {
              if (existingEpisode['name'] != episode['name'] ||
                  existingEpisode['overview'] != episode['overview']) {
                developer.log(
                  'Updating anime episode metadata',
                  name: 'TVShowsProvider',
                  error: {
                    'showId': showId,
                    'seasonNumber': seasonNumber,
                    'episodeNumber': episodeNumber,
                    'oldName': existingEpisode['name'],
                    'newName': episode['name'],
                    'hasOverviewChange': existingEpisode['overview'] != episode['overview'],
                  },
                );
                
                await _dbService.updateEpisodeMetadata(
                  existingEpisode['id'],
                  episode['name'],
                  episode['overview'],
                );
                updatedCount++;
              } else {
                developer.log(
                  'No changes needed for anime episode',
                  name: 'TVShowsProvider',
                  error: {
                    'showId': showId,
                    'seasonNumber': seasonNumber,
                    'episodeNumber': episodeNumber,
                  },
                );
              }
            } else {
              developer.log(
                'No existing anime episode found',
                name: 'TVShowsProvider',
                error: {
                  'showId': showId,
                  'seasonNumber': seasonNumber,
                  'episodeNumber': episodeNumber,
                },
              );
            }
          }
        }
      } else {
        final numberOfSeasons = show['number_of_seasons'] as int;
        
        developer.log(
          'Processing regular show seasons',
          name: 'TVShowsProvider',
          error: {
            'showId': showId,
            'numberOfSeasons': numberOfSeasons,
          },
        );
        
        for (var seasonNum = 1; seasonNum <= numberOfSeasons; seasonNum++) {
          final seasonDetails = await _tmdbService.getSeasonDetails(showId, seasonNum);
          final episodes = seasonDetails['episodes'] as List;
          
          final dbSeasons = await _dbService.getSeasonsForShow(showId);
          final dbSeason = dbSeasons.firstWhere(
            (s) => s['season_number'] == seasonNum,
            orElse: () => throw Exception('Season $seasonNum not found in database'),
          );
          final seasonId = dbSeason['id'] as int;
          
          developer.log(
            'Retrieved TMDB season details',
            name: 'TVShowsProvider',
            error: {
              'showId': showId,
              'seasonNumber': seasonNum,
              'episodeCount': episodes.length,
              'seasonId': seasonId,
            },
          );
          
          final existingEpisodes = await _dbService.getEpisodesForSeason(seasonId);
          final existingEpisodeMap = {
            for (var ep in existingEpisodes)
              ep['episode_number'] as int: ep
          };
          
          developer.log(
            'Retrieved existing TV show episodes',
            name: 'TVShowsProvider',
            error: {
              'showId': showId,
              'seasonNumber': seasonNum,
              'existingEpisodeCount': existingEpisodeMap.length,
            },
          );
          
          for (final episode in episodes) {
            final episodeNumber = episode['episode_number'] as int;
            final existingEpisode = existingEpisodeMap[episodeNumber];
            
            if (existingEpisode != null) {
              if (existingEpisode['name'] != episode['name'] ||
                  existingEpisode['overview'] != episode['overview']) {
                developer.log(
                  'Updating TV show episode metadata',
                  name: 'TVShowsProvider',
                  error: {
                    'showId': showId,
                    'seasonNumber': seasonNum,
                    'episodeNumber': episodeNumber,
                    'oldName': existingEpisode['name'],
                    'newName': episode['name'],
                    'hasOverviewChange': existingEpisode['overview'] != episode['overview'],
                  },
                );
                
                await _dbService.updateEpisodeMetadata(
                  existingEpisode['id'],
                  episode['name'],
                  episode['overview'],
                );
                updatedCount++;
              } else {
                developer.log(
                  'No changes needed for TV show episode',
                  name: 'TVShowsProvider',
                  error: {
                    'showId': showId,
                    'seasonNumber': seasonNum,
                    'episodeNumber': episodeNumber,
                  },
                );
              }
            } else {
              developer.log(
                'No existing TV show episode found',
                name: 'TVShowsProvider',
                error: {
                  'showId': showId,
                  'seasonNumber': seasonNum,
                  'episodeNumber': episodeNumber,
                },
              );
            }
          }
        }
      }

      developer.log(
        'Completed episode metadata update',
        name: 'TVShowsProvider',
        error: {
          'showId': showId,
          'updatedCount': updatedCount,
          'showName': show['name'],
        },
      );

      return updatedCount;
    } catch (e, st) {
      developer.log(
        'Failed to update episode metadata',
        name: 'TVShowsProvider',
        error: {'showId': showId, 'error': e.toString()},
        stackTrace: st,
        level: 1000,
      );
      rethrow;
    }
  }
}

@Riverpod(keepAlive: true)
class SelectedTVShow extends _$SelectedTVShow {
  @override
  TVShow? build() => null;

  void select(TVShow show) => state = show;
} 