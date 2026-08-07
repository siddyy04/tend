# ADR-0001 — Tend Architecture: Offline-First, On-Device AI, Local-First Sync

**Status:** Accepted
**Applies to:** all implementation work from Sprint 0 onward
**How to use this with Cursor:** paste this whole file into the repo as `ARCHITECTURE.md` and treat it as binding. Prompt pattern: *"Follow ARCHITECTURE.md exactly — if a task requires deviating from it, stop and ask rather than improvising."* Business logic must never import a vendor SDK (`flutter_gemma` / LiteRT bridge, Supabase) directly outside the specific provider/repository files named below.

**Supersession note (ADR-010 / ADR-011):** Concrete MVP extraction is a **model-agnostic LiteRT** layer (`lib/ai/providers/litert/`) with **Gemma 4 E2B** as the default catalog model via **LiteRT-LM** (`.litertlm`). Optional **Gemma 4 E4B** is catalog-listed for capable devices. Historical “Gemma 3n” / Qwen / MediaPipe `.task` wording below is superseded for the active runtime; treat ADR-011 + `ModelCatalog` as authoritative.

---

## 0. Summary of the decision

Isar (via `isar_community`) is the single source of truth on-device. All AI (extraction, embeddings) runs locally through a swappable provider interface, backed by a **LiteRT-LM** runtime with the active model selected via `ModelCatalog` (MVP: Gemma 4 E2B; optional E4B — see ADR-011). Supabase is demoted to authentication + optional, opt-in, encrypted backup/sync — never a dependency for core app function. No OpenAI, no pgvector, no server-side inference for MVP.

| Layer | Choice | Role |
|---|---|---|
| Local database | Isar (`isar_community` fork) | Source of truth, works fully offline |
| State management | Riverpod (code-gen) | All business logic, no logic in widgets |
| AI inference | On-device LiteRT-LM (via `flutter_gemma` + `flutter_gemma_litertlm`), behind an abstract provider interface; model chosen by `ModelCatalog` (MVP: Gemma 4 E2B) | Extraction + embeddings |
| ASR (voice-to-text) | Platform-native speech-to-text | Not the LLM — see Section 6 for why |
| OCR (screenshots) | Platform-native on-device OCR (ML Kit / Vision) | Not the LLM — see Section 6 for why |
| Backend | Supabase | Auth + optional backup/sync only |
| Semantic search | Local embeddings + brute-force cosine scan in Dart | No pgvector, no ANN index needed at MVP scale |

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
│                                │        └──> LiteRT LLM (on-device, │
│                                │             flutter_gemma bridge)  │
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
2. Voice → platform ASR → text. Photo → platform OCR → text.
3. Text goes to the local `ExtractionProvider` (LiteRT model via function calling).
4. Extraction result (matching the Deliverable 5 JSON schema exactly) is validated: confidence thresholds, grounding-quote check, taxonomy check — all unchanged from the original design.
5. Result written to a Riverpod state → confirmation card renders → user confirms/edits.
6. On confirm: write to Isar (`memories` collection), `syncStatus = pending`, `updatedAt = now()`.
7. Isar write triggers a watcher → UI updates immediately (no network round-trip in the critical path — this is the entire point of local-first).
8. If sync is enabled and connectivity exists, a background task later pushes the pending record to Supabase. If not, nothing blocks the user; the record is fully functional locally.

**Suggestion Engine flow:** unchanged from Deliverable 6 in logic, changed in execution — a scheduled local background task (`workmanager`) queries Isar directly (no cloud round-trip), scores candidates with the same rule-based formula, writes to the local `suggestion_log` collection, and triggers a local notification.

**Search flow:** query text → local embedding via the same `EmbeddingProvider` → brute-force cosine similarity scan across the user's `memories` in Isar → ranked results, each traceable to its source memory.

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
        litert_inference_adapter.dart    # sole flutter_gemma import
        litert_prompt_builder.dart
      manual/
        manual_fallback_provider.dart    # no-AI fallback for unsupported devices
    model_manager/
      model_catalog.dart           # active model + displayName / install kinds
      model_download_manager.dart  # download, verify, version check
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

