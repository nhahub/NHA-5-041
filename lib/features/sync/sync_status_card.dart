import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/router/routes.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/repositories/repositories.dart';
import 'sync_cubit.dart';

/// Idle / syncing / last synced / error with Retry / guest variants.
class SyncStatusCard extends StatelessWidget {
  const SyncStatusCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BlocBuilder<SyncCubit, SyncUiState>(
      builder: (context, s) {
        if (s.guest) {
          return Card(
            child: ListTile(
              contentPadding: const EdgeInsetsDirectional.all(AppSpacing.lg),
              leading: const Icon(Icons.cloud_off_outlined),
              title: const Text('Sign in to back up your favorites'),
              subtitle: const Text('Guests keep nothing in the cloud.'),
              trailing: TextButton(
                onPressed: () => context.push(Routes.login),
                child: const Text('Sign in'),
              ),
            ),
          );
        }
        final (
          IconData icon,
          String title,
          String? subtitle,
        ) = switch (s.phase) {
          SyncPhase.syncing => (Icons.sync, 'Backing up…', null),
          SyncPhase.restoring => (
            Icons.cloud_download_outlined,
            'Restoring your favorites…',
            null,
          ),
          SyncPhase.error => (Icons.error_outline, 'Sync failed', s.message),
          SyncPhase.idle => (
            s.pending ? Icons.cloud_queue : Icons.cloud_done_outlined,
            s.pending ? 'Waiting for connection' : 'Favorites backup',
            s.pending
                ? 'Your changes will sync when you are online.'
                : s.lastSyncedAt == null
                ? 'Not synced yet'
                : 'Last synced ${DateFormat('d MMM, HH:mm').format(s.lastSyncedAt!)}',
          ),
        };
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                s.busy
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        icon,
                        color: s.phase == SyncPhase.error
                            ? theme.colorScheme.error
                            : null,
                      ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: theme.textTheme.titleSmall),
                      if (subtitle != null)
                        Text(
                          subtitle,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: s.busy
                      ? null
                      : () => context.read<SyncCubit>().syncNow(),
                  child: Text(
                    s.phase == SyncPhase.error ? 'Retry' : 'Sync now',
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
