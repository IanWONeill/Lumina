import 'dart:developer' as developer;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/database_service.dart';
import '../services/tmdb_service.dart';
import '../services/simkl_service.dart';
import '../../settings/providers/settings_provider.dart';
import '../../settings/services/api_keys_service.dart';
import '../../movies/providers/movies_provider.dart';
import '../../tv_shows/providers/tv_shows_provider.dart';
import '../../../main.dart';

final syncProvider = AsyncNotifierProvider<SyncNotifier, void>(SyncNotifier.new);

class SyncNotifier extends AsyncNotifier<void> {
  late final DatabaseService _dbService;
  late final TMDBService _tmdbService;

  @override
  Future<void> build() async {
    _dbService = DatabaseService();
    
    final apiKeys = await ApiKeysService.readApiKeys();
    if (apiKeys['tmdb'] == null) {
      throw Exception('TMDB API key not found');
    }
    _tmdbService = TMDBService(apiKeys['tmdb']!);
  }

  Future<void> startSync() async {
    state = const AsyncLoading();
    
    try {
      ref.read(syncStatusProvider.notifier).state = 'Starting sync process...';
      developer.log('Starting Sync Process', name: 'SyncNotifier');
      
      final simklToken = await ref.read(simklAuthProvider.future);
      final apiKeys = await ApiKeysService.readApiKeys();
      
      if (simklToken == null) {
        throw Exception('SIMKL auth token not found');
      }
      if (apiKeys['simkl'] == null) {
        throw Exception('SIMKL API key not found');
      }

      final simklService = SimklSyncService(simklToken, apiKeys['simkl']!, ref);
      
      await _syncMovies(simklService);
      await _syncTVShows(simklService);
      
      developer.log('Sync Complete', name: 'SyncNotifier');
      ref.invalidate(moviesProvider);
      ref.invalidate(tVShowsProvider);
      
      ref.read(syncStatusProvider.notifier).state = null;
      state = const AsyncData(null);
    } catch (e, st) {
      developer.log(
        'Sync Error',
        name: 'SyncNotifier',
        error: e,
        stackTrace: st,
        level: 1000,
      );
      state = AsyncError(e, st);
      ref.read(syncStatusProvider.notifier).state = null;
    }
  }

  Future<void> _syncMovies(SimklSyncService simklService) async {
    final existingMovieIds = Set<int>.from(await _dbService.getAllMovieIds());
    developer.log(
      'Loading existing movies',
      name: 'SyncNotifier',
      error: {'count': existingMovieIds.length},
    );
    
    final movies = await simklService.getCompletedMovies();

    for (final movie in movies) {
      final tmdbId = movie['tmdb_id'];
      if (tmdbId == null) continue;

      ref.read(syncStatusProvider.notifier).state = 
          'Checking movie: ${movie['title']}';
      developer.log(
        'Checking movie',
        name: 'SyncNotifier',
        error: {
          'title': movie['title'],
          'tmdbId': tmdbId,
        },
      );
      
      try {
        if (existingMovieIds.contains(tmdbId)) {
          ref.read(syncStatusProvider.notifier).state = 
              'Movie exists: ${movie['title']}';
          developer.log(
            'Movie exists, skipping',
            name: 'SyncNotifier',
            error: {'title': movie['title']},
          );
          continue;
        }

        ref.read(syncStatusProvider.notifier).state = 
            'Adding movie: ${movie['title']}';
        developer.log(
          'Processing new movie',
          name: 'SyncNotifier',
          error: {'title': movie['title']},
        );
        
        final tmdbData = await _tmdbService.getMovieDetails(tmdbId);
        await _dbService.insertMovie(tmdbData);
        existingMovieIds.add(tmdbId);
        
        developer.log(
          'Successfully processed movie',
          name: 'SyncNotifier',
          error: {'title': movie['title']},
        );
        
        await Future.delayed(const Duration(milliseconds: 250));
      } catch (e, st) {
        ref.read(syncStatusProvider.notifier).state = 
            'Failed: ${movie['title']}';
        developer.log(
          'Failed to process movie',
          name: 'SyncNotifier',
          error: {
            'title': movie['title'],
            'tmdbId': tmdbId,
            'error': e.toString(),
          },
          stackTrace: st,
          level: 1000,
        );
      }
    }
  }

