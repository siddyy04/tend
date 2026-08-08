# FOUNDATION CLEANUP — Pre-Sprint 3 Architecture Debt Removal

**Status:** Complete
**Purpose:** Remove the specific architectural debt that Sprint 3 (Suggestion Engine / Today's Opportunities) would otherwise silently build on top of. This is not a feature sprint, not a rescoped Sprint 2, and not the 2B.8 RC gate — it is a small, independent unit of work that sits between them.
**Sequencing:** This plan is independent of Sprint 2B.8. Recommended order remains: **Foundation Cleanup → finish 2B.8 RC gate → Sprint 3 planning**, but nothing here blocks or is blocked by 2B.8's QA work — they touch different code.

---

## 0. Scope discipline — what's deliberately NOT in this cleanup, and why

Six items came up in the architecture review. Only three are in scope here. The other three are real, but none of them are things Sprint 3 needs to be *correct* — they're either bigger than "cleanup," or they're Sprint 3's own first design question, not pre-existing debt.

| Item | Why it's excluded from this cleanup |
|---|---|
| Person → memory cascade delete | Real feature work (a transactional multi-collection soft-delete), not a small fix — already correctly scoped to data-controls work. Sprint 3 doesn't need it *implemented*; it needs FollowUp scoring to not trust deleted people, which is a one-line defensive filter that belongs in Sprint 3's own scoring query, not here. |
| Deciding when a Memory generates a FollowUp | This is Sprint 3's first actual design question, not debt from a prior sprint. Nothing today is "wrong" because this hasn't been decided — deciding it now, before there's a scoring engine to decide it *for*, risks designing it in a vacuum. |
| `ARCHITECTURE.md` RAM-tier numbers vs. measured Gemma 4 E2B footprint; `DEVELOPMENT_ROADMAP.md`/`FEATURES.md` staleness | Real, but Sprint 3 (rule-based, no model inference) doesn't depend on either being correct to function. Worth doing soon, but doing it here would violate "keep this small" for no Sprint-3-blocking reason. |

The three items below are different in kind: each one is something Sprint 3 will either **read a contradiction from**, **silently inherit wrong data through**, or **accidentally call a known-buggy method via**, if left unresolved.

---

## 1. Mandatory Items

### Item A — Resolve the `FollowUp.deletedAt` schema contract

**What:** `ARCHITECTURE.md`'s `FollowUp` collection sketch includes `deletedAt`; `SCHEMA.md`'s `FollowUp` collection does not. Pick one contract and make every reference to `FollowUp` agree.

**Recommendation:** Add `deletedAt` to `FollowUp`. This is the right call, not just the convenient one — every other syncable collection in the project (`Person`, `Memory`) is soft-deleted per ADR-005, and `ARCHITECTURE.md`'s Sync Architecture section (Section 5) describes tombstone-based deletes as a universal pattern, not one that stops at `FollowUp`. Leaving `FollowUp` hard-delete-only would be the one collection that breaks the pattern for no stated reason.

**Why it can't wait:** Sprint 3 *is* the sprint that first writes real `FollowUp` rows. If the contract is still ambiguous when that code gets written, Cursor has to guess — and guessing wrong here is exactly the kind of thing that's cheap today (zero `FollowUp` rows exist anywhere) and expensive later (a real migration once Sprint 5 sync and real user data are riding on the answer).

**Migration/compatibility considerations:** None. `FollowUp` has zero rows in the codebase today — no sprint has written to it yet. This is a pure documentation-and-schema-definition fix, not a data migration.

**Acceptance criteria:**
1. `SCHEMA.md`'s `FollowUp` Isar collection includes `DateTime? deletedAt`, matching `ARCHITECTURE.md`'s sketch exactly.
2. `SCHEMA.md`'s Postgres backup-mirror `follow_ups` table definition includes a matching `deleted_at timestamptz` column (even though Sprint 5 hasn't built the mirror yet — the schema text itself must not contradict itself).
3. `BACKLOG.md`'s "FollowUp schema review" and "FollowUp.deletedAt SCHEMA vs ARCHITECTURE" entries are marked resolved, with a one-line pointer to this decision.
4. Grep both documents for `FollowUp` — no remaining field-set disagreement between them.

---

### Item B — Deterministic relative-date resolution (`dateValueRaw` → `dateValue`)

**What:** Currently, when `datePrecision == relative` (e.g. "next week," "yesterday"), only the literal phrase is stored in `dateValueRaw`. Nothing resolves it into an actual `DateTime` in `dateValue`. Implement a pure, deterministic resolver — in app code, not the model, per the existing `BACKLOG.md` proposal — and run it on every Memory save (manual entry and AI capture alike), plus a one-time backfill for existing rows.

**Why it can't wait:** Today's Opportunities' entire timing model — when a follow-up window opens, how staleness decays, what "next week" means for surfacing a suggestion — depends on having a real date to compute against. Right now, any memory captured with a relative date phrase has no usable `dateValue` at all. This isn't a nice-to-have refinement Sprint 3 can layer on later; it's a precondition for Sprint 3's scoring logic to work for a meaningful fraction of real captures.

**Design constraint worth stating explicitly:** the resolver must be anchored to the memory's own `createdAt`, not to wall-clock "now" at whatever moment the resolver runs. For a live capture these are effectively the same moment, so it's easy to miss that they're conceptually different — but the backfill pass (below) makes the distinction concrete: a memory captured three days ago saying "started physiotherapy yesterday" must resolve against *its own* `createdAt`, not against today's date, or the backfill would silently shift every historical relative date forward by however long it's been sitting unresolved.

```dart
// lib/domain/rules/date_resolution_rules.dart (new — same pattern as memory_sensitivity_rules.dart, per ADR-008)
DateTime? resolveRelativeDate({
  required String rawPhrase,
  required DateTime anchorDate,   // Memory.createdAt — NEVER DateTime.now() for backfill
});
```

