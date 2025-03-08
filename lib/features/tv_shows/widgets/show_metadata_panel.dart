import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../providers/tv_shows_provider.dart';
import '../providers/cast_provider.dart';

class ShowMetadataPanel extends HookConsumerWidget {
  const ShowMetadataPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedShow = ref.watch(selectedTVShowProvider);

    if (selectedShow == null) {
      return const Center(child: Text('No show selected'));
    }

    final cast = ref.watch(showCastProvider(selectedShow.id));

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            selectedShow.originalName,
            style: Theme.of(context).textTheme.headlineMedium,
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
          const SizedBox(height: 8),
          Text(
            'First Aired: ${selectedShow.firstAirDate}',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              child: Text(
                selectedShow.overview,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Seasons: ${selectedShow.numberOfSeasons}',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          Text(
            'Episodes: ${selectedShow.numberOfEpisodes}',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 16),
          const Text(
            'Top Billed Cast',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
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
    );
  }
} 