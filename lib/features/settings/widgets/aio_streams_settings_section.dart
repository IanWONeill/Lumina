import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../providers/aio_streams_settings_provider.dart';
import './aio_streams_query_settings_screen.dart';

class AioStreamsSettingsSection extends ConsumerWidget {
  const AioStreamsSettingsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(aioStreamsSettingsProvider);

    return settingsAsync.when(
      loading: () => const CircularProgressIndicator(),
      error: (error, stack) => Text('Error: $error'),
      data: (settings) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'AIOStreams Search Settings',
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
                        builder: (context) => AioStreamsQuerySettingsScreen(
                          title: 'Movie Search Settings',
                          settings: settings.movies,
                          onMinFileSizeChanged: (value) => ref
                              .read(aioStreamsSettingsProvider.notifier)
                              .updateMovieMinFileSize(value),
                          onMaxFileSizeChanged: (value) => ref
                              .read(aioStreamsSettingsProvider.notifier)
                              .updateMovieMaxFileSize(value),
                          onSortValueChanged: (value) => ref
                              .read(aioStreamsSettingsProvider.notifier)
                              .updateMovieSortValue(value),
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
                        builder: (context) => AioStreamsQuerySettingsScreen(
                          title: 'Episode Search Settings',
                          settings: settings.episodes,
                          onMinFileSizeChanged: (value) => ref
                              .read(aioStreamsSettingsProvider.notifier)
                              .updateEpisodeMinFileSize(value),
                          onMaxFileSizeChanged: (value) => ref
                              .read(aioStreamsSettingsProvider.notifier)
                              .updateEpisodeMaxFileSize(value),
                          onSortValueChanged: (value) => ref
                              .read(aioStreamsSettingsProvider.notifier)
                              .updateEpisodeSortValue(value),
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
