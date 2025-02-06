import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../models/season.dart';
import '../widgets/episode_list_panel.dart';
import '../widgets/episode_details_panel.dart';
import '../widgets/episode_still_panel.dart';

class EpisodesScreen extends HookConsumerWidget {
  final Season season;

  const EpisodesScreen({
    super.key,
    required this.season,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Season ${season.seasonNumber}'),
      ),
      body: Row(
        children: [
          Expanded(
            flex: 2,
            child: EpisodeStillPanel(),
          ),
          Expanded(
            flex: 3,
            child: EpisodeListPanel(season: season),
          ),
          Expanded(
            flex: 2,
            child: EpisodeDetailsPanel(),
          ),
        ],
      ),
    );
  }
} 