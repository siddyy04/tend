# Architecture Decision Records (ADR)

This document captures important architectural decisions made during the development of Tend.

The goal is to explain **why** a decision was made, not how the code works.

## Format

### ADR-XXX — Title

**Status**
Accepted | Superseded | Deprecated

**Date**
YYYY-MM-DD

**Context**
What problem were we trying to solve?

**Decision**
What did we decide?

**Rationale**
Why was this approach chosen?

**Consequences**
Pros, cons, and future implications.

---

# ADR-001 — Local-first architecture

**Status**
Accepted

**Date**
2026-08-07

**Context**
Tend must work reliably even without an internet connection and should avoid unnecessary cloud dependencies.

**Decision**
Isar is the primary source of truth for all application data.
Supabase is used only for authentication in the early sprints. Cloud synchronization will be added later without changing the local architecture.

**Rationale**
- Instant UI updates
- Full offline support
- Lower operating costs
- Better user privacy
- Simpler AI integration using local data

**Consequences**
- All repositories read/write Isar.
- Sync becomes an implementation detail rather than a core dependency.
- Extra work is required later for conflict resolution.

---

# ADR-002 — UUID-based relationships

**Status**
Accepted

**Date**
2026-08-07

**Context**
Entities reference each other throughout the application.

**Decision**
Relationships use UUID strings instead of IsarLinks or local database IDs.

**Rationale**
UUIDs remain stable across devices and future synchronization.

**Consequences**
- Navigation uses UUIDs only.
- Repositories expose UUIDs only.
- Local Isar IDs never leave the data layer.

---

# ADR-003 — Repository boundaries

**Status**
Accepted

**Date**
2026-08-07

**Context**
Repositories are the only boundary between business logic and Isar.

**Decision**
Repositories return flat entity lists.
Sorting, grouping, filtering, and presentation belong in Riverpod providers.

**Rationale**
Keeps repositories reusable and UI-independent.

**Consequences**
- Repository code stays simple.
- UI can have multiple derived views from the same data.

---

# ADR-004 — Form controller lifecycle

**Status**
Accepted

**Date**
2026-08-07

**Context**
Sprint 1A exposed a bug where create-mode forms reused stale controller state.

**Decision**
All temporary form controllers use `autoDispose`.
Create vs edit mode is determined only from immutable navigation/provider arguments.

**Rationale**
Prevents stale state leaking between screens.

**Consequences**
- Fresh controller every navigation.
- No hidden mutable mode state.
- Reusable pattern for all future forms.

---

# ADR-005 — Soft delete

**Status**
Accepted

**Date**
2026-08-07

**Context**
Deleted data may need synchronization, recovery, or audit history.

**Decision**
Person and Memory records are soft-deleted using `deletedAt`.

Repositories hide deleted records from callers.

**Rationale**
Supports future synchronization and recovery.

**Consequences**
- No hard deletes during normal app operation.
- Future restore functionality becomes possible.
- Sync engine can process deletions correctly.

---

# ADR-006 — Shared form screens

**Status**
Accepted

**Date**
2026-08-07

**Context**
Separate Add and Edit screens duplicate UI and validation logic.

**Decision**
Each entity has one shared form screen.

Examples:
- PersonFormScreen
- MemoryFormScreen

Mode is determined from route arguments.

**Rationale**
Reduces maintenance and keeps behavior consistent.

**Consequences**
- One validation path.
- One save flow.
- Less duplicated code.

---

# ADR-007 — Business defaults

**Status**
Accepted

**Date**
2026-08-07

**Context**
Default values such as Circle Tier and Memory Importance should not be scattered through the application.

**Decision**
Business defaults live in dedicated constants files.

Examples:
- person_defaults.dart
- memory_defaults.dart

**Rationale**
Single source of truth.

**Consequences**
Changing a default requires editing only one location.

---

# ADR-008 — Business rules

**Status**
Accepted

**Date**
2026-08-07

**Context**
Rules such as Memory sensitivity should not live inside widgets or repositories.

**Decision**
Business rules live in `domain/rules`.

Example:
- memory_sensitivity_rules.dart

**Rationale**
Reusable, testable, independent of UI and persistence.

**Consequences**
Future AI pipelines and manual forms use the same rules.

---

# ADR-009 — Manual-first before AI

