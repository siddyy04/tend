# Tend — Cursor Handoff

**Purpose:** Onboard a new Cursor chat to continue Tend development without prior conversation history.  
**Product:** Tend — offline-first personal relationship memory app (Flutter).  
**Last updated:** Sprint 1A complete; Sprint 1B next (manual Memory CRUD + Person Profile).

---

## 1. Current project status

- **Working app:** Auth (Supabase email/password), Isar DB open with full SCHEMA collections, go_router shell (My Circle / Today / Search), temporary Logout on My Circle.
- **Sprint 0:** Done (scaffold, Isar, auth, shell routes).
- **Sprint 1A:** Done — Person CRUD against Isar (list/group by tier, add/edit/soft-delete, validation, reactive streams).
- **Not built yet:** Memory CRUD, Person Profile, AI, sync, search, opportunities engine.
- **Next work:** Implement **Sprint 1B only** (manual Memory CRUD + Person Profile). Cascade person→memory delete is **deferred** (intentionally out of 1B).
- **Source-of-truth docs (binding):**
  - `ARCHITECTURE.md` — ADR-0001
  - `FEATURES.md` — P0 scope
  - `SCHEMA.md` — Isar/Supabase field contracts
  - `DEVELOPMENT_ROADMAP.md` — sprint order (1A / 1B split)
  - `SPRINT0.md` / `SPRINT1A.md` — completed sprint specs
  - `SPRINT1B.md` — authoritative scope for the next sprint
  - `DEVLOG.md` — short progress log
  - `BACKLOG.md` — deferred product notes (e.g. duplicate names)
  - This file — `CURSOR_HANDOFF.md`

---

## 2. Completed sprints

### Sprint 0 — Done
- Flutter scaffold + dependency stack (see §5)
- Isar collections + enums exactly per `SCHEMA.md` + `build_runner` codegen (`.g.dart` files exist)
- Fail-fast Isar init with all schemas registered (`tendIsarSchemas`)
- Supabase Auth init via `--dart-define` (`SUPABASE_URL`, `SUPABASE_ANON_KEY` → `publishableKey:`)
- `go_router` + `StatefulShellRoute.indexedStack` (tab state preserved)
- Auth splash → session redirect → shell or auth screen
- Auth UX: verification-email message; neutral copy when `user.identities` is empty (anti-enumeration); clear `AuthException` messages; loading/disabled controls
- Temporary developer **Logout** on My Circle AppBar
- Dev tooling: `.vscode/launch.json`, `tasks.json`, `settings.json`; lint rules; `.env` gitignore

### Sprint 1A — Done
- `PersonRepository` (`watchActivePeople`, `getByUuid`, `create`, `update`, `softDelete` tombstone only)
- Circle providers: `allPeopleProvider`, `groupedPeopleProvider`, `circleActionsProvider`
- Shared `PersonFormScreen` + autoDispose `personFormControllerProvider(String? personUuid)`
- Create vs edit decided **only** by provider argument `personUuid` (never mutable leftover state) — fixed after a create-reuse bug
- `defaultCircleTier` in `lib/core/constants/person_defaults.dart`
- Validators in `domain/validators/person_validators.dart`
- My Circle: empty state, tier sections (non-empty only), FAB add, tap → edit person, delete with confirm
- Routes: `/person/new`, `/person/edit/:personUuid` (full-screen, root navigator)
- No Memory UI, no cascade delete, no Supabase table writes for people

---

## 3. Current architecture

```
UI (features/*)
  → Riverpod providers/controllers
    → domain/repositories (ONLY layer that may use Isar)
      → Isar (isar_community) = local source of truth

Auth: supabase_flutter (Auth only — no table queries for app data)
AI / sync / workmanager: not in codebase yet (later sprints)
```

**Bootstrap (`main.dart`):**
1. `initializeSupabase()`
2. `initializeIsar()` (must succeed or error App)
3. `ProviderScope` + `isarProvider.overrideWithValue(isar)`
4. `App` → `MaterialApp.router` / `routerProvider`

**Routing:**
- `/splash` — auth loading
- `/auth` — sign in / sign up
- Shell: `/circle`, `/today`, `/search`
- Person form: `/person/new`, `/person/edit/:personUuid`
- Redirects on `AppAuthState` (loading / authenticated / unauthenticated)

---

## 4. Folder structure

