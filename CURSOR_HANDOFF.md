# Tend — Cursor Handoff

**Purpose:** Onboard a new Cursor chat to continue Tend development without prior conversation history.  
**Product:** Tend — offline-first personal relationship memory app (Flutter).  
**Last updated:** Sprint 1B complete; next is Sprint 2 (on-device capture + AI extraction).

---

## 1. Current project status

- **Working app:** Auth (Supabase email/password), Isar DB open with full SCHEMA collections, go_router shell (My Circle / Today / Search), temporary Logout on My Circle.
- **Sprint 0:** Done (scaffold, Isar, auth, shell routes).
- **Sprint 1A:** Done — Person CRUD against Isar.
- **Sprint 1B:** Done — manual Memory CRUD + Person Profile (offline Isar).
- **Not built yet:** AI capture/extraction, Today's Opportunities engine, semantic search, sync, settings/export/encryption polish.
- **Next work:** Implement **Sprint 2 only** (on-device capture + AI extraction) per `DEVELOPMENT_ROADMAP.md` / upcoming Sprint 2 spec. Do not start Sprint 3+.
- **Deferred by product decision:** Person→memory cascade delete (not in 1B; still required by `FEATURES.md` acceptance — schedule later, e.g. Sprint 6).
- **Source-of-truth docs (binding):**
  - `ARCHITECTURE.md` — ADR-0001 (system architecture)
  - `ADR.md` — smaller accepted decisions (repo queries, form lifecycle, soft delete, etc.)
  - `FEATURES.md` — P0 scope
  - `SCHEMA.md` — Isar/Supabase field contracts
  - `DEVELOPMENT_ROADMAP.md` — sprint order (1A / 1B split)
  - `SPRINT0.md` / `SPRINT1A.md` / `SPRINT1B.md` — completed sprint specs
  - `DEVLOG.md` — short progress log
  - `BACKLOG.md` — deferred product notes
  - This file — `CURSOR_HANDOFF.md`

---

## 2. Completed sprints

### Sprint 0 — Done
- Flutter scaffold + dependency stack (see §5)
- Isar collections + enums exactly per `SCHEMA.md` + `build_runner` codegen
- Fail-fast Isar init with all schemas registered (`tendIsarSchemas`)
- Supabase Auth init via `--dart-define` (`SUPABASE_URL`, `SUPABASE_ANON_KEY` → `publishableKey:`)
- `go_router` + `StatefulShellRoute.indexedStack`
- Auth splash → session redirect → shell or auth screen
- Auth UX: verification-email message; anti-enumeration on sign-up; loading/disabled controls
- Temporary developer **Logout** on My Circle AppBar
- Dev tooling: `.vscode/launch.json`, `tasks.json`, `settings.json`; lint rules; `.env` gitignore

### Sprint 1A — Done
- `PersonRepository` (`watchActivePeople`, `getByUuid`, `create`, `update`, `softDelete` tombstone only)
- Circle providers: `allPeopleProvider`, `groupedPeopleProvider`, `circleActionsProvider`
- Shared `PersonFormScreen` + autoDispose `personFormControllerProvider(String? personUuid)`
- Create vs edit decided **only** by provider argument `personUuid` (never mutable leftover state)
- `defaultCircleTier` in `lib/core/constants/person_defaults.dart`
- Validators in `domain/validators/person_validators.dart`
- My Circle: empty state, tier sections (non-empty only), FAB add, delete with confirm
- Routes: `/person/new`, `/person/edit/:personUuid`
- **Nav note:** Circle row tap originally went to PersonForm; **Sprint 1B rewired** it to Person Profile

