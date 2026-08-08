# ADR-0001 — Tend Architecture: Offline-First, On-Device AI, Local-First Sync

**Status:** Accepted
**Applies to:** all implementation work from Sprint 0 onward
**How to use this with Cursor:** paste this whole file into the repo as `ARCHITECTURE.md` and treat it as binding. Prompt pattern: *"Follow ARCHITECTURE.md exactly — if a task requires deviating from it, stop and ask rather than improvising."* Business logic must never import a vendor SDK (`flutter_gemma` / LiteRT bridge, Supabase) directly outside the specific provider/repository files named below.

**Supersession note (ADR-010 / ADR-011):** Concrete MVP extraction is a **model-agnostic LiteRT** layer (`lib/ai/providers/litert/`) with **Gemma 4 E2B** as the default catalog model via **LiteRT-LM** (`.litertlm`). Optional **Gemma 4 E4B** is catalog-listed for capable devices. Historical “Gemma 3n” / Qwen / MediaPipe `.task` wording below is superseded for the active runtime; treat ADR-011 + `ModelCatalog` as authoritative.

---

## 0. Summary of the decision

Isar (via `isar_community`) is the single source of truth on-device. Extraction runs on-device via LiteRT-LM + catalog-selected weights (MVP: Gemma 4 E2B; optional E4B — ADR-011). Embeddings run via a dedicated Gecko provider (`flutter_gemma_embeddings` — ADR-013). Both sit behind swappable provider interfaces. Supabase is demoted to authentication + optional, opt-in, encrypted backup/sync — never a dependency for core app function. No OpenAI, no pgvector, no server-side inference for MVP.

| Layer | Choice | Role |
|---|---|---|
| Local database | Isar (`isar_community` fork) | Source of truth, works fully offline |
| State management | Riverpod (code-gen) | All business logic, no logic in widgets |
| AI inference | On-device LiteRT-LM (via `flutter_gemma` + `flutter_gemma_litertlm`) for extraction; dedicated Gecko embedder (`flutter_gemma_embeddings`) for vectors | Extraction + embeddings |
| ASR (voice-to-text) | Swappable `TranscriptionProvider` — MVP: platform-native STT; long-form engine TBD after evaluation | Not the LLM — see Section 6 |
| OCR (screenshots) | Platform-native on-device OCR (ML Kit / Vision) | Not the LLM — see Section 6 for why |
| Backend | Supabase | Auth + optional backup/sync only |
| Semantic search | Tiered hybrid: keyword Tier 1 + Gecko cosine Tier 2 | No pgvector, no ANN index needed at MVP scale |

---

## 1. Overall System Architecture and Data Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                          Flutter App                              │
│                                                                     │
│  UI (widgets) ──watch──> Riverpod providers ──query/watch──> Isar  │
│                                │                                    │
│                                ├──> AI Provider Interface           │
│                                │      (Extraction / Embedding /     │
│                                │       Transcription / OCR)         │
│                                │        │                           │
│                                │        ├──> LiteRT-LM + Gemma 4    │
│                                │        │    (extraction;           │
│                                │        │     flutter_gemma +       │
│                                │        │     flutter_gemma_litertlm)│
│                                │        └──> Gecko embedder         │
│                                │             (flutter_gemma_        │
│                                │              embeddings; parallel  │
│                                │              vendor boundary)      │
│                                │                                    │
│                                └──> Sync Engine (background)        │
│                                       │                             │
└───────────────────────────────────────┼─────────────────────────┘
                                          │  (only if user opts in,
                                          │   only over network)
                                          ▼
                                ┌──────────────────┐
                                │     Supabase      │
                                │  Auth + Backup DB  │
                                └──────────────────┘
