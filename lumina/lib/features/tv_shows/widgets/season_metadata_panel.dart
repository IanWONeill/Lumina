import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../providers/seasons_provider.dart';

class SeasonMetadataPanel extends HookConsumerWidget {
  const SeasonMetadataPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedSeason = ref.watch(selectedSeasonProvider);

    if (selectedSeason == null) {
      return const Center(child: Text('No season selected'));
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            selectedSeason.name,
            style: Theme.of(context).textTheme.headlineMedium,
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
          const SizedBox(height: 16),
          if (selectedSeason.overview != null && selectedSeason.overview!.isNotEmpty)
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  selectedSeason.overview!,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            )
          else
            Text(
              'No overview available',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontStyle: FontStyle.italic,
              ),
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
} 