```
lib/
  main.dart
  app/
    app.dart
    app_routes.dart
    router.dart
  core/
    constants/
      enums.dart
      person_defaults.dart
      circle_tier_labels.dart
    theme/app_theme.dart          # still stub
  data/
    local/isar/
      isar_provider.dart
      collections/
        person.dart (+ .g.dart)
        memory.dart (+ .g.dart)
        follow_up.dart (+ .g.dart)
        suggestion_log_entry.dart (+ .g.dart)
        connection.dart (+ .g.dart)   # P1 schema stub
    remote/supabase/
      supabase_client.dart
  domain/
    repositories/
      person_repository.dart      # Sprint 1A — implemented
    validators/
      person_validators.dart
  features/
    auth/
      auth_controller.dart
      auth_screen.dart
    circle/
      circle_screen.dart
      circle_providers.dart
      widgets/
        circle_empty_state.dart
        person_list_tile.dart
        person_tier_section.dart
    person_form/
      person_form_screen.dart
      person_form_controller.dart
    opportunities/
      opportunities_screen.dart  # "Coming soon"
    search/
      search_screen.dart          # "Coming soon"
```

**Do not invent** `lib/screens/` or layer-first layouts. Feature-first per `ARCHITECTURE.md`.  
**Do not create** `features/capture/` or `settings/` until their sprints.  
**Sprint 1B will add** `features/person_profile/` and `features/memory_form/` per `SPRINT1B.md`.

---

## 5. Packages in use

**Pinned for analyzer compatibility with `isar_community_generator` 3.3.2** (do not casually upgrade Riverpod/build_runner to latest):

| Package | Version constraint |
|---|---|
| `isar_community` | `3.3.2` |
| `isar_community_flutter_libs` | `3.3.2` |
| `isar_community_generator` | `3.3.2` |
| `flutter_riverpod` | `3.2.1` |
| `riverpod_annotation` | `4.0.2` |
| `riverpod_generator` | `4.0.3` |
| `build_runner` | `>=2.12.0 <2.15.2` |
| `freezed` | `3.2.4` |
| `freezed_annotation` | `3.1.0` |
| `json_serializable` | `6.12.0` |
| `json_annotation` | `>=4.10.0 <4.11.0` |
| `go_router` | `^17.4.0` |
| `supabase_flutter` | `^2.17.1` |
| `path_provider` | `^2.1.6` |
| `uuid` | `^4.6.0` |
| `flutter_lints` | `^6.0.0` |

**Import Isar as:** `package:isar_community/isar.dart` (not official `isar`).

**SDK:** Dart `^3.12.2` / Flutter stable (project created on Flutter 3.44.x era).

---

## 6. Important architectural decisions

1. **Isar (`isar_community`) is the only source of truth** for app data. Offline is the default mode.
2. **Supabase = Auth (+ optional backup/sync from Sprint 5).** Never query Supabase tables for Person/Memory in early sprints.
3. **uuid FKs, never `IsarLink` / never sync Isar autoIncrement `id`.**
4. **Deletes are tombstones (`deletedAt`), not hard deletes.** Person→memory cascade is **deferred** past Sprint 1B (explicit product decision).
5. **Repositories are the only Isar touchpoint;** no Isar imports in widgets.
6. **Auth logic only in `auth_controller.dart`;** screens call the controller.
7. **Sign-up anti-enumeration:** if `AuthResponse.user.identities` is empty, show neutral failure copy — never “email already exists.”
8. **AI behind provider interfaces** (Sprint 2+); no `flutter_gemma` yet.
9. **Package pins** above are deliberate; latest Riverpod/build_runner break `isar_community_generator` (analyzer conflict).
10. **Sprint 1 split:** 1A People (done) → 1B Memory + Person Profile → then Sprint 2 AI.
11. **Form controllers must be `autoDispose`.** Create vs edit mode must follow the provider family argument only — never leftover mutable “loaded entity” state (Sprint 1A create-reuse bug).

---

## 7. Current coding conventions

- Feature-first folders under `lib/features/`
- Prefer **Riverpod** (`Notifier` / `Provider` / `StreamProvider`); `riverpod_generator` is available but most providers use manual declarations
- **Single quotes**, **prefer_const_constructors**, **unawaited_futures** (`analysis_options.yaml`)
- Line length **100** (`.vscode/settings.json`)
- Format on save + organize imports enabled in workspace
- SCHEMA field names/types/enums must not be renamed or “simplified”
- Generated Isar experimental warnings in `*.g.dart` can be ignored
- `AppAuthState` naming avoids clash with gotrue’s `AuthState`
- Supabase init uses **`publishableKey:`** (not deprecated `anonKey:`)