**Rule for Cursor:** nothing outside `ai/providers/litert/litert_inference_adapter.dart` may import `flutter_gemma`. Nothing outside `data/local/isar/` and `domain/repositories/` may import Isar directly. This is what makes Section 6's provider swap and any future database swap actually possible instead of theoretical.

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

### Collections (mirrors the Deliverable 4 ontology, with sync fields added to every collection)

```dart
@collection
class Person {
  Id id = Isar.autoIncrement;         // local-only fast key, never synced directly
  @Index(unique: true)
  late String uuid;                   // stable cross-device identity (client-generated v4 uuid)
  late String name;
  @enumerated
  late CircleTier circleTier;
  String? relationshipType;
  late DateTime createdAt;
  late DateTime updatedAt;            // sync: last local modification
  @enumerated
  late SyncStatus syncStatus;         // pending | synced | conflict
  DateTime? deletedAt;                // tombstone — null means not deleted
}

@collection
class Memory {
  Id id = Isar.autoIncrement;
  @Index(unique: true)
  late String uuid;
  @Index()
  late String personUuid;             // FK by stable uuid, not local Isar id
  @enumerated
  late MemoryCategory category;
  late String eventText;
  String? quoteEvidence;
  @enumerated
  late DatePrecision datePrecision;
  String? dateValueRaw;
  DateTime? dateValue;
  late int importanceScore;           // 1-5
  double? extractionConfidence;       // null if manually entered
  double? personMatchConfidence;
  @enumerated
  late SensitivityLevel sensitivityFlag;
  @enumerated
  late SourceType sourceType;
  String? sourceRef;                  // local file path, not a cloud URL
  late bool needsUserConfirmation;
  List<double>? embedding;            // local semantic search vector — see Section 8
  late DateTime createdAt;
  late DateTime updatedAt;
  @enumerated
  late SyncStatus syncStatus;
  DateTime? deletedAt;
}

@collection
class FollowUp {
  Id id = Isar.autoIncrement;
  @Index(unique: true)
  late String uuid;
  @Index()
  late String memoryUuid;
  String? note;
  DateTime? expectedDate;
  @enumerated
  late FollowUpStatus status;         // open | done | dismissed
  DateTime? resolvedAt;
  late DateTime createdAt;
  late DateTime updatedAt;
  @enumerated
  late SyncStatus syncStatus;
  DateTime? deletedAt;
}

@collection
class SuggestionLogEntry {
  Id id = Isar.autoIncrement;
  @Index(unique: true)
  late String uuid;
  @Index()
  late String followUpUuid;
  late DateTime surfacedAt;
  String? reasonShown;
  String? actionTaken;                // 'acted' | 'dismissed' | 'not_now'
  String? userFeedback;
  late DateTime updatedAt;
  @enumerated
  late SyncStatus syncStatus;
}
// Connection / connection_memories / connection_people: same pattern, deferred to P1
// per FEATURES.md — schema stub only, not implemented in MVP.
```

### Why a `uuid` field alongside Isar's own `Id`
Isar's `autoIncrement` id is a fast local integer, but it is **not safe to sync** — two devices will independently generate colliding integers. Every syncable collection carries its own client-generated UUID as the stable identity used for foreign keys, sync, and the Supabase mirror. Isar's own `id` never leaves the device.

### Why every collection carries `updatedAt` / `syncStatus` / `deletedAt` from day one
Even though the sync engine (Section 5) isn't built until later in the roadmap, retrofitting these fields onto existing local data after the fact is the kind of migration worth avoiding entirely. Cheap to include now, expensive to add later.

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
}

