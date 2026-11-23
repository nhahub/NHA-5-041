import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/prefs/preference_manager.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/states.dart';
import '../../domain/repositories/repositories.dart';
import 'home_cubits.dart';
import 'widgets/browse_recipes_section.dart';
import 'widgets/category_row_section.dart';
import 'widgets/home_header.dart';
import 'widgets/meal_of_the_day_section.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (ctx) => CategoriesCubit(ctx.read<MealRepository>())..load(),
        ),
        BlocProvider(
          create: (ctx) => MealOfDayCubit(
            ctx.read<MealRepository>(),
            ctx.read<PreferenceManager>(),
          )..load(),
        ),
        BlocProvider(
          create: (ctx) =>
              BrowseFeedCubit(ctx.read<MealRepository>())..loadMore(),
        ),
      ],
      child: const _HomeView(),
    );
  }
}

class _HomeView extends StatefulWidget {
  const _HomeView();

  @override
  State<_HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<_HomeView> {
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.position.extentAfter < 600) {
        context.read<BrowseFeedCubit>().loadMore();
      }
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    await Future.wait([
      context.read<CategoriesCubit>().load(),
      context.read<MealOfDayCubit>().load(force: true),
      context.read<BrowseFeedCubit>().refresh(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refresh,
      child: CustomScrollView(
        key: const PageStorageKey('home-scroll'),
        controller: _scroll,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: const [
          SliverToBoxAdapter(child: HomeHeader()),
          SliverToBoxAdapter(child: MealOfTheDaySection()),
          SliverToBoxAdapter(child: SectionHeader('Categories')),
          SliverToBoxAdapter(child: CategoryRowSection()),
          SliverToBoxAdapter(child: SectionHeader('Browse recipes')),
          BrowseRecipesSection(),
          SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),
        ],
      ),
    );
  }
}
