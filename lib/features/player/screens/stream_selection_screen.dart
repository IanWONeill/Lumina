import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../models/stream_info.dart';
import '../../settings/providers/orionoid_provider.dart';
import 'package:android_intent_plus/android_intent.dart';
import '../providers/just_player_broadcast_provider.dart';
import '../../database/providers/database_provider.dart';
import 'dart:developer' as developer;

class SelectIntent extends Intent {
  const SelectIntent();
}

class SelectAction extends Action<SelectIntent> {
  final VoidCallback onSelect;
  
  SelectAction(this.onSelect);
  
  @override
  Object? invoke(SelectIntent intent) {
    onSelect();
    return null;
  }
}

class StreamSelectionScreen extends ConsumerWidget {
  final Map<String, dynamic> streamsData;
  final bool isMovie;
  final int? episodeId;
  final int? showId;
  final int? seasonId;
  final int? episodeNumber;

  const StreamSelectionScreen({
    super.key,
    required this.streamsData,
    required this.isMovie,
    this.episodeId,
    this.showId,
    this.seasonId,
    this.episodeNumber,
  });

  List<StreamInfo> _parseStreams(Map<String, dynamic> data) {
    try {
      final streams = data['data']['streams'] as List;
      String orionId;
      String showTitle = '';
      int seasonNumber = 1;
      
      if (data['data']['episode'] != null) {
        orionId = data['data']['episode']['id']['orion'] as String;
        showTitle = data['data']['show']['meta']['title'] as String;
        seasonNumber = data['data']['episode']['number']['season'] as int;
      } else if (data['data']['movie'] != null) {
        orionId = data['data']['movie']['id']['orion'] as String;
      } else {
        developer.log(
          'Could not find orionId in data structure',
          name: 'StreamSelectionScreen',
          level: 1000,
        );
        return [];
      }
      
      return streams.map((stream) {
        if (stream == null) {
          developer.log(
            'Null stream data encountered',
            name: 'StreamSelectionScreen',
            level: 900,
          );
          return null;
        }
        
        try {
          final streamId = stream['id'] as String;
          
          final enrichedStream = {
            ...stream as Map<String, dynamic>,
            'orionId': orionId,
            'id': streamId,
            'show': data['data']['show'],
          };

          final streamInfo = StreamInfo.fromJson(enrichedStream);

          if (!isMovie) {
            if (!streamInfo.isValidForShow(showTitle)) {
              developer.log(
                'Skipping stream for wrong show',
                name: 'StreamSelectionScreen',
                error: {'fileName': streamInfo.fileName}
              );
              return null;
            }

            if (streamInfo.isPack) {
              final fileName = streamInfo.fileName.toLowerCase();
              
              bool isCorrectSeason = false;
              
              if (fileName.contains('complete series') || 
                  fileName.contains('season 1-') ||
                  fileName.contains('s01-')) {
                isCorrectSeason = true;
              } 
              else {
                final seasonPatterns = [
                  's(eason)?\\s*0?$seasonNumber\\b',
                  '\\bs0?$seasonNumber\\b',
                  'season\\s*0?$seasonNumber\\b',
                  'temporada\\s*0?$seasonNumber\\b',
                  '$seasonNumber(st|nd|rd|th|ª)\\s*temporada',
                ];
                
                isCorrectSeason = seasonPatterns.any((pattern) => 
                  RegExp(pattern, caseSensitive: false).hasMatch(fileName));
              }
              
              if (!isCorrectSeason) {
                developer.log(
                  'Skipping pack from wrong season',
                  name: 'StreamSelectionScreen',
                  error: {'fileName': streamInfo.fileName}
                );
                return null;
              }
              
              developer.log(
                'Found matching season pack',
                name: 'StreamSelectionScreen',
                error: {'fileName': streamInfo.fileName}
              );
            }
          }
          
          return streamInfo;
        } catch (e, stackTrace) {
          developer.log(
            'Error parsing individual stream',
            name: 'StreamSelectionScreen',
            error: e,
            stackTrace: stackTrace,
            level: 1000,
          );
          return null;
        }
      })
      .whereType<StreamInfo>()
      .toList();
    } catch (e, stackTrace) {
      developer.log(
        'Error parsing streams',
        name: 'StreamSelectionScreen',
        error: e,
        stackTrace: stackTrace,
        level: 1000,
      );
      developer.log(
        'Data structure keys',
        name: 'StreamSelectionScreen',
        error: data.keys,
      );
      return [];
    }
  }

