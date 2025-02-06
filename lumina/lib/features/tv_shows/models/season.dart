import 'package:freezed_annotation/freezed_annotation.dart';
import 'dart:io';

part 'season.freezed.dart';
part 'season.g.dart';

@freezed
class Season with _$Season {
  const Season._();

  const factory Season({
    required int id,
    required int tmdbId,
    required int showId,
    required int seasonNumber,
    required String name,
    @Default(0) int episodeCount,
    String? overview,
    String? posterPath,
  }) = _Season;

  factory Season.fromJson(Map<String, dynamic> json) => _$SeasonFromJson(json);

  factory Season.fromMap(Map<String, dynamic> map) => Season(
        id: map['id'] as int,
        tmdbId: map['tmdb_id'] as int,
        showId: map['show_id'] as int,
        seasonNumber: map['season_number'] as int,
        name: map['name'] as String,
        episodeCount: (map['episode_count'] as int?) ?? 0,
        overview: map['overview'] as String?,
        posterPath: map['poster_path'] as String?,
      );

  File? get posterFile {
    final path = '/storage/emulated/0/Debrid_Player/metadata/tv/posters/${showId.toString()}/poster.webp';
    final file = File(path);
    return file;
  }
} 