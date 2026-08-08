> **Backlog Rules**
>
> - Items in this document are intentionally out of scope for the current sprint.
> - New ideas should be added here instead of expanding the current sprint.
> - Priorities should be reviewed at the start of each sprint.
> - Completing the current sprint always takes precedence over backlog items.

# Product Backlog

## High Priority

### Evaluate long-form speech transcription providers
**Problem**
Tend’s product vision includes users speaking long conversations, stories, reflections, and updates — not only short memory snippets. Sprint 2B.4 MVP uses platform STT (`PlatformTranscriptionProvider` / `speech_to_text`), which is acceptable for short notes but is **not** a long-term solution (Android session length, pause timeouts, truncation, and dictation quality).

**Sprint / area**
Future dedicated evaluation sprint (after Sprint 2B functionality). **Do not implement a new engine until this evaluation completes.** Capture / Extraction / Confirmation must stay unchanged when the provider is swapped (`activeTranscriptionProvider`).

**Proposed solution**
Run a structured comparison; **do not pick an engine in this backlog item itself**. Document findings and recommend 1–2 candidates for a later implementation sprint.

**Candidates to compare (non-exhaustive)**
- Android platform STT (current MVP baseline)
- iOS Speech framework (current MVP baseline on Apple)
- Whisper (on-device)
- Whisper (cloud)
- Gemini / Google Speech APIs
- Other high-quality long-form transcription engines as relevant

**Evaluation criteria**
- Long-form transcription accuracy (multi-minute conversational speech)
- Multi-minute recording support (pauses, session continuity)
- Privacy (on-device vs cloud; audio retention)
- Offline capability
- Latency (time to editable transcript)
- Battery usage
- Memory / RAM usage (esp. alongside Gemma / LiteRT)
- Cost (if cloud)
- Ease of integration with `TranscriptionProvider` (listen-session and/or file `transcribe`)
- Multilingual support (reuse Settings speech-language preference)

**Related**
- `TranscriptionProvider` + `activeTranscriptionProvider` — swap point
- Speech language preference in Settings (`SpeechLocalePreferences`)
- Existing medium-priority voice items (waveform, VAD, live transcription, audio `sourceRef`) remain separate
- Downstream product vision: **Conversation Mode** (below) — depends on a capable long-form transcription foundation

---

### Conversation Mode — continuous long-form voice → incremental memories
**Problem**
MVP Voice is a single session: record → one transcript → one extraction pass. Product vision goes further: users should feel comfortable speaking for several minutes (conversations, stories, reflections, updates) as if talking to a trusted friend, while Tend continuously turns speech into memory candidates.

**Example**
User speaks for several minutes. Tend continuously segments speech into memory candidates instead of waiting for one final transcript.

**Sprint / area**
**Out of scope for MVP / Sprint 2B.** Post–long-form STT evaluation and after a capable transcription provider is in place. Do not start this while platform STT remains the only engine.

**Requires**
- Streaming transcription
- Incremental extraction (segment → candidate(s) without blocking the whole conversation)
- Conversational pause detection (segment boundaries, not crude auto-stop alone)
- Recovery after interruptions (app backgrounded, STT hiccups, brief silence, errors)

**Proposed direction (not an implementation plan yet)**
- Keep Capture → Confirmation → Save as the user trust boundary; Conversation Mode feeds candidates into review rather than auto-saving silently.
- Preserve `TranscriptionProvider` / `ExtractionProvider` separation — audio still never goes to Gemma as a live multimodal stream unless a future ADR explicitly changes that.
- Depends on High Priority: “Evaluate long-form speech transcription providers.”

**Explicitly not MVP**
- No streaming extraction UI, no continuous listen loop, no Conversation Mode chrome in Sprint 2B.

---

### Person → memory cascade delete
**Problem**
`FEATURES.md` requires deleting a person to cascade to their memories, follow-ups, and suggestion history. Sprint 1B intentionally deferred this.

**Proposed solution**
- When a Person is soft-deleted, also soft-delete related Memories (and later FollowUps / suggestion history).
- Keep tombstones; never hard-delete in early sprints.
- Likely fits Sprint 6 data-controls work unless re-prioritized earlier.
- Resolve `FollowUp.deletedAt` SCHEMA vs ARCHITECTURE mismatch before cascading to FollowUps.

---

### PersonRepository.getByUuid hides soft-deleted records
**Problem**
`MemoryRepository.getByUuid` excludes soft-deleted rows at the Isar query layer. `PersonRepository.getByUuid` still returns tombstoned people via the unique-index helper.

