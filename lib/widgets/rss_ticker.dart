import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rss_dart/dart_rss.dart';
import 'package:http/http.dart' as http;
import '../features/settings/providers/rss_settings_provider.dart';
import 'dart:async';
import 'dart:developer' as developer;

final rssFeedDataProvider = StateNotifierProvider<RSSFeedDataNotifier, Map<String, List<String>>>((ref) {
  final notifier = RSSFeedDataNotifier(ref);
  
  ref.listen(rssSettingsProvider, (previous, next) {
    developer.log(
      'RSS settings changed, reinitializing feeds',
      name: 'RSSFeedData',
      error: {
        'previousFeeds': previous?.selectedFeeds,
        'newFeeds': next.selectedFeeds,
      },
    );
    notifier._initializeFeeds();
  });
  
  return notifier;
});

class RSSFeedDataNotifier extends StateNotifier<Map<String, List<String>>> {
  final Ref ref;
  Timer? _refreshTimer;

  RSSFeedDataNotifier(this.ref) : super({}) {
    developer.log(
      'RSSFeedDataNotifier initialized',
      name: 'RSSFeedData',
    );
    
    Future.microtask(() {
      final settings = ref.read(rssSettingsProvider);
      developer.log(
        'Initial settings state',
        name: 'RSSFeedData',
        error: {
          'selectedFeeds': settings.selectedFeeds,
        },
      );
      _initializeFeeds();
    });

    _refreshTimer = Timer.periodic(
      const Duration(hours: 12),
      (_) => _initializeFeeds()
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializeFeeds() async {
    developer.log(
      'Starting feed initialization',
      name: 'RSSFeedData',
    );
    
    final settings = ref.read(rssSettingsProvider);
    final defaultFeeds = RSSFeedConfig.getDefaultFeeds();
    final enabledFeeds = settings.selectedFeeds
        .where((url) => url.isNotEmpty)
        .map((url) => defaultFeeds.firstWhere(
          (feed) => feed.url == url,
          orElse: () => RSSFeedConfig(url: url, name: 'Custom Feed'),
        ))
        .toList();
    
    developer.log(
      'Processing enabled feeds',
      name: 'RSSFeedData',
      error: {
        'enabledFeedsCount': enabledFeeds.length,
        'feeds': enabledFeeds.map((f) => '${f.name}: ${f.url}').toList(),
        'selectedFeeds': settings.selectedFeeds,
      },
    );
    
    if (enabledFeeds.isEmpty) {
      developer.log(
        'No enabled feeds found',
        name: 'RSSFeedData',
      );
      state = {};
      return;
    }

    final newState = <String, List<String>>{};
    
    for (final feed in enabledFeeds) {
      try {
        developer.log(
          'Fetching feed',
          name: 'RSSFeedData',
          error: {
            'feedName': feed.name,
            'feedUrl': feed.url,
          },
        );
        
        final items = await _fetchFeed(feed);
        newState[feed.url] = items;
        
        developer.log(
          'Feed fetched successfully',
          name: 'RSSFeedData',
          error: {
            'feedName': feed.name,
            'itemCount': items.length,
          },
        );
      } catch (e) {
        developer.log(
          'Error processing feed',
          name: 'RSSFeedData',
          error: {
            'feedName': feed.name,
            'error': e.toString(),
          },
        );
      }
    }
    
    state = newState;
    
    developer.log(
      'Feed initialization completed',
      name: 'RSSFeedData',
      error: {
        'feedCount': state.length,
        'feeds': state.map((k, v) => MapEntry(k, v.length)),
      },
    );
  }

  Future<List<String>> _fetchFeed(RSSFeedConfig feed) async {
    developer.log(
      'Fetching feed',
      name: 'RSSFeedData',
      error: {
        'feedName': feed.name,
        'feedUrl': feed.url,
      },
    );

    try {
      final response = await http.get(
        Uri.parse(feed.url),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
        },
      );
      
      if (response.statusCode == 200) {
        final rssFeed = RssFeed.parse(response.body);
        final items = rssFeed.items
            ?.map((item) => item.title ?? '')
            .where((title) => title.isNotEmpty)
            .toList() ?? [];
        
        developer.log(
          'Feed parsed successfully',
          name: 'RSSFeedData',
          error: {
            'feedName': feed.name,
            'itemCount': items.length,
            'firstItem': items.isNotEmpty ? items.first : 'no items',
          },
        );
        
        return items;
      }
      throw Exception('HTTP ${response.statusCode}');
    } catch (e) {
      developer.log(
        'Error fetching feed',
        name: 'RSSFeedData',
        error: {
          'feedName': feed.name,
          'error': e.toString(),
        },
      );
      rethrow;
    }
  }
}

class RSSTicker extends ConsumerStatefulWidget {
  const RSSTicker({super.key});

