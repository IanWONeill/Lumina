import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../providers/episodes_provider.dart';

class EpisodeDetailsPanel extends HookConsumerWidget {
  const EpisodeDetailsPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedEpisode = ref.watch(selectedEpisodeProvider);

    if (selectedEpisode == null) {
      return const Center(child: Text('No episode selected'));
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Episode ${selectedEpisode.episodeNumber}',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            selectedEpisode.name,
            style: Theme.of(context).textTheme.headlineSmall,
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
          if (selectedEpisode.airDate != null) ...[
            const SizedBox(height: 8),
            Text(
              'Air Date: ${selectedEpisode.airDate}',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
          const SizedBox(height: 16),
          if (selectedEpisode.overview != null)
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  selectedEpisode.overview!,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
} 