**Status**
Accepted

**Date**
2026-08-07

**Context**
AI should not be introduced before manual workflows are stable.

**Decision**
Every feature is implemented manually before AI assistance is added.

**Rationale**
AI augments existing workflows rather than defining them.

**Consequences**
- Easier debugging
- Better testing
- Clear separation between CRUD and intelligence

---

### ADR-010 — Model-agnostic LiteRT provider (abandon Gemma 3n Preview for MVP)

**Status**
Superseded in part by ADR-011 (MVP model choice and engine). Provider rename + catalog ownership remain in force.

**Date**
2026-08-07

**Context**
Sprint 2A scaffolded on-device extraction behind provider interfaces, but the concrete layer was named for Gemma and the catalog still pointed at Gemma 3n Preview. That Preview artifact is gated on Hugging Face and is unsuitable for Tend’s MVP in-app download (no end-user hub login). Tend must support publicly available LiteRT models without rewriting Capture, Confirmation, or repositories.

**Decision**
- Rename the concrete AI implementation folder/types from Gemma-specific names to **LiteRT** (`lib/ai/providers/litert/`, `LiteRtExtractionProvider`, `LiteRtInferenceAdapter`, `LiteRtPromptBuilder`).
- Keep using the `flutter_gemma` package as the LiteRT bridge; only the Tend adapter may import it.
- **`ModelCatalog` owns model selection**, including `displayName`, `fileName`, download URL, checksum, and install identity (`modelKind` / `fileKind`). Capture and Confirmation never read the catalog.
- ~~MVP default model: **Qwen 2.5 0.5B Instruct**. Qwen 2.5 1.5B remains in the catalog as an optional future upgrade.~~ → see ADR-011.
- Download UX: automatic download is the default path, with staged progress (Downloading → Verifying → Installing → Preparing model). Manual file placement is a fallback only (download failure, no URL, or explicit user choice), with exact file name and destination path instructions.

**Rationale**
- Separates runtime (LiteRT) from which weights are installed (catalog).
- Lets model swaps be a catalog change, not a pipeline rewrite.
- Matches MVP constraints: public HTTPS artifact, no hub login.

**Consequences**
- `ARCHITECTURE.md` Gemma-3n-as-default wording is superseded for the concrete provider/folder names and MVP model choice; the provider-interface pattern remains.
- Sprint 2B and later work target `litert/` paths, not `gemma/`.
- Device RAM floors may be revisited later; not required for this rename.

---

### ADR-011 — Gemma 4 LiteRT-LM as sole MVP inference stack

**Status**
Accepted

**Date**
2026-08-07

**Context**
Qwen 2.5 0.5B via MediaPipe `.task` proved the LiteRT architecture and native function-calling path, but literal-grounding quality on the 11-prompt benchmark was too low for MVP (2 accepted / 9 rejected). Maintaining MediaPipe `.task` (Qwen) and LiteRT-LM (Gemma 4) as dual engines is unnecessary complexity. Google’s Gemma 4 E2B/E4B ship as public `.litertlm` artifacts with native tool calling.

**Decision**
- **Sole production inference engine:** LiteRT-LM via `flutter_gemma_litertlm` (`LiteRtLmEngine`). Retire MediaPipe / `.task` / Qwen from production code.
- **MVP required model:** Gemma 4 E2B IT (`gemma4-e2b-it-v1`) — Recommended / default via `ModelCatalog.current`.
- **Optional upgrade:** Gemma 4 E4B IT (`gemma4-e4b-it-v1`) — Best Quality for capable devices; catalog-listed, not required.
- Keep `ExtractionProvider`, Capture, Confirmation, repositories, and validation unchanged.
- Keep model-agnostic `ModelCatalog` so future Gemma releases are catalog additions.
- Backend preference: **GPU → NPU (NNAPI-class) → CPU**, with automatic fallback.
- Native function calling (`ModelType.gemma4`, `supportsFunctionCalls: true`, `ToolChoice.auto`).

**Rationale**
- One inference stack reduces maintenance and abort risk from divergent engines.
- Public HF litert-community URLs (`needsAuth: false`); offline after install.
- E2B targets quality + footprint for MVP; E4B remains opt-in for high-end devices.

