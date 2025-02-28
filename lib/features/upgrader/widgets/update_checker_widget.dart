import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../providers/version_checker_provider.dart';
import '../services/download_service.dart';

class UpdateCheckerWidget extends ConsumerStatefulWidget {
  const UpdateCheckerWidget({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<UpdateCheckerWidget> createState() => _UpdateCheckerWidgetState();
}

class _UpdateCheckerWidgetState extends ConsumerState<UpdateCheckerWidget> {
  late final ValueNotifier<double> _progressNotifier;
  late final DownloadService _downloadService;
  bool _isDownloading = false;
  BuildContext? _dialogContext;

  @override
  void initState() {
    super.initState();
    _progressNotifier = ValueNotifier<double>(0.0);
    _downloadService = DownloadService();
  }

  @override
  void dispose() {
    _progressNotifier.dispose();
    if (_dialogContext != null) {
      Navigator.of(_dialogContext!).pop();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(versionCheckerProvider, (previous, next) {
      next.whenData((versionInfo) async {
        if (versionInfo != null && mounted && !_isDownloading) {
          final packageInfo = await PackageInfo.fromPlatform();
          _showUpdateDialog(context, versionInfo, packageInfo.version);
        }
      });
    });

    return widget.child;
  }

  void _showDownloadProgress(BuildContext context) {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        _dialogContext = dialogContext;
        return WillPopScope(
          onWillPop: () async => false,
          child: AlertDialog(
            title: const Text('Downloading Update'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const LinearProgressIndicator(),
                const SizedBox(height: 16),
                ValueListenableBuilder<double>(
                  valueListenable: _progressNotifier,
                  builder: (context, progress, _) {
                    return Text('${(progress * 100).toStringAsFixed(1)}%');
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showUpdateDialog(BuildContext context, versionInfo, String currentVersion) {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (dialogContext) {
        _dialogContext = dialogContext;
        return AlertDialog(
          title: Text('Update ${versionInfo.version} Available'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'You are currently running version $currentVersion.',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 24),
                const Text(
                  'What\'s New:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  versionInfo.notes,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            Focus(
              autofocus: true,
              child: Builder(
                builder: (context) {
                  final bool hasFocus = Focus.of(context).hasFocus;
                  return TextButton(
                    onPressed: () {
                      if (_dialogContext != null) {
                        Navigator.pop(_dialogContext!);
                        _dialogContext = null;
                      }
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: hasFocus ? Colors.blue.withOpacity(0.2) : null,
                    ),
                    child: Text(
                      'Later',
                      style: TextStyle(
                        color: hasFocus ? Colors.blue : Colors.white70,
                      ),
                    ),
                  );
                },
              ),
            ),
            Focus(
              child: Builder(
                builder: (context) {
                  final bool hasFocus = Focus.of(context).hasFocus;
                  return TextButton(
                    onPressed: () async {
                      if (!mounted || _dialogContext == null) return;
                      _isDownloading = true;
                      Navigator.pop(_dialogContext!);
                      _dialogContext = null;
                      _showDownloadProgress(context);

                      try {
                        await _downloadService.downloadAndInstallApk(
                          versionInfo.url,
                          (progress) {
                            if (mounted) {
                              _progressNotifier.value = progress;
                            }
                          },
                          () {
                            if (mounted && _dialogContext != null) {
                              Navigator.pop(_dialogContext!);
                              _dialogContext = null;
                              _isDownloading = false;
                            }
                          },
                          (error) {
                            if (mounted) {
                              if (_dialogContext != null) {
                                Navigator.pop(_dialogContext!);
                                _dialogContext = null;
                              }
                              _isDownloading = false;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Download failed: $error')),
                              );
                            }
                          },
                        );
                      } catch (e) {
                        if (mounted) {
                          if (_dialogContext != null) {
                            Navigator.pop(_dialogContext!);
                            _dialogContext = null;
                          }
                          _isDownloading = false;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Download failed: $e')),
                          );
                        }
                      }
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: hasFocus ? Colors.blue.withOpacity(0.2) : null,
                    ),
                    child: Text(
                      'Update Now',
                      style: TextStyle(
                        color: hasFocus ? Colors.blue : Colors.white70,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
          actionsAlignment: MainAxisAlignment.center,
          actionsPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        );
      },
    );
  }
} 