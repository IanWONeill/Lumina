import 'dart:convert';
import 'dart:developer' as developer;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/orionoid_service.dart';

final orionoidServiceProvider = Provider((ref) => OrionoidService());

final orionoidAuthProvider = AsyncNotifierProvider<OrionoidAuthNotifier, String?>(
  OrionoidAuthNotifier.new,
);

class OrionoidAuthNotifier extends AsyncNotifier<String?> {
  late final OrionoidService _orionoidService;
  static const _tokenKey = 'orionoid_token';

  @override
  Future<String?> build() async {
    developer.log(
      'Building OrionoidAuthNotifier...',
      name: 'OrionoidAuth'
    );
    _orionoidService = ref.read(orionoidServiceProvider);
    final prefs = await SharedPreferences.getInstance();
    final savedToken = prefs.getString(_tokenKey);
    
    if (savedToken != null) {
      developer.log(
        'Found saved Orionoid token',
        name: 'OrionoidAuth',
        error: {'token': '${savedToken.substring(0, 10)}...'},
      );
      return savedToken;
    } else {
      developer.log(
        'No saved Orionoid token found',
        name: 'OrionoidAuth'
      );
      return null;
    }
  }

  Future<void> startAuth() async {
    developer.log(
      'Starting Orionoid authorization process...',
      name: 'OrionoidAuth'
    );
    state = const AsyncValue.loading();
    
    try {
      final authData = await _orionoidService.requestAuthCode();
      final authInfo = {
        'link': authData['data']['link'],
        'qr': authData['data']['qr'],
        'code': authData['data']['code'],
      };
      developer.log(
        'Received auth info, starting polling...',
        name: 'OrionoidAuth'
      );
      state = AsyncValue.data('CODE:${jsonEncode(authInfo)}');

      bool polling = true;
      int attempts = 0;
      final code = authData['data']['code'];
      
      while (polling) {
        attempts++;
        developer.log(
          'Polling attempt',
          name: 'OrionoidAuth',
          error: {'attempt': attempts},
        );
        await Future.delayed(const Duration(seconds: 5));
        
        final token = await _orionoidService.pollForToken(code);
        if (token != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_tokenKey, token);
          state = AsyncValue.data(token);
          polling = false;
        }

        if (attempts >= 60) {
          state = const AsyncValue.error('Authorization timeout', StackTrace.empty);
          polling = false;
        }
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
} 