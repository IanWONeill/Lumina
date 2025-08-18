import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../services/api_keys_service.dart';
import 'dart:developer' as developer;

part 'aio_config_provider.g.dart';

@riverpod
Future<String?> aioConfig(AioConfigRef ref) async {
  final apiKeys = await ApiKeysService.readApiKeys();
  final aioConfig = apiKeys['aio_streams'];

  developer.log(
    'AIOConfig Status',
    name: 'AioConfigProvider',
    error: {'found': aioConfig != null},
  );

  return aioConfig;
}
