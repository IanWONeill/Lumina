import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../sync/services/database_service.dart';

part 'cast_provider.g.dart';

@riverpod
Future<List<Map<String, dynamic>>> movieCast(MovieCastRef ref, int movieId) async {
  final db = DatabaseService();
  final cast = await db.getMovieCast(movieId);
  return cast.take(3).toList();
} 