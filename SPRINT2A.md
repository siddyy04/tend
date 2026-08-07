# SPRINT 2A IMPLEMENTATION SPECIFICATION
### Target: AI coding agent (Cursor). Read fully before writing any code.

> **Supersession (ADR-010):** The concrete extraction implementation folder is now `lib/ai/providers/litert/` (`LiteRtExtractionProvider`, etc.), not `gemma/`. Historical “Gemma*” names in this sprint spec refer to the Sprint 2A original naming. Follow `CURSOR_HANDOFF.md` + ADR-010 for current paths.

You are implementing **Sprint 2A only** of the Tend Flutter app. Reference documents already in this repository: `ARCHITECTURE.md`, `ADR.md` (ADR-006, ADR-007, ADR-008, ADR-009 are directly load-bearing this sprint), `FEATURES.md`, `SCHEMA.md`, `DEVELOPMENT_ROADMAP.md`, `BACKLOG.md`, `SPRINT0.md`, `SPRINT1A.md`, `SPRINT1B.md` (prior sprints, already implemented). This specification is the authoritative scope for this task. If anything here appears to conflict with those documents, stop and ask rather than guessing which one wins.

**Sprint 2A is the first half of a two-part split of the original Sprint 2.** It establishes the entire AI-assisted capture pipeline — provider abstraction, model management, Gemma extraction, confirmation, save to Isar — using **text input only**. Sprint 2B (a separate specification, built on top of this one) adds voice, photo, share-sheet, multi-candidate extraction, clarification UI, and confidence-indicator polish. Do not build any Sprint 2B item now, even if it looks like an easy addition while a related file is already open — see Section 11.

Per ADR-009 ("Manual-first before AI"), this sprint builds strictly on top of the manual CRUD delivered in Sprints 1A/1B — it adds an AI-assisted path alongside that work, it does not replace or duplicate it.

---

## 0. Cross-Document Consistency Notes (read before building)

1. **`DEVELOPMENT_ROADMAP.md`'s Sprint 2 description bundles building `GemmaEmbeddingProvider` into "Sprint 2."** This spec (and Sprint 2B) override that. Embeddings are out of scope for both halves of this split — the `EmbeddingProvider` interface is defined (Section 3), but no concrete implementation is built anywhere in Sprint 2A or 2B, and `Memory.embedding` stays `null`. Deliberate, documented deviation from the roadmap bullet, not an oversight.
2. **`FEATURES.md` lists the model download/device-capability check under the "Onboarding & Auth" screen row**, but that screen shipped in Sprint 0 without it. This sprint gates model setup as a **first-run check before Capture is used for the first time**, not a retrofit into the already-shipped auth flow.
3. **`BACKLOG.md` documents that `PersonRepository.getByUuid()` currently does not exclude soft-deleted people** (an open bug, tracked separately). This sprint's person-match resolution does not rely on that method — see Section 7. Do not fix the underlying bug as part of this sprint.
4. **`BACKLOG.md`'s `FollowUp.deletedAt` schema mismatch is irrelevant to this sprint** — Sprint 2A does not read, write, or create any `FollowUp` record (Section 10).

---

## 1. Sprint Goal

Implement a manual-trigger, AI-assisted memory capture pipeline for **text input only**, running entirely on-device with no cloud LLM: typed text → on-device extraction via the `ExtractionProvider` abstraction (Gemma 3n E2B as the concrete implementation) → a single-candidate, user-editable confirmation screen → write the confirmed memory to Isar via the existing `MemoryRepository`. Voice, photo, share-sheet, multi-candidate handling, clarification UI, and confidence-indicator polish are all explicitly Sprint 2B.

---

## 2. Pipeline Boundary — read this twice

This sprint's scope ends the instant a confirmed memory is written to Isar. Specifically, this sprint does **not**:
- Create, read, or modify any `FollowUp` record, even though the extraction JSON naturally includes follow-up-related fields (see Section 9).
- Generate or store any embedding (`Memory.embedding` stays `null`).
- Implement any search, ranking, or suggestion logic.
- Touch the sync engine or any Supabase table.
- Handle voice, photo, or share-sheet input, or more than one candidate per capture (Sprint 2B).

