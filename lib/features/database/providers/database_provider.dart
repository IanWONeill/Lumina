import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../sync/services/database_service.dart';

final databaseServiceProvider = Provider<DatabaseService>((ref) {
  final db = DatabaseService();
  return db;
}); 