### Sprint 1B — Done
- `MemoryRepository` (`watchAllForPerson`, `getByUuid` excludes deleted at query layer, `create`, `update`, `softDelete`)
- `memory_validators.dart`, `memory_sensitivity_rules.dart`
- Providers: `memoryRepositoryProvider`, `personMemoriesProvider`, `personMemoryTimelineProvider` (`dateValue` desc, nulls older, `createdAt` desc tie-break), `profilePersonProvider`, `personProfileActionsProvider`
- autoDispose `memoryFormControllerProvider(({personUuid, memoryUuid?}))` — mode from `memoryUuid` only
- `MemoryFormScreen`: category, eventText, date toggle+picker, importance 1–5 (default 3); programmatic sensitivity/source/etc.
- `PersonProfileScreen`: permanent person header + timeline below (header visible when empty); edit person via app bar; FAB add memory; delete memory with confirm
- Widgets: `person_profile_header`, `memory_list_tile`, `memory_timeline_empty_state`
- Routes: `/profile/:personUuid`, `.../memory/new`, `.../memory/edit/:memoryUuid`
- Circle row tap → Person Profile
- **No** FollowUp, embeddings, AI, sync, or person→memory cascade

---

## 3. Current architecture

```
UI (features/*)
  → Riverpod providers/controllers
    → domain/repositories (ONLY layer that may use Isar)
      → Isar (isar_community) = local source of truth

Auth: supabase_flutter (Auth only — no table queries for app data)
AI / sync / workmanager: not in codebase yet (Sprint 2+)
```

**Bootstrap (`main.dart`):**
1. `initializeSupabase()`
2. `initializeIsar()` (must succeed or error App)
3. `ProviderScope` + `isarProvider.overrideWithValue(isar)`
4. `App` → `MaterialApp.router` / `routerProvider`

**Routing:**
- `/splash`, `/auth`
- Shell: `/circle`, `/today`, `/search`
- Person: `/person/new`, `/person/edit/:personUuid`
- Profile / memory: `/profile/:personUuid`, `/profile/:personUuid/memory/new`, `/profile/:personUuid/memory/edit/:memoryUuid`
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
      person_defaults.dart          # defaultCircleTier
      circle_tier_labels.dart       # display labels
      memory_defaults.dart          # defaultImportanceScore
      memory_category_labels.dart   # display labels
    theme/app_theme.dart            # still stub
  data/
    local/isar/
      isar_provider.dart
      collections/                  # Person, Memory, FollowUp, SuggestionLogEntry, Connection(+P1 stub)
    remote/supabase/
      supabase_client.dart          # auth init only
  domain/
    repositories/
      person_repository.dart
      memory_repository.dart
    validators/
      person_validators.dart
      memory_validators.dart
    rules/
      memory_sensitivity_rules.dart
  features/
    auth/
    circle/ (+ widgets/)
    person_form/
    person_profile/ (+ widgets/)
    memory_form/
    opportunities/                  # "Coming soon" stub
    search/                         # "Coming soon" stub
