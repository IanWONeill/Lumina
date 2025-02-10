import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import '../providers/genre_results_provider.dart';
import 'package:flutter/services.dart';
import '../../player/screens/media_details_screen.dart';
import 'dart:developer' as developer;
import '../../movies/models/movie.dart';

class GenreListPanel extends HookConsumerWidget {
  const GenreListPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final movies = ref.watch(searchResultsProvider);
    final itemScrollController = useMemoized(() => ItemScrollController());
    
    return ScrollablePositionedList.builder(
      itemCount: movies.length,
      itemScrollController: itemScrollController,
      itemBuilder: (context, index) {
        final movieData = movies[index];
        return Focus(
          autofocus: index == 0,
          onFocusChange: (hasFocus) {
            if (hasFocus) {
              ref.read(selectedGenreMovieProvider.notifier).state = movieData;
            }
          },
          onKey: (node, event) {
            if (event is RawKeyDownEvent && 
                event.logicalKey == LogicalKeyboardKey.select) {
              try {
                developer.log(
                  'Raw movie data before conversion',
                  name: 'GenreListPanel',
                  error: {
                    'id': movieData['id'],
                    'tmdb_id': movieData['tmdb_id'],
                    'original_title': movieData['original_title'],
                    'overview': movieData['overview'],
                    'release_date': movieData['release_date'],
                    'runtime': movieData['runtime'],
                    'vote_average': movieData['vote_average'],
                    'revenue': movieData['revenue'],
                    'poster_path': movieData['poster_path'],
                    'backdrop_path': movieData['backdrop_path'],
                    'is_watched': movieData['is_watched'],
                    'watch_progress': movieData['watch_progress'],
                  },
                );

                final movie = Movie.fromMap(movieData);

                developer.log(
                  'Movie data after conversion',
                  name: 'GenreListPanel',
                  error: {
                    'id': movie.id,
                    'tmdbId': movie.tmdbId,
                    'originalTitle': movie.originalTitle,
                    'isWatched': movie.isWatched,
                    'watchProgress': movie.watchProgress,
                  },
                );

                Future(() {
                  if (context.mounted) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MediaDetailsScreen(
                          media: movie,
                          isMovie: true,
                        ),
                      ),
                    );
                  }
                });

              } catch (e, stackTrace) {
                developer.log(
                  'Error converting movie data',
                  name: 'GenreListPanel',
                  error: e,
                  stackTrace: stackTrace,
                  level: 1000,
                );
              }
              return KeyEventResult.handled;
            }
            return KeyEventResult.ignored;
          },
          child: Builder(
            builder: (context) {
              final focused = Focus.of(context).hasFocus;
              return Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  color: focused ? Colors.blue.withOpacity(0.2) : null,
                  border: focused 
                    ? Border.all(color: Colors.blue, width: 2)
                    : null,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        movieData['original_title'],
                        style: TextStyle(
                          fontSize: 16,
                          color: focused ? Colors.blue : null,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (movieData['is_watched'] == 1)
                      const Icon(
                        Icons.check_circle,
                        size: 16,
                        color: Colors.green,
                      ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
} 