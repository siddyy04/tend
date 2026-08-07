# SPRINT 2B IMPLEMENTATION SPECIFICATION
### Target: AI coding agent (Cursor). Read fully before writing any code.

You are implementing **Sprint 2B only** of the Tend Flutter app. Reference documents already in this repository: `ARCHITECTURE.md`, `ADR.md`, `FEATURES.md`, `SCHEMA.md`, `DEVELOPMENT_ROADMAP.md`, `BACKLOG.md`, `SPRINT0.md`, `SPRINT1A.md`, `SPRINT1B.md`, and **`SPRINT2A.md`** (the immediately prior sprint — read it in full before starting this one; Sprint 2B extends its files rather than starting fresh). This specification is the authoritative scope for this task. If anything here appears to conflict with those documents, stop and ask rather than guessing which one wins.

Sprint 2B is the second half of the original Sprint 2 split. It extends Sprint 2A's text-only pipeline with voice capture, photo capture, OS share-sheet, multi-candidate extraction, clarification UI, and confidence-indicator polish. **Nothing in this sprint changes where the pipeline stops** — see Section 2, carried over unchanged from Sprint 2A.

---

## 0. Carried Over From Sprint 2A (still binding, not repeated in full)

- Embeddings remain entirely out of scope. `EmbeddingProvider` stays interface-only; a concrete LiteRT embedding provider is not built in this sprint either. `Memory.embedding` stays `null` for every record created in Sprint 2B, same as 2A. This is a deliberate deviation from `DEVELOPMENT_ROADMAP.md`'s original Sprint 2 bullet, still in effect.
- `FollowUp` remains completely untouched — no create, read, or update, anywhere in this sprint.
- Person resolution still reads `allPeopleProvider`'s current value; `PersonRepository` is still not modified. `getByUuid()`'s soft-delete leak (`BACKLOG.md`) is still not this sprint's problem to fix.
- Creating a brand-new `Person` inline from the confirmation screen is still out of scope.
- Sensitivity is still always computed via `memory_sensitivity_rules.dart` from the final category — never taken from the model, regardless of capture mode.

---

## 1. Sprint Goal

Extend Sprint 2A's capture pipeline to support voice capture, photo capture, and OS share-sheet input; remove the single-candidate restriction so a capture producing multiple facts surfaces multiple independently-confirmable candidates; add passive clarification-needed messaging; and replace the plain confidence indicator with a polished one. The pipeline still stops at writing confirmed memories to Isar — nothing about the destination changes, only the range of inputs and the richness of the confirmation experience.

---

## 2. Pipeline Boundary — still true, read again

Unchanged from Sprint 2A: this sprint does not create/read/modify `FollowUp`, does not generate or store embeddings, does not implement search/ranking/suggestions, and does not touch sync or Supabase. Adding voice/photo/share/multi-candidate/clarification/polish does not change any of that — it only changes what feeds into the same bounded pipeline and how richly the user reviews it before the same `MemoryRepository.create()` call Sprint 2A already established.

---

## 3. `ExtractionResult` — extended shape

Add back what Sprint 2A deliberately omitted:

```dart
class ExtractionResult {
  final List<ExtractedMemoryCandidate> candidates;
  final List<ClarificationNeeded> clarificationNeeded;   // NEW this sprint
}

class ClarificationNeeded {
  final String reason;
  final String rawSnippet;
}
```

`ExtractedMemoryCandidate` itself is unchanged from Sprint 2A. Update `litert_extraction_provider.dart` to populate `clarificationNeeded` from the model's function-call output (it was previously discarded/ignored if present at all).

---

## 4. Remove the Single-Candidate Restriction

Sprint 2A's `capture_confirmation_controller.dart` took only the first validated candidate and discarded the rest. **Remove that restriction.** All candidates surviving `hasGroundingQuote()` and `validatedCategory()` (Section 5 of `SPRINT2A.md`, unchanged) now flow through to the confirmation screen, each independently editable and independently confirmable or discardable. Saving writes only the confirmed candidates, each as its own `Memory` with its own generated `uuid` — no batching, no partial-failure rollback complexity: each candidate save is an independent operation.

This should be a small, additive change against Sprint 2A's existing code — the `List<ExtractedMemoryCandidate>` shape was already there for exactly this reason. If removing the restriction requires restructuring `capture_controller.dart` or `capture_confirmation_controller.dart` significantly, stop and reconsider whether Sprint 2A's implementation followed its own spec correctly, rather than working around it.

---

## 5. Files to Create or Modify

### New files
```
lib/
  ai/
    providers/
      platform/
        platform_transcription_provider.dart
        platform_ocr_provider.dart
  features/
    capture/
      share_intent_handler.dart          # OS share-sheet inbound handling
      confirmation/
        widgets/
          clarification_note.dart        # passive, non-blocking display for ClarificationNeeded entries
```

