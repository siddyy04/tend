# SPRINT 0 IMPLEMENTATION SPECIFICATION
### Target: AI coding agent (Cursor). Read fully before writing any code.

You are implementing **Sprint 0 only** of the Tend Flutter app. Reference documents already in this repository: `ARCHITECTURE.md` (binding architecture decisions), `FEATURES.md` (scope), `SCHEMA.md` (data model), `DEVELOPMENT_ROADMAP.md` (sprint sequence). This specification is the authoritative scope for this task. If anything here appears to conflict with those documents, stop and ask rather than guessing which one wins.

---

## 1. Sprint Goal

Produce an empty but real, running app: authentication works end to end against Supabase, the local Isar database is initialized with the full schema from `SCHEMA.md`, and a navigation shell exists with three empty stub screens. No feature logic beyond auth and navigation is in scope. The app must run offline after login except for the auth call itself.

---

## 2. Files and Folders to Create

Create exactly this set. Do not create files outside this list unless a file below explicitly requires a supporting file Flutter tooling generates automatically (e.g. `.g.dart` codegen output).

```
lib/
  main.dart
  app/
    app.dart
    router.dart
  core/
    constants/
      enums.dart
    theme/
      app_theme.dart
  data/
    local/
      isar/
        isar_provider.dart
        collections/
          person.dart
          memory.dart
          follow_up.dart
          suggestion_log_entry.dart
          connection.dart
    remote/
      supabase/
        supabase_client.dart
  domain/
    repositories/
      person_repository.dart
  features/
    auth/
      auth_screen.dart
      auth_controller.dart
    circle/
      circle_screen.dart
    opportunities/
      opportunities_screen.dart
    search/
      search_screen.dart
```

`person_repository.dart` is the only repository created this sprint — it exists solely to expose a watched, empty query against the `Person` collection for the Circle screen. Do not create `memory_repository.dart`, `follow_up_repository.dart`, or any AI/sync-related files this sprint — see Section 7.

---

## 3. Dependencies Required

Add only these to `pubspec.yaml`. Use the latest stable version of each at implementation time — do not pin versions from memory; check pub.dev directly.

**Runtime:**
- `isar_community` (and its companion native-libs package — confirm the exact current package name on pub.dev before adding; do not assume it is named identically to the discontinued `isar_flutter_libs`)
- `flutter_riverpod`
- `riverpod_annotation`
- `go_router`
- `supabase_flutter`
- `path_provider`
- `uuid`

**Dev:**
- `riverpod_generator`
- `build_runner`
- `isar_generator` (or the `isar_community` equivalent — confirm exact package name)

**Do not add this sprint**, even if they appear in `ARCHITECTURE.md`'s full package table: `flutter_gemma`, `workmanager`, `speech_to_text`, `google_mlkit_text_recognition`, `flutter_secure_storage`, `connectivity_plus`, `flutter_local_notifications`, `device_info_plus`. These belong to later sprints. Adding them now is out of scope even if unused.

---

## 4. Expected Project Structure

The folder tree in Section 2 must match `ARCHITECTURE.md` Section 2 exactly for the directories it touches. Do not introduce a different top-level structure (no `lib/screens/`, no `lib/models/`, no layer-first organization). Feature folders under `lib/features/` are created only for the four features listed above — do not scaffold empty folders for `capture/`, `person_profile/`, or `settings/` this sprint; they will be created when their sprint begins.

`main.dart` responsibilities only: initialize Isar (via `isar_provider.dart`), initialize Supabase, wrap the app in `ProviderScope`, run `App`. No other logic belongs in `main.dart`.

---

## 5. Acceptance Criteria

Sprint 0 is complete only when all of the following are true:

1. The app builds and runs on both iOS and Android targets (or at minimum one, if the dev environment only supports one — state which was verified).
2. A new user can sign up via Supabase Auth (email or phone OTP) and lands on the app shell.
3. An existing user can log in and land on the app shell, with the session persisting across an app restart.
4. The app shell shows three destinations (My Circle, Today, Search) via bottom navigation or a drawer, using `go_router`.
5. The My Circle screen queries the local `Person` Isar collection through `PersonRepository` and a Riverpod stream provider, and correctly renders an empty state — because zero Person records exist yet, and this sprint does not implement creating one.
6. The Today and Search screens render as simple placeholder screens (e.g. a centered "Coming soon" message) — no logic.
7. All Isar collections (`Person`, `Memory`, `FollowUp`, `SuggestionLogEntry`, `Connection`) from `SCHEMA.md` exist with codegen successfully run, even though only `Person` is queried by any UI this sprint.
8. Turning off network access after login does not crash the app or block navigation between the three stub screens.
9. No Supabase table is queried for anything other than authentication.

