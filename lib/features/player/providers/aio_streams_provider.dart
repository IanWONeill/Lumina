import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../services/aio_streams_service.dart';
import '../utils/aio_streams_filter.dart';
import '../models/stream_info.dart';
import '../../sync/services/database_service.dart';
import '../../tv_shows/models/episode.dart';
import '../../settings/providers/aio_config_provider.dart';
import '../../settings/providers/aio_streams_settings_provider.dart';
import 'dart:developer' as developer;

part 'aio_streams_provider.g.dart';

@riverpod
class AioStreams extends _$AioStreams {
  @override
  Future<Map<String, dynamic>> build(dynamic media, bool isMovie) async {
    final aioConfigAsync = await ref.watch(aioConfigProvider.future);
    final aioStreamsSettings = await ref.watch(aioStreamsSettingsProvider.future);
    
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

    final service = AioStreamsService(aioConfig: aioConfigAsync);
    
    // Try with filters first
    final response = await service.getStreams(
      imdbId: imdbId,
      isMovie: isMovie,
      seasonNumber: seasonNumber,
      episodeNumber: episodeNumber,
      useFilters: true,
    );

    if (response['streams'] != null && response['streams'] is List) {
      final rawStreams = response['streams'] as List;
      
      // Filter out error entries and entries without URLs
      final validStreams = rawStreams.where((stream) {
        final streamMap = stream as Map<String, dynamic>;
        final streamData = streamMap['streamData'] as Map<String, dynamic>?;
        
        // Skip error entries
        if (streamData?['type'] == 'error') {
          return false;
        }
        
        // Skip entries without URLs
        if (streamMap['url'] == null) {
          return false;
        }
        
        return true;
      }).toList();
      
      final streams = validStreams
          .map((stream) => StreamInfo.fromAioStreamsResponse(stream as Map<String, dynamic>))
          .toList();

      final filteredStreams = AioStreamsFilter.filterAndSort(
        streams,
        isMovie ? aioStreamsSettings.movies : aioStreamsSettings.episodes,
      );

      // If we found streams with filters, return them
      if (filteredStreams.isNotEmpty) {
        developer.log(
          'Found AIOStreams streams with filters',
          name: 'AioStreamsProvider',
          error: {'count': filteredStreams.length},
        );
        
        return {
          ...response,
          'streams': filteredStreams.map((stream) => {
            'name': stream.qualityLabel,
            'title': '${stream.fileName}\n👤 ${stream.seeds} 💾 ${stream.fileSize} ⚙️ ${stream.uploader}',
            'url': stream.id,
            'behaviorHints': {
              'bingeGroup': 'aiostreams|${stream.quality}|${stream.release}|${stream.codec}',
              'filename': stream.fileName,
            },
          }).toList(),
          'filterStatus': {
            'usedFilters': true,
            'provider': 'AIOStreams',
          },
        };
      }
    }

    // If no streams found with filters, try without filters
    developer.log(
      'No AIOStreams streams found with filters, trying without filters',
      name: 'AioStreamsProvider',
    );

    final fallbackResponse = await service.getStreams(
      imdbId: imdbId,
      isMovie: isMovie,
      seasonNumber: seasonNumber,
      episodeNumber: episodeNumber,
      useFilters: false,
    );

    if (fallbackResponse['streams'] != null && fallbackResponse['streams'] is List) {
      final rawStreams = fallbackResponse['streams'] as List;
      
      // Filter out error entries and entries without URLs
      final validStreams = rawStreams.where((stream) {
        final streamMap = stream as Map<String, dynamic>;
        final streamData = streamMap['streamData'] as Map<String, dynamic>?;
        
        // Skip error entries
        if (streamData?['type'] == 'error') {
          return false;
        }
        
        // Skip entries without URLs
        if (streamMap['url'] == null) {
          return false;
        }
        
        return true;
      }).toList();
      
      final streams = validStreams
          .map((stream) => StreamInfo.fromAioStreamsResponse(stream as Map<String, dynamic>))
          .toList();

      // Don't apply filters for fallback request
      final unfilteredStreams = streams;

      developer.log(
        'Found AIOStreams streams without filters',
        name: 'AioStreamsProvider',
        error: {'count': unfilteredStreams.length},
      );

      return {
        ...fallbackResponse,
        'streams': unfilteredStreams.map((stream) => {
          'name': stream.qualityLabel,
          'title': '${stream.fileName}\n👤 ${stream.seeds} 💾 ${stream.fileSize} ⚙️ ${stream.uploader}',
          'url': stream.id,
          'behaviorHints': {
            'bingeGroup': 'aiostreams|${stream.quality}|${stream.release}|${stream.codec}',
            'filename': stream.fileName,
          },
        }).toList(),
        'filterStatus': {
          'usedFilters': false,
          'provider': 'AIOStreams',
        },
      };
    }

    return {
      ...fallbackResponse,
      'filterStatus': {
        'usedFilters': false,
        'provider': 'AIOStreams',
      },
    };
  }
}
