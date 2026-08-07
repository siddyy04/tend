# SPRINT 1B IMPLEMENTATION SPECIFICATION
### Target: AI coding agent (Cursor). Read fully before writing any code.

You are implementing **Sprint 1B only** of the Tend Flutter app. Reference documents already in this repository: `ARCHITECTURE.md` (binding architecture decisions), `FEATURES.md` (scope), `SCHEMA.md` (data model), `DEVELOPMENT_ROADMAP.md` (sprint sequence), `SPRINT0.md` and `SPRINT1A.md` (prior sprints, already implemented). This specification is the authoritative scope for this task. If anything here appears to conflict with those documents, stop and ask rather than guessing which one wins. Every architecture decision in `ARCHITECTURE.md` and every schema definition in `SCHEMA.md` carries forward unchanged — this sprint implements against them, it does not revise them.

Sprint 1B is the second half of the original "Sprint 1" — it covers manual Memory entry only, built on top of the Person CRUD delivered in Sprint 1A. No AI, no suggestions, no embeddings, no sync.

---

## 1. Sprint Goal

Allow users to manually capture and manage memories for people in My Circle. A Person Profile screen shows a given person's memory timeline; users can add, edit, and soft-delete memories, entirely offline, entirely local (Isar), with the same reactive, validated, provider-mediated pattern established in Sprint 1A.

---

## 2. Implementation Order

Build in this order — each step depends on the one before it, and building UI before the data/logic layer beneath it is the most common way this kind of sprint goes sideways.

1. `MemoryRepository` (contract + Isar-backed implementation).
2. `memory_validators.dart` and `memory_sensitivity_rules.dart` — pure logic, no UI dependency, easiest to get right in isolation.
3. Riverpod providers: `memoryRepositoryProvider`, `personMemoriesProvider`, `personMemoryTimelineProvider`, `memoryFormControllerProvider`.
4. `MemoryFormScreen` + `memory_form_controller.dart` (create/edit form).
5. `PersonProfileScreen` (timeline UI, empty state, entry points to add/edit memory and to edit the person).
6. Router changes: new routes for Person Profile and the Memory form.
7. Update `circle_screen.dart`'s tap behavior (see Section 3 — this is a deliberate, called-out change from Sprint 1A).
8. Manual QA against Section 10's Testing Checklist.

---

## 3. Files to Create or Modify

### New files
```
lib/
  domain/
    repositories/
      memory_repository.dart
    validators/
      memory_validators.dart
    rules/
      memory_sensitivity_rules.dart
  features/
    person_profile/
      person_profile_screen.dart
      person_profile_providers.dart
      widgets/
        memory_list_tile.dart
        memory_timeline_empty_state.dart
    memory_form/
      memory_form_screen.dart
      memory_form_controller.dart
```

### Modified files
```
lib/
  features/
    circle/
      circle_screen.dart      # tap navigation changes — see below
  app/
    router.dart               # add Person Profile and Memory Form routes
```

**Deliberate navigation change from Sprint 1A, called out explicitly:** in Sprint 1A, tapping a person row navigated directly to `PersonFormScreen` in edit mode — a reasonable placeholder given no Person Profile screen existed yet. As of this sprint, tapping a person row in `circle_screen.dart` navigates to the new `PersonProfileScreen` instead. Editing a person's own details (name/tier/relationship type) becomes a secondary action reachable from within `PersonProfileScreen` (e.g. an edit icon in its app bar), not the primary tap target from the Circle list anymore. This matches the product's Person Profile screen as designed ("what matters about this person") and is expected, not an error to "fix" back to Sprint 1A's behavior.

Do not create or modify any file under `lib/ai/`, `lib/data/sync/`, or `lib/data/remote/supabase/` beyond what already exists from Sprint 0.

---

## 4. `MemoryRepository` Contract

Implement exactly this interface — the same shape and the same non-negotiable rule as `PersonRepository` from Sprint 1A.

```dart
abstract class MemoryRepository {
  Stream<List<Memory>> watchAllForPerson(String personUuid);  // excludes soft-deleted, returns an UNGROUPED, UNSORTED flat list
  Future<Memory?> getByUuid(String uuid);
  Future<void> create(Memory memory);
  Future<void> update(Memory memory);
  Future<void> softDelete(String uuid);
}
```

