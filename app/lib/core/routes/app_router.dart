import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:family_health/core/providers/auth_provider.dart';
import 'package:family_health/pages/home/home_page.dart';
import 'package:family_health/pages/records/records_page.dart';
import 'package:family_health/pages/charts/charts_page.dart';
import 'package:family_health/pages/devices/devices_page.dart';
import 'package:family_health/pages/settings/settings_page.dart';
import 'package:family_health/pages/splash/splash_page.dart';
import 'package:family_health/pages/auth/login_page.dart';
import 'package:family_health/pages/auth/register_page.dart';
import 'package:family_health/pages/auth/qr_login_page.dart';
import 'package:family_health/pages/records/vitals_record_page.dart';
import 'package:family_health/pages/records/sleep_record_page.dart';
import 'package:family_health/pages/records/smoking_record_page.dart';
import 'package:family_health/pages/records/drinking_record_page.dart';
import 'package:family_health/pages/records/work_posture_record_page.dart';
import 'package:family_health/pages/records/diet_record_page.dart';
import 'package:family_health/pages/records/sugar_record_page.dart';
import 'package:family_health/pages/records/food_detail_record_page.dart';
import 'package:family_health/pages/records/environment_record_page.dart';

// Forward-declared page builders — actual pages go here when created.
// These typedefs allow the router to compile standalone.
typedef PageBuilder = Widget Function(BuildContext, GoRouterState);
typedef ParamPageBuilder = Widget Function(BuildContext, GoRouterState, int);

/// Page registrations — swap these out when real pages exist.
///
/// Usage example for the Flutter standard pattern (alternative to inline builders):
/// Instead of referencing page classes directly in route definitions,
/// register them here and the router uses the registered builder.
class PageRegistry {
  static PageBuilder splash = (_, _) => const SplashPage();
  static PageBuilder login = (_, _) => const LoginPage();
  static PageBuilder register = (_, _) => const RegisterPage();
  static PageBuilder records = (_, _) => const RecordsPage();
  static PageBuilder charts = (_, _) => const ChartsPage();
  static PageBuilder devices = (_, _) => const DevicesPage();
  static PageBuilder settings = (_, _) => const SettingsPage();
  static ParamPageBuilder profileDetail = (_, _, pid) =>
      _PlaceholderPage(title: 'Profile #$pid');
  static ParamPageBuilder sleepRecord = (_, _, pid) =>
      SleepRecordPage(pid: pid);
  static ParamPageBuilder smokingRecord = (_, _, pid) =>
      SmokingRecordPage(pid: pid);
  static ParamPageBuilder drinkingRecord = (_, _, pid) =>
      DrinkingRecordPage(pid: pid);
  static ParamPageBuilder workPostureRecord = (_, _, pid) =>
      WorkPostureRecordPage(pid: pid);
  static ParamPageBuilder dietRecord = (_, _, pid) =>
      DietRecordPage(pid: pid);
  static ParamPageBuilder sugarRecord = (_, _, pid) =>
      SugarRecordPage(pid: pid);
  static ParamPageBuilder foodDetailRecord = (_, _, pid) =>
      FoodDetailRecordPage(pid: pid);
  static ParamPageBuilder environmentRecord = (_, _, pid) =>
      EnvironmentRecordPage(pid: pid);
  static ParamPageBuilder vitalsRecord = (_, _, pid) =>
      VitalsRecordPage(pid: pid);
}

/// Placeholder that is replaced once real page widgets are written.
class _PlaceholderPage extends StatelessWidget {
  final String title;
  const _PlaceholderPage({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Text(
          '🚧 $title\n\nReplace this with the real page widget\nin lib/pages/...',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
    );
  }
}

/// The GoRouter instance. Must be passed to the app's MaterialApp.router.
final goRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/splash',
    debugLogDiagnostics: true,

    // ── Auth redirect guard ──
    redirect: (context, state) {
      final isAuthenticated = authState is AuthAuthenticated;
      final isAuthRoute = state.matchedLocation.startsWith('/auth');
      final isSplash = state.matchedLocation == '/splash';

      // Allow splash page to render first
      if (isSplash) return null;

      // If not authenticated, redirect to login (except auth routes & splash)
      if (!isAuthenticated && !isAuthRoute) {
        return '/auth/login';
      }

      // If authenticated and on auth route, redirect to home
      if (isAuthenticated && isAuthRoute) {
        return '/home';
      }

      return null;
    },

    // ── Routes ──
    routes: [
      // Splash
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => PageRegistry.splash(context, state),
      ),

