import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/tv_show.dart';
import '../../sync/services/database_service.dart';

part 'tv_shows_provider.g.dart';

@Riverpod(keepAlive: true)
class TVShows extends _$TVShows {
  @override
  Future<List<TVShow>> build() async {
    final db = DatabaseService();
    final shows = await db.getAllTVShows();
    return shows.map((map) => TVShow.fromMap(map)).toList();
  }
}

@Riverpod(keepAlive: true)
class SelectedTVShow extends _$SelectedTVShow {
  @override
  TVShow? build() => null;

  void select(TVShow show) => state = show;
} 