# Changelog

All notable user-visible changes to Tend will be documented here.

This project follows a simple chronological changelog.

---

# v0.5.0 — Phase 3.3 hybrid semantic search + 3.4 stabilization

## Added

- Optional on-device **Gecko** embedder (~114 MB) for “possibly related” search results (Tier 2)
- Settings: download, defer, or prepare the semantic search model
- Async embedding after memory save + foreground backfill while the app is open
- Shared on-device inference lock so capture extraction and embedding never run at the same time

## Fixed

- Warm extraction latency with Gecko loaded — embedder worker is released before Gemma inference (keeps ≤8 s capture gate)

## Notes

- Keyword search (Tier 1) unchanged; Tier 2 threshold calibrated to **0.70**
- Phase 3.4 QA: all M1–M12 + mutex soak **PASS** on AIN065 release — see `SPRINT3_3_QA.md`
- Architecture unchanged: tiered hybrid, async queue, mutex, foreground-only backfill
- Docs sync (pre–Sprint 4): `SCHEMA.md` sole collection SoT; device-tier numbers from QA; `flutter_gemma_embeddings` + `releaseResident()` captured in `ARCHITECTURE.md`

---

# v0.4.2 — Phase 3.2 embedding spike (decision only)

## Notes

- Research spike complete: Gemma 4 E2B cannot embed via current bridge; **Conditional Go** for Phase 3.3 using public **Gecko-110m-en** (768-d) — see `SPRINT3_2_FINDINGS.md` / ADR-013
- No user-facing Search behavior change; Phase 3.1 keyword Search unchanged
- `flutter_gemma_embeddings` added for spike harness only (production does not register embedding backends yet)

---

# v0.4.1 — Capture Quality: pronoun binding

## Fixed

- Pronoun continuations in multi-sentence notes (e.g. “Met Rahul yesterday. He got selected by OpenAI.”) — prompt asks for separate tool calls with the named person; app binds empty/pronoun `personMentioned` when a single prior name is unambiguous
- Verbatim quote grounding no longer false-rejects when only whitespace/newlines differ from the note

## Notes

- Device trace pre-fix: one merged FunctionCall (OpenAI fact kept, meeting fact dropped)
- Post-fix device re-trace: still often one FunctionCall (model merge); binder cannot invent a missing call — remaining completeness gap is model-side
- App-layer binder fails safe when two+ distinct people already appeared (no guessing)
- ADR-012 unchanged; no NLP coreference pipeline
- Regression: `pronoun_person_binding_test.dart`; completeness cases C6–C9

---

# v0.4.0 — Keyword Search (Sprint 3 Phase 3.1)

## Added

- **Global Search** tab: ask about a memory with keyword/substring matching across the Circle
- **Person-scoped Search** from Person Profile (Search action)
- Deterministic relevance ranking (exact phrase → all terms → partial; `eventText` boost; recency tiebreak)
- Helpful empty states (idle examples, empty corpus, zero results)
- On-device search-query logging (SharedPreferences, capped; debug analytics hooks)

## Notes

- Phase 3.1 is **keyword Search only** — an intentional shippable slice per `SPRINT3.md` / `SPRINT3_1.md`. Semantic / hybrid ranking is Phase 3.2–3.4 (not a permanent retreat from embeddings).
- Pluggable `SearchProvider` boundary is in place for later semantic providers without UI rewrite
- Capture / LiteRT / embedding write paths unchanged
- **Next:** Phase 3.2 embedding-provider spike (not Suggestion Engine)

---

# v0.3.11 — Capture Release Candidate (Sprint 2B.8)

## Fixed

- Release APK builds (R8 / ML Kit optional script packages)
- Multi-confirm no longer surfaces raw exception text
- Double-submit guards on capture Continue / multi Continue / confirmation Save
- Voice STT errors surface in the recording UI
- Share intent bootstrap no longer logs stacks in release

## Changed

- Accessibility labels on Voice Stop/Cancel and Photo primary actions
- RC documentation: `RELEASE_READINESS_REPORT.md` (Conditional Pass / Go)

## Notes

- No new capture features; LiteRT protocol unchanged
- Owner sign-off 2026-08-08: Conditional Pass conditions satisfied; **Go** for ~100 beta
- **Next: Sprint 3 planning** (architecture review) — no Sprint 3 implementation yet

---

# Foundation Cleanup — pre-Sprint 3

## Fixed