**Proposed solution**
- Align Person with Memory: filter `uuidEqualTo` + `deletedAtIsNull` in the repository query.
- Keeps “repositories hide deleted records completely” consistent.

---

### Duplicate person names
**Problem**
Multiple people can legitimately share the same name, making the Circle list confusing.

**Proposed solution**
- Detect duplicate names during create/edit.
- Show a non-blocking informational message.
- Suggest adding a Relationship Type or nickname.
- Never prevent saving.

---

### Undo delete
**Problem**
Accidental deletes currently require a future restore feature.

**Proposed solution**
- After deleting a Person or Memory, show:
  - "Deleted"
  - Undo button
- Keep soft delete as the underlying implementation.

---

## Medium Priority

### AI Quality — Improve extraction completeness for pronouns and compound sentences
**Problem**
Multi-memory extraction under-extracts when later sentences use pronouns, or when multiple facts share one sentence. Manual test:

> Mom had spinal surgery. She started physiotherapy and is recovering well.

Expected three memories (surgery, physiotherapy, recovering well). Actual: only the first memory when later clauses use “She” / “and”. Earlier same-person benchmarks passed when each sentence repeated the name (“Mom … Mom …”), so this is prompt/completeness quality, not protocol design (ADR-012).

**Sprint / area**
AI Quality (post–Sprint 2B prompt refinement; does **not** block Sprint 2B.3+)

**Proposed solution (prompt only)**
- Treat every independently useful fact as a separate memory.
- Do not skip memories merely because later sentences use pronouns (he, she, they, him, her, etc.) instead of repeating the name.
- Split multiple independent facts in one sentence joined by “and” / “also” / “but” into separate memories where appropriate.
- Continue avoiding duplicated or merged memories.
- **Preserve architecture:** one native FunctionCall = one memory; parallel FunctionCall protocol; no `candidates[]` primary protocol (ADR-012).

**Regression suite**
See `EXTRACTION_COMPLETENESS_BENCHMARK.md` (and `lib/debug/extraction_completeness_cases.dart`). Re-run whenever extraction prompts are refined.

---

### AI Quality — complete primary clause for eventText
**Problem**
Literal extraction sometimes returns verb fragments for `eventText` (e.g. “works at Google” instead of “John works at Google”), which is weaker for confirmation and saved memory display even when grounding accepts the candidate.

**Proposed solution**
- When extracting `eventText`, prefer the complete primary clause, including subject, instead of returning verb fragments.
- Keep using only words from the note; do not invent.
- Prompt already nudges this; revisit if Gemma 4 E2B still truncates after confirmation UX review.

---

### Capture UX — clearer empty-extraction message for insufficient notes
**Problem**
When a note lacks enough information (e.g. bare name “Emily”), grounding correctly yields zero memories, but Capture shows a generic “Nothing could be captured from that note” message. That undersells the real reason and does not guide the user.

**Status**
**Shipped** — shared empty-state panel across Typed / Voice / OCR (`CaptureEmptyMemoriesPanel` via `CaptureSubmitFlowEmpty`). Genuine pipeline failures stay on `CaptureSubmitFailed`. Technical mapping/grounding strings are debug-only.

---

### Capture UX Polish — first-class Voice / OCR / Share actions
**Problem**
Voice (and, once shipped, OCR and Share) enter Capture via secondary controls (e.g. a small AppBar microphone icon). That works functionally but underplays Voice as a primary way to capture memories.

**Sprint / area**
**Capture UX Polish** — after Sprint 2B OCR (2B.5) and Share (2B.6) are complete. Do **not** redesign Capture chrome during 2B functionality phases.

**Proposed solution**
- Redesign the Capture screen so **Voice**, **OCR/Photo**, and **Share** are first-class actions alongside typed notes (not AppBar-only secondary icons).
- Keep a single shared extract → confirm → save pipeline; polish is presentation and entry hierarchy only.
- Decide layout (e.g. primary action cluster, mode switcher, or empty-state CTAs) once all three ingress methods exist and can be designed together.

---

### Voice capture — live transcription during recording
**Problem**
Sprint 2B.4 hides partial ASR results; users cannot see words appear while speaking.

**Proposed solution**
- Optionally show live partial transcript on the recording screen.
- Keep extraction gated until Stop → edit → Continue (model still never receives audio).

---

### Voice capture — waveform animation
**Problem**
Recording UI has indicator + timer only; no amplitude feedback.

**Proposed solution**
- Add a simple waveform or level meter while recording (cosmetic only).

---

### Voice capture — Voice Activity Detection (auto-stop)
**Problem**
Users must tap Stop manually; long silences keep the session open.

