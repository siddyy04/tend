# Tend — Cursor Handoff

**Purpose:** Onboard a new Cursor chat to continue Tend development without prior conversation history.  
**Product:** Tend — offline-first personal relationship memory app (Flutter).  
**Last updated:** Sprint **3 Phase 3.3/3.4 complete** — hybrid Search + stabilization **PASS** (M7 fixed via Gecko `releaseResident` before extract; warm avg **7163 ms**). QA: [`SPRINT3_3_QA.md`](SPRINT3_3_QA.md). **Next:** single commit + `v0.5.0` tag, then Sprint 4 planning (not implementation until planned).

---

## 1. Current project status

- **Sprint 0 / 1A / 1B / 2A / 2B (through 2B.8):** Done and closed. Capture RC signed off — see [`RELEASE_READINESS_REPORT.md`](RELEASE_READINESS_REPORT.md) (**Go**; Conditional Pass conditions satisfied 2026-08-08).
- **Post-2A architectural gate:** Done — LiteRT provider rename + catalog (ADR-010); **Gemma 4 E2B** as sole MVP model via LiteRT-LM (ADR-011). Qwen / MediaPipe `.task` retired from production.
- **Foundation Cleanup (pre-Sprint 3):** Done — `FollowUp.deletedAt` schema contract; `PersonRepository.getByUuid` soft-delete filter; relative-date resolution + backfill. See `FOUNDATION_CLEANUP.md` / CHANGELOG.
- **Sprint 3 Phase 3.1:** Done — global + person-scoped **keyword** Search.
- **Sprint 3 Phase 3.2:** Done — embedding spike; Conditional Go (Gecko).
- **Sprint 3 Phase 3.3:** Done — tiered hybrid Search (keyword Tier 1 + Gecko Tier 2).
- **Sprint 3 Phase 3.4:** Done — stabilization PASS; M7 fixed (release Gecko before extract). See [`SPRINT3_3_QA.md`](SPRINT3_3_QA.md).
- **Working app:** Auth, Isar, Person/Memory CRUD, Capture (4 modes), keyword + optional semantic Search.
- **Next work:** Create **`v0.5.0` commit + tag** when asked; then Sprint 4 (Suggestion Engine) **planning** only until a Sprint 4 spec is approved.
- **Still later:** Sprint 4 implementation.
- **Deferred product debt:** see `BACKLOG.md` (e.g. person→memory cascade; Search polish). Smaller accepted decisions: see `ADR.md`.

**Binding docs:** `ARCHITECTURE.md`, `ADR.md`, `FEATURES.md`, `SCHEMA.md`, `DEVELOPMENT_ROADMAP.md`, `SPRINT0.md`–`SPRINT2B8.md`, `SPRINT3.md`, `SPRINT3_1.md`, `SPRINT3_2.md`, `SPRINT3_2_FINDINGS.md`, `SPRINT3_3.md`, `SPRINT3_3_IMPLEMENTATION.md`, `SPRINT3_3_QA.md`, `RELEASE_READINESS_REPORT.md`, `DEVLOG.md`, `BACKLOG.md`, this file.

---

## 2. Sprint 2A — closed

Text-only AI-assisted capture pipeline (see `SPRINT2A.md`; concrete types use LiteRT names per ADR-010/011):

- Four AI **interfaces**: `ExtractionProvider`, `EmbeddingProvider`, `TranscriptionProvider`, `OCRProvider`
- Concrete extraction: `LiteRtExtractionProvider` + `ManualFallbackProvider` (spec’s `GemmaExtractionProvider` → LiteRT rename)
- Thin inference adapter: sole production `flutter_gemma` / LiteRT-LM import under `lib/ai/providers/litert/`
- Model manager: capability tiers, `ModelCatalog`, download/`http`, checksum verify, `ModelAssistStatus`
- Global capture FAB → setup or capture; confirmation → `MemoryRepository.create`
- Original Note (read-only, collapsed); user-centric “Review before saving” copy
- Product polish landed in 2A closeout era: category enum validation (no silent `preferences` fallback), unique case-insensitive person preselect, `classifyDatePrecision()` for explicit vs relative dates, chat lifecycle fix (`return await` before `chat.close()`)
- Debug: verbose AI dumps / probe route gated with `kDebugMode`; release keeps compact diagnostics only
- **Out of 2A (intentional):** embeddings persistence, FollowUp writes, voice/photo/share, multi-candidate UI, `ClarificationNeeded`, inline Create Person