- `PersonRepository.getByUuid()` now excludes soft-deleted people (aligned with MemoryRepository)
- Relative date phrases (`dateValueRaw`) resolve to `dateValue` on Memory save (manual + AI confirmation), anchored to `createdAt`
- One-time idempotent startup backfill for existing relative memories with null `dateValue`

## Changed

- `FollowUp` schema contract: `deletedAt` / Postgres `deleted_at` added (Isar collection + SCHEMA.md) — no FollowUp rows existed

## Notes

- No new features or FollowUp-writing code
- Next remains **Sprint 2B.8** RC gate (not Sprint 3)

---

# v0.3.10 — Capture UX Polish (Sprint 2B.7)

## Added

### Confirmation
- Passive notes when multiple Circle people share the same name (“Which John?”)
- Subtle “Found N memories to review” banner after successful extraction
- Lightweight **Needs review** chip when extraction confidence is below threshold

### Capture
- Shared “Finding memories…” loading status on Typed, Voice, OCR, and Share
- Capture analytics hooks (debug no-op until product analytics ships)

## Changed

- Confirmation spacing, button hierarchy, multi-memory labels, and success snackbars
- Ambiguous person picker copy aligned with clarification notes
- Human-only error strings on confirmation save failures

## Notes

- No AI protocol or confidence-threshold changes
- Next: **Sprint 2B.8** Capture stabilization (not Sprint 3)

---

# v0.3.9 — Share to Tend (Sprint 2B.6)

## Added

### Capture
- Android Share Sheet can send plain text / URLs into Tend
- Opens editable Shared text screen (cold start and warm start)
- Continue uses the same extraction / confirmation pipeline as Typed, Voice, and OCR
- Saved memories use `sourceType = share`

## Notes

- Images, PDFs, and multi-item shares remain backlog
- Referring-app package id is not yet available from the share plugin (`sourceRef` null for now)

---

# v0.3.8 — Capture empty-state UX

## Changed

### Capture (Typed / Voice / OCR)
- Empty extraction is a valid outcome, not an error: “No memories were found in this text.” with short explanation, examples, Try another note, and Enter manually
- Technical details (e.g. mapping/grounding diagnostics) stay debug-only
- `CaptureSubmitFailed` reserved for genuine pipeline failures (install / inference / unexpected exceptions)

### Extraction prompt
- If there is no explicit person and stable memory, emit zero function calls
- Never emit placeholders such as N/A, None, Unknown, or "-"

---

# v0.3.7 — Photo / OCR capture (Sprint 2B.5)

## Added

### Capture
- Camera and gallery entry for photo capture
- Image preview before OCR (Continue / choose another / Cancel)
- On-device OCR via ML Kit → editable extracted text → existing extraction / confirmation flow
- Saved memories from this path use `sourceType = photo` and a local image `sourceRef`

## Notes

- OCR stays behind `OCRProvider` / `activeOCRProvider` — images never go to Gemma / LiteRT
- Typed and voice capture unchanged

---

# v0.3.6 — Voice capture (Sprint 2B.4)

## Added

### Capture
- Microphone entry on Capture: record → platform speech-to-text → editable transcript → existing extraction / confirmation flow
- Recording screen with indicator, elapsed timer, Stop, and Cancel
- Microphone permission handling (clear deny / permanently denied → settings messaging; no repeated prompts when permanently denied)
- Saved memories from this path use `sourceType = voice` (audio file `sourceRef` still backlog)
- Speech language: device locale when available, otherwise a one-time picker; change anytime in Settings

## Notes

- ASR stays behind `TranscriptionProvider` / `activeTranscriptionProvider` — never routes live audio into Gemma / LiteRT
- Platform STT is the MVP backend; long-form conversational transcription remains a product goal (engine evaluation backlog)
- Typed capture unchanged; voice only produces text for the existing pipeline

---

# v0.3.5 — Create Person during capture (Sprint 2B.3)

## Added

### Capture confirmation
- When the mentioned person is not already in My Circle, an explicit **Create person** action is available
- User confirms Name, Relationship, and Circle before creation — never auto-created
- Newly created person is selected on the same confirmation screen

## Notes

- Matching remains exact only (case-insensitive, trimmed); similar-name suggestions are still backlog

---

# v0.3.4 — Multi-memory confirmation (Sprint 2B.2)

## Added

### Capture
- When extraction finds multiple memories: summary (“We found X memories”) then per-memory editable cards
- Each card has a Save toggle (default on); save button shows how many will be saved
- Single-memory capture keeps the previous review screen

