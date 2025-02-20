import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/rss_settings_provider.dart';

class RSSSettingsSection extends ConsumerWidget {
  const RSSSettingsSection({super.key});

  Future<String?> _showCustomUrlDialog(
    BuildContext context,
    String currentUrl,
  ) async {
    final controller = TextEditingController(text: currentUrl);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Custom RSS Feed'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Enter RSS feed URL',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (value) => Navigator.of(context).pop(value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    controller.dispose();
    return result;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(rssSettingsProvider);
    final defaultFeeds = RSSFeedConfig.getDefaultFeeds();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'RSS Feed Settings',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
        
        DropdownButtonFormField<RSSDisplayMode>(
          value: settings.displayMode,
          decoration: const InputDecoration(
            labelText: 'Display Mode',
            border: OutlineInputBorder(),
          ),
          items: RSSDisplayMode.values.map((mode) {
            return DropdownMenuItem(
              value: mode,
              child: Text(mode.name.toUpperCase()),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              ref.read(rssSettingsProvider.notifier).setDisplayMode(value);
            }
          },
        ),
        const SizedBox(height: 20),
        
        DropdownButtonFormField<RSSScrollSpeed>(
          value: settings.scrollSpeed,
          decoration: const InputDecoration(
            labelText: 'Scroll Speed',
            border: OutlineInputBorder(),
          ),
          items: RSSScrollSpeed.values.map((speed) {
            return DropdownMenuItem(
              value: speed,
              child: Text(speed.name.toUpperCase()),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              ref.read(rssSettingsProvider.notifier).setScrollSpeed(value);
            }
          },
        ),
        const SizedBox(height: 20),
        
        ...List.generate(3, (index) {
          final selectedUrl = index < settings.selectedFeeds.length 
              ? settings.selectedFeeds[index]
              : '';
              
          return Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: DropdownButtonFormField<String>(
              value: selectedUrl.isEmpty ? defaultFeeds.first.url : selectedUrl,
              decoration: InputDecoration(
                labelText: 'RSS Feed ${index + 1}',
                border: const OutlineInputBorder(),
              ),
              items: defaultFeeds.map((feed) => DropdownMenuItem(
                value: feed.url,
                child: Text(feed.name),
              )).toList(),
              onChanged: (value) {
                if (value != null) {
                  ref.read(rssSettingsProvider.notifier).updateFeed(index, value);
                }
              },
            ),
          );
        }),
      ],
    );
  }
} 