### Modified files
```
lib/
  ai/
    providers/
      ai_provider_selection.dart         # wire the new PlatformTranscriptionProvider/PlatformOCRProvider
      extraction_provider.dart           # ExtractionResult gains clarificationNeeded — Section 3
      litert/
        litert_extraction_provider.dart   # populate clarificationNeeded from model output
  features/
    capture/
      capture_screen.dart                # add voice/photo/share entry points alongside existing text mode
      capture_controller.dart            # orchestrate transcription/OCR before extraction; handle multi-candidate results
      confirmation/
        capture_confirmation_screen.dart      # multi-card layout
        capture_confirmation_controller.dart  # remove single-candidate restriction — Section 4
        widgets/
          candidate_card.dart                 # confidence-indicator visual polish
  app/
    router.dart                          # add a route/handler for inbound OS share-sheet content, if the
                                          # platform integration requires one (confirm at implementation time)
```

Do not create a second manual-entry form, a second validation path, or a second sensitivity computation — all of that is Sprint 2A's code, reused unmodified except where explicitly listed above.

---

## 6. Voice Capture

- `platform_transcription_provider.dart` wraps native speech-to-text (iOS Speech framework / Android `SpeechRecognizer`, or the `speech_to_text` package) — **never routes through `flutter_gemma`**, per `ARCHITECTURE.md` Section 6.
- The recorded audio file is stored locally (app documents directory, a dedicated captures subfolder) and its path becomes `Memory.sourceRef` for any memory saved from that recording. Cleanup/retention of these files is still out of scope (Section 12, carried from Sprint 2A).
- `capture_controller.dart`: voice mode records audio → `PlatformTranscriptionProvider.transcribe()` → resulting text enters the same extraction path Sprint 2A built for typed text, unchanged from that point on.
- `sourceType = SourceType.voice` on any memory saved from this path.

## 7. Photo Capture

- `platform_ocr_provider.dart` wraps on-device text recognition (ML Kit / Vision framework, or `google_mlkit_text_recognition`) — **never routes through `flutter_gemma`**, per `ARCHITECTURE.md` Section 6. This handles screenshots/text-bearing photos only — captioning a scene photo with no text is explicitly P1 (`FEATURES.md`), not this sprint.
- The photo file is stored locally the same way as voice audio; its path becomes `Memory.sourceRef`.
- `capture_controller.dart`: photo mode picks/captures an image → `PlatformOCRProvider.extractText()` → resulting text enters the same extraction path.
- `sourceType = SourceType.photo` on any memory saved from this path.

## 8. OS Share-Sheet

- `share_intent_handler.dart` receives shared text from other apps (via a share-intent package or platform channel — confirm the current recommended package at implementation time rather than assuming one).
- Shared text enters the same extraction path as typed text — no separate pipeline.
- `sourceType = SourceType.share` on any memory saved from this path; `sourceRef = null` (shared text has no local file, same as typed text in Sprint 2A).

## 9. Unsupported-Device Fallback, Extended to Voice/Photo

Sprint 2A's fallback (typed text pre-fills `MemoryFormScreen` directly, no extraction attempted) is extended, not replaced:

- **Transcription and OCR are not gated by device tier.** They're lightweight OS features, not LiteRT-model-dependent — they still run on unsupported/low-RAM devices exactly as they do on supported ones.
- On an unsupported device, voice/photo capture still transcribes/OCRs successfully, but the resulting text skips extraction entirely and pre-fills `MemoryFormScreen.eventText` in create mode, same pattern as Sprint 2A's text fallback — the user completes category/person/date manually from there.
- Still no second manual-entry form. Still the same `MemoryFormScreen` from Sprint 1B.

## 10. Clarification UI

- `clarification_note.dart` renders `ExtractionResult.clarificationNeeded` entries as a **passive, non-blocking informational note** on the confirmation screen (e.g. "Some of what you said couldn't be captured clearly") — visible alongside whatever candidate cards exist, never blocking save, never interactive.
- No conversational repair loop, no re-prompting the model, no per-entry action. If this feels like it needs more than a static, dismissible note, that's Sprint 3+ scope, not this sprint's — flag it rather than building it.

## 11. Confidence-Indicator Polish

