import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'dart:developer' as developer;
import '../providers/movies_provider.dart';

class MoviePosterPanel extends HookConsumerWidget {
  const MoviePosterPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedMovie = ref.watch(selectedMovieProvider);
    final movies = ref.watch(moviesProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: movies.when(
            loading: () => const Text('Loading...'),
            error: (err, stack) => const Text('Error loading movies'),
            data: (moviesList) => Text(
              '${moviesList.length} Movies',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
        ),
        Expanded(
          child: Center(
            child: Builder(
              builder: (context) {
                if (selectedMovie == null) {
                  return const Text('No movie selected');
                }

                final posterFile = selectedMovie.posterFile;

                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (posterFile != null && posterFile.existsSync())
                      Image.file(
                        posterFile,
                        height: 450,
                        width: 300,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          developer.log(
                            'Error loading image: $error',
                            name: 'MoviePosterPanel',
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
                    if (selectedMovie.watchProgress > 0)
                      LinearProgressIndicator(
                        value: selectedMovie.watchProgress / 100,
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