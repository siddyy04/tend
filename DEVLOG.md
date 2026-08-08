# Tend Development Log



## Sprint 0

- Project created

- Supabase authentication completed

- Isar initialized

- Router implemented

- Authentication UX improved



## Sprint 1A

- Person CRUD against Isar completed

- My Circle grouped by circle tier (empty state, add/edit/soft-delete)

- Shared PersonFormScreen with autoDispose form controller

- Create vs edit keyed only by `personUuid` (fixed create-reuse bug)



## Sprint 1B

- MemoryRepository + validators + sensitivity rules completed

- Person Profile with permanent header + memory timeline

- Manual MemoryFormScreen (create/edit/soft-delete)

- Circle tap → Person Profile; person edit secondary from profile

- Person→memory cascade deferred (see BACKLOG.md)

- Housekeeping: CURSOR_HANDOFF updated for post-1B / Sprint 2 next



## Sprint 2A

- AI provider interfaces + ManualFallbackProvider + GemmaExtractionProvider

- Thin Gemma adapter (sole flutter_gemma import); prompt builder + catalog-backed model path

- Model manager: device capability tiers, download/verify via http, ModelAssistStatus

  (notConfigured / manualMode / modelReady — manual is not permanent setup-complete)

- Text capture → single-candidate confirmation → MemoryRepository.create

- Original Note collapsible reference; user-centric review wording

- No embeddings, FollowUp writes, voice/photo/share, or ClarificationNeeded

- Docs: CURSOR_HANDOFF / CHANGELOG / DEVLOG updated for 2A complete; next Sprint 2B



## Post-2A — LiteRT refactor (ADR-010)

- Renamed `gemma/` → `litert/` (`LiteRtExtractionProvider`, `LiteRtInferenceAdapter`, `LiteRtPromptBuilder`)

- ModelCatalog owns displayName, modelKind, fileKind; MVP default Qwen 2.5 0.5B (1.5B listed as optional upgrade)

- Setup UX: auto-download primary with Downloading / Verifying / Installing / Preparing stages; manual install is fallback with exact path guide

- Docs: ADR-010, ARCHITECTURE, CURSOR_HANDOFF, SPRINT2B paths updated; next Sprint 2B



## Post-2A — Gemma 4 LiteRT-LM (ADR-011)

- Migrated sole production engine to LiteRT-LM (`flutter_gemma_litertlm`); removed MediaPipe / Qwen `.task`

- ModelCatalog: Gemma 4 E2B required (Recommended); Gemma 4 E4B optional (Best Quality)

- Adapter: ModelType.gemma4, `.litertlm`, native FC, GPU → NPU → CPU fallback

- Probe: `GemmaRuntimeProbe` / `probe_main.dart` — same 11-prompt grounding suite as Qwen baseline

- Docs: ADR-011, CHANGELOG v0.3.2, CURSOR_HANDOFF, ARCHITECTURE supersession

- **E2B grounding benchmark (AIN065, GPU, release):** accepted **11/11** (Qwen 0.5B baseline was 2/11); coldStart≈11.0s; warmAvg≈6.2s; peakRss≈1.13 GB; download≈2.41 GB



## Sprint 2A closeout

- Cleanup only (no new features): removed temporary CPU-retry / TextResponse envelope recovery; verbose AI dumps and diagnostics payloads gated with `kDebugMode`

- Extraction product fixes retained: category enum validation, unique person name preselect, `classifyDatePrecision()`, chat `return await` lifecycle fix

- Docs: CURSOR_HANDOFF / DEVLOG / CHANGELOG updated; BACKLOG Create Person during AI Capture (Sprint 2B / Capture UX)

- Analyzer: remaining warnings are Isar generated `experimental_member_use` + catalog constant id style infos — not Sprint 2A app regressions

- **Next:** Sprint 2B



## Sprint 2B

### Phase 2B.1 — Multi-memory extraction (parallel FC)

