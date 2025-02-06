import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' as developer;

part 'orion_settings_provider.g.dart';

const Map<String, String> FILEMATCH_FILTERS = {
  'Filter out HDR Formats': 
    r'^(?!.*{separator}(?:hdr(?:\d+|plus|\+|x)*){separator}).*$',
  
  'Filter out Dolby Vision': 
    r'^(?!.*{separator}(?:dolby{separator}*vision|dv){separator}).*$',
  
  'Filter out Cam Releases': 
    r'^(?!.*{separator}(?:cam|camrip|hdcam|dvdscr|dvdscreener|bdscr|screener|scr|ts|telesync|tc|telecine|workprint){separator}).*$',
  
  'Filter out Korean Subs': 
    r'^(?!.*{separator}(?:korsub|kor\.sub|korean\.sub|hc\.sub){separator}).*$',
};

@riverpod
class OrionSettings extends _$OrionSettings {
  SharedPreferences? _prefs;

  @override
  Future<OrionSettingsData> build() async {
    _prefs ??= await SharedPreferences.getInstance();
    
    final settings = OrionSettingsData(
      movies: OrionQuerySettings(
        limitCount: _prefs!.getInt('orion_movie_limit_count') ?? 50,
        streamTypes: _prefs!.getStringList('orion_movie_stream_types') ?? ['torrent'],
        minFileSize: _prefs!.getInt('orion_movie_min_file_size') ?? 500 * 1024 * 1024,
        maxFileSize: _prefs!.getInt('orion_movie_max_file_size') ?? 6 * 1024 * 1024 * 1024,
        accessTypes: _prefs!.getStringList('orion_movie_access_types') ?? 
            ['premiumize', 'premiumizetorrent'],
        sortValue: _prefs!.getString('orion_movie_sort_value') ?? 'videoquality',
        forceEnglishAudio: _prefs!.getBool('orion_movie_force_english_audio') ?? true,
        filematchFilters: _prefs!.getStringList('orion_movie_filematch_filters') ?? [],
      ),
      episodes: OrionQuerySettings(
        limitCount: _prefs!.getInt('orion_episode_limit_count') ?? 50,
        streamTypes: _prefs!.getStringList('orion_episode_stream_types') ?? ['torrent'],
        minFileSize: _prefs!.getInt('orion_episode_min_file_size') ?? 200 * 1024 * 1024,
        maxFileSize: _prefs!.getInt('orion_episode_max_file_size') ?? 3 * 1024 * 1024 * 1024,
        accessTypes: _prefs!.getStringList('orion_episode_access_types') ?? 
            ['premiumize', 'premiumizetorrent'],
        sortValue: _prefs!.getString('orion_episode_sort_value') ?? 'videoquality',
        forceEnglishAudio: _prefs!.getBool('orion_episode_force_english_audio') ?? true,
        filematchFilters: _prefs!.getStringList('orion_episode_filematch_filters') ?? [],
      ),
    );

    developer.log(
      'Settings initialized',
      name: 'OrionSettings',
      error: {
        'movieLimitCount': settings.movies.limitCount,
        'episodeLimitCount': settings.episodes.limitCount,
        'movieStreamTypes': settings.movies.streamTypes,
        'episodeStreamTypes': settings.episodes.streamTypes,
      },
    );

    return settings;
  }

  Future<void> updateMovieLimitCount(int value) async {
    developer.log(
      'Updating movie limit count',
      name: 'OrionSettings',
      error: {'value': value},
    );
    await _prefs?.setInt('orion_movie_limit_count', value);
    ref.invalidateSelf();
  }

  Future<void> updateMovieStreamTypes(List<String> types) async {
    developer.log(
      'Updating movie stream types',
      name: 'OrionSettings',
      error: {'types': types},
    );
    await _prefs?.setStringList('orion_movie_stream_types', types);
    ref.invalidateSelf();
  }

