# SPRINT3_3.md — Phase 3.3: Hybrid Semantic Search
### Architecture and implementation planning document — not an implementation specification

**Status:** Implemented + Phase 3.4 stabilized — see [`SPRINT3_3_IMPLEMENTATION.md`](SPRINT3_3_IMPLEMENTATION.md) and [`SPRINT3_3_QA.md`](SPRINT3_3_QA.md) (**PASS**). Ready for `v0.5.0`.
**Depends on:** Phase 3.1 (`v0.4.0`, shipped, unchanged) and Phase 3.2's findings (`SPRINT3_2_FINDINGS.md`, `ADR-013`).
**Structural note:** this phase absorbs what earlier planning called "Phase 3.4 — hybrid ranking" into one delivery unit, per your framing of Phase 3.3 as "the first production-ready version of Hybrid Semantic Search." What follows Phase 3.3 is a stabilization phase (Section 20 recommends calling it Phase 3.4, mirroring the 2B.8 pattern), not a separate hybrid-ranking phase.

**Fixed inputs — not reopened in this document:**
1. Embedding provider: Gecko-110m-en, 768-dim, via a new dedicated provider (not the LiteRT-LM/Gemma-4 bridge).
2. Keyword search (Phase 3.1) remains the primary, always-on path.
3. Semantic search is an additive signal, never a replacement.
4. `embeddingModelVersion` is part of the production schema.
5. Embedding generation is asynchronous, after successful Memory persistence.
6. Backfill is batched, resumable, opportunistic.
7. Phase 3.1's `SearchProvider`, pluggable-ranking abstraction, and offline-first design are unchanged.

Two findings from the spike are **not decisions to reopen, but real open risks this plan must design around rather than assume away**: (a) RAM/RSS and battery cost of Gecko were never measured, and (b) the retrieval-quality benchmark showed uncomfortably narrow separation between genuine matches (~0.73–0.79 cosine) and an unrelated negative query (~0.65 cosine) on a 7-case set. Both are addressed explicitly below, not glossed over.

---

## 1. Objective

Deliver the first production-ready version of hybrid search: Phase 3.1's keyword search remains the reliable default, and a new semantic layer — built on Gecko-110m-en — adds paraphrase recall on top of it, without ever degrading keyword search's speed, reliability, or the calibrated confidence a user can already place in it.

---

## 2. Scope

- Production `GeckoEmbeddingProvider` behind the existing `EmbeddingProvider` interface.
- `embeddingModelVersion` (and any needed dimension metadata) added to the `Memory` schema.
- Asynchronous, per-capture embedding generation after Memory persistence.
- A batched, resumable, opportunistic backfill for pre-existing memories.
- A tiered hybrid ranking strategy (Section 11) combining keyword and semantic signals, deterministically, with conservative no-match handling given the spike's calibration finding.
- Gecko model management via the existing `ModelCatalog`/`ModelDownloadManager` infrastructure — a new catalog entry, not a new download system.
- A pre-flight measurement task, early in this phase, closing the RSS/battery gaps the spike left open, before wider rollout.

## 3. Explicitly Out of Scope

