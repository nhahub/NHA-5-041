import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../router/routes.dart';
import 'auth_cubit.dart';

/// Guest gate. Returns `true` when the user is signed in. For guests it shows
/// a Sign in / Cancel dialog and returns `false`; choosing "Sign in" opens the
/// login screen, which pops back to the previous screen on success.
Future<bool> requireAuth(BuildContext context, {required String reason}) async {
  final auth = context.read<AuthCubit>();
  if (auth.isSignedIn) return true;

  final signIn = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      icon: const Icon(Icons.lock_outline),
      title: const Text('Sign in required'),
      content: Text(reason),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size(96, 48)),
          onPressed: () => Navigator.of(ctx).pop(true),
          child: const Text('Sign in'),
        ),
      ],
    ),
  );
  if (signIn == true && context.mounted) {
    context.push(Routes.login);
  }
  return false;
}
