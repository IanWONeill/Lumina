import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/search_provider.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'dart:async';
import '../../player/screens/media_details_screen.dart';
import '../../tv_shows/screens/seasons_screen.dart';
import '../../movies/providers/movie_details_provider.dart';
import '../../tv_shows/providers/tv_show_details_provider.dart';
import 'dart:developer' as developer;

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchController = TextEditingController();
  final SpeechToText _speechToText = SpeechToText();
  bool _showKeyboard = false;

  @override
  void initState() {
    super.initState();
    _initSpeech();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(searchResultsProvider.notifier).clearResults();
      ref.read(searchQueryProvider.notifier).state = '';
    });
  }

  Future<void> _initSpeech() async {
    await _speechToText.initialize();
  }

  void _handleSearch(String query) {
    developer.log(
      'Handling search',
      name: 'SearchScreen',
      error: {'query': query},
    );
    
    if (query.isNotEmpty) {
      ref.read(searchQueryProvider.notifier).state = query;
      setState(() {
        _showKeyboard = false;
      });
    }
  }

  void _handleVoiceInput() async {
    if (!_speechToText.isAvailable) {
      developer.log(
        'Speech recognition not available',
        name: 'SearchScreen',
        level: 900,
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _VoiceInputDialog(
        onResult: (String text) {
          _handleSearch(text);
        },
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => WillPopScope(
        onWillPop: () async {
          ref.read(searchResultsProvider.notifier).clearResults();
          ref.read(searchQueryProvider.notifier).state = '';
          return true;
        },
        child: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      autofocus: true,
                      onPressed: () {
                        setState(() {
                          _showKeyboard = true;
                          _searchController.clear();
                        });
                      },
                      icon: Icon(
                        Icons.keyboard,
                        size: 32,
                        color: Colors.greenAccent[400],
                      ),
                      label: const Text(
                        'Keyboard Input',
                        style: TextStyle(
                          fontSize: 18,
                        ),
                      ),
                      style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.resolveWith<Color>((states) {
                          if (states.contains(MaterialState.focused)) {
                            return Colors.blue;
                          }
                          return Colors.white10;
                        }),
                        foregroundColor: MaterialStateProperty.all(Colors.white),
                        padding: MaterialStateProperty.all(
                          const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 24),
                    ElevatedButton.icon(
                      onPressed: _handleVoiceInput,
                      icon: Icon(
                        Icons.mic,
                        size: 32,
                        color: Colors.greenAccent[400],
                      ),
                      label: const Text(
                        'Speech Input',
                        style: TextStyle(
                          fontSize: 18,
                        ),
                      ),
                      style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.resolveWith<Color>((states) {
                          if (states.contains(MaterialState.focused)) {
                            return Colors.blue;
                          }
                          return Colors.white10;
                        }),
                        foregroundColor: MaterialStateProperty.all(Colors.white),
                        padding: MaterialStateProperty.all(
                          const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                
                if (_showKeyboard) ...[
                  TextField(
                    controller: _searchController,
                    autofocus: true,
                    decoration: const InputDecoration(
                      hintText: 'Enter movie, TV show, or actor name...',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: _handleSearch,
                  ),
                  const SizedBox(height: 20),
                ],

                Expanded(
                  child: _buildSearchResults(),
                ),
              ],
            ),
          ),
        ),
      );

  Widget _buildSearchResults() {
    final results = ref.watch(searchResultsProvider);
    final isLoading = ref.watch(isSearchLoadingProvider);
    final query = ref.watch(searchQueryProvider);
    
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (query.isEmpty && results.isEmpty) {
      return const Center(
        child: Text(
          'Search for a Movie, TV Show, or Actor name',
          style: TextStyle(fontSize: 25),
        ),
      );
    }

    if (query.isNotEmpty && results.isEmpty) {
      return const Center(
        child: Text(
          'No results found',
          style: TextStyle(fontSize: 16),
        ),
      );
    }

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final item = results[index];
        final isMovie = item['media_type'] == 'movie';
        final hasActor = item.containsKey('actor_name');
        final isActorEntry = hasActor && !item.containsKey('media_type');
        
        return ListTile(
          title: Text(
            isMovie ? item['original_title'] : item['original_name'],
            style: const TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Wrap(
              spacing: 12,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isMovie ? Colors.blue.withOpacity(0.2) : Colors.purple.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isMovie ? Colors.blue : Colors.purple,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    isMovie ? 'Movie' : 'TV Show',
                    style: TextStyle(
                      color: isMovie ? Colors.blue : Colors.purple,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (hasActor)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.orange,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.person,
                          size: 16,
                          color: Colors.orange,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          item['actor_name'],
                          style: const TextStyle(
                            color: Colors.orange,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          onTap: () async {
            if (isMovie) {
              final tmdbId = item['tmdb_id'] as int;
              
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const Center(
                  child: CircularProgressIndicator(),
                ),
              );

              try {
                final movie = await ref.read(movieDetailsProvider(tmdbId).future);
                
                if (context.mounted) Navigator.pop(context);

                if (context.mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MediaDetailsScreen(
                        media: movie,
                        isMovie: true,
                      ),
                    ),
                  );
                }
              } catch (e, stackTrace) {
                if (context.mounted) Navigator.pop(context);
                developer.log(
                  'Error fetching movie details',
                  name: 'SearchScreen',
                  error: e,
                  stackTrace: stackTrace,
                  level: 1000,
                );
              }
            } else if (!isMovie && !isActorEntry) {
              final tmdbId = item['tmdb_id'] as int;
              
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const Center(
                  child: CircularProgressIndicator(),
                ),
              );

              try {
                final show = await ref.read(tvShowDetailsProvider(tmdbId).future);
                
                if (context.mounted) Navigator.pop(context);

                if (context.mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SeasonsScreen(show: show),
                    ),
                  );
                }
              } catch (e, stackTrace) {
                if (context.mounted) Navigator.pop(context);
                developer.log(
                  'Error fetching TV show details',
                  name: 'SearchScreen',
                  error: e,
                  stackTrace: stackTrace,
                  level: 1000,
                );
              }
            }
          },
        );
      },
    );
  }
}

