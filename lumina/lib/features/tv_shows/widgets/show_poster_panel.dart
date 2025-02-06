import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'dart:developer' as developer;
import '../providers/tv_shows_provider.dart';

class ShowPosterPanel extends HookConsumerWidget {
  const ShowPosterPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedShow = ref.watch(selectedTVShowProvider);
    final shows = ref.watch(tVShowsProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: shows.when(
            loading: () => const Text('Loading...'),
            error: (err, stack) {
              developer.log(
                'Error loading TV shows list',
                name: 'ShowPosterPanel',
                error: err.toString(),
                stackTrace: stack,
                level: 1000,
              );
              return const Text('Error loading shows');
            },
            data: (showsList) => Text(
              '${showsList.length} TV Shows',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
        ),
        Expanded(
          child: Center(
            child: Builder(
              builder: (context) {
                if (selectedShow == null) {
                  return const Text('No show selected');
                }

                final posterFile = selectedShow.posterFile;

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
                            'Error loading show poster',
                            name: 'ShowPosterPanel',
                            error: {
                              'showId': selectedShow.tmdbId,
                              'posterPath': posterFile.path,
                              'error': error.toString(),
                            },
                            stackTrace: stackTrace,
                            level: 1000,
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
                          child: Icon(Icons.tv, size: 100),
                        ),
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