---

## 6. Things Cursor Should Not Change

- Do not rename, restructure, or "improve" the folder layout in Section 2 or in `ARCHITECTURE.md` Section 2.
- Do not modify field names, types, or enum values defined in `SCHEMA.md`. If a field looks unused this sprint (e.g. `syncStatus`, `deletedAt`, `embedding`), keep it exactly as specified — it is intentionally present for later sprints, not dead code to remove.
- Do not replace Isar, Riverpod, go_router, or Supabase with alternative packages, even if you judge another package to be simpler for this specific screen. These are binding decisions from `ARCHITECTURE.md`, not suggestions.
- Do not use `IsarLink`/`IsarLinks` for relations between collections. All relations use the `uuid` string-field pattern already defined in `SCHEMA.md`. This is deliberate — see `SCHEMA.md`'s "Why uuid FKs, not IsarLinks" note.
- Do not add a `source_ref` upload path, Supabase Storage bucket, or any cloud file handling. Out of scope for every sprint until explicitly specified.
- Do not create the Supabase backup-mirror SQL schema from `SCHEMA.md`. That table set is Sprint 5 scope only. This sprint's Supabase project is for authentication alone.

---

## 7. Common Implementation Pitfalls to Avoid

- **Do not build Add/Edit Person UI.** It is tempting, on seeing an empty Circle screen, to add a "create person" flow to make it feel functional — that is explicitly Sprint 1 scope. The empty state is the correct and complete Sprint 0 behavior. A visible "+" button that does nothing yet, or no button at all, are both acceptable; a working create flow is not.
- **Do not query Supabase tables for Person/Memory/any app data.** Supabase in this sprint is authentication only. Any temptation to "just also save the person to Supabase since we're connected anyway" violates the local-first architecture — Isar is the only data store touched this sprint.
- **Do not put query or auth logic inside widgets.** Business logic belongs in Riverpod providers/controllers (`auth_controller.dart`, `person_repository.dart`), not in `build()` methods. A widget should only read `AsyncValue` state and call controller methods.
- **Do not use Isar's local `Id` (autoIncrement) as a foreign key anywhere**, including internally. Every collection's `uuid` field is the only identity that should ever be referenced across collections, even though no cross-collection queries exist yet this sprint.
- **Do not skip generating a `uuid` at record-creation time "for later."** Any code path that creates a Person/Memory/etc. (even if unused this sprint) must populate `uuid` via the `uuid` package at creation, not leave it nullable or defer it.
- **Do not implement token storage manually.** Use `supabase_flutter`'s built-in session persistence rather than hand-rolling secure storage — `flutter_secure_storage` is explicitly deferred (Section 3) and is not needed for `supabase_flutter`'s default session handling to work correctly this sprint.
- **Do not leave Isar collection files without running codegen**, and do not hand-write the `.g.dart` files — they must be generated via `build_runner` and committed or gitignored per this repo's existing convention (check for an existing `.gitignore` entry pattern before assuming).
- **Do not silently swallow Isar initialization or Supabase initialization errors.** If either fails to initialize, the app should show a clear error state, not a blank screen or a silent crash.

---

## 8. Clear Boundaries — Sprint 0 Only

Explicitly **out of scope** for this task, regardless of how small or tempting the addition seems:

- Add/Edit/Delete Person (Sprint 1)
- Manual memory entry form (Sprint 1)
- Any AI provider interface or implementation — `ExtractionProvider`, `EmbeddingProvider`, `TranscriptionProvider`, `OCRProvider`, or any Gemma integration (Sprint 2)
- Model download/device capability check logic (Sprint 2)
- Capture modal (voice/text/photo/share-sheet) (Sprint 2)
- Today's Opportunities logic or scheduled background jobs (Sprint 3)
- Semantic search or any embedding generation/storage logic (Sprint 4)
- Sync engine, push/pull logic, conflict resolution, or the Supabase backup mirror schema (Sprint 5)
- Data export, delete cascades, encryption (Sprint 6)
- Any P1/P2 feature from `FEATURES.md`

If implementing Sprint 0 correctly seems to require touching any of the above, stop and flag it rather than expanding scope to make Sprint 0 "more complete." A minimal, correct Sprint 0 that does exactly what Section 5 specifies — nothing more — is the success condition.