```

**Capture flow (the core loop, must stay under 10 seconds):**
1. User triggers capture (voice/text/photo/share-sheet).
2. Voice → platform ASR → text. Photo → platform OCR → text. Share → editable shared text.
3. Text goes to the local `ExtractionProvider` (LiteRT model via function calling).
4. Extraction result (matching the Deliverable 5 JSON schema exactly) is validated: confidence thresholds, grounding-quote check, taxonomy check — all unchanged from the original design.
5. Result written to a Riverpod state → confirmation card renders → user confirms/edits.
6. On confirm: write to Isar (`memories` collection), `syncStatus = pending`, `updatedAt = now()`. Embedding generation (if Gecko is ready) is **enqueued asynchronously after** this write — never on the save critical path (Phase 3.3).
7. Isar write triggers a watcher → UI updates immediately (no network round-trip in the critical path — this is the entire point of local-first).
8. If sync is enabled and connectivity exists, a background task later pushes the pending record to Supabase. If not, nothing blocks the user; the record is fully functional locally.

**Suggestion Engine flow:** unchanged from Deliverable 6 in logic, changed in execution — a scheduled local background task (`workmanager`) queries Isar directly (no cloud round-trip), scores candidates with the same rule-based formula, writes to the local `suggestion_log` collection, and triggers a local notification.

**Search flow:** query text → **Tier 1** keyword/substring search (Phase 3.1, always on) → optional **Tier 2** query embedding via `GeckoEmbeddingProvider` + brute-force cosine over version-valid memory embeddings → `HybridResultComposer` appends semantic-only hits under “Possibly related”. Keyword ranking is never reordered by semantic scores.

---

## 2. Flutter Project Structure (feature-first)

```
lib/
  app/
    app.dart                 # MaterialApp/router root
    router.dart               # go_router config
  core/
    theme/
    utils/
    constants/                # category taxonomy, decay defaults, etc. (Deliverable 3/4 constants)
  data/
    local/
      isar/
        collections/          # Person, Memory, FollowUp, SuggestionLogEntry, Connection
        isar_provider.dart     # opens the Isar instance, exposed via Riverpod
    remote/
      supabase/
        supabase_client.dart
        backup_schema.sql      # mirrors the Isar collections for backup/sync
    sync/
      sync_engine.dart         # push/pull, conflict resolution
      sync_status.dart
  domain/
    repositories/              # PersonRepository, MemoryRepository, FollowUpRepository
                                # — the ONLY layer allowed to touch Isar directly
    models/                    # plain Dart domain models, mapped from Isar collections
  ai/
    providers/
      extraction_provider.dart     # abstract interface
      embedding_provider.dart      # abstract interface
      transcription_provider.dart  # abstract interface
      ocr_provider.dart            # abstract interface
      litert/
        litert_extraction_provider.dart  # concrete LiteRT extraction (catalog model)
        litert_inference_adapter.dart    # sole flutter_gemma import (LLM)
        litert_prompt_builder.dart
      gecko/
        gecko_embedding_provider.dart    # concrete EmbeddingProvider (Gecko)
        gecko_inference_adapter.dart     # sole flutter_gemma_embeddings import
        gecko_constants.dart
      embedding/
        embedding_queue_controller.dart  # post-persist async embed queue
        embedding_backfill_controller.dart
        noop_embedding_provider.dart
      search/
        keyword_search_provider.dart
        semantic_search_provider.dart
        hybrid_result_composer.dart
      manual/
        manual_fallback_provider.dart    # no-AI fallback for unsupported devices
    inference/
      ai_inference_mutex.dart          # shared extraction > embedding mutex
    model_manager/
      model_catalog.dart               # Gemma extraction artifacts
      embedding_model_catalog.dart     # Gecko embedding artifacts
      model_download_manager.dart
      embedding_model_manager.dart
      device_capability_check.dart
  features/
    circle/                    # My Circle screen
    person_profile/
    capture/                   # capture modal + confirmation card
    opportunities/             # Today's Opportunities
    search/
    settings/
  main.dart
