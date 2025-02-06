import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'dart:developer' as developer;
import '../providers/episodes_provider.dart';
import '../providers/tv_shows_provider.dart';

class EpisodeStillPanel extends HookConsumerWidget {
  const EpisodeStillPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedEpisode = ref.watch(selectedEpisodeProvider);
    final selectedShow = ref.watch(selectedTVShowProvider);

    if (selectedEpisode == null || selectedShow == null) {
      return const Center(child: Text('No episode selected'));
    }

    final episodeStill = selectedEpisode.stillFile;
    final showPoster = selectedShow.posterFile;
    
    final imageFile = (episodeStill != null && episodeStill.existsSync())
        ? episodeStill
        : showPoster;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (imageFile != null && imageFile.existsSync())
          Image.file(
            imageFile,
            height: 450,
            width: 300,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              developer.log(
                'Error loading image',
                name: 'EpisodeStillPanel',
                error: {
                  'path': imageFile.path,
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
        if (selectedEpisode.watchProgress > 0)
          LinearProgressIndicator(
            value: selectedEpisode.watchProgress / 100,
          ),
      ],
    );
  }
} 