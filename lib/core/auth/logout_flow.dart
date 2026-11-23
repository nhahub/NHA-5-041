import 'package:flutter/material.dart';

import '../../domain/repositories/repositories.dart';

/// Signs the user out. Local favorites are KEPT (decision D4): they are scoped
/// by user id and hidden once signed out. A last backup is attempted but never
/// blocks the logout.
class LogoutFlow {
  const LogoutFlow({required this.auth, required this.sync});

  final AuthRepository auth;
  final SyncRepository sync;

  Future<void> call() async {
    final uid = auth.currentState.uid;
    if (uid != null) {
      try {
        await sync.backup(uid).timeout(const Duration(seconds: 4));
      } catch (_) {
        // Never block logout on backup.
      }
    }
    await auth.signOut();
  }
}

/// Yes / No dialog. Returns `true` when the user confirms.
Future<bool> confirmLogout(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Log out?'),
      content: const Text(
        'Your favorites stay on this phone and come back when you sign in again.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('No'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size(96, 48)),
          onPressed: () => Navigator.of(ctx).pop(true),
          child: const Text('Yes'),
        ),
      ],
    ),
  );
  return result ?? false;
}
