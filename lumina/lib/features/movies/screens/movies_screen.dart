import 'package:flutter/material.dart';
import '../widgets/movie_list_panel.dart';
import '../widgets/movie_metadata_panel.dart';
import '../widgets/movie_poster_panel.dart';

class MoviesScreen extends StatelessWidget {
  const MoviesScreen({super.key});

  @override
  Widget build(BuildContext context) => const Scaffold(
        body: Row(
          children: [
            Expanded(
              flex: 2,
              child: MoviePosterPanel(),
            ),
            Expanded(
              flex: 3,
              child: MovieListPanel(),
            ),
            Expanded(
              flex: 2,
              child: MovieMetadataPanel(),
            ),
          ],
        ),
      );
} 