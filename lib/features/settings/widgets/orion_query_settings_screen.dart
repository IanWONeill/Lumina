import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../providers/orion_settings_provider.dart';

class OrionQuerySettingsScreen extends StatelessWidget {
  final String title;
  final OrionQuerySettings settings;
  final Function(int) onLimitCountChanged;
  final Function(List<String>) onStreamTypesChanged;
  final Function(int) onMinFileSizeChanged;
  final Function(int) onMaxFileSizeChanged;
  final Function(List<String>) onAccessTypesChanged;
  final Function(String) onSortValueChanged;
  final Function(bool) onForceEnglishAudioChanged;
  final Function(List<String>) onFilenameFiltersChanged;

  const OrionQuerySettingsScreen({
    super.key,
    required this.title,
    required this.settings,
    required this.onLimitCountChanged,
    required this.onStreamTypesChanged,
    required this.onMinFileSizeChanged,
    required this.onMaxFileSizeChanged,
    required this.onAccessTypesChanged,
    required this.onSortValueChanged,
    required this.onForceEnglishAudioChanged,
    required this.onFilenameFiltersChanged,
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
          return SizedBox(
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
    String Function(T)? formatLabel,
  }) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SelectionScreen<T>(
          title: title,
          options: options,
          selectedValue: selectedValue,
          formatLabel: formatLabel,
        ),
      ),
    );

    if (result != null) {
      onSelect(result as T);
    }
  }

  Future<void> _showMultiSelectDialog({
    required BuildContext context,
    required String title,
    required List<String> options,
    required List<String> selectedValues,
    required Function(List<String>) onConfirm,
  }) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MultiSelectScreen(
          title: title,
          options: options,
          selectedValues: selectedValues,
        ),
      ),
    );

    if (result != null) {
      onConfirm(result as List<String>);
    }
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
                    label: 'Result Limit',
                    value: '${settings.limitCount} results',
                    onPressed: () => _showSelectionDialog<int>(
                      context: context,
                      title: 'Select Result Limit',
                      options: const [10, 25, 50, 75, 100],
                      selectedValue: settings.limitCount,
                      formatLabel: (value) => '$value results',
                      onSelect: onLimitCountChanged,
                    ),
                  ),
                  const SizedBox(height: 16),

                  _buildSettingButton(
                    context: context,
                    label: 'Stream Types',
                    value: '${settings.streamTypes.length} selected',
                    onPressed: () => _showMultiSelectDialog(
                      context: context,
                      title: 'Select Stream Types',
                      options: const ['torrent', 'usenet', 'hoster'],
                      selectedValues: settings.streamTypes,
                      onConfirm: onStreamTypesChanged,
                    ),
                  ),
                  const SizedBox(height: 16),

                  _buildSettingButton(
                    context: context,
                    label: 'Minimum File Size',
                    value: _formatFileSize(settings.minFileSize),
                    onPressed: () => _showSelectionDialog<String>(
                      context: context,
                      title: 'Select Minimum File Size',
                      options: const ['200MB', '500MB', '1GB', '2GB', '3GB', '5GB', 
                                    '7GB', '10GB', '12GB', '15GB', '20GB', '25GB'],
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
                                    '12GB', '15GB', '20GB', '25GB', '30GB', '35GB', 
                                    '40GB', '50GB', '75GB'],
                      selectedValue: _formatFileSize(settings.maxFileSize),
                      onSelect: (value) => onMaxFileSizeChanged(_parseFileSize(value)),
                    ),
                  ),
                  const SizedBox(height: 16),

                  _buildSettingButton(
                    context: context,
                    label: 'Access Types',
                    value: '${settings.accessTypes.length} selected',
                    onPressed: () => _showMultiSelectDialog(
                      context: context,
                      title: 'Select Access Types',
                      options: const ['direct', 'indirect', 'premiumize', 
                        'premiumizetorrent', 'premiumizeusenet', 'premiumizehoster', 
                        'offcloud', 'offcloudtorrent', 'offcloudusenet', 
                        'offcloudhoster', 'torbox', 'torboxtorrent', 'torboxusenet', 
                        'torboxhoster', 'realdebrid', 'realdebridtorrent', 
                        'realdebridusenet', 'realdebridhoster', 'debridlink', 
                        'debridlinktorrent', 'debridlinkhoster', 'alldebrid', 
                        'alldebridtorrent', 'alldebridhoster'],
                      selectedValues: settings.accessTypes,
                      onConfirm: onAccessTypesChanged,
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
                      options: const ['best', 'popularity', 'filesize', 'videoquality', 
                                    'audiochannels'],
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
                              'Force English Audio',
                              style: TextStyle(color: Colors.white),
                            ),
                            trailing: Icon(
                              settings.forceEnglishAudio
                                ? Icons.check_box
                                : Icons.check_box_outline_blank,
                              color: focused ? Colors.blue : Colors.white,
                            ),
                            onTap: () => onForceEnglishAudioChanged(!settings.forceEnglishAudio),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 16),

                  _buildSettingButton(
                    context: context,
                    label: 'Filename Filters',
                    value: settings.filematchFilters.isEmpty 
                      ? 'None' 
                      : '${settings.filematchFilters.length} selected',
                    onPressed: () => _showMultiSelectDialog(
                      context: context,
                      title: 'Select Filename Filters',
                      options: FILEMATCH_FILTERS.keys.toList(),
                      selectedValues: settings.filematchFilters,
                      onConfirm: onFilenameFiltersChanged,
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
}

class SelectionScreen<T> extends StatelessWidget {
  final String title;
  final List<T> options;
  final T selectedValue;
  final String Function(T)? formatLabel;

  const SelectionScreen({
    super.key,
    required this.title,
    required this.options,
    required this.selectedValue,
    this.formatLabel,
  });

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
              child: ListView.builder(
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final option = options[index];
                  final isSelected = option == selectedValue;
                  
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Focus(
                      autofocus: index == 0,
                      onKey: (node, event) {
                        if (event is RawKeyDownEvent &&
                            event.logicalKey == LogicalKeyboardKey.select) {
                          Navigator.pop(context, option);
                          return KeyEventResult.handled;
                        }
                        return KeyEventResult.ignored;
                      },
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
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Icon(
                                  isSelected 
                                    ? Icons.radio_button_checked 
                                    : Icons.radio_button_unchecked,
                                  color: focused ? Colors.blue : Colors.white,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  formatLabel?.call(option) ?? option.toString(),
                                  style: TextStyle(
                                    color: focused ? Colors.blue : Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MultiSelectScreen extends StatefulWidget {
  final String title;
  final List<String> options;
  final List<String> selectedValues;

  const MultiSelectScreen({
    super.key,
    required this.title,
    required this.options,
    required this.selectedValues,
  });

  @override
  State<MultiSelectScreen> createState() => _MultiSelectScreenState();
}

class _MultiSelectScreenState extends State<MultiSelectScreen> {
  late List<String> _selectedValues;

  @override
  void initState() {
    super.initState();
    _selectedValues = List.from(widget.selectedValues);
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
              widget.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView.builder(
                itemCount: widget.options.length,
                itemBuilder: (context, index) {
                  final option = widget.options[index];
                  final isSelected = _selectedValues.contains(option);
                  
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Focus(
                      autofocus: index == 0,
                      onKey: (node, event) {
                        if (event is RawKeyDownEvent &&
                            event.logicalKey == LogicalKeyboardKey.select) {
                          setState(() {
                            if (isSelected) {
                              _selectedValues.remove(option);
                            } else {
                              _selectedValues.add(option);
                            }
                          });
                          return KeyEventResult.handled;
                        }
                        return KeyEventResult.ignored;
                      },
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
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Icon(
                                  isSelected 
                                    ? Icons.check_box 
                                    : Icons.check_box_outline_blank,
                                  color: focused ? Colors.blue : Colors.white,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  option,
                                  style: TextStyle(
                                    color: focused ? Colors.blue : Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Focus(
                  child: Builder(
                    builder: (context) {
                      final focused = Focus.of(context).hasFocus;
                      return ElevatedButton(
                        onPressed: () => Navigator.pop(context, _selectedValues),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: focused 
                            ? Colors.blue.withOpacity(0.2) 
                            : Colors.white.withOpacity(0.1),
                          foregroundColor: focused ? Colors.blue : Colors.white,
                          side: focused 
                            ? const BorderSide(color: Colors.blue, width: 2)
                            : null,
                        ),
                        child: const Text('Confirm'),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
} 