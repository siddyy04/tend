# SPRINT 3.3 IMPLEMENTATION SPECIFICATION
### Target: AI coding agent (Cursor). Read fully before writing any code.

> **Parent architecture doc:** [`SPRINT3_3.md`](SPRINT3_3.md) is **frozen and approved** and is the architecture source of truth for Phase 3.3.  
> **Spike evidence:** [`SPRINT3_2_FINDINGS.md`](SPRINT3_2_FINDINGS.md), **ADR-013**.  
> **This file** is the authoritative **implementation specification for Phase 3.3 only**.  
> Do **not** begin Phase 3.4 stabilization polish beyond what this DoD requires, and do **not** start Sprint 4 (Suggestion Engine / FollowUps).

You are implementing **Sprint 3 Phase 3.3 only** of the Tend Flutter app. Reference documents already in this repository: `SPRINT3.md`, `SPRINT3_1.md` (Phase 3.1 keyword Search — shipped, **do not modify internals**), `SPRINT3_2.md` / `SPRINT3_2_FINDINGS.md`, `SPRINT3_3.md`, `ARCHITECTURE.md`, `ADR.md` (especially ADR-003, ADR-008, ADR-010, ADR-011, ADR-013), `FEATURES.md`, `SCHEMA.md`, `BACKLOG.md`, `CURSOR_HANDOFF.md`, `SPRINT0.md`–`SPRINT2B8.md`, and `RELEASE_READINESS_REPORT.md`.

If anything in this file appears to conflict with `SPRINT3_3.md`, **`SPRINT3_3.md` wins on product/architecture intent** — stop and ask rather than expanding scope. If this file is more specific on file layout, queue/mutex mechanics, or DoD, treat **this file as binding for Phase 3.3 implementation**.

Phase 3.3 must be a **complete, independently reviewable, independently testable vertical slice** of production hybrid semantic search before Phase 3.4 (stabilization) begins.

**Do not write production code until this specification is the agreed brief** (already true for this chat once product approved `SPRINT3_3.md`; implement only when explicitly instructed to start coding).

---

## 0. Cross-Document Consistency Notes (read before building)

1. **`FEATURES.md` / `ARCHITECTURE.md` describe embeddings + cosine search.** Phase 3.1 shipped keyword-first; Phase 3.3 now delivers the first production semantic layer as **Tier 2 only**, on top of unchanged Tier 1 keyword Search (`SPRINT3_3.md` §10–11). Update docs to describe **tiered hybrid**, not blended scoring.
2. **`SCHEMA.md` currently warns that `Memory.embedding` has no fixed dimension and needs a re-embed strategy.** Phase 3.3 closes that gap: Gecko is **768-d**; persist **`embeddingModelVersion`**; never compare across versions. Dimension is **not** stored per row.
3. **`DEVELOPMENT_ROADMAP.md` may still list Suggestion Engine as Sprint 3.** `SPRINT3.md` supersedes: Sprint 3 = Search; Suggestion Engine → Sprint 4. Do not build FollowUps here.
4. **`ModelCatalog` today is extraction/LLM-oriented** (`LiteRtModelKind` / `.litertlm`). Gecko is a **different** artifact (`.tflite` + tokenizer) and package (`flutter_gemma_embeddings`). Reuse **download/verify/install staging** from `model_manager/`; introduce an **embedding catalog** sibling if `ModelArtifactSpec` cannot honestly describe Gecko without lying about LiteRT-LM kinds. Do **not** invent a second HTTP download stack.
5. **Settings today has no model re-offer UI** (defer/decline lives on `ModelSetupScreen` for Gemma). Phase 3.3 must add a **Settings surface** for Gecko download / defer / decline / retry (architecture §7). Do not fold Gecko into the Gemma first-run blocking gate.
6. **`activeEmbeddingProvider` does not exist yet.** Wire it in `ai_provider_selection.dart` (or adjacent). Production must register `embeddingBackends` **only** when Gecko is ready (ADR-013) — spike harness patterns in `lib/debug/embedding_spike_*.dart` are reference, not production entrypoints.
7. **No `AiInferenceMutex` exists today.** Capture extraction and Gecko embedding must share one app-wide mutex (architecture §4a). This is new coordination logic — required.
8. **Phase 3.1 `KeywordSearchProvider` / `search_ranking_rules.dart` are frozen for this phase.** Do not change match/rank heuristics, empty-state copy (except Tier 2 section chrome), or keyword query path. Hybrid composition lives **outside** the keyword provider.
9. **Spike provisional Tier 2 threshold 0.75 is a hypothesis.** Shipping DoD requires recalibration against a larger benchmark (query log + synthetic) — not shipping the spike number alone (`SPRINT3_3.md` §22).
10. **Postgres / sync:** no embedding column work this phase (Sprint 5 note only).
11. **`workmanager` is explicitly out of scope.** Backfill is foreground-only.

---

## 1. Objective

Deliver the first **production-ready hybrid search**: Phase 3.1 keyword Search remains the reliable, always-on **Tier 1**; a new **Gecko-110m-en** embedding layer adds paraphrase recall as **Tier 2** (“possibly related”), without degrading keyword speed, reliability, capture latency, or offline behavior.