  Future<void> _syncTVShows(SimklSyncService simklService) async {
    developer.log('Processing TV Shows', name: 'SyncNotifier');
    
    ref.read(syncStatusProvider.notifier).state = 'Loading TV show database...';
    final existingShows = await _dbService.getAllTVShowDetails();
    final seasonIdMap = await _dbService.getAllSeasonIds();
    final episodeNumberMap = await _dbService.getAllEpisodeNumbers();
    
    developer.log(
      'Loaded TV show database',
      name: 'SyncNotifier',
      error: {
        'showCount': existingShows.length,
        'showsWithSeasons': seasonIdMap.length,
      },
    );
    
    final shows = await simklService.getCompletedTVShows();
    developer.log(
      'Processing SIMKL shows',
      name: 'SyncNotifier',
      error: {'count': shows.length},
    );

    for (final show in shows) {
      final tmdbId = show['tmdb_id'];
      final imdbId = show['imdb_id'];
      if (tmdbId == null) continue;

      ref.read(syncStatusProvider.notifier).state = 
          'Checking show: ${show['title']}';
      developer.log(
        'Processing TV show',
        name: 'SyncNotifier',
        error: {
          'title': show['title'],
          'tmdbId': tmdbId,
          'imdbId': imdbId,
        },
      );
      
      try {
        final existingShow = existingShows[tmdbId];
        final simklEpisodeCount = show['total_episodes'] ?? 0;
        
        if (existingShow == null) {
          ref.read(syncStatusProvider.notifier).state = 
              'Adding show: ${show['title']}';
          developer.log(
            'New show detected, fetching from TMDB',
            name: 'SyncNotifier',
            error: {'title': show['title']},
          );
          
          try {
            final tmdbData = await _tmdbService.getTVShowDetails(tmdbId);
            tmdbData['total_episodes_count'] = simklEpisodeCount;
            tmdbData['imdb_id'] = imdbId;
            
            developer.log(
              'Got basic show data, fetching seasons',
              name: 'SyncNotifier',
              error: {
                'title': show['title'],
                'numberOfSeasons': tmdbData['number_of_seasons'],
              },
            );
            
            final seasons = [];
            final numberOfSeasons = tmdbData['number_of_seasons'] as int;
            
            for (var seasonNum = 1; seasonNum <= numberOfSeasons; seasonNum++) {
              ref.read(syncStatusProvider.notifier).state = 
                  'Fetching season $seasonNum of $numberOfSeasons: ${show['title']}';
              
              try {
                developer.log(
                  'Fetching season',
                  name: 'SyncNotifier',
                  error: {
                    'title': show['title'],
                    'season': seasonNum,
                    'total': numberOfSeasons,
                  },
                );
                
                final seasonData = await _tmdbService.getSeasonDetails(tmdbId, seasonNum);
                if (seasonData['episodes'] != null) {
                  seasons.add(seasonData);
                  developer.log(
                    'Added season data',
                    name: 'SyncNotifier',
                    error: {
                      'title': show['title'],
                      'season': seasonNum,
                      'episodeCount': seasonData['episodes'].length,
                    },
                  );
                }
                
                await Future.delayed(const Duration(milliseconds: 250));
              } catch (e) {
                developer.log(
                  'Failed to fetch season',
                  name: 'SyncNotifier',
                  error: {
                    'showTitle': show['title'],
                    'seasonNum': seasonNum,
                    'error': e.toString(),
                  },
                  level: 900,
                );
                continue;
              }
            }
            
            developer.log(
              'Fetched all seasons, preparing to insert',
              name: 'SyncNotifier',
              error: {
                'title': show['title'],
                'seasonCount': seasons.length,
              },
            );
            
            tmdbData['seasons'] = seasons;

            try {
              developer.log(
                'Starting database insertion',
                name: 'SyncNotifier',
                error: {
                  'title': show['title'],
                  'seasonCount': seasons.length,
                  'episodeCount': seasons.fold<int>(
                    0,
                    (int sum, season) {
                      final episodeCount = (season['episodes']?.length ?? 0) as int;
                      return sum + episodeCount;
                    },
                  ),
                },
              );
              
              await _dbService.insertTVShow(tmdbData);
              
              developer.log(
                'Successfully inserted show and seasons',
                name: 'SyncNotifier',
                error: {
                  'title': show['title'],
                  'seasonCount': seasons.length,
                },
              );
            } catch (e, st) {
              developer.log(
                'Database insertion failed',
                name: 'SyncNotifier',
                error: {
                  'title': show['title'],
                  'error': e.toString(),
                },
                stackTrace: st,
                level: 1000,
              );
              rethrow;
            }
            
            existingShows[tmdbId] = tmdbData;
            
            ref.read(syncStatusProvider.notifier).state = 
                'Completed adding: ${show['title']}';
          } catch (e, st) {
            developer.log(
              'Failed to process show',
              name: 'SyncNotifier',
              error: {
                'title': show['title'],
                'error': e.toString(),
              },
              stackTrace: st,
              level: 1000,
            );
            rethrow;
          }
        } else {
          final dbEpisodeCount = existingShow['total_episodes_count'] as int;
          
          if (simklEpisodeCount > dbEpisodeCount) {
            ref.read(syncStatusProvider.notifier).state = 
                'New episodes found: ${show['title']}';
            developer.log(
              'New episodes detected',
              name: 'SyncNotifier',
              error: {
                'simklEpisodeCount': simklEpisodeCount,
                'dbEpisodeCount': dbEpisodeCount,
              },
            );
            
            final tmdbData = await _tmdbService.getTVShowDetails(tmdbId);
            tmdbData['total_episodes_count'] = simklEpisodeCount;
            tmdbData['imdb_id'] = imdbId;
            await _dbService.updateTVShowDetails(tmdbData);
            
            await _updateExistingSeasons(
              tmdbId, 
              tmdbData['number_of_seasons'], 
              showTitle: show['title'],
              existingSeasons: seasonIdMap[tmdbId] ?? {},
              existingEpisodes: episodeNumberMap,
            );
            
            existingShows[tmdbId] = tmdbData;
          } else {
            ref.read(syncStatusProvider.notifier).state = 
                'Show up to date: ${show['title']}';
            developer.log(
              'No new episodes detected',
              name: 'SyncNotifier',
              error: {'title': show['title']},
            );
            continue;
          }
        }

        await Future.delayed(const Duration(milliseconds: 500));
      } catch (e, st) {
        ref.read(syncStatusProvider.notifier).state = 
            'Failed: ${show['title']}';
        developer.log(
          'Failed to process TV show',
          name: 'SyncNotifier',
          error: {
            'title': show['title'],
            'tmdbId': tmdbId,
            'error': e.toString(),
          },
          stackTrace: st,
          level: 1000,
        );
      }
    }
  }

