import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../widgets/genre_list_panel.dart';
import '../widgets/genre_metadata_panel.dart';
import '../widgets/genre_poster_panel.dart';
import '../providers/search_provider.dart';

class GenreResultsScreen extends ConsumerWidget {
  final String genreName;
  
  const GenreResultsScreen({
    super.key,
    required this.genreName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) => WillPopScope(
        onWillPop: () async {
          ref.read(searchResultsProvider.notifier).clearResults();
          ref.read(searchQueryProvider.notifier).state = '';
          return true;
        },
        child: Scaffold(
          appBar: AppBar(
            title: Text('$genreName Movies'),
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
          body: Row(
            children: [
              Expanded(
                flex: 2,
                child: GenrePosterPanel(),
              ),
              const Expanded(
                flex: 3,
                child: GenreListPanel(),
              ),
              const Expanded(
                flex: 2,
                child: GenreMetadataPanel(),
              ),
            ],
          ),
        ),
      );
} 