```

**Rule for Cursor:** nothing outside `ai/providers/litert/litert_inference_adapter.dart` may import `flutter_gemma` / `flutter_gemma_litertlm` for the LLM path (plus a process bootstrap hook). Nothing outside `ai/providers/gecko/gecko_inference_adapter.dart` may import `flutter_gemma_embeddings`. Nothing outside `data/local/isar/` and `domain/repositories/` may import Isar directly. Collection field definitions live only in **`SCHEMA.md`** — do not duplicate them here.

---

## 3. State Management — Riverpod

- Use `riverpod` + `riverpod_generator` (code-gen, `@riverpod` annotations) — avoids the boilerplate of manually writing `StateNotifierProvider` declarations and catches provider-dependency mistakes at compile time.
- **Repositories are providers.** `personRepositoryProvider`, `memoryRepositoryProvider`, etc. wrap Isar access; nothing above the repository layer knows Isar exists.
- **Isar's native watchers feed Riverpod streams directly** — e.g. a `Stream<List<Memory>>` from `isar.memories.where()...watch()` exposed as an `@riverpod` stream provider. This gets you reactive UI updates for free without hand-rolled polling or manual `setState` calls.
- **AsyncNotifier, not manual loading/error state**, for anything with a lifecycle (capture flow, sync status) — Riverpod's `AsyncValue` already models loading/data/error, don't reinvent it per-feature.
- **No business logic in widgets.** A widget calls a provider method and renders `AsyncValue`; the confirmation-card confidence-threshold logic, the suggestion-scoring formula, the sync conflict resolution — all of it lives in `domain/` or `ai/`, never inline in a `build()` method. This isn't a style preference — it's what makes the logic testable without spinning up the widget tree.

---

## 4. Local Database — Isar

### ⚠️ Maintenance note (read before `pub add`)
Official `isar` development has slowed significantly. **Depend on `isar_community`** (the actively-maintained community fork — same API, drop-in) rather than the original `isar` package. `isar_plus` is a second, smaller fork with similar goals if `isar_community` ever stalls too — worth a five-minute comparison at implementation time, not a blocker now. If sync ends up being more painful to hand-roll than expected (Section 5), ObjectBox is the credible alternative to revisit — it has native sync support, which is the one thing Isar doesn't give you for free. Not switching now; flagging it so it isn't rediscovered the hard way in six months.

### Collections — single source of truth

**Do not define or copy Isar collection field lists in this file.** The authoritative collection definitions (Person, Memory, FollowUp, SuggestionLogEntry, Connection), enums, indexes, FK patterns, embedding versioning, and Postgres backup-mirror notes live in **[`SCHEMA.md`](SCHEMA.md)**.

Implementation must generate Dart `@collection` classes to match `SCHEMA.md` exactly. If architecture text and `SCHEMA.md` ever disagree on a field, **`SCHEMA.md` wins** — update this document’s narrative, do not invent a second schema.

Sync-oriented fields (`uuid`, `updatedAt`, `syncStatus`, `deletedAt`) are intentional in `SCHEMA.md` from day one so later sync (Section 5) does not require a painful retrofit. Isar’s local `Id` never leaves the device; foreign keys use client-generated `uuid` strings (see `SCHEMA.md` “Why uuid FKs, not IsarLinks”).

---

## 5. Sync Architecture — Local-First with Supabase

**Principle:** Isar is always correct and always available. Supabase is a mirror that may be stale, absent, or unreachable at any moment, and the app must behave identically either way.

- **Authentication:** Supabase Auth (email or phone OTP), unchanged from the original design — this is the one piece of the old architecture that survives untouched.
- **Backup/sync is opt-in, default OFF.** This is a direct consequence of the Bible's own privacy-by-design principle — the architecture should back up what the product already claims to believe, not just the policy language. On first enabling sync, the app pushes the full local Isar dataset to the Supabase mirror.
- **Sync engine, running as a background task (`workmanager`):**
  1. **Push:** query all local records where `syncStatus == pending`, upsert to Supabase using `uuid` as the conflict key, mark `syncStatus = synced` on success.
  2. **Pull:** query Supabase for records with `updatedAt > lastSyncedAt` for this user, upsert into Isar by `uuid`.
  3. **Conflict resolution: last-write-wins by `updatedAt`.** This is a deliberate simplicity choice, not an oversight — per-field merging is real added complexity that isn't justified for a product that's mostly single-device, single-editor. Revisit only if shared circles (P1) make concurrent multi-user edits to the same record common.
  4. **Deletes are tombstones, not row deletions:** set `deletedAt` locally, sync the tombstone, and only hard-delete after both sides confirm sync (or after a retention window) — this avoids a deleted-on-device-A record silently reappearing after a sync from device B that hasn't seen the delete yet.
- **Supabase schema mirrors the Isar collections field-for-field**, including `uuid`, `updated_at`, `deleted_at`. Row Level Security stays on every table, exactly as in the original schema — even as a backup mirror, one user must never be able to read another's data.
- **Offline is not a degraded mode — it's the default mode.** Every feature must work with sync fully disabled. Sync only adds "available on another device" and "recoverable if the device is lost" — it should never be a dependency for anything else.

---

## 6. AI Architecture — Provider Abstraction

The whole point of this layer: **business logic never knows which model is running.** Confirmation-card thresholds, the extraction JSON schema, the grounding-quote check — all of that is defined once, against an interface, and stays identical no matter what's underneath.

```dart
abstract class ExtractionProvider {
  Future<ExtractionResult> extract({
    required String text,
    required List<Person> knownPeople,   // for person-match resolution
  });
}

