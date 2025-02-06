import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../movies/providers/movies_provider.dart';
import '../../tv_shows/providers/episodes_provider.dart';
import '../../tv_shows/models/season.dart';
import '../../database/providers/database_provider.dart';

part 'watched_status_provider.g.dart';

@riverpod
class WatchedStatus extends _$WatchedStatus {
  @override
  Future<bool> build(int mediaId, bool isMovie) async {
    final db = ref.watch(databaseServiceProvider);
    if (isMovie) {
      final movie = await db.getMovie(mediaId);
      return movie?['is_watched'] == 1;
    } else {
      final episode = await db.getEpisode(mediaId);
      return episode?['is_watched'] == 1;
    }
  }

  Future<void> toggleWatched() async {
    final db = ref.read(databaseServiceProvider);
    final isCurrentlyWatched = await future;
    
    if (isMovie) {
      await db.updateMovieWatchedStatus(mediaId, !isCurrentlyWatched);
      ref.invalidate(moviesProvider);
    } else {
      final episode = await db.getEpisode(mediaId);
      if (episode != null) {
        await db.updateEpisodeWatchedStatus(mediaId, !isCurrentlyWatched);
        
        final seasons = await db.getSeasonsForShow(episode['show_id'] as int);
        final seasonData = seasons.firstWhere(
          (s) => s['id'] == episode['season_id'],
        );
        
        final season = Season(
          id: seasonData['id'] as int,
          tmdbId: seasonData['tmdb_id'] as int,
          showId: seasonData['show_id'] as int,
          seasonNumber: seasonData['season_number'] as int,
          name: seasonData['name'] as String,
          overview: seasonData['overview'] as String,
          posterPath: seasonData['poster_path'] as String?,
        );
        
        ref.invalidate(seasonEpisodesProvider(season));
      }
    }
    
    ref.invalidateSelf();
  }
} 