**Known AC nuance:** warm capture is ~6s; **cold first load ~11s** on benchmark device can miss the “well under 10s” wording for the absolute first inference after prepare.

---

## 3. Current architecture (post–LiteRT + Gemma 4)

```
UI (features/*)
  → Riverpod providers/controllers (manual style)
    → domain/repositories (ONLY Isar touchpoint)
      → Isar (isar_community) = source of truth

AI:
  Capture / Confirmation
    → activeExtractionProvider
         → LiteRtExtractionProvider  OR  ManualFallbackProvider
              → LiteRtInferenceAdapter  (flutter_gemma + LiteRtLmEngine only here)
                   → ModelDownloadManager + ModelCatalog (artifact path/version/kind)
              → beforeInference: GeckoInferenceAdapter.releaseResident()
                   (drop embedder worker before Gemma extract; M7)

  Search / post-save embed / backfill
    → AiInferenceMutex (extraction > embedding)
    → GeckoEmbeddingProvider → GeckoInferenceAdapter
         (flutter_gemma_embeddings only here)
```

Capture / Confirmation / repos / validation stay model-agnostic. Collection fields: **`SCHEMA.md` only** (not duplicated in `ARCHITECTURE.md`).

---

## 5. AI layer currently implemented

| Piece | Status |
|---|---|
| `ExtractionProvider` + result types | Done (no `clarificationNeeded` in 2A) |
| `TranscriptionProvider` | Abstract; MVP concrete = `PlatformTranscriptionProvider` via `activeTranscriptionProvider`; long-form engine TBD (High Priority backlog) |
| `OCRProvider` | Abstract; MVP concrete = `PlatformOCRProvider` (ML Kit) via `activeOCRProvider` |
| `ShareIntentHandler` | Abstract; MVP = `PlatformShareIntentHandler` (`receive_sharing_intent`) → editable text → `SourceType.share` |
| `EmbeddingProvider` | Done — `GeckoEmbeddingProvider` (+ `NoOpEmbeddingProvider` when Gecko absent) |
| `LiteRtExtractionProvider` | Done — maps tool-call args → `ExtractionResult`; `beforeInference` → `releaseResident()` |
| `ManualFallbackProvider` | Done — empty candidates |
| `LiteRtInferenceAdapter` | Done — LiteRT-LM + native FC; GPU→NPU→CPU; install kinds from catalog |
| `GeckoInferenceAdapter` | Done — sole `flutter_gemma_embeddings` import; `releaseResident()` for M7 |
| `AiInferenceMutex` | Done — extraction priority over embedding |
| `LiteRtPromptBuilder` | Done — prompts + tool schema (no SDK import) |
| `extraction_validation_rules` / `extraction_defaults` | Done |
| Capture + confirmation + save | Done (Typed / Voice / OCR / Share → same `CaptureSubmitFlow`) |
| Model capability + download manager + setup UI | Done (staged: Downloading / Verifying / Installing / Preparing) |
| ClarificationNeeded + confidence polish | **2B.7 done** |
| Capture RC stabilization (E2E, perf, offline, cleanup, release notes) | **2B.8 done** — Go; owner sign-off 2026-08-08 (`RELEASE_READINESS_REPORT.md`) |
| Sprint 3 Search (3.1–3.4) | **Done** — keyword + optional Gecko Tier 2; Phase 3.4 PASS |
| Sprint 4 (Suggestion Engine) | **Planning next** — no implementation until Sprint 4 spec approved |
| Embeddings persistence | Done (async post-save + backfill; `embeddingModelVersion` in `SCHEMA.md`) |

