import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:developer' as developer;

class TorrentioStreamsService {
  static const String _baseUrl = 'https://torrentio.strem.fun';
  final String? premiumizeApiKey;

  TorrentioStreamsService({this.premiumizeApiKey});

  void _logLongString(String text, {String type = 'Data'}) {
    final pattern = RegExp('.{1,800}');
    var partNumber = 1;
    pattern.allMatches(text).forEach((match) {
      developer.log(
        '$type (Part $partNumber)',
        name: 'TorrentioStreams',
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
    final providers = 'yts,eztv,rarbg,1337x,thepiratebay,kickasstorrents,'
        'torrentgalaxy,magnetdl,horriblesubs,nyaasi,tokyotosho,anidex,rutor,rutracker';
    final debridOptions = 'nodownloadlinks';
    final premiumizeParam = premiumizeApiKey != null ? premiumizeApiKey : '';
    
    final String mediaType = isMovie ? 'movie' : 'series';
    String endpoint = '$_baseUrl/providers=$providers|debridoptions=$debridOptions|'
        'premiumize=$premiumizeParam/stream/$mediaType/$imdbId';
        
    if (!isMovie) {
      if (seasonNumber == null || episodeNumber == null) {
        throw Exception('Season and episode numbers are required for TV shows');
      }
      endpoint += ':$seasonNumber:$episodeNumber';
    }
    endpoint += '.json';

    developer.log(
      'Stream Request',
      name: 'TorrentioStreams',
      error: {
        'url': endpoint,
        'mediaType': mediaType,
        'imdbId': imdbId,
        'season': seasonNumber,
        'episode': episodeNumber,
      },
    );

    final headers = {
      "Host": "torrentio.strem.fun",
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
      name: 'TorrentioStreams',
      error: {
        'statusCode': response.statusCode,
        'success': response.statusCode == 200,
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