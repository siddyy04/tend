# Tend — Development Roadmap (Cursor / Flutter build order)

**Status:** Living roadmap — last aligned **pre–Sprint 4** (after Sprint 3 Search close-out / docs sync).  
**Authoritative for day-to-day status:** [`CURSOR_HANDOFF.md`](CURSOR_HANDOFF.md). Binding architecture / schema / features: `ARCHITECTURE.md`, `SCHEMA.md`, `FEATURES.md`. Per-sprint specs win for historical “what was in scope” detail.

**How to use this with Cursor:** treat this file as the **sequence and status map**. For implementation work, open the binding sprint spec for that slice (e.g. `SPRINT3_3.md`), not only this summary. Do not implement a future sprint until its Cursor-facing spec exists and is approved.

**Stack (ADR-0001 / ADR-011 / ADR-013):** Flutter · `isar_community` (local SoT) · `flutter_riverpod` · `go_router` · `flutter_gemma` + `flutter_gemma_litertlm` (Gemma 4 extraction via `LiteRtInferenceAdapter` only) · `flutter_gemma_embeddings` (Gecko via `GeckoInferenceAdapter` only) · `supabase_flutter` (auth + optional backup) · `workmanager` (future sync + Suggestion Engine). Collection fields: **`SCHEMA.md` only**.

---

## Current position

| Item | State |
|---|---|
| Milestone | **`v0.5.0`** — Capture RC + hybrid Search (Phase 3.4 PASS). Commit/tag when asked. |
| Shipped | Sprint 0 → 1A → 1B → 2A/2B (Capture) → Foundation Cleanup → Sprint 3 Search (3.1–3.4) |
| Next | **Sprint 4 — Suggestion Engine / Today's Opportunities** — **planning only** until a Sprint 4 spec is approved |
| Later | Sprint 5 Sync → Sprint 6 Data controls / polish → P1 |

**Why Search before Suggestion Engine:** early beta has few memories old enough for resurfacing payoff; Search delivers value in the same session as capture. Search-query logs also inform what is worth suggesting later. See [`SPRINT3.md`](SPRINT3.md) §0. (Original Bible order had Suggestion Engine as Sprint 3 — deliberately swapped.)

---

## Executed sequence (done)

### Sprint 0 — Project Setup ✅
Auth (Supabase), Isar schema from `SCHEMA.md`, navigation shell (My Circle / Today / Search stubs). Spec: `SPRINT0.md`.

### Sprint 1A — Person CRUD ✅
My Circle, Person add/edit/soft-delete, no memories/AI. Spec: `SPRINT1A.md`.

### Sprint 1B — Manual Memory CRUD + Person Profile ✅
Timeline + manual memory forms; person→memory cascade **deferred** (`BACKLOG.md`). Spec: `SPRINT1B.md`.

### Sprint 2 — On-Device Capture + AI Extraction ✅
Split into **2A** (text capture + LiteRT extraction + confirmation) and **2B.1–2B.8** (multi-memory, Create Person, voice/OCR/share, clarification, Capture RC).

| Slice | Outcome |
|---|---|
| Production extraction | `LiteRtExtractionProvider` + **Gemma 4 E2B** (LiteRT-LM); optional E4B in catalog (ADR-010/011) |
| Capture modes | Typed, Voice (platform STT), OCR (ML Kit), Share → shared `CaptureSubmitFlow` |
| RC | **Go** — [`RELEASE_READINESS_REPORT.md`](RELEASE_READINESS_REPORT.md) |
| Specs | `SPRINT2A.md`, `SPRINT2B.md` … `SPRINT2B8.md` |

Embeddings were **not** part of Sprint 2 (interface only until Sprint 3).

### Foundation Cleanup (pre–Sprint 3) ✅
`FollowUp.deletedAt` schema alignment; `PersonRepository.getByUuid` soft-delete filter; relative-date resolution + backfill. See `FOUNDATION_CLEANUP.md`.

### Sprint 3 — Local Search (keyword → hybrid) ✅ → `v0.5.0`
Phases (keyword-first, then semantic) per [`SPRINT3.md`](SPRINT3.md):

