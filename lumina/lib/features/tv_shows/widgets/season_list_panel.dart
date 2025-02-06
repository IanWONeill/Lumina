import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import '../models/tv_show.dart';
import '../providers/seasons_provider.dart';
import '../screens/episodes_screen.dart';

class SeasonListPanel extends HookConsumerWidget {
  final TVShow show;

  const SeasonListPanel({
    super.key,
    required this.show,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final seasons = ref.watch(seasonsProvider(show.tmdbId));
    final itemScrollController = useMemoized(() => ItemScrollController());
    final itemPositionsListener = useMemoized(() => ItemPositionsListener.create());

    return seasons.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
      data: (seasons) => ScrollablePositionedList.builder(
        itemCount: seasons.length,
        itemScrollController: itemScrollController,
        itemPositionsListener: itemPositionsListener,
        itemBuilder: (context, index) {
          final season = seasons[index];
          return Focus(
            autofocus: index == 0,
            onFocusChange: (hasFocus) {
              if (hasFocus) {
                ref.read(selectedSeasonProvider.notifier).select(season);
              }
            },
            onKey: (node, event) {
              if (event is RawKeyDownEvent &&
                  event.logicalKey == LogicalKeyboardKey.select) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EpisodesScreen(season: season),
                  ),
                );
                return KeyEventResult.handled;
              }
              return KeyEventResult.ignored;
            },
            child: Builder(
              builder: (context) {
                final focused = Focus.of(context).hasFocus;
                return Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    color: focused ? Colors.blue.withOpacity(0.2) : null,
                    border: focused 
                      ? Border.all(color: Colors.blue, width: 2)
                      : null,
                  ),
                  child: Text(
                    'Season ${season.seasonNumber}',
                    style: TextStyle(
                      fontSize: 16,
                      color: focused ? Colors.blue : null,
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
} 