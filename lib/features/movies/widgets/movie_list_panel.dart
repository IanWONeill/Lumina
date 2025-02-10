import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import '../providers/movies_provider.dart';
import 'package:flutter/services.dart';
import '../../player/screens/media_details_screen.dart';
import '../providers/alphabet_navigation_provider.dart';

class MovieListPanel extends HookConsumerWidget {
  const MovieListPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final movies = ref.watch(moviesProvider);
    final itemScrollController = useMemoized(() => ItemScrollController());
    final itemPositionsListener = useMemoized(() => ItemPositionsListener.create());
    
    final jumpToIndex = ref.watch(alphabetNavigationProvider);
    
    useEffect(() {
      if (jumpToIndex != null) {
        itemScrollController.jumpTo(index: jumpToIndex);
      }
      return null;
    }, [jumpToIndex]);

    return Row(
      children: [
        Expanded(
          flex: 4,
          child: movies.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Error: $err')),
            data: (movies) => ScrollablePositionedList.builder(
              itemCount: movies.length,
              itemScrollController: itemScrollController,
              itemPositionsListener: itemPositionsListener,
              itemBuilder: (context, index) {
                final movie = movies[index];
                return Focus(
                  autofocus: index == 0,
                  onFocusChange: (hasFocus) {
                    if (hasFocus) {
                      ref.read(selectedMovieProvider.notifier).select(movie);
                    }
                  },
                  onKey: (node, event) {
                    if (event is RawKeyDownEvent && 
                        event.logicalKey == LogicalKeyboardKey.select) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MediaDetailsScreen(
                            media: movie,
                            isMovie: true,
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
                            Expanded(
                              child: Text(
                                movie.releaseDate.isNotEmpty 
                                    ? '${movie.originalTitle} (${movie.releaseDate.substring(0, 4)})'
                                    : movie.originalTitle,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: focused ? Colors.blue : null,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (movie.isWatched)
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
          ),
        ),
        const _AlphabetSelector(),
      ],
    );
  }
}

class _AlphabetSelector extends HookConsumerWidget {
  const _AlphabetSelector();

  static const _letters = [
    'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M',
    'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z',
  ];

  double _getScale(int currentIndex, int focusedIndex) {
    final distance = (currentIndex - focusedIndex).abs();
    if (distance == 0) return 3.0;
    if (distance == 1) return 2.0;
    return 1.0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final focusedIndexState = useState<int?>(null);

    return SizedBox(
      width: 25,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final itemHeight = constraints.maxHeight / _letters.length;
          
          return ScrollablePositionedList.builder(
            itemCount: _letters.length,
            itemBuilder: (context, index) {
              final letter = _letters[index];
              return Focus(
                autofocus: false,
                onFocusChange: (hasFocus) {
                  if (hasFocus) {
                    focusedIndexState.value = index;
                  }
                },
                onKey: (node, event) {
                  if (event is RawKeyDownEvent &&
                      event.logicalKey == LogicalKeyboardKey.select) {
                    final movies = ref.read(moviesProvider).value ?? [];
                    ref.read(alphabetNavigationProvider.notifier)
                       .jumpToLetter(letter, movies);
                    return KeyEventResult.handled;
                  }
                  return KeyEventResult.ignored;
                },
                child: Builder(
                  builder: (context) {
                    final focused = Focus.of(context).hasFocus;
                    final scale = _getScale(
                      index,
                      focusedIndexState.value ?? 0,
                    );

                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      curve: Curves.easeOutCubic,
                      height: itemHeight,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: focused ? Colors.blue.withOpacity(0.2) : null,
                        border: focused 
                          ? Border.all(color: Colors.blue, width: 2)
                          : null,
                      ),
                      child: Transform.scale(
                        scale: scale,
                        child: Text(
                          letter,
                          style: TextStyle(
                            fontSize: itemHeight * 0.4,
                            color: focused ? Colors.blue : null,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
} 