import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import '../providers/details_cast_provider.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import '../providers/watched_status_provider.dart';
import '../providers/streams_provider.dart';
import './stream_selection_screen.dart';
import 'dart:convert';
import 'dart:developer' as developer;

class MediaDetailsScreen extends HookConsumerWidget {
  final dynamic media;
  final bool isMovie;

  const MediaDetailsScreen({
    super.key,
    required this.media,
    required this.isMovie,
  });

  Future<void> _handlePlayButton(BuildContext context, WidgetRef ref, dynamic media, bool isMovie) async {
    try {
      final streams = await ref.read(
        streamsProvider(media, isMovie).future,
      );
      final prettyJson = const JsonEncoder.withIndent('  ').convert(streams);
      developer.log(
        'Streams data received',
        name: 'MediaDetailsScreen',
        error: prettyJson
      );
      
      if (context.mounted) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => StreamSelectionScreen(
              streamsData: streams,
              isMovie: isMovie,
              episodeId: isMovie ? null : media.id,
              showId: isMovie ? null : media.showId,
              seasonId: isMovie ? null : media.seasonId,
              episodeNumber: isMovie ? null : media.episodeNumber,
            ),
          ),
        );
      }
    } catch (e, stackTrace) {
      developer.log(
        'Failed to get streams',
        name: 'MediaDetailsScreen',
        error: e,
        stackTrace: stackTrace,
        level: 1000,
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scrollController = useScrollController();
    final isLoading = useState(false);
    
    useEffect(() {
      bool isDisposed = false;
      Future<void> autoScroll() async {
        if (isDisposed || !scrollController.hasClients) return;
        
        final maxScroll = scrollController.position.maxScrollExtent;
        if (maxScroll > 0) {
          while (!isDisposed) {
            if (!isDisposed) {
              await scrollController.animateTo(
                maxScroll,
                duration: Duration(seconds: maxScroll ~/ 30),
                curve: Curves.linear,
              );
            }
            
            if (!isDisposed) await Future.delayed(const Duration(seconds: 2));
            
            if (!isDisposed) scrollController.jumpTo(0);
            
            if (!isDisposed) await Future.delayed(const Duration(seconds: 2));
          }
        }
      }

      Future.delayed(const Duration(seconds: 1), autoScroll);

      return () {
        isDisposed = true;
      };
    }, []);

    Future<void> handlePlayWithLoading(BuildContext context) async {
      if (isLoading.value) return;
      
      isLoading.value = true;
      try {
        await _handlePlayButton(context, ref, media, isMovie);
      } finally {
        isLoading.value = false;
      }
    }

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.file(
              File('/storage/emulated/0/Debrid_Player/metadata/${isMovie ? 'movies' : 'tv'}/backdrops/${isMovie ? media.tmdbId : media.showId}/backdrop.webp'),
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                color: Colors.black,
              ),
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.6),
                    Colors.black.withOpacity(0.8),
                    Colors.black,
                  ],
                ),
              ),
            ),
          ),
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(4.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 1),
                    Text(
                      isMovie ? media.originalTitle : media.name,
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Row(
                      children: [
                        if (isMovie) ...[
                          _MetadataItem(
                            icon: Icons.calendar_today,
                            text: media.releaseDate,
                          ),
                          const SizedBox(width: 24),
                          _MetadataItem(
                            icon: Icons.timer,
                            text: '${media.runtime} min',
                          ),
                          const SizedBox(width: 24),
                          _MetadataItem(
                            icon: Icons.star,
                            text: '${media.voteAverage}/10',
                          ),
                        ] else ...[
                          _MetadataItem(
                            icon: Icons.tv,
                            text: 'Episode ${media.episodeNumber}',
                          ),
                          const SizedBox(width: 24),
                          _MetadataItem(
                            icon: Icons.calendar_today,
                            text: media.airDate,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Overview',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 180,
                      child: SingleChildScrollView(
                        controller: scrollController,
                        physics: const NeverScrollableScrollPhysics(),
                        child: Text(
                          media.overview,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Cast',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 100,
                      child: Consumer(
                        builder: (context, ref, child) {
                          final castAsync = isMovie 
                              ? ref.watch(detailsMovieCastProvider(media.tmdbId))
                              : ref.watch(detailsShowCastProvider(media.showId));
                              
                          return castAsync.when(
                            loading: () => const Center(
                              child: CircularProgressIndicator(
                                color: Colors.white,
                              ),
                            ),
                            error: (err, stack) => Text(
                              'Error loading cast: $err',
                              style: const TextStyle(color: Colors.white),
                            ),
                            data: (castList) => Row(
                              children: castList.map((actor) => Padding(
                                padding: const EdgeInsets.only(right: 16.0),
                                child: Column(
                                  children: [
                                    CircleAvatar(
                                      radius: 30,
                                      backgroundImage: FileImage(
                                        File('/storage/emulated/0/Debrid_Player/metadata/actors/${actor['actor_id']}/${actor['actor_id']}.webp'),
                                      ),
                                      onBackgroundImageError: (_, __) => const Icon(Icons.person, color: Colors.white),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      actor['name'] as String,
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: Colors.white.withOpacity(0.7),
                                      ),
                                    ),
                                  ],
                                ),
                              )).toList(),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Focus(
                          autofocus: true,
                          onKey: (node, event) {
                            if (event is RawKeyDownEvent &&
                                event.logicalKey == LogicalKeyboardKey.select) {
                              handlePlayWithLoading(context);
                              return KeyEventResult.handled;
                            }
                            return KeyEventResult.ignored;
                          },
                          child: Builder(
                            builder: (context) {
                              final focused = Focus.of(context).hasFocus;
                              return ElevatedButton.icon(
                                onPressed: () => handlePlayWithLoading(context),
                                icon: isLoading.value 
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.play_arrow),
                                label: Text(isLoading.value ? 'Loading...' : 'Play'),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 32,
                                    vertical: 16,
                                  ),
                                  backgroundColor: focused 
                                    ? Colors.blue.withOpacity(0.2) 
                                    : Colors.white.withOpacity(0.1),
                                  foregroundColor: focused ? Colors.blue : Colors.white,
                                  side: focused 
                                    ? const BorderSide(color: Colors.blue, width: 2)
                                    : null,
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Focus(
                          child: Builder(
                            builder: (context) {
                              final focused = Focus.of(context).hasFocus;
                              return Consumer(
                                builder: (context, ref, child) {
                                  final watchedStatus = ref.watch(
                                    watchedStatusProvider(
                                      isMovie ? media.tmdbId : media.id,
                                      isMovie,
                                    ),
                                  );

                                  return watchedStatus.when(
                                    loading: () => const ElevatedButton(
                                      onPressed: null,
                                      child: CircularProgressIndicator(),
                                    ),
                                    error: (_, __) => const ElevatedButton(
                                      onPressed: null,
                                      child: Text('Error'),
                                    ),
                                    data: (isWatched) => ElevatedButton.icon(
                                      onPressed: () {
                                        ref
                                            .read(
                                              watchedStatusProvider(
                                                isMovie ? media.tmdbId : media.id,
                                                isMovie,
                                              ).notifier,
                                            )
                                            .toggleWatched();
                                      },
                                      icon: Icon(
                                        isWatched ? Icons.check_circle : Icons.check,
                                        color: focused ? Colors.blue : Colors.white,
                                      ),
                                      label: Text(
                                        isWatched ? 'Mark as Unwatched' : 'Mark as Watched',
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 32,
                                          vertical: 16,
                                        ),
                                        backgroundColor: focused 
                                          ? Colors.blue.withOpacity(0.2) 
                                          : Colors.white.withOpacity(0.1),
                                        foregroundColor: focused ? Colors.blue : Colors.white,
                                        side: focused 
                                          ? const BorderSide(color: Colors.blue, width: 2)
                                          : null,
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetadataItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _MetadataItem({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          color: Colors.white.withOpacity(0.7),
          size: 16,
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.white.withOpacity(0.7),
          ),
        ),
      ],
    );
  }
} 