**Success metric (product):** a user can find a memory they described in different words than they typed at capture — while still trusting exact keyword hits exactly as today — fully offline once the optional Gecko model is present.

---

## 2. Scope

### 2.1 Features included (Phase 3.3 only)

| Feature | Notes |
|---|---|
| `GeckoEmbeddingProvider` | Implements existing `EmbeddingProvider`; sole production embedder |
| `GeckoInferenceAdapter` | **Only** file that may import `flutter_gemma_embeddings` |
| `NoOpEmbeddingProvider` | Null-object when Gecko unavailable; queue stays inactive |
| `embeddingModelVersion` on Memory | Nullable string; single source of truth for valid/stale/needs-backfill |
| Async post-persist embedding | Fire-and-forget after `create`/`update`; zero added save latency |
| `EmbeddingQueueController` | Sequential queue; retries with bounded backoff |
| Shared `AiInferenceMutex` | Extraction always wins over embedding/backfill |
| Batched resumable backfill | Foreground + idle only; no OS background worker |
| Embedding model catalog + download | Gecko `.tflite` + tokenizer; reuse download-manager staging |
| Optional Gecko download UX | Auto-offer after primary model ready; Settings defer/decline/retry |
| `SemanticSearchProvider` | Cosine scan over valid embeddings; conservative threshold |
| `HybridResultComposer` | Tier 1 then Tier 2; no blending; no Tier 1 duplication |
| Search UI Tier 2 section | Visually + semantically distinguished (“possibly related”) |
| Pre-flight RSS/battery measurement | Early task; document before trusting wider rollout |
| Threshold calibration task | Expand benchmark; persist tunable threshold |
| Offline-first query path | Network only for one-time Gecko download |

### 2.2 Features explicitly excluded (do not build)

- Any modification to Phase 3.1 keyword matching, ranking, or `KeywordSearchProvider` internals
- Blended / weighted hybrid scores (`keyword + w * semantic`)
- Alternative embedding providers (EmbeddingGemma, Gemma-4-as-embedder, etc.)
- `workmanager` / OS background execution
- Suggestion Engine, FollowUps, Today’s Opportunities, notifications
- Sync / Supabase / remote search / Postgres embedding mirror
- Cross-person Connection search
- Learned / personalized ranking
- ANN / vector indexes
- Changing LiteRT extraction protocol or capture UX (except mutex acquire + post-save enqueue)
- Phase 3.4 soak / E2E stabilization campaign as a substitute for this phase’s own DoD
- Sprint 4 work “while we’re here”

If an implementation detail seems to require any excluded item to feel complete, **it doesn’t** — stop and flag it in findings / backlog.

---

## 3. Architecture Overview

```
Capture / Manual Entry (persist path unchanged for UX)
   → MemoryRepository.create() / update() succeeds
        → EmbeddingEnqueueHook.enqueue(memory.uuid)   // fire-and-forget

EmbeddingQueueController (Riverpod, in-app async — NOT workmanager)
   → AiInferenceMutex.acquire(priority: embedding)     // yields to extraction
        → activeEmbeddingProvider.embed(eventText)
             → GeckoEmbeddingProvider
                  → GeckoInferenceAdapter   // sole flutter_gemma_embeddings import
        → MemoryRepository.update()  // embedding + embeddingModelVersion only

Search (query time)
   UI → SearchController
        → KeywordSearchProvider.search()      // Tier 1 — UNCHANGED, always runs
        → SemanticSearchProvider.search()     // Tier 2 — only if Gecko ready + threshold
        → HybridResultComposer.compose()      // merge outside both providers
        → UI: Tier 1 list, then optional Tier 2 section
```

**Binding constraints:**

- **ADR-003:** Isar only via repositories. Ranking/composition not inside `IsarMemoryRepository`.
- **ADR-008:** Cosine similarity, threshold compare, tier merge helpers are pure (unit-testable) where practical.
- **ADR-010/011:** Gemma / LiteRT-LM boundary unchanged; Gecko is a **parallel** vendor boundary under `lib/ai/providers/gecko/`.
- **ADR-013:** Gecko dedicated embedder; versioning required; semantic additive only.
- **Tiered, not blended** (`SPRINT3_3.md` §10): Tier 1 ranking byte-stable vs Phase 3.1; Tier 2 appended below.
- **Rollback:** disabling Tier 2 = composer skips semantic provider / DI returns NoOp — keyword path untouched.

### 3.1 Why a shared mutex

Gecko RSS/battery were **not** measured in the spike. Running Gemma-4 extraction and Gecko embedding concurrently is an unacceptable unknown. One app-wide “on-device inference busy” mutex is mandatory. Capture extraction **always** has priority; embedding/backfill wait and resume.

### 3.2 Why not put hybrid merge inside `KeywordSearchProvider`

Preserves Phase 3.1 rollback, test stability, and ADR-style single-responsibility. Composer is the only place that knows both tiers.

---

## 4. Files to Create

