import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:developer' as developer;
import 'features/movies/screens/movies_screen.dart';
import 'features/tv_shows/screens/tv_shows_screen.dart';
import 'features/settings/screens/settings_screen.dart';
import 'features/sync/providers/sync_provider.dart';
import 'features/player/providers/just_player_broadcast_provider.dart';
import 'features/search/screens/search_screen.dart';

void main() {
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Media Center',
        theme: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: Colors.blue,
            secondary: Colors.blueAccent,
          ),
          scaffoldBackgroundColor: Colors.black87,
          appBarTheme: const AppBarTheme(
            toolbarHeight: 0,
            backgroundColor: Colors.transparent,
            elevation: 0,
            titleTextStyle: TextStyle(
              height: 0,
              fontSize: 0,
            ),
            toolbarTextStyle: TextStyle(
              height: 0,
              fontSize: 0,
            ),
            iconTheme: IconThemeData(
              size: 0,
              opacity: 0,
            ),
            actionsIconTheme: IconThemeData(
              size: 0,
              opacity: 0,
            ),
          ),
        ),
        home: const HomeScreen(),
      );
}

final syncStatusProvider = StateProvider<String?>((ref) => null);

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int? _focusedIndex;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      developer.log(
        'Starting JustPlayer broadcast listener',
        name: 'HomeScreen',
      );
      
      final service = ref.read(justPlayerBroadcastServiceProvider);
      service.startListening().then((_) {
        developer.log(
          'JustPlayer broadcast listener started successfully',
          name: 'HomeScreen',
        );
      }).catchError((error, stackTrace) {
        developer.log(
          'Failed to start JustPlayer broadcast listener',
          name: 'HomeScreen',
          error: error.toString(),
          stackTrace: stackTrace,
          level: 1000,
        );
      });
    });
  }

  static const _syncMenuIndex = 3;
  static const _settingsIndex = 4;

  late final List<MenuItem> _menuItems = [
    const MenuItem(
      icon: Icons.movie,
      label: 'Movies',
      destination: MoviesScreen(),
    ),
    const MenuItem(
      icon: Icons.tv,
      label: 'TV Shows',
      destination: TVShowsScreen(),
    ),
    MenuItem(
      icon: Icons.search,
      label: 'Search',
      destination: const SearchScreen(),
      onSelect: () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const SearchScreen(),
          ),
        );
      },
    ),
    MenuItem(
      icon: Icons.sync,
      label: 'Sync',
      destination: const SizedBox.shrink(),
      onSelect: () => ref.read(syncProvider.notifier).startSync(),
    ),
    const MenuItem(
      icon: Icons.settings,
      label: 'Settings',
      destination: SettingsScreen(),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final syncState = ref.watch(syncProvider);
    final syncStatus = ref.watch(syncStatusProvider);

    return Scaffold(
      body: Stack(
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (syncState.isLoading && syncStatus != null)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.blue.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 120,
                        child: Text(
                          syncStatus.split(':')[0] + ':',
                          style: TextStyle(
                            color: Colors.blue.withOpacity(0.9),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          syncStatus.split(':').length > 1 
                              ? syncStatus.split(':')[1].trim()
                              : '',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              _buildMainMenu(syncState),
            ],
          ),
          Positioned(
            bottom: 20,
            right: 20,
            child: _buildSettingsButton(),
          ),
        ],
      ),
    );
  }

  Widget _buildMainMenu(AsyncValue<void> syncState) => SizedBox(
        height: 200,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _menuItems.length - 1,
            (index) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: FocusableActionDetector(
                autofocus: index == 0,
                onFocusChange: (focused) {
                  if (focused) {
                    setState(() => _focusedIndex = index);
                  }
                },
                actions: {
                  ActivateIntent: CallbackAction<ActivateIntent>(
                    onInvoke: (_) {
                      if (index == _syncMenuIndex) {
                        _menuItems[index].onSelect?.call();
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => _menuItems[index].destination,
                          ),
                        );
                      }
                      return null;
                    },
                  ),
                },
                child: Focus(
                  onKey: (node, event) {
                    if (event is RawKeyDownEvent) {
                      if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                        FocusScope.of(context).requestFocus(_settingsFocusNode);
                        setState(() => _focusedIndex = _settingsIndex);
                        return KeyEventResult.handled;
                      }
                      if (index == _syncMenuIndex && 
                          event.logicalKey == LogicalKeyboardKey.arrowRight) {
                        return KeyEventResult.handled;
                      }
                    }
                    return KeyEventResult.ignored;
                  },
                  child: InkWell(
                    onTap: () {
                      if (index == _syncMenuIndex) {
                        _menuItems[index].onSelect?.call();
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => _menuItems[index].destination,
                          ),
                        );
                      }
                    },
                    child: MainMenuItem(
                      item: _menuItems[index],
                      isFocused: index == _focusedIndex,
                      isLoading: index == _syncMenuIndex && syncState.isLoading,
                      hasError: index == _syncMenuIndex && syncState.hasError,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

  final _settingsFocusNode = FocusNode();

  Widget _buildSettingsButton() => SizedBox(
        width: 100,
        height: 100,
        child: FocusableActionDetector(
          focusNode: _settingsFocusNode,
          onFocusChange: (focused) {
            if (focused) {
              setState(() => _focusedIndex = _settingsIndex);
            }
          },
          actions: {
            ActivateIntent: CallbackAction<ActivateIntent>(
              onInvoke: (_) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => _menuItems[_settingsIndex].destination,
                  ),
                );
                return null;
              },
            ),
          },
          child: Focus(
            onKey: (node, event) {
              if (event is RawKeyDownEvent &&
                  event.logicalKey == LogicalKeyboardKey.arrowUp) {
                FocusScope.of(context).previousFocus();
                return KeyEventResult.handled;
              }
              return KeyEventResult.ignored;
            },
            child: MainMenuItem(
              item: _menuItems[_settingsIndex],
              isFocused: _settingsIndex == _focusedIndex,
              isSmall: true,
            ),
          ),
        ),
      );
}

class MenuItem {
  const MenuItem({
    required this.icon,
    required this.label,
    required this.destination,
    this.onSelect,
  });

  final IconData icon;
  final String label;
  final Widget destination;
  final VoidCallback? onSelect;
}

class MainMenuItem extends StatelessWidget {
  const MainMenuItem({
    required this.item,
    required this.isFocused,
    this.isLoading = false,
    this.hasError = false,
    this.isSmall = false,
    super.key,
  });

  final MenuItem item;
  final bool isFocused;
  final bool isLoading;
  final bool hasError;
  final bool isSmall;

  @override
  Widget build(BuildContext context) => Container(
        width: isSmall ? 100 : 200,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              isFocused ? Colors.blue : Colors.white10,
              isFocused ? Colors.blue.shade900 : Colors.black45,
            ],
          ),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isFocused ? Colors.white30 : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isLoading)
              const SizedBox(
                width: 36,
                height: 36,
                child: CircularProgressIndicator(strokeWidth: 3),
              )
            else
              Icon(
                hasError ? Icons.sync_problem : item.icon,
                size: isSmall ? 24 : 36,
                color: hasError ? Colors.red[700] : Colors.white,
              ),
            const SizedBox(height: 8),
            Text(
              item.label,
              style: TextStyle(
                fontSize: isSmall ? 14 : 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      );
}
