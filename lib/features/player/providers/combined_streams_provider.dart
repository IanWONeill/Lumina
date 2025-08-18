import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'dart:developer' as developer;
import './streams_provider.dart';
import './torrentio_streams_provider.dart';
import './aio_streams_provider.dart';
import '../../settings/providers/stream_providers_settings_provider.dart';
import '../../sync/services/database_service.dart';

part 'combined_streams_provider.g.dart';

@riverpod
Future<Map<String, dynamic>> combinedStreams(
  CombinedStreamsRef ref,
  dynamic media,
  bool isMovie,
) async {
  try {
    final orionoidEnabled = await ref.watch(orionoidEnabledProviderProvider.future);
    final torrentioEnabled = await ref.watch(torrentioEnabledProviderProvider.future);
    final aioStreamsEnabled = await ref.watch(aioStreamsEnabledProviderProvider.future);

    final futures = <Future<Map<String, dynamic>>>[];
    
    if (orionoidEnabled) {
      futures.add(ref.watch(streamsProvider(media, isMovie).future));
    }
    
    if (torrentioEnabled) {
      futures.add(ref.watch(torrentioStreamsProvider(media, isMovie).future));
    }
    
    if (aioStreamsEnabled) {
      futures.add(ref.watch(aioStreamsProvider(media, isMovie).future));
    }

    if (futures.isEmpty) {
      developer.log(
        'No stream providers enabled',
        name: 'CombinedStreamsProvider',
        error: {'orionoid': orionoidEnabled, 'torrentio': torrentioEnabled, 'aioStreams': aioStreamsEnabled},
      );
      return {
        'data': {'streams': []},
        'filterStatus': {
          'usedFilters': false,
          'providers': [],
        },
      };
    }

    final results = await Future.wait(futures);
    
    // Check if any streams were found
    int totalStreams = 0;
    int orionoidStreams = 0;
    int torrentioStreams = 0;
    int aioStreamsStreams = 0;
    List<Map<String, dynamic>> filterStatuses = [];
    
    int resultIndex = 0;
    
    if (orionoidEnabled) {
      final orionoidData = results[resultIndex++];
      final streams = orionoidData['data']?['streams'] as List<dynamic>?;
      orionoidStreams = streams?.length ?? 0;
      totalStreams += orionoidStreams;
      
      if (orionoidData['filterStatus'] != null) {
        filterStatuses.add(orionoidData['filterStatus'] as Map<String, dynamic>);
      }
    }
    
    if (torrentioEnabled) {
      final torrentioData = results[resultIndex++];
      final streams = torrentioData['streams'] as List<dynamic>?;
      torrentioStreams = streams?.length ?? 0;
      totalStreams += torrentioStreams;
      
      if (torrentioData['filterStatus'] != null) {
        filterStatuses.add(torrentioData['filterStatus'] as Map<String, dynamic>);
      }
    }
    
    if (aioStreamsEnabled) {
      final aioStreamsData = results[resultIndex++];
      final streams = aioStreamsData['streams'] as List<dynamic>?;
      aioStreamsStreams = streams?.length ?? 0;
      totalStreams += aioStreamsStreams;
      
      if (aioStreamsData['filterStatus'] != null) {
        filterStatuses.add(aioStreamsData['filterStatus'] as Map<String, dynamic>);
      }
    }
    
    // Determine overall filter status
    final allUsedFilters = filterStatuses.every((status) => status['usedFilters'] == true);
    final someUsedFilters = filterStatuses.any((status) => status['usedFilters'] == true);
    final noneUsedFilters = filterStatuses.every((status) => status['usedFilters'] == false);
    
    String overallFilterStatus;
    if (allUsedFilters) {
      overallFilterStatus = 'all_filtered';
    } else if (someUsedFilters) {
      overallFilterStatus = 'mixed';
    } else {
      overallFilterStatus = 'none_filtered';
    }
    
    developer.log(
      'Stream search results',
      name: 'CombinedStreamsProvider',
      error: {
        'totalStreams': totalStreams,
        'orionoidStreams': orionoidStreams,
        'torrentioStreams': torrentioStreams,
        'orionoidEnabled': orionoidEnabled,
        'torrentioEnabled': torrentioEnabled,
        'filterStatuses': filterStatuses,
        'overallFilterStatus': overallFilterStatus,
      },
    );
    
    if (totalStreams == 0) {
      developer.log(
        'No streams found from any provider',
        name: 'CombinedStreamsProvider',
        error: {
          'mediaType': isMovie ? 'movie' : 'show',
          'mediaId': isMovie ? media.tmdbId : media.id,
        },
      );
    }
    
    if (orionoidEnabled && !torrentioEnabled && !aioStreamsEnabled) {
      return results[0];
    }
    
    if (!orionoidEnabled && torrentioEnabled && !aioStreamsEnabled) {
      final torrentioData = results[0];
      
      final torrentioStreamsList = (torrentioData['streams'] as List<dynamic>)
          .map((stream) {
            final quality = stream['name'].toString().contains('1080p') 
                ? 'hd1080' 
                : stream['name'].toString().contains('720p') 
                    ? 'hd720' 
                    : 'sd';
                    
            final sizeMatch = RegExp(r'(?:\s|^)(\d+(?:\.\d+)?)\s*(GB|MB)')
                .firstMatch(stream['title'].toString());
            
            final fileSize = sizeMatch != null 
                ? '${sizeMatch.group(1)} ${sizeMatch.group(2)}'
                : '0 MB';
                
            final sizeInBytes = _convertToBytes(fileSize);

            developer.log(
              'Parsed Torrentio stream size',
              name: 'CombinedStreamsProvider',
              error: {
                'title': stream['title'],
                'extracted': fileSize,
                'bytes': sizeInBytes,
              },
            );

            return {
              'id': stream['url'],
              'links': [stream['url']],
              'file': {
                'name': stream['behaviorHints']['filename'],
                'size': sizeInBytes,
                'pack': false,
              },
              'video': {
                'quality': quality,
                'codec': 'h264',
                '3d': false,
              },
              'audio': {
                'type': 'standard',
                'channels': 2,
                'system': 'aac',
                'codec': 'aac',
                'languages': ['en'],
              },
              'access': {
                'direct': true,
                'premiumize': true,
              },
              'stream': {
                'type': 'torrent',
                'source': 'Torrentio',
              },
            };
          })
          .toList();

      return {
        'data': {
          'type': isMovie ? 'movie' : 'show',
          'movie': isMovie ? {
            'id': {
              'orion': 'torrentio_${media.tmdbId}',
              'tmdb': media.tmdbId.toString(),
            },
            'meta': {
              'title': media.originalTitle,
            },
          } : null,
          'episode': !isMovie ? {
            'id': {
              'orion': 'torrentio_${media.id}',
            },
            'number': {
              'season': await _getSeasonNumber(media.seasonId),
              'episode': media.episodeNumber,
            },
          } : null,
          'show': !isMovie ? {
            'meta': {
              'title': await _getShowTitle(media.showId),
            },
          } : null,
          'streams': torrentioStreamsList,
        },
        'filterStatus': {
          'overallStatus': torrentioData['filterStatus']?['usedFilters'] == true ? 'all_filtered' : 'none_filtered',
          'providers': [torrentioData['filterStatus']?['provider'] ?? 'Torrentio'],
          'details': [torrentioData['filterStatus'] ?? {'provider': 'Torrentio', 'usedFilters': false}],
        },
      };
    }
    
    if (!orionoidEnabled && !torrentioEnabled && aioStreamsEnabled) {
      final aioStreamsData = results[0];
      
      final aioStreamsList = (aioStreamsData['streams'] as List<dynamic>)
          .map((stream) {
            final quality = stream['name'].toString().contains('1080p') 
                ? 'hd1080' 
                : stream['name'].toString().contains('720p') 
                    ? 'hd720' 
                    : 'sd';
                    
            final sizeMatch = RegExp(r'(?:\s|^)(\d+(?:\.\d+)?)\s*(GB|MB)')
                .firstMatch(stream['title'].toString());
            
            final fileSize = sizeMatch != null 
                ? '${sizeMatch.group(1)} ${sizeMatch.group(2)}'
                : '0 MB';
                
            final sizeInBytes = _convertToBytes(fileSize);

            developer.log(
              'Parsed AIOStreams stream size',
              name: 'CombinedStreamsProvider',
              error: {
                'title': stream['title'],
                'extracted': fileSize,
                'bytes': sizeInBytes,
              },
            );

            return {
              'id': stream['url'],
              'links': [stream['url']],
              'file': {
                'name': stream['behaviorHints']['filename'],
                'size': sizeInBytes,
                'pack': false,
              },
              'video': {
                'quality': quality,
                'codec': 'h264',
                '3d': false,
              },
              'audio': {
                'type': 'standard',
                'channels': 2,
                'system': 'aac',
                'codec': 'aac',
                'languages': ['en'],
              },
              'access': {
                'direct': true,
                'premiumize': true,
              },
                          'stream': {
              'type': 'torrent',
              'source': 'aiostreams',
            },
            };
          })
          .toList();

      return {
        'data': {
          'type': isMovie ? 'movie' : 'show',
          'movie': isMovie ? {
            'id': {
              'orion': 'aiostreams_${media.tmdbId}',
              'tmdb': media.tmdbId.toString(),
            },
            'meta': {
              'title': media.originalTitle,
            },
          } : null,
          'episode': !isMovie ? {
            'id': {
              'orion': 'aiostreams_${media.id}',
            },
            'number': {
              'season': await _getSeasonNumber(media.seasonId),
              'episode': media.episodeNumber,
            },
          } : null,
          'show': !isMovie ? {
            'meta': {
              'title': await _getShowTitle(media.showId),
            },
          } : null,
          'streams': aioStreamsList,
        },
        'filterStatus': {
          'overallStatus': aioStreamsData['filterStatus']?['usedFilters'] == true ? 'all_filtered' : 'none_filtered',
          'providers': [aioStreamsData['filterStatus']?['provider'] ?? 'AIOStreams'],
          'details': [aioStreamsData['filterStatus'] ?? {'provider': 'AIOStreams', 'usedFilters': false}],
        },
      };
    }
    
    // Handle multiple providers - determine which results to use
    Map<String, dynamic>? orionoidData;
    Map<String, dynamic>? torrentioData;
    Map<String, dynamic>? aioStreamsData;
    
    if (orionoidEnabled) {
      orionoidData = results[0];
    }
    if (torrentioEnabled) {
      torrentioData = orionoidEnabled ? results[1] : results[0];
    }
    if (aioStreamsEnabled) {
      if (orionoidEnabled && torrentioEnabled) {
        aioStreamsData = results[2];
      } else if (orionoidEnabled || torrentioEnabled) {
        aioStreamsData = results[1];
      } else {
        aioStreamsData = results[0];
      }
    }

    final torrentioStreamsList = torrentioData != null ? (torrentioData['streams'] as List<dynamic>)
        .map((stream) {
          final quality = stream['name'].toString().contains('1080p') 
              ? 'hd1080' 
              : stream['name'].toString().contains('720p') 
                  ? 'hd720' 
                  : 'sd';
                  
          final sizeMatch = RegExp(r'(?:\s|^)(\d+(?:\.\d+)?)\s*(GB|MB)')
              .firstMatch(stream['title'].toString());
          
          final fileSize = sizeMatch != null 
              ? '${sizeMatch.group(1)} ${sizeMatch.group(2)}'
              : '0 MB';
              
          final sizeInBytes = _convertToBytes(fileSize);

          developer.log(
            'Parsed Torrentio stream size',
            name: 'CombinedStreamsProvider',
            error: {
              'title': stream['title'],
              'extracted': fileSize,
              'bytes': sizeInBytes,
            },
          );

          return {
            'id': stream['url'],
            'links': [stream['url']],
            'file': {
              'name': stream['behaviorHints']['filename'],
              'size': sizeInBytes,
              'pack': false,
            },
            'video': {
              'quality': quality,
              'codec': 'h264',
              '3d': false,
            },
            'audio': {
              'type': 'standard',
              'channels': 2,
              'system': 'aac',
              'codec': 'aac',
              'languages': ['en'],
            },
            'access': {
              'direct': true,
              'premiumize': true,
            },
            'stream': {
              'type': 'torrent',
              'source': 'Torrentio',
            },
          };
        })
        .toList() : <Map<String, dynamic>>[];

    final aioStreamsList = aioStreamsData != null ? (aioStreamsData['streams'] as List<dynamic>)
        .map((stream) {
          final quality = stream['name'].toString().contains('1080p') 
              ? 'hd1080' 
              : stream['name'].toString().contains('720p') 
                  ? 'hd720' 
                  : 'sd';
                  
          final sizeMatch = RegExp(r'(?:\s|^)(\d+(?:\.\d+)?)\s*(GB|MB)')
              .firstMatch(stream['title'].toString());
          
          final fileSize = sizeMatch != null 
              ? '${sizeMatch.group(1)} ${sizeMatch.group(2)}'
              : '0 MB';
              
          final sizeInBytes = _convertToBytes(fileSize);

          developer.log(
            'Parsed AIOStreams stream size (combined)',
            name: 'CombinedStreamsProvider',
            error: {
              'title': stream['title'],
              'extracted': fileSize,
              'bytes': sizeInBytes,
            },
          );

          return {
            'id': stream['url'],
            'links': [stream['url']],
            'file': {
              'name': stream['behaviorHints']['filename'],
              'size': sizeInBytes,
              'pack': false,
            },
            'video': {
              'quality': quality,
              'codec': 'h264',
              '3d': false,
            },
            'audio': {
              'type': 'standard',
              'channels': 2,
              'system': 'aac',
              'codec': 'aac',
              'languages': ['en'],
            },
            'access': {
              'direct': true,
              'premiumize': true,
            },
            'stream': {
              'type': 'torrent',
              'source': 'aiostreams',
            },
          };
        })
        .toList() : <Map<String, dynamic>>[];

    if (orionoidData != null && orionoidData['data']?['streams'] != null) {
      final List<dynamic> existingStreams = orionoidData['data']['streams'];
      existingStreams.addAll(torrentioStreamsList);
      existingStreams.addAll(aioStreamsList);
      
      developer.log(
        'Combined streams count',
        name: 'CombinedStreamsProvider',
        error: {
          'orionoid': existingStreams.length - torrentioStreamsList.length - aioStreamsList.length,
          'torrentio': torrentioStreamsList.length,
          'aioStreams': aioStreamsList.length,
          'total': existingStreams.length,
        },
      );
      
      return {
        ...orionoidData,
        'filterStatus': {
          'overallStatus': overallFilterStatus,
          'providers': filterStatuses.map((status) => status['provider'] as String).toList(),
          'details': filterStatuses,
        },
      };
    } else {
      // Combine Torrentio and AIOStreams streams when no Orionoid data
      final List<dynamic> combinedStreams = <dynamic>[];
      combinedStreams.addAll(torrentioStreamsList);
      combinedStreams.addAll(aioStreamsList);
      
      // Determine the primary provider for the ID
      String primaryProvider = 'torrentio';
      if (torrentioStreamsList.isEmpty && aioStreamsList.isNotEmpty) {
        primaryProvider = 'aiostreams';
      }
      
      return {
        'data': {
          'type': isMovie ? 'movie' : 'show',
          'movie': isMovie ? {
            'id': {
              'orion': '${primaryProvider}_${media.tmdbId}',
              'tmdb': media.tmdbId.toString(),
            },
            'meta': {
              'title': media.originalTitle,
            },
          } : null,
          'episode': !isMovie ? {
            'id': {
              'orion': '${primaryProvider}_${media.id}',
            },
            'number': {
              'season': await _getSeasonNumber(media.seasonId),
              'episode': media.episodeNumber,
            },
          } : null,
          'show': !isMovie ? {
            'meta': {
              'title': await _getShowTitle(media.showId),
            },
          } : null,
          'streams': combinedStreams,
        },
        'filterStatus': {
          'overallStatus': overallFilterStatus,
          'providers': filterStatuses.map((status) => status['provider'] as String).toList(),
          'details': filterStatuses,
        },
      };
    }
  } catch (e, stackTrace) {
    developer.log(
      'Error combining streams',
      name: 'CombinedStreamsProvider',
      error: e,
      stackTrace: stackTrace,
      level: 1000,
    );
    rethrow;
  }
}

int _convertToBytes(String sizeString) {
  final value = double.tryParse(
    sizeString.replaceAll(RegExp(r'[^0-9.]'), '')
  ) ?? 0.0;
  
  final isGB = sizeString.toUpperCase().contains('GB');
  if (isGB) {
    return (value * 1024 * 1024 * 1024).round();
  } else {
    return (value * 1024 * 1024).round();
  }
}

Future<int> _getSeasonNumber(int seasonId) async {
  final db = DatabaseService();
  final seasonDetails = await db.getSeasonDetails(seasonId);
  return seasonDetails?['season_number'] ?? 0;
}

Future<String> _getShowTitle(int showId) async {
  final db = DatabaseService();
  final showDetails = await db.getTVShowDetails(showId);
  return showDetails?['name'] ?? 'Unknown Show';
} 