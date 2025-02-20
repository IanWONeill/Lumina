import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import 'package:fluttertoast/fluttertoast.dart';
import '../../player/screens/media_details_screen.dart';
import '../../database/providers/database_provider.dart';
import '../models/movie.dart';

class CollectionDialog extends ConsumerWidget {
  final List<Map<String, dynamic>> collections;

  const CollectionDialog({
    super.key,
    required this.collections,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Collections',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ...collections.map((collection) {
              final collectionData = collection['collection'] as Map<String, dynamic>;
              final source = collectionData['source'] as String;
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: FocusableActionDetector(
                  actions: {
                    ActivateIntent: CallbackAction<ActivateIntent>(
                      onInvoke: (_) {
                        showDialog(
                          context: context,
                          builder: (context) => _CollectionMoviesDialog(
                            collection: collection,
                          ),
                        );
                        return null;
                      },
                    ),
                  },
                  child: Builder(
                    builder: (context) {
                      final focused = Focus.of(context).hasFocus;
                      return ElevatedButton.icon(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => _CollectionMoviesDialog(
                              collection: collection,
                            ),
                          );
                        },
                        icon: Icon(
                          source == 'tmdb' ? Icons.movie : Icons.public,
                          color: focused ? Colors.blue : Colors.white,
                        ),
                        label: Text(collectionData['name'] as String),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                          backgroundColor: focused 
                            ? Colors.blue.withOpacity(0.2) 
                            : Colors.white.withOpacity(0.1),
                          foregroundColor: focused ? Colors.blue : Colors.white,
                          side: focused 
                            ? const BorderSide(color: Colors.blue, width: 2)
                            : null,
                          minimumSize: const Size(300, 50),
                        ),
                      );
                    }
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}

class _CollectionMoviesDialog extends ConsumerWidget {
  final Map<String, dynamic> collection;

  const _CollectionMoviesDialog({
    required this.collection,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.read(databaseServiceProvider);
    final movies = collection['movies'] as List<Map<String, dynamic>>;
    final collectionData = collection['collection'] as Map<String, dynamic>;

    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  collectionData['name'] as String,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(width: 8),
                Icon(
                  collectionData['source'] == 'tmdb' ? Icons.movie : Icons.public,
                  size: 16,
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 400,
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  childAspectRatio: 0.6,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 16,
                ),
                itemCount: movies.length,
                itemBuilder: (context, index) {
                  final movie = movies[index];
                  final isPresent = movie['status'] == 'present';
                  
                  return FocusableActionDetector(
                    actions: {
                      ActivateIntent: CallbackAction<ActivateIntent>(
                        onInvoke: (_) async {
                          if (isPresent) {
                            final movieData = await db.getMovie(movie['tmdb_id'] as int);
                            if (movieData != null && context.mounted) {
                              Navigator.pop(context);
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => MediaDetailsScreen(
                                    media: Movie.fromMap(movieData),
                                    isMovie: true,
                                  ),
                                ),
                              );
                            }
                          } else {
                            Fluttertoast.showToast(
                              msg: "Movie not in library",
                              toastLength: Toast.LENGTH_SHORT,
                              gravity: ToastGravity.CENTER,
                            );
                          }
                          return null;
                        },
                      ),
                    },
                    child: Builder(
                      builder: (context) {
                        final focused = Focus.of(context).hasFocus;
                        return Container(
                          decoration: BoxDecoration(
                            border: focused
                                ? Border.all(color: Colors.blue, width: 2)
                                : null,
                          ),
                          child: Column(
                            children: [
                              Expanded(
                                child: isPresent
                                    ? Image.file(
                                        File('/storage/emulated/0/Debrid_Player/metadata/movies/posters/${movie['tmdb_id']}/poster.webp'),
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) =>
                                            Image.asset(
                                              'assets/images/missing_poster.webp',
                                              fit: BoxFit.cover,
                                            ),
                                      )
                                    : Image.asset(
                                        'assets/images/missing_poster.webp',
                                        fit: BoxFit.cover,
                                      ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                movie['original_title'] as String,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: isPresent ? null : Colors.red,
                                  fontSize: 12,
                                ),
                              ),
                              if (movie['release_date'] != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  movie['release_date'] as String,
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      }
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
} 