  Future<void> updateMovieMinFileSize(int bytes) async {
    await _prefs?.setInt('orion_movie_min_file_size', bytes);
    ref.invalidateSelf();
  }

  Future<void> updateMovieMaxFileSize(int bytes) async {
    await _prefs?.setInt('orion_movie_max_file_size', bytes);
    ref.invalidateSelf();
  }

  Future<void> updateMovieAccessTypes(List<String> types) async {
    await _prefs?.setStringList('orion_movie_access_types', types);
    ref.invalidateSelf();
  }

  Future<void> updateMovieSortValue(String value) async {
    await _prefs?.setString('orion_movie_sort_value', value);
    ref.invalidateSelf();
  }

  Future<void> updateMovieForceEnglishAudio(bool value) async {
    await _prefs?.setBool('orion_movie_force_english_audio', value);
    ref.invalidateSelf();
  }

  Future<void> updateMovieFilematchFilters(List<String> filters) async {
    await _prefs?.setStringList('orion_movie_filematch_filters', filters);
    ref.invalidateSelf();
  }

  Future<void> updateEpisodeLimitCount(int value) async {
    developer.log(
      'Updating episode limit count',
      name: 'OrionSettings',
      error: {'value': value},
    );
    await _prefs?.setInt('orion_episode_limit_count', value);
    ref.invalidateSelf();
  }

  Future<void> updateEpisodeStreamTypes(List<String> types) async {
    developer.log(
      'Updating episode stream types',
      name: 'OrionSettings',
      error: {'types': types},
    );
    await _prefs?.setStringList('orion_episode_stream_types', types);
    ref.invalidateSelf();
  }

  Future<void> updateEpisodeMinFileSize(int bytes) async {
    await _prefs?.setInt('orion_episode_min_file_size', bytes);
    ref.invalidateSelf();
  }

  Future<void> updateEpisodeMaxFileSize(int bytes) async {
    await _prefs?.setInt('orion_episode_max_file_size', bytes);
    ref.invalidateSelf();
  }

  Future<void> updateEpisodeAccessTypes(List<String> types) async {
    await _prefs?.setStringList('orion_episode_access_types', types);
    ref.invalidateSelf();
  }

  Future<void> updateEpisodeSortValue(String value) async {
    await _prefs?.setString('orion_episode_sort_value', value);
    ref.invalidateSelf();
  }

  Future<void> updateEpisodeForceEnglishAudio(bool value) async {
    await _prefs?.setBool('orion_episode_force_english_audio', value);
    ref.invalidateSelf();
  }

  Future<void> updateEpisodeFilematchFilters(List<String> filters) async {
    await _prefs?.setStringList('orion_episode_filematch_filters', filters);
    ref.invalidateSelf();
  }
}

class OrionSettingsData {
  final OrionQuerySettings movies;
  final OrionQuerySettings episodes;

  const OrionSettingsData({
    required this.movies,
    required this.episodes,
  });
}

class OrionQuerySettings {
  final int limitCount;
  final List<String> streamTypes;
  final int minFileSize;
  final int maxFileSize;
  final List<String> accessTypes;
  final String sortValue;
  final bool forceEnglishAudio;
  final List<String> filematchFilters;

  const OrionQuerySettings({
    required this.limitCount,
    required this.streamTypes,
    required this.minFileSize,
    required this.maxFileSize,
    required this.accessTypes,
    required this.sortValue,
    required this.forceEnglishAudio,
    required this.filematchFilters,
  });

  String get fileSizeParam => '${minFileSize}_$maxFileSize';
  String get streamTypesParam => streamTypes.join(',');
  String get accessTypesParam => accessTypes.join(',');
  String? get audioLanguagesParam => forceEnglishAudio ? 'en' : null;
  String? get filematchParam => filematchFilters.isNotEmpty 
    ? filematchFilters.map((key) => FILEMATCH_FILTERS[key]).join('|')
    : null;
} 