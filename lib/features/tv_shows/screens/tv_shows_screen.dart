import 'package:flutter/material.dart';
import '../widgets/show_list_panel.dart';
import '../widgets/show_metadata_panel.dart';
import '../widgets/show_poster_panel.dart';

class TVShowsScreen extends StatelessWidget {
  const TVShowsScreen({super.key});

  @override
  Widget build(BuildContext context) => const Scaffold(
        body: Row(
          children: [
            Expanded(
              flex: 2,
              child: ShowPosterPanel(),
            ),
            Expanded(
              flex: 3,
              child: ShowListPanel(),
            ),
            Expanded(
              flex: 2,
              child: ShowMetadataPanel(),
            ),
          ],
        ),
      );
} 