class _VoiceInputDialog extends StatefulWidget {
  final Function(String) onResult;

  const _VoiceInputDialog({required this.onResult});

  @override
  State<_VoiceInputDialog> createState() => _VoiceInputDialogState();
}

class _VoiceInputDialogState extends State<_VoiceInputDialog> {
  final SpeechToText _speechToText = SpeechToText();
  String _lastWords = '';
  Timer? _silenceTimer;

  @override
  void initState() {
    super.initState();
    _startListening();
  }

  @override
  void dispose() {
    _silenceTimer?.cancel();
    _speechToText.stop();
    super.dispose();
  }

  void _startListening() async {
    await _speechToText.listen(
      onResult: _onSpeechResult,
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 2),
      partialResults: true,
      cancelOnError: true,
      listenMode: ListenMode.confirmation,
    );
    setState(() {});
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    setState(() {
      _lastWords = result.recognizedWords;
    });

    _silenceTimer?.cancel();
    _silenceTimer = Timer(const Duration(seconds: 2), () {
      if (_lastWords.isNotEmpty) {
        Navigator.of(context).pop();
        widget.onResult(_lastWords);
      }
    });
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Listening...'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.mic,
              size: 50,
              color: Colors.blue,
            ),
            const SizedBox(height: 16),
            Text(
              _lastWords.isEmpty
                  ? 'Say something...'
                  : _lastWords,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              _speechToText.stop();
              Navigator.of(context).pop();
            },
            child: const Text('Cancel'),
          ),
        ],
      );
}

class EpisodeDetails {
  final int id;
  final int showId;
  final String name;
  final String overview;
  final String airDate;
  final int episodeNumber;
  final int seasonId;

  EpisodeDetails({
    required this.id,
    required this.showId,
    required this.name,
    required this.overview,
    required this.airDate,
    required this.episodeNumber,
    required this.seasonId,
  });
}