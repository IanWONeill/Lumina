import 'dart:developer' as dev;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/simkl_service.dart';

final simklServiceProvider = Provider((ref) => SimklService());

final simklAuthProvider = AsyncNotifierProvider<SimklAuthNotifier, String?>(
  SimklAuthNotifier.new,
);

class SimklAuthNotifier extends AsyncNotifier<String?> {
  late final SimklService _simklService;
  static const _tokenKey = 'simkl_token';

  @override
  Future<String?> build() async {
    _simklService = ref.read(simklServiceProvider);
    final prefs = await SharedPreferences.getInstance();
    final savedToken = prefs.getString(_tokenKey);
    dev.log(savedToken != null 
      ? 'Found saved token: ${savedToken.substring(0, 10)}...'
      : 'No saved token found');
    return savedToken;
  }

  Future<void> startAuth() async {
    dev.log('Starting SIMKL authorization process...');
    state = const AsyncValue.loading();
    
    try {
      final userCode = await _simklService.requestDeviceCode();
      state = AsyncValue.data('CODE:$userCode');

      bool polling = true;
      int attempts = 0;
      while (polling) {
        attempts++;
        await Future.delayed(const Duration(seconds: 5));
        
        final token = await _simklService.pollForToken(userCode);
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

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    state = const AsyncValue.data(null);
  }
} 