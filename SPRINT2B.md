# SPRINT 2B IMPLEMENTATION SPECIFICATION
### Target: AI coding agent (Cursor). Read fully before writing any code.

> **Supersession (ADR-010 / ADR-011):** Concrete extraction lives under `lib/ai/providers/litert/` (`LiteRtExtractionProvider`, `LiteRtInferenceAdapter`, `LiteRtPromptBuilder`). MVP inference is **LiteRT-LM** + **Gemma 4 E2B** with **native function calling**. Do not reintroduce MediaPipe / Qwen / `.task`. Historical “Gemma 3n” wording in older docs does not apply.

You are implementing **Sprint 2B only** of the Tend Flutter app. Reference documents already in this repository: `ARCHITECTURE.md`, `ADR.md`, `FEATURES.md`, `SCHEMA.md`, `DEVELOPMENT_ROADMAP.md`, `BACKLOG.md`, `SPRINT0.md`, `SPRINT1A.md`, `SPRINT1B.md`, and **`SPRINT2A.md`** (the immediately prior sprint — read it in full before starting this one; Sprint 2B extends its files rather than starting fresh). This specification is the authoritative scope for this task. If anything here appears to conflict with those documents, stop and ask rather than guessing which one wins.

Sprint 2B is the second half of the original Sprint 2 split. It extends Sprint 2A's text-only pipeline with **multi-memory extraction and confirmation**, **inline Create Person**, then **voice / photo / share** ingress, and finally **clarification + confidence polish**. **Nothing in this sprint changes where the pipeline stops** — see Section 2.

**Implement only in the phase order in Section 16.** Do not start voice/photo/share or clarification until earlier phases are proven.

---

## 0. Carried Over From Sprint 2A (still binding, not repeated in full)

- Embeddings remain entirely out of scope. `EmbeddingProvider` stays interface-only; a concrete LiteRT embedding provider is not built in this sprint either. `Memory.embedding` stays `null` for every record created in Sprint 2B, same as 2A. This is a deliberate deviation from `DEVELOPMENT_ROADMAP.md`'s original Sprint 2 bullet, still in effect.
- `FollowUp` remains completely untouched — no create, read, or update, anywhere in this sprint.
- Person resolution for *matching* still reads `allPeopleProvider`'s current value. `getByUuid()`'s soft-delete leak (`BACKLOG.md`) is still not this sprint's problem to fix.
- **Create Person during capture is in scope for Sprint 2B** (Phase 2B.3) — see Section 3B. People are never auto-created; creation requires explicit user approval on the confirmation screen.
- Sensitivity is still always computed via `memory_sensitivity_rules.dart` from the final category — never taken from the model, regardless of capture mode.

---

## 1. Sprint Goal

Extend Sprint 2A's capture pipeline so that:

1. A single note can yield **multiple independently confirmable memories**.
2. Users can **create a missing Person inline** during confirmation (explicit approval only).
3. Capture accepts **voice, photo (OCR), and OS share-sheet** in addition to text.
4. Late in the sprint: add **passive clarification** messaging and **confidence-indicator polish** — only after multi-memory extraction behaviour is proven.

The pipeline still stops at writing confirmed memories to Isar.

---

## 2. Pipeline Boundary — still true, read again

Unchanged from Sprint 2A: this sprint does not create/read/modify `FollowUp`, does not generate or store embeddings, does not implement search/ranking/suggestions, and does not touch sync or Supabase. Adding multi-memory / Create Person / voice / photo / share / clarification / polish does not change any of that — it only changes what feeds into the same bounded pipeline and how richly the user reviews it before the same `MemoryRepository.create()` call Sprint 2A already established.

---

## 3. Multi-memory extraction (Phase 2B.1) — locked

**Architecture lock (ADR-012):** Tend’s long-term extraction protocol is **parallel native function calls** — one flat `extract_memories` call per stable, independently useful memory. **Invariant: one FunctionCall → one `ExtractedMemoryCandidate`.** Future prompt refinements may improve completeness but must not change this contract. Do **not** experiment with `candidates[]` or other alternate protocols without a new ADR. Remaining misses are treated as **prompt/model quality**, not protocol redesign.

**Decision evidence (device spike on AIN065 / Gemma 4 E2B / GPU):**

| Approach | 2 / 3 / 4-fact notes | Single-fact control | Notes |
|---|---|---|---|
| Parallel FC | 2/2, 3/3, 4/4 accepted | 1/1 `FunctionCallResponse` | First-class `ParallelFunctionCallResponse` |
| `candidates[]` | 2/2, 3/3, 4/4 accepted | **0/1** — fell back to `TextResponse` markdown JSON (protocol failure) | Slightly faster on multi (~1–2s) but regresses single-fact path |

