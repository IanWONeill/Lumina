import 'package:freezed_annotation/freezed_annotation.dart';
import 'dart:io';

part 'tv_show.freezed.dart';
part 'tv_show.g.dart';

@freezed
class TVShow with _$TVShow {
  const TVShow._();

  const factory TVShow({
    required int id,
    required int tmdbId,
    required String originalName,
    required String overview,
    required String firstAirDate,
    required int numberOfSeasons,
    required int numberOfEpisodes,
    String? posterPath,
    String? backdropPath,
  }) = _TVShow;

  factory TVShow.fromJson(Map<String, dynamic> json) => _$TVShowFromJson(json);

  factory TVShow.fromMap(Map<String, dynamic> map) => TVShow(
        id: map['id'] as int? ?? map['tmdb_id'] as int,
        tmdbId: map['tmdb_id'] as int,
        originalName: map['original_name'] as String,
        overview: map['overview'] as String,
        firstAirDate: map['first_air_date'] as String,
        numberOfSeasons: map['number_of_seasons'] as int,
        numberOfEpisodes: map['number_of_episodes'] as int,
        posterPath: map['poster_path'] as String?,
        backdropPath: map['backdrop_path'] as String?,
      );

  File? get posterFile {
    final path = '/storage/emulated/0/Debrid_Player/metadata/tv/posters/${tmdbId.toString()}/poster.webp';
    final file = File(path);
    return file;
  }
} 