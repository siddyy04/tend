# SPRINT 1A IMPLEMENTATION SPECIFICATION
### Target: AI coding agent (Cursor). Read fully before writing any code.

You are implementing **Sprint 1A only** of the Tend Flutter app. Reference documents already in this repository: `ARCHITECTURE.md` (binding architecture decisions), `FEATURES.md` (scope), `SCHEMA.md` (data model), `DEVELOPMENT_ROADMAP.md` (sprint sequence), `SPRINT0.md` (prior sprint, already implemented). This specification is the authoritative scope for this task. If anything here appears to conflict with those documents, stop and ask rather than guessing which one wins. Every architecture decision in `ARCHITECTURE.md` and every schema definition in `SCHEMA.md` carries forward unchanged — this sprint implements against them, it does not revise them.

Sprint 1A is a deliberate split of the original single "Sprint 1" — it covers Person CRUD only. Manual Memory entry (originally also part of Sprint 1) is Sprint 1B and is explicitly out of scope here.

---

## 1. Sprint Goal

Turn the empty My Circle screen from Sprint 0 into a fully working, offline, local-only Person management feature: users can view people grouped by circle tier, add a person, edit a person, and soft-delete a person — all persisted to Isar, all validated, all reactive (UI updates automatically from Isar watchers, no manual refresh). No AI, no Memory data, no sync, no network calls beyond the Sprint 0 auth session already in place.

---

## 2. Files and Folders to Create or Modify

### New files
```
lib/
  domain/
    validators/
      person_validators.dart
  features/
    circle/
      circle_providers.dart
      widgets/
        person_list_tile.dart
        person_tier_section.dart
        circle_empty_state.dart
    person_form/
      person_form_screen.dart
      person_form_controller.dart
```

### Modified files
```
lib/
  domain/
    repositories/
      person_repository.dart      # fill out full CRUD — Sprint 0 left this as a minimal empty-query stub
  features/
    circle/
      circle_screen.dart          # replace Sprint 0 empty-state-only view with grouped list + navigation
  app/
    router.dart                  # add routes for create and edit, both pointing at PersonFormScreen
```

Do not create any file under `lib/features/memory/`, `lib/ai/`, `lib/data/sync/`, or `lib/data/remote/supabase/` beyond what Sprint 0 already created. None of those are in scope this sprint.

---

## 3. `PersonRepository` Contract

Implement exactly this interface. Do not add methods beyond it without flagging why.

```dart
abstract class PersonRepository {
  Stream<List<Person>> watchAll();        // excludes soft-deleted, returns an UNGROUPED flat list
  Future<Person?> getByUuid(String uuid);
  Future<void> create(Person person);
  Future<void> update(Person person);
  Future<void> softDelete(String uuid);
}
```

**Non-negotiable rule:** `watchAll()` returns a flat `List<Person>`. Grouping by `circleTier` is explicitly **not** the repository's job — it happens in `circle_providers.dart`, one layer up. If you find yourself writing a `Map<CircleTier, List<Person>>` return type anywhere inside `person_repository.dart`, stop — that logic belongs in the provider layer instead.

`watchAll()` must filter at the query level (`deletedAt == null`), not by fetching everything and filtering in the widget or provider. A soft-deleted person must never reach any consumer of this stream.

---

## 4. Riverpod Providers/Controllers

- `personRepositoryProvider` — exposes the `PersonRepository` implementation, backed by the Isar instance from `isar_provider.dart`.
- `allPeopleProvider` (`StreamProvider<List<Person>>`) — wraps `personRepository.watchAll()` directly, no transformation.
- `groupedPeopleProvider` (`Provider<Map<CircleTier, List<Person>>>`) — derives from `allPeopleProvider`, groups the flat list by `circleTier`, and sorts people within each group alphabetically by `name`. This is where the grouping logic required by Section 3 actually lives. Tiers with zero people still appear as empty-list entries in the map — this provider stays a complete, general-purpose grouping of all six tiers regardless of what the current screen chooses to render; `circle_screen.dart` is the layer responsible for filtering empty tiers out of the display, not this provider.
- `personFormControllerProvider` (`AsyncNotifier`, family-parameterized by an optional `personUuid`) — owns create/edit form state, validation, and the save action. Exposes `AsyncValue<void>` so the form screen can render loading/error/success without containing that logic itself.
- Delete is a simple method call (`ref.read(personRepositoryProvider).softDelete(uuid)`) triggered from a controller-level action in `circle_providers.dart`, never called directly from a widget's `onPressed` without going through a provider-exposed method — keep the write path consistent with the "no business logic in widgets" rule from Sprint 0.

---

## 5. Shared Add/Edit Form — `PersonFormScreen`

There is exactly **one** form screen for both creating and editing a person. Do not create separate `AddPersonScreen` and `EditPersonScreen` files or widgets.