      // Auth routes
      GoRoute(
        path: '/auth/login',
        name: 'login',
        builder: (context, state) => PageRegistry.login(context, state),
      ),
      GoRoute(
        path: '/auth/register',
        name: 'register',
        builder: (context, state) => PageRegistry.register(context, state),
      ),
      GoRoute(
        path: '/auth/qr-login',
        name: 'qrLogin',
        builder: (context, state) => const QRLoginPage(),
      ),

      // Authenticated shell route with bottom navigation
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return _HomeShell(navigationShell: navigationShell);
        },
        branches: [
          // Tab 0: Records
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                name: 'home',
                builder: (context, state) => PageRegistry.records(context, state),
              ),
            ],
          ),

          // Tab 1: Charts
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home/charts',
                name: 'charts',
                builder: (context, state) => PageRegistry.charts(context, state),
              ),
            ],
          ),

          // Tab 2: Devices
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home/devices',
                name: 'devices',
                builder: (context, state) => PageRegistry.devices(context, state),
              ),
            ],
          ),

          // Tab 3: Settings
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home/settings',
                name: 'settings',
                builder: (context, state) => PageRegistry.settings(context, state),
              ),
            ],
          ),
        ],
      ),

      // Profile detail (with parameter)
      GoRoute(
        path: '/profile/:pid',
        name: 'profileDetail',
        builder: (context, state) {
          final pid = int.parse(state.pathParameters['pid']!);
          return PageRegistry.profileDetail(context, state, pid);
        },
      ),

      // Record creation routes
      GoRoute(
        path: '/record/sleep/:pid',
        name: 'sleepRecord',
        builder: (context, state) {
          final pid = int.parse(state.pathParameters['pid']!);
          return PageRegistry.sleepRecord(context, state, pid);
        },
      ),
      GoRoute(
        path: '/record/smoking/:pid',
        name: 'smokingRecord',
        builder: (context, state) {
          final pid = int.parse(state.pathParameters['pid']!);
          return PageRegistry.smokingRecord(context, state, pid);
        },
      ),
      GoRoute(
        path: '/record/drinking/:pid',
        name: 'drinkingRecord',
        builder: (context, state) {
          final pid = int.parse(state.pathParameters['pid']!);
          return PageRegistry.drinkingRecord(context, state, pid);
        },
      ),
      GoRoute(
        path: '/record/work_posture/:pid',
        name: 'workPostureRecord',
        builder: (context, state) {
          final pid = int.parse(state.pathParameters['pid']!);
          return PageRegistry.workPostureRecord(context, state, pid);
        },
      ),
      GoRoute(
        path: '/record/diet/:pid',
        name: 'dietRecord',
        builder: (context, state) {
          final pid = int.parse(state.pathParameters['pid']!);
          return PageRegistry.dietRecord(context, state, pid);
        },
      ),
      GoRoute(
        path: '/record/sugar/:pid',
        name: 'sugarRecord',
        builder: (context, state) {
          final pid = int.parse(state.pathParameters['pid']!);
          return PageRegistry.sugarRecord(context, state, pid);
        },
      ),
      GoRoute(
        path: '/record/food_detail/:pid',
        name: 'foodDetailRecord',
        builder: (context, state) {
          final pid = int.parse(state.pathParameters['pid']!);
          return PageRegistry.foodDetailRecord(context, state, pid);
        },
      ),
      GoRoute(
        path: '/record/environment/:pid',
        name: 'environmentRecord',
        builder: (context, state) {
          final pid = int.parse(state.pathParameters['pid']!);
          return PageRegistry.environmentRecord(context, state, pid);
        },
      ),
      GoRoute(
        path: '/record/vitals/:pid',
        name: 'vitalsRecord',
        builder: (context, state) {
          final pid = int.parse(state.pathParameters['pid']!);
          return PageRegistry.vitalsRecord(context, state, pid);
        },
      ),
    ],

    // ── Error page ──
    errorBuilder: (context, state) {
      return Scaffold(
        appBar: AppBar(title: const Text('Page Not Found')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Page not found: ${state.uri}',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.go('/home'),
                child: const Text('Go Home'),
              ),
            ],
          ),
        ),
      );
    },
  );
});

/// Home shell widget with bottom navigation bar.
class _HomeShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  const _HomeShell({required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) {
          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.assignment_outlined),
            selectedIcon: Icon(Icons.assignment),
            label: 'Records',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Charts',
          ),
          NavigationDestination(
            icon: Icon(Icons.bluetooth_outlined),
            selectedIcon: Icon(Icons.bluetooth),
            label: 'Devices',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