```
lib/
  ai/
    inference/
      ai_inference_mutex.dart              # app-wide mutex + priority (extraction > embedding)
    providers/
      gecko/
        gecko_embedding_provider.dart      # EmbeddingProvider impl
        gecko_inference_adapter.dart       # ONLY flutter_gemma_embeddings import
        gecko_constants.dart               # version id string, dim=768, default threshold key
      embedding/
        noop_embedding_provider.dart       # null-object
        embedding_queue_controller.dart    # queue + sequential worker + retry
        embedding_enqueue_hook.dart        # thin API used after persist
        embedding_backfill_controller.dart # batched opportunistic backfill
      search/
        semantic_search_provider.dart      # cosine Tier 2 candidates
        hybrid_result_composer.dart        # Tier1 + Tier2 merge
        hybrid_search_models.dart          # HybridSearchResult, SearchResultTier, etc.
    model_manager/
      embedding_model_catalog.dart         # Gecko artifact + tokenizer specs (sibling to ModelCatalog)
      # OR extend existing catalog if done without lying about LiteRt* kinds — prefer sibling
  domain/
    rules/
      embedding_similarity_rules.dart      # cosine, threshold gate (pure)
      hybrid_search_rules.dart             # dedupe Tier2 vs Tier1 uuids (pure)
  features/
    search/
      # extend existing widgets / controller — see §5
    settings/
      widgets/gecko_model_settings_tile.dart  # download / defer / decline / status
    embedding/  # optional feature folder if Settings + status need a home
      embedding_model_status.dart

test/
  domain/rules/embedding_similarity_rules_test.dart
  domain/rules/hybrid_search_rules_test.dart
  ai/providers/search/semantic_search_provider_test.dart
  ai/providers/search/hybrid_result_composer_test.dart
  ai/inference/ai_inference_mutex_test.dart
  ai/providers/embedding/embedding_queue_controller_test.dart
  # fakes for EmbeddingProvider / repos

lib/debug/
  embedding_rss_battery_probe_main.dart    # pre-flight measurement harness (debug only)
  embedding_calibration_main.dart          # optional: threshold calibration runner
```

Do **not** put production Gecko wiring inside `lib/debug/embedding_spike_main.dart` — keep spike as historical reference; production code lives under `lib/ai/providers/gecko/`.

---

## 5. Files to Modify

| File | Change |
|---|---|
| `lib/data/local/isar/collections/memory.dart` | Add `String? embeddingModelVersion` + `@Index()` |
| Generated Isar `*.g.dart` | Regenerate via build_runner |
| `lib/domain/repositories/memory_repository.dart` | Add queries: memories needing embed (null/stale version); optional `updateEmbedding(...)` helper |
| `lib/data/local/isar/isar_memory_repository.dart` | Implement above; keep soft-delete filters |
| `lib/features/capture/confirmation/capture_confirmation_controller.dart` | After successful `create`, enqueue uuid (do not await embed) |
| `lib/features/memory_form/memory_form_controller.dart` | After successful `create`/`update`, enqueue when `eventText` or `category` changed |
| `lib/ai/providers/ai_provider_selection.dart` | `activeEmbeddingProvider`, mutex provider, Gecko/NoOp resolution |
| `lib/ai/providers/litert/litert_extraction_provider.dart` (and/or adapter call sites) | Acquire/release `AiInferenceMutex` around extraction inference |
| `lib/ai/model_manager/model_download_manager.dart` | Support embedding artifact download/verify/install paths **or** shared helper used by both catalogs — no parallel HTTP stack |
| `lib/ai/model_manager/model_manager_providers.dart` | Gecko readiness / assist-style status providers |
| `lib/features/search/search_controller.dart` | Call keyword + semantic + composer; expose tiered result model to UI |
| `lib/features/search/widgets/search_results_list.dart` (and related) | Render Tier 1 then Tier 2 section with a11y label |
| `lib/features/search/widgets/search_result_tile.dart` | Optional subtle “possibly related” treatment for Tier 2 only |
| `lib/features/settings/settings_screen.dart` | Gecko model status + download/defer/decline/retry |
| `lib/features/capture/model_setup_screen.dart` / entry | After primary model becomes ready, **opportunistically** start or schedule Gecko download (non-blocking); never block Capture |
| `pubspec.yaml` | Keep `flutter_gemma_embeddings`; remove “spike only” comment; still no backends until ready |
| `SCHEMA.md` | Document `embeddingModelVersion`, 768-d Gecko, lifecycle |
| `ARCHITECTURE.md` | Tiered hybrid search; mutex; gecko boundary |
| `CHANGELOG.md` / `DEVLOG.md` / `CURSOR_HANDOFF.md` / `BACKLOG.md` | Phase 3.3 outcomes |
| `ADR.md` | Confirm ADR-013 Accepted (not draft) when phase ships |

**Do not modify** for Phase 3.3:

- `lib/ai/providers/search/keyword_search_provider.dart` ranking logic
- `lib/domain/rules/search_ranking_rules.dart`
- FollowUp / SuggestionLog collections
- Supabase client / sync
- Spike harness behavior (optional: leave intact)

**Preferred enqueue coverage:** either (a) explicit enqueue at every successful write call site that creates/updates searchable text, or (b) a thin decorating repository/facade used by those call sites. Prefer **explicit enqueue after success** at known controllers for clarity in 3.3; file any missed write path as a bug. Do **not** embed ranking or Gecko imports inside the Isar repository.

---

## 6. Implementation Order (logical sections)

