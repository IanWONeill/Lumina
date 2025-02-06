import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../services/just_player_broadcast_service.dart';
import '../../database/providers/database_provider.dart';

final justPlayerBroadcastServiceProvider = Provider((ref) {
  final db = ref.watch(databaseServiceProvider);
  
  final service = JustPlayerBroadcastService(db, ref);
  
  service.startListening();
  
  ref.onDispose(() {
    service.stopListening();
  });
  
  return service;
}); 