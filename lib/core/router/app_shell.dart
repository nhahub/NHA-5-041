import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../features/options/options_menu.dart';
import '../connectivity/connectivity_cubit.dart';
import '../widgets/states.dart';

/// The 5-tab shell: Home, Search, Calendar, Favorites, Profile. Each tab keeps
/// its state. The options menu and the offline banner live here.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  static const _titles = [
    'Food Planner',
    'Search',
    'Calendar',
    'Favorites',
    'Profile',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[shell.currentIndex]),
        actions: const [OptionsMenu()],
      ),
      body: Column(
        children: [
          BlocBuilder<ConnectivityCubit, ConnectionStatus>(
            builder: (context, status) => AnimatedSize(
              duration: const Duration(milliseconds: 200),
              child: status == ConnectionStatus.offline
                  ? const OfflineBanner()
                  : const SizedBox(width: double.infinity),
            ),
          ),
          Expanded(child: shell),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: shell.currentIndex,
        onDestinationSelected: (i) =>
            shell.goBranch(i, initialLocation: i == shell.currentIndex),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(icon: Icon(Icons.search), label: 'Search'),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'Calendar',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_outline),
            selectedIcon: Icon(Icons.favorite),
            label: 'Favorites',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
