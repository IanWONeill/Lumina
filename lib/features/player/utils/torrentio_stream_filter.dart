import '../models/stream_info.dart';
import '../../settings/providers/torrentio_settings_provider.dart';

class TorrentioStreamFilter {
  static List<StreamInfo> filterAndSort(
    List<StreamInfo> streams,
    TorrentioQuerySettings settings,
  ) {
    var filteredStreams = streams.where((stream) {
      double sizeInGB;
      if (stream.fileSize.endsWith(' GB')) {
        sizeInGB = double.parse(stream.fileSize.replaceAll(' GB', ''));
      } else if (stream.fileSize.endsWith(' MB')) {
        sizeInGB = double.parse(stream.fileSize.replaceAll(' MB', '')) / 1024;
      } else {
        return settings.hideHdr ? !stream.isHdr : true;
      }
      
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
          double sizeA, sizeB;
          
          if (a.fileSize.endsWith(' GB')) {
            sizeA = double.parse(a.fileSize.replaceAll(' GB', ''));
          } else if (a.fileSize.endsWith(' MB')) {
            sizeA = double.parse(a.fileSize.replaceAll(' MB', '')) / 1024;
          } else {
            sizeA = 0;
          }
          
          if (b.fileSize.endsWith(' GB')) {
            sizeB = double.parse(b.fileSize.replaceAll(' GB', ''));
          } else if (b.fileSize.endsWith(' MB')) {
            sizeB = double.parse(b.fileSize.replaceAll(' MB', '')) / 1024;
          } else {
            sizeB = 0;
          }
          
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