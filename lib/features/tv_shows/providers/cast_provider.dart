import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../database/providers/database_provider.dart';

part 'cast_provider.g.dart';

@riverpod
class ShowCast extends _$ShowCast {
  @override
  Future<List<Map<String, dynamic>>> build(int showId) async {
    final db = ref.watch(databaseServiceProvider);
    final cast = await db.getTVShowCast(showId);
    return cast.take(3).toList();
  }
} 