**Proposed solution**
- Detect sustained silence and offer or perform auto-stop after a threshold.
- Keep an explicit Stop control.

---

### Voice capture — offline speech recognition evaluation
**Problem**
Platform ASR quality and offline availability vary by OS/vendor.

**Status**
**Superseded / folded into High Priority:** “Evaluate long-form speech transcription providers.” Use that item as the authoritative evaluation task (includes offline capability as a criterion). Keep this note so older references still resolve.

---

### Voice capture — analytics
**Problem**
No product telemetry for voice funnel quality.

**Proposed solution**
- Track recording duration, whether the transcript was edited before Continue, and downstream extraction success/empty/failure (privacy-preserving; no raw audio/transcript content in analytics payloads unless explicitly approved later).

---

### Voice capture — persist audio file as `sourceRef` + retention/deletion policy
**Problem**
Sprint 2B.4 sets `sourceType = voice` but does not yet store a local audio file path in `Memory.sourceRef` (platform listen-session ASR does not yield a file). Retention/deletion of any future audio captures is undefined.

**Proposed solution**
- Record audio to app documents (captures subfolder) when mic exclusivity allows, or adopt a file-capable STT path.
- Set `sourceRef` to that path on save.
- Define retention (e.g. delete with soft-deleted memory, max age, user purge) and implement cleanup.

---

### OCR — handwriting recognition
**Problem**
MVP OCR targets printed / screenshot text; handwritten notes may fail or read poorly.

**Proposed solution**
- Evaluate handwriting-capable OCR engines or script packs; keep behind `OCRProvider`.

---

### OCR — automatic document detection
**Problem**
Users must frame documents manually; cluttered photos reduce OCR quality.

**Proposed solution**
- Detect document / page bounds before OCR (still no AI vision captioning).

---

### OCR — automatic cropping
**Problem**
Full-frame photos include unrelated background that can confuse OCR.

**Proposed solution**
- Crop to detected document region (or user-adjustable crop) before OCR.

---

### OCR — perspective correction
**Problem**
Angled photos of invitations / notices warp text and hurt recognition.

**Proposed solution**
- Apply perspective transform after document detection.

---

### OCR — multi-page document OCR
**Problem**
Multi-page notices require repeated captures; no assembly into one editable text.

**Proposed solution**
- Capture multiple pages, OCR each, concatenate (with page markers) into one editable draft.

---

### OCR — batch image processing
**Problem**
Users may want several photos in one capture session.

**Proposed solution**
- Select multiple gallery images; OCR sequentially; merge or present as separate drafts.

---

### OCR — confidence overlay
**Problem**
Users cannot see which regions OCR was unsure about before editing.

**Proposed solution**
- Optional overlay / highlights for low-confidence blocks (engine permitting).

---

### OCR — image enhancement before OCR
**Problem**
Low light, glare, or low contrast reduces OCR accuracy.

**Proposed solution**
- Lightweight preprocess (contrast / denoise / binarize) before `extractText` — still not generative AI enhancement.

---

### OCR — language / script selection
**Problem**
MVP uses Latin ML Kit script; other scripts need explicit packs / selection.

**Proposed solution**
- Settings preference for OCR script/language (similar to speech language), wired through `OCRProvider`.

---

### OCR — AI vision models for image understanding
**Problem**
Scene photos (not text-bearing) cannot become memories via OCR alone.

**Sprint / area**
P1 / FEATURES vision captioning — **not** Sprint 2B. Requires explicit product + ADR if the LLM ever receives images.

**Proposed solution**
- Separate from OCR path; do not overload `OCRProvider` with captioning.

---

### OCR — original image retention/deletion policy
**Problem**
Sprint 2B.5 stores images under `documents/captures/` as `sourceRef`; retention and purge rules are undefined.

**Proposed solution**
- Define retention (delete with soft-deleted memory, max age, user purge) and implement cleanup. Align with voice audio retention policy where possible.

---

### AI / Date Resolution
**Problem**
Relative date phrases are stored as `dateValueRaw` only. Confirmation and later features benefit from an absolute `dateValue` derived from the device clock.

**Proposed solution**
- When `datePrecision == relative`, resolve `dateValueRaw` into an absolute `dateValue` using the device’s current date and timezone.
- Examples: tomorrow, yesterday, next week, next Thursday, in 3 months.
- The LLM should continue copying the literal phrase only. Resolution should be deterministic in app code rather than performed by the model.

---

### Temporary Logout on My Circle
**Problem**
Developer Logout lives on the My Circle AppBar from Sprint 0.

**Proposed solution**
- Move sign-out into Settings (Sprint 5/6) and remove the temporary AppBar action.

