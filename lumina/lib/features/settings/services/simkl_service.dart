import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;

class SimklService {
  static const String _baseUrl = 'https://api.simkl.com';
  static const String _clientId = 
    '148a8c1f067f5aaecdaae32f28fb4587fd2991fe2b98ec3291fa03570cc896ac';

  Future<String> requestDeviceCode() async {
    final uri = Uri.parse('$_baseUrl/oauth/pin?client_id=$_clientId');

    developer.log(
      'Requesting device code',
      name: 'SimklService',
      error: {'url': uri.toString()},
    );

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final userCode = data['user_code'] as String;
      developer.log(
        'Received device code',
        name: 'SimklService',
        error: {'userCode': userCode},
      );
      return userCode;
    } else {
      developer.log(
        'Failed to get device code',
        name: 'SimklService',
        error: response.body,
        level: 1000,
      );
      throw Exception('Failed to get device code: ${response.body}');
    }
  }

  Future<String?> pollForToken(String userCode) async {
    final uri = Uri.parse('$_baseUrl/oauth/pin/$userCode?client_id=$_clientId');

    developer.log(
      'Polling for token',
      name: 'SimklService',
      error: {
        'url': uri.toString(),
        'userCode': userCode,
      },
    );

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['result'] == 'OK') {
        final token = data['access_token'] as String;
        developer.log(
          'Token received',
          name: 'SimklService',
        );
        return token;
      }
    } else {
      developer.log(
        'Poll request failed',
        name: 'SimklService',
        error: response.body,
        level: 1000,
      );
    }
    return null;
  }
} 