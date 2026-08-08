# SPRINT3_3_QA.md — Phase 3.3 / 3.4 acceptance summary

**Date:** 2026-08-08  
**Spec:** `SPRINT3_3_IMPLEMENTATION.md` / architecture `SPRINT3_3.md`  
**Device:** AIN065 (reference)  
**Harness:** `lib/debug/phase34_stabilization_main.dart` (**release** build)  
**Stabilization status:** **PASS** — Phase 3.3/3.4 complete; ready for `v0.5.0` commit + tag

---

## Implementation shipped (Phase 3.3)

- `GeckoEmbeddingProvider` + `GeckoInferenceAdapter` (sole `flutter_gemma_embeddings` import)
- `embeddingModelVersion` on Memory + repo APIs + async queue + foreground backfill
- `AiInferenceMutex` (extraction > embedding) wired into LiteRT extraction
- Tiered hybrid Search UI (Tier 1 keyword unchanged path; Tier 2 “Possibly related”)
- Settings: Gecko download / defer / prepare
- Opportunistic Gecko download after primary model ready (non-blocking)
- Unit tests: cosine / hybrid compose / mutex

### M7 fix (resource management — not architecture change)

- **Problem:** Warm extract ~8575 ms with Gecko worker co-resident (P1 vs ≤8 s gate).
- **Fix:** `GeckoInferenceAdapter.releaseResident()` closes the embedder worker; wired as `beforeInference` on `LiteRtExtractionProvider` (runs inside the extraction mutex lock, before Gemma inference).
- Next embed/search reloads via `prepare()` / `getActiveEmbedder()` — files and prefs unchanged.
- Architecture preserved: tiered hybrid, async queue, mutex, foreground-only backfill.

---

## Threshold calibration (Phase 3.4)

| Item | Value |
|---|---|
| Spike provisional | 0.75 |
| **Calibrated production default** | **0.70** |
| Exact top-1 rate (micro-set) | 1.0 |
| Paraphrase top-1 rate | 1.0 |
| Paraphrase scores | 0.780, 0.788, 0.734 |
| Negative max (wedding) | 0.661 |
| Live `search_query_log_v1` | 0 entries (synthetic set used) |
| Prefs key | `tend_semantic_tier2_cosine_threshold` |
| Code default | `GeckoConstants.provisionalTier2Threshold = 0.70` |

---

## Pre-flight / RSS & latency (final release pass)

| Metric | Value |
|---|---|
| Gecko-only Δ RSS (earlier debug) | ~250 MB |
| Warm embed (spike release / debug) | ~172 ms / ~293 ms |
| Tier 1 keyword | 1–3 ms |
| Tier 2 added | **~211–240 ms** (≤500 ms) |
| **M7 warm extract (Gecko was resident → released)** | **avg 7163 ms** (7158, 7131, 7201) — **≤8000 PASS** |
| Prior fail (co-resident, no release) | avg 8575 ms |
| Mutex soak | 6 rounds, **0 failures**, ~49 s |
| RSS after soak | ~1.21 GB |
| Battery | Soft manual — no abort during soak |

---

## Manual QA matrix (M1–M12) — final release harness

| ID | Case | Result | Notes |
|---|---|---|---|
| M1 | Keyword exact hit | **PASS** | |
| M2 | Paraphrase via semantic Tier 2 | **PASS** | |
| M3 | No Tier 1/2 duplicate | **PASS** | |
| M4 | Unrelated → no Tier 2 | **PASS** | threshold 0.70 |
| M5 | Gecko unavailable → keyword only | **PASS** | |
| M6 | Offline hybrid | **PASS** | |
| M7 | Capture warm extract ≤8 s | **PASS** | **7163 ms** with release-before-extract |
| M7_enqueue | Save enqueue latency | **PASS** | 0 ms |
| M8 | Backfill resume / re-embed | **PASS** | |
| M9 | Mutex extraction priority | **PASS** | |
| M10 | Person-scoped isolation | **PASS** | |
| M11 | Decline Gecko → keyword OK | **PASS** | |
| M12 | a11y Tier 2 semantics | **PASS** | |
| MUTEX_SOAK | Mixed capture+embed | **PASS** | |
| TIER2_LATENCY | ≤~500 ms added | **PASS** | |

**Harness verdict:** `PHASE34_VERDICT=PASS`

---

## Ready for `v0.5.0` commit/tag?

**Yes.** Phase 3.3 implementation + Phase 3.4 stabilization are complete with the release gate unchanged (warm extract ≤8 s). No open P0/P1. Sprint 4 not started.

## Explicitly not in this phase

- Blended scoring, workmanager, Suggestion Engine / FollowUps (Sprint 4)
