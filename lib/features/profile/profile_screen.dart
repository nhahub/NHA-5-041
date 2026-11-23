import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_cubit.dart';
import '../../core/auth/logout_flow.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/models/user_and_plan.dart';
import '../sync/sync_status_card.dart';
import 'avatar_cubit.dart';
import 'user_avatar.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, auth) {
        final guest = auth.isGuest;
        final name = guest
            ? 'Guest'
            : (auth.user?.displayName.isNotEmpty ?? false)
            ? auth.user!.displayName
            : 'Chef';
        final email = auth.user?.email ?? '';
        return ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            const SizedBox(height: AppSpacing.md),
            Center(
              child: Stack(
                children: [
                  UserAvatar(
                    radius: 52,
                    onTap: guest ? null : () => _changePhoto(context),
                  ),
                  if (!guest)
                    PositionedDirectional(
                      end: 0,
                      bottom: 0,
                      child: Semantics(
                        button: true,
                        label: 'Change profile photo',
                        child: IconButton.filled(
                          constraints: const BoxConstraints(
                            minWidth: AppSpacing.minTarget,
                            minHeight: AppSpacing.minTarget,
                          ),
                          onPressed: () => _changePhoto(context),
                          icon: const Icon(Icons.photo_camera_outlined),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Center(child: Text(name, style: theme.textTheme.headlineSmall)),
            if (!guest && email.isNotEmpty)
              Center(
                child: Text(
                  email,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            if (guest) ...[
              const SizedBox(height: AppSpacing.md),
              Center(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(200, AppSpacing.minTarget),
                  ),
                  onPressed: () => context.push(Routes.login),
                  icon: const Icon(Icons.login),
                  label: const Text('Sign in'),
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.xl),
            const SyncStatusCard(),
            const SizedBox(height: AppSpacing.lg),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.favorite_outline),
                    title: const Text('Favorite Meals'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.go(Routes.favorites),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.calendar_month_outlined),
                    title: const Text('Planned Meals'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.go(Routes.calendar),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: Icon(
                      guest ? Icons.login : Icons.logout,
                      color: theme.colorScheme.error,
                    ),
                    title: Text(
                      guest ? 'Leave guest mode' : 'Logout',
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                    onTap: () => performLogout(context),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _changePhoto(BuildContext context) async {
    final avatar = context.read<AvatarCubit>();
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheet) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () {
                Navigator.of(sheet).pop();
                avatar.pick();
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('Use default picture'),
              onTap: () {
                Navigator.of(sheet).pop();
                avatar.reset();
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Shared by Profile and the Options menu: confirm, then run the logout flow.
Future<void> performLogout(BuildContext context) async {
  final flow = context.read<LogoutFlow>();
  if (await confirmLogout(context)) await flow();
}
