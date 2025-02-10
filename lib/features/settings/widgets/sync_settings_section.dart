import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../providers/auto_sync_preference_provider.dart';
import '../providers/sync_list_preference_provider.dart';
import '../providers/last_sync_time_provider.dart';

class SyncSettingsSection extends ConsumerWidget {
  const SyncSettingsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listPreference = ref.watch(simklListPreferenceProvider);
    final autoSyncPreference = ref.watch(autoSyncPreferenceProvider);

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
        const SizedBox(height: 12),
        Focus(
          child: Builder(
            builder: (context) {
              final focused = Focus.of(context).hasFocus;
              return Container(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final currentEnabled = autoSyncPreference.value?.enabled ?? false;
                    await ref.read(autoSyncPreferenceProvider.notifier)
                        .setEnabled(!currentEnabled);
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
                      Text('Enable Auto Sync: ${autoSyncPreference.when(
                        data: (data) => data.enabled ? 'Yes' : 'No',
                        loading: () => '...',
                        error: (_, __) => 'Error',
                      )}'),
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
        if (autoSyncPreference.value?.enabled ?? false) ...[
          const SizedBox(height: 12),
          Focus(
            child: Builder(
              builder: (context) {
                final focused = Focus.of(context).hasFocus;
                return Container(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      final lastSync = await ref.read(lastSyncTimeProvider.future);
                      final nextSync = _calculateNextSyncTime(
                        autoSyncPreference.value?.time,
                      );
                      
                      if (!context.mounted) return;
                      
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Auto Sync Status'),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Last auto sync: ${
                                lastSync == null 
                                  ? 'No syncs have occurred yet'
                                  : '${lastSync.month}/${lastSync.day}/${lastSync.year} at '
                                      '${lastSync.hour}:${lastSync.minute.toString().padLeft(2, '0')}'
                              }'),
                              const SizedBox(height: 8),
                              Text('Next auto sync: ${nextSync != null 
                                ? '${nextSync.month}/${nextSync.day}/${nextSync.year} at '
                                    '${nextSync.hour}:${nextSync.minute.toString().padLeft(2, '0')}'
                                : 'Not scheduled - please set a sync time'}'),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('Close'),
                            ),
                          ],
                        ),
                      );
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
                        const Text('Check Sync Status'),
                        Icon(
                          Icons.info_outline,
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
          const SizedBox(height: 12),
          Focus(
            child: Builder(
              builder: (context) {
                final focused = Focus.of(context).hasFocus;
                return Container(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _showTimePickerDialog(context, ref),
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
                        Text('Auto Sync Time: ${autoSyncPreference.when(
                          data: (data) => data.time ?? 'Not Set',
                          loading: () => '...',
                          error: (_, __) => 'Error',
                        )}'),
                        Icon(
                          Icons.access_time,
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
      ],
    );
  }

  DateTime? _calculateNextSyncTime(String? timeString) {
    if (timeString == null) return null;
    
    final isPM = timeString.toLowerCase().endsWith('pm');
    final timeParts = timeString.toLowerCase()
        .replaceAll('am', '')
        .replaceAll('pm', '')
        .split(':');
    
    var hours = int.parse(timeParts[0]);
    final minutes = timeParts.length > 1 ? int.parse(timeParts[1]) : 0;
    
    if (isPM && hours != 12) hours += 12;
    if (!isPM && hours == 12) hours = 0;

    final now = DateTime.now();
    var nextSyncTime = DateTime(
      now.year,
      now.month,
      now.day,
      hours,
      minutes,
    );

    if (now.isAfter(nextSyncTime)) {
      nextSyncTime = nextSyncTime.add(const Duration(days: 1));
    }

    return nextSyncTime;
  }

  Future<void> _showTimePickerDialog(BuildContext context, WidgetRef ref) {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Auto Sync Time'),
        content: SizedBox(
          width: 200,
          height: 400,
          child: ListView.builder(
            itemCount: 96,
            itemBuilder: (context, index) {
              final hour = index ~/ 4;
              final minute = (index % 4) * 15;
              final isAM = hour < 12;
              final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
              final timeString = '$displayHour:${minute.toString().padLeft(2, '0')}${isAM ? 'am' : 'pm'}';

              return Focus(
                child: Builder(
                  builder: (context) {
                    final focused = Focus.of(context).hasFocus;
                    return ListTile(
                      onTap: () async {
                        await ref.read(autoSyncPreferenceProvider.notifier)
                            .setTime(timeString);
                        Navigator.of(context).pop();
                      },
                      title: Text(
                        timeString,
                        style: TextStyle(
                          color: focused ? Colors.blue : Colors.white,
                        ),
                      ),
                      tileColor: focused 
                          ? Colors.blue.withOpacity(0.2) 
                          : Colors.transparent,
                      shape: focused 
                          ? RoundedRectangleBorder(
                              side: const BorderSide(color: Colors.blue, width: 2),
                              borderRadius: BorderRadius.circular(4),
                            )
                          : null,
                    );
                  },
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
} 