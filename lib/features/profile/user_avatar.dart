import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'avatar_cubit.dart';

/// The current user's avatar: gallery photo when set, default icon otherwise.
class UserAvatar extends StatelessWidget {
  const UserAvatar({super.key, this.radius = 24, this.onTap});

  final double radius;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return BlocBuilder<AvatarCubit, String?>(
      builder: (context, path) {
        final avatar = CircleAvatar(
          radius: radius,
          backgroundColor: scheme.primaryContainer,
          foregroundImage: path == null ? null : FileImage(File(path)),
          child: Icon(
            Icons.person,
            size: radius,
            color: scheme.onPrimaryContainer,
          ),
        );
        return Semantics(
          label: 'Profile picture',
          button: onTap != null,
          child: onTap == null
              ? avatar
              : InkResponse(onTap: onTap, radius: radius + 8, child: avatar),
        );
      },
    );
  }
}
