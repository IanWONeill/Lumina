import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/stream_info.dart';

part 'stream_selection_provider.g.dart';

@riverpod
class StreamSelection extends _$StreamSelection {
  @override
  StreamInfo? build() {
    return null;
  }

  void selectStream(StreamInfo stream) {
    state = stream;
  }

  void clearSelection() {
    state = null;
  }
} 