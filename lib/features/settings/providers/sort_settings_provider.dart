import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../movies/providers/movies_provider.dart';

enum SortField {
  title,
  releaseDate,
  dateAdded,
}

final sortFieldProvider = StateNotifierProvider<SortFieldNotifier, SortField>((ref) {
  return SortFieldNotifier(ref);
});

final sortAscendingProvider = StateNotifierProvider<SortAscendingNotifier, bool>((ref) {
  return SortAscendingNotifier(ref);
});

class SortFieldNotifier extends StateNotifier<SortField> {
  final Ref ref;
  
  SortFieldNotifier(this.ref) : super(SortField.title) {
    _loadSavedField();
  }

  Future<void> _loadSavedField() async {
    final prefs = await SharedPreferences.getInstance();
    final savedField = prefs.getString('sort_field') ?? 'title';
    state = SortField.values.firstWhere(
      (field) => field.name == savedField,
      orElse: () => SortField.title,
    );
  }

  Future<void> setSortField(SortField field) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('sort_field', field.name);
    state = field;
    ref.invalidate(moviesProvider);
  }
}

class SortAscendingNotifier extends StateNotifier<bool> {
  final Ref ref;
  
  SortAscendingNotifier(this.ref) : super(true) {
    _loadSavedDirection();
  }

  Future<void> _loadSavedDirection() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool('sort_ascending') ?? true;
  }

  Future<void> setSortAscending(bool ascending) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sort_ascending', ascending);
    state = ascending;
    ref.invalidate(moviesProvider);
  }
} 