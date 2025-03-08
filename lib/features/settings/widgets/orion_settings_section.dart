import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../providers/orion_settings_provider.dart';
import './orion_query_settings_screen.dart';

class OrionSettingsSection extends ConsumerWidget {
  const OrionSettingsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(orionSettingsProvider);

    return settingsAsync.when(
      loading: () => const CircularProgressIndicator(),
      error: (error, stack) => Text('Error: $error'),
      data: (settings) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Orion Search Settings',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),

          Focus(
            child: Builder(
              builder: (context) {
                final focused = Focus.of(context).hasFocus;
                return SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => OrionQuerySettingsScreen(
                          title: 'Movie Search Settings',
                          settings: settings.movies,
                          onLimitCountChanged: (value) => ref
                              .read(orionSettingsProvider.notifier)
                              .updateMovieLimitCount(value),
                          onStreamTypesChanged: (value) => ref
                              .read(orionSettingsProvider.notifier)
                              .updateMovieStreamTypes(value),
                          onMinFileSizeChanged: (value) => ref
                              .read(orionSettingsProvider.notifier)
                              .updateMovieMinFileSize(value),
                          onMaxFileSizeChanged: (value) => ref
                              .read(orionSettingsProvider.notifier)
                              .updateMovieMaxFileSize(value),
                          onAccessTypesChanged: (value) => ref
                              .read(orionSettingsProvider.notifier)
                              .updateMovieAccessTypes(value),
                          onSortValueChanged: (value) => ref
                              .read(orionSettingsProvider.notifier)
                              .updateMovieSortValue(value),
                          onForceEnglishAudioChanged: (value) => ref
                              .read(orionSettingsProvider.notifier)
                              .updateMovieForceEnglishAudio(value),
                          onFilenameFiltersChanged: (value) => ref
                              .read(orionSettingsProvider.notifier)
                              .updateMovieFilematchFilters(value),
                        ),
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: focused 
                        ? Colors.blue.withOpacity(0.2) 
                        : Colors.white.withOpacity(0.1),
                      foregroundColor: focused ? Colors.blue : Colors.white,
                      padding: const EdgeInsets.all(16),
                      side: focused 
                        ? const BorderSide(color: Colors.blue, width: 2)
                        : null,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Movie Search Settings'),
                        Icon(
                          Icons.arrow_forward_ios,
                          color: focused ? Colors.blue : Colors.white,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),

          Focus(
            child: Builder(
              builder: (context) {
                final focused = Focus.of(context).hasFocus;
                return SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => OrionQuerySettingsScreen(
                          title: 'Episode Search Settings',
                          settings: settings.episodes,
                          onLimitCountChanged: (value) => ref
                              .read(orionSettingsProvider.notifier)
                              .updateEpisodeLimitCount(value),
                          onStreamTypesChanged: (value) => ref
                              .read(orionSettingsProvider.notifier)
                              .updateEpisodeStreamTypes(value),
                          onMinFileSizeChanged: (value) => ref
                              .read(orionSettingsProvider.notifier)
                              .updateEpisodeMinFileSize(value),
                          onMaxFileSizeChanged: (value) => ref
                              .read(orionSettingsProvider.notifier)
                              .updateEpisodeMaxFileSize(value),
                          onAccessTypesChanged: (value) => ref
                              .read(orionSettingsProvider.notifier)
                              .updateEpisodeAccessTypes(value),
                          onSortValueChanged: (value) => ref
                              .read(orionSettingsProvider.notifier)
                              .updateEpisodeSortValue(value),
                          onForceEnglishAudioChanged: (value) => ref
                              .read(orionSettingsProvider.notifier)
                              .updateEpisodeForceEnglishAudio(value),
                          onFilenameFiltersChanged: (value) => ref
                              .read(orionSettingsProvider.notifier)
                              .updateEpisodeFilematchFilters(value),
                        ),
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: focused 
                        ? Colors.blue.withOpacity(0.2) 
                        : Colors.white.withOpacity(0.1),
                      foregroundColor: focused ? Colors.blue : Colors.white,
                      padding: const EdgeInsets.all(16),
                      side: focused 
                        ? const BorderSide(color: Colors.blue, width: 2)
                        : null,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Episode Search Settings'),
                        Icon(
                          Icons.arrow_forward_ios,
                          color: focused ? Colors.blue : Colors.white,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
} 