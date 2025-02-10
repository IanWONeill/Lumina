import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'dart:developer' as developer;
import '../models/tv_show.dart';
import '../providers/seasons_provider.dart';
import '../../../widgets/digital_clock.dart';

class SeasonPosterPanel extends HookConsumerWidget {
  final TVShow show;

  const SeasonPosterPanel({
    super.key,
    required this.show,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedSeason = ref.watch(selectedSeasonProvider);

    if (selectedSeason == null) {
      return const Center(child: Text('No season selected'));
    }

    final posterFile = show.posterFile;

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
                'Error loading season poster',
                name: 'SeasonPosterPanel',
                error: {
                  'showId': show.tmdbId,
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
        const SizedBox(height: 16),
        const DigitalClock(),
      ],
    );
  }
} 