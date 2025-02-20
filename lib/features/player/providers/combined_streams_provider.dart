import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'dart:developer' as developer;
import './streams_provider.dart';
import './torrentio_streams_provider.dart';
import '../../settings/providers/stream_providers_settings_provider.dart';

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

    final futures = <Future<Map<String, dynamic>>>[];
    
    if (orionoidEnabled) {
      futures.add(ref.watch(streamsProvider(media, isMovie).future));
    }
    
    if (torrentioEnabled) {
      futures.add(ref.watch(torrentioStreamsProvider(media, isMovie).future));
    }

    if (futures.isEmpty) {
      return {'data': {'streams': []}};
    }

    final results = await Future.wait(futures);
    
    if (orionoidEnabled && !torrentioEnabled) {
      return results[0];
    }
    
    if (!orionoidEnabled && torrentioEnabled) {
      final torrentioData = results[0];
      
      final torrentioStreams = (torrentioData['streams'] as List<dynamic>)
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
              'season': media.seasonNumber,
            },
          } : null,
          'streams': torrentioStreams,
        },
      };
    }
    
    final orionoidData = results[0];
    final torrentioData = results[1];

    final torrentioStreams = (torrentioData['streams'] as List<dynamic>)
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

    if (orionoidData['data']?['streams'] != null) {
      final List<dynamic> existingStreams = orionoidData['data']['streams'];
      existingStreams.addAll(torrentioStreams);
      
      developer.log(
        'Combined streams count',
        name: 'CombinedStreamsProvider',
        error: {
          'orionoid': existingStreams.length - torrentioStreams.length,
          'torrentio': torrentioStreams.length,
          'total': existingStreams.length,
        },
      );
      
      return orionoidData;
    } else {
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
              'season': media.seasonNumber,
            },
          } : null,
          'streams': torrentioStreams,
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