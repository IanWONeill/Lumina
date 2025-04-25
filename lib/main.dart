import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:developer' as developer;
import 'dart:io' show exit;
import 'package:device_info_plus/device_info_plus.dart';
import 'features/movies/screens/movies_screen.dart';
import 'features/tv_shows/screens/tv_shows_screen.dart';
import 'features/settings/screens/settings_screen.dart';
import 'features/sync/providers/sync_provider.dart';
import 'features/player/providers/just_player_broadcast_provider.dart';
import 'features/search/screens/search_screen.dart';
import 'features/sync/providers/sync_schedule_provider.dart';
import 'features/sync/widgets/sync_status_overlay.dart';
import 'widgets/digital_clock.dart';
import 'features/database/providers/database_provider.dart';
import 'widgets/rss_ticker.dart';
import 'features/upgrader/widgets/update_checker_widget.dart';
import 'features/settings/services/api_keys_service.dart';

final navigatorKey = GlobalKey<NavigatorState>();
final movieCountProvider = StateNotifierProvider<CountNotifier, int>((ref) => CountNotifier());
final tvShowCountProvider = StateNotifierProvider<CountNotifier, int>((ref) => CountNotifier());

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final hasPermission = await ApiKeysService.hasStoragePermission();
  if (!hasPermission) {
    final deviceInfo = await DeviceInfoPlugin().androidInfo;
    final sdkInt = deviceInfo.version.sdkInt;
    
    String permissionInstructions = 'Please grant storage permission in your device settings and restart the app.';
    if (sdkInt >= 30) {
      permissionInstructions = 'Please go to Settings > Apps > Lumina > Permissions > Files and media > Allow management of all files and restart the app.';
    } else if (sdkInt >= 29) {
      permissionInstructions = 'Please go to Settings > Apps > Lumina > Permissions > Storage > Allow and restart the app.';
    }

    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: AlertDialog(
              title: const Text('Storage Permission Required'),
              content: Text(
                'This app requires storage permission to save metadata.\n\n'
                '$permissionInstructions',
              ),
              actions: [
                TextButton(
                  onPressed: () => exit(0),
                  child: const Text('OK'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    return;
  }
  
  final wasCreated = await ApiKeysService.createApiKeysFileIfNotExists();
  
  if (wasCreated) {
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: AlertDialog(
              title: const Text('API Keys File Created'),
              content: const Text(
                'The API keys file was not found and has been created.\n\n'
                'Please edit the file at:\n'
                '/storage/Debrid_Player/api_keys.txt\n\n'
                'Add your API keys and restart the app.',
              ),
              actions: [
                TextButton(
                  onPressed: () => exit(0),
                  child: const Text('OK'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    return;
  }

  final apiKeysStatus = await ApiKeysService.checkApiKeys();
  final missingRequired = apiKeysStatus['missingRequired']!;
  final missingOptional = apiKeysStatus['missingOptional']!;

  if (missingRequired.isNotEmpty || missingOptional.isNotEmpty) {
    final message = StringBuffer();
    
    if (missingRequired.isNotEmpty) {
      message.writeln('The following required API keys are missing or not set:');
      message.writeln(missingRequired.map((key) => key.toUpperCase()).join(', '));
      message.writeln();
    }
    
    if (missingOptional.isNotEmpty) {
      message.writeln('You must set at least one of these API keys:');
      message.writeln(missingOptional.map((key) => key.toUpperCase()).join(' or '));
      message.writeln();
    }
    
    message.writeln('Please edit the file at:');
    message.writeln('/storage/Debrid_Player/api_keys.txt');
    message.writeln();
    message.writeln('Add your API keys and restart the app.');

    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: AlertDialog(
              title: const Text('Missing API Keys'),
              content: Text(message.toString()),
              actions: [
                TextButton(
                  onPressed: () => exit(0),
                  child: const Text('OK'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    return;
  }
  
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
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
      home: const UpdateCheckerWidget(
        child: InitApp(),
      ),
      builder: (context, child) => Stack(
        children: [
          if (child != null) child,
          const SyncStatusOverlay(),
        ],
      ),
      navigatorKey: navigatorKey,
    );
  }
}

class InitApp extends ConsumerWidget {
  const InitApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(syncScheduleProvider);
    
    return const HomeScreen();
  }
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
      _updateCounts();
      
      final db = ref.read(databaseServiceProvider);
      db.setOnMovieAdded(() {
        if (mounted) {
          ref.read(movieCountProvider.notifier).increment();
        }
      });
      
      db.setOnTVShowAdded(() {
        if (mounted) {
          ref.read(tvShowCountProvider.notifier).increment();
        }
      });
      
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

  Future<bool> _onWillPop() async {
    final shouldPop = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Center(
          child: Text('Exit Lumina??'),
        ),
        contentPadding: const EdgeInsets.only(
          top: 20,
          bottom: 20,
          left: 24,
          right: 24,
        ),
        content: const SizedBox(
          height: 20,
          child: Center(
            child: Text('Are you sure you want to exit?'),
          ),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            autofocus: true,
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Exit'),
          ),
        ],
      ),
    );
    return shouldPop ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final syncState = ref.watch(syncProvider);
    final syncStatus = ref.watch(syncStatusProvider);

    _updateCounts();

    final menuItems = [
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
        onSelect: () {
          if (syncState.hasError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Sync failed: ${syncState.error.toString()}',
                  style: const TextStyle(color: Colors.white),
                ),
                backgroundColor: Colors.red.shade900,
                duration: const Duration(seconds: 8),
                behavior: SnackBarBehavior.floating,
                margin: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            );
          } else {
            ref.read(syncProvider.notifier).sync();
          }
        },
      ),
      const MenuItem(
        icon: Icons.settings,
        label: 'Settings',
        destination: SettingsScreen(),
      ),
    ];

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        body: Stack(
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (syncState.isLoading && syncStatus != null)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(
                      left: 24,
                      right: 24,
                      top: 0,
                      bottom: 16,
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
                            '${syncStatus.split(':')[0]}:',
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
                Container(
                  margin: const EdgeInsets.only(bottom: 40),
                  child: _buildMainMenu(syncState),
                ),
              ],
            ),
            const Positioned(
              bottom: 61,
              left: 0,
              right: 0,
              child: RSSTicker(),
            ),
            _buildSettingsButton(menuItems),
            const Positioned(
              bottom: 20,
              left: 20,
              child: DigitalClock(),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateCounts() async {
    final db = ref.read(databaseServiceProvider);
    final movieCount = await db.getMovieCount();
    final tvShowCount = await db.getTVShowCount();
    
    if (mounted) {
      ref.read(movieCountProvider.notifier).set(movieCount);
      ref.read(tvShowCountProvider.notifier).set(tvShowCount);
    }
  }

  static const _syncMenuIndex = 3;
  static const _settingsIndex = 4;

  Widget _buildMainMenu(AsyncValue<void> syncState) {
    final menuItems = [
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
        onSelect: () {
          if (syncState.hasError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Sync failed: ${syncState.error.toString()}',
                  style: const TextStyle(color: Colors.white),
                ),
                backgroundColor: Colors.red.shade900,
                duration: const Duration(seconds: 8),
                behavior: SnackBarBehavior.floating,
                margin: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            );
          } else {
            ref.read(syncProvider.notifier).sync();
          }
        },
      ),
      const MenuItem(
        icon: Icons.settings,
        label: 'Settings',
        destination: SettingsScreen(),
      ),
    ];

    return SizedBox(
      height: 200,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          menuItems.length - 1,
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
                      menuItems[index].onSelect?.call();
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => menuItems[index].destination,
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
                      menuItems[index].onSelect?.call();
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => menuItems[index].destination,
                        ),
                      );
                    }
                  },
                  child: MainMenuItem(
                    item: menuItems[index],
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
  }

  final _settingsFocusNode = FocusNode();

  Widget _buildSettingsButton(List<MenuItem> menuItems) => Positioned(
        bottom: 1,
        right: 20,
        child: SizedBox(
          height: 36,
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
                      builder: (context) => menuItems[_settingsIndex].destination,
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
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                decoration: BoxDecoration(
                  color: _focusedIndex == _settingsIndex 
                      ? Colors.blue 
                      : Colors.black45,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: _focusedIndex == _settingsIndex 
                        ? Colors.white30 
                        : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: const Text(
                  'Settings',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
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
            if (!isSmall && (item.label == 'Movies' || item.label == 'TV Shows'))
              Consumer(
                builder: (context, ref, _) {
                  final count = item.label == 'Movies'
                      ? ref.watch(movieCountProvider)
                      : ref.watch(tvShowCountProvider);
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      count.toString(),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      );
}

class CountNotifier extends StateNotifier<int> {
  CountNotifier() : super(0);
  
  void increment() {
    state = state + 1;
  }
  void decrement() => state = state - 1;
  void set(int value) {
    state = value;
  }
}
