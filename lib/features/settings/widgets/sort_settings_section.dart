import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/sort_settings_provider.dart';

class SortSettingsSection extends ConsumerWidget {
  const SortSettingsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sortField = ref.watch(sortFieldProvider);
    final sortAscending = ref.watch(sortAscendingProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Sort Settings',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
        DropdownButtonFormField<SortField>(
          value: sortField,
          decoration: const InputDecoration(
            labelText: 'Sort by',
            border: OutlineInputBorder(),
          ),
          items: SortField.values.map((field) {
            return DropdownMenuItem(
              value: field,
              child: Text(
                switch (field) {
                  SortField.title => 'Title',
                  SortField.releaseDate => 'Release Date',
                  SortField.dateAdded => 'Date Added',
                },
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              ref.read(sortFieldProvider.notifier).setSortField(value);
            }
          },
        ),
        const SizedBox(height: 16),
        SwitchListTile(
          title: const Text('Reverse Order'),
          value: !sortAscending,
          onChanged: (value) {
            ref.read(sortAscendingProvider.notifier).setSortAscending(!value);
          },
        ),
      ],
    );
  }
} 