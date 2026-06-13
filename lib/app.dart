// app.dart
// app.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/theme/app_theme.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_text_styles.dart';

// ── Screen imports (stubs until each phase is built) ──
// Phase 2 — Dashboard
import 'features/dashboard/dashboard_screen.dart';
// Phase 3 — Farmers
import 'features/farmers/farmers_screen.dart';
import 'features/farmers/farmer_detail_screen.dart';
// Phase 4 — Add Farmer
import 'features/farmers/add_farmer_screen.dart';
// Phase 5 — Crops
import 'features/crops/crops_screen.dart';
import 'features/crops/add_season_screen.dart';
import 'features/crops/add_event_screen.dart';
// Phase 6 — Plots
import 'features/plots/plots_screen.dart';
import 'features/plots/add_plot_screen.dart';
// Phase 7 — Carbon
import 'features/carbon/carbon_screen.dart';
import 'features/carbon/add_emission_screen.dart';

// ── Router ─────────────────────────────────────────────
final _router = GoRouter(
  initialLocation: '/',
  routes: [
    // Nav shell wraps all bottom-nav tabs
    ShellRoute(
      builder: (context, state, child) => NavShell(child: child),
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const DashboardScreen(),
        ),
        GoRoute(
          path: '/farmers',
          builder: (context, state) => const FarmersScreen(),
          routes: [
            GoRoute(
              path: ':id',
              builder: (context, state) => FarmerDetailScreen(
                farmerId: state.pathParameters['id']!,
              ),
            ),
          ],
        ),
        GoRoute(
          path: '/crops',
          builder: (context, state) => const CropsScreen(),
        ),
        GoRoute(
          path: '/plots',
          builder: (context, state) => const PlotsScreen(),
        ),
        GoRoute(
          path: '/carbon',
          builder: (context, state) => const CarbonScreen(),
        ),
      ],
    ),

    // Modal screens (outside shell — no bottom nav)
    GoRoute(
      path: '/add-farmer',
      builder: (context, state) => const AddFarmerScreen(),
    ),
    GoRoute(
      path: '/add-season',
      builder: (context, state) => AddSeasonScreen(
        farmerId: state.uri.queryParameters['farmerId'],
      ),
    ),
    GoRoute(
      path: '/add-event',
      builder: (context, state) => AddEventScreen(
        seasonId: state.uri.queryParameters['seasonId']!,
      ),
    ),
    GoRoute(
      path: '/add-plot',
      builder: (context, state) => AddPlotScreen(
        farmerId: state.uri.queryParameters['farmerId'],
      ),
    ),
    GoRoute(
      path: '/add-emission',
      builder: (context, state) => AddEmissionScreen(
        seasonId: state.uri.queryParameters['seasonId'],
      ),
    ),
  ],
);

// ── Root app widget ────────────────────────────────────
class AgriTrackApp extends ConsumerWidget {
  const AgriTrackApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'AgriTrack',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: _router,
    );
  }
}

// ── Navigation Shell ───────────────────────────────────
class NavShell extends StatelessWidget {
  const NavShell({super.key, required this.child});

  final Widget child;

  // Map route path → bottom nav index
  static const _tabs = ['/', '/farmers', '/crops', '/plots', '/carbon'];

  int _indexFromLocation(String location) {
    // Match on prefix so nested routes keep the right tab highlighted
    for (int i = _tabs.length - 1; i >= 0; i--) {
      if (location.startsWith(_tabs[i])) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final currentIndex = _indexFromLocation(location);

    return Scaffold(
      // ── AppBar ────────────────────────────────────
      appBar: AppBar(
        title: Row(
          children: [
            // Logo mark
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(
                Icons.grass,
                size: 16,
                color: AppColors.textOnPrimary,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'AgriTrack',
              style: AppTextStyles.h2.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        actions: [
          // Sync status icon — will be driven by connectivityProvider later
          IconButton(
            onPressed: () {
              // TODO Phase 9: show sync status sheet
            },
            icon: const Icon(Icons.cloud_done_outlined),
            tooltip: 'Sync status',
          ),
          // Avatar / profile
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () {
                // TODO Phase 8: navigate to profile / logout
              },
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.successBg,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.border,
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    'A', // TODO: replace with user initials from authProvider
                    style: AppTextStyles.labelLarge.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),

      // ── Body ──────────────────────────────────────
      body: child,

      // ── Bottom Navigation Bar ──────────────────────
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (i) => context.go(_tabs[i]),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            activeIcon: Icon(Icons.people),
            label: 'Farmers',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.grass_outlined),
            activeIcon: Icon(Icons.grass),
            label: 'Crops',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map_outlined),
            activeIcon: Icon(Icons.map),
            label: 'Plots',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.eco_outlined),
            activeIcon: Icon(Icons.eco),
            label: 'Carbon',
          ),
        ],
      ),
    );
  }
}