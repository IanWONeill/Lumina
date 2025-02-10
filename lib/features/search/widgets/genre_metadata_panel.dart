import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../providers/genre_results_provider.dart';
import 'dart:io';

class GenreMetadataPanel extends HookConsumerWidget {
  const GenreMetadataPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedMovie = ref.watch(selectedGenreMovieProvider);

    if (selectedMovie == null) {
      return const Center(child: Text('No movie selected'));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 8.0),
          child: Text(
            selectedMovie['original_title'],
            style: Theme.of(context).textTheme.headlineMedium,
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Release Date: ${selectedMovie['release_date']}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Text(
                  'Runtime: ${selectedMovie['runtime']} minutes',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Text(
                  'Rating: ${selectedMovie['vote_average']}/10',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                if ((selectedMovie['revenue'] ?? 0) > 0)
                  Text(
                    'Revenue: \$${(selectedMovie['revenue'] / 1000000).toStringAsFixed(1)}M',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                const SizedBox(height: 4),
                const Divider(
                  height: 1,
                  thickness: 1,
                  color: Colors.grey,
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: SingleChildScrollView(
                    child: Text(
                      selectedMovie['overview'] ?? '',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
} 