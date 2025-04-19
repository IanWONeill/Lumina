import 'dart:developer' as developer;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/database_service.dart';
import '../services/tmdb_service.dart';
import '../services/tvdb_service.dart';
import '../services/simkl_service.dart';
import '../services/trakt_service.dart';
import '../../movies/providers/movies_provider.dart';
import '../../tv_shows/providers/tv_shows_provider.dart';
import '../../settings/providers/settings_provider.dart';
import '../../settings/providers/sync_source_provider.dart';
import '../../settings/providers/last_sync_time_provider.dart';
import '../../settings/services/api_keys_service.dart';
import '../../../main.dart';

final syncProvider = AsyncNotifierProvider<SyncNotifier, void>(SyncNotifier.new);

class SyncNotifier extends AsyncNotifier<void> {
  late final DatabaseService _dbService;
  late TMDBService _tmdbService;
  late final SimklSyncService? _simklService;
  late final TraktSyncService? _traktService;
  late final SyncSource _syncSource;
  late final TVDBService _tvdbService;

  void _updateTMDBService(String apiKey, SimklSyncService? simklService) {
    _tmdbService = TMDBService(apiKey, _dbService, simklService);
  }

  @override
  Future<void> build() async {
    _dbService = DatabaseService();
    
    final apiKeys = await ApiKeysService.readApiKeys();
    if (apiKeys['tmdb'] == null) {
      throw Exception('TMDB API key not found');
    }
    if (apiKeys['tvdb'] == null) {
      throw Exception('TVDB API key not found');
    }

    _syncSource = await ref.read(syncSourcePreferenceProvider.future);
    
    if (_syncSource == SyncSource.simkl) {
      if (apiKeys['simkl'] == null) {
        throw Exception('SIMKL API key not found');
      }

      final simklToken = await ref.read(simklAuthProvider.future);
      if (simklToken == null) {
        throw Exception('SIMKL auth token not found');
      }

      _simklService = SimklSyncService(simklToken, apiKeys['simkl']!, ref);
      _traktService = null;
    } else {
      if (apiKeys['trakt'] == null) {
        throw Exception('Trakt client ID not found');
      }

      _traktService = TraktSyncService(apiKeys['trakt']!, ref);
      _simklService = null;
    }
    
    _tmdbService = TMDBService(apiKeys['tmdb']!, _dbService, _syncSource == SyncSource.simkl ? _simklService : null);
    _tvdbService = TVDBService(apiKeys['tvdb']!, _dbService);
  }

  Future<void> sync() async {
    if (state is AsyncLoading) return;
    
    state = const AsyncLoading();
    ref.read(syncStatusProvider.notifier).state = 'Starting sync...';
    
    try {
      final apiKeys = await ApiKeysService.readApiKeys();
      if (apiKeys['tmdb'] == null) {
        throw Exception('TMDB API key not found');
      }
      
      final syncSource = await ref.read(syncSourcePreferenceProvider.future);
      
      if (syncSource == SyncSource.simkl) {
        if (apiKeys['simkl'] == null) {
          throw Exception('SIMKL API key not found');
        }
        
        final simklToken = await ref.read(simklAuthProvider.future);
        if (simklToken == null) {
          throw Exception('SIMKL auth token not found');
        }
        
        final SimklSyncService simklService;
        if (_syncSource == SyncSource.simkl && _simklService != null) {
          simklService = _simklService;
        } else {
          simklService = SimklSyncService(simklToken, apiKeys['simkl']!, ref);
        }
        
        if (_syncSource != SyncSource.simkl) {
          _updateTMDBService(apiKeys['tmdb']!, simklService);
        }
        
        ref.read(syncStatusProvider.notifier).state = 'Syncing from SIMKL...';
        
        await _syncMoviesFromSimkl(simklService);
        await _syncTVShowsFromSimkl(simklService);
      } else if (syncSource == SyncSource.trakt) {
        if (apiKeys['trakt'] == null) {
          throw Exception('Trakt API key not found');
        }
        
        final TraktSyncService traktService;
        if (_syncSource == SyncSource.trakt && _traktService != null) {
          traktService = _traktService;
        } else {
          traktService = TraktSyncService(apiKeys['trakt']!, ref);
        }
        
        if (_syncSource != SyncSource.trakt) {
          _updateTMDBService(apiKeys['tmdb']!, null);
        }
        
        ref.read(syncStatusProvider.notifier).state = 'Syncing from Trakt...';
        
        await traktService.fetchAllItems();
        
        await _syncMoviesFromTrakt(traktService);
        await _syncTVShowsFromTrakt(traktService);
        
        traktService.clearCache();
      }
      
      if (syncSource == SyncSource.simkl) {
        await _tmdbService.syncWithSimkl();
      } else {
        await _tmdbService.syncWithTrakt(_traktService!);
      }
      
      final now = DateTime.now();
      await ref.read(lastSyncTimeProvider.notifier).setLastSyncTime(now);
      
      ref.read(syncStatusProvider.notifier).state = 'Sync completed';
      state = const AsyncData(null);
      
      ref.invalidate(moviesProvider);
      ref.invalidate(tVShowsProvider);
    } catch (e, st) {
      ref.read(syncStatusProvider.notifier).state = 'Sync failed: $e';
      developer.log(
        'Sync failed',
        name: 'SyncNotifier',
        error: e,
        stackTrace: st,
        level: 1000,
      );
      state = AsyncError(e, st);
    }
  }

