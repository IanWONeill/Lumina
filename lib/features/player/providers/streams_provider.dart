import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'dart:developer' as developer;
import '../services/orionoid_streams_service.dart';
import '../../settings/providers/orionoid_provider.dart';
import '../../settings/providers/orion_settings_provider.dart';
import '../../sync/services/database_service.dart';
import '../../tv_shows/models/episode.dart';

part 'streams_provider.g.dart';

@riverpod
class Streams extends _$Streams {
  @override
  Future<Map<String, dynamic>> build(dynamic media, bool isMovie) async {
    final tokenAsync = ref.watch(orionoidAuthProvider);
    
    final token = switch (tokenAsync) {
      AsyncData(:final value) => value,
      AsyncError(:final error) => throw Exception('Token error: $error'),
      _ => throw Exception('Waiting for token...'),
    };

    final settings = await ref.watch(orionSettingsProvider.future);

    developer.log(
      'Authentication Status',
      name: 'StreamsProvider',
      error: {
        'token': token != null ? 'Found' : 'Not found',
        'settings': settings != null ? 'Found' : 'Not found'
      }
    );

    if (token == null || settings == null) {
      throw Exception('Orionoid token or settings not found');
    }

    final db = DatabaseService();
    String? imdbId;
    int? seasonNumber;
    int? episodeNumber;
    
    if (isMovie) {
      final movie = await db.getMovie(media.tmdbId);
      imdbId = movie?['imdb_id'];
    } else {
      final episode = media as Episode;
      final showDetails = await db.getTVShowDetails(episode.showId);
      imdbId = showDetails?['imdb_id'];
      
      developer.log(
        'Episode Details',
        name: 'StreamsProvider',
        error: {
          'episodeId': episode.id,
          'showId': episode.showId,
          'seasonId': episode.seasonId,
          'episodeNumber': episode.episodeNumber,
        }
      );
      
      final seasonDetails = await db.getSeasonDetails(episode.seasonId);
      seasonNumber = seasonDetails?['season_number'];
      
      developer.log(
        'Season Details',
        name: 'StreamsProvider',
        error: {'seasonNumber': seasonNumber}
      );
      
      episodeNumber = episode.episodeNumber;
    }

    if (imdbId == null) {
      throw Exception('IMDB ID not found');
    }

    final service = OrionoidStreamsService(
      token,
      isMovie ? settings.movies : settings.episodes,
    );
     
    return service.getStreams(
      imdbId: imdbId,
      isMovie: isMovie,
      seasonNumber: seasonNumber,
      episodeNumber: episodeNumber,
    );
  }
} 