  Future<void> _updateExistingSeasons(
    int showId, 
    int numberOfSeasons, 
    {
      required String showTitle,
      required Map<int, int> existingSeasons,
      required Map<int, Set<int>> existingEpisodes,
    }
  ) async {
    for (var seasonNum = 1; seasonNum <= numberOfSeasons; seasonNum++) {
      try {
        final seasonId = existingSeasons[seasonNum];
        if (seasonId == null) continue;

        ref.read(syncStatusProvider.notifier).state = 
            'Checking season $seasonNum: $showTitle';
        developer.log(
          'Checking for new episodes in season',
          name: 'SyncNotifier',
          error: {'seasonNum': seasonNum, 'showTitle': showTitle},
        );
        
        final seasonData = await _tmdbService.getSeasonDetails(showId, seasonNum);
        final episodes = List<Map<String, dynamic>>.from(seasonData['episodes']);
        
        final existingEpisodeNumbers = existingEpisodes[seasonId] ?? {};
        
        final newEpisodes = episodes.where(
          (episode) => !existingEpisodeNumbers.contains(episode['episode_number']),
        ).toList();

        if (newEpisodes.isNotEmpty) {
          ref.read(syncStatusProvider.notifier).state = 
              'Found ${newEpisodes.length} new episodes in season $seasonNum';
          developer.log(
            'Found new episodes',
            name: 'SyncNotifier',
            error: {'seasonNum': seasonNum, 'count': newEpisodes.length},
          );
          
          for (final episode in newEpisodes) {
            await _dbService.insertEpisode(episode, showId, seasonId);
            existingEpisodes.putIfAbsent(seasonId, () => {})
              .add(episode['episode_number'] as int);
          }
        }

        await Future.delayed(const Duration(milliseconds: 250));
      } catch (e, st) {
        ref.read(syncStatusProvider.notifier).state = 
            'Failed season $seasonNum: $showTitle';
        developer.log(
          'Failed to update season',
          name: 'SyncNotifier',
          error: {
            'seasonNum': seasonNum,
            'showTitle': showTitle,
            'error': e.toString(),
          },
          stackTrace: st,
          level: 1000,
        );
      }
    }
  }
} 