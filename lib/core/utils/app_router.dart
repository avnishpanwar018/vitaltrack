import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:shared_preferences/shared_preferences.dart';

import '../../screens/add_reading/add_reading_screen.dart';
import '../../screens/charts/charts_screen.dart';
import '../../screens/history/history_screen.dart';
import '../../screens/home/home_screen.dart';
import '../../screens/insights/insights_screen.dart';
import '../../screens/lock/lock_screen.dart';
import '../../screens/main_shell.dart';
import '../../screens/profiles/profiles_screen.dart';
import '../../screens/reports/reports_screen.dart';
import '../../screens/attachments/attachments_screen.dart';
import '../../screens/settings/about_screen.dart';
import '../../screens/settings/settings_screen.dart';
import '../../screens/statistics/statistics_screen.dart';

/// App route paths.
abstract class AppRoutes {
  static const home = '/';
  static const history = '/history';
  static const statistics = '/statistics';
  static const charts = '/charts';
  static const settings = '/settings';
  static const addReading = '/add-reading';
  static const editReading = '/edit-reading';
  static const reports = '/reports';
  static const insights = '/insights';
  static const profiles = '/profiles';
  static const lock = '/lock';
  static const about = '/about';
  static const attachments = '/attachments';
}

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

bool isAppUnlocked = false;

void lockApp() {
  isAppUnlocked = false;
  appRouter.go(AppRoutes.lock);
}

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: AppRoutes.home,
  redirect: (context, state) async {
    final location = state.uri.path;
    final isLockRoute = location == AppRoutes.lock;

    if (!isAppUnlocked) {
      final prefs = await SharedPreferences.getInstance();
      final pinEnabled = prefs.getBool('pin_enabled') ?? false;

      if (pinEnabled && !isLockRoute) {
        return AppRoutes.lock;
      }
    }
    return null;
  },
  routes: [
    GoRoute(
      path: AppRoutes.lock,
      builder: (context, state) => const LockScreen(),
    ),
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) => MainShell(child: child),
      routes: [
        GoRoute(
          path: AppRoutes.home,
          pageBuilder: (context, state) => const NoTransitionPage(
            child: HomeScreen(),
          ),
        ),
        GoRoute(
          path: AppRoutes.history,
          pageBuilder: (context, state) => const NoTransitionPage(
            child: HistoryScreen(),
          ),
        ),
        GoRoute(
          path: AppRoutes.statistics,
          pageBuilder: (context, state) => const NoTransitionPage(
            child: StatisticsScreen(),
          ),
        ),
        GoRoute(
          path: AppRoutes.charts,
          pageBuilder: (context, state) => const NoTransitionPage(
            child: ChartsScreen(),
          ),
        ),
        GoRoute(
          path: AppRoutes.settings,
          pageBuilder: (context, state) => const NoTransitionPage(
            child: SettingsScreen(),
          ),
        ),
      ],
    ),
    GoRoute(
      path: AppRoutes.addReading,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const AddReadingScreen(),
    ),
    GoRoute(
      path: '${AppRoutes.editReading}/:id',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => AddReadingScreen(
        readingId: state.pathParameters['id'],
      ),
    ),
    GoRoute(
      path: AppRoutes.reports,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const ReportsScreen(),
    ),
    GoRoute(
      path: AppRoutes.insights,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const InsightsScreen(),
    ),
    GoRoute(
      path: AppRoutes.profiles,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const ProfilesScreen(),
    ),
    GoRoute(
      path: AppRoutes.about,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const AboutScreen(),
    ),
    GoRoute(
      path: AppRoutes.attachments,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const AttachmentsScreen(),
    ),
  ],
);
