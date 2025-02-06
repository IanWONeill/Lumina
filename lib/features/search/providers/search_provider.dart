import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:developer' as developer;
import '../../../features/sync/services/database_service.dart';

final databaseServiceProvider = Provider<DatabaseService>((ref) {
  return DatabaseService();
});

final searchQueryProvider = StateProvider<String>((ref) => '');

final isSearchLoadingProvider = StateProvider<bool>((ref) => false);

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
          ref.read(isSearchLoadingProvider.notifier).state = true;
          await notifier.search(next);
          ref.read(isSearchLoadingProvider.notifier).state = false;
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

  void clearResults() {
    state = [];
  }
} 