import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/auth_cubit.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/models/user_and_plan.dart';
import '../../profile/user_avatar.dart';

/// Header section showing user greeting and avatar.
class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, auth) {
        final name = auth.user?.displayName ?? '';
        final greeting = name.isEmpty
            ? 'Hello, chef!'
            : 'Hello, ${name.split(' ').first}!';
        return Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            0,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(greeting, style: theme.textTheme.headlineSmall),
                    Text(
                      'What shall we cook today?',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              UserAvatar(radius: 24, onTap: () => context.go(Routes.profile)),
            ],
          ),
        );
      },
    );
  }
}
