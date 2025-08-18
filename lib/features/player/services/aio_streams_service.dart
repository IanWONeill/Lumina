import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:developer' as developer;

class AioStreamsService {
  static const String _baseUrl = 'https://aiostreams.elfhosted.com/stremio';
  final String? aioConfig;

  AioStreamsService({this.aioConfig});

  void _logLongString(String text, {String type = 'Data'}) {
    final pattern = RegExp('.{1,800}');
    var partNumber = 1;
    pattern.allMatches(text).forEach((match) {
      developer.log(
        '$type (Part $partNumber)',
        name: 'AioStreams',
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
    bool useFilters = true,
  }) async {
    if (aioConfig == null || aioConfig!.isEmpty) {
      throw Exception('AIOConfig is required');
    }

    final String mediaType = isMovie ? 'movie' : 'series';
    String endpoint = '$_baseUrl/$aioConfig/stream/$mediaType/$imdbId';
        
    if (!isMovie) {
      if (seasonNumber == null || episodeNumber == null) {
        throw Exception('Season and episode numbers are required for TV shows');
      }
      endpoint += '%3A$seasonNumber%3A$episodeNumber';
    }
    endpoint += '.json';

    developer.log(
      'Stream Request URL',
      name: 'AioStreams',
      error: endpoint,
    );
    
    developer.log(
      'Stream Request Details',
      name: 'AioStreams',
      error: {
        'mediaType': mediaType,
        'imdbId': imdbId,
        'season': seasonNumber,
        'episode': episodeNumber,
        'useFilters': useFilters,
      },
    );

    final headers = {
      "Host": "aiostreams.elfhosted.com",
      "Connection": "keep-alive",
      "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 "
          "(KHTML, like Gecko) Chrome/132.0.0.0 Safari/537.36 Edg/132.0.0.0",
      "Accept": "*/*",
      "Origin": "https://web.stremio.com",
      "Sec-Fetch-Site": "cross-site",
      "Sec-Fetch-Mode": "cors",
      "Sec-Fetch-Dest": "empty",
      "Referer": "https://web.stremio.com/",
      "Accept-Language": "en-US,en;q=0.9"
    };

    final response = await http.get(Uri.parse(endpoint), headers: headers);

    developer.log(
      'Response Status',
      name: 'AioStreams',
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