If an implementation detail seems to require any of the above to feel "complete," it doesn't — stop and flag it instead of expanding scope.

---

## 3. Provider Interfaces (define all four before any concrete implementation)

Per `ARCHITECTURE.md` Section 6, exactly as specified there — do not alter these signatures, even though `TranscriptionProvider`/`OCRProvider` have no concrete implementation until Sprint 2B:

```dart
abstract class ExtractionProvider {
  Future<ExtractionResult> extract({
    required String text,
    required List<Person> knownPeople,
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

All four interface files are created this sprint. **Only `ExtractionProvider` gets a concrete implementation in Sprint 2A** (`GemmaExtractionProvider` and `ManualFallbackProvider`). `TranscriptionProvider` and `OCRProvider` are defined but unimplemented until Sprint 2B. `EmbeddingProvider` is defined and stays unimplemented through both halves.

### `ExtractionResult` data shape — Sprint 2A version
**No `ClarificationNeeded` type and no `clarificationNeeded` field this sprint.** This is a deliberate reduction from the eventual shape — Sprint 2B adds it back. Do not include an empty placeholder list "for forward compatibility"; the field does not exist on the type at all in Sprint 2A.

```dart
class ExtractionResult {
  final List<ExtractedMemoryCandidate> candidates;
}

class ExtractedMemoryCandidate {
  final String personMentioned;         // name as stated in the input
  final String? personMatchUuid;        // matched existing Person's uuid, null if unmatched/ambiguous
  final double personMatchConfidence;   // 0.0-1.0
  final MemoryCategory category;
  final String eventText;
  final String quoteEvidence;           // mandatory grounding quote — see Section 6
  final DatePrecision datePrecision;
  final String? dateValueRaw;
  final DateTime? dateValue;
  final int importanceScore;            // 1-5, model-suggested, user-editable
  final double extractionConfidence;    // 0.0-1.0
  final bool followUpSuggested;         // present in the model's output — NEVER persisted this sprint, see Section 9
  final String? followUpNote;           // same — discarded after the confirmation screen
}
```
Note what's absent: no `sensitivityFlag` (the model does not decide sensitivity — Section 8), and no `ClarificationNeeded` type (Sprint 2B).

### Single-candidate restriction, explicit and temporary
The model's function-call output may still technically return more than one candidate for a given input — that's the underlying schema shape and it isn't worth constraining server/model-side. **`capture_confirmation_controller.dart` in Sprint 2A takes only the first candidate surviving validation (Section 6) and discards any additional ones.** No multi-card UI exists this sprint. Sprint 2B removes this restriction and builds the multi-card layout — that removal should be a small, additive change against this same pipeline, not a rewrite, which is exactly why the underlying `List<ExtractedMemoryCandidate>` shape is preserved now even though only index 0 is ever used.

---

## 4. Files to Create or Modify

### New files
```
lib/
  core/
    constants/
      extraction_defaults.dart          # confidence thresholds (ADR-007 pattern)
  domain/
    rules/
      extraction_validation_rules.dart  # grounding-quote check, confidence checks, taxonomy check (ADR-008 pattern)
  ai/
    providers/
      extraction_provider.dart          # interface + ExtractionResult/ExtractedMemoryCandidate
      embedding_provider.dart           # interface only
      transcription_provider.dart       # interface only, no implementation this sprint
      ocr_provider.dart                 # interface only, no implementation this sprint
      gemma/
        gemma_extraction_provider.dart
      manual/
        manual_fallback_provider.dart
      ai_provider_selection.dart        # Riverpod providers resolving which concrete ExtractionProvider is active
    model_manager/
      device_capability_check.dart
      model_download_manager.dart
      model_manager_providers.dart
  features/
    capture/
      capture_entry_point.dart          # the persistent FAB/entry widget, wired into the app shell
      capture_screen.dart               # text-input mode only this sprint
      capture_controller.dart           # orchestrates text → extract → hand off
      model_setup_screen.dart           # first-run device-capability/model-download gate
      confirmation/
        capture_confirmation_screen.dart    # single-candidate layout only
        capture_confirmation_controller.dart
        widgets/
          candidate_card.dart               # plain/minimal treatment this sprint — polish is Sprint 2B
          person_picker_field.dart
