import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_constants.dart';
import 'di/dependency_injection.dart';
import 'features/artifact/presentation/providers/artifact_provider.dart';
import 'features/artifact/presentation/widgets/artifact_portal_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Hive
  await initializeHive();
  
  // Set fixed window size for desktop
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    await windowManager.ensureInitialized();
    await windowManager.setSize(const Size(1280, 900));
    await windowManager.setResizable(false);
    await windowManager.setTitle(AppConstants.appName);
  }
  
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });
  }

  Future<void> _initializeData() async {
    try {
      // Initialize sample data
      final dataSource = ref.read(artifactLocalDataSourceProvider);
      await dataSource.initializeSampleData();
      print('Sample data initialized successfully');
      
      // Trigger refresh of artifacts
      ref.read(refreshTriggerProvider.notifier).state++;
    } catch (e) {
      print('Error initializing sample data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppTheme.appBackgroundGradient,
      ),
      child: MaterialApp(
        title: AppConstants.appName,
        theme: AppTheme.darkTheme.copyWith(
          scaffoldBackgroundColor: Colors.transparent,
        ),
        home: const ArtifactPortalScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