**Why parallel wins:** same proven flat schema as Sprint 2A; per-call grounding isolation; stable single-fact path; cleaner `ExtractionProvider` mapping (`List` of calls → candidates); better extensibility for future tools.

**Phase 2B.1 requirements (implemented):**

- Keep flat tool schema; prompt asks for one call per independent memory (incl. status/recovery when useful).
- Adapter maps **all** parallel calls (no longer drops to `.first`).
- Capture returns every validated candidate (multi-card UI is Phase 2B.2).
- **Do not** implement `clarificationNeeded` in this phase.
- Preserve grounding + category validation for **every** candidate.

Spike entrypoints (debug only): `lib/debug/multi_memory_spike_main.dart`, `same_person_multi_memory_spike_main.dart`, `mom_completeness_spike_main.dart`.

---

## 3B. Create Person during AI Capture (Phase 2B.3) — core feature

When AI extracts a `personMentioned` that does not match anyone in My Circle (no confident unique match):

- Show an inline **Add '&lt;person&gt;' to My Circle** option on the confirmation flow.
- Allow the user to edit details before creating (at minimum **Relationship** and **Circle**).
- Create the `Person` only after **explicit user approval**.
- Then allow saving the Memory linked to the newly created Person.
- **Never** create people automatically without user confirmation.

**Out of this item (still backlog):** if multiple similar people exist (e.g. "John" vs "John Smith"), suggest possible matches before offering to create a new person.

Reuse Sprint 1A person create rules/validators where possible; do not invent a parallel Person domain path.

---

## 4. Multi-memory confirmation (Phase 2B.2)

Sprint 2A took only the first validated candidate. **Remove that restriction.**

All candidates surviving `hasGroundingQuote()` and `validatedCategory()` flow to confirmation. Each is independently editable and independently selectable / deselectable / savable. Saving writes only selected/confirmed candidates, each as its own `Memory` with its own generated `uuid` — no transactional multi-save batching: each save is an independent operation.

**UX note:** Before (or instead of immediately showing) a stack of editable cards, consider a lightweight **"We found X memories"** summary with checkboxes to select which memories to keep, then edit the selected set. Use this if it simplifies the UX; do not gold-plate.

---

## 5. Files to Create or Modify

Touch set grows by phase; do not create platform/share/clarification files in 2B.1–2B.3.

### Eventually new (later phases)
```
lib/
  ai/
    providers/
      platform/
        platform_transcription_provider.dart    # 2B.4
        platform_ocr_provider.dart              # 2B.5
  features/
    capture/
      share_intent_handler.dart                 # 2B.6
      confirmation/
        widgets/
          clarification_note.dart               # 2B.7
          # Create Person inline UI (2B.3) — exact filename at implementation time
```

### Modified (by phase)
```
# 2B.1 — Multi-memory extraction
lib/ai/providers/litert/litert_prompt_builder.dart
lib/ai/providers/litert/litert_inference_adapter.dart
lib/ai/providers/litert/litert_extraction_provider.dart
lib/features/capture/capture_controller.dart

# 2B.2 — Multi-memory confirmation
lib/features/capture/confirmation/capture_confirmation_screen.dart
lib/features/capture/confirmation/capture_confirmation_controller.dart
lib/features/capture/confirmation/capture_confirmation_args.dart
lib/features/capture/confirmation/widgets/candidate_card.dart

# 2B.3 — Create Person during capture
# confirmation widgets + Person create reuse (Sprint 1A form/rules as appropriate)
# PersonRepository create path reused — avoid new repository APIs unless necessary

# 2B.4–2B.6 — Voice / OCR / Share
lib/ai/providers/ai_provider_selection.dart
lib/features/capture/capture_screen.dart
lib/features/capture/capture_controller.dart
lib/app/router.dart   # share inbound if required

# 2B.7 — Clarification + confidence polish
lib/ai/providers/extraction_provider.dart       # clarificationNeeded field
lib/ai/providers/litert/litert_extraction_provider.dart
lib/features/capture/confirmation/widgets/candidate_card.dart
lib/features/capture/confirmation/widgets/clarification_note.dart
```

Do not create a second manual-entry form, a second validation path, or a second sensitivity computation — reuse Sprint 1B / 2A code except where explicitly listed.

---

## 6. Voice Capture (Phase 2B.4)

- `platform_transcription_provider.dart` wraps native speech-to-text (iOS Speech framework / Android `SpeechRecognizer`, or the `speech_to_text` package) — **never routes through `flutter_gemma`**, per `ARCHITECTURE.md` Section 6.
- The recorded audio file is stored locally (app documents directory, a dedicated captures subfolder) and its path becomes `Memory.sourceRef` for any memory saved from that recording. Cleanup/retention of these files is still out of scope.
- `capture_controller.dart`: voice mode records audio → `PlatformTranscriptionProvider.transcribe()` → resulting text enters the same extraction path as typed text.
- `sourceType = SourceType.voice` on any memory saved from this path.