Execute in this order unless blocked — each section has its own exit checks.

### Section A — Pre-flight measurement (gate early unknowns)

1. Debug harness measures **RSS delta** and a **soft battery spot-check** for Gecko warm embed on AIN065 (or current reference device).
2. Document numbers in `DEVLOG.md` (and a short note in findings or CHANGELOG Notes).
3. If RSS is catastrophically incompatible with concurrent Gemma residency even with mutex serialization, **stop and escalate** before wiring Search UI — do not silently ship.

### Section B — Schema + repository

1. Add `embeddingModelVersion` + index; regenerate Isar.
2. Repository APIs for backfill candidates and embedding writes.
3. Unit/repo tests for soft-delete + version filters.

### Section C — Mutex + Gecko provider

1. `AiInferenceMutex` with priorities + unit tests.
2. Wire mutex into LiteRT extraction path.
3. `GeckoInferenceAdapter` + `GeckoEmbeddingProvider` + `NoOpEmbeddingProvider`.
4. Embedding catalog + download/verify/install readiness.
5. `activeEmbeddingProvider` resolution.

### Section D — Queue + post-persist + backfill

1. `EmbeddingQueueController` (sequential, retry/backoff).
2. Enqueue hooks after create/update.
3. `EmbeddingBackfillController` (batch 10–25, idle/foreground, yields to mutex/capture).
4. Prove kill-and-restart resumes via version query (no separate progress store).

### Section E — Semantic search + hybrid compose

1. Pure cosine + threshold rules.
2. `SemanticSearchProvider`.
3. `HybridResultComposer` (dedupe, tier order, optional suppress Tier 2 when Tier 1 is “strong” — start with **always show Tier 2 if any pass threshold**; suppress heuristic only if QA demands and is documented).
4. Threshold stored as tunable preference/constant with documented default **after** calibration task (provisional code default may start at 0.75 but **must not** ship as final without recalibration evidence).

### Section F — Search UI + Settings UX

1. Controller returns hybrid model; UI sections + a11y.
2. Settings Gecko tile; optional auto-download after primary ready.
3. Loading announcement if Tier 2 adds noticeable wait.

### Section G — Calibration + QA + docs

1. Build expanded relevance benchmark (spike cases + anonymized `search_query_log_v1` samples).
2. Set production threshold from evidence; document in DEVLOG.
3. Manual QA matrix; capture-latency regression; docs; handoff to 3.4.

---

## 7. Data Flow

### 7.1 Persist → embed (async)

```
User confirms capture / saves memory form
  → MemoryRepository.create|update succeeds  (embedding may be null)
  → Confirmation/save UX completes immediately (unchanged latency budget)
  → EmbeddingEnqueueHook.enqueue(uuid)       // non-blocking
  → Queue worker (when provider ready + mutex free):
       load Memory by uuid (skip if deleted)
       if eventText empty → skip
       if embeddingModelVersion == current && embedding length == 768 → skip
       mutex.acquire(embedding)
       vector = embed(eventText)             // optionally include category label in embed text — document choice; default: eventText only
       mutex.release()
       update Memory: embedding=vector, embeddingModelVersion=currentVersion
  → Memory is Tier-1 searchable immediately; Tier-2 eligible after update
```

### 7.2 Backfill

```
App foreground + not capturing + Gecko ready
  → BackfillController ticks
  → Query: active memories where embeddingModelVersion != current (incl. null)
  → Take batch N (10–25)
  → For each: same as queue worker (enqueue or process inline sequentially)
  → On app kill: no cursor persisted; next launch re-queries — idempotent
  → Progress UI only if estimated remaining > ~30–60s (estimate = count * ~172ms)
```

### 7.3 Search query

```
User types query (existing debounce)
  → Tier1 = KeywordSearchProvider.search(query)     // always
  → if Gecko not ready OR embed(query) fails:
       results = HybridResult(tier1: Tier1, tier2: [])
  → else:
       qVec = embed(query) under mutex (search may wait briefly; never fail UX)
       Tier2cands = SemanticSearchProvider over scoped active memories with valid version+embedding
       filter cosine >= threshold
       exclude uuids already in Tier1
       sort Tier2 by cosine desc, then recency, then uuid
       compose HybridResult
  → UI renders Tier1 (unchanged tiles), then Tier2 section if non-empty
  → analytics: log tier1Count, tier2Count (local only; extend SearchAnalytics carefully)
```

### 7.4 Freshness

- Keyword: immediate (Phase 3.1).
- Semantic: after async embed completes; early search simply omits that memory from Tier 2 — **not** an error.

---

## 8. State Management Approach

- **Riverpod, manual-style** (match existing Capture / Search).
- Providers to add (names indicative):
  - `aiInferenceMutexProvider` (`keepAlive`)
  - `geckoInferenceAdapterProvider` / readiness
  - `activeEmbeddingProvider` → `GeckoEmbeddingProvider` | `NoOpEmbeddingProvider`
  - `embeddingQueueControllerProvider` (`keepAlive` while app lives)
  - `embeddingBackfillControllerProvider`
  - `semanticSearchProvider` / `hybridResultComposerProvider`
  - Tunable `tier2CosineThresholdProvider` (read from prefs with documented default)
