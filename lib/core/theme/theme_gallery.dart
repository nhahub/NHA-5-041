import 'package:flutter/material.dart';

import '../widgets/states.dart';
import 'app_theme.dart';

/// Debug-only gallery of design tokens and UI kit widgets (`/theme-gallery`).
class ThemeGalleryScreen extends StatelessWidget {
  const ThemeGalleryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final swatches = <(String, Color, Color)>[
      ('primary', scheme.primary, scheme.onPrimary),
      ('primaryContainer', scheme.primaryContainer, scheme.onPrimaryContainer),
      ('secondary', scheme.secondary, scheme.onSecondary),
      (
        'tertiaryContainer',
        scheme.tertiaryContainer,
        scheme.onTertiaryContainer,
      ),
      ('surface', scheme.surface, scheme.onSurface),
      (
        'surfaceContainerHighest',
        scheme.surfaceContainerHighest,
        scheme.onSurface,
      ),
      ('error', scheme.error, scheme.onError),
      ('errorContainer', scheme.errorContainer, scheme.onErrorContainer),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('Theme gallery')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text('Colors', style: theme.textTheme.titleLarge),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final s in swatches)
                Container(
                  width: 150,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: s.$2,
                    borderRadius: AppRadius.card,
                    border: Border.all(color: scheme.outlineVariant),
                  ),
                  child: Text(
                    s.$1,
                    style: theme.textTheme.labelMedium?.copyWith(color: s.$3),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Text('Text styles', style: theme.textTheme.titleLarge),
          Text('Headline medium', style: theme.textTheme.headlineMedium),
          Text('Title large', style: theme.textTheme.titleLarge),
          Text('Title medium', style: theme.textTheme.titleMedium),
          Text('Body large', style: theme.textTheme.bodyLarge),
          Text('Body medium', style: theme.textTheme.bodyMedium),
          Text('Label large', style: theme.textTheme.labelLarge),
          const SizedBox(height: AppSpacing.xl),
          Text('UI kit', style: theme.textTheme.titleLarge),
          const SizedBox(height: AppSpacing.sm),
          const SectionHeader('Section header'),
          AppSearchField(hint: 'Search field', onChanged: (_) {}),
          const SizedBox(height: AppSpacing.md),
          const OfflineBanner(),
          const SizedBox(height: AppSpacing.md),
          const Skeleton(height: 64, radius: AppRadius.md),
          SizedBox(
            height: 220,
            child: EmptyState(
              title: 'Empty state',
              message: 'Guidance goes here.',
              actionLabel: 'Action',
              onAction: () {},
            ),
          ),
          SizedBox(
            height: 220,
            child: ErrorState(message: 'Error state', onRetry: () {}),
          ),
          Row(
            children: [
              FilledButton(onPressed: () {}, child: const Text('Filled')),
              const SizedBox(width: AppSpacing.sm),
              OutlinedButton(onPressed: () {}, child: const Text('Outlined')),
            ],
          ),
        ],
      ),
    );
  }
}