abstract class OCRProvider {
  Future<String> extractText(String imageFilePath);
}
```

Concrete implementations live behind these interfaces:
- `LiteRtExtractionProvider` — on-device LiteRT-LM via `flutter_gemma`, using **function-calling mode** to enforce the Deliverable 5 JSON schema. Which weights run is decided by `ModelCatalog` (MVP: Gemma 4 E2B), not by Capture/Confirmation.
- `PlatformTranscriptionProvider` — wraps iOS Speech framework / Android `SpeechRecognizer`, **not the LLM**. See rationale below.
- `PlatformOCRProvider` — wraps ML Kit / Vision on-device text recognition, **not the LLM**. Same rationale.
- `ManualFallbackProvider` — a null-object implementation for devices that can't run a local model (Section 7): `extract()` returns "needs manual entry" instead of throwing, `embed()` returns null and search silently degrades to keyword-only. The app must never crash or block capture because the model isn't available — it should just quietly become the pre-AI version of itself.

### Why ASR and OCR are platform-native, not the LLM, even though Gemma 3n is multimodal
Gemma 3n *can* take audio and image input directly, but routing every voice note or screenshot through the full multimodal model is the heavier, slower, more battery-costly path for a job that mature, purpose-built on-device APIs already do accurately, near-instantly, and with zero extra download. Reserve the LLM for what only it can do — structured reasoning over text — and let the OS do transcription and text recognition. This also shrinks the required model footprint, which matters directly for Section 7's device-compatibility story.

---

## 7. Model Management Strategy

**Bundled vs. downloaded:** download on first run, not bundled in the app binary. Bundling a multi-GB model blows past app store size norms and means every model update requires a full app-store release cycle. Download-on-first-run, store in the app's documents directory, and let model updates ship independently of app releases.

**Update flow:**
- On launch, check the bundled model manifest against the latest known version (a small remote config check, not a full re-download).
- If a newer model is available, offer it as an optional download — never force it mid-session, never silently swap a model out from under an in-progress capture.
- Verify the downloaded model against a checksum before use; if verification fails, fall back to the previously working model rather than a corrupt one.

**Unsupported / low-memory devices — the real risk to design for, not an edge case:**
- Gemma 3n E2B needs roughly 3GB of RAM just for the model. On a 6GB device, the model and the camera can't both be resident — the OS will kill something.
- At first launch, run a `device_info_plus`-based capability check (available RAM, OS version) **before** offering the model download.
- **Tiered behavior, not a hard cutoff:**
  - **≥8GB RAM:** full experience — Gemma 3n E2B, multimodal-capable, all AI features on.
  - **~6GB RAM:** Gemma 3n E2B works, but disable simultaneous camera+model use in the UI (defer image capture to gallery-picker style flows rather than live camera during an active model session).
  - **Below a defined floor (device can't comfortably run any local model):** ship with `ManualFallbackProvider` — capture, editing, Today's Opportunities, and the rest of the product work exactly as designed, just without AI-assisted extraction or semantic search. The product's core value doesn't require AI to function, only to be effortless — this is a genuinely acceptable degraded mode, not a broken one.

### Model recommendation — don't use one model for everything

This is the one place I'd actively push back on "just ship Gemma 3n E2B for every AI task":

- **Extraction (text → structured Memory JSON):** start with **Gemma 3n E2B in zero-shot function-calling mode** for MVP — it works out of the box with no training data required, which matters because you don't have any extraction examples to fine-tune with yet.
- **Once you have real usage data (post-Concierge-pilot / post-beta):** fine-tune **FunctionGemma (270M)** — a Gemma 3 270M variant purpose-built for function calling — on your own captured extraction examples. Google's own benchmark shows accuracy jumping from 58% zero-shot to 85% after task-specific fine-tuning; it is explicitly *not* meant to be used zero-shot. That fine-tuning requirement is exactly why it isn't the Sprint 2 default — you need real examples first — but once you have them, a fine-tuned 270M specialist is dramatically smaller (a few hundred MB vs. ~3GB), faster, and runs comfortably on lower-RAM devices than a general-purpose Gemma 3n, likely *improving* extraction accuracy on your narrow, well-defined task rather than trading accuracy for size. Treat this as a defined P1 roadmap item, not a someday-maybe: it directly widens your supported-device floor.
- **Embeddings:** use Gemma 3n's built-in embedding support (via `flutter_gemma`) rather than a separate model/pipeline — one less thing to download and version.
- **ASR/OCR:** platform-native, as covered in Section 6 — never the LLM.

This staged plan is exactly why the provider abstraction in Section 6 exists: swapping the `ExtractionProvider` implementation from Gemma-3n-zero-shot to fine-tuned-FunctionGemma later is a contained change, not a rearchitecture.

---

## 8. Semantic Search Architecture

- Generate an embedding for each memory **at capture time** (via `EmbeddingProvider`, one extra local inference call already inside the existing capture latency budget) and store it directly on the `Memory` collection as `List<double>`.
- At query time, embed only the query string (cheap — one short text) and run a **brute-force cosine similarity scan in Dart** across the user's memories.
- **This is a deliberate simplification, not a compromise.** pgvector's ANN indexing (ivfflat/HNSW) exists to solve a scale problem — millions of vectors — that a single user's personal relationship history will never approach. Realistic per-user scale is hundreds to low thousands of memories; scanning that many short float vectors is on the order of milliseconds on a phone CPU. No index is needed at MVP.
- **Escape hatch, not needed now:** if a power user's dataset ever grows large enough that the linear scan becomes noticeable, add a keyword pre-filter using Isar's native indexed/full-text query capability to narrow candidates before the vector scan — cheap to add later, not worth building speculatively now.
- **Worth instrumenting before over-investing further:** structured filtering (by person, category, date range) may cover most real "search" behavior in early usage, with semantic recall needed less often than assumed. Cheap to check with real beta data; expensive to have built a bigger pipeline than the actual usage pattern needed.

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
| `flutter_gemma` + `flutter_gemma_litertlm` | On-device LiteRT-LM inference bridge (extraction, embeddings), via the provider abstraction only |
| `supabase_flutter` | Auth + optional backup/sync client |
| `workmanager` | Background sync engine + daily Suggestion Engine job |
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
| On-device Gemma 3n over cloud LLM | No per-call cost, real privacy, offline capability | Weaker extraction accuracy than a frontier cloud model; real device-fragmentation risk | Directly serves the stated goals (privacy, cost, offline); mitigated by conservative confidence defaults and tiered device support |
| Platform-native ASR/OCR over multimodal LLM | Better accuracy, lower RAM/battery cost, smaller required model | One more provider interface to maintain | The LLM should do what only it can do — structured reasoning — not tasks mature OS APIs already do better |
| Brute-force local embeddings over pgvector | Radically simpler, no server dependency, fast enough at real scale | Would need revisiting at a scale this product is unlikely to reach for a long time | Solving for a scale problem we don't have is exactly the over-engineering this project has avoided throughout |
| Last-write-wins sync over per-field merge | Simple, predictable, fast to build | Real data loss risk in true concurrent-edit scenarios | Acceptable for a mostly single-device, single-editor product; explicitly flagged to revisit if/when shared circles (P1) ship |
| Fine-tuned FunctionGemma deferred to P1 | Avoids blocking MVP on a fine-tuning pipeline you don't have data for yet | Slightly worse footprint/accuracy trade-off during MVP than the optimized future state | You need real extraction examples before fine-tuning helps at all — Gemma 3n E2B zero-shot is the correct MVP default |

---

**This document supersedes the cloud-AI/pgvector architecture discussed earlier in this project. `FEATURES.md` (scope) and the sprint roadmap remain valid in structure; the database schema and Sprint 2/4 implementation details should be read through this ADR going forward.**
