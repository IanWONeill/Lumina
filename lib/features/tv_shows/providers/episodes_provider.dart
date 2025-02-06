import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/episode.dart';
import '../models/season.dart';
import '../../sync/services/database_service.dart';

part 'episodes_provider.g.dart';

@Riverpod(keepAlive: true)
class SeasonEpisodes extends _$SeasonEpisodes {
  @override
  Future<List<Episode>> build(Season season) async {
    final db = DatabaseService();
    final episodes = await db.getEpisodesForSeason(season.id);
    return episodes.map((map) => Episode.fromMap(map)).toList();
  }
}

@Riverpod(keepAlive: true)
class SelectedEpisode extends _$SelectedEpisode {
  @override
  Episode? build() => null;

  void select(Episode episode) => state = episode;
} 