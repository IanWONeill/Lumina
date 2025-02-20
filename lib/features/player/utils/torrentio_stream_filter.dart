import '../models/stream_info.dart';
import '../../settings/providers/torrentio_settings_provider.dart';

class TorrentioStreamFilter {
  static List<StreamInfo> filterAndSort(
    List<StreamInfo> streams,
    TorrentioQuerySettings settings,
  ) {
    var filteredStreams = streams.where((stream) {
      final sizeStr = stream.fileSize.replaceAll(' GB', '');
      final sizeInGB = double.parse(sizeStr);
      final sizeInBytes = (sizeInGB * 1024 * 1024 * 1024).toInt();

      if (sizeInBytes < settings.minFileSize || sizeInBytes > settings.maxFileSize) {
        return false;
      }

      if (settings.hideHdr && stream.isHdr) {
        return false;
      }

      return true;
    }).toList();

    filteredStreams.sort((a, b) {
      switch (settings.sortValue) {
        case 'quality':
          final qualityOrder = {
            '4K': 4,
            '1080p': 3,
            '720p': 2,
          };
          
          final qualityA = qualityOrder[a.qualityLabel] ?? 1;
          final qualityB = qualityOrder[b.qualityLabel] ?? 1;
          
          if (qualityA != qualityB) {
            return qualityB.compareTo(qualityA);
          }
          
          return b.seeds.compareTo(a.seeds);

        case 'size':
          final sizeA = double.parse(a.fileSize.replaceAll(' GB', ''));
          final sizeB = double.parse(b.fileSize.replaceAll(' GB', ''));
          
          final sizeComparison = sizeB.compareTo(sizeA);
          
          if (sizeComparison == 0) {
            return b.seeds.compareTo(a.seeds);
          }
          
          return sizeComparison;

        default:
          return b.seeds.compareTo(a.seeds);
      }
    });

    return filteredStreams;
  }
} 