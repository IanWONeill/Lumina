import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import '../models/season.dart';
import '../providers/episodes_provider.dart';
import 'package:flutter/services.dart';
import '../../player/screens/media_details_screen.dart';

class EpisodeListPanel extends HookConsumerWidget {
  final Season season;

  const EpisodeListPanel({
    super.key,
    required this.season,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final episodes = ref.watch(seasonEpisodesProvider(season));
    final itemScrollController = useMemoized(() => ItemScrollController());
    final itemPositionsListener = useMemoized(() => ItemPositionsListener.create());

    return episodes.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
      data: (episodes) => ScrollablePositionedList.builder(
        itemCount: episodes.length,
        itemScrollController: itemScrollController,
        itemPositionsListener: itemPositionsListener,
        itemBuilder: (context, index) {
          final episode = episodes[index];
          return Focus(
            autofocus: index == 0,
            onFocusChange: (hasFocus) {
              if (hasFocus) {
                ref.read(selectedEpisodeProvider.notifier).select(episode);
              }
            },
            onKey: (node, event) {
              if (event is RawKeyDownEvent && 
                  event.logicalKey == LogicalKeyboardKey.select) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MediaDetailsScreen(
                      media: episode,
                      isMovie: false,
                    ),
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
                  child: Row(
                    children: [
                      SizedBox(
                        width: 40,
                        child: Text(
                          episode.episodeNumber.toString(),
                          style: TextStyle(
                            fontSize: 16,
                            color: focused ? Colors.blue : null,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          episode.name,
                          style: TextStyle(
                            fontSize: 16,
                            color: focused ? Colors.blue : null,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (episode.isWatched)
                        const Icon(
                          Icons.check_circle,
                          size: 16,
                          color: Colors.green,
                        ),
                    ],
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