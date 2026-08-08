# SPRINT3_2.md — Phase 3.2: Embedding Provider Spike
### Planning document — research spike, not an implementation specification

**Status:** Spike complete — see [`SPRINT3_2_FINDINGS.md`](SPRINT3_2_FINDINGS.md) and ADR-013.  
**Type:** Timeboxed research spike (mirrors the discipline of `ADR-012`'s device spike and `lib/debug/multi_memory_spike_main.dart`)  
**Timebox (binding):** **Two working days** — wall-clock calendar days of focused spike work, not calendar sprawl. See Section 0.1.  
**Depends on:** Sprint 3 Phase 3.1 (`v0.4.0`) — complete, frozen.  
**Produces:** A decision, not a feature. Outcome: **Conditional Go** (Gecko dedicated embedder; not Gemma 4 E2B).

---

## 0. The distinction this entire document depends on

There are two different things that could be called "success" here, and this spike measures the first one, not the second:

- **Spike success:** every research question below gets a clear, evidence-backed answer, and a defensible go/no-go/conditional recommendation exists.
- **Technology success:** the embedding approach turns out to be fast, cheap, and accurate.

**Only the first one is required.** A spike that conclusively shows "the current LiteRT stack cannot cleanly support on-device embeddings, and here's the data proving it" is a *successful spike* — exactly as successful as one that concludes "go." The failure mode this document is designed to prevent is a spike that produces a vague impression instead of a decision, in either direction.

---

## 0.1 Binding timebox — two working days

**Constraint:** The entire Phase 3.2 research spike is timeboxed to **two working days**. This is binding — not aspirational.

**Purpose of the timebox:** reduce architectural uncertainty and produce a clear, evidence-based recommendation. It is **not** to maximize experiments, exhaust every alternative, or drift into Phase 3.3 implementation.

**What “done within the timebox” means:**

1. Run the highest-priority experiments first (Section 10 Experiment 1 → then 2–3 if capability exists → Option 2 only if needed).
2. Stop when the timebox ends — even if some measurements are incomplete.
3. If a research question cannot be fully answered in time: **document what remains unknown, explain why** (blocked, timeboxed out, or deprioritized), and still produce the **best recommendation supported by the available evidence** (go / no-go / conditional).
4. Do **not** extend the spike into a third day to “finish one more experiment” without an explicit product decision to reopen the timebox.
5. Do **not** treat unfinished curiosity as license to start Phase 3.3 wiring.

**Priority if time runs short (cut order):** Battery spot-check (Exp 6) → second alternative model → large backfill extrapolations beyond current corpus → deeper paraphrase set expansion. **Never cut:** Experiment 1 (capability yes/no), a written recommendation, and the findings document.

---

## 1. Objective

Reduce architectural uncertainty about how — or whether — Tend should generate on-device embeddings for semantic search, and produce an evidence-based recommendation for Phase 3.3. Not to ship a feature, not to guarantee semantic search happens.

---

## 2. Research Questions to Answer

1. Does `flutter_gemma` / `flutter_gemma_litertlm` expose an embedding-generation capability for the already-installed Gemma 4 E2B model, without requiring a second download?
2. If yes: what is the embedding's dimensionality, generation latency (cold and warm, for short text typical of a memory's `eventText`), and RAM footprint at generation time — additive to the already-resident model?
3. If yes: is retrieval quality acceptable for Tend's actual data shape — short, structured, named-entity-heavy memory text, not prose — specifically on paraphrase-recall cases, since that's the entire reason semantic search is being considered over keyword search at all?
4. If no, or if quality/cost is unacceptable: what does the single most credible alternative — a dedicated, compact, on-device embedding model — cost and deliver, measured the same way?
5. What is the realistic backfill cost (time, battery) for the current real corpus, extrapolated to a plausible larger one?
6. Does a chosen approach risk needing a near-term re-embed migration, given the project has already changed its underlying model twice (Qwen → Gemma 4)?
7. Does any candidate approach have the same distribution problem the original Gemma 3n Preview did (Hugging Face account gating) — i.e. is it actually deployable to an end user without a hub login?

---

## 3. Success Criteria

- Every research question in Section 2 has a documented answer backed by measured numbers, not impressions — **or**, if the two-day timebox expires first, a documented “unknown” with reason and the best recommendation still supported by what was measured (Section 0.1).
- A clear recommendation exists: **go** (with provider, dimension, and versioning approach pinned), **no-go** (with specific, falsifiable reasons — "cold latency measured at X exceeds Y budget," not "felt slow"), or **conditional** (e.g. "viable, but only worth it if backfill can run opportunistically while charging").
- If a second candidate model was evaluated (Section 7, Option 2), its numbers are recorded with the same rigor as Option 1's — not a lighter-touch pass. If Option 2 was cut for time, say so explicitly.
- The recommendation is written so that whoever reads it later (including a future Cursor session with no memory of this spike) can understand *why*, not just *what*.
- The spike stays inside the **two working day** timebox (Section 0.1).