  Future<void> _handleStreamSelection(
    BuildContext context,
    WidgetRef ref,
    StreamInfo stream,
  ) async {
    try {
      final int mediaId;
      if (isMovie) {
        final tmdbId = streamsData['data']['movie']['id']['tmdb'];
        final parsedId = int.tryParse(tmdbId.toString());
        if (parsedId == null) {
          throw Exception('Invalid movie TMDB ID');
        }
        mediaId = parsedId;
      } else {
        if (episodeId == null) {
          throw Exception('Episode ID is required but was null');
        }
        mediaId = episodeId!;
      }

      final db = await ref.read(databaseServiceProvider).database;
      final Map<String, dynamic>? mediaProgress;
      if (isMovie) {
        mediaProgress = await db.query(
          'movies',
          columns: ['watch_progress'],
          where: 'tmdb_id = ?',
          whereArgs: [mediaId],
          limit: 1,
        ).then((result) => result.isNotEmpty ? result.first : null);
      } else {
        mediaProgress = await db.query(
          'episodes',
          columns: ['watch_progress'],
          where: 'id = ?',
          whereArgs: [mediaId],
          limit: 1,
        ).then((result) => result.isNotEmpty ? result.first : null);
      }

      final int? watchProgress = mediaProgress?['watch_progress'] as int?;
      
      int startPosition = 0;
      if (watchProgress != null && watchProgress > 0) {
        if (!context.mounted) return;
        bool? result;
        try {
          result = await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (context) => WillPopScope(
              onWillPop: () async {
                developer.log(
                  'WillPopScope triggered',
                  name: 'StreamSelectionScreen',
                );
                Navigator.of(context).pop();
                return false;
              },
              child: AlertDialog(
                backgroundColor: Colors.black87,
                title: const Text(
                  'Resume Playback?',
                  style: TextStyle(color: Colors.white),
                ),
                content: Text(
                  'Would you like to resume from where you left off?',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 17,
                    ),
                ),
                actions: [
                  FocusableActionDetector(
                    autofocus: true,
                    shortcuts: {
                      SingleActivator(LogicalKeyboardKey.select): const SelectIntent(),
                    },
                    actions: {
                      SelectIntent: SelectAction(() {
                        developer.log(
                          'Start Over selected via action',
                          name: 'StreamSelectionScreen',
                        );
                        Navigator.of(context).pop(false);
                      }),
                    },
                    child: Builder(
                      builder: (context) {
                        final focused = Focus.of(context).hasFocus;
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: focused ? Colors.blue.withOpacity(0.2) : Colors.transparent,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Start Over',
                            style: TextStyle(
                              color: focused ? Colors.blue : Colors.white,
                              fontSize: 21,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  FocusableActionDetector(
                    autofocus: false,
                    shortcuts: {
                      SingleActivator(LogicalKeyboardKey.select): const SelectIntent(),
                    },
                    actions: {
                      SelectIntent: SelectAction(() {
                        developer.log(
                          'Resume selected via action',
                          name: 'StreamSelectionScreen',
                        );
                        Navigator.of(context).pop(true);
                      }),
                    },
                    child: Builder(
                      builder: (context) {
                        final focused = Focus.of(context).hasFocus;
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: focused ? Colors.blue.withOpacity(0.2) : Colors.transparent,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Resume',
                            style: TextStyle(
                              color: focused ? Colors.blue : Colors.white,
                              fontSize: 21,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
          
          developer.log(
            'Dialog result',
            name: 'StreamSelectionScreen',
            error: {'result': result},
          );
          
          if (result == null) {
            developer.log(
              'Dialog was dismissed',
              name: 'StreamSelectionScreen',
            );
            return;
          } else if (result == true) {
            developer.log(
              'Setting start position',
              name: 'StreamSelectionScreen',
              error: {'position': watchProgress},
            );
            startPosition = watchProgress;
          } else {
            developer.log(
              'Setting start position to 0 (Start Over)',
              name: 'StreamSelectionScreen',
            );
            startPosition = 0;
          }
        } catch (e, stackTrace) {
          developer.log(
            'Error in dialog',
            name: 'StreamSelectionScreen',
            error: e,
            stackTrace: stackTrace,
            level: 1000,
          );
          return;
        }
      }

      if (!context.mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: Card(
            color: Colors.black87,
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Colors.blue),
                  SizedBox(height: 16),
                  Text(
                    'Preparing stream...',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      final orionService = ref.read(orionoidServiceProvider);
      final token = await ref.read(orionoidAuthProvider.future);
      
      if (token == null) {
        throw Exception('No Orionoid token found');
      }

      int? actualSeasonNumber;
      if (!isMovie && seasonId != null) {
        final seasonDetails = await db.query(
          'seasons',
          columns: ['season_number'],
          where: 'id = ?',
          whereArgs: [seasonId],
          limit: 1,
        );
        if (seasonDetails.isNotEmpty) {
          actualSeasonNumber = seasonDetails.first['season_number'] as int;
        }
      }

      final streamUrl = await orionService.resolveDebridLink(
        token: token,
        orionId: stream.orionId,
        streamId: stream.id,
        seasonNumber: isMovie ? null : actualSeasonNumber,
        episodeNumber: isMovie ? null : episodeNumber,
      );
      
      if (streamUrl == null || streamUrl.isEmpty) {
        throw Exception('Failed to resolve stream URL');
      }

      final playerService = ref.read(justPlayerBroadcastServiceProvider);
      playerService.setCurrentMedia(
        mediaId: mediaId,
        type: isMovie ? 'movie' : 'episode',
      );

      developer.log(
        'Launching player',
        name: 'StreamSelectionScreen',
        error: {
          'streamUrl': streamUrl,
          'mediaType': isMovie ? 'movie' : 'episode',
          'mediaId': mediaId,
          'startPosition': startPosition,
        },
      );

      final intent = AndroidIntent(
        action: 'action_view',
        data: streamUrl,
        package: 'com.brouken.player',
        type: 'video/*',
        arguments: {
          'position': startPosition,
        },
      );

      developer.log(
        'Intent Configuration',
        name: 'StreamSelectionScreen',
        error: {
          'action': intent.action,
          'package': intent.package,
          'type': intent.type,
          'arguments': intent.arguments,
        },
      );

      if (context.mounted) {
        Navigator.of(context).pop();
      }

      await intent.launch();
      developer.log(
        'Intent launched successfully',
        name: 'StreamSelectionScreen',
      );
      
    } catch (e, stackTrace) {
      if (context.mounted) {
        Navigator.of(context).pop();
      }
      
      developer.log(
        'Stream selection error',
        name: 'StreamSelectionScreen',
        error: e,
        stackTrace: stackTrace,
        level: 1000,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to play stream: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streams = _parseStreams(streamsData);
    
    if (streams.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.search_off,
                color: Colors.white,
                size: 64,
              ),
              const SizedBox(height: 16),
              Text(
                'No Streams Found',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Try again later or check another title',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Stream',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView.builder(
                itemCount: streams.length,
                itemBuilder: (context, index) {
                  final stream = streams[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Focus(
                      autofocus: index == 0,
                      onKey: (node, event) {
                        if (event is RawKeyDownEvent &&
                            event.logicalKey == LogicalKeyboardKey.select) {
                          _handleStreamSelection(context, ref, stream);
                          return KeyEventResult.handled;
                        }
                        return KeyEventResult.ignored;
                      },
                      child: Builder(
                        builder: (context) {
                          final focused = Focus.of(context).hasFocus;
                          return Container(
                            decoration: BoxDecoration(
                              color: focused 
                                ? Colors.blue.withOpacity(0.2) 
                                : Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: focused
                                ? Border.all(color: Colors.blue, width: 2)
                                : null,
                            ),
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  stream.fileName,
                                  style: TextStyle(
                                    color: focused ? Colors.blue : Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Text(
                                      stream.fileSize,
                                      style: TextStyle(
                                        color: (focused ? Colors.blue : Colors.white)
                                            .withOpacity(0.7),
                                        fontSize: 14,
                                      ),
                                    ),
                                    Text(
                                      ' • ',
                                      style: TextStyle(
                                        color: (focused ? Colors.blue : Colors.white)
                                            .withOpacity(0.7),
                                        fontSize: 14,
                                      ),
                                    ),
                                    Text(
                                      stream.qualityLabel,
                                      style: TextStyle(
                                        color: (focused ? Colors.blue : Colors.white)
                                            .withOpacity(0.7),
                                        fontSize: 14,
                                      ),
                                    ),
                                    if (stream.hdrFormats.isNotEmpty) ...[
                                      for (final format in stream.hdrFormats) ...[
                                        Text(
                                          ' • ',
                                          style: TextStyle(
                                            color: (focused ? Colors.blue : Colors.white)
                                                .withOpacity(0.7),
                                            fontSize: 14,
                                          ),
                                        ),
                                        Text(
                                          format,
                                          style: TextStyle(
                                            color: (focused ? Colors.blue : Colors.white)
                                                .withOpacity(0.7),
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ],
                                    Text(
                                      ' • ',
                                      style: TextStyle(
                                        color: (focused ? Colors.blue : Colors.white)
                                            .withOpacity(0.7),
                                        fontSize: 14,
                                      ),
                                    ),
                                    Text(
                                      stream.isAtmos 
                                          ? 'Atmos' 
                                          : '${stream.audioChannels}.1',
                                      style: TextStyle(
                                        color: (focused ? Colors.blue : Colors.white)
                                            .withOpacity(0.7),
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Source: ${stream.source}',
                                  style: TextStyle(
                                    color: (focused ? Colors.blue : Colors.white)
                                        .withOpacity(0.7),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
} 