```

**Do not invent** `lib/screens/` or layer-first layouts. Feature-first per `ARCHITECTURE.md`.  
**Do not create** `features/capture/` or `settings/` until their sprints (Sprint 2 / Sprint 5–6).

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

**SDK:** Dart `^3.12.2` / Flutter stable.

---

## 6. Important architectural decisions

1. **Isar (`isar_community`) is the only source of truth** for app data. Offline is the default mode.
2. **Supabase = Auth (+ optional backup/sync from Sprint 5).** Never query Supabase tables for Person/Memory in early sprints.
3. **uuid FKs, never `IsarLink` / never sync Isar autoIncrement `id`.**
4. **Deletes are tombstones (`deletedAt`), not hard deletes.** Person→memory cascade is **deferred** (explicit decision after 1B planning).
5. **Repositories are the only Isar touchpoint;** no Isar imports in widgets. Active-record reads (`getByUuid`, watches) must **hide soft-deleted rows at the query layer**.
6. **Auth logic only in `auth_controller.dart`.**
7. **Sign-up anti-enumeration:** empty `user.identities` → neutral failure copy.
8. **AI behind provider interfaces** (Sprint 2+); no `flutter_gemma` yet.
9. **Package pins** above are deliberate (analyzer conflict with Isar codegen).
10. **Sprint 1 split:** 1A People → 1B Memory + Profile (both done) → Sprint 2 AI.
11. **Form controllers must be `autoDispose`.** Create vs edit from immutable route/provider args only (`ADR.md` ADR-004).
12. **Timeline sort** lives in providers, not repositories (`dateValue` desc, nulls older, `createdAt` desc tie-break).

---

## 7. Current coding conventions

- Feature-first folders under `lib/features/`
- Prefer **Riverpod** manual `Provider` / `StreamProvider` / `AsyncNotifier`; `riverpod_generator` is available but largely unused so far
- **Single quotes**, **prefer_const_constructors**, **unawaited_futures**
- Line length **100**
- SCHEMA field names/types/enums must not be renamed
- Generated Isar warnings in `*.g.dart` can be ignored
- `AppAuthState` naming avoids clash with gotrue’s `AuthState`
- Supabase init uses **`publishableKey:`**

---

## 8. Developer workflow

**Run / debug (preferred):** F5 with `.vscode/launch.json`  
- Passes `--dart-define=SUPABASE_URL=...` and `SUPABASE_ANON_KEY=...`  
- **Do not commit secrets.** Prefer `${env:...}` over hardcoding keys.

**Tasks:** Flutter Pub Get / Analyze / Test; Codegen Build / Watch via `build_runner`.

**Manual:** `flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...`

---

## 9. Pending Sprint 2 work

**Authoritative plan:** `DEVELOPMENT_ROADMAP.md` → Sprint 2 (add a `SPRINT2.md` spec before coding if the team follows the 1A/1B pattern).

**Expected scope (roadmap):**
1. Abstract AI providers (`Extraction` / `Embedding` / `Transcription` / `OCR`) before concrete Gemma
2. Model management + device capability + `ManualFallbackProvider` first
3. Gemma extraction/embeddings; platform ASR/OCR
4. Global capture modal + confirmation card
5. Wire into existing Memory model / Person Profile flows where appropriate

**Out of scope until later sprints:** Suggestion Engine (3), semantic search UI (4), sync (5), export/encryption polish (6), person→memory cascade (deferred).

---

## 10. Things future chats must not change

Without an explicit product decision / re-scoping conversation:

- Do **not** replace `isar_community`, Riverpod, go_router, or Supabase Auth
- Do **not** switch to official `isar` / `IsarLink`
- Do **not** invent or rename SCHEMA fields/enums
- Do **not** query Supabase for app data tables before Sprint 5
- Do **not** skip Sprint 2 model-management / provider abstraction
- Do **not** casually upgrade Riverpod / `build_runner` past pinned ranges
- Do **not** reveal “email already exists” on sign-up
- Do **not** auto sign-in after sign-up
- Do **not** hard-delete Person/Memory rows (tombstone only)
- Do **not** put business logic or Isar access inside widgets
- Do **not** create FollowUp records from memory save until Sprint 3 defines when
- Do **not** implement person→memory cascade unless explicitly re-scoped
- Prefer not to expand folder layout beyond ARCHITECTURE + sprint-spec trees

---

## Quick start prompt for a new chat

> Read `CURSOR_HANDOFF.md`, `ARCHITECTURE.md`, `ADR.md`, `SCHEMA.md`, `FEATURES.md`, and Sprint 2 in `DEVELOPMENT_ROADMAP.md`. Implement Sprint 2 only (on-device capture + AI extraction). Do not implement Suggestion Engine, sync, or cascade delete. Follow repository boundaries and SCHEMA exactly. Wait for approval between major steps if the user asks.

---

## Related paths

| Doc | Role |
|---|---|
| `ARCHITECTURE.md` | Binding system architecture |
| `ADR.md` | Smaller accepted decisions |
| `FEATURES.md` | P0/P1 scope + acceptance |
| `SCHEMA.md` | Exact data model |
| `DEVELOPMENT_ROADMAP.md` | Sprint sequence |
| `DEVLOG.md` | Human progress notes |
| `SPRINT0.md` / `SPRINT1A.md` / `SPRINT1B.md` | Completed sprint specs |
| `BACKLOG.md` | Deferred product notes |