---

## 4. Failure Criteria

- Any research question left unanswered **without** documenting the unknown and why (timebox, blocked, deprioritized) — silence is failure; honest “unknown” within the timebox is not.
- Answers that are pure impressions, or a single anecdotal run presented as if it were the Section 11 methodology — when a claim is made, it must cite measured evidence or be labeled unknown.
- No clear go/no-go/conditional recommendation at the end.
- The spike continues past two working days without an explicit product decision to reopen the timebox.
- **Scope bleeds into partial production implementation** — e.g. `LiteRtEmbeddingProvider` gets wired into the real `EmbeddingProvider` interface, or Phase 3.1's shipped search code gets touched. If that happens, the spike has quietly become Phase 3.3 without the decision this spike exists to produce ever actually being made — this is the single most important failure mode to guard against, precisely because it's the easiest one to fall into by accident.

---

## 5. Scope

- Confirm or deny Gemma 4 E2B's embedding capability through the current bridge.
- If available: benchmark quality, latency, and footprint using the fixed methodology in Section 11.
- If unavailable or clearly inadequate: evaluate exactly **one** credible alternative compact embedding model — not a broad survey. Pick the single most promising candidate from quick desk research and benchmark it with the same rigor; only evaluate a second alternative if the first one fails outright.
- Produce a written recommendation and a draft ADR.
- A throwaway debug harness, consistent with the existing `lib/debug/*_spike_main.dart` pattern — isolated, never wired into production code or navigation.

## 6. Explicitly Out of Scope

- Building or registering a concrete `EmbeddingProvider` implementation for production use.
- Implementing the semantic search engine itself (the brute-force cosine scan, its integration into the real search UI) — that's Phase 3.3.
- Running a real backfill against production Memory data — this spike *estimates* backfill cost (Section 15) and recommends an approach; it does not execute one.
- Any change to Phase 3.1's shipped code or the `SearchProvider` abstraction it introduced.
- Hybrid ranking (Phase 3.4).
- Evaluating more than one alternative embedding model unless the first credible candidate clearly fails.
- Any UI work.
- A large-scale, statistically rigorous relevance benchmark — that belongs to Phase 3.3/3.5. This spike uses a small, fixed, hand-curated set sufficient to make a directional call.

---

## 7. Architecture Options to Evaluate

Presented evenhandedly — this spike does not presuppose semantic search must ship.

**Option 1 — Reuse Gemma 4 E2B's embedding output (if it exists).** Zero additional download, reuses the model already resident on-device. Unknown until Section 10's Experiment 1 runs.

**Option 2 — A dedicated, compact, on-device embedding model.** Purpose-built embedding models are typically smaller and faster than repurposing a generative LLM's internal representations, but this adds a second model to `ModelCatalog`, a second download, and a second lifecycle to maintain.

**Option 3 — No on-device embedding for now.** Tend stays keyword-search-only (Phase 3.1, already shipped and real) until a clearly better on-device option exists. This is a legitimate, first-class outcome of this spike, not a fallback to be avoided — Phase 3.1 already provides genuine search value, so "not now" costs the product nothing except deferred paraphrase recall, which the Phase 3.1 query log can help quantify the actual demand for.

---

## 8. Risks

- **Scope creep into implementation** (Section 4) — the primary risk, worth repeating.
- **Benchmark bias from an entirely synthetic case set.** Mitigate by drawing some benchmark queries from Phase 3.1's real (on-device, already-collected) search-query log, not only hand-authored cases — this is exactly the kind of real signal that log was built to provide.
- **Reference-device results may not generalize** to lower-spec devices within the supported tier range — a stated limitation of this spike, not something it needs to solve.
- **A marginal "it technically works" result creates pressure to greenlight Phase 3.3 even when the numbers are borderline.** The recommendation must surface marginal cases explicitly rather than collapsing them into a binary yes/no.
- **Distribution risk for a second model (Option 2):** must be verified as publicly downloadable with no end-user hub login — the exact constraint that ruled out the original Gemma 3n Preview (ADR-010). A candidate that fails this is disqualified regardless of its quality numbers.

---

## 9. Trade-offs

| Option | Gains | Costs |
|---|---|---|
| 1 — Reuse Gemma 4 E2B | Zero added download/footprint; one fewer model to maintain | Generative-model embeddings may be lower quality than a purpose-built embedding model; unknown until measured |
| 2 — Dedicated embedding model | Likely better speed/quality for retrieval specifically | New download size, new RAM footprint, new `ModelCatalog` entry, new versioning/lifecycle surface |
| 3 — Stay keyword-only | Zero added cost, zero added risk, ships nothing new | No paraphrase recall — acceptable only if Phase 3.1's query log doesn't show real demand for it |

