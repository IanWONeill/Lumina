import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../sync/services/database_service.dart';

part 'database_provider.g.dart';

@Riverpod(keepAlive: true)
DatabaseService databaseService(DatabaseServiceRef ref) {
  return DatabaseService();
} 