- `SearchController` / `SearchUiState`: evolve from `List<SearchHit>` to a **hybrid result** type (`tier1`, `tier2`) **or** a single list with `SearchResultTier` on each hit — prefer **explicit two lists** so Tier 1 ordering cannot be accidentally interleaved.
- Do not use codegen unless the repo already requires it for these modules.
- Cancel stale search responses with existing monotonic request-id pattern; if Tier 2 is slower, still never replace a newer query’s Tier 1 with an older Tier 2.

---

## 9. Queue and Mutex Implementation Details

### 9.1 `AiInferenceMutex`

**Requirements:**

| Rule | Behavior |
|---|---|
| Mutual exclusion | At most one on-device inference critical section at a time (extraction **or** embedding) |
| Priority | `extraction` > `embedding` (includes per-capture embed and backfill) |
| Extraction waiting | If embedding holds lock, extraction waits; embedding must not start new work when extraction is queued (prefer: embedding checks `extractionWaiting` / priority queue) |
| Fairness | Simple is fine: extraction always preempts **scheduling** of embedding; do not cancel an in-flight embed mid-native-call if unsafe — wait for it to finish, then run extraction next |
| API shape (indicative) | `Future<T> withLock(AiInferencePriority priority, Future<T> Function() action)` |
| Testing | Unit-test ordering with fake delays |

**Wire points:**

- LiteRT extraction path that calls `runFunctionCalls` / generate (acquire `extraction`).
- `GeckoEmbeddingProvider.embed` or adapter (acquire `embedding`).
- Search-time query embed uses same embedding priority (capture still wins if contended).

### 9.2 `EmbeddingQueueController`

| Rule | Behavior |
|---|---|
| Ordering | FIFO by enqueue time; **one embed at a time** (sequential) — no concurrent Gecko calls |
| Deduping | Re-enqueue of same uuid coalesces (at most one pending entry per uuid) |
| Skip conditions | NoOp provider; memory missing/deleted; empty `eventText`; already current version + valid dim |
| Retry | Transient failures: bounded retries (e.g. 3) with exponential backoff; then leave as needs-backfill (version still null/stale) for a later pass — **not** infinite spin |
| Persistence of queue | In-memory is OK; durability of “needs work” is the **schema version field**, not the queue |
| Capture UX | Never block UI; never surface embed errors as snackbars |

### 9.3 `EmbeddingBackfillController`

| Rule | Behavior |
|---|---|
| When | App resumed/foreground; Gecko ready; not in active capture extraction |
| Batch size | 10–25 per tick |
| Yield | Before each item, respect mutex; if capture starts, pause tick |
| Tiny corpora | If remaining &lt; ~50–100, may run a single burst on first idle — still sequential + mutex |
| Progress UI | Hidden by default; show only when estimate &gt; 30–60s |
| No workmanager | Explicit |

---

## 10. Provider Responsibilities

| Component | Responsibility | Must not |
|---|---|---|
| `KeywordSearchProvider` | Phase 3.1 keyword search | Know about embeddings / tiers |
| `SemanticSearchProvider` | Embed query; cosine over valid memories in scope; apply threshold | Re-rank or mutate Tier 1; touch Isar directly |
| `HybridResultComposer` | Concatenate tiers; dedupe by `memoryUuid`; optional suppress policy | Call Isar; blend scores |
| `GeckoEmbeddingProvider` | `embed(text) → List&lt;double&gt;` length 768; report `modelVersion` | Import UI; own download UX |
| `GeckoInferenceAdapter` | Install/load embedder; generateEmbedding | Be imported outside `gecko/` |
| `NoOpEmbeddingProvider` | Unavailable stand-in | Throw into user-visible paths |
| `EmbeddingQueueController` | Serialize post-persist embeds | Run during save critical path |
| `EmbeddingBackfillController` | Drive stale/null version catch-up | Use OS background APIs |
| `AiInferenceMutex` | Cross-model exclusion + priority | Know Search ranking |
| `MemoryRepository` | CRUD + candidate queries + persist vectors | Call Gecko |
| `ModelDownloadManager` / embedding catalog | Fetch/verify Gecko files | Block Capture on failure |

`activeEmbeddingProvider` resolves to Gecko **only** when model files are downloaded, verified, and adapter reports ready; else NoOp.

---

## 11. Repository Changes

Add to `MemoryRepository` (names indicative):

```dart
/// Active memories whose embedding is missing or not [currentVersion].
Future<List<Memory>> getMemoriesNeedingEmbedding(String currentVersion, {int? limit});

/// Persist embedding fields only (preferred over full-object races).
Future<void> updateEmbedding({
  required String uuid,
  required List<double> embedding,
  required String embeddingModelVersion,
});
```

Rules:

- Always soft-delete filter (`deletedAt == null`).
- Prefer indexed query on `embeddingModelVersion`.
- `updateEmbedding` must not clobber unrelated fields; load-merge-put or partial update pattern consistent with existing Isar usage.
- Do **not** clear embedding on unrelated field edits; do enqueue regeneration when `eventText` or `category` changes (controller responsibility).

---

## 12. Schema Changes

Additive on `Memory` Isar collection:

```dart
List<double>? embedding;                 // existing — now written as 768-d Gecko vectors
@Index()
String? embeddingModelVersion;           // e.g. "gecko-110m-en-seq256-v1"; null = never / stale signal when != current
```

**Version string (binding default):** `gecko-110m-en-seq256-v1` (from spike / ADR-013). Change only with a catalog bump that intentionally invalidates all prior vectors.

**Lifecycle (binding):**

| State | Condition | Tier 2 eligible? |
|---|---|---|
| Missing | `embedding == null` or version null | No |
| Valid | version == current AND length == 768 | Yes |
| Stale | version != current | No (treated like missing for Tier 2) |
| Regenerate | `eventText` or `category` changed on update | Re-enqueue; old vector until replaced |

Do **not** store per-row dimension. Do **not** compare vectors across versions.

Migration: nullable add — existing rows null → backfill. Low risk.

Update `SCHEMA.md` accordingly; note Sprint 5 Postgres mirror later.

---

## 13. Search Pipeline Changes

### 13.1 Tier 1 (unchanged)

- Continue to use `KeywordSearchProvider` via existing wiring.
- Result order and membership for keyword hits must match Phase 3.1 for the same corpus/query (regression AC).

### 13.2 Tier 2

- Candidate pool: same scope as keyword (global vs person).
- Only memories with **valid** embedding for current version.
- Score: cosine similarity between query embedding and memory embedding (pure function).
- Keep if `score >= tier2Threshold`.
- Exclude any `memoryUuid` already in Tier 1.
- Sort: score desc → recency (`dateValue` else `createdAt`) → `uuid` asc.

### 13.3 Threshold

- **Provisional engineering default:** `0.75` (spike-informed).
- **Ship requirement:** recalibrate using expanded benchmark; store final value in a single tunable location (prefs or constants with DEVLOG citation).
- Zero Tier 2 hits is **success**, not failure — never lower threshold just to fill UI.

### 13.4 Composer

```
HybridSearchResult {
  List<SearchHit> tier1; // keyword, Phase 3.1 order
  List<SearchHit> tier2; // semantic-only; may reuse SearchHit + tier flag or parallel type
}
```

Optional UX policy (not required day one): if Tier 1 has ≥ N strong hits (`exactPhrase` / high count), suppress Tier 2 for that query — only enable if QA shows noise; document if enabled.

### 13.5 Degradation

| Condition | Behavior |
|---|---|
| Gecko not downloaded / declined / not ready | Tier 1 only |
| Query embed fails | Tier 1 only (silent) |
| No valid corpus embeddings yet | Tier 1 only |
| Semantic scan throws | Tier 1 only (silent); log locally |

---

## 14. UI / UX Flow

### 14.1 Search results

1. Keep existing query field, debounce, empty states for blank query / no corpus / zero Tier-1-and-Tier-2.
2. If Tier 1 non-empty: show existing list **unchanged**.
3. If Tier 2 non-empty: section header **“Possibly related”** (or equivalent), then Tier 2 tiles.
4. If Tier 1 empty and Tier 2 non-empty: show only Tier 2 under that header (still not “AI answered”).
5. If both empty: existing Phase 3.1 zero-results empty state.
6. Do **not** show raw cosine scores to users.
7. Person-scoped search: same composition; isolation unchanged.

### 14.2 Embedding invisibility

- No per-memory “embedding…” spinner on Capture confirmation.
- Backfill progress only when estimate warrants.

### 14.3 Gecko download

- **Not** part of blocking first-run Gemma gate.
- After primary model ready: may auto-start download in background **or** prompt gently — user can defer/decline in Settings.
- Copy must state approximate size (~114 MB) and that Search still works without it (keyword only).
- Failed download: retry in Settings; app otherwise fully usable.

### 14.4 Loading

- If Tier 2 adds wait after Tier 1 is ready: show Tier 1 immediately, then append Tier 2 when ready **or** show a short accessible “Finding related memories…” — prefer **Tier 1 first paint** to protect perceived keyword latency (hard requirement: Tier 1 latency unaffected).

---

## 15. Business Rules

1. Soft-deleted memories never embed-candidate and never appear in either tier.
2. Person-scoped isolation identical to Phase 3.1 for both tiers.
3. Every result is a real Memory row — no generative answers.
4. Tier 2 never duplicates Tier 1 uuids.
5. Tier 1 never reordered by semantic scores.
6. Embed text: **`eventText`** at minimum; if category is included, document and keep consistent between index and query (recommend **eventText only** for v1 to match spike methodology).
7. Edits to `importanceScore` / dates alone do **not** force re-embed; `eventText` or `category` changes do.
8. Offline: all search/embed inference local; only model download needs network.
9. Analytics remain on-device; may add `tier1Count` / `tier2Count` fields to local search log.

---

## 16. Failure and Recovery Behaviour

| Failure | Behavior |
|---|---|
| Gecko download fails or declined | Tier 1 only; Settings retry; no other feature blocked |
| Per-memory embed fails (transient) | Stay Tier-1-only; retry via queue/backfill with bounded backoff |
| Backfill interrupted | Resume via version query next foreground idle |
| Query-time embed fails | Silent Tier-1-only for that query |
| Mixed / stale versions in corpus | Excluded from Tier 2 until re-embedded |
| Mutex contention | Extraction wins; embedding waits |
| Corrupt / wrong-length vector | Treat as invalid; re-enqueue |
| Adapter not initialized | NoOp provider; queue idle |

