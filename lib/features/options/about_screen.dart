import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../core/theme/app_theme.dart';

const _developers = <(String, String)>[
  ('Mohamed', 'Tech Lead, Setup & Release'),
  ('Amr', 'Discovery & QA'),
  ('Youssef', 'Home, UI Kit & Planner'),
  ('Abd Alrahman', 'Identity, Details & Reminders'),
  ('Mina', 'API & Data'),
];

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key, this.versionLoader = PackageInfo.fromPlatform});

  /// Replaced in tests.
  final Future<PackageInfo> Function() versionLoader;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Center(
            child: Icon(
              Icons.restaurant_menu,
              size: 64,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Center(
            child: Text('Food Planner', style: theme.textTheme.headlineMedium),
          ),
          Center(
            child: FutureBuilder<PackageInfo>(
              future: versionLoader(),
              builder: (context, snap) => Text(
                snap.hasData
                    ? 'Version ${snap.data!.version} (${snap.data!.buildNumber})'
                    : 'Version …',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text('About the app', style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          const Text(
            'Food Planner helps you discover recipes from around the world, save your favorites, '
            'back them up to the cloud and plan your week with reminders. Guests can browse '
            'everything; favorites, planning and backup need an account.',
          ),
          const SizedBox(height: AppSpacing.xl),
          Text('Developers', style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          Card(
            child: Column(
              children: [
                for (var i = 0; i < _developers.length; i++) ...[
                  if (i > 0) const Divider(height: 1),
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: theme.colorScheme.primaryContainer,
                      child: Text(
                        _developers[i].$1[0],
                        style: TextStyle(
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                    title: Text(_developers[i].$1),
                    subtitle: Text(_developers[i].$2),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text('Credits', style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          const Text(
            '• Recipe data: TheMealDB (themealdb.com). The free test key is for development '
            'and education; a public store release needs a supporter key.\n'
            '• Splash animation: original Lottie animation created for this project.',
          ),
        ],
      ),
    );
  }
}
