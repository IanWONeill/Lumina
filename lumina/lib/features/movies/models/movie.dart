import 'package:freezed_annotation/freezed_annotation.dart';
import 'dart:io';

part 'movie.freezed.dart';
part 'movie.g.dart';

@freezed
class Movie with _$Movie {
  const Movie._();

  const factory Movie({
    required int id,
    required int tmdbId,
    required String originalTitle,
    required String overview,
    required String releaseDate,
    required int runtime,
    required double voteAverage,
    required int revenue,
    String? posterPath,
    @Default(false) bool isWatched,
    String? backdropPath,
    @Default(0) int watchProgress,
  }) = _Movie;

  factory Movie.fromJson(Map<String, dynamic> json) => _$MovieFromJson(json);

  factory Movie.fromMap(Map<String, dynamic> map) => Movie(
        id: map['id'] as int? ?? map['tmdb_id'] as int,
        tmdbId: map['tmdb_id'] as int,
        originalTitle: map['original_title'] as String,
        overview: map['overview'] as String,
        releaseDate: map['release_date'] as String,
        runtime: map['runtime'] as int,
        voteAverage: (map['vote_average'] as num).toDouble(),
        revenue: map['revenue'] as int? ?? 0,
        posterPath: map['poster_path'] as String?,
        backdropPath: map['backdrop_path'] as String?,
        isWatched: (map['is_watched'] as int) == 1,
        watchProgress: map['watch_progress'] as int? ?? 0,
      );

  File? get posterFile {
    final path = '/storage/emulated/0/Debrid_Player/metadata/movies/posters/${tmdbId.toString()}/poster.webp';
    final file = File(path);
    return file;
  }
} 