```

### Modified files
```
lib/
  app/
    router.dart                # new routes: capture, model setup, confirmation
  (the Sprint 0 app-shell widget wherever My Circle / Today / Search navigation
   currently lives — locate it before editing rather than assuming a filename;
   add the persistent capture entry point there)
```

Do not create or modify anything under `lib/data/sync/`, `lib/features/opportunities/`, `lib/features/search/` (beyond Sprint 0 stubs), or any `follow_up`-related file. Do not create `lib/ai/providers/platform/` — that folder belongs to Sprint 2B.

---

## 5. `domain/rules/extraction_validation_rules.dart`

Pure functions, no I/O, no widget dependency — consistent with ADR-008:

- `bool hasGroundingQuote(ExtractedMemoryCandidate candidate)` — a candidate with an empty or missing `quoteEvidence` is discarded entirely before it reaches the confirmation screen. No grounding quote, no memory — non-negotiable.
- `bool meetsExtractionConfidenceThreshold(ExtractedMemoryCandidate candidate)` — compares against `kExtractionConfidenceThreshold` from `extraction_defaults.dart`. Below threshold, the candidate is still shown (Sprint 2A gives it a minimal/plain treatment; Sprint 2B polishes the indicator), but is flagged for `needsUserConfirmation = true` on save.
- `bool meetsPersonMatchConfidenceThreshold(ExtractedMemoryCandidate candidate)` — same pattern, against `kPersonMatchConfidenceThreshold`. Below threshold (or `personMatchUuid == null`), the confirmation screen requires an explicit person selection — see Section 7.
- `MemoryCategory? validatedCategory(String rawCategoryValue)` — if the model's function-call output contains a category string that doesn't match any `MemoryCategory` enum value, this returns `null` and the candidate is discarded. Never guess a fallback category.

`extraction_defaults.dart` holds both threshold constants as the single source of truth, per ADR-007 — do not inline threshold numbers anywhere else.

---

## 6. Applying Validation and the Single-Candidate Cut

`capture_controller.dart` calls `ExtractionProvider.extract()`, then runs every returned candidate through `hasGroundingQuote()` and `validatedCategory()`, discarding any that fail either check. **From the surviving, validated candidates, take only the first — this is the Sprint 2A single-candidate restriction from Section 3.** If zero candidates survive validation, the confirmation screen is not shown at all; instead, show a plain message that nothing could be captured from that input and let the user retry or open Sprint 1B's `MemoryFormScreen` directly for manual entry.

---

## 7. Person Resolution — the global capture / known-people problem

Sprint 2A's capture entry point is **global** (reachable from anywhere in the app shell, not scoped to a specific person's profile) — this is what `ExtractionProvider.extract()`'s `knownPeople` parameter is for: letting the model figure out who a captured memory is about, rather than requiring the user to navigate to a person first.

- **Building the `knownPeople` list:** read the current value of Sprint 1A's existing `allPeopleProvider` stream (`ref.read(allPeopleProvider.future)` or its latest emitted value) at the moment capture is triggered. **Do not** add a new method to `PersonRepository`, and **do not** build this list via `getByUuid()` calls — per Section 0 item 3, `getByUuid()` currently leaks soft-deleted records, and `allPeopleProvider` already filters correctly. `PersonRepository`'s contract from Sprint 1A is not modified this sprint.
- **Confident match** (`personMatchUuid` non-null and `meetsPersonMatchConfidenceThreshold` true): the confirmation card pre-selects that person, but the selection remains editable — the user can pick a different existing person if the model got it wrong.
- **No confident match:** the confirmation card requires the user to explicitly pick an existing person from their Circle before the candidate can be saved. Save is blocked until a person is selected.
- **Creating a brand-new Person inline from the confirmation screen is explicitly out of scope** (Section 11). If the memory is about someone not yet in Circle, the user must cancel, add the Person via the existing Sprint 1A flow, and capture again.

---

## 8. Sensitivity — always deterministic, never model-decided

`ExtractedMemoryCandidate` deliberately has no `sensitivityFlag` field. Per ADR-008 ("Future AI pipelines and manual forms use the same rules"), **the confirmed candidate's `sensitivityFlag` is computed by calling Sprint 1B's existing `defaultSensitivityForCategory()` in `memory_sensitivity_rules.dart`, unmodified, using the candidate's final (possibly user-edited) category.** The model's own judgment about sensitivity is never consulted or persisted. This is the permanent rule ADR-008 establishes, and this sprint is its first real test.

---

## 9. What Happens to `followUpSuggested` / `followUpNote`

These fields exist on `ExtractedMemoryCandidate` because the model's output naturally includes them — but `Memory` has no corresponding field in `SCHEMA.md`, and `FollowUp` is untouched this sprint. **Discard them after the confirmation screen. Do not persist them anywhere, do not add a field to `Memory` to stash them, and do not create a `FollowUp` record from them.** Sprint 3 owns that decision entirely.

---

## 10. Confirmation Screen Behavior (single-candidate)

- Renders exactly one `candidate_card.dart` for the single surviving candidate (Section 6). No list, no multi-card layout — that's Sprint 2B.
- Every field is editable: category, event text, date, importance score, and the person selection (Section 7).
- A candidate below `kExtractionConfidenceThreshold` gets a minimal, plain indicator this sprint (e.g. a small text label) — not a blocker to saving, and not the polished visual treatment Sprint 2B adds. `needsUserConfirmation = true` is set on the resulting `Memory` in this case; above-threshold candidates get `needsUserConfirmation = false`.
- Save reuses Sprint 1B's `memory_validators.dart` unmodified against the confirmed candidate's final field values before writing — do not create a parallel validation path for AI-sourced memories.
- On save, the candidate becomes a `Memory` with: `uuid` generated fresh, `personUuid` from the resolved selection, `sensitivityFlag` from Section 8, `sourceType = SourceType.text`, `sourceRef = null` (typed text has no file), `quoteEvidence` carried through, `extractionConfidence`/`personMatchConfidence` carried through, `embedding = null`, `createdAt`/`updatedAt` set to now, `syncStatus = pending`.

---

## 11. Model Management (build before the capture UI, per `DEVELOPMENT_ROADMAP.md`)

- `device_capability_check.dart`: uses `device_info_plus` to assess available RAM and produce a tier (per `ARCHITECTURE.md` Section 7: ≥8GB full experience, ~6GB works, below floor → unsupported).
- `model_download_manager.dart`: download-on-first-run (not bundled), stored in the app's documents directory, checksum-verified before use, falls back to the previously working model on verification failure. **Do not implement a Hugging-Face-account-gated download flow** — the model file must be rehosted somewhere the app can fetch without requiring the end user to authenticate to a third-party ML hub.
- `model_setup_screen.dart`: the first-run gate shown before Capture is used for the first time. On a supported device, walks through capability check → download → verify. On an unsupported device, explains plainly that AI capture isn't available on this device and that manual entry (Sprint 1B) works exactly as before — never an error state.
- **Unsupported-device behavior in Sprint 2A:** since only text capture exists this sprint, the fallback is simple — typed capture text is **not** sent to extraction at all; it goes straight to pre-filling Sprint 1B's `MemoryFormScreen.eventText` in create mode, and the user completes category/person/date manually. **Do not build a second manual-entry form for this fallback path.** (Sprint 2B extends this same pattern to voice/photo, where transcription/OCR still run even on unsupported devices before falling back.)
- `ManualFallbackProvider` implements `ExtractionProvider` only, per `ARCHITECTURE.md` Section 6.

---

## 12. Acceptance Criteria

1. A user can trigger text capture from anywhere in the app shell — not scoped to a specific person's profile.
2. On a supported device, typed text is sent to `GemmaExtractionProvider`; the result is filtered through `hasGroundingQuote()` and `validatedCategory()`, and only the first surviving candidate reaches the confirmation screen.
3. The confirmation screen renders exactly one editable candidate card; saving is blocked if no person is resolved (Section 7) or the candidate fails `memory_validators.dart` checks.
4. `sensitivityFlag` on the saved memory is computed via Sprint 1B's `defaultSensitivityForCategory()`, never taken from the model.
5. The confirmed candidate is written to Isar via the existing `MemoryRepository.create()` — no new repository method, no bypass of Sprint 1B's write path.
6. `Memory.embedding` is `null` for every record created this sprint. No `FollowUp` record is created, read, or modified anywhere in this sprint's code.
7. On an unsupported/low-RAM device, typed text pre-fills Sprint 1B's `MemoryFormScreen` directly — never an error state, never extraction attempted.
8. The full text-capture-to-saved-memory flow (including the confirmation tap) completes in well under 10 seconds on a supported device, entirely offline — no network call anywhere in this pipeline.
9. No Supabase table is read from or written to anywhere in this sprint's code.
10. `ExtractionResult` has no `clarificationNeeded` field or `ClarificationNeeded` type anywhere in the codebase this sprint.

---

## 13. Definition of Done

- [ ] All four provider interfaces exist; only `ExtractionProvider` has a concrete implementation this sprint (`GemmaExtractionProvider`, `ManualFallbackProvider`).
- [ ] `GemmaExtractionProvider` uses `flutter_gemma`'s function-calling mode against the `ExtractedMemoryCandidate` shape — no free-text-then-parse JSON approach.
- [ ] `extraction_validation_rules.dart` contains all grounding-quote, confidence-threshold, and taxonomy checks as pure functions — none of this logic lives in `GemmaExtractionProvider` itself or in any widget.
- [ ] `extraction_defaults.dart` is the single source of truth for both confidence thresholds.
- [ ] Person resolution for `knownPeople` reads `allPeopleProvider`'s current value — `PersonRepository` is unmodified this sprint.
- [ ] `sensitivityFlag` on the saved memory traces to `memory_sensitivity_rules.dart`, called with the candidate's final category.
- [ ] `followUpSuggested`/`followUpNote` are discarded after confirmation — no trace of them in Isar, no new field added to `Memory`.
- [ ] `ExtractionResult` has exactly one field (`candidates`) — no `clarificationNeeded` field exists this sprint.
- [ ] Only the first validated candidate ever reaches the confirmation screen; there is no multi-card layout anywhere in the codebase this sprint.
- [ ] Device capability tiering, model download/verification, and the unsupported-device fallback to `MemoryFormScreen` (pre-filled, not a new form) all work as specified.
- [ ] `Memory.embedding` is null on every record created this sprint; `GemmaEmbeddingProvider` does not exist as a file; `PlatformTranscriptionProvider`/`PlatformOCRProvider` do not exist as files.
- [ ] No file exists under `lib/data/sync/`, `lib/ai/providers/platform/`; no `FollowUp`-touching code exists; no Supabase table read/write exists anywhere in this sprint's changes.
- [ ] Every acceptance criterion in Section 12 passes manually, and every scenario in Section 15's Testing Checklist passes.

---

## 14. Explicit Out-of-Scope Items

- Voice capture, photo capture, OS share-sheet — all Sprint 2B.
- Multi-candidate extraction and the multi-card confirmation layout — Sprint 2B.
- `ClarificationNeeded` type, field, or any UI for it — Sprint 2B.
- Confidence-indicator visual polish — Sprint 2A ships the minimal/plain version only.
- Suggestion Engine, `FollowUp` creation/reading/scoring in any form (Sprint 3).
- Semantic search, `GemmaEmbeddingProvider`, or any use of `EmbeddingProvider.embed()` (Sprint 4 — and per Section 0 item 1, not part of Sprint 2B either).
- Sync engine, Supabase backup mirror tables, any push/pull logic (Sprint 5).
- Data export, encryption, account deletion (Sprint 6).
- Creating a brand-new `Person` inline from the capture confirmation screen — a real MVP limitation, not an oversight.
- Fine-tuned FunctionGemma as an `ExtractionProvider` swap (`ARCHITECTURE.md` Section 7 — P1).
- Any cloud-model fallback option (`FEATURES.md` P2).
- Captured file lifecycle management — moot this sprint since text capture has no `sourceRef` file.
- Fixing `PersonRepository.getByUuid()`'s soft-delete leak, or resolving the `FollowUp.deletedAt` schema mismatch (`BACKLOG.md`) — both irrelevant or worked around, not fixed.

---

## 15. Testing Checklist

- [ ] Capture via text on a supported device with a clear single-person single-fact input — confirm one candidate appears, pre-filled correctly, with a visible grounding quote.
- [ ] Capture text where the model's raw output would contain more than one candidate (if reproducible) — confirm only the first validated one is shown, and there is no way to see or recover the others in the UI.
- [ ] Capture text referencing someone not in Circle — confirm the confirmation card requires manual person selection and blocks save until one is chosen; confirm there is no inline "create new person" option.
- [ ] Force a low-confidence extraction (e.g. deliberately ambiguous input) — confirm the candidate is still shown with the plain/minimal flag, and confirm the resulting `Memory.needsUserConfirmation` is `true`.
- [ ] Confirm a candidate with a category in each of the three sensitivity tiers (e.g. Health, Family, Career) and verify `sensitivityFlag` matches Sprint 1B's mapping exactly.
- [ ] Edit the candidate's category on the confirmation screen before saving — confirm the saved `sensitivityFlag` reflects the edited category, not the model's original suggestion.
- [ ] Attempt to save with an empty edited event text — confirm it's blocked via `memory_validators.dart`, same as Sprint 1B's manual form.
- [ ] Capture text where extraction produces zero valid candidates (e.g. no grounding quote) — confirm the confirmation screen is skipped entirely and the user is offered manual entry instead.
- [ ] Simulate an unsupported/low-RAM device — confirm typed text pre-fills `MemoryFormScreen` directly with no extraction attempted, and no crash or dead end occurs.
- [ ] Complete a full text-capture-to-saved-memory cycle in airplane mode — confirm success with zero network calls.
- [ ] Inspect a saved AI-sourced memory directly in Isar — confirm `embedding` is null, `extractionConfidence`/`personMatchConfidence`/`quoteEvidence` are populated, `sourceType = text`, `sourceRef` is null, and no corresponding `FollowUp` row exists anywhere.
- [ ] Confirm the model download flow completes without requiring the tester to authenticate to any third-party ML hub account.
- [ ] Grep the codebase for `ClarificationNeeded` — confirm zero matches.

---

## 16. Common Implementation Pitfalls to Avoid

- **Do not build voice, photo, or share-sheet entry points "since the capture screen is already open."** Text-only this sprint — see Section 1 and Section 14.
- **Do not add a `clarificationNeeded` field to `ExtractionResult`, even as an empty placeholder list "for later."** The type doesn't exist this sprint at all.
- **Do not build a multi-card confirmation layout "just in case."** Take the first validated candidate only — Section 6.
- **Do not skip the grounding-quote check "since the model usually gets it right."** `hasGroundingQuote()` runs on every candidate, no exceptions, before anything reaches the confirmation screen.
- **Do not let the model's own sensitivity judgment leak into `Memory.sensitivityFlag`.** `ExtractedMemoryCandidate` has no such field by design.
- **Do not create, stub, or "pre-wire" a `FollowUp` record from `followUpSuggested`/`followUpNote`.**
- **Do not implement `GemmaEmbeddingProvider`, `PlatformTranscriptionProvider`, or `PlatformOCRProvider` "while already in the neighborhood."** All three are Sprint 2B or later — see Section 0 item 1 and Section 14.
- **Do not add a new method to `PersonRepository`** to support person-match resolution. Read `allPeopleProvider`'s current value instead.
- **Do not validate the confirmed candidate with a new, parallel validation function.** Reuse `memory_validators.dart` from Sprint 1B unmodified.
- **Do not require a Hugging-Face (or any third-party ML hub) login as part of the model download flow.**
- **Do not silently guess a fallback `MemoryCategory` when the model's output doesn't match the enum.** Discard the candidate instead.
- **Do not scope the capture entry point to a specific person.** Capture is global by design — person resolution happens via the model plus the confirmation screen.
- **Do not build a polished confidence-indicator UI.** A plain/minimal label is correct for this sprint; polish is explicitly Sprint 2B's job, not a nice-to-have to sneak in early.
