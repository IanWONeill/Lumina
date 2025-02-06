import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'dart:io';
import 'dart:developer' as developer;
import '../services/tmdb_service.dart';
import '../services/database_service.dart';
import '../../settings/services/api_keys_service.dart';

part 'full_sync_provider.g.dart';

@Riverpod(keepAlive: true)
class FullSync extends _$FullSync {
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

  Future<void> startFullSync() async {
    state = const AsyncLoading();

    try {
      final movies = await _dbService.getAllMovies();
      final shows = await _dbService.getAllTVShows();

      developer.log(
        'Starting Full Sync',
        name: 'FullSync',
        error: {
          'movieCount': movies.length,
          'showCount': shows.length,
        },
      );

      for (final show in shows) {
        if (show['original_name'] == null || show['original_name'].toString().isEmpty) {
          developer.log(
            'Show missing original_name',
            name: 'FullSync',
            error: {'tmdbId': show['tmdb_id']},
            level: 900,
          );
          try {
            final showData = await _tmdbService.getTVShowDetails(show['tmdb_id']);
            await _dbService.insertTVShow(showData);
            continue;
          } catch (e, stack) {
            developer.log(
              'Error fixing show with missing title',
              name: 'FullSync',
              error: e,
              stackTrace: stack,
              level: 1000,
            );
            continue;
          }
        }

        final needsRegularSync = _shouldSyncShow(show);
        final needsTitleSync = _shouldSyncTitle(show['original_name']);
        
        developer.log(
          'Checking show',
          name: 'FullSync',
          error: {
            'title': show['original_name'],
            'needsTitleSync': needsTitleSync,
            'needsRegularSync': needsRegularSync,
          },
        );
        
        if (needsRegularSync || needsTitleSync) {
          developer.log(
            'Syncing show data',
            name: 'FullSync',
            error: {'title': show['original_name']},
          );
          try {
            final showData = await _tmdbService.getTVShowDetails(show['tmdb_id']);
            
            if (!needsRegularSync && needsTitleSync) {
              showData['cast'] = show['cast'];
              showData['overview'] = show['overview'];
              showData['first_air_date'] = show['first_air_date'];
              showData['number_of_episodes'] = show['number_of_episodes'];
              showData['number_of_seasons'] = show['number_of_seasons'];
              showData['has_no_backdrop'] = show['has_no_backdrop'];
            }
            
            if (needsTitleSync && showData['name'] != null) {
              developer.log(
                'Updating show title',
                name: 'FullSync',
                error: {
                  'oldTitle': show['original_name'],
                  'newTitle': showData['name'],
                },
              );
              showData['original_name'] = showData['name'];
            }
            
            await _dbService.insertTVShow(showData);
            await Future.delayed(const Duration(milliseconds: 250));
          } catch (e, stack) {
            developer.log(
              'Error syncing show',
              name: 'FullSync',
              error: {
                'title': show['original_name'],
                'error': e.toString(),
              },
              stackTrace: stack,
              level: 1000,
            );
          }
        } else {
          developer.log(
            'Skipping show',
            name: 'FullSync',
            error: {'title': show['original_name']},
          );
        }
      }

      for (final movie in movies) {
        if (movie['original_title'] == null || movie['original_title'].toString().isEmpty) {
          developer.log(
            'Movie missing original_title',
            name: 'FullSync',
            error: {'tmdbId': movie['tmdb_id']},
            level: 900,
          );
          try {
            final movieData = await _tmdbService.getMovieDetails(movie['tmdb_id']);
            await _dbService.insertMovie(movieData);
            continue;
          } catch (e) {
            developer.log(
              'Error fixing movie with missing title',
              name: 'FullSync',
              error: e,
              level: 1000,
            );
            continue;
          }
        }

        final needsRegularSync = _shouldSyncMovie(movie);
        final needsTitleSync = _shouldSyncTitle(movie['original_title']);
        
        developer.log(
          'Checking movie',
          name: 'FullSync',
          error: {
            'title': movie['original_title'],
            'needsTitleSync': needsTitleSync,
            'needsRegularSync': needsRegularSync,
          },
        );
        
        if (needsRegularSync || needsTitleSync) {
          developer.log(
            'Syncing movie data',
            name: 'FullSync',
            error: {'title': movie['original_title']},
          );
          try {
            final movieData = await _tmdbService.getMovieDetails(movie['tmdb_id']);
            
            if (!needsRegularSync && needsTitleSync) {
              movieData['cast'] = movie['cast'] ?? [];
              movieData['overview'] = movie['overview'];
              movieData['release_date'] = movie['release_date'];
              movieData['revenue'] = movie['revenue'];
              movieData['runtime'] = movie['runtime'];
              movieData['vote_average'] = movie['vote_average'];
              movieData['has_no_backdrop'] = movie['has_no_backdrop'];
              
              movieData['_skip_downloads'] = true;
            }
            
            if (needsTitleSync && movieData['title'] != null) {
              developer.log(
                'Updating movie title',
                name: 'FullSync',
                error: {
                  'oldTitle': movie['original_title'],
                  'newTitle': movieData['title'],
                },
              );
              movieData['original_title'] = movieData['title'];
            }
            
            movieData['cast'] = movieData['cast'] ?? [];
            
            await _dbService.insertMovie(movieData);
            await Future.delayed(const Duration(milliseconds: 250));
          } catch (e, stack) {
            developer.log(
              'Error syncing movie',
              name: 'FullSync',
              error: {
                'title': movie['original_title'],
                'error': e.toString(),
              },
              stackTrace: stack,
              level: 1000,
            );
          }
        } else {
          developer.log(
            'Skipping movie',
            name: 'FullSync',
            error: {'title': movie['original_title']},
          );
        }
      }

      developer.log('Full Sync Complete', name: 'FullSync');
      state = const AsyncData(null);
    } catch (e, st) {
      developer.log(
        'Error during full sync',
        name: 'FullSync',
        error: e,
        stackTrace: st,
        level: 1000,
      );
      state = AsyncError(e, st);
    }
  }