## Notes

- Extraction protocol unchanged (ADR-012: one FunctionCall → one memory candidate)

---

# v0.3.3 — Sprint 2A closeout

## Changed

### On-device assistance
- Release builds no longer retain verbose AI prompt/raw diagnostic payloads (debug-only)
- Temporary troubleshooting paths removed from the LiteRT inference adapter (CPU retry / text-envelope recovery)

### Capture quality (retained from late 2A)
- Invalid model categories are rejected (no silent fallback to Preferences)
- Unique Circle name matches pre-select the person on confirmation
- Date phrases like “15 August” classify as explicit; relative phrases stay relative

## Notes

- Sprint 2A is closed; next is Sprint 2B (`SPRINT2B.md`)
- Warm capture remains offline and typically ~6s; cold first inference after prepare can be ~11s on some devices

---

# v0.3.2 — Gemma 4 LiteRT-LM (MVP model)

## Changed

### On-device assistance
- Default / required MVP model is now **Gemma 4 E2B IT** (LiteRT-LM `.litertlm`)
- **Gemma 4 E4B IT** is listed as an optional Best Quality upgrade for capable devices
- Inference engine is **LiteRT-LM only**; MediaPipe `.task` / Qwen paths removed from production
- Accelerator preference: GPU → NPU → CPU with automatic fallback

## Notes

- Capture, confirmation, repositories, and validation are unchanged
- Model selection remains catalog-driven (`ModelCatalog`) for future Gemma releases
- Same 11-prompt literal-grounding suite vs Qwen 0.5B baseline: **11/11 accepted** (was 2/11) on GPU; cold start ~11s, warm ~6s/capture, peak RSS ~1.1 GB, download ~2.41 GB

---

# v0.3.1 — Model-agnostic LiteRT (pre–Sprint 2B)

## Changed

### On-device assistance
- Concrete AI layer renamed from Gemma-specific types to a **LiteRT** provider stack
- Default model was **Qwen 2.5 0.5B Instruct** (superseded by v0.3.2 / Gemma 4 E2B)
- Model setup shows staged progress: Downloading → Verifying → Installing → Preparing model
- Manual model placement is a fallback only, with exact file name and destination path

## Notes

- Capture, confirmation, and repository contracts are unchanged
- Voice/photo/share and multi-candidate review remain Sprint 2B

---

# v0.3.0 — Text Capture & On-Device Extraction (Sprint 2A)

## Added

### Capture
- Global capture entry from the app shell
- Text capture with review-before-saving confirmation
- Collapsible read-only Original Note on confirmation
- First-run model setup gate (prepare on-device assistance or continue manually)

### On-device assistance
- Device capability check (RAM tiers)
- Optional model download/verify (no Hugging Face login)
- Manual model placement for development
- Graceful manual capture when the device or model is unavailable

### Architecture
- AI provider interfaces (extraction implemented; embedding/transcription/OCR stubs)
- Model catalog designed for future version upgrades without changing capture UI

## Changed

- Circle “Add person” moved to the AppBar so the shell capture FAB stays primary

## Notes

- Voice, photo, share-sheet, multi-candidate review, and embeddings are not in this release
- Choosing manual entry does not permanently complete model setup (Settings can offer download later)

---

# v0.2.0 — Person & Memory Foundation

## Added

### Authentication
- Email/password authentication
- Persistent login session
- Splash screen authentication check

### My Circle
- Offline Person CRUD
- Shared PersonFormScreen
- Soft delete
- Circle grouping
- Empty state
- Validation

### Person Profile
- Dedicated profile screen
- Read-only person header
- Edit person action

### Memories
- Offline Memory CRUD
- Shared MemoryFormScreen
- Reverse chronological timeline
- Memory categories
- Importance levels
- Manual date support
- Soft delete
- Memory sensitivity rules

### Architecture
- Isar local database
- Repository pattern
- Riverpod state management
- Offline-first design
- UUID-based relationships

---

## Changed

- Tapping a person now opens Person Profile instead of the Person edit form.
- Memory timelines now live inside Person Profile.

---

## Fixed

- Fixed create/edit controller reuse bug caused by long-lived Riverpod providers.
- Form controllers now use autoDispose.
- Create/edit mode now depends solely on immutable route arguments.

---

# v0.1.0 — Project Foundation

## Added

- Flutter project setup
- Supabase authentication
- Isar initialization
- Routing
- Project architecture
- Development workflow
- Documentation