- Route/navigation passes an optional `personUuid` (a `String?`, never an Isar `Id`/int).
- `personUuid == null` → create mode: empty form, default `circleTier` may be pre-selected to `acquaintances` as a sensible default, save calls `PersonRepository.create()`.
- `personUuid != null` → edit mode: `person_form_controller.dart` loads the existing `Person` via `getByUuid()`, pre-fills the form, save calls `PersonRepository.update()`.
- Fields: `name` (required text), `circleTier` (required selection, one of the six enum values), `relationshipType` (optional free text).
- On create: generate `uuid` once via the `uuid` package. On edit: the existing `uuid` is carried through untouched — never regenerated.
- On both create and update: set `updatedAt = DateTime.now()` and `syncStatus = SyncStatus.pending`. Nothing consumes `syncStatus` yet (that's Sprint 5), but every write must already set it correctly so no backfill migration is needed later.
- On create only: set `createdAt = DateTime.now()`.

---

## 6. My Circle Screen

- If zero people exist in total (the Sprint 0 state), render **only** the full-screen empty state from `circle_empty_state.dart` — reuse/extend the Sprint 0 empty-state pattern rather than replacing it outright. Nothing else renders on the screen in this state.
- Once at least one active (non-deleted) person exists, render one section per `CircleTier`, in the fixed order Inner Circle, Family, Friends, Professional, Mentors, Acquaintances, **but only for tiers that contain at least one person.** Do not render a section, header, or placeholder for a tier with zero people — `groupedPeopleProvider`'s map may still contain empty-list entries for every tier (Section 4 is unchanged), but the screen filters those out before rendering, so a tier with no people simply does not appear at all.
- Do not implement a per-tier empty indicator this sprint. This is a deliberate simplification to avoid unnecessary scrolling in the early, sparsely-populated state of the app; revisit only if user testing later suggests always-visible tier structure is worth the trade-off.
- Each person row navigates to `PersonFormScreen` in edit mode on tap.
- Each person row exposes a delete action (e.g. swipe-to-delete or a menu action) that **requires a confirmation dialog** before calling the delete method — this is a destructive-feeling action for the user even though it's recoverable at the data layer, and must not fire on a single accidental tap.
- An entry point (e.g. a floating action button) navigates to `PersonFormScreen` in create mode.

---

## 7. Validation

Implement in `domain/validators/person_validators.dart` as pure, widget-independent functions — not as inline `validator:` closures scattered across the form widget. `person_form_controller.dart` calls these functions; `person_form_screen.dart` only renders the error strings they return.

- `name`: required, non-empty after trimming whitespace, reasonable max length (100 characters — a placeholder implementation limit, not a documented product requirement; adjust only if asked).
- `circleTier`: required — the form must not allow save with no tier selected, even though a default is pre-selected in create mode (an edit-mode load should never produce a null tier, since it's a required enum field in `SCHEMA.md`, but validate defensively anyway).
- `relationshipType`: optional; if provided, same reasonable max length as `name`.
- A failed validation blocks the save call entirely — no partial write to Isar, no navigation away from the form, and the specific field error is shown inline next to the offending field.

---

## 8. Acceptance Criteria

1. `PersonRepository` is fully implemented against Isar per the Section 3 contract, using `uuid` as the only identity ever exposed outside the local Isar layer.
2. My Circle screen shows the full-screen empty state when zero people exist, and once at least one person exists, shows only the tier sections that actually contain people — sourced from `groupedPeopleProvider`, filtered before render. No empty tier section or placeholder ever appears.
3. Adding a person through `PersonFormScreen` (create mode) results in the new person appearing in the correct tier section immediately, with no manual refresh — proving the Isar watcher → Riverpod stream → UI chain is reactive end to end.
4. Editing a person through `PersonFormScreen` (edit mode, pre-filled) persists changes and reflects them live in the Circle screen.
5. Deleting a person soft-deletes it: `deletedAt`, `updatedAt`, and `syncStatus` are all updated; the record disappears from the Circle screen immediately; the record is **not** physically removed from Isar.
6. Attempting to save with an empty name is blocked with an inline validation error; no record is created or modified.
7. `uuid` is generated exactly once, at creation, and never changes across edits.
8. No Supabase table is read from or written to for any Person data — Isar only.
9. The app remains fully functional with no network connectivity throughout every flow in this sprint.

---

## 9. Definition of Done

Sprint 1A is not complete until every item below is checked:

- [ ] `PersonRepository` implements `watchAll`, `getByUuid`, `create`, `update`, `softDelete` exactly per Section 3, with no grouping logic inside it.
- [ ] `groupedPeopleProvider` performs all tier-grouping and sorting; no widget contains grouping logic.
- [ ] `PersonFormScreen` is a single shared file handling both create and edit modes via an optional `personUuid` parameter — no separate Add/Edit screens exist anywhere in the codebase.
- [ ] The My Circle screen renders the full-screen empty state only when zero people exist, and once at least one exists, renders only tier sections that contain people — no empty tier is ever shown once the circle is non-empty.
- [ ] Delete is soft-delete only — no `isar.persons.delete()` (hard delete) call exists anywhere in this sprint's code.
- [ ] Delete requires a confirmation step before executing.
- [ ] Every create/update sets `updatedAt` and `syncStatus = pending`; create additionally sets `createdAt`; `uuid` is immutable after creation.
- [ ] Validation logic lives in `person_validators.dart` as pure functions, independent of any widget.
- [ ] No new Isar collection, no new field on `Person`, and no field type change exists anywhere relative to `SCHEMA.md`.
- [ ] No file exists under `lib/features/memory/`, `lib/ai/`, or `lib/data/sync/`.
- [ ] The app builds, runs fully offline post-login, and every acceptance criterion in Section 8 passes manually.

---

## 10. Things Cursor Should Not Change

- Do not modify `SCHEMA.md`'s `Person` collection definition, its field names/types, or the `enums.dart` values. If Person needs a field this sprint's UI seems to want but `SCHEMA.md` doesn't define (e.g. a photo/avatar), do not add it — flag it instead.
- Do not modify the folder structure established in `ARCHITECTURE.md` Section 2 or the Sprint 0 spec.
- Do not touch `data/local/isar/collections/memory.dart`, `follow_up.dart`, `suggestion_log_entry.dart`, or `connection.dart` — they exist from Sprint 0 and are untouched until their own sprints.
- Do not touch anything under `data/remote/supabase/` beyond what Sprint 0 already implemented for auth.
- Do not introduce `IsarLink`/`IsarLinks` anywhere. Person has no relations to implement yet, but if any relation-like need appears, it follows the `uuid` string-field pattern per `SCHEMA.md`, not Isar's native link feature.

---

## 11. Explicit Out-of-Scope Items

- Manual Memory entry, or any Memory-related UI, repository, or provider (Sprint 1B).
- Any AI provider interface, Gemma integration, or capture modal (Sprint 2).
- Today's Opportunities, Suggestion Engine logic, or background jobs (Sprint 3).
- Semantic search, embeddings, or any search UI (Sprint 4).
- Sync engine, Supabase backup mirror schema/tables, or any push/pull logic (Sprint 5).
- Data export, encryption, account deletion (Sprint 6).
- A "restore deleted person" or trash/undo UI — soft delete makes recovery possible at the data layer in principle, but no UI for it exists this sprint; a soft-deleted person is simply gone from the user's perspective until a later sprint decides otherwise.
- A photo/avatar field for Person — not defined in `SCHEMA.md`; do not add one.
- Person-to-person relationships or the `Connection` collection — that collection is a P1 schema stub only, per `SCHEMA.md`.
- Bulk actions, multi-select, sorting/filtering controls beyond the fixed tier grouping and alphabetical-by-name default, or pagination — the expected list sizes for MVP do not warrant any of this yet.

---

## 12. Common Implementation Pitfalls to Avoid

- **Do not create `AddPersonScreen` and `EditPersonScreen` as separate files.** This is an explicit requirement, not a style suggestion — one `PersonFormScreen`, mode determined by whether `personUuid` is null.
- **Do not implement grouping inside `PersonRepository`.** A repository method that returns `Map<CircleTier, List<Person>>` is a violation of Section 3 even if it "seems more convenient" — grouping is provider-layer logic only.
- **Do not perform a hard delete.** `softDelete()` must only ever set `deletedAt`/`updatedAt`/`syncStatus` — never call Isar's actual delete/remove operation on a Person record this sprint.
- **Do not filter soft-deleted records at the UI layer instead of the query layer.** If `watchAll()` returns deleted records and the widget filters them out before rendering, that's a bug — any future consumer of `watchAll()` (there will be several, in later sprints) would silently break by re-showing deleted people.
- **Do not regenerate `uuid` on edit.** A common accidental bug pattern: using a `copyWith`-style update helper that doesn't explicitly preserve the original `uuid`, or reconstructing a `Person` object from form fields without carrying the loaded record's `uuid` forward.
- **Do not forget `updatedAt`/`syncStatus` on edit and delete, not just create.** All three write paths (create, update, soft-delete) must touch these fields.
- **Do not validate only inside a widget's `TextFormField.validator` closure with no separately callable function.** Validators must be pure, testable functions in `person_validators.dart` that the widget merely calls and displays the result of.
- **Do not skip the delete confirmation dialog.** A direct swipe-and-gone or single-tap-and-gone delete is not acceptable UX for a destructive-feeling action, regardless of soft-delete recoverability at the data layer.
- **Do not pass Isar's local `Id` (the autoIncrement int) through navigation/routing for the edit flow.** Only `uuid` (a `String`) is ever passed between screens or used to look up a record.
- **Do not add pagination, infinite scroll, or any performance optimization for large lists.** Realistic MVP list sizes do not need it, and building it now is scope creep against Section 11.
- **Do not render a section, header, or empty-state message for a tier with zero people.** `groupedPeopleProvider` intentionally still returns every tier as a map key (Section 4), including ones with an empty list — that's for future consumers, not a signal to display them. `circle_screen.dart` must filter out empty-list entries before building the section list. A tier silently disappearing when its last person is deleted, and reappearing the moment someone is added to it, is the correct and expected behavior this sprint.
