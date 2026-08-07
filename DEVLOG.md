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


