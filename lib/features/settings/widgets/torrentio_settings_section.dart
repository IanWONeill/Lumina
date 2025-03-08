import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../providers/torrentio_settings_provider.dart';
import './torrentio_query_settings_screen.dart';

class TorrentioSettingsSection extends ConsumerWidget {
  const TorrentioSettingsSection({super.key});

  String _formatFileSize(int bytes) {
    if (bytes >= 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024 * 1024)).round()}GB';
    }
    return '${(bytes / (1024 * 1024)).round()}MB';
  }

  int _parseFileSize(String size) {
    final value = int.parse(size.replaceAll(RegExp(r'[A-Za-z]'), ''));
    if (size.endsWith('GB')) {
      return value * 1024 * 1024 * 1024;
    }
    return value * 1024 * 1024;
  }

  Widget _buildSettingButton({
    required BuildContext context,
    required String label,
    required String value,
    required VoidCallback onPressed,
  }) {
    return Focus(
      child: Builder(
        builder: (context) {
          final focused = Focus.of(context).hasFocus;
          return SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onPressed,
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
                  Text(label),
                  Text(value),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(torrentioSettingsProvider);

    return settingsAsync.when(
      loading: () => const CircularProgressIndicator(),
      error: (error, stack) => Text('Error: $error'),
      data: (settings) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Torrentio Search Settings',
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
                        builder: (context) => TorrentioQuerySettingsScreen(
                          title: 'Movie Search Settings',
                          settings: settings.movies,
                          onMinFileSizeChanged: (value) => ref
                              .read(torrentioSettingsProvider.notifier)
                              .updateMovieMinFileSize(value),
                          onMaxFileSizeChanged: (value) => ref
                              .read(torrentioSettingsProvider.notifier)
                              .updateMovieMaxFileSize(value),
                          onSortValueChanged: (value) => ref
                              .read(torrentioSettingsProvider.notifier)
                              .updateMovieSortValue(value),
                          onHideHdrChanged: (value) => ref
                              .read(torrentioSettingsProvider.notifier)
                              .updateMovieHideHdr(value),
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
                        builder: (context) => TorrentioQuerySettingsScreen(
                          title: 'Episode Search Settings',
                          settings: settings.episodes,
                          onMinFileSizeChanged: (value) => ref
                              .read(torrentioSettingsProvider.notifier)
                              .updateEpisodeMinFileSize(value),
                          onMaxFileSizeChanged: (value) => ref
                              .read(torrentioSettingsProvider.notifier)
                              .updateEpisodeMaxFileSize(value),
                          onSortValueChanged: (value) => ref
                              .read(torrentioSettingsProvider.notifier)
                              .updateEpisodeSortValue(value),
                          onHideHdrChanged: (value) => ref
                              .read(torrentioSettingsProvider.notifier)
                              .updateEpisodeHideHdr(value),
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