## 7. Photo Capture (Phase 2B.5)

- `platform_ocr_provider.dart` wraps on-device text recognition (ML Kit / Vision framework, or `google_mlkit_text_recognition`) — **never routes through `flutter_gemma`**. Screenshots/text-bearing photos only — scene captioning is P1 (`FEATURES.md`), not this sprint.
- The photo file is stored locally the same way as voice audio; its path becomes `Memory.sourceRef`.
- `capture_controller.dart`: photo mode picks/captures an image → `PlatformOCRProvider.extractText()` → resulting text enters the same extraction path.
- `sourceType = SourceType.photo` on any memory saved from this path.

## 8. OS Share-Sheet (Phase 2B.6)

- `share_intent_handler.dart` receives shared text from other apps (via a share-intent package or platform channel — confirm the package at implementation time).
- Shared text enters the same extraction path as typed text — no separate pipeline.
- `sourceType = SourceType.share`; `sourceRef = null`.

## 9. Unsupported-Device Fallback, Extended to Voice/Photo

Sprint 2A's fallback (typed text pre-fills `MemoryFormScreen` directly, no extraction attempted) is extended, not replaced:

- **Transcription and OCR are not gated by device tier.** They still run on unsupported/low-RAM devices.
- On an unsupported device, voice/photo still transcribes/OCRs, then skips extraction and pre-fills `MemoryFormScreen.eventText` in create mode.
- Still no second manual-entry form. Still the same `MemoryFormScreen` from Sprint 1B.

## 10. Clarification UI (Phase 2B.7 only)

**Do not implement until multi-memory extraction is proven** and it is clear when clarification is genuinely needed.

Then:

- Extend `ExtractionResult` with `clarificationNeeded` (see shape below).
- `clarification_note.dart` renders entries as a **passive, non-blocking** note on confirmation — never blocking save, never interactive.
- No conversational repair loop, no re-prompting the model.

```dart
class ExtractionResult {
  final List<ExtractedMemoryCandidate> candidates;
  final List<ClarificationNeeded> clarificationNeeded;   // Phase 2B.7
}

class ClarificationNeeded {
  final String reason;
  final String rawSnippet;
}
```

## 11. Confidence-Indicator Polish (Phase 2B.7)

- Replace Sprint 2A's plain/minimal below-threshold label with a calmer visual treatment.
- Visual only — `needsUserConfirmation` / threshold logic in `extraction_validation_rules.dart` unchanged.
- Distinguishing low extraction vs low person-match confidence is optional; a single “double-check this” treatment is acceptable.

---

## 12. Acceptance Criteria

1. Voice, photo, text, and share-sheet capture are all reachable from the same global entry point established in Sprint 2A.
2. Voice capture transcribes via `PlatformTranscriptionProvider`; photo capture extracts text via `PlatformOCRProvider`; neither routes through the LiteRT / `flutter_gemma` adapter (debug probe under `lib/debug/` may still import `flutter_gemma`).
3. A capture producing multiple valid candidates renders multiple independently-editable, independently-selectable/confirmable cards (or summary → cards); saving writes only the confirmed ones.
4. When `personMentioned` has no Circle match, the user can add the person inline after explicit approval (Relationship + Circle editable); people are never auto-created.
5. `ExtractionResult.clarificationNeeded` entries (Phase 2B.7) render as a passive note, never blocking save, never interactive.
6. A below-threshold candidate shows the polished confidence indicator (Phase 2B.7); `needsUserConfirmation` is still computed exactly as in Sprint 2A.
7. On an unsupported/low-RAM device, voice/photo capture still transcribes/OCRs successfully and pre-fills `MemoryFormScreen`.
8. `sourceType`/`sourceRef` are set correctly per capture method (`voice`+file path, `photo`+file path, `share`+null, `text`+null).
9. Every Sprint 2A acceptance criterion still holds — nothing about the text-only path regresses.
10. `Memory.embedding` is still `null` for every record; no `FollowUp` record exists anywhere; no Supabase table is touched.
11. Offline remains supported. Prefer warm capture flows well under ~10s; cold first inference after prepare may exceed that (known Sprint 2A nuance) — do not regress warm-path behaviour.

---

## 13. Definition of Done

- [ ] Multi-memory extraction approach chosen and implemented (parallel FC **or** candidates array); single-fact path does not regress.
- [ ] Single-candidate restriction removed; confirmation supports review / edit / select / save per memory.
- [ ] Create Person during capture works with explicit approval only (Relationship + Circle editable).
- [ ] `PlatformTranscriptionProvider` and `PlatformOCRProvider` implemented and wired; neither imports `flutter_gemma`.
- [ ] Voice, photo, and share-sheet each produce correct `sourceType`/`sourceRef`.
- [ ] Unsupported-device fallback works for voice/photo as for text in Sprint 2A.
- [ ] Clarification + confidence polish landed in Phase 2B.7 only; confidence logic thresholds unchanged.
- [ ] No `EmbeddingProvider` implementation; `Memory.embedding` null; no FollowUp / Supabase writes.
- [ ] Sprint 2A testing checklist still passes, plus Section 15.

