import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/settings_provider.dart';
import '../providers/orionoid_provider.dart';
import 'dart:convert';
import '../widgets/orion_settings_section.dart';
import '../widgets/sync_settings_section.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final simklAuthState = ref.watch(simklAuthProvider);
    final orionoidAuthState = ref.watch(orionoidAuthProvider);

    return Scaffold(
      body: SingleChildScrollView(
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
            const SyncSettingsSection(),
          ],
        ),
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