**Non-negotiable rule (same as Sprint 1A, Section 3):** `watchAllForPerson()` filters by `personUuid` and by `deletedAt == null` at the query level — both are legitimate scope constraints for a repository, not "grouping." But it returns a flat, unsorted `List<Memory>`. Chronological ordering is **not** the repository's job — it happens in `personMemoryTimelineProvider`, one layer up. If you find yourself calling `.sortByDateValueDesc()` or any sort method inside `memory_repository.dart`, stop — that belongs in the provider layer instead, even though `SCHEMA.md`'s example query shows sorting inline; this sprint's explicit rule supersedes that example for consistency with Sprint 1A's pattern.

`getByUuid()` must also exclude soft-deleted records — do not allow the edit flow to load a deleted memory.

---

## 5. Riverpod Providers/Controllers

- `memoryRepositoryProvider` — exposes the `MemoryRepository` implementation, backed by the same Isar instance.
- `personMemoriesProvider` (family, `StreamProvider<List<Memory>>` keyed by `personUuid`) — wraps `memoryRepository.watchAllForPerson(personUuid)` directly, no transformation.
- `personMemoryTimelineProvider` (family, `Provider<List<Memory>>` keyed by `personUuid`) — derives from `personMemoriesProvider`, sorted reverse-chronologically by `dateValue` descending, with `createdAt` descending as the deterministic tie-breaker in every case where primary ordering doesn't fully resolve — both when two memories share the exact same `dateValue`, and when `dateValue` is null on one or both (nulls sort as if older than any explicit date, then compare by `createdAt` descending among themselves). The sort must never depend on undefined/incidental ordering — every pair of memories has a single correct relative order, always resolvable down to `createdAt`. This is where the sorting required by Section 4 actually lives.
- `memoryFormControllerProvider` (family `AutoDisposeAsyncNotifier`, keyed by a record `({String personUuid, String? memoryUuid})`) — owns create/edit form state, validation, sensitivity derivation, and the save action. `personUuid` is always required (a memory cannot exist without a person); `memoryUuid` is null in create mode. **Must be `autoDispose`** — this provider's state is only meaningful while the form screen is on-screen; leaving it non-`autoDispose` would leak stale form state (and a stale loaded `Memory`) in the provider container after the user navigates away, and would cause a leftover create-mode or edit-mode instance to persist incorrectly across repeated visits to the form for different memories.
- Delete is a controller-exposed method (`ref.read(memoryRepositoryProvider).softDelete(uuid)`), called from `person_profile_providers.dart`, never called directly from a widget — same rule as Sprint 1A.

---

## 6. Shared Add/Edit Form — `MemoryFormScreen`

Exactly **one** form screen for both creating and editing a memory. Do not create separate `AddMemoryScreen` and `EditMemoryScreen` files or widgets.

- Requires `personUuid` always (route parameter, never optional — a memory always belongs to exactly one person, per `SCHEMA.md`).
- Accepts an optional `memoryUuid`. Null → create mode. Present → edit mode: `memory_form_controller.dart` loads the existing `Memory` via `getByUuid()` and pre-fills the form; save calls `MemoryRepository.update()`.
- Fields exposed to the user:
  - `category` — required dropdown, one of the 11 `MemoryCategory` values.
  - `eventText` — required multiline text.
  - Date — a simple toggle: off means no date (`datePrecision = none`, `dateValue = null`, `dateValueRaw = null`); on reveals a native date picker and sets `datePrecision = explicit`, `dateValue` = the picked date. **Do not build any free-text/relative date input** (e.g. typing "next month") — that is exclusively an AI-extraction concern from Sprint 2's `date_type: relative` path, not something a human manually typing a memory needs replicated here.
  - `importanceScore` — required, an integer 1–5 control (e.g. a segmented control or slider), defaulting to 3.
- Fields **not** exposed to the user, set programmatically:
  - `sensitivityFlag` — always recomputed from the current `category` via `memory_sensitivity_rules.dart`, on every save (create and edit alike). It is never independently persisted as a separate user choice — if the category changes on edit, the sensitivity is recalculated, not carried over from the original value.
  - `sourceType` — hardcoded to `SourceType.text` for every memory created through this form.
  - `sourceRef`, `quoteEvidence`, `extractionConfidence`, `personMatchConfidence` — all stay `null`. These exist in `SCHEMA.md` for the AI-extraction path (Sprint 2) and have no meaning for manually entered memories.
  - `needsUserConfirmation` — always `false`. A manually typed memory is already user-confirmed by construction; this flag exists for the AI confidence-gating flow, not this one.
  - `embedding` — stays `null`. Do not generate or store an embedding this sprint (Sprint 4 scope).
