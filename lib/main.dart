import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'core/providers/providers.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/app_router.dart';
import 'core/utils/constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb && (Platform.isWindows || Platform.isLinux)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const ProviderScope(child: VitalTrackApp()));
}

class VitalTrackApp extends ConsumerStatefulWidget {
  const VitalTrackApp({super.key});

  @override
  ConsumerState<VitalTrackApp> createState() => _VitalTrackAppState();
}

class _VitalTrackAppState extends ConsumerState<VitalTrackApp>
    with WidgetsBindingObserver {
  bool _wasBackgrounded = false;
  bool _privacyCover = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_initializeApp());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.hidden) {
      _wasBackgrounded = true;
      isAppUnlocked = false;
      setState(() => _privacyCover = true);
    } else if (state == AppLifecycleState.resumed && _wasBackgrounded) {
      _wasBackgrounded = false;
      unawaited(_relockAfterResume());
    }
  }

  Future<void> _initializeApp() async {
    final homeWidget = ref.read(homeWidgetServiceProvider);
    final profileRepo = ref.read(profileRepositoryProvider);
    try {
      await homeWidget.initialize();
    } catch (_) {
      // Home widgets are optional and unsupported on some platforms.
    }
    try {
      await profileRepo.ensureDefaultProfile();
    } catch (_) {
      // Profile loading errors are surfaced by the profile provider in the UI.
    }
  }

  Future<void> _relockAfterResume() async {
    if (!mounted) return;
    try {
      final settings = await ref.read(settingsServiceProvider.future);
      if (!mounted) return;
      if (settings.pinEnabled) lockApp();
    } catch (_) {
      // Fail closed if security preferences cannot be read.
      lockApp();
    }
    // Keep the cover until the router has replaced any protected route.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_wasBackgrounded) {
        setState(() => _privacyCover = false);
      }
    });
  }

  ThemeMode _resolveThemeMode(String mode) {
    switch (mode) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _resolveThemeMode(themeMode),
      routerConfig: appRouter,
      builder: (context, child) => Stack(
        fit: StackFit.expand,
        children: [
          if (child != null) child,
          if (_privacyCover)
            const Positioned.fill(
              child: ColoredBox(
                color: Colors.black,
                child: Center(child: Icon(Icons.lock_outline, color: Colors.white)),
              ),
            ),
        ],
      ),
    );
  }
}
