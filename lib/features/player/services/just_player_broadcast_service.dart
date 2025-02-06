import 'package:flutter_broadcasts/flutter_broadcasts.dart';
import 'dart:developer' as developer;
import '../../sync/services/database_service.dart';
import '../providers/watched_status_provider.dart';
import 'package:riverpod/riverpod.dart';
import '../../movies/providers/movies_provider.dart';
import '../../tv_shows/providers/episodes_provider.dart';
import '../../tv_shows/models/season.dart';

class JustPlayerBroadcastService {
  static const List<String> justPlayerActions = [
    'com.brouken.player.PLAYBACK_UPDATE',
  ];
  
  final DatabaseService _db;
  final Ref _ref;
  BroadcastReceiver? _receiver;
  int? _currentMediaId;
  String? _mediaType;
  static const int _watchThreshold = 75;
  bool _isListening = false;
  DateTime? _lastUpdate;
  static const Duration _updateThrottle = Duration(seconds: 10);

  JustPlayerBroadcastService(this._db, this._ref);

  bool get _canUpdate {
    if (_lastUpdate == null) return true;
    return DateTime.now().difference(_lastUpdate!) >= _updateThrottle;
  }

  void setCurrentMedia({
    required int mediaId,
    required String type,
  }) async {
    await stopListening();
    
    assert(type == 'movie' || type == 'episode', 
      'Media type must be either "movie" or "episode"');
    _currentMediaId = mediaId;
    _mediaType = type;
    
    await startListening();
  }

  Future<void> startListening() async {
    if (_isListening) {
      return;
    }

    try {
      _receiver = BroadcastReceiver(names: justPlayerActions);
      
      _receiver?.messages.listen(
        (event) async {
          if (event.data != null && _currentMediaId != null) {
            final percentage = event.data?['percentage'] as int? ?? 0;
            final position = event.data?['position'] as int?;
            final duration = event.data?['duration'] as int?;

            developer.log(
              'Received broadcast',
              name: 'JustPlayerBroadcast',
              error: {
                'percentage': '$percentage%',
                'position': '${position}ms',
                'duration': duration,
              },
            );

            if (position != null && _currentMediaId != null) {
              await _updateWatchProgress(
                position,
                percentage,
              );
              
              if (percentage >= _watchThreshold) {
                developer.log(
                  'Watch threshold reached',
                  name: 'JustPlayerBroadcast',
                  error: {
                    'current': percentage,
                    'threshold': _watchThreshold,
                  },
                );
                await _updateWatchStatus();
              }
            }
          }
        },
        onError: (error, stackTrace) {
          developer.log(
            'Error in broadcast listener',
            name: 'JustPlayerBroadcast',
            error: error,
            stackTrace: stackTrace,
            level: 1000,
          );
        },
      );

      await _receiver?.start();
      _isListening = true;
      developer.log(
        'Broadcast listener started successfully',
        name: 'JustPlayerBroadcast',
      );
    } catch (e, stackTrace) {
      _isListening = false;
      developer.log(
        'Failed to start broadcast listener',
        name: 'JustPlayerBroadcast',
        error: e,
        stackTrace: stackTrace,
        level: 1000,
      );
    }
  }

  Future<void> _updateWatchProgress(int positionMs, int percentage) async {
    if (_currentMediaId == null || _mediaType == null) return;

    if (!_canUpdate) {
      final nextUpdate = _updateThrottle.inSeconds - 
          DateTime.now().difference(_lastUpdate!).inSeconds;
      developer.log(
        'Skipping update - throttled',
        name: 'JustPlayerBroadcast',
        error: {'nextUpdateIn': '${nextUpdate}s'},
      );
      return;
    }

    try {
      developer.log(
        'Updating watch progress',
        name: 'JustPlayerBroadcast',
        error: {
          'mediaId': _currentMediaId,
          'position': '${positionMs}ms',
          'percentage': '$percentage%',
        },
      );
      
      if (_mediaType == 'movie') {
        await _db.updateMovieProgress(
          _currentMediaId!, 
          positionMs,
          percentage,
        );
      } else if (_mediaType == 'episode') {
        await _db.updateEpisodeWatchProgress(
          _currentMediaId!, 
          positionMs,
          percentage,
        );
      }
      
      _lastUpdate = DateTime.now();
      
    } catch (e, stackTrace) {
      developer.log(
        'Error updating watch progress',
        name: 'JustPlayerBroadcast',
        error: e,
        stackTrace: stackTrace,
        level: 1000,
      );
    }
  }

  Future<void> _updateWatchStatus() async {
    if (_currentMediaId == null || _mediaType == null) return;

    try {
      developer.log(
        'Updating watch status',
        name: 'JustPlayerBroadcast',
        error: {
          'mediaType': _mediaType,
          'mediaId': _currentMediaId,
        },
      );
      
      if (_mediaType == 'movie') {
        await _ref.read(
          watchedStatusProvider(_currentMediaId!, true).notifier
        ).toggleWatched();
        
        _ref.invalidate(moviesProvider);
        await Future.delayed(const Duration(milliseconds: 100));
        await _ref.refresh(moviesProvider.future);
        
      } else if (_mediaType == 'episode') {
        await _ref.read(
          watchedStatusProvider(_currentMediaId!, false).notifier
        ).toggleWatched();

        final episode = await _db.getEpisode(_currentMediaId!);
        if (episode != null) {
          final seasons = await _db.getSeasonsForShow(episode['show_id'] as int);
          final seasonData = seasons.firstWhere(
            (s) => s['id'] == episode['season_id'],
          );
          
          final season = Season(
            id: seasonData['id'] as int,
            tmdbId: seasonData['tmdb_id'] as int,
            showId: seasonData['show_id'] as int, 
            seasonNumber: seasonData['season_number'] as int,
            name: seasonData['name'] as String,
            overview: seasonData['overview'] as String,
            posterPath: seasonData['poster_path'] as String?,
          );

          _ref.invalidate(seasonEpisodesProvider(season));
          await Future.delayed(const Duration(milliseconds: 100));
          await _ref.refresh(seasonEpisodesProvider(season).future);
        }
      }
      
      developer.log(
        'Watch status update completed',
        name: 'JustPlayerBroadcast',
      );
    } catch (e, stackTrace) {
      developer.log(
        'Error updating watch status',
        name: 'JustPlayerBroadcast',
        error: e,
        stackTrace: stackTrace,
        level: 1000,
      );
    }
  }

  Future<void> stopListening() async {
    try {
      await _receiver?.stop();
      _receiver = null;
      _currentMediaId = null;
      _mediaType = null;
      _isListening = false;
      _lastUpdate = null;
    } catch (e, stackTrace) {
      developer.log(
        'Failed to stop broadcast listener',
        name: 'JustPlayerBroadcast',
        error: e,
        stackTrace: stackTrace,
        level: 1000,
      );
    }
  }
} 