  Future<void> _syncMoviesFromSimkl(SimklSyncService simklService) async {
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

  Future<void> _syncTVShowsFromSimkl(SimklSyncService simklService) async {
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
            final tmdbData = await _tmdbService.fetchTVShowDetails(tmdbId);
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
            
            final tmdbData = await _tmdbService.fetchTVShowDetails(tmdbId);
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

  Future<void> _syncMoviesFromTrakt(TraktSyncService traktService) async {
    ref.read(syncStatusProvider.notifier).state = 'Fetching movies from Trakt...';
    
    try {
      final movies = await traktService.getCompletedMovies();
      
      ref.read(syncStatusProvider.notifier).state = 
          'Processing ${movies.length} movies from Trakt...';
      
      final existingMovieIds = Set<int>.from(await _dbService.getAllMovieIds());
      developer.log(
        'Loading existing movies',
        name: 'SyncNotifier',
        error: {'count': existingMovieIds.length},
      );
      
      for (final movie in movies) {
        final tmdbId = movie['tmdb_id'];
        if (tmdbId == null) continue;
        
        ref.read(syncStatusProvider.notifier).state = 
            'Checking movie: ${movie['title'] ?? 'Unknown'}';
        
        if (existingMovieIds.contains(tmdbId)) {
          developer.log(
            'Movie exists, skipping',
            name: 'SyncNotifier',
            error: {
              'title': movie['title'] ?? 'Unknown',
              'tmdbId': tmdbId,
            },
          );
          continue;
        }

        try {
          ref.read(syncStatusProvider.notifier).state = 
              'Adding movie: ${movie['title'] ?? 'Unknown'}';
          
          final movieDetails = await _tmdbService.fetchMovieDetails(tmdbId);
          if (movie['imdb_id'] != null) {
            movieDetails['imdb_id'] = movie['imdb_id'];
          }
          
          await _dbService.insertMovie({
            ...movieDetails,
            'last_updated': DateTime.now().toIso8601String(),
          });
          
          developer.log(
            'Successfully added new movie',
            name: 'SyncNotifier',
            error: {
              'title': movie['title'] ?? 'Unknown',
              'imdbId': movie['imdb_id'],
            },
          );
        } catch (e, st) {
          developer.log(
            'Failed to add new movie',
            name: 'SyncNotifier',
            error: {'tmdbId': tmdbId, 'title': movie['title'] ?? 'Unknown', 'error': e},
            stackTrace: st,
            level: 900,
          );
        }
        
        await Future.delayed(const Duration(milliseconds: 250));
      }
      
      ref.read(syncStatusProvider.notifier).state = 'Movies sync completed';
    } catch (e, stackTrace) {
      developer.log(
        'Error syncing movies from Trakt',
        name: 'SyncNotifier',
        error: e,
        stackTrace: stackTrace,
        level: 1000,
      );
      throw Exception('Failed to sync movies: $e');
    }
  }

  Future<void> _syncTVShowsFromTrakt(TraktSyncService traktService) async {
    ref.read(syncStatusProvider.notifier).state = 'Fetching TV shows from Trakt...';
    
    try {
      final shows = await traktService.getCompletedTVShows();
      
      ref.read(syncStatusProvider.notifier).state = 
          'Processing ${shows.length} TV shows from Trakt...';
      
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
      
      for (final show in shows) {
        final tmdbId = show['tmdb_id'];
        final tvdbId = show['tvdb_id'];
        final isAnime = show['is_anime'] == 1;
        
        if (tmdbId == null) continue;
        
        ref.read(syncStatusProvider.notifier).state = 
            'Checking show: ${show['title'] ?? 'Unknown'}';
        
        try {
          final existingShow = existingShows[tmdbId];
          
          if (existingShow != null) {

            Map<String, dynamic> episodeInfo;
            
            if (isAnime && tvdbId != null) {
              episodeInfo = await _tvdbService.getEpisodeCount(tvdbId);
              final newEpisodeCount = episodeInfo['number_of_episodes'] as int;
              final existingEpisodeCount = existingShow['total_episodes_count'] as int;
              
              if (newEpisodeCount <= existingEpisodeCount) {
                developer.log(
                  'No new episodes, skipping',
                  name: 'SyncNotifier',
                  error: {
                    'title': show['title'] ?? 'Unknown',
                    'currentEpisodes': existingEpisodeCount,
                    'newEpisodes': newEpisodeCount,
                  },
                );
                continue;
              }
              
              Map<String, dynamic> showData = await _tvdbService.getAnimeDetails(tvdbId, tmdbId);
              showData['tmdb_id'] = tmdbId;
              showData['is_anime'] = isAnime ? 1 : 0;
              if (tvdbId != null) showData['tvdb_id'] = tvdbId;
              if (show['imdb_id'] != null) showData['imdb_id'] = show['imdb_id'];
              showData['total_episodes_count'] = newEpisodeCount;
              showData['number_of_episodes'] = newEpisodeCount;
              showData['last_updated'] = DateTime.now().toIso8601String();
              
              developer.log(
                'Updating anime with Trakt overview',
                name: 'SyncNotifier',
                error: {
                  'title': show['title'] ?? 'Unknown',
                  'has_show_data': show['show'] != null,
                  'has_overview': show['show']?['overview'] != null,
                  'overview': show['show']?['overview'],
                },
              );
              
              if (show['show']?['overview'] != null) {
                showData['overview'] = show['show']['overview'];
              }
              
              if (show['title'] != null) {
                showData['name'] = show['title'];
                showData['original_name'] = show['title'];
                
                developer.log(
                  'Using Trakt title for existing anime show',
                  name: 'SyncNotifier',
                  error: {
                    'title': show['title'],
                    'tvdb_slug': showData['original_name'],
                  },
                );
              }
              
              await _dbService.updateTVShowDetails(showData);
              
              if (!isAnime) {
                await _updateExistingSeasons(
                  tmdbId, 
                  showData['number_of_seasons'], 
                  showTitle: existingShow['name'],
                  existingSeasons: seasonIdMap[tmdbId] ?? {},
                  existingEpisodes: episodeNumberMap,
                );
              }
            } else {
              episodeInfo = await _tmdbService.getEpisodeCount(tmdbId);
              final newEpisodeCount = episodeInfo['number_of_episodes'] as int;
              final existingEpisodeCount = existingShow['total_episodes_count'] as int;
              
              if (newEpisodeCount <= existingEpisodeCount) {
                developer.log(
                  'No new episodes, skipping',
                  name: 'SyncNotifier',
                  error: {
                    'title': show['title'] ?? 'Unknown',
                    'currentEpisodes': existingEpisodeCount,
                    'newEpisodes': newEpisodeCount,
                  },
                );
                continue;
              }
              
              Map<String, dynamic> showData = await _tmdbService.fetchTVShowDetails(tmdbId);
              showData['tmdb_id'] = tmdbId;
              showData['is_anime'] = isAnime ? 1 : 0;
              if (tvdbId != null) showData['tvdb_id'] = tvdbId;
              if (show['imdb_id'] != null) showData['imdb_id'] = show['imdb_id'];
              showData['total_episodes_count'] = newEpisodeCount;
              showData['number_of_episodes'] = newEpisodeCount;
              showData['last_updated'] = DateTime.now().toIso8601String();
              
              await _dbService.updateTVShowDetails(showData);
              
              if (!isAnime) {
                await _updateExistingSeasons(
                  tmdbId, 
                  showData['number_of_seasons'], 
                  showTitle: existingShow['name'],
                  existingSeasons: seasonIdMap[tmdbId] ?? {},
                  existingEpisodes: episodeNumberMap,
                );
              }
            }
          } else {
            ref.read(syncStatusProvider.notifier).state = 
                'Adding new show: ${show['title'] ?? 'Unknown'}';
            
            try {
              Map<String, dynamic> showData;
              
              if (isAnime && tvdbId != null) {
                showData = await _tvdbService.getAnimeDetails(tvdbId, tmdbId);
                showData['tmdb_id'] = tmdbId;
                showData['is_anime'] = 1;
                
                developer.log(
                  'Adding Trakt overview for anime',
                  name: 'SyncNotifier',
                  error: {
                    'title': show['title'] ?? 'Unknown',
                    'has_show_data': show['show'] != null,
                    'has_overview': show['show']?['overview'] != null,
                    'overview': show['show']?['overview'],
                  },
                );

                if (show['show']?['overview'] != null) {
                  showData['overview'] = show['show']['overview'];
                }
                
                if (show['title'] != null) {
                  showData['name'] = show['title'];
                  showData['original_name'] = show['title'];
                  
                  developer.log(
                    'Using Trakt title for anime show',
                    name: 'SyncNotifier',
                    error: {
                      'title': show['title'],
                      'tvdb_slug': showData['original_name'],
                    },
                  );
                }
              } else {
                showData = await _tmdbService.fetchTVShowDetails(tmdbId);
                if (tvdbId != null) showData['tvdb_id'] = tvdbId;
              }
              
              if (show['imdb_id'] != null) showData['imdb_id'] = show['imdb_id'];
              showData['total_episodes_count'] = showData['number_of_episodes'];
              showData['last_updated'] = DateTime.now().toIso8601String();
              
              await _dbService.insertTVShow(showData);
              
              developer.log(
                'Successfully added new show',
                name: 'SyncNotifier',
                error: {
                  'title': show['title'] ?? 'Unknown',
                  'isAnime': isAnime,
                  'provider': isAnime ? 'TVDB' : 'TMDB',
                },
              );
            } catch (e, st) {
              developer.log(
                'Failed to add new show',
                name: 'SyncNotifier',
                error: {
                  'title': show['title'] ?? 'Unknown',
                  'error': e.toString(),
                },
                stackTrace: st,
                level: 1000,
              );
            }
          }
          
          await Future.delayed(const Duration(milliseconds: 250));
        } catch (e, st) {
          developer.log(
            'Error processing TV show',
            name: 'SyncNotifier',
            error: {
              'tmdbId': tmdbId,
              'tvdbId': tvdbId,
              'error': e.toString(),
            },
            stackTrace: st,
            level: 1000,
          );
        }
      }
      
      ref.read(syncStatusProvider.notifier).state = 'TV shows sync completed';
      
      traktService.clearCache();
    } catch (e, stackTrace) {
      developer.log(
        'Error syncing TV shows from Trakt',
        name: 'SyncNotifier',
        error: e,
        stackTrace: stackTrace,
        level: 1000,
      );
      throw Exception('Failed to sync TV shows: $e');
    }
  }
} 