---

### Auth surface: phone OTP
**Problem**
`FEATURES.md` mentions email/phone OTP; the app currently supports email/password only.

**Proposed solution**
- Add phone OTP (or document email/password as the intentional MVP auth path).

---

### Person Profile extras (FEATURES P0 notes)
**Problem**
FEATURES Person Profile lists upcoming/recent, category filter, and search entry point. Sprint 1B shipped timeline + manual memories only.

**Proposed solution**
- Add category filter / search entry / upcoming-recent sections when those P0 surfaces are built (Search sprint / polish), without expanding AI scope early.

---

### FollowUp.deletedAt schema alignment
**Problem**
`ARCHITECTURE.md` collection sketch includes `deletedAt` on FollowUp; `SCHEMA.md` FollowUp does not.

**Proposed solution**
- Pick one contract before Sprint 3 (Suggestion Engine) or cascade-delete work touches FollowUps.
- Prefer updating SCHEMA + Isar collection together if tombstones are required.

---

### Archive person
Allow users to archive a person without deleting them or their memories.
Archived people should disappear from My Circle but remain searchable and restorable.

---

### Rich display names
Support richer display names such as:
- Uncle John
- John (Work)
- John Smith
- Dr. Patel

without changing the underlying identity model.

---

### Timeline grouping
Group memories by year and month once a person has many memories.

Example:
2026
- July
- June

2025
- December
- October

---

### Pin memories
Allow users to pin important memories so they always appear above the chronological timeline.

---

### Favorite people
Allow users to pin important people to the top of My Circle regardless of Circle Tier.

---

### Recent activity
Display the latest interaction or memory date for each person in My Circle.

Example:
Sarah
Last memory: 2 days ago

---

### Global search improvements
Future search should support:
- People
- Memories
- Suggestions

instead of a single combined list.

---

### Create Person during AI Capture
**Status**
**Implemented in Sprint 2B Phase 2B.3** — see confirmation Create Person dialog. Kept here for the remaining future enhancement.

**Problem**
When AI extracts a `personMentioned` that does not match anyone in My Circle, the user must cancel capture, add the person via Sprint 1A flows, and capture again.

**Sprint / area**
Sprint 2B / Capture UX (core phase 2B.3) — **shipped** for exact-match create path.

**Shipped**
- Inline Create Person when no exact Circle match (case-insensitive, trimmed).
- Edit Relationship + Circle before create; explicit confirm only.
- Select newly created person and stay on confirmation.

**Future enhancement (not part of Sprint 2B)**
- If multiple similar people exist (e.g. "John" vs "John Smith"), suggest possible matches before offering to create a new person.

---

## Low Priority

### App theme stub
**Problem**
`lib/core/theme/app_theme.dart` is still Sprint 0 scaffolding.

**Proposed solution**
- Define real theme tokens when visual polish is prioritized (often Sprint 6).

---

### Merge duplicate people
Allow users to merge two Person records while preserving all memories.

---

### Person avatars
Support optional profile photos or avatars.

---

### Timeline filters
Allow filtering memories by category (Health, Family, Work, Finance, etc.).

---

### Person statistics
Display simple profile statistics such as:
- Total memories
- Last updated
- Completed follow-ups

------

# Technical Debt

## Person delete cascade
**Priority:** High

**Problem**
Deleting a Person currently soft-deletes only the Person record.

**Future work**
Implement a transactional soft-delete cascade:
- Person → Memories
- Person → FollowUps (when FollowUps are implemented)

This was intentionally deferred from Sprint 1B.

---

## Repository consistency
**Priority:** High

**Problem**
`PersonRepository.getByUuid()` may still return soft-deleted people.

**Future work**
Ensure all repositories hide soft-deleted entities consistently at the repository boundary.

---

## Logout location
**Priority:** Medium

**Problem**
Logout is temporarily located on the My Circle screen for development convenience.

**Future work**
Move Logout into the future Settings screen.

---

## App theme
**Priority:** Medium

**Problem**
`app_theme.dart` is still a scaffold.

**Future work**
Complete the application theme once the visual design is finalized.

---

## FollowUp schema review
**Priority:** Medium

**Problem**
The architecture notes and schema differ regarding `FollowUp.deletedAt`.

**Future work**
Resolve the schema before implementing FollowUps or delete cascades.

---

## Person Profile enhancements
**Priority:** Medium

Deferred from Sprint 1B:

- Memory category filters
- Search within a person's memories
- Upcoming / Recent memories section

### Activity log
Maintain a timeline of actions such as:
- Memory added
- Memory edited
- Memory deleted
- Person updated
