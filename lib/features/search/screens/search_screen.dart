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
import '../../sync/services/database_service.dart';
import '../../search/screens/genre_results_screen.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchController = TextEditingController();
  final _keyboardFocusNode = FocusNode();
  final _genreFocusNode = FocusNode();
  final _textFieldFocusNode = FocusNode();
  final _speechFocusNode = FocusNode();
  final SpeechToText _speechToText = SpeechToText();
  bool _showKeyboard = false;
  bool _isKeyboardFocused = false;
  bool _isTextFieldFocused = false;
  bool _isGenreFocused = false;
  bool _isSpeechFocused = false;
  final Map<String, int> _genreIds = {
    'Action': 28,
    'Animation': 16,
    'Comedy': 35,
    'Crime': 80,
    'Documentary': 99,
    'Drama': 18,
    'Fantasy': 14,
    'History': 36,
    'Horror': 27,
    'Mystery': 9648,
    'Romance': 10749,
    'Science Fiction': 878,
    'Thriller': 53,
    'War': 10752,
    'Western': 37,
  };

  @override
  void initState() {
    super.initState();
    _initSpeech();
    _setupFocusListeners();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(searchResultsProvider.notifier).clearResults();
      ref.read(searchQueryProvider.notifier).state = '';
    });
  }

  void _setupFocusListeners() {
    _keyboardFocusNode.addListener(() {
      setState(() => _isKeyboardFocused = _keyboardFocusNode.hasFocus);
    });
    _genreFocusNode.addListener(() {
      setState(() => _isGenreFocused = _genreFocusNode.hasFocus);
    });
    _textFieldFocusNode.addListener(() {
      setState(() => _isTextFieldFocused = _textFieldFocusNode.hasFocus);
    });
    _speechFocusNode.addListener(() {
      setState(() => _isSpeechFocused = _speechFocusNode.hasFocus);
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

  void _showGenreSelector() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        contentPadding: const EdgeInsets.all(5),
        insetPadding: const EdgeInsets.all(5),
        content: Container(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          child: LayoutBuilder(
            builder: (context, constraints) => GridView.count(
              crossAxisCount: 3,
              mainAxisSpacing: 5,
              crossAxisSpacing: 5,
              childAspectRatio: (constraints.maxWidth / 3 - 5) / 
                              (constraints.maxHeight / 5 - 5),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildGenreButton('Action', Icons.local_fire_department),
                _buildGenreButton('Animation', Icons.movie_creation),
                _buildGenreButton('Comedy', Icons.sentiment_very_satisfied),
                _buildGenreButton('Crime', Icons.gavel),
                _buildGenreButton('Documentary', Icons.camera_roll),
                _buildGenreButton('Drama', Icons.theater_comedy),
                _buildGenreButton('Fantasy', Icons.auto_fix_high),
                _buildGenreButton('History', Icons.history),
                _buildGenreButton('Horror', Icons.warning_amber),
                _buildGenreButton('Mystery', Icons.search),
                _buildGenreButton('Romance', Icons.favorite),
                _buildGenreButton('Science Fiction', Icons.rocket),
                _buildGenreButton('Thriller', Icons.nightlife),
                _buildGenreButton('War', Icons.gavel),
                _buildGenreButton('Western', Icons.landscape),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGenreButton(String genre, IconData icon) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final fontSize = constraints.maxWidth * 0.1;
        final iconSize = constraints.maxHeight * 0.4;
        
        return ElevatedButton.icon(
          onPressed: () async {
            Navigator.pop(context);
            
            final genreId = _genreIds[genre];
            if (genreId != null) {
              if (context.mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => GenreResultsScreen(
                      genreName: genre,
                    ),
                    settings: RouteSettings(arguments: genre),
                  ),
                );
              }

              ref.read(isGenreSearchProvider.notifier).state = true;
              ref.read(isSearchLoadingProvider.notifier).state = true;
              
              await ref.read(searchResultsProvider.notifier)
                       .searchByGenre(genreId);
              
              ref.read(searchQueryProvider.notifier).state = genre;
              ref.read(isSearchLoadingProvider.notifier).state = false;
              ref.read(isGenreSearchProvider.notifier).state = false;
            }
          },
          icon: Icon(
            icon,
            size: iconSize,
            color: Colors.greenAccent[400],
          ),
          label: Text(
            genre,
            style: TextStyle(
              fontSize: fontSize,
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
              EdgeInsets.symmetric(
                horizontal: constraints.maxWidth * 0.05,
                vertical: constraints.maxHeight * 0.1,
              ),
            ),
          ),
        );
      }
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _keyboardFocusNode.dispose();
    _genreFocusNode.dispose();
    _textFieldFocusNode.dispose();
    _speechFocusNode.dispose();
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
                      focusNode: _keyboardFocusNode,
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
                      focusNode: _speechFocusNode,
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
                    const SizedBox(width: 24),
                    ElevatedButton.icon(
                      focusNode: _genreFocusNode,
                      onPressed: _showGenreSelector,
                      icon: Icon(
                        Icons.category,
                        size: 32,
                        color: Colors.greenAccent[400],
                      ),
                      label: const Text(
                        'Genre Search',
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
                    focusNode: _textFieldFocusNode,
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
      String hintText = '';
      if (_isGenreFocused) {
        hintText = 'Search for a Movie Genre';
      } else if (_isKeyboardFocused || _isTextFieldFocused || _showKeyboard) {
        hintText = 'Search for a Movie, TV Show, or Actor name by typing it in';
      } else if (_isSpeechFocused) {
        hintText = 'Search for a Movie, TV Show, or Actor name by talking into your remote';
      }

      return Center(
        child: Text(
          hintText,
          style: const TextStyle(fontSize: 25),
          textAlign: TextAlign.center,
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
  Timer? _initialTimer;
  bool _hasStartedTalking = false;

  @override
  void initState() {
    super.initState();
    _startListening();
    _initialTimer = Timer(const Duration(seconds: 8), () {
      if (!_hasStartedTalking) {
        _speechToText.stop();
        Navigator.of(context).pop();
      }
    });
  }

  @override
  void dispose() {
    _silenceTimer?.cancel();
    _initialTimer?.cancel();
    _speechToText.stop();
    super.dispose();
  }

  void _startListening() async {
    await _speechToText.listen(
      onResult: _onSpeechResult,
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 10),
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

    if (!_hasStartedTalking && result.recognizedWords.isNotEmpty) {
      _hasStartedTalking = true;
      _initialTimer?.cancel();
    }

    _silenceTimer?.cancel();
    if (_hasStartedTalking) {
      _silenceTimer = Timer(const Duration(seconds: 2), () {
        if (_lastWords.isNotEmpty) {
          Navigator.of(context).pop();
          widget.onResult(_lastWords);
        }
      });
    }
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