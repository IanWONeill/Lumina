import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';

class OrionoidService {
  static const String _baseUrl = 'https://api.orionoid.com';
  static const String _keyApp = 'NSKPLFPKW8859TWAMEKHRAAPRUGEHEJM';
  final _dio = Dio();

  Future<Map<String, dynamic>> requestAuthCode() async {
    final requestBody = {
      'keyapp': _keyApp,
      'mode': 'user',
      'action': 'authenticate',
    };
    
    developer.log(
      'Auth Request',
      name: 'OrionoidService',
      error: {
        'url': _baseUrl,
        'body': requestBody,
      },
    );
    
    final response = await http.post(
      Uri.parse(_baseUrl),
      body: requestBody,
    );

    developer.log(
      'Auth Response',
      name: 'OrionoidService',
      error: {
        'statusCode': response.statusCode,
        'body': response.body,
      },
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data;
    } else {
      throw Exception('Failed to get auth code: ${response.body}');
    }
  }

  Future<String?> pollForToken(String code) async {
    final requestBody = {
      'keyapp': _keyApp,
      'mode': 'user',
      'action': 'authenticate',
      'code': code,
    };
    
    developer.log(
      'Poll Request',
      name: 'OrionoidService',
      error: {
        'url': _baseUrl,
        'body': requestBody,
      },
    );
    
    final response = await http.post(
      Uri.parse(_baseUrl),
      body: requestBody,
    );

    developer.log(
      'Poll Response',
      name: 'OrionoidService',
      error: {
        'statusCode': response.statusCode,
        'body': response.body,
      },
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['result']['status'] == 'success' && 
          data['result']['type'] == 'userauthapprove') {
        final token = data['data']['token'] as String;
        return token;
      }
    } else {
      developer.log(
        'Poll request failed',
        name: 'OrionoidService',
        error: response.body,
        level: 1000,
      );
    }
    return null;
  }

  Future<String> resolveDebridLink({
    required String token,
    required String orionId,
    required String streamId,
    int? seasonNumber,
    int? episodeNumber,
  }) async {
    final requestData = {
      'token': token,
      'mode': 'debrid',
      'action': 'resolve',
      'type': 'premiumize',
      'iditem': orionId,
      'idstream': streamId,
      'file': 'original',
    };
    
    developer.log(
      'Debrid Request',
      name: 'OrionoidService',
      error: {
        'url': _baseUrl,
        'data': requestData,
      },
    );
    
    try {
      final response = await _dio.post(
        _baseUrl,
        data: requestData,
      );
      
      developer.log(
        'Debrid Response',
        name: 'OrionoidService',
        error: {'data': response.data},
      );
      
      final files = response.data['data']['files'] as List;
      if (files.isEmpty) {
        throw Exception('No files found in response');
      }

      if (seasonNumber != null && episodeNumber != null) {
        final patterns = [
          RegExp(r'[Ss]0*' + seasonNumber.toString() + r'[Ee]0*' + episodeNumber.toString(), caseSensitive: false),
          RegExp(r'0*' + seasonNumber.toString() + r'x0*' + episodeNumber.toString(), caseSensitive: false),
          RegExp(r'season\s*0*' + seasonNumber.toString() + r'.*episode\s*0*' + episodeNumber.toString(), caseSensitive: false),
        ];

        for (final file in files) {
          final fileName = file['original']['name'] as String? ?? '';
          
          developer.log(
            'Checking file',
            name: 'OrionoidService',
            error: {'fileName': fileName},
          );
          
          for (final pattern in patterns) {
            if (pattern.hasMatch(fileName)) {
              final streamUrl = file['original']['link'] as String?;
              if (streamUrl != null && streamUrl.isNotEmpty) {
                developer.log(
                  'Found matching episode file',
                  name: 'OrionoidService',
                  error: {'fileName': fileName},
                );
                return streamUrl;
              }
            }
          }
        }
        
        throw Exception('Could not find specific episode S${seasonNumber}E$episodeNumber in pack');
      }
      
      final streamUrl = files[0]['original']['link'] as String?;
      if (streamUrl == null || streamUrl.isEmpty) {
        throw Exception('No stream URL found in response');
      }
      
      return streamUrl;
    } catch (e, stackTrace) {
      developer.log(
        'Debrid Error',
        name: 'OrionoidService',
        error: e,
        stackTrace: stackTrace,
        level: 1000,
      );
      rethrow;
    }
  }
} 