abstract class EmbeddingProvider {
  Future<List<double>> embed(String text);
}

abstract class TranscriptionProvider {
  Future<String> transcribe(String audioFilePath);
  Future<bool> isAvailable();
  Future<List<TranscriptionLocale>> supportedLocales();
  Future<TranscriptionLocale?> recommendedLocale();
  Future<void> startListening({
    required void Function(String words, bool isFinal) onResult,
    void Function(String error)? onError,
    String? localeId,
  });
  Future<String> stopListening();
  Future<void> cancelListening();
}

abstract class OCRProvider {
  Future<String> extractText(String imageFilePath);
}
```

Concrete implementations live behind these interfaces:
- `LiteRtExtractionProvider` — on-device LiteRT-LM via `flutter_gemma` + `flutter_gemma_litertlm`, using **native function-calling** to enforce the extraction schema. Which weights run is decided by `ModelCatalog` (MVP: **Gemma 4 E2B**; optional E4B), not by Capture/Confirmation.
- `GeckoEmbeddingProvider` — on-device **Gecko-110m-en** (768-d) via `flutter_gemma_embeddings` / `GeckoInferenceAdapter`. Optional download (~114 MB); when unavailable, resolve `NoOpEmbeddingProvider` and keep keyword Search only.
- `PlatformTranscriptionProvider` — **Sprint 2B.4 MVP** wraps iOS Speech / Android `SpeechRecognizer` via `speech_to_text`, **not the LLM**. Selected through `activeTranscriptionProvider`. Acceptable for short notes; **not** the long-term conversational / multi-minute transcription solution (see product backlog evaluation). Future long-form engines (Whisper, cloud STT, etc.) must implement the same `TranscriptionProvider` interface so Capture → Extraction → Confirmation stay unchanged.
- `PlatformOCRProvider` — **Sprint 2B.5 MVP** wraps Google ML Kit text recognition via `google_mlkit_text_recognition`, **not the LLM**. Selected through `activeOCRProvider`. Screenshots / text-bearing photos only; scene captioning remains P1. Future OCR engines implement the same `OCRProvider` interface so Capture → Extraction → Confirmation stay unchanged.
- `ShareIntentHandler` / `PlatformShareIntentHandler` — **Sprint 2B.6 MVP** converts Android share-sheet text/URLs (`receive_sharing_intent`) into editable Capture text only. No AI logic in the share path; Continue uses the same `CaptureSubmitFlow` as Typed / Voice / OCR with `SourceType.share`.
- `ManualFallbackProvider` — a null-object implementation for devices that can't run a local extraction model (Section 7): `extract()` returns “needs manual entry” instead of throwing. Semantic search silently degrades to keyword-only when Gecko is declined/missing. The app must never crash or block capture because a model isn't available — it should just quietly become the pre-AI (or keyword-only) version of itself.

### Shared on-device inference coordination (Phase 3.3 / 3.4)

Gemma-4 extraction and Gecko embedding are **separate** native workloads. They must not run concurrently:

1. **`AiInferenceMutex`** — app-wide lock; **extraction priority** over embedding (per-capture embed, backfill, and search-time query embed wait).
2. **`GeckoInferenceAdapter.releaseResident()`** — closes the resident embedder worker and drops the in-memory handle **immediately before** Gemma extraction (wired as `beforeInference` on `LiteRtExtractionProvider`, inside the extraction lock). Catalog files and readiness prefs are untouched; the next embed/search reloads via `prepare()` / `getActiveEmbedder()`.
3. **Rationale (M7):** with Gecko co-resident, warm extract averaged ~8.6 s on AIN065 (failed the ≤8 s release gate). After `releaseResident()`, warm extract averaged **~7.2 s** with the same gate. This is resource management, not a ranking/architecture change — see `SPRINT3_3_QA.md`.

### Why ASR, OCR, and Share stay outside the LLM (and why the ASR *implementation* is swappable)
Gemma *can* take audio and image input directly, but routing every voice note or screenshot through the full multimodal model is the heavier, slower, more battery-costly path for jobs that purpose-built ASR/OCR stacks can do. Reserve the LLM for structured reasoning over **text**. Platform STT is the MVP transcription backend; Tend’s product goal includes **long-form conversational voice**, so the transcription *provider* is intentionally abstracted and can be upgraded after a structured evaluation without touching Capture, Extraction, or Confirmation. Speech language preference (Settings) is provider-agnostic and should travel with any future engine. Share ingress similarly only produces editable text — never images, PDFs, or HTML markup for the model.

---

## 7. Model Management Strategy

**Bundled vs. downloaded:** download on first run, not bundled in the app binary. Bundling a multi-GB model blows past app store size norms and means every model update requires a full app-store release cycle. Download-on-first-run, store in the app's documents directory, and let model updates ship independently of app releases.

**Update flow:**
- On launch, check the bundled model manifest against the latest known version (a small remote config check, not a full re-download).
- If a newer model is available, offer it as an optional download — never force it mid-session, never silently swap a model out from under an in-progress capture.
- Verify the downloaded model against a checksum before use; if verification fails, fall back to the previously working model rather than a corrupt one.

**Unsupported / low-memory devices — the real risk to design for, not an edge case:**

Measured on reference device **AIN065** (Phase 3.3/3.4 QA — see `SPRINT3_3_QA.md`):

| Workload | Observed footprint / latency |
|---|---|
| Gecko embedder load (debug probe) | **~+250 MB** VmRSS delta |
| Gecko warm embed | ~172 ms (release spike) / ~293 ms (debug) |
| Gemma 4 E2B download | **~2.4 GB** on disk |
| Gemma + Gecko co-resident (soak, before release discipline) | **~1.35 GB** VmRSS; warm extract **~8.6 s** (failed ≤8 s gate) |
| After `releaseResident()` before extract | warm extract **~7.2 s** (PASS ≤8 s); soak RSS ~1.21 GB |

At first launch, run a `device_info_plus`-based capability check (available RAM, OS version) **before** offering the primary model download.

**Tiered behavior, not a hard cutoff** (floors informed by Gemma 4 E2B ~2.4 GB download + multi-GB runtime, plus optional Gecko ~114 MB / ~250 MB RSS):

- **≥8GB RAM:** full experience — Gemma 4 E2B extraction, optional Gecko Tier 2 search, all AI features on. Still **serialize** extraction vs embedding (`AiInferenceMutex`) and **release** the Gecko worker before extraction (`releaseResident()`).
- **~6GB RAM:** Gemma 4 E2B may run, but treat concurrent camera+model and concurrent Gemma+Gecko residency as unsafe — prefer gallery-style photo flows; keep mutex + `releaseResident()` mandatory; consider declining Gecko if capture latency/thermal pressure appears.
- **Below a defined floor (device can't comfortably run Gemma 4 E2B):** ship with `ManualFallbackProvider` — capture, editing, and the rest of the product work; keyword Search still works; no extraction and no Tier 2 semantic search. Acceptable degraded mode.

**Do not** assume historical “Gemma 3n ~3GB” numbers for new tiering work — use the Phase 3.3/3.4 measurements above and re-measure when changing models.

### Model recommendation — don't use one model for everything

- **Extraction (text → structured Memory):** production MVP is **Gemma 4 E2B** via LiteRT-LM function calling (`ModelCatalog` / ADR-011). Optional **Gemma 4 E4B** for capable devices.
- **Once you have real usage data (post-beta):** fine-tune a smaller function-calling specialist (e.g. FunctionGemma-class) on Tend extraction examples — a defined future roadmap item to widen the supported-device floor, not a Sprint 3/4 blocker.
- **Embeddings:** dedicated **Gecko-110m-en** via `flutter_gemma_embeddings` (Phase 3.3 / ADR-013) — **not** Gemma 4 E2B (no embed API on `InferenceModel`).
- **ASR/OCR:** platform-native, as covered in Section 6 — never the LLM.

The provider abstraction in Section 6 exists so swapping extraction or embedding implementations remains a contained change, not a rearchitecture.

---

## 8. Semantic Search Architecture

- Phase 3.1 ships **keyword search** as Tier 1 (always on, offline).
- Phase 3.3 adds **Gecko-110m-en** embeddings (768-d) via `GeckoEmbeddingProvider` / `GeckoInferenceAdapter` (sole `flutter_gemma_embeddings` import).
- Embeddings are generated **asynchronously after** Memory persistence (and via foreground batched backfill) — never on the capture save critical path.
- Persist `embeddingModelVersion` with every vector (`SCHEMA.md`); stale/null versions are Tier-2-ineligible until re-embedded.
- Query time: embed the query; brute-force cosine in Dart over valid vectors; apply a tunable absolute threshold (calibrated **0.70** in Phase 3.4); append Tier 2 below Tier 1 (**tiered**, not blended).
- **Concurrency / RAM:** `AiInferenceMutex` (extraction > embedding) plus `releaseResident()` before extraction — see Section 6.
- Gecko download is optional (~114 MB), independent of the Gemma setup gate; decline → keyword-only.
- At MVP scale, no ANN index. Authoritative field notes: `SCHEMA.md`; decisions: ADR-013 / `SPRINT3_3.md`.
- **This is a deliberate simplification, not a compromise.** pgvector's ANN indexing exists to solve a scale problem a single user's relationship history will not approach soon. Realistic per-user scale is hundreds to low thousands of memories.
- **Escape hatch, not needed now:** Isar keyword prefilter before the vector scan if linear scan ever becomes noticeable.
- **Worth instrumenting before over-investing further:** structured filtering (person, category, date) may cover much early “search” behavior; validate with real query-log data.

---

## 9. Security and Privacy Model

- **All user data lives locally by default.** Nothing leaves the device unless the user explicitly opts into backup/sync (Section 5).
- **Local encryption:** use platform-backed secure storage (`flutter_secure_storage`, backed by iOS Keychain / Android Keystore) for auth tokens and any encryption keys; if the chosen Isar fork supports at-rest encryption, enable it for the local database file — verify this specifically for `isar_community` at implementation time, since encryption support has historically varied across Isar forks.
- **Sensitivity-driven storage minimization carries through unchanged from Deliverable 3/5:** `sensitivityFlag = high` still forces softened `eventText` and mandatory user confirmation before save, regardless of which model produced the extraction.
- **Model inference is stateless and local** — no captured text, audio, or images are ever sent to a third-party AI API. This is the architecture actually backing up the product's own stated privacy principle, not just a policy claim layered on top of a cloud pipeline.
- **Data export and delete** work identically to the original design — full local export, cascading deletes (`deletedAt` tombstones locally, hard-deleted after sync confirmation or a retention window) — see Section 5.
- **Backup, when enabled, is still access-controlled server-side** via Supabase Row Level Security on every mirrored table — a backup opt-in doesn't mean a security opt-out.

---

## 10. Recommended Packages

| Package | Responsibility |
|---|---|
| `isar_community` | Local database — source of truth |
| `flutter_riverpod` + `riverpod_generator` | State management, dependency injection, reactive streams |
| `go_router` | Navigation |
| `flutter_gemma` + `flutter_gemma_litertlm` | On-device LiteRT-LM inference bridge (**extraction / Gemma 4**), via `LiteRtInferenceAdapter` only |
| `flutter_gemma_embeddings` | On-device **Gecko** embedding backend, via `GeckoInferenceAdapter` only (Phase 3.3+) |
| `supabase_flutter` | Auth + optional backup/sync client |
| `workmanager` | Background sync engine + daily Suggestion Engine job (future; not used for embedding backfill in Phase 3.3) |
| `flutter_secure_storage` | Auth tokens, encryption keys |
| `device_info_plus` | Device capability check for model tiering |
| `speech_to_text` (or platform channel to native ASR) | Voice transcription, outside the LLM |
| `google_mlkit_text_recognition` (or platform Vision framework) | On-device OCR for screenshot capture |
| `path_provider` | Local file paths for model storage, audio/photo source refs |
| `connectivity_plus` | Detect network availability before attempting sync |
| `flutter_local_notifications` | Today's Opportunities daily digest |
| `uuid` | Client-generated stable identifiers for sync-safe foreign keys |

---

## 11. Key Trade-offs at a Glance

| Decision | What we gained | What we gave up | Why it's the right call here |
|---|---|---|---|
| Isar over Supabase-as-primary | Offline-first, zero query latency, privacy by default | Multi-device sync is now something we build, not something the backend gives us for free | Matches the product's own privacy-by-design principle; sync complexity is bounded (Section 5), not open-ended |
| `isar_community` over official `isar` | Ongoing maintenance | A less battle-tested fork than the original at its peak | Official `isar` maintenance has slowed — betting on the actively maintained fork is the more defensible long-term call |
| On-device Gemma 4 (+ optional Gecko) over cloud LLM | No per-call cost, real privacy, offline capability | Weaker extraction than a frontier cloud model; real device-fragmentation / RAM risk | Directly serves privacy, cost, offline; mitigated by confidence defaults, tiered devices, mutex + `releaseResident()` |
| Platform-native ASR/OCR over multimodal LLM | Better accuracy, lower RAM/battery cost, smaller required model | One more provider interface to maintain | The LLM should do structured reasoning — not tasks mature OS APIs already do better |
| Dedicated Gecko embedder over “reuse Gemma for vectors” | Honest API boundary; public download; measured Tier 2 quality | Extra ~114 MB download + ~250 MB RSS when loaded | Gemma 4 `InferenceModel` has no embed API (Phase 3.2 spike / ADR-013) |
| Brute-force local embeddings over pgvector | Radically simpler, no server dependency, fast enough at real scale | Would need revisiting at a scale this product is unlikely to reach for a long time | Solving for a scale problem we don't have is exactly the over-engineering this project has avoided throughout |
| Last-write-wins sync over per-field merge | Simple, predictable, fast to build | Real data loss risk in true concurrent-edit scenarios | Acceptable for a mostly single-device, single-editor product; explicitly flagged to revisit if/when shared circles (P1) ship |
| Fine-tuned small function-caller deferred | Avoids blocking MVP on a fine-tuning pipeline without data | Slightly worse footprint/accuracy trade-off during MVP than an optimized future state | Need real extraction examples first — Gemma 4 E2B zero-shot FC is the correct MVP default |

---

**This document supersedes the cloud-AI/pgvector architecture discussed earlier in this project. `FEATURES.md` (scope) and the sprint roadmap remain valid in structure; the database schema and Sprint 2/4 implementation details should be read through this ADR going forward.**
