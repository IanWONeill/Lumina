import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../services/api_keys_service.dart';
import 'dart:developer' as developer;

part 'premiumize_provider.g.dart';

@riverpod
Future<String?> premiumizeApiKey(PremiumizeApiKeyRef ref) async {
  final apiKeys = await ApiKeysService.readApiKeys();
  final apiKey = apiKeys['premiumize'];

  developer.log(
    'Premiumize API Key Status',
    name: 'PremiumizeProvider',
    error: {'found': apiKey != null},
  );

  return apiKey;
} 