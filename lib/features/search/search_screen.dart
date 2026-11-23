import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/routes.dart';
import '../../core/theme/app_theme.dart';
import '../../core/view_state.dart';
import '../../core/widgets/states.dart';
import '../../domain/repositories/repositories.dart';
import '../meal_list/meal_list_cubit.dart';
import 'search_cubit.dart';

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key, this.areaCatalog});

  /// Override in tests.
  final AreaCatalog? areaCatalog;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (ctx) => SearchCubit(
      ctx.read<MealRepository>(),
      areaCatalog ?? AssetAreaCatalog(),
    )..load(SearchMode.categories),
    child: const _SearchView(),
  );
}

class _SearchView extends StatefulWidget {
  const _SearchView();

  @override
  State<_SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<_SearchView> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  static int columnsFor(SearchMode m) => m == SearchMode.categories ? 2 : 3;

  String get _hint => switch (context.read<SearchCubit>().state.mode) {
    SearchMode.categories => 'Search categories',
    SearchMode.countries => 'Search countries',
    SearchMode.ingredients => 'Search ingredients',
  };

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SearchCubit, SearchState>(
      // Restore the typed text when the mode changes.
      listenWhen: (a, b) => a.mode != b.mode,
      listener: (context, state) => _controller.text = state.query,
      builder: (context, state) {
        final cubit = context.read<SearchCubit>();
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                0,
              ),
              child: SizedBox(
                width: double.infinity,
                child: SegmentedButton<SearchMode>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(
                      value: SearchMode.categories,
                      label: Text('Categories'),
                    ),
                    ButtonSegment(
                      value: SearchMode.countries,
                      label: Text('Countries'),
                    ),
                    ButtonSegment(
                      value: SearchMode.ingredients,
                      label: Text('Ingredients'),
                    ),
                  ],
                  selected: {state.mode},
                  onSelectionChanged: (s) => cubit.setMode(s.first),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: AppSearchField(
                controller: _controller,
                hint: _hint,
                onChanged: cubit.setQuery,
              ),
            ),
            Expanded(child: _Body(state: state)),
          ],
        );
      },
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.state});

  final SearchState state;

  String _type(SearchMode m) => switch (m) {
    SearchMode.categories => MealListType.category.name,
    SearchMode.countries => MealListType.area.name,
    SearchMode.ingredients => MealListType.ingredient.name,
  };

  @override
  Widget build(BuildContext context) {
    final columns = _SearchViewState.columnsFor(state.mode);
    final cubit = context.read<SearchCubit>();
    return switch (state.current) {
      ViewLoading() => GridSkeleton(columns: columns),
      ViewEmpty() => EmptyState(
        title: 'Nothing here yet',
        message: 'There is nothing to search in this section.',
        actionLabel: 'Reload',
        onAction: () => cubit.load(state.mode, force: true),
      ),
      ViewError(:final failure) => ErrorState(
        message: failure.message,
        onRetry: () => cubit.load(state.mode, force: true),
      ),
      ViewData() => () {
        final items = state.visible;
        if (items.isEmpty) {
          return EmptyState(
            title: 'No results',
            message: 'Nothing matches "${state.query.trim()}".',
          );
        }
        return GridView.builder(
          key: PageStorageKey('search-grid-${state.mode.name}'),
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.xl,
          ),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: AppSpacing.md,
            mainAxisSpacing: AppSpacing.md,
            childAspectRatio: state.mode == SearchMode.categories ? 1.25 : 0.95,
          ),
          itemCount: items.length,
          itemBuilder: (context, i) {
            final item = items[i];
            return _SearchTile(
              item: item,
              mode: state.mode,
              onTap: () =>
                  context.push(Routes.mealsPath(_type(state.mode), item.name)),
            );
          },
        );
      }(),
    };
  }
}

class _SearchTile extends StatelessWidget {
  const _SearchTile({
    required this.item,
    required this.mode,
    required this.onTap,
  });

  final SearchItem item;
  final SearchMode mode;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Widget visual = switch (mode) {
      SearchMode.countries =>
        item.flag != null
            ? FittedBox(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Text(item.flag!, style: const TextStyle(fontSize: 40)),
                ),
              )
            : Icon(Icons.public, size: 40, color: theme.colorScheme.primary),
      SearchMode.categories => AppNetworkImage(
        item.imageUrl,
        fit: BoxFit.contain,
        cacheWidth: 400,
      ),
      SearchMode.ingredients => Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: AppNetworkImage(
          item.imageUrl,
          fit: BoxFit.contain,
          cacheWidth: 200,
          fallbackIcon: Icons.eco,
        ),
      ),
    };
    return Semantics(
      button: true,
      label: item.name,
      child: Card(
        child: InkWell(
          onTap: onTap,
          child: Column(
            children: [
              Expanded(child: Center(child: visual)),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.sm,
                  0,
                  AppSpacing.sm,
                  AppSpacing.sm,
                ),
                child: Text(
                  item.name,
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelLarge,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