Never show a user-visible error dialog for “semantic unavailable.”

---

## 17. Performance Expectations

| Metric | Target | Notes |
|---|---|---|
| Tier 1 latency | **No regression** vs Phase 3.1 | Hard requirement; measure on device |
| Tier 2 added latency | Provisional **≤ ~500 ms** total added (query embed + scan) | Measure; don’t assume spike’s 172 ms alone |
| Capture save path | **Zero** await on embed | Enqueue only |
| Embed throughput | ~172 ms/item warm (spike) | Backfill batching based on this until remeasured |
| Concurrent embeds | **1** | Sequential queue |
| Storage | ~3 KB/memory; ~14.6 MB @ 5k | Acceptable |

---

## 18. Accessibility Considerations

- Tier 2 section: screen reader announces **“possibly related results”** (or equivalent), not color-only distinction.
- Tier 2 tiles: button semantics include that they are possibly related.
- If a loading state waits on Tier 2: announce consistently with Capture’s live-region pattern (“Finding related memories…”).
- Gecko Settings download UI: same accessible patterns as model setup (labels, progress, errors as text).
- Do not rely on badge color alone.

---

## 19. Testing Strategy

### 19.1 Unit tests (required)

- Cosine similarity edge cases (identical, orthogonal, zero vectors guard).
- Threshold gate.
- Hybrid dedupe (Tier 1 uuid excluded from Tier 2).
- Tier ordering (all Tier 1 before any Tier 2).
- Mutex priority (extraction scheduled before embedding when both wait).
- Queue coalesce / skip-if-current-version.
- Stale version not Tier-2-eligible.

### 19.2 Provider / repository tests

- `getMemoriesNeedingEmbedding` returns null and stale; excludes deleted and current.
- `SemanticSearchProvider` respects person scope.
- Composer does not call keyword provider (inject lists).
- `activeEmbeddingProvider` returns NoOp when not ready.

### 19.3 Widget tests (lightweight)

- Results list shows Tier 2 header only when `tier2` non-empty.
- Semantics label present for Tier 2 section.
- Keyword-only hybrid (empty tier2) matches prior list structure.

### 19.4 Integration / harness

- Debug RSS/battery probe documented.
- Calibration runner or documented manual procedure using query log export.

### 19.5 Manual QA (required before Phase 3.3 exit)

On reference device (AIN065 or equivalent):

| # | Case | Expect |
|---|---|---|
| M1 | Keyword exact hit | Tier 1 identical to pre-3.3 behavior |
| M2 | Paraphrase query (no keyword overlap) | Appears in Tier 2 when embedded + above threshold; not Tier 1 |
| M3 | Tier 1 hit also high cosine | Appears **only** in Tier 1 |
| M4 | Unrelated query | No Tier 2 (threshold holds) |
| M5 | Gecko not installed | Search works; Tier 1 only; no errors |
| M6 | Airplane mode (model already on disk) | Hybrid works offline |
| M7 | Capture save timing | No regression vs 2B.8 / 3.1 |
| M8 | Kill mid-backfill → relaunch | Remaining null/stale eventually embed; no dup corrupt versions |
| M9 | Start capture during backfill | Extraction proceeds; backfill yields |
| M10 | Person-scoped hybrid | No cross-person leak in either tier |
| M11 | Decline Gecko in Settings | App healthy; keyword search OK |
| M12 | a11y spot-check | Tier 2 announced |

---

## 20. Acceptance Criteria

Maps to `SPRINT3_3.md` §19 — all must pass:

1. `GeckoEmbeddingProvider` implements `EmbeddingProvider`; only `gecko_inference_adapter.dart` imports `flutter_gemma_embeddings`.
2. Gecko model management reuses `model_manager` download/verify/install staging; never blocks primary Gemma setup gate.
3. `embeddingModelVersion` on Memory is the single source of truth for needs-backfill / stale.
4. Per-capture embedding is async and adds **zero** latency to save/confirmation await path.
5. Backfill is batched, resumable (kill-and-restart verified), mutex-respecting, foreground-only.
6. Search UI shows two distinguished tiers; Tier 1 output/ranking matches Phase 3.1 for identical inputs.
7. Tier 2 never duplicates a Tier 1 `memoryUuid`.
8. Tier 2 threshold is documented, tunable without hunting magic literals, and **validated** against an expanded benchmark before exit (not spike 0.75 alone).
9. Failed/declined download, failed embed, failed query embed → graceful Tier-1-only; no user-facing semantic errors.
10. RSS and battery cost of embedding generation measured on reference device and documented.
11. Fully offline search/embed once model is local; network only for download.
12. Shared `AiInferenceMutex` exists; extraction priority verified.
13. Capture-latency regression suite re-run with no regression.

---

## 21. Definition of Done

