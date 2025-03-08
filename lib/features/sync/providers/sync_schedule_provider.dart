import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../movies/providers/movies_provider.dart';
import '../../tv_shows/providers/tv_shows_provider.dart';
import '../../settings/providers/auto_sync_preference_provider.dart';
import 'sync_provider.dart';
import '../../settings/providers/last_sync_time_provider.dart';

final syncScheduleProvider = Provider<SyncScheduleService>((ref) {
  return SyncScheduleService(ref);
});

class SyncScheduleService {
  SyncScheduleService(this._ref) {
    _initializeTimer();
    _ref.listen(autoSyncPreferenceProvider, (previous, next) {
      _initializeTimer();
    });
  }

  final Ref _ref;
  Timer? _syncTimer;
  
  void _initializeTimer() {
    _syncTimer?.cancel();
    
    final autoSyncPref = _ref.read(autoSyncPreferenceProvider);
    
    if (!autoSyncPref.hasValue || !autoSyncPref.value!.enabled) {
      return;
    }
    
    final timeString = autoSyncPref.value!.time;
    if (timeString == null) return;
    
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

    final timeUntilSync = nextSyncTime.difference(now);
    
    _syncTimer = Timer(timeUntilSync, () {
      _performScheduledSync();
      _initializeTimer();
    });
  }

  Future<void> _performScheduledSync() async {
    final currentState = _ref.read(syncProvider);
    if (currentState is AsyncLoading) return;

    await _ref.read(syncProvider.notifier).sync();
    await _ref.read(lastSyncTimeProvider.notifier).setLastSyncTime(DateTime.now());

    _ref.invalidate(moviesProvider);
    _ref.invalidate(tVShowsProvider);
  }

  void dispose() {
    _syncTimer?.cancel();
    _syncTimer = null;
  }
} 