- Replace Sprint 2A's plain/minimal below-threshold label on `candidate_card.dart` with a proper visual treatment (e.g. a distinct badge or inline styling) that clearly but calmly signals "worth double-checking" without alarming the user — this is UI polish, not new logic. The underlying `needsUserConfirmation` computation from `extraction_validation_rules.dart` (Sprint 2A) is unchanged.
- Consider (but don't over-build) visually distinguishing a low `extractionConfidence` from a low `personMatchConfidence`, since they mean different things to the user ("I'm not sure I got this right" vs. "I'm not sure who this is about") — if this adds meaningful complexity, a single unified "double-check this" treatment is an acceptable simpler alternative; use judgment, don't gold-plate this.

---

## 12. Acceptance Criteria

1. Voice, photo, text, and share-sheet capture are all reachable from the same global entry point established in Sprint 2A.
2. Voice capture transcribes via `PlatformTranscriptionProvider`; photo capture extracts text via `PlatformOCRProvider`; neither routes through the LiteRT / `flutter_gemma` adapter.
3. A capture producing multiple valid candidates (e.g. mentioning two different people) renders multiple independently-editable, independently-confirmable cards; saving writes only the confirmed ones.
4. `ExtractionResult.clarificationNeeded` entries render as a passive note, never blocking save, never interactive.
5. A below-threshold candidate shows the polished confidence indicator; `needsUserConfirmation` is still computed exactly as in Sprint 2A.
6. On an unsupported/low-RAM device, voice/photo capture still transcribes/OCRs successfully and pre-fills `MemoryFormScreen`, same fallback pattern as Sprint 2A's text path.
7. `sourceType`/`sourceRef` are set correctly per capture method (`voice`+file path, `photo`+file path, `share`+null, `text`+null).
8. Every Sprint 2A acceptance criterion still holds — nothing about the text-only path regresses.
9. `Memory.embedding` is still `null` for every record; no `FollowUp` record exists anywhere; no Supabase table is touched.
10. All of this remains fully functional offline, with each capture-to-saved-memory flow well under 10 seconds.

---

## 13. Definition of Done

- [ ] `PlatformTranscriptionProvider` and `PlatformOCRProvider` are implemented and wired via `ai_provider_selection.dart`; neither imports `flutter_gemma`.
- [ ] `ExtractionResult` includes `clarificationNeeded`; `LiteRtExtractionProvider` populates it from the model's output.
- [ ] The single-candidate restriction from Sprint 2A is removed; the confirmation screen renders one card per validated candidate.
- [ ] Voice, photo, and share-sheet each produce a `Memory` with the correct `sourceType`/`sourceRef` per Section 12 item 7.
- [ ] The unsupported-device fallback works identically in spirit for voice/photo as it did for text in Sprint 2A — same target screen, same reuse of `MemoryFormScreen`.
- [ ] Confidence-indicator polish is visual only — no change to `extraction_validation_rules.dart`'s threshold logic.
- [ ] No new file exists implementing `EmbeddingProvider`; `Memory.embedding` is null on every record created this sprint.
- [ ] No `FollowUp`-touching code, no Supabase read/write, anywhere in this sprint's changes.
- [ ] Every Sprint 2A Testing Checklist item still passes, in addition to every scenario in this sprint's Section 15.

---

## 14. Explicit Out-of-Scope Items

- Everything already out of scope in Sprint 2A (Suggestion Engine, `FollowUp`, semantic search/embeddings, sync, Supabase writes, data export/encryption, inline Person creation, fine-tuned FunctionGemma, cloud-model fallback) remains out of scope here too.
- Vision captioning of scene photos with no text (P1 per `FEATURES.md`) — this sprint's photo capture is OCR-on-text-bearing-images only.
- Interactive/conversational clarification handling — passive note only, per Section 10.
- Any per-candidate save batching, transactional multi-save, or partial-failure recovery UI — each candidate save is an independent, simple operation.
- Captured audio/photo file lifecycle management (cleanup, storage limits, retention) — still not addressed.
- Any change to `memory_validators.dart`, `memory_sensitivity_rules.dart`, or `PersonRepository` beyond what's explicitly listed in Section 5.

---

## 15. Testing Checklist

Run Sprint 2A's full Testing Checklist first to confirm no regression, then:

- [ ] Capture via voice with a clear single-fact input — confirm transcription happens, extraction runs, and a correct candidate appears with `sourceType = voice` and a valid `sourceRef` pointing to the saved audio file.
- [ ] Capture via photo of a text-bearing screenshot — confirm OCR happens, extraction runs, and a correct candidate appears with `sourceType = photo` and a valid `sourceRef`.
- [ ] Trigger capture via OS share-sheet from another app — confirm it enters the same pipeline with `sourceType = share`, `sourceRef = null`.
- [ ] Capture a single input mentioning two different people — confirm two independent candidate cards appear; confirm one, discard the other; confirm only the confirmed one is written to Isar.
- [ ] Force an input that produces a `clarificationNeeded` entry — confirm the passive note renders, does not block saving any valid candidates alongside it, and has no interactive elements.
- [ ] Force a low-confidence candidate — confirm the polished indicator renders (not Sprint 2A's plain label) and `needsUserConfirmation` is still set correctly.
- [ ] Simulate an unsupported/low-RAM device and capture via voice — confirm transcription still succeeds and the text pre-fills `MemoryFormScreen`, with no extraction attempted and no crash.
- [ ] Simulate the same for photo capture on an unsupported device.
- [ ] Complete a full voice-capture-to-multi-candidate-confirmation-to-save cycle in airplane mode — confirm success with zero network calls.
- [ ] Grep the codebase for any import of `flutter_gemma` outside `lib/ai/providers/litert/litert_inference_adapter.dart` — confirm zero matches, including in the new `platform/` provider files.