- Device spike (AIN065, Gemma 4 E2B, GPU): parallel FC vs `candidates[]` on 2–4 fact notes + single-fact control
- **Winner: parallel native function calls** — multi-fact 2/2, 3/3, 4/4 accepted; single-fact 1/1. `candidates[]` matched multi-fact quality but **failed single-fact** (`TextResponse` / markdown JSON protocol break)
- Implemented: flat tool schema + one-call-per-memory prompt; adapter returns all parallel calls; Capture passes full validated candidate list (confirmation UI still single-card until 2B.2)
- Spike harness: `lib/debug/multi_memory_spike_main.dart`

- Same-person follow-up spike (`lib/debug/same_person_multi_memory_spike_main.dart`, AIN065/GPU):
  - Priya career+move+pref+goal: **PASS** 4/4 calls, person=Priya, order OK, no merge/dup
  - Dad retired+walk: **PASS** 2/2
  - Mom surgery+physio+follow-up+recovery: **FAIL** — model returned **3/4** calls (dropped “recovering well”); person/dup OK on returned calls; count/order/merge checks failed as cascade
  - Protocol architecture **locked** as parallel native FC (ADR-012); remaining issues = prompt/model quality
  - Prompt completeness pass: status/recovery guidance + pattern few-shots (avoid literal example quotes that contaminate grounding)
  - Mom re-check after prompt tune: **PASS** 4/4 parallel calls (surgery, physio, recovering well, follow-up scan); ~14.6s GPU

### Phase 2B.2 — Multi-memory confirmation

- Single candidate: existing Sprint 2A confirmation UX unchanged
- Multiple: summary (“We found X memories”, person + event lines, Continue, no checkboxes) → multi-card edit with per-card Save toggle (default ON), selection count, dynamic “Save N memories” button; Original Note preserved
- Routes: `/capture/confirm/summary`, `/capture/confirm/multi`

- Tracked (not blocking 2B.3): AI Quality — pronouns/compound completeness → `BACKLOG.md` + `EXTRACTION_COMPLETENESS_BENCHMARK.md`

### Phase 2B.3 — Create Person during capture

- Confirmation: when `personMentioned` has no exact Circle match (trimmed, case-insensitive), show **Create "&lt;name&gt;"**
- Dialog: Name / Relationship / Circle; create only on explicit confirm; select new person; stay on confirmation
- Duplicate exact name → select existing unique match or block ambiguous create
- Exact unique match still auto-selects (unchanged)

- Prompt: insufficient-information notes must yield zero FunctionCalls (no invent-to-satisfy-tool); regression I1–I6 in `EXTRACTION_COMPLETENESS_BENCHMARK.md`
- Backlog UX (not implemented): clearer empty-capture copy for insufficient notes

### Phase 2B.4 — Voice capture

- Mic on Capture → recording screen (indicator, timer, Stop, Cancel) → platform STT (`speech_to_text` via `PlatformTranscriptionProvider`) → editable transcript → Continue into existing `CaptureController.submitText` / confirmation path
- Permissions: `permission_handler` + Android `RECORD_AUDIO` / speech RecognitionService query; iOS mic + speech usage strings
- No live transcription UI, no AI during recording, cancel discards with no draft
- `sourceType = voice` on save; audio file `sourceRef` deferred (backlog: persist audio + retention policy)
- **Architecture:** Voice UI depends on `activeTranscriptionProvider` (abstract `TranscriptionProvider`); platform STT is the MVP concrete impl only — long-form conversational transcription is a product goal; engine evaluation is High Priority backlog (no new engine in 2B.4)
- Speech language: auto-detect device/system locale when possible; otherwise prompt once; persist in Settings (`SpeechLocalePreferences`) for all future STT providers
- Backlog: live transcription, waveform, VAD, voice analytics, audio retention; Capture UX Polish for first-class Voice/OCR/Share actions (after 2B.5–2B.6)

### Phase 2B.5 — OCR / Photo capture