**Consequences**
- `flutter_gemma_mediapipe` removed from `pubspec.yaml`.
- ADR-010’s Qwen default is superseded; LiteRT naming + catalog ownership remain.
- Benchmark against the prior Qwen 11-prompt suite before locking E2B as the quality baseline.

---

### ADR-012 — Parallel native function calls for multi-memory extraction

**Status**
Accepted

**Date**
2026-08-08

**Context**
Sprint 2B needs multiple memories from one note. Two native FC shapes were spiked on Gemma 4 E2B: parallel flat `extract_memories` calls vs a single call with `candidates[]`. Parallel matched multi-fact quality and preserved the single-fact path; `candidates[]` broke single-fact control (`TextResponse` / markdown JSON). Same-person multi-memory also works under parallel FC; residual misses are prompt/model completeness, not protocol design.

**Decision**
- **Long-term Tend extraction protocol:** one native function call per stable, independently useful memory (parallel `FunctionCallResponse` / `ParallelFunctionCallResponse`).
- Keep the **flat** tool parameter schema (no primary `candidates[]` array protocol).
- **Architectural contract (invariant):** **one FunctionCall → one `ExtractedMemoryCandidate`.** Future prompt refinements may improve extraction completeness, but must not change this mapping (no bundling multiple memories into a single call’s args, no switching to a `candidates[]` primary protocol).
- Do not reopen alternative extraction protocols without a new ADR.
- Completeness tuning stays in `LiteRtPromptBuilder` prompts/few-shots; occasional soft-fact omission is accepted as model-quality limitation.

**Consequences**
- `LiteRtInferenceAdapter.runFunctionCalls` returns all parallel calls.
- Capture/Confirmation consume `List<ExtractedMemoryCandidate>` produced by mapping each call independently.
- Spike harnesses under `lib/debug/` may compare protocols for research, but production stays parallel-flat.
- Prompt-only changes are allowed without an ADR; protocol/shape changes require a new ADR.

---

### ADR-013 — On-device embeddings: Conditional Go with Gecko (not Gemma 4 E2B)

**Status**
Accepted (Phase 3.3 implemented)

**Date**
2026-08-08

**Context**
Phase 3.1 shipped keyword Search. Phase 3.2 asked whether Tend should generate on-device embeddings for semantic search (`SPRINT3_2.md`, two-day timebox). Spike evidence is in `SPRINT3_2_FINDINGS.md`.

**Decision**
- **Do not** use Gemma 4 E2B / LiteRT-LM inference for embeddings — the current bridge exposes no embedding API on `InferenceModel`.
- **Conditional Go** for Phase 3.3 semantic search using a **dedicated** embedder: **Gecko-110m-en** (`Gecko_256_quant.tflite`, 768-d) via `flutter_gemma_embeddings`, publicly downloadable without hub login.
- **Do not** adopt EmbeddingGemma-300m for MVP download while HF gating (401 without token) remains — same distribution class as ADR-010’s gated Preview rejection.
- Semantic ranking must be an **additive** `SearchProvider` signal on top of Phase 3.1 keyword search — never a replacement.
- Before production writes: add Memory fields **`embeddingModelVersion`** (string) and keep `embedding` as `List<double>?`; never compare vectors across different versions/dimensions.
- Production must not register `embeddingBackends` until Phase 3.3 implements `EmbeddingProvider`.
- If product declines Phase 3.3: **Option 3 — stay keyword-only** is an accepted outcome; no production rollback required.

**Rationale**
- RQ1 measured **NOT_CAPABLE** for Gemma 4 embeddings.
- Gecko: warm ≈172 ms/embed on AIN065; exact 2/2 and paraphrase 3/3 on the fixed micro-set; ~114 MB public artifact; ~3 KB/memory storage.
- Absolute cosine scores for unrelated queries remain mid-0.6 → hybrid/threshold required.
- Versioning closes the long-standing SCHEMA.md re-embed gap.

**Consequences**
- Phase 3.3 (if started) implements Gecko-backed `EmbeddingProvider`, versioning fields, background embed + backfill — not this spike.
- `flutter_gemma_embeddings` may remain in `pubspec` inert until Phase 3.3; spike harness alone registers the backend today.
- Larger relevance / battery / RSS work deferred to Phase 3.3/3.5 as documented unknowns in findings.

---