  @override
  ConsumerState<RSSTicker> createState() => _RSSTickerState();
}

class _RSSTickerState extends ConsumerState<RSSTicker> {
  final Map<String, ScrollController> _scrollControllers = {};
  Timer? _scrollTimer;

  @override
  void dispose() {
    _scrollTimer?.cancel();
    for (final controller in _scrollControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _initializeScrollController(String feedUrl) {
    _scrollControllers[feedUrl]?.dispose();
    _scrollControllers[feedUrl] = ScrollController();
  }

  void _startScrolling(RSSScrollSpeed speed) {
    _scrollTimer?.cancel();

    final scrollDuration = switch (speed) {
      RSSScrollSpeed.slow => const Duration(milliseconds: 50),
      RSSScrollSpeed.medium => const Duration(milliseconds: 30),
      RSSScrollSpeed.fast => const Duration(milliseconds: 15),
    };

    _scrollTimer = Timer.periodic(scrollDuration, (_) {
      for (final controller in _scrollControllers.values) {
        if (controller.hasClients) {
          final maxScroll = controller.position.maxScrollExtent;
          final currentScroll = controller.offset;
          
          if (currentScroll >= maxScroll) {
            controller.jumpTo(0);
          } else {
            controller.jumpTo(currentScroll + 1);
          }
        }
      }
    });
  }

  Widget _buildFeedTicker(RSSFeedConfig feed, double height, List<String> items) {
    if (items.isEmpty) return const SizedBox.shrink();
    
    _initializeScrollController(feed.url);
    
    return SizedBox(
      height: height,
      child: Row(
        children: [
          IntrinsicWidth(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.2),
                border: Border(
                  right: BorderSide(
                    color: Colors.blue.withOpacity(0.3),
                    width: 1,
                  ),
                ),
              ),
              child: Center(
                child: Text(
                  feed.name,
                  style: TextStyle(
                    color: Colors.blue.withOpacity(0.9),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: _scrollControllers[feed.url],
              scrollDirection: Axis.horizontal,
              itemCount: items.length * 2,
              itemBuilder: (context, index) {
                final actualIndex = index % items.length;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Center(
                    child: Text(
                      items[actualIndex],
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(rssSettingsProvider);
    final feedData = ref.watch(rssFeedDataProvider);
    final defaultFeeds = RSSFeedConfig.getDefaultFeeds();
    final enabledFeeds = settings.selectedFeeds
        .where((url) => url.isNotEmpty)
        .map((url) => defaultFeeds.firstWhere(
          (feed) => feed.url == url,
          orElse: () => RSSFeedConfig(url: url, name: 'Custom Feed'),
        ))
        .toList();

    if (enabledFeeds.isEmpty) return const SizedBox.shrink();

    _startScrolling(settings.scrollSpeed);

    return RepaintBoundary(
      child: Container(
        height: settings.displayMode == RSSDisplayMode.stacked
            ? enabledFeeds.length * 30.0
            : 30.0,
        decoration: BoxDecoration(
          color: Colors.black87,
          border: Border(
            top: BorderSide(
              color: Colors.blue.withOpacity(0.3),
              width: 1,
            ),
          ),
        ),
        child: settings.displayMode == RSSDisplayMode.stacked
            ? Column(
                children: [
                  for (int i = 0; i < enabledFeeds.length; i++) ...[
                    Expanded(
                      child: _buildFeedTicker(
                        enabledFeeds[i],
                        30.0,
                        feedData[enabledFeeds[i].url] ?? [],
                      ),
                    ),
                    if (i < enabledFeeds.length - 1)
                      Container(
                        height: 1,
                        color: Colors.blue.withOpacity(0.3),
                      ),
                  ],
                ],
              )
            : Row(
                children: enabledFeeds.map((feed) {
                  final items = feedData[feed.url] ?? [];
                  if (items.isEmpty) return const SizedBox.shrink();
                  return Expanded(
                    child: _buildFeedTicker(feed, 30.0, items),
                  );
                }).toList(),
              ),
      ),
    );
  }
} 