- [ ] Section 20 acceptance criteria all verified  
- [ ] Sections A–G implementation order complete  
- [ ] Pre-flight RSS/battery documented  
- [ ] Tier 2 threshold recalibrated and recorded in DEVLOG  
- [ ] Unit + provider tests green for new pure rules / composer / mutex / queue  
- [ ] Manual QA matrix (§19.5) executed on device  
- [ ] Capture-latency regression re-run  
- [ ] No Phase 3.4-only soak campaign required to call 3.3 Done — but no open P0/P1 from §19.5  
- [ ] Docs updated (§23)  
- [ ] Short QA/acceptance summary artifact written (see §21.1)  
- [ ] No Sprint 4 / FollowUp code merged  
- [ ] Keyword provider internals unchanged (diff review)  

### 21.1 QA / acceptance summary (required artifact)

Produce a short markdown note (e.g. `SPRINT3_3_QA.md` or a DEVLOG section) containing:

- Device + build  
- Threshold chosen + benchmark summary  
- RSS/battery numbers  
- Latency: Tier 1 / Tier 2 / capture  
- Pass/fail of manual matrix  
- Known residual risks for Phase 3.4  

---

## 22. Risks and Implementation Pitfalls

| Risk / pitfall | Mitigation |
|---|---|
| Reopening blended scoring | Forbidden; composer is tiered only |
| Modifying keyword ranking “to make hybrid nicer” | Diff-ban `search_ranking_rules.dart` / keyword provider logic |
| Registering `embeddingBackends` at app start before model ready | Gate on readiness; NoOp otherwise |
| Importing `flutter_gemma_embeddings` outside adapter | Code review / package boundary |
| Awaiting embed on save | Enqueue-only; test save path |
| Concurrent Gecko + Gemma without mutex | Mandatory mutex before dual workloads |
| Shipping provisional 0.75 | Exit criterion blocks on recalibration |
| Trusting absolute cosine without negatives | Benchmark must include unrelated queries |
| Building `workmanager` for “real” backfill | Out of scope; foreground trade-off accepted |
| Folding Gecko into Gemma setup gate | Optional additive download only |
| Storing wrong version string | Single constant in `gecko_constants.dart` |
| Comparing stale vectors | Version gate in semantic provider |
| Interleaving Tier 2 into Tier 1 list | Two-section UI / two lists |
| Settings omission | Gecko defer/decline/retry required |
| Premature ANN | Brute-force cosine only at MVP scale |
| Scope creep into 3.4 soak | Stabilization is next phase; 3.3 DoD is sufficient but complete |

---

## 23. Documentation Updates Required

| Doc | Update |
|---|---|
| `SCHEMA.md` | `embeddingModelVersion`, 768-d, lifecycle, index note |
| `ARCHITECTURE.md` | Tiered hybrid; gecko provider boundary; mutex; async embed; backfill |
| `FEATURES.md` | Search describes keyword + optional semantic Tier 2 (not “embeddings only”) |
| `CHANGELOG.md` | User-visible hybrid search + optional Gecko download |
| `DEVLOG.md` | Measurements, threshold, mutex, backlog cuts |
| `CURSOR_HANDOFF.md` | Phase 3.3 done → next Phase 3.4 stabilization (not Sprint 4) |
| `BACKLOG.md` | Close gated 3.3 item; file residuals (e.g. workmanager revisit, blended scoring research) |
| `ADR.md` | ADR-013 → Accepted (implemented) |
| `SPRINT3_3.md` | Status line → implemented / ready for 3.4 (one-line only) |
| `SPRINT3_3_QA.md` (or DEVLOG equivalent) | QA summary artifact |

---

## 24. Handoff Criteria for Phase 3.4 (Stabilization)

Phase 3.4 (short stabilization pass — **not** a new hybrid-ranking phase) may begin only when:

1. Phase 3.3 Definition of Done (§21) is complete.  
2. Recalibrated Tier 2 threshold is what production uses (not the unvalidated spike provisional alone).  
3. RSS/battery numbers are documented and available to feed (or explicitly defer) `ARCHITECTURE.md` device-tiering recalibration.  
4. No open P0/P1-equivalent issues from the Phase 3.3 QA matrix.  
5. Product agrees to start stabilization (E2E across Typed/Voice/OCR/Share + search, mutex soak under mixed load, docs close-out).  

**Phase 3.4 must not** invent blended ranking or swap embedding providers without a new ADR.

**Sprint 4 (Suggestion Engine) must not begin until** Phase 3.4 handoff criteria in `SPRINT3_3.md` §23 are also met (stabilization complete). Planning Sprint 4 during 3.3 implementation is forbidden.

---

## 25. Suggested Day-One Checklist for the Implementing Agent

When explicitly told to **start coding**:

1. Re-read this file + `SPRINT3_3.md` §4–16.  
2. Run Section A pre-flight probe before large UI work.  
3. Schema → mutex → Gecko provider → queue → semantic/composer → UI → Settings.  
4. Keep keyword diffs empty.  
5. Stop at DoD; write QA summary; update handoff to Phase 3.4.  

---

## 26. Out-of-Scope Reminder (final)

Do not implement blended hybrid scores, `workmanager`, Suggestion Engine, FollowUps, alternative embedders, keyword-ranking changes, sync, or Phase 3.4 soak-as-substitute-for-DoD.

**Phase 3.3 ships tiered hybrid search:** keyword Tier 1 unchanged; Gecko semantic Tier 2 additive; async embeddings; versioned schema; mutex; graceful degradation.