| Phase | What shipped | Spec / artifact |
|---|---|---|
| **3.1** | Global + person-scoped **keyword** Search; `SearchProvider`; query log | `SPRINT3_1.md` |
| **3.2** | Embedding spike → **Conditional Go** for **Gecko-110m-en** (not Gemma 4 embed) | `SPRINT3_2.md`, `SPRINT3_2_FINDINGS.md`, ADR-013 |
| **3.3** | Tiered hybrid: keyword Tier 1 + Gecko Tier 2; async embed queue; backfill; mutex | `SPRINT3_3.md`, `SPRINT3_3_IMPLEMENTATION.md` |
| **3.4** | Stabilization PASS; threshold **0.70**; M7 via `releaseResident()` before extract | `SPRINT3_3_QA.md` |

**Out of Sprint 3 (intentional):** Suggestion Engine, FollowUp creation from capture, sync, ANN indexes.

---

## Upcoming sequence (not started)

### Sprint 4 — Suggestion Engine / Today's Opportunities 🔜 Next
**Goal:** resurfacing half of the magic loop — local, rule-based, offline.

**Status:** Planning only. No implementation until a Cursor-facing Sprint 4 spec is written and approved (mirror `SPRINT3.md` → phase specs).

**Intended scope (from original design / `FEATURES.md` — refine in the Sprint 4 spec):**
- Rule-based scoring as a local scheduled task (`workmanager`) over Isar — no cloud job
- Today's Opportunities UI: hard cap of 5; “why this surfaced”; act / dismiss / not-now → `SuggestionLogEntry`
- Local push notifications for the daily digest (`flutter_local_notifications`)
- Hard exclusions: no suggestion without a grounding memory; no batch/productivity framing; no fabricated emotional language
- Product design still open: **when does a Memory generate a FollowUp?** — deferred through Sprints 2–3 on purpose

**Inputs that should shape the spec:** real capture patterns, relative-date behavior, and Sprint 3 **search-query logs** (what people try to recall).

**Done when:** a short, specific daily digest works fully offline; dismissed/acted items stop reappearing per suppression rules.

### Sprint 5 — Sync Engine
Opt-in backup / multi-device sync (default **OFF**). Supabase mirror from `SCHEMA.md`; push/pull by `uuid`; last-write-wins on `updatedAt`; tombstone deletes. Enabling sync must never block core capture/search.

### Sprint 6 — Data Controls, Encryption, and Polish
Isar encryption (verify `isar_community` support), `flutter_secure_storage`, export/delete (including **person→memory cascade** from `BACKLOG.md`), empty states, onboarding polish. **Done when:** every P0 acceptance criterion in `FEATURES.md` is met.

### Sprint 7+ (P1 — after MVP beta validates the core loop)
From `FEATURES.md` P1: Connection layer, calendar, email forwarding, shared circles (implies revisiting last-write-wins), learned suggestion weighting, vision captioning, fine-tuned small function-caller swap once real extraction examples exist.

---

## Dependency notes (why this order)

- **1A → 1B → 2:** prove Person, then Memory, then AI on top of a stable model (ADR-009 manual-first).
- **2 model management before extraction UI:** graceful degradation is foundation, not retrofit.
- **2 before 3 (Search):** search over an empty corpus demonstrates nothing.
- **3 (Search) before 4 (Suggestion Engine):** early-usage value + calibration data before proactive resurfacing (`SPRINT3.md` §0).
- **4 before 5:** retention loop does not require sync; sync must not become a dependency for core value.
- **5 before 6:** export/delete/encryption must account for the sync/tombstone path.

---

## Historical note (original roadmap numbering)

An earlier draft of this file numbered **Sprint 3 = Suggestion Engine** and **Sprint 4 = Semantic Search**. Product Sprint 3 executed Search instead; Suggestion Engine is now Sprint 4. Frozen sprint markdown under `SPRINT2*.md` may still mention the old order — follow this file + `CURSOR_HANDOFF.md` for the live sequence.