---

## 10. Required Experiments

1. **Capability check.** Attempt to call an embedding-generation method via `flutter_gemma_litertlm` against the already-installed Gemma 4 E2B artifact. Timebox this small — it's a yes/no question, not an open-ended integration task.
2. **Latency/footprint micro-benchmark (if Experiment 1 succeeds).** Generate embeddings for the fixed benchmark set (Section 11), measure per-call latency (cold and warm) and peak RSS delta, on the same reference device used for 2B.8's RC benchmarks — for direct numeric comparability, not a new baseline.
3. **Retrieval quality micro-benchmark.** Using the same benchmark set, compute similarity rankings and manually judge whether the correct memory ranks at or near the top for each query — with particular attention to the paraphrase cases, since that's the whole reason this is being considered.
4. **Repeat Experiments 2–3 against exactly one alternative model**, only if Experiment 1 fails or Experiment 3 scores poorly for Option 1.
5. **Backfill cost extrapolation.** Using Experiment 2's per-item latency, extrapolate total time/battery for the current real corpus size (measured directly, not guessed) and for a plausible larger one (e.g. 500 and 2,000 memories) to understand scaling.
6. **Battery spot-check.** A fixed protocol (e.g. N consecutive embedding generations), measured the same soft-gate way 2B.8 measured extraction battery cost — for methodological continuity, not a new standard invented from scratch.

---

## 11. Benchmark Methodology

- **Reference device:** the same device used for Sprint 2B.8's RC benchmarks, for numbers that are directly comparable to the project's existing latency/RSS baselines.
- **A fixed, small, versioned benchmark case set**, checked into `lib/debug/` (e.g. `embedding_spike_cases.dart`), mirroring the existing `extraction_completeness_cases.dart` pattern — reproducible, and reusable as a starting point for Phase 3.3's eventual larger relevance benchmark rather than throwaway.
- **Composition:** a mix of hand-authored synthetic cases systematically covering exact-term match, genuine paraphrase (no literal keyword overlap), category-only relevance, and negative/no-match cases — plus a handful of real, on-device-only, already-anonymized queries pulled from Phase 3.1's actual search-query log, since that data now exists and is exactly the real signal this project's own "let data decide" discipline calls for using when it's available.
- **Cold vs. warm distinction**, consistent with how 2B.8 measured extraction — the first call after model load is not representative of steady-state cost.

---

## 12. Performance Measurements to Collect

- Embedding generation latency: cold (first call) and warm (average of N subsequent calls).
- Peak RSS delta during generation — additive to the already-resident Gemma 4 E2B footprint (Option 1) or standalone (Option 2).
- Model/download size, if Option 2 is evaluated.
- Extrapolated backfill time for the current corpus and a larger hypothetical one.
- Battery delta for the fixed generation protocol.

---

## 13. Memory and Storage Considerations

- **Per-Memory storage cost** once a dimension is pinned — compute the real number (e.g. a 384-dim float32 vector is roughly 1.5KB; 768-dim roughly 3KB) and extrapolate total Isar storage growth for a large corpus (e.g. 5,000 memories) to confirm it's negligible rather than assuming it.
- **RAM footprint at generation time is the number that actually matters for device-tiering.** `ARCHITECTURE.md` Section 7's RAM-tier thresholds were sized against an assumed Gemma-3n-era footprint that was never reconciled with the real, measured Gemma 4 E2B numbers (a gap already identified in the earlier architecture review, still open). This spike's RAM findings should feed that still-open recalibration — this spike doesn't need to fix it, but its numbers are direct evidence for whoever does.
- **Disk footprint for Option 2** is a real, user-facing cost stacked on top of the existing ~2.4GB Gemma 4 E2B download — state the cumulative total explicitly, since that's a genuine consideration for users on constrained devices/storage plans, not just an engineering footnote.

---

## 14. Battery Impact Considerations

- Distinguish **per-capture incremental cost** (small, ongoing, happens on every new memory) from **one-time backfill cost** (potentially large, happens once). These have different UX implications — a large one-time cost is a candidate for running opportunistically (e.g. only while charging and idle), which is a design option worth naming now even though the actual backfill implementation belongs to Phase 3.3.
- Use the same soft-gate framing 2B.8 established ("~5% battery / N warm operations" as a soft check, not a hard pass/fail) — for methodological continuity, not a new bar invented here.

---

## 15. Backfill Strategy (recommendation only — not implemented in this spike)

This spike's job is to **recommend** a backfill approach based on the measured numbers, not to build one. Based on Section 10's Experiment 5, the spike should conclude with a specific recommendation covering: batched vs. all-at-once, opportunistic (charging/idle) vs. immediate, resumable/idempotent (the same precedent already established for the date-resolution backfill in the Foundation Cleanup phase), and whether any user-visible progress indication is warranted. Phase 3.3, if it happens, implements whatever this spike recommends — or revisits the recommendation if real corpus sizes at that point have changed the calculus.

