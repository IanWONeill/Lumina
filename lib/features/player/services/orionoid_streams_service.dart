import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:developer' as developer;
import '../../settings/providers/orion_settings_provider.dart';

class OrionoidStreamsService {
  static const String _baseUrl = 'https://api.orionoid.com';
  final String _token;
  final OrionQuerySettings settings;

  OrionoidStreamsService(this._token, this.settings);

  void _logLongString(String text, {String type = 'Data'}) {
    final pattern = RegExp('.{1,800}');
    var partNumber = 1;
    pattern.allMatches(text).forEach((match) {
      developer.log(
        '$type (Part $partNumber)',
        name: 'OrionoidStreams',
        error: match.group(0),
      );
      partNumber++;
    });
  }

  Future<Map<String, dynamic>> getStreams({
    required String imdbId,
    required bool isMovie,
    int? seasonNumber,
    int? episodeNumber,
  }) async {
    // Try with filters first
    final result = await _makeRequest(
      imdbId: imdbId,
      isMovie: isMovie,
      seasonNumber: seasonNumber,
      episodeNumber: episodeNumber,
      useFilters: true,
    );

    // Check if we got any streams
    final streams = result['data']?['streams'] as List<dynamic>?;
    if (streams != null && streams.isNotEmpty) {
      developer.log(
        'Found streams with filters',
        name: 'OrionoidStreams',
        error: {'count': streams.length},
      );
      return result;
    }

    // If no streams found, try without filters
    developer.log(
      'No streams found with filters, trying without filters',
      name: 'OrionoidStreams',
    );

    return await _makeRequest(
      imdbId: imdbId,
      isMovie: isMovie,
      seasonNumber: seasonNumber,
      episodeNumber: episodeNumber,
      useFilters: false,
    );
  }

  Future<Map<String, dynamic>> _makeRequest({
    required String imdbId,
    required bool isMovie,
    int? seasonNumber,
    int? episodeNumber,
    required bool useFilters,
  }) async {
    
    final Map<String, String> requestData = {
      'token': _token,
      'mode': 'stream',
      'action': 'retrieve',
      'access': settings.accessTypesParam,
      'type': isMovie ? 'movie' : 'show',
      'idimdb': imdbId,
      'limitcount': settings.limitCount.toString(),
      'streamtype': settings.streamTypesParam,
      'sortvalue': settings.sortValue,
    };

    // Only apply filters if useFilters is true
    if (useFilters) {
      requestData['filesize'] = settings.fileSizeParam;
      
      if (settings.audioLanguagesParam != null) {
        requestData['audiolanguages'] = settings.audioLanguagesParam!;
      }

      if (settings.filematchParam != null) {
        requestData['filematch'] = settings.filematchParam!;
      }
    }

    if (!isMovie) {
      if (seasonNumber == null || episodeNumber == null) {
        throw ArgumentError('Season and episode numbers required for TV shows');
      }
      requestData['numberseason'] = seasonNumber.toString();
      requestData['numberepisode'] = episodeNumber.toString();
      requestData['filepack'] = 'true';
    }

    developer.log(
      'Stream Request',
      name: 'OrionoidStreams',
      error: {
        'url': _baseUrl,
        'mediaType': isMovie ? 'movie' : 'show',
        'imdbId': imdbId,
        'season': seasonNumber,
        'episode': episodeNumber,
        'useFilters': useFilters,
      },
    );

    _logLongString(
      jsonEncode(requestData),
      type: 'Request Data',
    );

    final response = await http.post(
      Uri.parse(_baseUrl),
      body: requestData,
    );

    developer.log(
      'Response Status',
      name: 'OrionoidStreams',
      error: {
        'statusCode': response.statusCode,
        'success': response.statusCode == 200,
        'useFilters': useFilters,
      },
    );

    _logLongString(
      response.body,
      type: 'Response Body',
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to get streams: ${response.body}');
    }
  }
} 