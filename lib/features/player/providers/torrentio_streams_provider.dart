import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../services/torrentio_streams_service.dart';
import '../utils/torrentio_stream_filter.dart';
import '../models/stream_info.dart';
import '../../sync/services/database_service.dart';
import '../../tv_shows/models/episode.dart';
import '../../settings/providers/premiumize_provider.dart';
import '../../settings/providers/torrentio_settings_provider.dart';

part 'torrentio_streams_provider.g.dart';

@riverpod
class TorrentioStreams extends _$TorrentioStreams {
  @override
  Future<Map<String, dynamic>> build(dynamic media, bool isMovie) async {
    final premiumizeApiKeyAsync = await ref.watch(premiumizeApiKeyProvider.future);
    final torrentioSettings = await ref.watch(torrentioSettingsProvider.future);
    
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
      
      final seasonDetails = await db.getSeasonDetails(episode.seasonId);
      seasonNumber = seasonDetails?['season_number'];
      episodeNumber = episode.episodeNumber;
    }

    if (imdbId == null) {
      throw Exception('IMDB ID not found');
    }

    final service = TorrentioStreamsService(premiumizeApiKey: premiumizeApiKeyAsync);
     
    final response = await service.getStreams(
      imdbId: imdbId,
      isMovie: isMovie,
      seasonNumber: seasonNumber,
      episodeNumber: episodeNumber,
    );

    if (response['streams'] != null && response['streams'] is List) {
      final rawStreams = response['streams'] as List;
      final streams = rawStreams
          .map((stream) => StreamInfo.fromTorrentioResponse(stream as Map<String, dynamic>))
          .toList();

      final filteredStreams = TorrentioStreamFilter.filterAndSort(
        streams,
        isMovie ? torrentioSettings.movies : torrentioSettings.episodes,
      );

      return {
        ...response,
        'streams': filteredStreams.map((stream) => {
          'name': stream.qualityLabel,
          'title': '${stream.fileName}\n👤 ${stream.seeds} 💾 ${stream.fileSize} ⚙️ ${stream.uploader}',
          'url': stream.id,
          'behaviorHints': {
            'bingeGroup': 'torrentio|${stream.quality}|${stream.release}|${stream.codec}',
            'filename': stream.fileName,
          },
        }).toList(),
      };
    }

    return response;
  }
} 