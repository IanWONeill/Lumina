import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'dart:developer' as developer;
import '../providers/genre_results_provider.dart';
import 'dart:io';

class GenrePosterPanel extends HookConsumerWidget {
  const GenrePosterPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedMovie = ref.watch(selectedGenreMovieProvider);
    final movies = ref.watch(searchResultsProvider);
    final genreName = ModalRoute.of(context)?.settings.arguments as String? ?? 
                     'Genre';

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            '${movies.length} $genreName Results',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        Expanded(
          child: Center(
            child: Builder(
              builder: (context) {
                if (selectedMovie == null) {
                  return const Text('No movie selected');
                }

                final posterFile = File('/storage/emulated/0/Debrid_Player/metadata/movies/posters/${selectedMovie['tmdb_id']}/poster.webp');

                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (posterFile.existsSync())
                      Image.file(
                        posterFile,
                        height: 450,
                        width: 300,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          developer.log(
                            'Error loading image: $error',
                            name: 'GenrePosterPanel',
                            error: error,
                            stackTrace: stackTrace,
                          );
                          return const SizedBox(
                            height: 450,
                            width: 300,
                            child: Center(
                              child: Icon(Icons.error, size: 100),
                            ),
                          );
                        },
                      )
                    else
                      const SizedBox(
                        height: 450,
                        width: 300,
                        child: Center(
                          child: Icon(Icons.movie, size: 100),
                        ),
                      ),
                    if (selectedMovie['watch_progress'] != null)
                      LinearProgressIndicator(
                        value: selectedMovie['watch_progress'] / 100,
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }
} 