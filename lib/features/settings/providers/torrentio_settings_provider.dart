import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'torrentio_settings_provider.g.dart';

@riverpod
class TorrentioSettings extends _$TorrentioSettings {
  SharedPreferences? _prefs;

  @override
  Future<TorrentioSettingsData> build() async {
    _prefs ??= await SharedPreferences.getInstance();
    
    return TorrentioSettingsData(
      movies: TorrentioQuerySettings(
        minFileSize: _prefs!.getInt('torrentio_movie_min_file_size') ?? 500 * 1024 * 1024,
        maxFileSize: _prefs!.getInt('torrentio_movie_max_file_size') ?? 6 * 1024 * 1024 * 1024,
        sortValue: _prefs!.getString('torrentio_movie_sort_value') ?? 'quality',
        hideHdr: _prefs!.getBool('torrentio_movie_hide_hdr') ?? false,
      ),
      episodes: TorrentioQuerySettings(
        minFileSize: _prefs!.getInt('torrentio_episode_min_file_size') ?? 200 * 1024 * 1024,
        maxFileSize: _prefs!.getInt('torrentio_episode_max_file_size') ?? 3 * 1024 * 1024 * 1024,
        sortValue: _prefs!.getString('torrentio_episode_sort_value') ?? 'quality',
        hideHdr: _prefs!.getBool('torrentio_episode_hide_hdr') ?? false,
      ),
    );
  }

  Future<void> updateMovieMinFileSize(int bytes) async {
    await _prefs?.setInt('torrentio_movie_min_file_size', bytes);
    ref.invalidateSelf();
  }

  Future<void> updateMovieMaxFileSize(int bytes) async {
    await _prefs?.setInt('torrentio_movie_max_file_size', bytes);
    ref.invalidateSelf();
  }

  Future<void> updateMovieSortValue(String value) async {
    await _prefs?.setString('torrentio_movie_sort_value', value);
    ref.invalidateSelf();
  }

  Future<void> updateMovieHideHdr(bool value) async {
    await _prefs?.setBool('torrentio_movie_hide_hdr', value);
    ref.invalidateSelf();
  }

  Future<void> updateEpisodeMinFileSize(int bytes) async {
    await _prefs?.setInt('torrentio_episode_min_file_size', bytes);
    ref.invalidateSelf();
  }

  Future<void> updateEpisodeMaxFileSize(int bytes) async {
    await _prefs?.setInt('torrentio_episode_max_file_size', bytes);
    ref.invalidateSelf();
  }

  Future<void> updateEpisodeSortValue(String value) async {
    await _prefs?.setString('torrentio_episode_sort_value', value);
    ref.invalidateSelf();
  }

  Future<void> updateEpisodeHideHdr(bool value) async {
    await _prefs?.setBool('torrentio_episode_hide_hdr', value);
    ref.invalidateSelf();
  }
}

class TorrentioSettingsData {
  final TorrentioQuerySettings movies;
  final TorrentioQuerySettings episodes;

  const TorrentioSettingsData({
    required this.movies,
    required this.episodes,
  });
}

class TorrentioQuerySettings {
  final int minFileSize;
  final int maxFileSize;
  final String sortValue;
  final bool hideHdr;

  const TorrentioQuerySettings({
    required this.minFileSize,
    required this.maxFileSize,
    required this.sortValue,
    required this.hideHdr,
  });
} 