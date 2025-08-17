import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../providers/settings_provider.dart';
import '../providers/orionoid_provider.dart';
import 'dart:convert';
import '../widgets/orion_settings_section.dart';
import '../widgets/sync_settings_section.dart';
import '../widgets/sort_settings_section.dart';
import '../widgets/stream_providers_settings_section.dart';
import '../widgets/torrentio_settings_section.dart';
import '../widgets/rss_settings_section.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  String _version = '';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _version = packageInfo.version;
    });
  }

  @override
  Widget build(BuildContext context) {
    final simklAuthState = ref.watch(simklAuthProvider);
    final orionoidAuthState = ref.watch(orionoidAuthProvider);

    return Scaffold(
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAuthSection(
                  'SIMKL',
                  simklAuthState,
                  () => ref.read(simklAuthProvider.notifier).startAuth(),
                ),
                const SizedBox(height: 40),
                _buildAuthSection(
                  'Orionoid',
                  orionoidAuthState,
                  () => ref.read(orionoidAuthProvider.notifier).startAuth(),
                ),
                const SizedBox(height: 40),
                const OrionSettingsSection(),
                const SizedBox(height: 40),
                const TorrentioSettingsSection(),
                const SizedBox(height: 40),
                const StreamProvidersSettingsSection(),
                const SizedBox(height: 40),
                const SyncSettingsSection(),
                const SizedBox(height: 40),
                const SortSettingsSection(),
                const SizedBox(height: 40),
                const RSSSettingsSection(),
              ],
            ),
          ),
          // Version display at top right
          Positioned(
            top: 24,
            right: 24,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'v$_version',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuthSection(
    String title,
    AsyncValue<String?> state,
    VoidCallback onConnect,
  ) => Column(
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          state.when(
            data: (data) {
              if (data == null) {
                return ElevatedButton(
                  onPressed: onConnect,
                  child: Text('Connect to $title'),
                );
              } else if (data.startsWith('CODE:')) {
                final authInfo = data.substring(5);
                if (title == 'Orionoid') {
                  final info = jsonDecode(authInfo);
                  return Column(
                    children: [
                      const Text('Please scan QR code or visit:'),
                      const SizedBox(height: 10),
                      Text(info['link']),
                      const SizedBox(height: 20),
                      Image.network(info['qr']),
                      const SizedBox(height: 20),
                      const Text('Waiting for authorization...'),
                    ],
                  );
                } else {
                  return Column(
                    children: [
                      const Text('Please visit:'),
                      const Text('https://simkl.com/pin'),
                      const SizedBox(height: 20),
                      Text(
                        authInfo,
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text('Waiting for authorization...'),
                    ],
                  );
                }
              } else {
                return Text(
                  'Connected to $title',
                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.green,
                  ),
                );
              }
            },
            loading: () => const CircularProgressIndicator(),
            error: (error, stack) => Text('Error: $error'),
          ),
        ],
      );
} 