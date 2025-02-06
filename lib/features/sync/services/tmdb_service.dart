import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class TMDBService {
  final String _apiKey;
  static const String _baseUrl = 'https://api.themoviedb.org/3';
  static const String _imageBaseUrl = 'https://image.tmdb.org/t/p/original';

  TMDBService(this._apiKey);

  Map<String, String> get _headers => {
    'Authorization': 'Bearer $_apiKey',
    'Accept': 'application/json',
  };

  Future<Map<String, dynamic>> getMovieDetails(int tmdbId) async {
    developer.log(
      'Fetching movie details',
      name: 'TMDBService',
      error: {'tmdbId': tmdbId},
    );
    
    final response = await http.get(
      Uri.parse('$_baseUrl/movie/$tmdbId?append_to_response=credits,images'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      
      String title = data['title'] ?? '';
      String originalTitle = data['original_title'] ?? '';
      
      if (originalTitle.isEmpty) {
        developer.log(
          'Empty original title',
          name: 'TMDBService',
          error: {'tmdbId': tmdbId, 'title': title},
          level: 900,
        );
        originalTitle = title;
      }
      if (title.isEmpty) {
        developer.log(
          'Empty title',
          name: 'TMDBService',
          error: {'tmdbId': tmdbId, 'originalTitle': originalTitle},
          level: 900,
        );
        title = originalTitle;
      }
      
      if (title.isEmpty) {
        throw Exception('No valid title found for movie $tmdbId');
      }

      final movieData = {
        'tmdb_id': tmdbId,
        'imdb_id': data['imdb_id'],
        'original_title': title,
        'title': title,
        'overview': data['overview'],
        'release_date': data['release_date'],
        'revenue': data['revenue'],
        'runtime': data['runtime'],
        'vote_average': data['vote_average'],
        'cast': (data['credits']['cast'] as List?)
            ?.take(7)
            .map((actor) => {
                  'id': actor['id'],
                  'name': actor['name'],
                })
            .toList() ?? [],
      };

      developer.log(
        'Processed movie data',
        name: 'TMDBService',
        error: {'tmdbId': tmdbId, 'title': title},
      );

      if (data['poster_path'] != null) {
        await downloadImage(
          data['poster_path'],
          'movies/posters',
          tmdbId.toString(),
        );
      }

      if (data['backdrop_path'] != null) {
        await downloadImage(
          data['backdrop_path'],
          'movies/backdrops',
          tmdbId.toString(),
        );
      }

      developer.log('Processing actor images');
      for (final actor in data['credits']['cast'].take(10)) {
        if (actor['profile_path'] != null) {
          await downloadActorImage(actor);
        }
      }

      return movieData;
    } else {
      developer.log(
        'Failed to fetch movie details',
        name: 'TMDBService',
        error: {
          'tmdbId': tmdbId,
          'statusCode': response.statusCode,
          'response': response.body,
        },
        level: 1000,
      );
      throw Exception('Failed to fetch movie details');
    }
  }

  Future<Map<String, dynamic>> getTVShowDetails(int tmdbId) async {
    developer.log(
      'Fetching TV show details',
      name: 'TMDBService',
      error: {'tmdbId': tmdbId},
    );
    
    final response = await http.get(
      Uri.parse('$_baseUrl/tv/$tmdbId?append_to_response=credits,images'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      
      String name = data['name'] ?? '';
      String originalName = data['original_name'] ?? '';
      
      if (originalName.isEmpty) {
        developer.log(
          'Empty original name',
          name: 'TMDBService',
          error: {'tmdbId': tmdbId, 'name': name},
          level: 900,
        );
        originalName = name;
      }
      if (name.isEmpty) {
        developer.log(
          'Empty name',
          name: 'TMDBService',
          error: {'tmdbId': tmdbId, 'originalName': originalName},
          level: 900,
        );
        name = originalName;
      }
      
      if (name.isEmpty) {
        throw Exception('No valid name found for TV show $tmdbId');
      }

      final showData = {
        'tmdb_id': tmdbId,
        'original_name': name,
        'name': name,
        'overview': data['overview'],
        'first_air_date': data['first_air_date'],
        'number_of_episodes': data['number_of_episodes'],
        'number_of_seasons': data['number_of_seasons'],
        'overview': data['overview'],
        'cast': (data['credits']['cast'] as List?)
            ?.take(7)
            .map((actor) => {
                  'id': actor['id'],
                  'name': actor['name'],
                })
            .toList() ?? [],
      };

      if (data['poster_path'] != null) {
        await downloadImage(
          data['poster_path'],
          'tv/posters',
          tmdbId.toString(),
        );
      }

      if (data['backdrop_path'] != null) {
        await downloadImage(
          data['backdrop_path'],
          'tv/backdrops',
          tmdbId.toString(),
        );
      }

      for (final actor in showData['cast']) {
        await downloadActorImage(actor);
      }

      developer.log(
        'Processed TV show data',
        name: 'TMDBService',
        error: {'tmdbId': tmdbId, 'name': name},
      );

      return showData;
    } else {
      developer.log(
        'Failed to fetch TV show details',
        name: 'TMDBService',
        error: {
          'tmdbId': tmdbId,
          'statusCode': response.statusCode,
          'response': response.body,
        },
        level: 1000,
      );
      throw Exception('Failed to fetch TV show details');
    }
  }

  Future<Map<String, dynamic>> getSeasonDetails(int showId, int seasonNumber) async {
    developer.log(
      'Fetching season details',
      name: 'TMDBService',
      error: {'showId': showId, 'seasonNumber': seasonNumber},
    );
    
    final response = await http.get(
      Uri.parse('$_baseUrl/tv/$showId/season/$seasonNumber'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data;
    } else {
      developer.log(
        'Failed to fetch season details',
        name: 'TMDBService',
        error: {
          'showId': showId,
          'seasonNumber': seasonNumber,
          'statusCode': response.statusCode,
          'response': response.body,
        },
        level: 1000,
      );
      throw Exception('Failed to fetch season details');
    }
  }

  Future<String> downloadImage(String path, String type, String id) async {
    final url = '$_imageBaseUrl$path';
    developer.log(
      'Downloading image',
      name: 'TMDBService',
      error: {'url': url, 'type': type, 'id': id},
    );
    
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: _headers,
      );
      
      if (response.statusCode == 200) {
        final metadataDir = Directory('/storage/emulated/0/Debrid_Player/metadata/$type/$id');
        await metadataDir.create(recursive: true);
        
        final fileName = type == 'actors' 
            ? '${id}.webp'
            : type.contains('backdrop') 
                ? 'backdrop.webp' 
                : 'poster.webp';
            
        final file = File('${metadataDir.path}/$fileName');
        final compressedImage = await FlutterImageCompress.compressWithList(
          response.bodyBytes,
          format: CompressFormat.webp,
          quality: 75,
        );

        await file.writeAsBytes(compressedImage);
        
        developer.log(
          'Image downloaded and compressed',
          name: 'TMDBService',
          error: {
            'path': file.path,
            'originalSize': response.bodyBytes.length,
            'compressedSize': compressedImage.length,
          },
        );
        return file.path;
      } else {
        developer.log(
          'Failed to download image',
          name: 'TMDBService',
          error: {
            'url': url,
            'statusCode': response.statusCode,
          },
          level: 1000,
        );
        throw Exception('Failed to download image');
      }
    } catch (e, st) {
      developer.log(
        'Error downloading/compressing image',
        name: 'TMDBService',
        error: {'url': url, 'error': e.toString()},
        stackTrace: st,
        level: 1000,
      );
      rethrow;
    }
  }

  Future<void> downloadActorImage(Map<String, dynamic> actor) async {
    if (actor['profile_path'] == null) return;

    final actorImagesDir = Directory('/storage/emulated/0/Debrid_Player/metadata/actors');
    final actorImageFile = File('${actorImagesDir.path}/${actor['id']}/${actor['id']}.webp');

    if (!await actorImageFile.exists()) {
      developer.log(
        'Downloading new actor image',
        name: 'TMDBService',
        error: {'actorName': actor['name']},
      );
      await downloadImage(
        actor['profile_path'],
        'actors',
        actor['id'].toString(),
      );
    } else {
      developer.log(
        'Actor image already exists',
        name: 'TMDBService',
        error: {'actorName': actor['name']},
      );
    }
  }
} 