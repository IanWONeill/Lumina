import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'aio_streams_settings_provider.g.dart';

@riverpod
class AioStreamsSettings extends _$AioStreamsSettings {
  SharedPreferences? _prefs;

  @override
  Future<AioStreamsSettingsData> build() async {
    _prefs ??= await SharedPreferences.getInstance();
    
    return AioStreamsSettingsData(
      movies: AioStreamsQuerySettings(
        minFileSize: _prefs!.getInt('aio_streams_movie_min_file_size') ?? 500 * 1024 * 1024,
        maxFileSize: _prefs!.getInt('aio_streams_movie_max_file_size') ?? 6 * 1024 * 1024 * 1024,
        sortValue: _prefs!.getString('aio_streams_movie_sort_value') ?? 'size',
      ),
      episodes: AioStreamsQuerySettings(
        minFileSize: _prefs!.getInt('aio_streams_episode_min_file_size') ?? 200 * 1024 * 1024,
        maxFileSize: _prefs!.getInt('aio_streams_episode_max_file_size') ?? 3 * 1024 * 1024 * 1024,
        sortValue: _prefs!.getString('aio_streams_episode_sort_value') ?? 'size',
      ),
    );
  }

  Future<void> updateMovieMinFileSize(int bytes) async {
    await _prefs?.setInt('aio_streams_movie_min_file_size', bytes);
    ref.invalidateSelf();
  }

  Future<void> updateMovieMaxFileSize(int bytes) async {
    await _prefs?.setInt('aio_streams_movie_max_file_size', bytes);
    ref.invalidateSelf();
  }

  Future<void> updateMovieSortValue(String value) async {
    await _prefs?.setString('aio_streams_movie_sort_value', value);
    ref.invalidateSelf();
  }

  Future<void> updateEpisodeMinFileSize(int bytes) async {
    await _prefs?.setInt('aio_streams_episode_min_file_size', bytes);
    ref.invalidateSelf();
  }

  Future<void> updateEpisodeMaxFileSize(int bytes) async {
    await _prefs?.setInt('aio_streams_episode_max_file_size', bytes);
    ref.invalidateSelf();
  }

  Future<void> updateEpisodeSortValue(String value) async {
    await _prefs?.setString('aio_streams_episode_sort_value', value);
    ref.invalidateSelf();
  }
}

class AioStreamsSettingsData {
  final AioStreamsQuerySettings movies;
  final AioStreamsQuerySettings episodes;

  const AioStreamsSettingsData({
    required this.movies,
    required this.episodes,
  });
}

class AioStreamsQuerySettings {
  final int minFileSize;
  final int maxFileSize;
  final String sortValue;

  const AioStreamsQuerySettings({
    required this.minFileSize,
    required this.maxFileSize,
    required this.sortValue,
  });
}