---

## 16. Versioning Strategy for Embeddings

This directly closes a gap `SCHEMA.md` has flagged since it was first written: *"this needs an explicit re-embed migration strategy, which isn't fully designed yet."* Given the project has already changed its underlying model twice, a third change is a real possibility, not a hypothetical — embeddings from different provider versions or dimensions must never be silently compared as if compatible.

**Recommendation to validate in this spike:** each Memory record should carry an `embeddingModelVersion` (or equivalent) field alongside its embedding vector, so a future provider swap can be detected and trigger a re-embed pass rather than corrupting similarity comparisons silently. This spike's deliverable is a **documented recommendation** (an updated `SCHEMA.md` field proposal, captured in the findings doc and draft ADR) — actually adding the field to the live Isar collection and wiring it through is Phase 3.3's implementation work, not this spike's.

---

## 17. Rollback Strategy If Embeddings Prove Unsuitable

**During this spike:** trivial by design. The harness lives entirely under `lib/debug/`, never touches production code, schema, or the shipped `EmbeddingProvider`/`SearchProvider` abstractions. If the recommendation is "no-go," rollback is simply not proceeding — there's nothing in production to undo. This is itself a signal the spike is correctly scoped: a spike that would need a complicated rollback plan is a spike that's already too large.

**For Phase 3.3, if it proceeds (a design note for later, not this spike's work):** semantic matching should be built as an *additive* signal on top of Phase 3.1's keyword search, per the pluggable `SearchProvider` architecture already established — never a replacement for it. That means if semantic search later proves low-value or costly in production, "rollback" is as simple as disabling that one signal in the ranking strategy — the product never loses search entirely, only the semantic enhancement on top of it.

---

## 18. Definition of Done

- [ ] Spike completed inside the **two working day** timebox (or an explicit product reopen was recorded).
- [ ] All Section 10 experiments that fit the timebox were run and documented with real, measured numbers; any skipped experiment is listed with reason (Section 0.1 cut order).
- [ ] Every Section 2 research question has a documented, evidence-based answer **or** a documented unknown with explanation.
- [ ] A go / no-go / conditional recommendation is written, with specific supporting data — not impressions — even if some questions remain unknown.
- [ ] If go: provider, embedding dimension, and versioning approach (Section 16) are pinned in a draft ADR.
- [ ] If no-go: reasons are specific and falsifiable, and a recommended alternative path is stated (stay keyword-only, revisit after model X, etc.).
- [ ] Backfill strategy recommendation (Section 15) is documented to the extent evidence allows, even though nothing was actually backfilled.
- [ ] Debug harness and benchmark case set exist entirely under `lib/debug/`; zero production code touched.
- [ ] `BACKLOG.md` and `DEVLOG.md` updated with the spike's outcome.

---

## 19. Exit Criteria

The spike is complete when the decision document exists and has been reviewed — not when "the engineering feels done," mirroring the same non-vibes exit-criteria discipline `SPRINT2B8.md` established for the RC gate. **The two-day timebox is an exit condition:** when it ends, write the findings and recommendation from whatever evidence exists; do not keep the spike open indefinitely. **Phase 3.3 does not begin** until this spike's recommendation is either a documented "go" (with the decisions above pinned) or an explicitly accepted "descope Phase 3.3 for now, stay on Phase 3.1's keyword search."

---

## 20. Deliverables

1. **A findings document** (e.g. `SPRINT3_2_FINDINGS.md`) — separate from this planning document, produced at the end of the spike, capturing the actual measured results and the recommendation. This document is the plan; that one is the outcome — kept distinct the same way `SPRINT2B8.md` (plan) and `RELEASE_READINESS_REPORT.md` (filled-in outcome) were kept as two documents, not one merged over time.
2. **A new ADR** (`ADR-013`, continuing the existing sequence) capturing whichever decision is reached — go or no-go — consistent with this project's established practice of writing an ADR for exactly this class of architectural decision (see ADR-010, ADR-011, ADR-012).
3. **If go:** a recommended `SCHEMA.md` field addition for embedding versioning (Section 16), documented for Phase 3.3 to implement — not implemented here.
4. **The debug spike harness and benchmark case file**, committed under `lib/debug/`.
5. **Updated `BACKLOG.md` and `DEVLOG.md` entries** reflecting the spike's outcome.

---

**Binding timebox:** **two working days** (Section 0.1). The goal is a decision under uncertainty reduction, not maximal experimentation. Incomplete answers are acceptable if unknowns are documented and the best evidence-based recommendation is still produced. Extending past two days requires an explicit product reopen — not silent drift into Phase 3.3.