**Migration/compatibility considerations:** Real, unlike Item A. Dev/testing usage across Sprints 1B/2A/2B has almost certainly already produced Memory rows with `datePrecision == relative` and `dateValue == null`. This cleanup includes a **one-time backfill pass**: query all such rows, resolve each using its own `createdAt` as the anchor, write the result. This should run once (e.g. behind a small migration/startup check, or a debug-triggerable one-off script — implementation detail for whoever picks this up) and be idempotent (safe to run twice without corrupting already-resolved rows — skip any row where `dateValue` is already non-null).

**Acceptance criteria:**
1. `resolveRelativeDate()` exists as a pure function in `domain/rules/`, unit-testable with no Isar/widget dependency, matching the existing `memory_sensitivity_rules.dart` pattern.
2. Both Memory save paths (manual entry via `MemoryFormScreen`/`memory_form_controller.dart`, and AI capture via the confirmation save flow) call it whenever `datePrecision == relative`, and populate `dateValue` before writing to Isar.
3. Explicit resolution for at minimum: "today," "yesterday," "tomorrow," "next week," "last week," "next month," "next [weekday]," "in N days/weeks/months" — matching the phrase set already exercised in `EXTRACTION_COMPLETENESS_BENCHMARK.md`'s C5 case.
4. An unresolvable phrase (doesn't match any known pattern) leaves `dateValue` null rather than guessing — this must fail safe, not fail wrong.
5. The backfill pass runs once, is idempotent, and resolves every existing `dateValue == null` + `datePrecision == relative` row using that row's own `createdAt` as the anchor — verified by spot-checking a handful of pre-cleanup rows before/after.
6. `BACKLOG.md`'s "AI / Date Resolution" entry is marked resolved.

---

### Item C — Fix `PersonRepository.getByUuid()`'s soft-delete leak

**What:** `MemoryRepository.getByUuid()` already correctly excludes soft-deleted rows at the query layer (`uuidEqualTo` + `deletedAtIsNull`). `PersonRepository.getByUuid()` does not — it still returns tombstoned people via the unique-index helper. Align Person with Memory's existing correct pattern.

**Why it can't wait:** This is the smallest item in this plan, and it's here specifically because Sprint 3 is exactly the kind of feature that's likely to need a fresh Person lookup by uuid (e.g. building "why this surfaced" copy, or resolving a FollowUp's `personUuid` back to a display name). The known-buggy method will be sitting right there, and reusing it by habit is a much easier mistake to make while writing new Sprint 3 code than while everyone still remembers the workaround. Fixing it now, while nothing depends on the current (wrong) behavior, removes the trap before Sprint 3 can walk into it.

**Migration/compatibility considerations:** None functionally — this changes query behavior, not stored data. One verification step: confirm no existing call site intentionally relies on `getByUuid()` returning a soft-deleted record (none should, per `BACKLOG.md`'s own note that Capture already works around this via `allPeopleProvider` rather than depending on it).

**Acceptance criteria:**
1. `PersonRepository.getByUuid()` filters `uuidEqualTo(uuid)` **and** `deletedAtIsNull()`, matching `MemoryRepository.getByUuid()` exactly.
2. A soft-deleted Person's uuid passed to `getByUuid()` returns `null`, verified with a direct test.
3. Grep every existing call site of `PersonRepository.getByUuid()` in the codebase and confirm none regresses — none should have been relying on the leaked behavior.
4. `BACKLOG.md`'s "PersonRepository.getByUuid hides soft-deleted records" and the matching "Repository consistency" tech-debt entry are marked resolved.

---

## 2. Recommended Implementation Order

1. **Item A (FollowUp schema contract)** — first, because it's pure documentation/schema-definition with zero data risk, and it removes the one contradiction that's explicitly called out as a hard blocker in the project's own docs.
2. **Item C (`getByUuid` fix)** — second, for the same reason: small, mechanical, zero data migration, independent of the other two.
3. **Item B (date resolution + backfill)** — last, deliberately. It's the only item with real logic and a real data migration, so it benefits from landing on top of an already-consistent schema and repository layer rather than in parallel with them.

None of the three have a hard dependency on each other — this order is about doing the cheapest, lowest-risk fixes first and saving the one genuinely new piece of logic for last, not about one blocking another.

---

## 3. Definition of Done — Foundation Cleanup phase

- [x] Item A: `SCHEMA.md` and `ARCHITECTURE.md` agree on `FollowUp`'s full field set, including `deletedAt`; `BACKLOG.md` entries resolved.
- [x] Item C: `PersonRepository.getByUuid()` excludes soft-deleted records, verified by test; `BACKLOG.md` entries resolved.
- [x] Item B: `resolveRelativeDate()` exists, is called from both Memory save paths, and the one-time backfill has run and been spot-verified; `BACKLOG.md` entry resolved.
- [x] No new features, screens, or FollowUp-writing code were introduced — this phase touched schema consistency, one repository method, and one new pure domain-rule function plus its call sites. Nothing else.
- [x] `DEVLOG.md`/`CHANGELOG.md` record this as its own entry (e.g. "Foundation Cleanup — pre-Sprint 3"), distinct from both 2B.8 and Sprint 3, so the project history doesn't blur "bug fix" into "feature sprint."
- [x] `CURSOR_HANDOFF.md` updated: cleanup complete, next is still **2B.8 RC gate**, Sprint 3 planning unchanged and still gated on RC Go.

This phase does not change, accelerate, or bypass the Sprint 2B.8 gate. Once this is done, the plan reverts to exactly what it was: finish 2B.8 → Release Readiness Report reaches Go → Sprint 3 planning resumes.
