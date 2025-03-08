import 'dart:developer' as developer;
import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseService {
  static Database? _database;
  
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    final dbDir = Directory('/storage/emulated/0/Debrid_Player');
    await dbDir.create(recursive: true);
    final path = join(dbDir.path, 'debrid_player.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        
        await db.execute('''
          CREATE TABLE movies (
            tmdb_id INTEGER PRIMARY KEY,
            imdb_id TEXT,
            original_title TEXT,
            overview TEXT,
            release_date TEXT,
            revenue INTEGER,
            runtime INTEGER,
            vote_average REAL,
            is_watched INTEGER DEFAULT 0,
            watch_progress INTEGER DEFAULT 0,
            last_updated INTEGER,
            marked_for_deletion INTEGER,
            deletion_syncs INTEGER
          )
        ''');

        await db.execute('''
          CREATE TABLE tv_shows (
            tmdb_id INTEGER PRIMARY KEY,
            imdb_id TEXT,
            tvdb_id INTEGER,
            is_anime INTEGER,
            original_name TEXT,
            overview TEXT,
            first_air_date TEXT,
            number_of_episodes INTEGER,
            number_of_seasons INTEGER,
            total_episodes_count INTEGER,
            last_updated INTEGER,
            marked_for_deletion INTEGER,
            deletion_syncs INTEGER
          )
        ''');

        await db.execute('''
          CREATE TABLE actors (
            actor_id INTEGER PRIMARY KEY,  -- TMDB actor ID
            name TEXT NOT NULL,
            profile_path TEXT,
            last_updated INTEGER
          )
        ''');

        await db.execute('''
          CREATE TABLE media_cast (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            actor_id INTEGER,
            media_id INTEGER,
            media_type TEXT,  -- 'movie' or 'tv'
            FOREIGN KEY (actor_id) REFERENCES actors (actor_id),
            UNIQUE(actor_id, media_id, media_type)
          )
        ''');

        await db.execute('''
          CREATE TABLE seasons (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            tmdb_id INTEGER,
            show_id INTEGER,
            season_number INTEGER,
            name TEXT,
            overview TEXT,
            poster_path TEXT,
            FOREIGN KEY (show_id) REFERENCES tv_shows (tmdb_id),
            UNIQUE(show_id, season_number)
          )
        ''');

        await db.execute('''
          CREATE TABLE episodes (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            tmdb_id INTEGER,
            show_id INTEGER,
            season_id INTEGER,
            episode_number INTEGER,
            name TEXT,
            overview TEXT,
            still_path TEXT,
            air_date TEXT,
            is_watched INTEGER DEFAULT 0,
            watch_progress INTEGER DEFAULT 0,
            FOREIGN KEY (show_id) REFERENCES tv_shows (tmdb_id),
            FOREIGN KEY (season_id) REFERENCES seasons (id),
            UNIQUE(show_id, season_id, episode_number)
          )
        ''');

        await db.execute('''
          CREATE TABLE genres (
            genre_id INTEGER PRIMARY KEY,
            name TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE movie_genres (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            movie_id INTEGER,
            genre_id INTEGER,
            FOREIGN KEY (movie_id) REFERENCES movies (tmdb_id),
            FOREIGN KEY (genre_id) REFERENCES genres (genre_id),
            UNIQUE(movie_id, genre_id)
          )
        ''');

        await db.execute('''
          CREATE TABLE collections (
            collection_id INTEGER PRIMARY KEY,
            name TEXT NOT NULL,
            overview TEXT,
            poster_path TEXT,
            backdrop_path TEXT,
            source TEXT NOT NULL,
            wikidata_id TEXT,
            last_updated INTEGER
          )
        ''');

        await db.execute('''
          CREATE TABLE movie_collections (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            movie_tmdb_id INTEGER,
            movie_imdb_id TEXT,
            collection_id INTEGER,
            title TEXT NOT NULL,
            release_date TEXT,
            FOREIGN KEY (movie_tmdb_id) REFERENCES movies (tmdb_id),
            FOREIGN KEY (collection_id) REFERENCES collections (collection_id)
          )
        ''');

        developer.log(
          'Database created',
          name: 'DatabaseService',
          error: {'path': path},
        );
      },
    );
  }

  Future<void> insertActor(Map<String, dynamic> actor) async {
    final db = await database;
    
    await db.insert(
      'actors',
      {
        'actor_id': actor['id'],
        'name': actor['name'],
        'profile_path': actor['profile_path'],
        'last_updated': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> insertMediaCast(int actorId, int mediaId, String mediaType) async {
    final db = await database;
    
    await db.insert(
      'media_cast',
      {
        'actor_id': actorId,
        'media_id': mediaId,
        'media_type': mediaType,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<void> insertMovie(Map<String, dynamic> movie) async {
    final db = await database;
    
    await db.transaction((txn) async {
      try {
        final exists = await txn.query(
          'movies',
          where: 'tmdb_id = ?',
          whereArgs: [movie['tmdb_id']],
          limit: 1,
        );
        final isNewMovie = exists.isEmpty;

        developer.log(
          'Inserting movie with genres',
          name: 'DatabaseService',
          error: {
            'movieId': movie['tmdb_id'],
            'movieTitle': movie['original_title'],
            'genresCount': movie['genres']?.length ?? 0,
            'genres': movie['genres'],
          },
        );

        await txn.insert(
          'movies',
          {
            'tmdb_id': movie['tmdb_id'],
            'imdb_id': movie['imdb_id'],
            'original_title': movie['original_title'],
            'overview': movie['overview'],
            'release_date': movie['release_date'],
            'revenue': movie['revenue'],
            'runtime': movie['runtime'],
            'vote_average': movie['vote_average'],
            'last_updated': DateTime.now().millisecondsSinceEpoch,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );

        await txn.delete(
          'movie_genres',
          where: 'movie_id = ?',
          whereArgs: [movie['tmdb_id']],
        );

        if (movie['genres'] != null) {
          for (final genre in movie['genres']) {
            developer.log(
              'Inserting genre',
              name: 'DatabaseService',
              error: {
                'movieId': movie['tmdb_id'],
                'genreId': genre['id'],
                'genreName': genre['name'],
              },
            );

            await txn.insert(
              'genres',
              {
                'genre_id': genre['id'],
                'name': genre['name'],
              },
              conflictAlgorithm: ConflictAlgorithm.ignore,
            );
            
            await txn.insert(
              'movie_genres',
              {
                'movie_id': movie['tmdb_id'],
                'genre_id': genre['id'],
              },
              conflictAlgorithm: ConflictAlgorithm.ignore,
            );
          }
        }

        for (final actor in movie['cast']) {
          await txn.insert(
            'actors',
            {
              'actor_id': actor['id'],
              'name': actor['name'],
              'profile_path': actor['profile_path'],
              'last_updated': DateTime.now().millisecondsSinceEpoch,
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
          
          await txn.insert(
            'media_cast',
            {
              'actor_id': actor['id'],
              'media_id': movie['tmdb_id'],
              'media_type': 'movie',
            },
            conflictAlgorithm: ConflictAlgorithm.ignore,
          );
        }

        if (movie['collection'] != null) {
          await txn.insert(
            'collections',
            {
              'collection_id': movie['collection']['collection_id'],
              'name': movie['collection']['name'],
              'overview': movie['collection']['overview'],
              'poster_path': movie['collection']['poster_path'],
              'backdrop_path': movie['collection']['backdrop_path'],
              'source': movie['collection']['source'] ?? 'tmdb',
              'wikidata_id': movie['collection']['wikidata_id'],
              'last_updated': DateTime.now().millisecondsSinceEpoch,
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );

          for (final part in movie['collection']['parts']) {
            final existingEntry = await txn.query(
              'movie_collections',
              where: 'movie_tmdb_id = ? AND collection_id = ?',
              whereArgs: [part['tmdb_id'], movie['collection']['collection_id']],
            );

            if (existingEntry.isEmpty) {
              await txn.insert(
                'movie_collections',
                {
                  'movie_tmdb_id': part['tmdb_id'],
                  'movie_imdb_id': part['imdb_id'],
                  'collection_id': movie['collection']['collection_id'],
                  'title': part['title'],
                  'release_date': part['release_date'],
                },
                conflictAlgorithm: ConflictAlgorithm.ignore,
              );
            }
          }
        }

        if (isNewMovie) {
          _notifyMovieAdded();
        }
      } catch (e, st) {
        developer.log(
          'Error inserting movie',
          name: 'DatabaseService',
          error: {
            'movieId': movie['tmdb_id'],
            'error': e.toString(),
          },
          stackTrace: st,
          level: 1000,
        );
        rethrow;
      }
    });
  }

  Future<void> insertTVShow(Map<String, dynamic> show) async {
    final db = await database;
    
    await db.transaction((txn) async {
      try {
        final exists = await txn.query(
          'tv_shows',
          where: 'tmdb_id = ?',
          whereArgs: [show['tmdb_id']],
          limit: 1,
        );
        final isNewShow = exists.isEmpty;

        developer.log(
          'Starting TV show transaction',
          name: 'DatabaseService',
          error: {
            'showId': show['tmdb_id'],
            'title': show['original_name'],
          },
        );

        await txn.insert(
          'tv_shows',
          {
            'tmdb_id': show['tmdb_id'],
            'imdb_id': show['imdb_id'],
            'tvdb_id': show['tvdb_id'],
            'is_anime': show['is_anime'],
            'original_name': show['original_name'],
            'overview': show['overview'],
            'first_air_date': show['first_air_date'],
            'number_of_episodes': show['number_of_episodes'],
            'number_of_seasons': show['number_of_seasons'],
            'total_episodes_count': show['total_episodes_count'],
            'last_updated': DateTime.now().millisecondsSinceEpoch,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );

        developer.log(
          'Inserted show data',
          name: 'DatabaseService',
          error: {'showId': show['tmdb_id']},
        );

        for (final actor in show['cast']) {
          await txn.insert(
            'actors',
            {
              'actor_id': actor['id'],
              'name': actor['name'],
              'profile_path': actor['profile_path'],
              'last_updated': DateTime.now().millisecondsSinceEpoch,
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
          
          await txn.insert(
            'media_cast',
            {
              'actor_id': actor['id'],
              'media_id': show['tmdb_id'],
              'media_type': 'tv',
            },
            conflictAlgorithm: ConflictAlgorithm.ignore,
          );
        }

        developer.log(
          'Inserted cast data',
          name: 'DatabaseService',
          error: {'showId': show['tmdb_id']},
        );

        if (show['seasons'] != null) {
          developer.log(
            'Starting seasons insertion',
            name: 'DatabaseService',
            error: {
              'showId': show['tmdb_id'],
              'seasonCount': show['seasons'].length,
            },
          );

          for (final season in show['seasons']) {
            try {
              developer.log(
                'Inserting season',
                name: 'DatabaseService',
                error: {
                  'showId': show['tmdb_id'],
                  'seasonNumber': season['season_number'],
                  'episodeCount': season['episodes']?.length ?? 0,
                },
              );

              final seasonId = await txn.insert(
                'seasons',
                {
                  'tmdb_id': season['id'],
                  'show_id': show['tmdb_id'],
                  'season_number': season['season_number'],
                  'name': season['name'],
                  'overview': season['overview'],
                  'poster_path': season['poster_path'],
                },
                conflictAlgorithm: ConflictAlgorithm.replace,
              );

              developer.log(
                'Inserted season',
                name: 'DatabaseService',
                error: {
                  'showId': show['tmdb_id'],
                  'seasonNumber': season['season_number'],
                  'seasonId': seasonId,
                },
              );

              if (season['episodes'] != null) {
                developer.log(
                  'Starting episode insertion',
                  name: 'DatabaseService',
                  error: {
                    'showId': show['tmdb_id'],
                    'seasonNumber': season['season_number'],
                    'episodeCount': season['episodes'].length,
                  },
                );

                for (final episode in season['episodes']) {
                  try {
                    await txn.insert(
                      'episodes',
                      {
                        'tmdb_id': episode['id'],
                        'show_id': show['tmdb_id'],
                        'season_id': seasonId,
                        'episode_number': episode['episode_number'],
                        'name': episode['name'],
                        'overview': episode['overview'],
                        'still_path': episode['still_path'],
                        'air_date': episode['air_date'],
                      },
                      conflictAlgorithm: ConflictAlgorithm.replace,
                    );
                  } catch (e, st) {
                    developer.log(
                      'Failed to insert episode',
                      name: 'DatabaseService',
                      error: {
                        'showId': show['tmdb_id'],
                        'seasonNumber': season['season_number'],
                        'episodeNumber': episode['episode_number'],
                        'error': e.toString(),
                      },
                      stackTrace: st,
                      level: 1000,
                    );
                    rethrow;
                  }
                }

                developer.log(
                  'Completed episode insertion',
                  name: 'DatabaseService',
                  error: {
                    'showId': show['tmdb_id'],
                    'seasonNumber': season['season_number'],
                  },
                );
              }
            } catch (e, st) {
              developer.log(
                'Failed to insert season',
                name: 'DatabaseService',
                error: {
                  'showId': show['tmdb_id'],
                  'seasonNumber': season['season_number'],
                  'error': e.toString(),
                },
                stackTrace: st,
                level: 1000,
              );
              rethrow;
            }
          }

          developer.log(
            'Completed seasons insertion',
            name: 'DatabaseService',
            error: {'showId': show['tmdb_id']},
          );
        }

        developer.log(
          'Completed TV show transaction',
          name: 'DatabaseService',
          error: {'showId': show['tmdb_id']},
        );

        if (isNewShow) {
          _notifyTVShowAdded();
        }
      } catch (e, st) {
        developer.log(
          'Error in TV show transaction',
          name: 'DatabaseService',
          error: {
            'showId': show['tmdb_id'],
            'error': e.toString(),
          },
          stackTrace: st,
          level: 1000,
        );
        rethrow;
      }
    });
  }

  Future<int> insertSeason(Map<String, dynamic> season, int showId) async {
    final db = await database;
    
    final seasonId = await db.insert(
      'seasons',
      {
        'tmdb_id': season['id'],
        'show_id': showId,
        'season_number': season['season_number'],
        'name': season['name'],
        'overview': season['overview'],
        'poster_path': season['poster_path'],
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return seasonId;
  }

  Future<void> insertEpisode(Map<String, dynamic> episode, int showId, int seasonId) async {
    final db = await database;
    
    await db.insert(
      'episodes',
      {
        'tmdb_id': episode['id'],
        'show_id': showId,
        'season_id': seasonId,
        'episode_number': episode['episode_number'],
        'name': episode['name'],
        'overview': episode['overview'],
        'still_path': episode['still_path'],
        'air_date': episode['air_date'],
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> insertSeasonWithEpisodes(
    Map<String, dynamic> seasonData,
    List<Map<String, dynamic>> episodes,
    int showId,
  ) async {
    final db = await database;
    
    final seasonId = await db.insert('seasons', {
      'show_id': showId,
      'season_number': seasonData['season_number'],
      'name': seasonData['name'],
      'overview': seasonData['overview'],
      'air_date': seasonData['air_date'],
      'poster_path': seasonData['poster_path'],
    });

    for (final episode in episodes) {
      await db.insert('episodes', {
        'show_id': showId,
        'season_id': seasonId,
        'episode_number': episode['episode_number'],
        'name': episode['name'],
        'overview': episode['overview'],
        'air_date': episode['air_date'],
        'still_path': episode['still_path'],
      });
    }

    return seasonId;
  }

  Future<List<Map<String, dynamic>>> getSeasons(int showId) async {
    final db = await database;
    
    return await db.query(
      'seasons',
      where: 'show_id = ?',
      whereArgs: [showId],
      orderBy: 'season_number ASC',
    );
  }

  Future<List<Map<String, dynamic>>> getEpisodes(int seasonId) async {
    final db = await database;
    
    return await db.query(
      'episodes',
      where: 'season_id = ?',
      whereArgs: [seasonId],
      orderBy: 'episode_number ASC',
    );
  }

  Future<void> deleteShowData(int showId) async {
    final db = await database;
    
    await db.transaction((txn) async {
      await txn.delete(
        'episodes',
        where: 'show_id = ?',
        whereArgs: [showId],
      );

      await txn.delete(
        'seasons',
        where: 'show_id = ?',
        whereArgs: [showId],
      );

      await txn.delete(
        'tv_shows',
        where: 'tmdb_id = ?',
        whereArgs: [showId],
      );

      await txn.delete(
        'cast',
        where: 'media_id = ? AND media_type = ?',
        whereArgs: [showId, 'tv'],
      );
    });
  }

  Future<bool> movieExists(int tmdbId) async {
    final db = await database;
    final result = await db.query(
      'movies',
      where: 'tmdb_id = ?',
      whereArgs: [tmdbId],
      limit: 1,
    );
    return result.isNotEmpty;
  }

  Future<Map<String, dynamic>?> getTVShowDetails(int tmdbId) async {
    final db = await database;
    final result = await db.query(
      'tv_shows',
      where: 'tmdb_id = ?',
      whereArgs: [tmdbId],
      limit: 1,
    );
    return result.isNotEmpty ? result.first : null;
  }

  Future<List<Map<String, dynamic>>> getExistingSeasons(int showId) async {
    final db = await database;
    return await db.query(
      'seasons',
      where: 'show_id = ?',
      whereArgs: [showId],
      columns: ['season_number', 'id'],
    );
  }

  Future<List<Map<String, dynamic>>> getExistingEpisodes(int seasonId) async {
    final db = await database;
    return await db.query(
      'episodes',
      where: 'season_id = ?',
      whereArgs: [seasonId],
      columns: ['episode_number', 'id'],
    );
  }

  Future<void> updateTVShowDetails(Map<String, dynamic> show) async {
    final db = await database;
    await db.update(
      'tv_shows',
      {
        'number_of_episodes': show['number_of_episodes'],
        'number_of_seasons': show['number_of_seasons'],
        'total_episodes_count': show['total_episodes_count'],
        'last_updated': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'tmdb_id = ?',
      whereArgs: [show['tmdb_id']],
    );
  }

  Future<Map<int, int>> getSeasonIdMap(int showId) async {
    final db = await database;
    final seasons = await db.query(
      'seasons',
      where: 'show_id = ?',
      whereArgs: [showId],
      columns: ['id', 'season_number'],
    );
    
    return Map.fromEntries(
      seasons.map((s) => MapEntry(s['season_number'] as int, s['id'] as int)),
    );
  }

  Future<Set<int>> getExistingEpisodeNumbers(int seasonId) async {
    final db = await database;
    final episodes = await db.query(
      'episodes',
      where: 'season_id = ?',
      whereArgs: [seasonId],
      columns: ['episode_number'],
    );
    
    return episodes.map((e) => e['episode_number'] as int).toSet();
  }

  Future<List<Map<String, dynamic>>> getAllMovies() async {
    final db = await database;
    return await db.query(
      'movies',
      orderBy: 'original_title ASC',
    );
  }

  Future<void> updateMovieProgress(int tmdbId, int progress, int percentage) async {
    final db = await database;
    await db.update(
      'movies',
      {
        'watch_progress': progress,
        'is_watched': percentage >= 75 ? 1 : 0,
      },
      where: 'tmdb_id = ?',
      whereArgs: [tmdbId],
    );
  }

  Future<void> updateEpisodeWatchProgress(int episodeId, int progress, int percentage) async {
    final db = await database;
    await db.update(
      'episodes',
      {
        'watch_progress': progress,
        'is_watched': percentage >= 75 ? 1 : 0,
      },
      where: 'id = ?',
      whereArgs: [episodeId],
    );

    developer.log(
      'Episode progress updated',
      name: 'DatabaseService',
      error: {
        'episodeId': episodeId,
        'progress': progress,
        'percentage': percentage,
        'isWatched': percentage >= 75,
      },
    );
  }

  Future<List<Map<String, dynamic>>> getAllTVShows() async {
    final db = await database;
    return await db.query(
      'tv_shows',
      orderBy: 'original_name ASC',
    );
  }

  Future<List<Map<String, dynamic>>> getEpisodesForSeason(int seasonId) async {
    final db = await database;
    return await db.query(
      'episodes',
      where: 'season_id = ?',
      whereArgs: [seasonId],
      orderBy: 'episode_number ASC',
    );
  }

  Future<List<Map<String, dynamic>>> getSeasonsForShow(int showId) async {
    final db = await database;
    return await db.query(
      'seasons',
      where: 'show_id = ?',
      whereArgs: [showId],
      orderBy: 'season_number ASC',
    );
  }

  Future<List<Map<String, dynamic>>> getMovieCast(int movieId) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT a.* FROM actors a
      INNER JOIN media_cast mc ON mc.actor_id = a.actor_id
      WHERE mc.media_id = ? AND mc.media_type = 'movie'
      LIMIT 3
    ''', [movieId]);
    return result;
  }

  Future<List<Map<String, dynamic>>> getTVShowCast(int showId) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT a.* FROM actors a
      INNER JOIN media_cast mc ON mc.actor_id = a.actor_id
      WHERE mc.media_id = ? AND mc.media_type = 'tv'
      LIMIT 3
    ''', [showId]);
    return result;
  }

  Future<List<Map<String, dynamic>>> getMovieCastDetails(int movieId) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT a.* FROM actors a
      INNER JOIN media_cast mc ON mc.actor_id = a.actor_id
      WHERE mc.media_id = ? AND mc.media_type = 'movie'
      LIMIT 7
    ''', [movieId]); 
    return result;
  }

  Future<List<Map<String, dynamic>>> getTVShowCastDetails(int showId) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT a.* FROM actors a
      INNER JOIN media_cast mc ON mc.actor_id = a.actor_id
      WHERE mc.media_id = ? AND mc.media_type = 'tv'
      LIMIT 7
    ''', [showId]);
    return result;
  }

  Future<Map<String, dynamic>?> getMovie(int tmdbId) async {
    final db = await database;
    final result = await db.query(
      'movies',
      where: 'tmdb_id = ?',
      whereArgs: [tmdbId],
      limit: 1,
    );
    return result.isNotEmpty ? result.first : null;
  }

  Future<Map<String, dynamic>?> getEpisode(int episodeId) async {
    final db = await database;
    final result = await db.query(
      'episodes',
      where: 'id = ?',
      whereArgs: [episodeId],
      limit: 1,
    );
    return result.isNotEmpty ? result.first : null;
  }

  Future<void> updateMovieWatchedStatus(int tmdbId, bool isWatched) async {
    final db = await database;
    await db.update(
      'movies',
      {
        'is_watched': isWatched ? 1 : 0,
      },
      where: 'tmdb_id = ?',
      whereArgs: [tmdbId],
    );
  }

  Future<void> updateEpisodeWatchedStatus(int episodeId, bool isWatched) async {
    final db = await database;
    await db.update(
      'episodes',
      {
        'is_watched': isWatched ? 1 : 0,
      },
      where: 'id = ?',
      whereArgs: [episodeId],
    );
  }

  Future<List<Map<String, dynamic>>> searchMovies(String query) async {
    final db = await database;
    final searchTerm = '%$query%';
    
    return await db.query(
      'movies',
      where: 'original_title LIKE ?',
      whereArgs: [searchTerm],
      orderBy: 'original_title ASC',
    );
  }

  Future<List<Map<String, dynamic>>> searchTVShows(String query) async {
    final db = await database;
    final searchTerm = '%$query%';
    
    return await db.query(
      'tv_shows',
      where: 'original_name LIKE ?',
      whereArgs: [searchTerm],
      orderBy: 'original_name ASC',
    );
  }

  Future<List<Map<String, dynamic>>> searchAll(String query) async {
    final db = await database;
    final searchTerm = '%$query%';
    
    try {
      final movies = await db.rawQuery('''
        SELECT 
          m.tmdb_id,
          m.original_title,
          'movie' as media_type
        FROM movies m 
        WHERE m.original_title LIKE ?
      ''', [searchTerm]);

      final tvShows = await db.rawQuery('''
        SELECT 
          t.tmdb_id,
          t.original_name,
          'tv' as media_type
        FROM tv_shows t 
        WHERE t.original_name LIKE ?
      ''', [searchTerm]);

      final actorResults = await db.rawQuery('''
        SELECT 
          CASE 
            WHEN mc.media_type = 'movie' THEN m.original_title
            WHEN mc.media_type = 'tv' THEN t.original_name
          END as title,
          CASE 
            WHEN mc.media_type = 'movie' THEN m.tmdb_id
            WHEN mc.media_type = 'tv' THEN t.tmdb_id
          END as tmdb_id,
          mc.media_type,
          a.name as actor_name
        FROM actors a
        JOIN media_cast mc ON a.actor_id = mc.actor_id
        LEFT JOIN movies m ON mc.media_id = m.tmdb_id AND mc.media_type = 'movie'
        LEFT JOIN tv_shows t ON mc.media_id = t.tmdb_id AND mc.media_type = 'tv'
        WHERE a.name LIKE ?
      ''', [searchTerm]);

      final actorMediaResults = actorResults.map((result) {
        return {
          'tmdb_id': result['tmdb_id'],
          result['media_type'] == 'movie' ? 'original_title' : 'original_name': result['title'],
          'media_type': result['media_type'],
          'actor_name': result['actor_name'],
        };
      }).toList();

      final allResults = [...movies, ...tvShows, ...actorMediaResults];
      
      final seen = <String>{};
      final uniqueResults = allResults.where((result) {
        final key = '${result['tmdb_id']}_${result['media_type']}';
        return seen.add(key);
      }).toList();

      uniqueResults.sort((a, b) {
        final aTitle = a['media_type'] == 'movie' 
            ? a['original_title'] as String 
            : a['original_name'] as String;
        final bTitle = b['media_type'] == 'movie' 
            ? b['original_title'] as String 
            : b['original_name'] as String;
        return aTitle.compareTo(bTitle);
      });

      return uniqueResults;
    } catch (e, stackTrace) {
      developer.log(
        'Error during search',
        name: 'DatabaseService',
        error: {
          'query': query,
          'error': e.toString(),
        },
        stackTrace: stackTrace,
        level: 1000,
      );
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getTVShow(int tmdbId) async {
    final db = await database;
    final result = await db.query(
      'tv_shows',
      where: 'tmdb_id = ?',
      whereArgs: [tmdbId],
      limit: 1,
    );
    return result.isNotEmpty ? result.first : null;
  }

  Future<Map<String, dynamic>?> getSeasonDetails(int seasonId) async {
    final db = await database;
    final result = await db.query(
      'seasons',
      where: 'id = ?',
      whereArgs: [seasonId],
      limit: 1,
    );
    return result.isNotEmpty ? result.first : null;
  }

  Future<List<int>> getAllMovieIds() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'movies',
      columns: ['tmdb_id'],
    );
    return List<int>.from(maps.map((map) => map['tmdb_id']));
  }

  Future<Map<int, Map<String, dynamic>>> getAllTVShowDetails() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('tv_shows');
    return Map.fromEntries(
      maps.map((show) => MapEntry(show['tmdb_id'] as int, show)),
    );
  }

  Future<Map<int, Map<int, int>>> getAllSeasonIds() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('seasons');
    
    final seasonMap = <int, Map<int, int>>{};
    for (final map in maps) {
      final showId = map['show_id'] as int;
      final seasonNumber = map['season_number'] as int;
      final seasonId = map['id'] as int;
      
      seasonMap.putIfAbsent(showId, () => {});
      seasonMap[showId]![seasonNumber] = seasonId;
    }
    return seasonMap;
  }

  Future<Map<int, Set<int>>> getAllEpisodeNumbers() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('episodes');
    
    final episodeMap = <int, Set<int>>{};
    for (final map in maps) {
      final seasonId = map['season_id'] as int;
      final episodeNumber = map['episode_number'] as int;
      
      episodeMap.putIfAbsent(seasonId, () => {});
      episodeMap[seasonId]!.add(episodeNumber);
    }
    return episodeMap;
  }

  Future<List<Map<String, dynamic>>> getMovieGenres(int movieId) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT g.* FROM genres g
      INNER JOIN movie_genres mg ON mg.genre_id = g.genre_id
      WHERE mg.movie_id = ?
    ''', [movieId]);
    return result;
  }

  Future<List<Map<String, dynamic>>> getAllGenres() async {
    final db = await database;
    return await db.query('genres', orderBy: 'name ASC');
  }

  Future<List<Map<String, dynamic>>> getMoviesByGenre(int genreId) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT m.* FROM movies m
      INNER JOIN movie_genres mg ON mg.movie_id = m.tmdb_id
      WHERE mg.genre_id = ?
      ORDER BY m.original_title ASC
    ''', [genreId]);
    return result;
  }

  Future<void> insertCollection(Map<String, dynamic> collection) async {
    final db = await database;
    
    await db.transaction((txn) async {
      await txn.insert(
        'collections',
        {
          'collection_id': collection['collection_id'],
          'name': collection['name'],
          'overview': collection['overview'],
          'poster_path': collection['poster_path'],
          'backdrop_path': collection['backdrop_path'],
          'source': collection['source'] ?? 'tmdb',
          'wikidata_id': collection['wikidata_id'],
          'last_updated': DateTime.now().millisecondsSinceEpoch,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      await txn.delete(
        'movie_collections',
        where: 'collection_id = ?',
        whereArgs: [collection['collection_id']],
      );

      if (collection['parts'] != null) {
        for (final movie in collection['parts']) {
          await txn.insert(
            'movie_collections',
            {
              'movie_tmdb_id': movie['tmdb_id'],
              'movie_imdb_id': movie['imdb_id'],
              'collection_id': collection['collection_id'],
              'title': movie['title'],
              'release_date': movie['release_date'],
            },
            conflictAlgorithm: ConflictAlgorithm.ignore,
          );
        }
      }
    });
  }

  Future<void> linkMovieToCollection(int movieId, int collectionId) async {
    final db = await database;
    
    await db.insert(
      'movie_collections',
      {
        'movie_tmdb_id': movieId,
        'collection_id': collectionId,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<Map<String, dynamic>?> getCollection(int collectionId) async {
    final db = await database;
    final result = await db.query(
      'collections',
      where: 'collection_id = ?',
      whereArgs: [collectionId],
      limit: 1,
    );
    return result.isNotEmpty ? result.first : null;
  }

  Future<List<Map<String, dynamic>>> getMoviesInCollection(int collectionId) async {
    final db = await database;
    
    final result = await db.rawQuery('''
      SELECT 
        mc.movie_tmdb_id as tmdb_id,
        mc.movie_imdb_id as imdb_id,
        COALESCE(m.original_title, mc.title) as original_title,
        mc.release_date,
        CASE 
          WHEN m.tmdb_id IS NOT NULL OR m2.imdb_id IS NOT NULL THEN 'present'
          ELSE 'missing'
        END as status,
        COALESCE(m.tmdb_id, m2.tmdb_id) as linked_tmdb_id
      FROM movie_collections mc
      LEFT JOIN movies m ON mc.movie_tmdb_id = m.tmdb_id
      LEFT JOIN movies m2 ON mc.movie_imdb_id = m2.imdb_id
      WHERE mc.collection_id = ?
      ORDER BY 
        CASE WHEN mc.release_date IS NULL THEN 1 ELSE 0 END,
        mc.release_date ASC
    ''', [collectionId]);

    developer.log(
      'Found movies in collection',
      name: 'DatabaseService',
      error: {
        'collectionId': collectionId,
        'movieCount': result.length,
        'movies': result.map((m) => {
          'title': m['original_title'],
          'tmdbId': m['tmdb_id'],
          'imdbId': m['imdb_id'],
          'status': m['status'],
          'linkedTmdbId': m['linked_tmdb_id'],
        }).toList(),
      },
    );

    return result.map((movie) => {
      'tmdb_id': movie['linked_tmdb_id'] ?? movie['tmdb_id'],
      'imdb_id': movie['imdb_id'],
      'original_title': movie['original_title'],
      'status': movie['status'],
      'release_date': movie['release_date'],
    }).toList();
  }

  Future<List<Map<String, dynamic>>> getCollectionsForMovie(int movieId) async {
    final db = await database;
    
    final movieResult = await db.query(
      'movies',
      columns: ['imdb_id'],
      where: 'tmdb_id = ?',
      whereArgs: [movieId],
      limit: 1,
    );

    if (movieResult.isEmpty) {
      developer.log(
        'Movie not found',
        name: 'DatabaseService',
        error: {'movieId': movieId},
      );
      return [];
    }

    final imdbId = movieResult.first['imdb_id'] as String?;
    
    final result = await db.rawQuery('''
      SELECT DISTINCT
        c.*,
        CASE 
          WHEN c.source = 'wikidata' THEN c.wikidata_id
          ELSE NULL
        END as collection_source_id
      FROM collections c
      INNER JOIN movie_collections mc ON mc.collection_id = c.collection_id
      WHERE mc.movie_tmdb_id = ? OR mc.movie_imdb_id = ?
      GROUP BY c.collection_id
      ORDER BY c.source, c.name
    ''', [movieId, imdbId]);

    developer.log(
      'Found collections for movie',
      name: 'DatabaseService',
      error: {
        'movieId': movieId,
        'imdbId': imdbId,
        'collectionsCount': result.length,
        'collections': result.map((c) => {
          'name': c['name'],
          'source': c['source'],
          'collection_id': c['collection_id'],
        }).toList(),
      },
    );

    return result;
  }

  Future<void> insertWikidataCollections(List<Map<String, dynamic>> collections) async {
    final db = await database;
    
    await db.transaction((txn) async {
      try {
        for (final collection in collections) {
          developer.log(
            'Processing Wikidata collection',
            name: 'DatabaseService',
            error: {
              'collectionName': collection['name'],
              'wikidataId': collection['wikidata_id'],
              'movieCount': collection['parts']?.length ?? 0,
            },
          );

          await txn.insert(
            'collections',
            {
              'collection_id': collection['name'].hashCode.abs(),
              'name': collection['name'],
              'overview': null,
              'poster_path': null,
              'backdrop_path': null,
              'source': 'wikidata',
              'wikidata_id': collection['wikidata_id'],
              'last_updated': DateTime.now().millisecondsSinceEpoch,
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );

          if (collection['parts'] != null) {
            for (final part in collection['parts']) {
              final existingEntry = await txn.query(
                'movie_collections',
                where: 'movie_imdb_id = ? AND collection_id = ?',
                whereArgs: [part['imdb_id'], collection['name'].hashCode.abs()],
              );

              if (existingEntry.isEmpty) {
                developer.log(
                  'Inserting new movie into collection',
                  name: 'DatabaseService',
                  error: {
                    'title': part['title'],
                    'imdbId': part['imdb_id'],
                    'releaseDate': part['release_date'],
                    'collectionName': collection['name'],
                  },
                );

                await txn.insert(
                  'movie_collections',
                  {
                    'movie_imdb_id': part['imdb_id'],
                    'collection_id': collection['name'].hashCode.abs(),
                    'title': part['title'],
                    'release_date': part['release_date'],
                  },
                  conflictAlgorithm: ConflictAlgorithm.ignore,
                );
              } else {
                developer.log(
                  'Movie already exists in collection',
                  name: 'DatabaseService',
                  error: {
                    'title': part['title'],
                    'imdbId': part['imdb_id'],
                    'collectionName': collection['name'],
                  },
                );
              }
            }
          }
        }
      } catch (e, st) {
        developer.log(
          'Error inserting Wikidata collections',
          name: 'DatabaseService',
          error: {'error': e.toString()},
          stackTrace: st,
          level: 1000,
        );
        rethrow;
      }
    });
  }

  Future<void> deleteMovie(int tmdbId) async {
    final db = await database;
    
    await db.transaction((txn) async {
      await txn.delete(
        'media_cast',
        where: 'media_id = ? AND media_type = ?',
        whereArgs: [tmdbId, 'movie'],
      );

      await txn.delete(
        'movie_genres',
        where: 'movie_id = ?',
        whereArgs: [tmdbId],
      );

      await txn.delete(
        'movies',
        where: 'tmdb_id = ?',
        whereArgs: [tmdbId],
      );
    });
  }

  Future<List<int>> getMovieTmdbIds() async {
    final db = await database;
    final result = await db.query(
      'movies',
      columns: ['tmdb_id'],
    );
    return result.map((row) => row['tmdb_id'] as int).toList();
  }

  Future<List<int>> getTVShowTmdbIds() async {
    final db = await database;
    final result = await db.query(
      'tv_shows',
      columns: ['tmdb_id'],
    );
    return result.map((row) => row['tmdb_id'] as int).toList();
  }

  Future<void> markForDeletion(String mediaType, int tmdbId) async {
    final db = await database;
    final table = mediaType == 'movie' ? 'movies' : 'tv_shows';
    
    await db.update(
      table,
      {
        'marked_for_deletion': DateTime.now().millisecondsSinceEpoch,
        'deletion_syncs': 1,
      },
      where: 'tmdb_id = ?',
      whereArgs: [tmdbId],
    );
    
    developer.log(
      'Marked for deletion',
      name: 'DatabaseService',
      error: {
        'mediaType': mediaType,
        'tmdbId': tmdbId,
      },
    );
  }

  Future<void> incrementDeletionSync(String mediaType, int tmdbId) async {
    final db = await database;
    final table = mediaType == 'movie' ? 'movies' : 'tv_shows';
    
    await db.rawUpdate('''
      UPDATE $table 
      SET deletion_syncs = deletion_syncs + 1
      WHERE tmdb_id = ?
    ''', [tmdbId]);
  }

  Future<void> clearDeletionMark(String mediaType, int tmdbId) async {
    final db = await database;
    final table = mediaType == 'movie' ? 'movies' : 'tv_shows';
    
    await db.update(
      table,
      {
        'marked_for_deletion': null,
        'deletion_syncs': null,
      },
      where: 'tmdb_id = ?',
      whereArgs: [tmdbId],
    );
  }

  Future<int> getMovieCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM movies');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> getTVShowCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM tv_shows');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<List<Map<String, dynamic>>> getItemsMarkedForDeletion(
    String mediaType,
    int minSyncs,
  ) async {
    final db = await database;
    final table = mediaType == 'movie' ? 'movies' : 'tv_shows';
    
    return await db.query(
      table,
      where: 'marked_for_deletion IS NOT NULL AND deletion_syncs >= ?',
      whereArgs: [minSyncs],
    );
  }

  Function? _onMovieAdded;
  Function? _onTVShowAdded;

  void setOnMovieAdded(Function callback) {
    _onMovieAdded = callback;
  }

  void setOnTVShowAdded(Function callback) {
    _onTVShowAdded = callback;
  }

  void _notifyMovieAdded() {
    if (_onMovieAdded != null) {
      _onMovieAdded!();
    }
  }

  void _notifyTVShowAdded() {
    if (_onTVShowAdded != null) {
      _onTVShowAdded!();
    }
  }

  Future<Map<String, dynamic>?> getMovieByTmdbId(int tmdbId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'movies',
      where: 'tmdb_id = ?',
      whereArgs: [tmdbId],
    );
    
    if (maps.isEmpty) {
      return null;
    }
    
    return maps.first;
  }

  Future<Map<String, dynamic>?> getTVShowByTmdbId(int tmdbId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'tv_shows',
      where: 'tmdb_id = ?',
      whereArgs: [tmdbId],
    );
    
    if (maps.isEmpty) {
      return null;
    }
    
    return maps.first;
  }

  Future<void> updateMovie(int id, Map<String, dynamic> data) async {
    final db = await database;
    await db.update(
      'movies',
      data,
      where: 'tmdb_id = ?',
      whereArgs: [id],
    );
  }
}