**Capture / Confirmation / repositories must not import `flutter_gemma`.** Only `litert_inference_adapter.dart` may (plus debug probe under `lib/debug/`).  
**Nothing outside `gecko_inference_adapter.dart` may import `flutter_gemma_embeddings`.**

---

## 6. Model catalog (ADR-011)

- Runtime = **LiteRT-LM** (`LiteRtLmEngine`). Active weights = **`ModelCatalog.current`**.
- MVP required: **Gemma 4 E2B IT** (`gemma4-e2b-it-v1`) — Recommended.
- Optional: **Gemma 4 E4B IT** (`gemma4-e4b-it-v1`) — Best Quality for capable devices.
- Format: `.litertlm` (not MediaPipe `.task`).
- Each `ModelArtifactSpec` includes: `versionId`, `displayName`, `fileName`, `downloadUrl`, `sha256`, `modelKind`, `fileKind`, `backendPreference`, size fields.
- **Qwen / MediaPipe path retired** from production. Catalog still maps unused `LiteRtModelKind` / `LiteRtFileKind.task` enum values to the SDK for model-agnosticism — no Qwen artifact is listed or downloadable.
- **Gemma 3n Preview** remains abandoned.

**Download UX policy:**

1. Automatic download is the default path (public HTTPS; override via `TEND_MODEL_DOWNLOAD_URL`).
2. Setup shows staged progress: Downloading → Verifying → Installing → Preparing model.
3. Manual installation is fallback only (download failure, no URL, or user chooses “Install manually”).
4. Manual guide shows exact file name + absolute destination folder/path.

**Grounding probe (debug only):** `lib/debug/probe_main.dart` / `GemmaRuntimeProbe` / `/debug/gemma-probe` — same 11 notes as the Qwen baseline; route registered only when `kDebugMode`.

---

## 7. Packages and dependencies

**SDK:** Dart `^3.12.2` / Flutter stable.

| Package | Role / constraint |
|---|---|
| `isar_community` `3.3.2` | Local DB (pinned w/ generator) |
| `isar_community_flutter_libs` `3.3.2` | Native Isar |
| `isar_community_generator` `3.3.2` | Codegen (dev) |
| `flutter_riverpod` `3.2.1` | State (manual providers in app code) |
| `riverpod_annotation` `4.0.2` / `riverpod_generator` `4.0.3` | Available; largely unused |
| `build_runner` `>=2.12.0 <2.15.2` | Codegen pin |
| `go_router` `^17.4.0` | Navigation |
| `supabase_flutter` `^2.17.1` | Auth only |
| `path_provider` `^2.1.6` | Paths |
| `path` `^1.9.1` | Path join |
| `uuid` `^4.6.0` | Client UUIDs |
| `flutter_gemma` `^1.5.2` | On-device LiteRT LLM API bridge (extraction / Gemma 4) |
| `flutter_gemma_litertlm` `^1.3.1` | LiteRT-LM engine (`.litertlm`) |
| `flutter_gemma_embeddings` `^1.0.4` | On-device Gecko embedder (Phase 3.3+; via `GeckoInferenceAdapter` only) |
| `device_info_plus` `^13.2.0` | RAM / capability |
| `http` `^1.6.0` | Model download |
| `crypto` `^3.0.7` | Checksums |
| `shared_preferences` `^2.5.5` | Assist status / model version prefs |
| `freezed` / `json_*` | Present; pins for analyzer |
| `flutter_lints` `^6.0.0` | Lint |

**Import Isar as** `package:isar_community/isar.dart`.  
**Do not casually upgrade** Riverpod / `build_runner` past pinned ranges (Isar codegen analyzer conflict).

**Dart-defines:** `SUPABASE_URL`, `SUPABASE_ANON_KEY`; optional `TEND_MODEL_DOWNLOAD_URL`, `TEND_MODEL_SHA256`.

---

## 8. Known technical debt and open decisions

**Track full lists in `BACKLOG.md` and decisions in `ADR.md`.** Highlights:

| Item | Notes |
|---|---|
| Device RAM floors | Informed by Phase 3.3/3.4 QA (~250 MB Gecko ΔRSS; hybrid soak ~1.21–1.35 GB; see `ARCHITECTURE.md` §7 / `SPRINT3_3_QA.md`) |
| Public download URL / rehost | Default HF litert-community URL (needsAuth: false); rehost optional |
| Optional E4B picker UX | Catalog has E4B; Settings UI to select upgrade still thin |
| Person→memory cascade delete | FEATURES P0; deferred (~Sprint 6) |
| Auth phone OTP vs email/password | FEATURES vs shipped path |
| Temporary Logout on My Circle | Move to Settings later |
| App theme stub | Still Sprint 0 scaffolding |
| Tier 2 / confidence thresholds `0.70` | Calibrated in Phase 3.4; retune with more query-log data |
| FunctionGemma / small FC fine-tune | ARCHITECTURE P1 after real capture examples — not MVP default |
| Create Person during AI Capture | **Done in 2B.3**; similar-name suggestions remain backlog |
| AI Quality — pronouns / compound sentences | Medium backlog; suite in `EXTRACTION_COMPLETENESS_BENCHMARK.md` — prompt-only, ADR-012 invariant |

---

## 9. Things future chats must not change (without product decision)

- Do **not** replace `isar_community`, Riverpod, go_router, or Supabase Auth
- Do **not** query Supabase for app data tables before Sprint 5
- Do **not** invent/rename SCHEMA fields; no hard deletes; do **not** duplicate collection field lists into `ARCHITECTURE.md`
- Do **not** treat `manualMode` as permanent setup-complete
- Do **not** create FollowUps from capture save (until Suggestion Engine / FollowUp sprints)
- Do **not** import `flutter_gemma` outside `litert_inference_adapter.dart` (except debug probe)
- Do **not** import `flutter_gemma_embeddings` outside `gecko_inference_adapter.dart`
- Do **not** remove `AiInferenceMutex` or `releaseResident()`-before-extract without re-measuring M7 on device
- Do **not** reintroduce MediaPipe `.task` / Qwen / Gemma 3n as a production extraction stack
- Do **not** hardcode model install kinds in Capture — keep them on `ModelCatalog`
- Do **not** change the extraction contract **one FunctionCall → one `ExtractedMemoryCandidate`** (ADR-012); prompt refinements only

---

## Quick start prompt for a new chat

> Read `CURSOR_HANDOFF.md`, `ARCHITECTURE.md`, `ADR.md` (especially ADR-010/011/013), `BACKLOG.md`, `SCHEMA.md`, `FEATURES.md`, `SPRINT3_3_QA.md`. Sprint 3 Search (3.1–3.4) is **closed** — hybrid keyword + optional Gecko Tier 2; M7 uses `releaseResident()` before extract. MVP extraction is **Gemma 4 E2B** via LiteRT-LM; embeddings are **Gecko** via `flutter_gemma_embeddings`. **Next:** `v0.5.0` commit/tag when asked, then **Sprint 4 Suggestion Engine planning** only — no implementation until a Sprint 4 spec is approved. Do not implement sync or cascade delete early.

---

## Related paths

| Doc | Role |
|---|---|
| `ARCHITECTURE.md` | Binding system architecture |
| `ADR.md` | Smaller accepted decisions — **read for why** |
| `BACKLOG.md` | Deferred product/tech debt — **read for what’s parked** |
| `FEATURES.md` | P0/P1 scope + acceptance |
| `SCHEMA.md` | Exact data model |
| `DEVELOPMENT_ROADMAP.md` | Sprint sequence |
| `DEVLOG.md` | Human progress notes |
| `CHANGELOG.md` | User-visible changes |
| `EVALUATION_TEST.md` | Capture / extraction eval notes |
| `EXTRACTION_COMPLETENESS_BENCHMARK.md` | Pronoun / compound multi-memory regression cases |
| `SPRINT3.md` / `SPRINT3_3_QA.md` | Sprint 3 Search scope + Phase 3.4 QA verdict |
| `SPRINT2B.md` | Closed Capture RC specification |