---

## 14. Explicit Out-of-Scope Items

- Suggestion Engine, `FollowUp`, semantic search/embeddings, sync, Supabase writes, data export/encryption, fine-tuned FunctionGemma, cloud-model fallback.
- Vision captioning of scene photos with no text (P1).
- Interactive/conversational clarification — passive note only, and only in Phase 2B.7.
- Suggesting matches among similar existing names before Create Person (future backlog enhancement).
- Transactional multi-save / partial-failure recovery UI — each candidate save is independent.
- Captured audio/photo file lifecycle management (cleanup, retention).
- Fixing `PersonRepository.getByUuid()` soft-delete leak unless Create Person absolutely requires it (prefer `allPeopleProvider` + existing create APIs).

---

## 15. Testing Checklist

Run Sprint 2A's full Testing Checklist first to confirm no regression, then by phase:

**2B.1 / 2B.2**
- [ ] Multi-fact note (e.g. two people / two facts) → multiple validated candidates → multi-card (or summary + cards) confirmation; save one, discard another; only saved rows in Isar.
- [ ] Single-fact note still yields exactly one good candidate (no regression).

**2B.3**
- [ ] Unknown `personMentioned` → inline Add to My Circle → edit Relationship/Circle → approve → Memory linked to new Person; cancel/dismiss does not create a Person.

**2B.4–2B.6**
- [ ] Voice → transcription → extraction → correct `sourceType`/`sourceRef`.
- [ ] Photo OCR → same with `photo` + file path.
- [ ] OS share → `share`, `sourceRef = null`.
- [ ] Unsupported device: voice/photo still ASR/OCR then pre-fill `MemoryFormScreen`.

**2B.7**
- [ ] Clarification note passive when present; does not block save.
- [ ] Polished confidence indicator; `needsUserConfirmation` still correct.

**Always**
- [ ] Airplane-mode full cycle succeeds with zero network calls.
- [ ] `flutter_gemma` imports only in `litert_inference_adapter.dart` and debug probe files — not in `platform/` providers.

---

## 16. Implementation plan (authoritative phase order)

Implement **only** in this order. Do not skip ahead to voice/OCR/share/clarification before earlier phases are done.

| Phase | Name | What to build | Complexity | Notes / risks |
|---|---|---|---|---|
| **2B.1** | Multi-memory extraction | **Done (parallel FC).** Spike locked approach; adapter/provider/prompt + Capture pass all candidates | **High** | Confirmed on device; multi-card UI deferred to 2B.2 |
| **2B.2** | Multi-memory confirmation | **Done.** Summary → multi-card; Save toggles; N=1 keeps 2A UX | **Medium** | Depends on 2B.1 returning N candidates |
| **2B.3** | Create Person during capture | **Done.** Exact-match Create Person dialog on confirmation; no auto-create | **Medium** | Fuzzy similar-name suggestions remain backlog |
| **2B.4** | Voice capture | `PlatformTranscriptionProvider`, mic permissions, audio `sourceRef`, wire into extract → confirm | **High** | OS ASR variance; file retention debt; RAM with model loaded |
| **2B.5** | OCR / Photo capture | `PlatformOCRProvider`, camera/gallery, image `sourceRef`, OCR-only | **High** | Empty OCR; permissions; avoid scene captioning scope creep |
| **2B.6** | Share to Tend | Share-intent handler; `SourceType.share`; cold-start into capture | **Medium–High** | App-not-running share lifecycle; package choice at implement time |
| **2B.7** | Clarification + confidence polish | Add `clarificationNeeded` only once multi-extract is understood; passive note; confidence badge polish | **Low–Medium** | Explicitly last — implement clarification only when genuinely needed |

### Dependency sketch

```text
2B.1 Multi-memory extraction
  → 2B.2 Multi-memory confirmation
    → 2B.3 Create Person during capture
      → 2B.4 Voice
        → 2B.5 OCR / Photo
          → 2B.6 Share to Tend
            → 2B.7 Clarification + confidence polish
```

### Phase gate before 2B.4

Do not start voice until:

1. Multi-fact extraction is reliable enough for confirmation testing.
2. Multi-card (or summary → cards) confirmation can save/discard independently.
3. Create Person inline works without auto-create.

### Phase gate before 2B.7

Do not add `clarificationNeeded` until multi-memory behaviour is proven in real captures and product decides when clarification is genuinely useful (vs empty/noisy model output).
