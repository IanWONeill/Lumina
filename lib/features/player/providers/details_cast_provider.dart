import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../sync/services/database_service.dart';

part 'details_cast_provider.g.dart';

@riverpod
Future<List<Map<String, dynamic>>> detailsMovieCast(
  DetailsMovieCastRef ref, 
  int movieId,
) async {
  final db = DatabaseService();
  return db.getMovieCastDetails(movieId);
}

@riverpod
Future<List<Map<String, dynamic>>> detailsShowCast(
  DetailsShowCastRef ref, 
  int showId,
) async {
  final db = DatabaseService();
  return db.getTVShowCastDetails(showId);
} 