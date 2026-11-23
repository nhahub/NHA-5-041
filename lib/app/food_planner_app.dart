import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../core/auth/auth_cubit.dart';
import '../core/auth/logout_flow.dart';
import '../core/clock.dart';
import '../core/connectivity/connectivity_cubit.dart';
import '../core/prefs/preference_manager.dart';
import '../core/router/app_router.dart';
import '../core/router/routes.dart';
import '../core/theme/app_theme.dart';
import '../domain/repositories/repositories.dart';
import '../features/favorites/favorites_cubit.dart';
import '../features/profile/avatar_cubit.dart';
import '../features/reminders/reminder_cubit.dart';
import '../features/search/search_cubit.dart';
import '../features/sync/sync_cubit.dart';
import 'app_dependencies.dart';

class FoodPlannerApp extends StatefulWidget {
  const FoodPlannerApp({
    super.key,
    required this.deps,
    this.initialLocation = Routes.splash,
  });

  final AppDependencies deps;
  final String initialLocation;

  @override
  State<FoodPlannerApp> createState() => _FoodPlannerAppState();
}

class _FoodPlannerAppState extends State<FoodPlannerApp> {
  late final AuthCubit _auth = AuthCubit(widget.deps.auth);
  late final ConnectivityCubit _connectivity = ConnectivityCubit(
    widget.deps.connectivity,
  );
  late final GoRouter _router = AppRouter.create(
    _auth,
    initialLocation: widget.initialLocation,
    videoBuilder: widget.deps.videoBuilder,
  );

  @override
  void initState() {
    super.initState();
    _setUpNotificationTaps();
  }

  /// Notification tap opens `/meal/<id>` (warm start and cold start).
  Future<void> _setUpNotificationTaps() async {
    final helper = widget.deps.notifications;
    if (helper == null) return;
    await helper.init(onTap: _openPayload);
    final launch = await helper.launchPayload();
    if (launch != null) _openPayload(launch);
  }

  void _openPayload(String? payload) {
    if (payload == null || !payload.startsWith('/meal/')) return;
    void go() => _router.push(payload);
    if (_router.routerDelegate.currentConfiguration.uri.path != Routes.splash) {
      go();
      return;
    }
    // Cold start: wait until the splash has routed on.
    void listener() {
      if (_router.routerDelegate.currentConfiguration.uri.path !=
          Routes.splash) {
        _router.routerDelegate.removeListener(listener);
        go();
      }
    }

    _router.routerDelegate.addListener(listener);
  }

  @override
  void dispose() {
    _router.dispose();
    _auth.close();
    _connectivity.close();
    for (final d in widget.deps.disposables) {
      d();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.deps;
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<PreferenceManager>.value(value: d.prefManager),
        RepositoryProvider<Clock>.value(value: d.clock),
        RepositoryProvider<AuthRepository>.value(value: d.auth),
        RepositoryProvider<MealRepository>.value(value: d.meals),
        RepositoryProvider<FavoritesRepository>.value(value: d.favorites),
        RepositoryProvider<PlannerRepository>.value(value: d.planner),
        RepositoryProvider<SyncRepository>.value(value: d.sync),
        RepositoryProvider<ReminderService>.value(value: d.reminders),
        RepositoryProvider<NotificationPermission>.value(value: d.permission),
        RepositoryProvider<LogoutFlow>.value(value: d.logout),
        RepositoryProvider<AreaCatalog>.value(value: d.areaCatalog),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<AuthCubit>.value(value: _auth),
          BlocProvider<ConnectivityCubit>.value(value: _connectivity),
          BlocProvider(create: (_) => AvatarCubit(d.auth, d.avatarStore)),
          BlocProvider(create: (_) => FavoritesCubit(d.favorites, d.auth)),
          BlocProvider(
            create: (_) => SyncCubit(
              auth: d.auth,
              sync: d.sync,
              favorites: d.favorites,
              connectivity: _connectivity,
            ),
          ),
        ],
        child: MaterialApp.router(
          title: 'Food Planner',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(useGoogleFonts: d.useGoogleFonts),
          darkTheme: AppTheme.dark(useGoogleFonts: d.useGoogleFonts),
          routerConfig: _router,
        ),
      ),
    );
  }
}
