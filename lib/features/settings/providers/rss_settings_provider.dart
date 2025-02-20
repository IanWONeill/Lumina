import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'dart:developer' as developer;

enum RSSDisplayMode {
  stacked,
  series
}

enum RSSScrollSpeed {
  slow,
  medium,
  fast
}

class RSSFeedConfig {
  final String url;
  final String name;

  const RSSFeedConfig({
    required this.url,
    required this.name,
  });

  static List<RSSFeedConfig> getDefaultFeeds() => [
    RSSFeedConfig(
      url: '',
      name: 'Disabled',
    ),
    RSSFeedConfig(
      url: 'https://www.filmjabber.com/rss/rss-dvd-releases.php',
      name: 'New DVD Releases',
    ),
    RSSFeedConfig(
      url: 'https://www.filmjabber.com/rss/rss-dvd-upcoming.php',
      name: 'Upcoming DVD Releases',
    ),
    RSSFeedConfig(
      url: 'https://www.filmjabber.com/rss/rss-upcoming.php',
      name: 'Coming to Theaters',
    ),
    RSSFeedConfig(
      url: 'https://www.filmjabber.com/rss/rss-current.php',
      name: 'Now Playing Movies',
    ),
    RSSFeedConfig(
      url: 'http://feeds.feedburner.com/Onvideo',
      name: 'OnVideo Movie News',
    ),
    RSSFeedConfig(
      url: 'https://www.fandango.com/rss/newmovies.rss',
      name: 'Fandango New Movies',
    ),
    RSSFeedConfig(
      url: 'https://www.fandango.com/rss/comingsoonmovies.rss',
      name: 'Fandango Coming Soon Movies',
    ),
    RSSFeedConfig(
      url: 'https://www.fandango.com/rss/top10boxoffice.rss',
      name: 'Fandango Box Office Top 10',
    ),
  ];
}

class RSSSettingsState {
  final List<String> selectedFeeds;
  final RSSDisplayMode displayMode;
  final RSSScrollSpeed scrollSpeed;

  const RSSSettingsState({
    required this.selectedFeeds,
    required this.displayMode,
    required this.scrollSpeed,
  });

  factory RSSSettingsState.fromJson(Map<String, dynamic> json) {
    developer.log(
      'Creating RSSSettingsState from JSON',
      name: 'RSSSettings',
      error: {
        'json': json,
      },
    );
    
    final selectedFeeds = (json['selectedFeeds'] as List<dynamic>?)
        ?.map((e) => e as String)
        .toList() ?? List.filled(3, '');
        
    return RSSSettingsState(
      selectedFeeds: selectedFeeds,
      displayMode: RSSDisplayMode.values.byName(json['displayMode'] ?? 'stacked'),
      scrollSpeed: RSSScrollSpeed.values.byName(json['scrollSpeed'] ?? 'medium'),
    );
  }

  Map<String, dynamic> toJson() => {
    'selectedFeeds': selectedFeeds,
    'displayMode': displayMode.name,
    'scrollSpeed': scrollSpeed.name,
  };
}

class RSSSettingsNotifier extends StateNotifier<RSSSettingsState> {
  RSSSettingsNotifier() : super(
    RSSSettingsState(
      selectedFeeds: List.filled(3, ''),
      displayMode: RSSDisplayMode.stacked,
      scrollSpeed: RSSScrollSpeed.medium,
    )
  ) {
    developer.log(
      'RSSSettingsNotifier initialized',
      name: 'RSSSettings',
      error: {
        'initialState': {
          'selectedFeeds': state.selectedFeeds,
          'displayMode': state.displayMode.toString(),
          'scrollSpeed': state.scrollSpeed.toString(),
        },
      },
    );
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = prefs.getString('rss_settings');
      
      developer.log(
        'Loading RSS settings from storage',
        name: 'RSSSettings',
        error: {
          'settingsFound': settingsJson != null,
          'rawSettings': settingsJson,
        },
      );

      if (settingsJson != null) {
        final Map<String, dynamic> settings = json.decode(settingsJson);
        state = RSSSettingsState.fromJson(settings);
        
        developer.log(
          'RSS settings loaded successfully',
          name: 'RSSSettings',
          error: {
            'loadedState': {
              'selectedFeeds': state.selectedFeeds,
              'displayMode': state.displayMode.toString(),
              'scrollSpeed': state.scrollSpeed.toString(),
            },
          },
        );
      }
    } catch (e) {
      developer.log(
        'Error loading RSS settings',
        name: 'RSSSettings',
        error: {
          'error': e.toString(),
          'stackTrace': StackTrace.current.toString(),
        },
      );
    }
  }

  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = json.encode(state.toJson());
      
      developer.log(
        'Saving RSS settings',
        name: 'RSSSettings',
        error: {
          'settingsToSave': {
            'selectedFeeds': state.selectedFeeds,
            'displayMode': state.displayMode.toString(),
            'scrollSpeed': state.scrollSpeed.toString(),
          },
          'jsonToSave': settingsJson,
        },
      );

      await prefs.setString('rss_settings', settingsJson);
      
      developer.log(
        'RSS settings saved successfully',
        name: 'RSSSettings',
      );
    } catch (e) {
      developer.log(
        'Error saving RSS settings',
        name: 'RSSSettings',
        error: {
          'error': e.toString(),
          'stackTrace': StackTrace.current.toString(),
        },
      );
    }
  }

  void updateFeed(int index, String url) {
    final newFeeds = List<String>.from(state.selectedFeeds);
    while (newFeeds.length <= index) {
      newFeeds.add('');
    }
    newFeeds[index] = url;
    
    developer.log(
      'Updating RSS feed',
      name: 'RSSSettings',
      error: {
        'index': index,
        'url': url,
        'newFeeds': newFeeds,
      },
    );
    
    state = RSSSettingsState(
      selectedFeeds: newFeeds,
      displayMode: state.displayMode,
      scrollSpeed: state.scrollSpeed,
    );
    _saveSettings();
  }

  void setDisplayMode(RSSDisplayMode mode) {
    state = RSSSettingsState(
      selectedFeeds: state.selectedFeeds,
      displayMode: mode,
      scrollSpeed: state.scrollSpeed,
    );
    _saveSettings();
  }

  void setScrollSpeed(RSSScrollSpeed speed) {
    state = RSSSettingsState(
      selectedFeeds: state.selectedFeeds,
      displayMode: state.displayMode,
      scrollSpeed: speed,
    );
    _saveSettings();
  }
}

final rssSettingsProvider = StateNotifierProvider<RSSSettingsNotifier, RSSSettingsState>((ref) {
  return RSSSettingsNotifier();
}); 