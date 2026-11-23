import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_cubit.dart';
import '../../core/router/routes.dart';
import '../profile/profile_screen.dart';

enum _Option { about, logout, signIn }

/// Overflow menu in the main app bar: About and Logout.
class OptionsMenu extends StatelessWidget {
  const OptionsMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final guest = context.watch<AuthCubit>().isGuest;
    return PopupMenuButton<_Option>(
      tooltip: 'More options',
      icon: const Icon(Icons.more_vert),
      onSelected: (option) {
        switch (option) {
          case _Option.about:
            context.push(Routes.about);
          case _Option.logout:
            performLogout(context);
          case _Option.signIn:
            context.push(Routes.login);
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(value: _Option.about, child: Text('About')),
        if (guest)
          const PopupMenuItem(value: _Option.signIn, child: Text('Sign in'))
        else
          const PopupMenuItem(value: _Option.logout, child: Text('Logout')),
      ],
    );
  }
}
