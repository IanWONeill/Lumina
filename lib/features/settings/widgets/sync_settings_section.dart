import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../sync/providers/full_sync_provider.dart';
import '../providers/sync_list_preference_provider.dart';

class SyncSettingsSection extends ConsumerWidget {
  const SyncSettingsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncState = ref.watch(fullSyncProvider);
    final listPreference = ref.watch(simklListPreferenceProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Sync Settings',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
        Focus(
          child: Builder(
            builder: (context) {
              final focused = Focus.of(context).hasFocus;
              return Container(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final currentType = listPreference.value ?? SimklListType.planToWatch;
                    final newType = currentType == SimklListType.completed
                        ? SimklListType.planToWatch
                        : SimklListType.completed;
                    await ref.read(simklListPreferenceProvider.notifier)
                        .setListType(newType);
                  },
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
                      Text('Simkl List to Sync: ${listPreference.when(
                        data: (type) => type == SimklListType.completed 
                            ? 'Completed' 
                            : 'Plan to Watch',
                        loading: () => '...',
                        error: (_, __) => 'Error',
                      )}'),
                      Icon(
                        Icons.swap_horiz,
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
        const SizedBox(height: 20),
        Focus(
          child: Builder(
            builder: (context) {
              final focused = Focus.of(context).hasFocus;
              return Container(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: syncState.isLoading 
                    ? null 
                    : () => ref.read(fullSyncProvider.notifier).startFullSync(),
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
                      Text(syncState.isLoading 
                        ? 'Checking for missing metadata...' 
                        : 'Check for missing metadata'),
                      if (syncState.isLoading)
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      else
                        Icon(
                          Icons.sync,
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
    );
  }
} 