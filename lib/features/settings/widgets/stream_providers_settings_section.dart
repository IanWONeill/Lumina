import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../providers/stream_providers_settings_provider.dart';

class StreamProvidersSettingsSection extends ConsumerWidget {
  const StreamProvidersSettingsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orionoidEnabled = ref.watch(orionoidEnabledProviderProvider);
    final torrentioEnabled = ref.watch(torrentioEnabledProviderProvider);
    final aioStreamsEnabled = ref.watch(aioStreamsEnabledProviderProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Stream Providers',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 20),
        orionoidEnabled.when(
          data: (enabled) => SwitchListTile(
            title: const Text('Orionoid'),
            subtitle: const Text('Enable/disable Orionoid as a stream provider'),
            value: enabled,
            onChanged: (value) {
              ref.read(orionoidEnabledProviderProvider.notifier).toggle();
            },
          ),
          loading: () => const CircularProgressIndicator(),
          error: (error, stack) => Text('Error: $error'),
        ),
        torrentioEnabled.when(
          data: (enabled) => SwitchListTile(
            title: const Text('Torrentio'),
            subtitle: const Text('Enable/disable Torrentio as a stream provider'),
            value: enabled,
            onChanged: (value) {
              ref.read(torrentioEnabledProviderProvider.notifier).toggle();
            },
          ),
          loading: () => const CircularProgressIndicator(),
          error: (error, stack) => Text('Error: $error'),
        ),
        aioStreamsEnabled.when(
          data: (enabled) => SwitchListTile(
            title: const Text('AIOStreams'),
            subtitle: const Text('Enable/disable AIOStreams as a stream provider'),
            value: enabled,
            onChanged: (value) {
              ref.read(aioStreamsEnabledProviderProvider.notifier).toggle();
            },
          ),
          loading: () => const CircularProgressIndicator(),
          error: (error, stack) => Text('Error: $error'),
        ),
      ],
    );
  }
} 