  bool _shouldSyncMovie(Map<String, dynamic> movie) {
    final posterPath = '/storage/emulated/0/Debrid_Player/metadata/movies/posters/${movie['tmdb_id']}/poster.webp';
    final backdropPath = '/storage/emulated/0/Debrid_Player/metadata/movies/backdrops/${movie['tmdb_id']}/backdrop.webp';
    
    final hasIncompleteData = 
      (movie['overview'] == null || movie['overview'].toString().isEmpty) ||
      (movie['release_date'] == null || movie['release_date'].toString().isEmpty) ||
      movie['runtime'] == null ||
      movie['vote_average'] == null;

    final hasPoster = File(posterPath).existsSync();
    final hasBackdrop = File(backdropPath).existsSync();
    final hasNoBackdropInTMDB = movie['has_no_backdrop'] == true;

    final cast = movie['cast'] as List<dynamic>?;
    if (cast != null) {
      developer.log(
        'Checking actor images',
        name: 'FullSync',
        error: {'actorCount': cast.length},
      );
    }
    final hasMissingActorImages = cast?.any((actor) {
      final actorImagePath = '/storage/emulated/0/Debrid_Player/metadata/actors/${actor['id']}/${actor['id']}.webp';
      final exists = File(actorImagePath).existsSync();
      return !exists;
    }) ?? false;

    final backdropComplete = hasBackdrop || hasNoBackdropInTMDB;

    if (hasPoster && backdropComplete && !hasMissingActorImages && !hasIncompleteData) {
      developer.log(
        'Movie files complete',
        name: 'FullSync',
        error: {'title': movie['original_title']},
      );
      return false;
    }
    
    return true;
  }

  bool _shouldSyncShow(Map<String, dynamic> show) {
    final posterPath = '/storage/emulated/0/Debrid_Player/metadata/tv/posters/${show['tmdb_id']}/poster.webp';
    final backdropPath = '/storage/emulated/0/Debrid_Player/metadata/tv/backdrops/${show['tmdb_id']}/backdrop.webp';
    
    final hasIncompleteData = 
      (show['overview'] == null || show['overview'].toString().isEmpty) ||
      (show['first_air_date'] == null || show['first_air_date'].toString().isEmpty) ||
      show['number_of_episodes'] == null ||
      show['number_of_seasons'] == null;

    final hasPoster = File(posterPath).existsSync();
    final hasBackdrop = File(backdropPath).existsSync();
    final hasNoBackdropInTMDB = show['has_no_backdrop'] == true;
    final backdropComplete = hasBackdrop || hasNoBackdropInTMDB;

    final cast = show['cast'] as List<dynamic>?;
    final hasMissingActorImages = cast?.any((actor) {
      final actorImagePath = '/storage/emulated/0/Debrid_Player/metadata/actors/${actor['id']}/${actor['id']}.webp';
      final exists = File(actorImagePath).existsSync();
      return !exists;
    }) ?? false;

    return !hasPoster || !backdropComplete || hasMissingActorImages || hasIncompleteData;
  }

  bool _shouldSyncTitle(String? title) {
    if (title == null || title.isEmpty) return false;
    
    final latinRegex = RegExp('^[a-zA-Z0-9\\s\\-\'":,.!?&() ]+\$');
    
    return !latinRegex.hasMatch(title);
  }
} 