---

## 8. Developer workflow

**Run / debug (preferred):** F5 with `.vscode/launch.json`  
- Configs: `Tend (debug)`, `Tend (profile)`, `Tend (Android)`  
- Passes `--dart-define=SUPABASE_URL=...` and `SUPABASE_ANON_KEY=...`  
- Ensure env vars or launch defines are set; **do not commit secrets.** Prefer `${env:...}` over hardcoding keys in `launch.json`.

**Tasks (Terminal → Run Task):**
- Flutter: Pub Get / Analyze / Test
- Codegen: Build → `dart run build_runner build`
- Codegen: Watch → `dart run build_runner watch`

**Manual alternative:** `flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...`

**Gitignore:** `.env`, `.env.*` ignored. Keep `.vscode/` shareable but scrub secrets from launch configs before pushing.

---

## 9. Pending Sprint 1B work

**Authoritative spec:** `SPRINT1B.md`.

**Scope:**
1. `MemoryRepository` — watch by person, getByUuid (exclude deleted), create, update, softDelete
2. `memory_validators.dart` + `memory_sensitivity_rules.dart`
3. Providers: `personMemoriesProvider`, `personMemoryTimelineProvider` (sort: `dateValue` desc, then `createdAt` desc; null dates older), autoDispose `memoryFormControllerProvider`
4. `MemoryFormScreen` (manual fields only; no FollowUp, no embedding)
5. `PersonProfileScreen` — person header **always** shown (even when timeline empty) + memory timeline
6. Router + Circle tap → Profile (person edit becomes secondary from profile)
7. **No** person→memory cascade this sprint

**Suggested order:** Repository → validators/rules → providers → form UI → profile UI → router/circle rewire → QA checklist in `SPRINT1B.md`.

**Out of scope for 1B:** AI, capture modal, FollowUp, embeddings, sync, relative dates, category filters/search on timeline, cascade delete.

---

## 10. Things future chats must not change

Without an explicit product decision / re-scoping conversation:

- Do **not** replace `isar_community`, Riverpod, go_router, or Supabase Auth
- Do **not** switch to official `isar` / `IsarLink`
- Do **not** invent or rename SCHEMA fields/enums
- Do **not** query Supabase for app data tables before Sprint 5
- Do **not** add AI / Gemma / capture / opportunities engine early
- Do **not** implement Sprint 2+ while doing 1B
- Do **not** casually upgrade `flutter_riverpod` / `riverpod_generator` / `build_runner` past pinned ranges (breaks Isar codegen)
- Do **not** reveal “email already exists” on sign-up (preserve anti-enumeration UX)
- Do **not** auto sign-in after sign-up
- Do **not** hard-delete Person/Memory rows (tombstone only)
- Do **not** put business logic or Isar access inside widgets
- Do **not** create the Supabase backup-mirror SQL schema before Sprint 5
- Do **not** implement person→memory cascade unless explicitly re-scoped
- Prefer not to expand folder layout beyond ARCHITECTURE + sprint-spec feature-first trees

---

## Quick start prompt for a new chat

> Read `CURSOR_HANDOFF.md`, `ARCHITECTURE.md`, `SCHEMA.md`, `FEATURES.md`, and `SPRINT1B.md`. Implement Sprint 1B only (manual Memory CRUD + Person Profile). Do not implement cascade delete, AI, FollowUp, or embeddings. Follow repository boundaries and SCHEMA exactly. Wait for approval between major steps if the user asks.

---

## Related paths

| Doc | Role |
|---|---|
| `ARCHITECTURE.md` | Binding architecture |
| `FEATURES.md` | P0/P1 scope + acceptance |
| `SCHEMA.md` | Exact data model |
| `DEVELOPMENT_ROADMAP.md` | Sprint sequence |
| `DEVLOG.md` | Human progress notes |
| `SPRINT0.md` / `SPRINT1A.md` | Completed sprint specs |
| `SPRINT1B.md` | Current sprint spec |
| `BACKLOG.md` | Deferred product notes |