- Re-implementing or modifying Phase 3.1's keyword `SearchProvider` internals.
- Any change to Phase 3.1's ranking heuristic, empty states, or UI beyond what's needed to render the new Tier 2 result category (Section 11).
- Evaluating alternative embedding providers — Gecko is fixed per Phase 3.2.
- Suggestion Engine / `FollowUp` (Sprint 4).
- Sync/Supabase involvement of any kind — search and embeddings remain entirely local.
- `workmanager` or any OS-level background execution dependency (Section 7 explains why this phase deliberately doesn't need one yet).
- Cross-person "Connection" search (P1, unrelated to this phase).
- A learned/personalized ranking model — the hybrid strategy here is fixed and deterministic (Section 11), not adaptive.

---

## 4. High-Level Architecture

```
Capture / Manual Entry (unchanged)
   → MemoryRepository.create()/update() succeeds
        → EmbeddingQueueController enqueues memory.uuid  (fire-and-forget, non-blocking)

EmbeddingQueueController (new, Riverpod-managed, in-app async — not OS-level background)
   → AI inference mutex (shared with LLM extraction — Section 4a)
        → GeckoEmbeddingProvider.embed(eventText)
             → GeckoInferenceAdapter  (sole flutter_gemma_embeddings import point)
        → MemoryRepository.update()  (writes embedding + embeddingModelVersion)

Search (query time)
   UI → SearchController
        → existing keyword SearchProvider   (Tier 1 — unchanged, always runs, always fast)
        → new SemanticSearchProvider        (Tier 2 — additive, conservative threshold)
        → HybridResultComposer (new, provider layer — merges Tier 1 + Tier 2, never inside either provider)
```

**4a. Shared AI-inference mutex.** Gecko embedding generation and Gemma-4 LLM extraction must never run concurrently on-device — both are real inference workloads, and their combined RAM/CPU cost is one of the exact unknowns this phase needs to resolve (Section 12). A single, simple app-wide mutex/semaphore around "an on-device model is currently running" is the cheapest way to guarantee they never compound: if a capture's extraction call is in flight, embedding generation (whether per-capture or backfill) waits; if backfill is embedding, a capture's extraction call still takes priority and backfill yields. This is new coordination logic Phase 3.3 must add — it didn't exist before because only one on-device model workload existed at a time until now.

---

## 5. Data Flow

1. A Memory is created or updated (any path — manual entry, or any of the four AI capture modes) exactly as today; this write is unaffected by anything in this phase.
2. On successful persistence, `EmbeddingQueueController` enqueues the memory's `uuid`. This is fire-and-forget from the caller's perspective — the confirmation/save UX completes exactly as it does today, with zero added latency.
3. The queue processes entries sequentially (Section 12 explains why not concurrently, given unmeasured RSS), respecting the shared mutex from Section 4a.
4. `GeckoEmbeddingProvider.embed()` returns a 768-dim vector; `MemoryRepository.update()` persists it along with `embeddingModelVersion`.
5. The memory is keyword-searchable from the moment it's saved (Tier 1, unaffected) and becomes semantically searchable (Tier 2-eligible) once this background step completes — there is no user-visible "processing" state for this; it's invisible unless the user searches before it's done, in which case that memory simply isn't yet a Tier 2 candidate (still fully Tier 1-searchable).
6. Backfill (Section 8) runs the same pipeline against every pre-existing memory with a missing or stale `embeddingModelVersion`, opportunistically, whenever the app is foregrounded and idle.

---

## 6. Embedding Lifecycle

- **Created:** on first successful persistence of a new Memory, or retroactively via backfill for pre-existing ones.
- **Valid:** `embedding != null` and `embeddingModelVersion` matches the currently active provider's version string.
- **Stale:** `embeddingModelVersion` is null or doesn't match current — treated as "not yet Tier 2-eligible," not an error. A stale memory remains fully Tier 1-searchable the entire time.
- **Regenerated:** on Memory edit where `eventText` or `category` changes (the fields that meaningfully affect what the embedding represents) — re-enqueue for embedding, same as a fresh create. A user editing only, say, `importanceScore` does not need to trigger regeneration.
- **Invalidated:** if the active embedding provider or model version ever changes in the future (a real possibility, given this project's history), every existing embedding becomes stale by definition via the version-mismatch check — no special migration code needed beyond what backfill already does, since "stale" and "never embedded" are handled by the identical code path.

---

## 7. Production `EmbeddingProvider` Design

- **New files**, following the same discipline `ARCHITECTURE.md`/ADR-010 established for the LLM provider — mirrored, not copied verbatim, since Gecko is a genuinely different vendor package:
  - `lib/ai/providers/gecko/gecko_embedding_provider.dart` — implements `EmbeddingProvider`. No other file may know Gecko exists.
  - `lib/ai/providers/gecko/gecko_inference_adapter.dart` — the **only** file permitted to import `flutter_gemma_embeddings`, exactly mirroring the existing rule that only `litert_inference_adapter.dart` may import `flutter_gemma`. This is a second, parallel vendor boundary, not a relaxation of the first.
- **Model management reuses existing infrastructure**, not a parallel system: a new `ModelCatalog` entry for Gecko (`Gecko_256_quant.tflite`, ~114MB, public URL, checksum), staged progress (Downloading → Verifying → Installing → Preparing) via the existing `ModelDownloadManager`.
- **Gecko's download is independent of and additional to the primary Gemma-4 setup gate** — never bundled into first-run onboarding. Recommended trigger: begin downloading automatically in the background once the primary model setup completes successfully (114MB is a much smaller ask than the 2.4GB primary download, and doing it opportunistically avoids adding a second blocking gate to onboarding) — but the user must be able to see, defer, or decline it from Settings, since it's genuinely optional. A failed or declined Gecko download must never block, degrade, or error any other part of the app — it simply means Tier 2 results don't exist yet.
- **Availability resolution:** `activeEmbeddingProvider` resolves to `GeckoEmbeddingProvider` only once the model is downloaded, verified, and ready; otherwise it resolves to a null-object `NoOpEmbeddingProvider` (mirroring `ManualFallbackProvider`'s existing pattern) whose `embed()` simply never gets called by the queue controller — no error path needed, just an inactive queue.
- **Why not fold Gecko into the LiteRT provider family:** Gecko is a different artifact format (`.tflite`, not `.litertlm`), a different package (`flutter_gemma_embeddings`, not `flutter_gemma_litertlm`), and a genuinely different model family. Naming it `LiteRtEmbeddingProvider` would misleadingly imply it shares the Gemma-4/LiteRT-LM bridge (ADR-010/011) when it doesn't — a distinct `gecko/` folder keeps that boundary honest.

---

## 8. Schema Updates Required

Additive, low-risk changes to `Memory` in `SCHEMA.md` and the Isar collection:

```dart
// additions to Memory, per ADR-013
String? embeddingModelVersion;   // e.g. "gecko-110m-en-seq256-v1"; null = not yet embedded / stale
```

- **Migration risk is low:** adding a new nullable field to an existing Isar collection is an additive, backward-compatible schema change — existing rows simply have `embeddingModelVersion == null`, which is exactly the "needs backfill" signal this design already relies on. No destructive migration, no data loss risk.
- **Index recommendation:** add `@Index()` on `embeddingModelVersion` to make "find everything needing backfill" (`embeddingModelVersionIsNull()` or not-equal-to-current) an efficient query rather than a full collection scan, since backfill will run this query repeatedly across a potentially large corpus.
- **Dimension is not stored per-record** — 768 is fixed by the chosen provider and documented, not re-derived at query time. If a future provider changes dimension, that's exactly what the version-mismatch check (Section 6) already handles.
- **No Postgres backup-mirror change needed yet** — that table stays dormant until Sprint 5, per every prior sprint's boundary; when Sprint 5 does stand it up, it should include the same `embedding_model_version` column for consistency, but that's a note for later, not this phase's work.

---

## 9. Backfill Architecture

Directly implementing the spike's own recommendation (`SPRINT3_2_FINDINGS.md` §5), not redesigning it:

- **Batched:** 10–25 memories per processing tick, never the full corpus in one pass.
- **Resumable / idempotent:** driven by the same `embeddingModelVersionIsNull()`-or-stale query used for lifecycle tracking (Section 6) — interrupting and restarting the app simply re-runs the same query and continues; no separate progress-tracking state needed beyond what the schema already provides.
- **Opportunistic, scoped to what's actually achievable without new infrastructure:** since `workmanager` is deliberately not being added this phase (Section 3), backfill only progresses while the app is foregrounded and not actively capturing — there is no OS-level background execution. This is an explicit, accepted trade-off (Section 17), not an oversight.
- **Respects the AI-inference mutex (Section 4a):** backfill always yields to an in-progress capture's extraction call.
- **Progress UI is conditional, not default:** only shown if the estimated remaining time for the user's actual corpus exceeds roughly 30–60 seconds (using the spike's ~172ms/item warm latency as the estimate basis) — for small corpora, backfill should be invisible and simply finish.
- **Tiny corpora get simpler treatment:** given ~172ms per item, a corpus under roughly 50–100 memories can reasonably backfill as a single foreground burst the first time the app opens post-update, rather than needing the full opportunistic-scheduling machinery — worth confirming this threshold against Section 12's real measurements rather than the number stated here provisionally.

---

## 10. Hybrid Ranking Strategy

Deliberately **tiered, not blended**, chosen specifically because of the spike's calibration finding (narrow separation between genuine and negative-query scores):

- **Tier 1 — keyword matches.** Exactly Phase 3.1's existing ranking, completely unmodified. Always computed, always shown first, never suppressed or reordered by anything semantic.
- **Tier 2 — semantic-only matches.** Memories that clear a conservative similarity threshold (Section 11) but were **not** already found by keyword matching, appended below Tier 1 results, visually and semantically distinguished (e.g. "possibly related") — never interleaved with or reordering Tier 1.

**Why tiered instead of a single blended numeric score:** a blended formula (e.g. `keyword_score + w * semantic_score`) requires trusting the semantic score's absolute magnitude to combine sensibly with keyword's — and the spike's own data shows that trust isn't earned yet (a negative query scored ~0.65, only ~0.08–0.14 below genuine matches). A tiered design sidesteps this entirely: Tier 1's reliability is untouched by however uncalibrated Tier 2 turns out to be, and if Tier 2 needs to be disabled entirely later, that's a one-line change with zero effect on Tier 1 — the same rollback property already committed to in the Phase 3.2 plan.

---

## 11. Keyword + Semantic Score Combination

- No numeric combination — see Section 10's rationale. Tiering *is* the combination strategy.
- **Tier 2 threshold:** a conservative absolute cosine-similarity cutoff, set meaningfully above the spike's observed negative-query score (~0.65) — a provisional starting point of **0.75** is reasonable given the spike's paraphrase matches ranged ~0.73–0.79, but this number is a hypothesis, not a settled constant. It must be validated against a larger, more realistic benchmark early in this phase (Section 18) before being trusted in production, and explicitly logged/reviewable so it can be tuned without a code change if it proves wrong.
- **A memory already present in Tier 1 is never duplicated into Tier 2**, even if it also clears the semantic threshold — Tier 2 exists specifically to surface what keyword search *missed*.
- **If Tier 1 already returned strong results, Tier 2 may be suppressed entirely for that query** (or shown but visually deprioritized) — a query with several solid keyword hits has less need for uncertain semantic additions; this is a UX-tuning decision to make during QA (Section 18), not fixed rigidly here.

---

## 12. No-Match Handling / Threshold Calibration

- **Absolute score alone is not trusted**, per the spike's finding. The Section 11 threshold is a starting hypothesis requiring real recalibration, not a final answer.
- **Recalibration plan:** by the time this phase ships, Phase 3.1's search-query log will have real usage data it didn't have during the spike (the spike explicitly notes this log was never ingested). Building a larger relevance benchmark from real, on-device, anonymized queries — mixed with the spike's synthetic set — is a required early task in this phase (Section 18), not an optional polish item.
- **Zero Tier 2 results is a normal, expected outcome**, not a failure state — if nothing clears the conservative threshold, the search simply shows Tier 1 results (or Phase 3.1's existing empty state if Tier 1 also has nothing). Never lower the bar just to avoid an empty Tier 2 section.
- **A query that fails to embed (e.g., a transient inference error) degrades to Tier 1 only**, silently — never an error surfaced to the user for what is, from their perspective, still a completely functional search.

---

## 13. `SearchProvider` Integration

- Phase 3.1's keyword `SearchProvider` is consumed **unmodified** — a new `SemanticSearchProvider` (implementing a comparable, parallel contract, not literally the same interface unless a natural shared shape exists) is added alongside it, and a new `HybridResultComposer` in the provider/controller layer (not inside either provider — per ADR-003's repository/provider boundary discipline, extended here to a search-orchestration boundary) merges their outputs per Section 10's tiering rule.
- This preserves the exact same rollback property already promised in Phase 3.2's plan: disabling semantic search means removing `SemanticSearchProvider` from the composition, with zero change required to the keyword path.
- Person-scoped and global search both compose the same way — `SemanticSearchProvider`'s candidate pool is scoped identically to how Phase 3.1's keyword provider already scopes (whole Circle vs. one person), so cross-person isolation is inherited, not reimplemented.

---

## 14. Performance Expectations

- **Tier 1 (keyword) latency is unaffected** — this is a hard requirement, not an aspiration; Section 18's QA explicitly re-verifies Phase 3.1's existing numbers show no regression.
- **Tier 2 adds real latency**, bounded by: one query-embedding generation (~172–187ms per the spike's single-call measurement) plus a brute-force cosine scan across the corpus (expected to be low-single-digit milliseconds at realistic corpus sizes, per the same reasoning already established in `SCHEMA.md`'s original search design — but **not yet measured end-to-end against a real corpus**, which the spike didn't do). A provisional target of **under ~500ms total added latency** for Tier 2 is reasonable given the components, but must be measured, not assumed, as an early task in this phase.
- **Capture-latency protection is non-negotiable** — per-capture embedding generation runs strictly after persistence, off the critical path; Section 18's QA re-runs the existing capture-latency regression tests every prior phase has protected.

---

## 15. Memory and Storage Considerations

- **Per-embedding storage is negligible:** 768 × 4 bytes = 3,072 bytes; ~14.6MB total Isar growth even at 5,000 memories, per the spike's own extrapolation. Not a design concern.
- **Cumulative download size becomes real:** Gemma-4 (~2.4GB) + Gecko (~114MB) ≈ 2.5GB+ total. Given Gecko is optional and additive, users on constrained storage/data plans should be able to see this cost and decline it (Section 7) rather than have it silently added to their device.
- **RAM/RSS footprint during embedding generation is the biggest open unknown entering this phase** — the spike explicitly did not measure it. This must be resolved as a pre-flight measurement task (Section 18) before this phase's design can be fully trusted, particularly because it interacts directly with `ARCHITECTURE.md`'s still-uncalibrated device-tiering thresholds (a gap flagged in the earlier architecture review and still open) — Gecko's real footprint, especially if it's ever resident simultaneously with Gemma-4, is direct evidence for that recalibration, whether or not this phase does the recalibration itself.

---

## 16. Failure and Recovery Behavior

| Failure | Behavior |
|---|---|
| Gecko download fails or is declined | App fully functional via Tier 1 keyword search; retry available from Settings; never blocks any other feature. |
| Embedding generation fails for a specific memory (transient error) | Memory stays Tier 1-searchable; entry remains eligible for retry on the next queue pass — bounded retry/backoff, not an infinite loop, not a silent permanent skip. |
| Backfill interrupted (app closed/killed mid-pass) | Resumes automatically via the same `embeddingModelVersionIsNull()`-driven query on next foreground/idle window — no separate resume-state bookkeeping needed. |
| Query embedding generation fails at search time | Silently degrade to Tier 1-only results for that query — never an error shown to the user. |
| Mixed embedding versions in the corpus (e.g. after a future provider change) | Stale-version embeddings are excluded from Tier 2 candidacy (treated as not-yet-embedded) until re-embedded — never compared across incompatible versions/dimensions. |
| AI-inference mutex contention (capture extraction and embedding both wanting to run) | Capture extraction always wins; embedding (per-capture or backfill) waits and resumes after. |

---

## 17. Accessibility Considerations

- Tier 2 ("possibly related") results must be distinguished for screen-reader users through actual semantics — an announced label ("possibly related result"), not only a visual badge or color difference.
- Any loading state introduced by Tier 2's added latency (Section 14) should be announced consistent with the existing accessible loading-copy pattern already established for Capture's "Finding memories…" status, not a silent spinner.
- The Gecko download prompt (Settings) follows the same accessible patterns already used for the primary model setup gate — no new pattern invented for a smaller, "just as important to some users" download.

---

## 18. Risks and Trade-offs

| Risk/trade-off | Notes |
|---|---|
| RSS/battery cost genuinely unknown entering this phase | Must be resolved via an early pre-flight measurement task, not assumed; direct input to both this phase's own tiering decisions and the still-open `ARCHITECTURE.md` Section 7 recalibration. |
| Calibration threshold (0.75 provisional) is a hypothesis, not validated at scale | Requires a larger benchmark, ideally incorporating real Phase 3.1 query-log data, before being trusted in production — explicitly called out as an early task, not deferred to "someday." |
| Cumulative download size (~2.5GB+) | Mitigated by making Gecko optional/declinable; a real cost nonetheless, worth being upfront about in UI copy. |
| No OS-level background execution (`workmanager` deliberately not added) | Backfill only progresses while the app is open and idle — a deliberate, accepted trade-off for lower complexity and no new dependency; revisit only if real backfill completion times prove this inadequate for real corpora. |
| Resource contention between simultaneous on-device model operations | Addressed via the shared AI-inference mutex (Section 4a) — new coordination logic this phase must add, since it never previously needed to exist. |
| Tiered (not blended) ranking is simpler but less "smart" | A deliberate trade-off favoring determinism and safety over sophistication, consistent with the instruction to avoid unnecessary complexity — revisit only with real evidence tiering is insufficient. |

---

## 19. Acceptance Criteria

1. `GeckoEmbeddingProvider` implements `EmbeddingProvider`; only `gecko_inference_adapter.dart` imports `flutter_gemma_embeddings`.
2. Gecko model management reuses the existing `ModelCatalog`/`ModelDownloadManager` staged-progress flow; download is independent of and never blocks the primary model setup gate.
3. `embeddingModelVersion` is added to `Memory` and used consistently as the single source of truth for "needs backfill"/"stale" status.
4. Per-capture embedding generation is fully asynchronous and provably adds zero latency to the existing save/confirmation path.
5. Backfill is batched, resumable (verified via a kill-and-restart test), and respects the AI-inference mutex.
6. Search results render as two clearly distinguished tiers; Tier 1 output and ranking are byte-for-byte identical to Phase 3.1's current behavior.
7. Tier 2 never shows a memory already present in Tier 1.
8. The Tier 2 threshold is documented, tunable without a code change, and validated against a benchmark built from real query-log data before being trusted as a production default.
9. A failed or declined Gecko download, a failed embedding generation, and a failed query-time embedding all degrade gracefully to Tier-1-only behavior — none produce a user-visible error.
10. RSS and battery cost of embedding generation are measured on the reference device and documented — not left as an open unknown at ship time.
11. All of this works fully offline; nothing in this phase makes a network call except the one-time Gecko model download.

---

## 20. Definition of Done

- [ ] Every item in Section 19 verified.
- [ ] Pre-flight RSS/battery measurement complete and documented (Section 12/15/18).
- [ ] Tier 2 threshold recalibrated against a real-data-informed benchmark, not shipped on the spike's provisional 0.75 alone.
- [ ] Capture-latency regression suite re-run and shows no regression.
- [ ] `SCHEMA.md`, `ARCHITECTURE.md`, `BACKLOG.md`, `DEVLOG.md`, `CHANGELOG.md`, `CURSOR_HANDOFF.md` all updated to reflect this phase's additions.
- [ ] A short QA/acceptance summary produced (Section 21) — doesn't need 2B.8's full weight, but should exist as a real, reviewable artifact, not just "it felt done."

---

## 21. QA Strategy

- **Relevance/calibration benchmark, expanded:** the spike's 7-case set plus real, anonymized queries drawn from Phase 3.1's live search-query log — large enough to make the Tier 2 threshold a real, evidence-based number rather than the provisional 0.75.
- **Latency measurement:** Tier 1 alone (regression check against Phase 3.1's existing numbers), Tier 2 alone, and combined — on the same reference device used throughout this project for comparability.
- **RSS and battery measurement:** the two gaps the spike explicitly left open — both mandatory here, not optional.
- **Backfill verification:** kill-and-restart mid-backfill, confirm resumption with no duplicate work and no skipped records; verify the AI-inference mutex correctly pauses backfill during an active capture.
- **Capture-latency regression:** re-run Sprint 2B.8's existing warm/cold capture timing tests.
- **Offline verification:** full search and capture flow, airplane mode, at every step.
- **Accessibility spot-check:** Tier 2 announcement behavior, loading-state announcements, Gecko download prompt.
- **Cross-person isolation:** confirm hybrid results respect person-scoped vs. global search boundaries identically to Phase 3.1.
- **Failure-path verification:** each row of Section 16's table exercised directly, not just reasoned about.

---

## 22. Exit Criteria

This phase is complete when Section 20's Definition of Done is fully checked and the QA summary (Section 21) is documented and reviewed — not when the engineering "feels done," consistent with every prior phase's exit-criteria discipline. Specifically: **the Tier 2 threshold must be backed by real calibration data, not the provisional spike-derived number, before this phase can be considered exited** — shipping on an unvalidated threshold would mean the single biggest risk this document identified (Section 18) was never actually closed.

---

## 23. Handoff Criteria for the Next Phase

Recommend the next phase be a short **stabilization pass** (call it Phase 3.4, mirroring the 2B.8 pattern that's already proven valuable for exactly this kind of gate) rather than proceeding directly into Sprint 4 planning — covering: real-world E2E regression across Typed/Voice/OCR/Share combined with search, a longer soak test of the AI-inference mutex under realistic mixed capture+search+backfill usage, and documentation close-out. Sprint 4 (Suggestion Engine) planning should not begin until:

1. This phase's Definition of Done (Section 20) is fully met.
2. The recalibrated Tier 2 threshold is in production, not the provisional one.
3. RSS/battery numbers are documented and feed into (or explicitly close out) the still-open `ARCHITECTURE.md` Section 7 device-tiering recalibration.
4. No open P0/P1-equivalent issues remain from Section 21's QA pass.

---

**Next step:** Implement Phase 3.3 only when explicitly kicked off, using [`SPRINT3_3_IMPLEMENTATION.md`](SPRINT3_3_IMPLEMENTATION.md) as the binding implementation brief. Do not start Phase 3.4 or Sprint 4 from this document alone.
