import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'dart:convert';

class WikidataService {
  static const String _endpoint = 'https://query.wikidata.org/sparql';

  Future<List<Map<String, dynamic>>> getCollectionsForMovie(String imdbId) async {
    developer.log(
      'Fetching Wikidata collections',
      name: 'WikidataService',
      error: {'imdbId': imdbId},
    );

    final query = '''
    SELECT ?collection ?collectionLabel ?movieLabel ?movieImdbID ?tmdbId ?releaseDate WHERE {
      ?movie wdt:P345 "$imdbId".
      ?movie (wdt:P179|wdt:P361) ?collection.
      ?relatedMovie (wdt:P179|wdt:P361) ?collection.
      ?relatedMovie wdt:P345 ?movieImdbID.
      OPTIONAL { ?relatedMovie wdt:P4947 ?tmdbId. }
      OPTIONAL { ?relatedMovie wdt:P577 ?releaseDate. }
      SERVICE wikibase:label {
        bd:serviceParam wikibase:language "en".
        ?collection rdfs:label ?collectionLabel.
        ?relatedMovie rdfs:label ?movieLabel.
      }
    }
    ORDER BY ?collectionLabel ?movieLabel
    ''';

    try {
      final response = await http.get(
        Uri.parse('$_endpoint?query=${Uri.encodeComponent(query)}'),
        headers: {
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final results = data['results']['bindings'] as List;

        developer.log(
          'Raw Wikidata results',
          name: 'WikidataService',
          error: {
            'imdbId': imdbId,
            'resultsCount': results.length,
            'results': results,
          },
        );

        final collections = <String, Map<String, dynamic>>{};
        
        for (final result in results) {
          final collectionName = result['collectionLabel']['value'];
          final movieTitle = result['movieLabel']['value'];
          final movieImdbId = result['movieImdbID']['value'];
          final tmdbId = result['tmdbId']?['value'];
          final releaseDate = result['releaseDate']?['value'];

          String? formattedDate;
          if (releaseDate != null) {
            try {
              final date = DateTime.parse(releaseDate);
              formattedDate = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
            } catch (e) {
              developer.log(
                'Error parsing release date',
                name: 'WikidataService',
                error: {
                  'date': releaseDate,
                  'error': e.toString(),
                },
              );
            }
          }

          if (!collections.containsKey(collectionName)) {
            collections[collectionName] = {
              'name': collectionName,
              'source': 'wikidata',
              'parts': <Map<String, dynamic>>[],
            };
          }

          collections[collectionName]!['parts']!.add({
            'title': movieTitle,
            'imdb_id': movieImdbId,
            'tmdb_id': tmdbId != null ? int.tryParse(tmdbId) : null,
            'release_date': formattedDate,
          });
        }

        for (final collection in collections.values) {
          final parts = collection['parts'] as List<Map<String, dynamic>>;
          parts.sort((a, b) {
            final aDate = a['release_date'];
            final bDate = b['release_date'];
            if (aDate == null && bDate == null) return 0;
            if (aDate == null) return 1;
            if (bDate == null) return -1;
            return aDate.compareTo(bDate);
          });
        }

        developer.log(
          'Processed Wikidata collections',
          name: 'WikidataService',
          error: {
            'imdbId': imdbId,
            'collectionsCount': collections.length,
            'collectionsData': collections,
          },
        );

        return collections.values.toList();
      } else {
        throw Exception('Failed to fetch Wikidata collections: ${response.statusCode}');
      }
    } catch (e, st) {
      developer.log(
        'Error fetching Wikidata collections',
        name: 'WikidataService',
        error: {'imdbId': imdbId, 'error': e.toString()},
        stackTrace: st,
        level: 1000,
      );
      rethrow;
    }
  }
} 