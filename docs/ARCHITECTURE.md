# Architecture

```
lib/
  app/        DI container (AppDependencies) + root widget
  core/       theme, router, auth gate, connectivity, shared UI kit
  domain/     models, Result/Failure, abstract repositories, in-memory fakes
  data/       remote (TheMealDB client), local (Drift), repositories, auth, sync, reminders
  features/   splash auth home search meal_list meal_details favorites planner profile options reminders sync
```

- Every screen exposes Loading / Data / Empty / Error (`ViewState` or an equivalent state class).
- Screens never touch Dio, Drift or Firebase; tests inject fakes (`domain/fakes`).
- Favorites and planned meals are scoped by user id; logout keeps them (D4).
- Planned days are stored as `yyyy-MM-dd` strings, never timestamps.

## Sync policy
Restore on login only if local favorites are empty; auto-backup (2 s debounce) after add/remove when online; queued and retried when connectivity returns; last write wins per meal; removals delete the cloud document; guests are rejected before any call.

## Reminders
WorkManager one-off task with `initialDelay` shows a notification (deferrable, not exact: Doze / battery optimisers may delay it). Tapping opens `/meal/<id>`.