- On create: generate `uuid` once via the `uuid` package, set `createdAt = DateTime.now()`.
- On both create and update: set `updatedAt = DateTime.now()` and `syncStatus = SyncStatus.pending` — same forward-compatible rule as Sprint 1A, even though nothing consumes it yet.
- On edit: `uuid` and `personUuid` are carried through untouched — never regenerated or changed. A memory cannot be moved to a different person through this form.

### `memory_sensitivity_rules.dart`
A pure function, no side effects, no I/O:
```dart
SensitivityLevel defaultSensitivityForCategory(MemoryCategory category) {
  switch (category) {
    case MemoryCategory.health:
    case MemoryCategory.finance:
      return SensitivityLevel.high;
    case MemoryCategory.family:
      return SensitivityLevel.medium;
    default:
      return SensitivityLevel.low;
  }
}
```
This matches the category-to-sensitivity defaults already established in the project's Bible/ontology work. Do not invent a different mapping.

---

## 7. Person Profile Screen

- Displays basic person info at the top (name, circle tier, relationship type) — read-only display here; editing is a separate action (an edit icon navigating to `PersonFormScreen`, reusing Sprint 1A's screen unchanged), not inline editing on this screen. **`PersonProfileScreen` must remain strictly read-only with respect to Person data — it never calls `PersonRepository.update()` or any Person write method directly, under any circumstance.** The only path to modifying a person's own fields is navigating to `PersonFormScreen` in edit mode; `PersonProfileScreen` itself has no editable Person fields, no inline text inputs, and no save action of its own for Person data.
- Below that, the memory timeline: reads `personMemoryTimelineProvider(personUuid)` and renders memories reverse-chronologically.
- If the person has zero active memories, render the full-screen-within-profile empty state from `memory_timeline_empty_state.dart` — distinct from Sprint 1A's Circle-level empty state, scoped to this person only.
- Each memory row navigates to `MemoryFormScreen` in edit mode on tap.
- Each memory row exposes a delete action requiring a confirmation dialog before executing — same UX rule as Sprint 1A's person delete.
- An entry point (e.g. a floating action button) navigates to `MemoryFormScreen` in create mode, with `personUuid` pre-filled from the current profile and no memory selector needed.
- Do not implement category filter chips, search within the timeline, or any sort-order control beyond the fixed reverse-chronological default — out of scope, matching Sprint 1A's precedent of trimming non-essential list controls.

---

## 8. Validation

Implement in `domain/validators/memory_validators.dart` as pure, widget-independent functions — same rule as Sprint 1A's `person_validators.dart`. `memory_form_controller.dart` calls these; `memory_form_screen.dart` only renders the error strings they return.

- `eventText`: required, non-empty after trimming, reasonable max length (1000 characters — a placeholder implementation limit, not a documented product requirement; adjust only if asked).
- `category`: required — the form must not allow save with no category selected.
- `importanceScore`: must be an integer between 1 and 5 inclusive (enforced by the control itself, but validate defensively).
- Date: if the date toggle is on, `dateValue` must be non-null before save; if the toggle is off, `dateValue`/`dateValueRaw` must both be null — the two states must never be inconsistent.
- A failed validation blocks the save call entirely — no partial write to Isar, no navigation away from the form, and the specific field error is shown inline next to the offending field.

---

## 9. Acceptance Criteria

1. `MemoryRepository` is fully implemented against Isar per the Section 4 contract, using `uuid` (both the memory's own and `personUuid`) as the only identities ever exposed outside the local Isar layer.
2. Person Profile screen shows a specific person's active memories, reverse-chronologically, sourced via `personMemoryTimelineProvider`, with all sorting performed in the provider layer.
3. A person with zero memories shows the person-scoped empty state; this is distinct from, and does not affect, Sprint 1A's Circle-level empty state.
4. Adding a memory through `MemoryFormScreen` (create mode) appears immediately in the correct person's timeline and does not appear in any other person's timeline.
5. Editing a memory through `MemoryFormScreen` (edit mode, pre-filled) persists changes and reflects them live.
6. Deleting a memory soft-deletes it: `deletedAt`, `updatedAt`, `syncStatus` all updated; the record disappears from the timeline immediately; it is **not** physically removed from Isar.
7. Save is blocked with inline errors on empty `eventText`, no category selected, or an inconsistent date-toggle state.
8. `uuid` is generated exactly once at creation and never changes; `personUuid` never changes after creation.
9. `sensitivityFlag` is recomputed from `category` on every save via `memory_sensitivity_rules.dart` — never directly editable by the user.
10. No Supabase table is read from or written to for any Memory data — Isar only.
11. No `FollowUp` record is created, read, or modified anywhere in this sprint's code — that entity is untouched until Sprint 3 defines exactly when and how memories generate one.
12. No embedding is generated or stored — `Memory.embedding` stays `null` for every record created this sprint.
13. The app remains fully functional with no network connectivity throughout every flow in this sprint.

---

## 10. Testing Checklist

Run through all of these manually before considering the sprint done:

- [ ] Create a memory with the date toggle off — confirm `datePrecision = none`, `dateValue`/`dateValueRaw` both null, and it sorts by `createdAt` in the timeline.
- [ ] Create a memory with the date toggle on and a specific date picked — confirm `datePrecision = explicit`, `dateValue` stored correctly, and it sorts by that date in the timeline.
- [ ] Create memories in each of the 11 categories and confirm `sensitivityFlag` matches the mapping in Section 6 for each.
- [ ] Edit an existing memory's category and confirm `sensitivityFlag` is recalculated, not carried over from before the edit.
- [ ] Delete a memory and confirm: it disappears from the timeline immediately, but a direct Isar inspection shows the row still present with `deletedAt` set.
- [ ] Create memories for two different people and confirm each person's timeline shows only their own memories — no cross-contamination.
- [ ] View a person with zero memories and confirm the person-scoped empty state renders, not the Sprint 1A Circle-level empty state.
- [ ] Attempt to save with empty `eventText` — confirm it's blocked with an inline error and nothing is written.
- [ ] Toggle the date switch on without picking a date and attempt to save — confirm it's blocked.
- [ ] Edit a memory and confirm its `uuid` and `personUuid` are unchanged after save.
- [ ] Confirm `updatedAt` and `syncStatus` change on both edit and delete, not just create.
- [ ] Put the device in airplane mode and complete a full create → edit → delete cycle successfully.
- [ ] Confirm (via logs or a network inspector) that zero Supabase calls occur during any memory create/edit/delete action.
- [ ] Confirm tapping a person row in the Circle screen now opens `PersonProfileScreen`, not `PersonFormScreen` directly.
- [ ] Confirm editing a person's own details is still possible, now via an action inside `PersonProfileScreen`.

---

## 11. Definition of Done

Sprint 1B is not complete until every item below is checked:

- [ ] `MemoryRepository` implements `watchAllForPerson`, `getByUuid`, `create`, `update`, `softDelete` exactly per Section 4, with no sorting logic inside it.
- [ ] `personMemoryTimelineProvider` performs all chronological sorting; no widget and no repository method contains sort logic.
- [ ] `MemoryFormScreen` is a single shared file handling both create and edit modes via an optional `memoryUuid` parameter plus a required `personUuid` — no separate Add/Edit screens exist anywhere in the codebase.
- [ ] `PersonProfileScreen` exists, shows person info + memory timeline, and its own empty state is distinct from the Circle-level empty state.
- [ ] Delete is soft-delete only — no hard-delete call on a Memory record exists anywhere in this sprint's code.
- [ ] Delete requires a confirmation step before executing.
- [ ] Every create/update sets `updatedAt` and `syncStatus = pending`; create additionally sets `createdAt`; `uuid` and `personUuid` are immutable after creation.
- [ ] `sensitivityFlag` is derived exclusively via `memory_sensitivity_rules.dart`, recomputed on every save, never a user-facing form field.
- [ ] Validation logic lives in `memory_validators.dart` as pure functions, independent of any widget.
- [ ] No new Isar collection, no new field on `Memory`, and no field type change exists anywhere relative to `SCHEMA.md`.
- [ ] No `FollowUp`, embedding, AI provider, or Supabase-table code exists anywhere in this sprint's changes.
- [ ] `circle_screen.dart`'s tap behavior is updated to navigate to `PersonProfileScreen`, with person editing still reachable from within it.
- [ ] The app builds, runs fully offline post-login, and every item in Section 10's Testing Checklist passes.

---

## 12. Things Cursor Should Not Change

- Do not modify `SCHEMA.md`'s `Memory` collection definition, its field names/types, or `enums.dart`. If the form seems to want a field `SCHEMA.md` doesn't define (e.g. an attached photo for a manually typed memory), do not add it — flag it instead.
- Do not modify the folder structure established in `ARCHITECTURE.md` Section 2 or the prior sprint specs.
- Do not touch `data/local/isar/collections/follow_up.dart`, `suggestion_log_entry.dart`, or `connection.dart` — untouched until their own sprints.
- Do not touch anything under `data/remote/supabase/` beyond what Sprint 0 already implemented for auth.
- Do not introduce `IsarLink`/`IsarLinks` for the Memory-Person relationship. It uses the `personUuid` string-field pattern already defined in `SCHEMA.md`, exactly like every other relation in this project.
- Do not change `PersonRepository` or `PersonFormScreen` from Sprint 1A beyond what Section 3 explicitly requires (the Circle screen's tap-navigation change and Person Profile's edit entry point).

---

## 13. Explicit Out-of-Scope Items

- Any AI provider interface, Gemma integration, voice/photo/share-sheet capture modal (Sprint 2).
- Relative/free-text date parsing or any AI-derived date handling — manual entry only supports "no date" or an explicit picked date.
- `FollowUp` creation, reading, or the Suggestion Engine in any form (Sprint 3) — Memory does not generate a `FollowUp` this sprint, period; Sprint 3 will define exactly when and how that happens.
- Semantic search, embeddings, or any search UI (Sprint 4) — `Memory.embedding` stays null.
- Sync engine, Supabase backup mirror tables, or any push/pull logic (Sprint 5).
- Data export, encryption, account deletion (Sprint 6).
- A "restore deleted memory" or trash/undo UI — same rule as Sprint 1A's soft-deleted Person.
- A source/attachment picker (audio file, photo) for a memory — `sourceType` is hardcoded to `text`, `sourceRef` stays null this sprint.
- Category filter chips, in-timeline search, or any sort-order control beyond fixed reverse-chronological.
- Any change to `Connection`, `FollowUp`, or `SuggestionLogEntry` collections.
- Bulk actions, multi-select, or pagination on the memory timeline.

---

## 14. Common Implementation Pitfalls to Avoid

- **Do not create `AddMemoryScreen` and `EditMemoryScreen` as separate files.** One `MemoryFormScreen`, mode determined by whether `memoryUuid` is null.
- **Do not implement sorting inside `MemoryRepository`.** `watchAllForPerson()` filters by `personUuid` and non-deleted status only — chronological order is `personMemoryTimelineProvider`'s job, even though `SCHEMA.md`'s example query sorts inline; this sprint's rule supersedes that example.
- **Do not perform a hard delete.** `softDelete()` only ever sets `deletedAt`/`updatedAt`/`syncStatus` — never call Isar's actual delete/remove operation on a Memory record.
- **Do not filter soft-deleted memories at the UI layer instead of the query layer.** Both `watchAllForPerson()` and `getByUuid()` must exclude deleted records at the query itself.
- **Do not regenerate `uuid` or allow `personUuid` to change on edit.** A `copyWith`-style helper that doesn't explicitly preserve both is a common source of this bug.
- **Do not expose `sensitivityFlag` as an editable form field.** It is always derived, always recomputed on save — never a user choice, never independently persisted across an edit that changes category.
- **Do not build any relative-date input control.** "No date" or a native date picker producing an explicit date are the only two supported states this sprint.
- **Do not create, touch, or even stub out a `FollowUp` record when a memory is saved.** It's tempting to add a "might as well create the follow-up now" shortcut — don't; Sprint 3 owns that decision entirely, including whether it happens at save time at all.
- **Do not generate an embedding "since the field already exists on the schema."** The field existing in `SCHEMA.md` is for Sprint 4 — leave it null this sprint regardless of how easy it looks to fill in early.
- **Do not write anything to a Supabase table for Memory data**, including as a "just in case" pending-sync placeholder — Isar only, this sprint and until Sprint 5.
- **Do not pass Isar's local `Id` through navigation for either `personUuid` or `memoryUuid`.** Only the `String` `uuid` values are ever used across screens or repository lookups.
- **Do not skip the delete confirmation dialog.**
- **Do not leave `circle_screen.dart`'s tap behavior pointed at `PersonFormScreen`.** This is a required change this sprint, not an optional cleanup — verify it explicitly, since it's easy to build the new `PersonProfileScreen` and forget to rewire the entry point to it.
