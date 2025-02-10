import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../providers/movies_provider.dart';
import '../providers/cast_provider.dart';
import 'dart:io';
import '../../sync/services/database_service.dart';

class MovieMetadataPanel extends HookConsumerWidget {
  const MovieMetadataPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedMovie = ref.watch(selectedMovieProvider);

    if (selectedMovie == null) {
      return const Center(child: Text('No movie selected'));
    }

    final cast = ref.watch(movieCastProvider(selectedMovie.id));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                selectedMovie.originalTitle,
                style: Theme.of(context).textTheme.headlineMedium,
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
              Consumer(
                builder: (context, ref, child) {
                  final genres = ref.watch(movieGenresProvider(selectedMovie.tmdbId));
                  return genres.when(
                    data: (genreList) {
                      if (genreList.isEmpty) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          genreList.join(' • '),
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[400],
                          ),
                        ),
                      );
                    },
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  );
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Release Date: ${selectedMovie.releaseDate}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Text(
                  'Runtime: ${selectedMovie.runtime} minutes',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Text(
                  'Rating: ${selectedMovie.voteAverage}/10',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                if (selectedMovie.revenue > 0)
                  Text(
                    'Revenue: \$${(selectedMovie.revenue / 1000000).toStringAsFixed(1)}M',
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
                      selectedMovie.overview,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Top Billed Cast',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                cast.when(
                  loading: () => const CircularProgressIndicator(),
                  error: (err, stack) => Text('Error: $err'),
                  data: (castList) => Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: castList.map((actor) => SizedBox(
                      width: 80,
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundImage: actor['actor_id'] != null
                                ? FileImage(File('/storage/emulated/0/Debrid_Player/metadata/actors/${actor['actor_id']}/${actor['actor_id']}.webp'))
                                : null,
                            child: actor['actor_id'] == null
                                ? const Icon(Icons.person)
                                : null,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            actor['name'],
                            style: Theme.of(context).textTheme.bodySmall,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    )).toList(),
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