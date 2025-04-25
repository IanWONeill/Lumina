import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:developer' as developer;
import '../../../features/sync/services/database_service.dart';

final databaseServiceProvider = Provider<DatabaseService>((ref) {
  return DatabaseService();
});

final searchQueryProvider = StateProvider<String>((ref) => '');

final isSearchLoadingProvider = StateProvider<bool>((ref) => false);

final isGenreSearchProvider = StateProvider<bool>((ref) => false);

final searchResultsProvider = StateNotifierProvider<SearchResultsNotifier, List<Map<String, dynamic>>>(
  (ref) {
    final dbService = ref.watch(databaseServiceProvider);
    final notifier = SearchResultsNotifier(dbService);
    
    ref.listen<String>(
      searchQueryProvider,
      (previous, next) async {
        if (next.isEmpty) {
          notifier.clearResults();
        } else {
          final isGenreSearch = ref.read(isGenreSearchProvider);
          if (!isGenreSearch) {
            ref.read(isSearchLoadingProvider.notifier).state = true;
            await notifier.search(next);
            ref.read(isSearchLoadingProvider.notifier).state = false;
          }
        }
      },
    );

    return notifier;
  },
);

final searchScreenControllerProvider = Provider((ref) {
  ref.onDispose(() {
    ref.read(searchQueryProvider.notifier).state = '';
    ref.read(isSearchLoadingProvider.notifier).state = false;
    ref.read(isGenreSearchProvider.notifier).state = false;
    ref.read(searchResultsProvider.notifier).clearResults();
  });
  return null;
});

class SearchResultsNotifier extends StateNotifier<List<Map<String, dynamic>>> {
  final DatabaseService _dbService;

  SearchResultsNotifier(this._dbService) : super([]);

  Future<void> search(String query) async {
    if (query.isEmpty) {
      state = [];
      return;
    }

    try {
      developer.log(
        'Starting search',
        name: 'SearchResultsNotifier',
        error: {'query': query},
      );
      
      final results = await _dbService.searchAll(query);
      
      developer.log(
        'Search completed',
        name: 'SearchResultsNotifier',
        error: {'resultCount': results.length},
      );
      
      state = results;
    } catch (e, stackTrace) {
      developer.log(
        'Error searching',
        name: 'SearchResultsNotifier',
        error: e,
        stackTrace: stackTrace,
        level: 1000,
      );
      state = [];
    }
  }

  Future<void> searchByGenre(int genreId) async {
    try {
      developer.log(
        'Starting genre search',
        name: 'SearchResultsNotifier',
        error: {'genreId': genreId},
      );
      
      final movies = await _dbService.getMoviesByGenre(genreId);
      final results = movies.map((movie) => {
        ...movie,
        'media_type': 'movie',
      }).toList();
      
      results.sort((a, b) {
        final aTitle = a['original_title'].toString().toLowerCase();
        final bTitle = b['original_title'].toString().toLowerCase();
        
        final aSortTitle = aTitle.startsWith('the ') ? aTitle.substring(4) : aTitle;
        final bSortTitle = bTitle.startsWith('the ') ? bTitle.substring(4) : bTitle;
        
        return aSortTitle.compareTo(bSortTitle);
      });
      
      developer.log(
        'Genre search completed',
        name: 'SearchResultsNotifier',
        error: {'resultCount': results.length},
      );
      
      state = results;
    } catch (e, stackTrace) {
      developer.log(
        'Error in genre search',
        name: 'SearchResultsNotifier',
        error: e,
        stackTrace: stackTrace,
        level: 1000,
      );
      state = [];
    }
  }

  void clearResults() {
    state = [];
  }

  void setResults(List<Map<String, dynamic>> results) {
    developer.log(
      'Setting search results',
      name: 'SearchResultsNotifier',
      error: {'resultCount': results.length},
    );
    state = results;
  }
} 