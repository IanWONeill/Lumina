import 'package:flutter/material.dart';
import '../providers/torrentio_settings_provider.dart';
import './orion_query_settings_screen.dart';

class TorrentioQuerySettingsScreen extends StatelessWidget {
  final String title;
  final TorrentioQuerySettings settings;
  final Function(int) onMinFileSizeChanged;
  final Function(int) onMaxFileSizeChanged;
  final Function(String) onSortValueChanged;
  final Function(bool) onHideHdrChanged;

  const TorrentioQuerySettingsScreen({
    super.key,
    required this.title,
    required this.settings,
    required this.onMinFileSizeChanged,
    required this.onMaxFileSizeChanged,
    required this.onSortValueChanged,
    required this.onHideHdrChanged,
  });

  String _formatFileSize(int bytes) {
    if (bytes >= 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024 * 1024)).round()}GB';
    }
    return '${(bytes / (1024 * 1024)).round()}MB';
  }

  int _parseFileSize(String size) {
    final value = int.parse(size.replaceAll(RegExp(r'[A-Za-z]'), ''));
    if (size.endsWith('GB')) {
      return value * 1024 * 1024 * 1024;
    }
    return value * 1024 * 1024;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView(
                children: [
                  _buildSettingButton(
                    context: context,
                    label: 'Minimum File Size',
                    value: _formatFileSize(settings.minFileSize),
                    onPressed: () => _showSelectionDialog<String>(
                      context: context,
                      title: 'Select Minimum File Size',
                      options: const ['200MB', '500MB', '1GB', '2GB', '3GB', '5GB'],
                      selectedValue: _formatFileSize(settings.minFileSize),
                      onSelect: (value) => onMinFileSizeChanged(_parseFileSize(value)),
                    ),
                  ),
                  const SizedBox(height: 16),

                  _buildSettingButton(
                    context: context,
                    label: 'Maximum File Size',
                    value: _formatFileSize(settings.maxFileSize),
                    onPressed: () => _showSelectionDialog<String>(
                      context: context,
                      title: 'Select Maximum File Size',
                      options: const ['1GB', '2GB', '3GB', '5GB', '6GB', '8GB', '10GB', 
                                    '15GB', '20GB', '25GB', '30GB'],
                      selectedValue: _formatFileSize(settings.maxFileSize),
                      onSelect: (value) => onMaxFileSizeChanged(_parseFileSize(value)),
                    ),
                  ),
                  const SizedBox(height: 16),

                  _buildSettingButton(
                    context: context,
                    label: 'Sort By',
                    value: settings.sortValue,
                    onPressed: () => _showSelectionDialog<String>(
                      context: context,
                      title: 'Select Sort Order',
                      options: const ['quality', 'size'],
                      selectedValue: settings.sortValue,
                      onSelect: onSortValueChanged,
                    ),
                  ),
                  const SizedBox(height: 16),

                  Focus(
                    child: Builder(
                      builder: (context) {
                        final focused = Focus.of(context).hasFocus;
                        return Container(
                          decoration: BoxDecoration(
                            color: focused 
                              ? Colors.blue.withOpacity(0.2) 
                              : Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: focused
                              ? Border.all(color: Colors.blue, width: 2)
                              : null,
                          ),
                          child: ListTile(
                            title: const Text(
                              'Hide HDR Content',
                              style: TextStyle(color: Colors.white),
                            ),
                            trailing: Icon(
                              settings.hideHdr
                                ? Icons.check_box
                                : Icons.check_box_outline_blank,
                              color: focused ? Colors.blue : Colors.white,
                            ),
                            onTap: () => onHideHdrChanged(!settings.hideHdr),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingButton({
    required BuildContext context,
    required String label,
    required String value,
    required VoidCallback onPressed,
  }) {
    return Focus(
      child: Builder(
        builder: (context) {
          final focused = Focus.of(context).hasFocus;
          return Container(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: focused 
                  ? Colors.blue.withOpacity(0.2) 
                  : Colors.white.withOpacity(0.1),
                foregroundColor: focused ? Colors.blue : Colors.white,
                padding: const EdgeInsets.all(16),
                side: focused 
                  ? const BorderSide(color: Colors.blue, width: 2)
                  : null,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(label),
                  Text(value),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _showSelectionDialog<T>({
    required BuildContext context,
    required String title,
    required List<T> options,
    required T selectedValue,
    required Function(T) onSelect,
  }) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SelectionScreen<T>(
          title: title,
          options: options,
          selectedValue: selectedValue,
        ),
      ),
    );

    if (result != null) {
      onSelect(result as T);
    }
  }
} 