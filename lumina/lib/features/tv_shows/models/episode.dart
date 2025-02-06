import 'package:freezed_annotation/freezed_annotation.dart';
import 'dart:io';

part 'episode.freezed.dart';
part 'episode.g.dart';

@freezed
class Episode with _$Episode {
  const Episode._();

  const factory Episode({
    required int id,
    required int tmdbId,
    required int showId,
    required int seasonId,
    required int episodeNumber,
    required String name,
    String? overview,
    String? stillPath,
    String? airDate,
    @Default(false) bool isWatched,
    @Default(0) int watchProgress,
  }) = _Episode;

  factory Episode.fromJson(Map<String, dynamic> json) => _$EpisodeFromJson(json);

  factory Episode.fromMap(Map<String, dynamic> map) => Episode(
        id: map['id'] as int,
        tmdbId: map['tmdb_id'] as int,
        showId: map['show_id'] as int,
        seasonId: map['season_id'] as int,
        episodeNumber: map['episode_number'] as int,
        name: map['name'] as String,
        overview: map['overview'] as String?,
        stillPath: map['still_path'] as String?,
        airDate: map['air_date'] as String?,
        isWatched: (map['is_watched'] as int) == 1,
        watchProgress: map['watch_progress'] as int,
      );

  File? get stillFile {
    final path = '/storage/emulated/0/Debrid_Player/metadata/tv/posters/${showId.toString()}/poster.webp';
    final file = File(path);
    return file;
  }
} 