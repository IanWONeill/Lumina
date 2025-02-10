import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/sync_provider.dart';
import '../../../main.dart';

class SyncStatusOverlay extends ConsumerWidget {
  const SyncStatusOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncStatus = ref.watch(syncStatusProvider);
    final syncState = ref.watch(syncProvider);

    if (!syncState.isLoading || syncStatus == null) {
      return const SizedBox.shrink();
    }

    return Positioned(
      top: 20,
      right: 20,
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            syncStatus,
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }
} 