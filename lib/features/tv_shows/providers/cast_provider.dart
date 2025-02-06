import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../sync/services/database_service.dart';

part 'cast_provider.g.dart';

@riverpod
Future<List<Map<String, dynamic>>> showCast(ShowCastRef ref, int showId) async {
  final db = DatabaseService();
  final cast = await db.getTVShowCast(showId);
  return cast.take(3).toList();
} 