- Capture camera icon → Take photo / Choose from gallery → preview (no OCR yet) → Continue → ML Kit on-device OCR (`PlatformOCRProvider`) → editable text → `CaptureSubmitFlow` / confirmation
- Permissions: camera + photos; permanently denied → settings messaging; no repeated prompts
- Empty OCR: friendly message, no Gemma call; try another image or back to Capture
- Image copied to `documents/captures/` as `sourceRef`; `sourceType = photo`
- Architecture: UI depends on `activeOCRProvider` only; engine replaceable later
- Backlog: handwriting, document detection/crop/perspective, multi-page, batch, confidence overlay, enhancement, OCR language, AI vision, image retention

### Capture empty-state UX (post–2B.5)

- Distinguished Success / Empty / Failure across Typed, Voice, OCR via `CaptureSubmitFlow`
- Empty: friendly panel + examples; mapping/grounding strings debug-only
- Failure only for genuine pipeline issues (`lastPipelineFailureReason` / exceptions)
- Prompt: no placeholders (N/A/None/Unknown/-); zero calls when no person + stable memory

### Phase 2B.7 — Capture UX Polish

- `ClarificationNeeded` on `ExtractionResult` / confirmation args; populated only for ambiguous exact Circle names
- Passive `ClarificationNote` (passive); `NeedsReviewChip` when below threshold (no High/Medium badges)
- Found-memories banner on confirmation; extracting status on Typed/Voice/OCR/Share
- `CaptureAnalytics` hooks (started/completed/duration/counts/edited/person-created)
- Next gate: **Sprint 2B.8 RC** (`SPRINT2B8.md`) — explicit exit criteria + `RELEASE_READINESS_REPORT.md` (Go for ~100 beta) before Sprint 3


- Android `SEND` `text/*` intent-filter; `launchMode=singleTask`
- `PlatformShareIntentHandler` (`receive_sharing_intent`) → pending share → `/capture/share`
- Cold start: initial media held through splash/auth; redirect to Share Capture instead of Circle when pending
- Warm start: media stream navigates to Share Capture
- Editable shared text → `CaptureSubmitFlow` with `SourceType.share`; shared empty-state panel
- Backlog: share images→OCR, PDFs, multi-item, HTML cleanup, article extraction, email metadata, threads, audio→voice, share analytics

## Foundation Cleanup — pre-Sprint 3

- Item A: `FollowUp.deletedAt` / Postgres `deleted_at` — SCHEMA + Isar collection aligned with ARCHITECTURE (zero rows; no data migration)
- Item C: `PersonRepository.getByUuid` filters soft-deletes (`uuidEqualTo` + `deletedAtIsNull`); unit test added
- Item B: `resolveRelativeDate` / `resolveDateValueForPersistence` in `domain/rules/`; wired on confirmation + memory form saves; one-time prefs-gated backfill on startup (`migration_relative_date_backfill_v1`)
- Docs: BACKLOG entries resolved; CHANGELOG/CURSOR_HANDOFF updated
- Next remains **2B.8 RC** — cleanup does not replace or bypass the Release Candidate gate

## Sprint 2B.8 — Capture Release Candidate

- RC hardening: R8 ProGuard for ML Kit optional packs; human multi-confirm errors; double-submit guards; STT error forwarding; Share log gating; Voice/Photo a11y labels
- Device QA (AIN065, Android 16, GPU): grounding probe 11/11; warmAvg≈6.3s; coldStart≈11.3s; peakRss≈1.15 GB; Typed full path + Share cold-start verified
- Owner smokes (2026-08-08): Voice→Save, OCR→Save, airplane-mode extract — no release-blocking issues; Conditional Pass conditions satisfied
- `RELEASE_READINESS_REPORT.md`: **Go** (product sign-off recorded). Sprint 2 closed.
- Next: **Sprint 3 planning** (architecture review) — no Sprint 3 implementation until plan is approved

