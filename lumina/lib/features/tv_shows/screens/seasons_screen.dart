import 'package:flutter/material.dart';
import '../models/tv_show.dart';
import '../widgets/season_list_panel.dart';
import '../widgets/season_metadata_panel.dart';
import '../widgets/season_poster_panel.dart';

class SeasonsScreen extends StatelessWidget {
  final TVShow show;

  const SeasonsScreen({
    super.key,
    required this.show,
  });

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text(show.originalName),
        ),
        body: Row(
          children: [
            Expanded(
              flex: 2,
              child: SeasonPosterPanel(show: show),
            ),
            Expanded(
              flex: 3,
              child: SeasonListPanel(show: show),
            ),
            Expanded(
              flex: 2,
              child: SeasonMetadataPanel(),
            ),
          ],
        ),
      );
} 