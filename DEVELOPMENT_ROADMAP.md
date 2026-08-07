# Tend — Development Roadmap (Cursor / Flutter build order)

**Supersedes:** `03-development-roadmap.md`. Aligned to `ARCHITECTURE.md` (ADR-0001).
**How to use this with Cursor:** work through this sprint by sprint — copy only that sprint's section into a Cursor prompt (e.g. *"Implement Sprint 1 exactly as scoped below, using SCHEMA.md and FEATURES.md as the source of truth"*). Each sprint is independently shippable and testable before moving to the next.

**Stack (per ADR-0001):** Flutter, `isar_community` (local source of truth), `flutter_riverpod` + `riverpod_generator`, `go_router`, `flutter_gemma` (behind the `ai/providers/` abstraction), `supabase_flutter` (auth + optional backup), `workmanager` (background sync + Suggestion Engine). Repo organized feature-first per `ARCHITECTURE.md` Section 2.

**What changed from the original roadmap:** the core sprint order is preserved almost exactly, per your instruction — but **sync is now its own dedicated sprint (Sprint 5)** rather than a "harden the offline queue" line item folded into polish. Local-first sync with conflict resolution is genuinely new engineering scope the original cloud-primary design never had, and it deserves its own scoped, testable unit rather than being squeezed in at the end. **Sprint 1 is also split into Sprint 1A (Person CRUD) and Sprint 1B (manual Memory CRUD + Person Profile)** so each is independently shippable while preserving the original "validate schema before AI" intent. Everything else — dependency logic, what ships when — is unchanged in spirit.

---

## Sprint 0 — Project Setup
**Goal:** an empty but real app — auth works, local schema is live, navigation shell exists.
- Flutter project scaffold; add `isar_community`, `flutter_riverpod`, `riverpod_generator`, `go_router`, `supabase_flutter`.
- Define the Isar collections and enums exactly as specified in `SCHEMA.md`; run codegen; open the local Isar instance behind a Riverpod provider.
- Create the Supabase project for **auth only** at this stage — the backup mirror schema is only needed once Sprint 5 begins.
- Auth screens: sign up / log in (email or phone OTP via Supabase Auth).
- App shell: bottom nav or drawer with My Circle / Today / Search stubs, using `go_router`.
- **Done when:** a user can sign up, log in, and see an empty "My Circle" screen backed by a real (empty) local Isar collection — no network dependency beyond the auth call itself.

## Sprint 1A — Person CRUD (no memories, no AI)
**Goal:** ship a complete people layer against Isar before adding memory complexity.
- `PersonRepository` + Riverpod providers/streams (Isar watchers); nothing above the repository touches Isar directly (`ARCHITECTURE.md`).
- My Circle list grouped by `circleTier`, including a correct empty state when no people exist.
- Add Person / Edit Person screens: name, circle tier, relationship type; client-generated `uuid`; `syncStatus = pending`; `createdAt` / `updatedAt` set correctly.
- Delete Person via `deletedAt` tombstone (not a hard delete); exclude tombstoned people from My Circle.
- Form validation (required name, valid circle tier, etc.).
- **Out of scope for 1A:** Person Profile, any Memory UI/repository, AI, sync.
- **Done when:** a user can add, edit, delete, and list people entirely offline with data persisting in Isar, and My Circle shows a proper empty state when appropriate.

## Sprint 1B — Manual Memory CRUD + Person Profile (no AI)
**Goal:** validate the Memory data model end to end with hand-entered data before wiring capture/AI.
- `MemoryRepository` + Riverpod providers; FK by `personUuid` only (no `IsarLink`).
- Person Profile screen: timeline of that person's memories (newest first), empty state when none.
- Manual Add/Edit/Delete Memory: category, event text, optional date fields per `SCHEMA.md`; no AI extraction; `extractionConfidence` left null for manual entry.
- Person delete cascade: tombstoning a person also tombstones their memories (and related follow-ups if any) — required by `FEATURES.md` acceptance criteria; implement here once memories exist.
- Routing: navigate from My Circle → Person Profile; memory forms reachable from the profile.
- **Out of scope for 1B:** AI providers, capture modal, embeddings, Today's Opportunities logic.
- **Done when:** a user can open a person, manually log/edit/delete memories on a timeline, entirely offline, with persistence correct in Isar. Zero AI — deliberately catching data-model problems while they're cheap to fix.

## Sprint 2 — On-Device Capture + AI Extraction
**Goal:** the actual core loop — capture in under 10 seconds, entirely on-device, user confirms.
- Implement the `ExtractionProvider`, `EmbeddingProvider`, `TranscriptionProvider`, `OCRProvider` abstract interfaces (`ARCHITECTURE.md` Section 6) before writing any concrete implementation — this is what keeps the app decoupled from Gemma specifically.
- **Model management first:** device capability check (`device_info_plus`), tiered behavior, on-demand model download flow with checksum verification, and the `ManualFallbackProvider` for unsupported devices — build this *before* the extraction UI, so every subsequent screen can assume graceful degradation exists rather than bolting it on after.
- Implement `GemmaExtractionProvider` and `GemmaEmbeddingProvider` using `flutter_gemma`'s function-calling mode against the Deliverable 5 JSON schema.
- Implement `PlatformTranscriptionProvider` (native speech-to-text) and `PlatformOCRProvider` (native on-device text recognition) — these do not touch `flutter_gemma` at all.
- Global capture modal: voice (default), text, photo, OS share-sheet entry points.
- Confirmation card: editable fields, respects `needsUserConfirmation` and the confidence thresholds — never auto-saves below threshold.
- **Done when:** a user can go from opening the app to a saved, AI-structured memory in under 10 seconds including the confirmation tap — for both voice and text, entirely offline — and a user on a simulated low-RAM device instead lands cleanly in manual-entry mode with no crash or dead end.

## Sprint 3 — Today's Opportunities (Suggestion Engine v1)
**Goal:** the resurfacing half of the magic loop, computed entirely locally.
- Implement the rule-based scoring logic (unchanged from the original design) as a `workmanager` scheduled background task querying Isar directly — no cloud job, no network dependency.
- Today's Opportunities screen: hard cap of 5, each item shows its "why this surfaced" line, act/dismiss/not-now actions writing to `SuggestionLogEntry`.
- Local push notifications for the daily digest (`flutter_local_notifications`).
- Enforce the hard exclusion rules in code: no suggestion without a grounding memory, no batch/productivity framing, no fabricated emotional language.
- **Done when:** a user reliably receives a short, specific daily digest with the device fully offline, and dismissed/acted items correctly stop reappearing per the suppression logic.

## Sprint 4 — Local Semantic Search
**Goal:** on-demand recall, computed entirely on-device.
- Extend the Sprint 2 extraction flow to generate and store an embedding on every memory at capture time.
- Person-scoped and global natural-language search UI, using the brute-force cosine scan from `SCHEMA.md`.
- Answers must cite the specific memory they're drawn from — never a synthesized answer with no traceable source.
- **Done when:** a plain-language question like "what did Rahul say about buying a house?" returns a correct, sourced answer with the device offline.

## Sprint 5 — Sync Engine *(new — see "what changed" above)*
**Goal:** opt-in backup/multi-device sync, without ever becoming a dependency for core function.
- Stand up the Supabase backup mirror schema from `SCHEMA.md`.
- Build the push path: query Isar for `syncStatus == pending`, upsert to Supabase by `uuid`, mark `synced` on success.
- Build the pull path: query Supabase for records with `updatedAt` newer than `lastSyncedAt`, upsert into Isar by `uuid`.
- Implement last-write-wins conflict resolution by `updatedAt`, and tombstone-based deletes (`deletedAt`) rather than hard deletes at sync time.
- Settings toggle: enable/disable sync, defaulting to **OFF**. Enabling triggers a full initial push of local data.
- **Done when:** a user can enable sync, see their data appear on a second device, disable sync again with all local data fully intact, and force-kill the app mid-sync without corrupting local state.

## Sprint 6 — Data Controls, Encryption, and Polish
**Goal:** MVP feature-complete and trustworthy enough for a closed beta.
- Local encryption for the Isar database file (verify actual support in `isar_community` at implementation time) and `flutter_secure_storage` for auth tokens/keys.
- Data export (full JSON dump) and delete flows (person/memory/account) with correct cascading tombstones, propagating through sync if enabled.
- Empty states, error handling, onboarding polish (including the model-download step from Sprint 2).
- **Done when:** the app matches every P0 acceptance criterion in `FEATURES.md`.

---

## Sprint 7+ (P1 — only after MVP beta validates the core loop)
Pull from the P1 list in `FEATURES.md`: Connection layer, calendar integration, email forwarding capture, shared/family circles (requires revisiting last-write-wins — see gaps below), learned suggestion weighting, and the fine-tuned FunctionGemma provider swap once real capture data exists to fine-tune on.

---

## Dependency notes (why this order, specifically)
- **Sprint 1A before Sprint 1B:** prove Person persistence, list grouping, and tombstone delete before introducing Memory FKs and the profile timeline.
- **Sprint 1B before Sprint 2:** find Memory data-model problems with a boring manual form before wiring up on-device inference on top of it.
- **Sprint 2 before Sprint 3:** the Suggestion Engine has nothing to rank without real captured memories.
- **Sprint 2's model management before its extraction UI:** graceful degradation needs to be a foundation every later screen can assume, not a retrofit.
- **Sprint 3 before Sprint 4:** Today's Opportunities is the retention loop and the core promise; search is valuable but not what makes or breaks the "wow, you remembered" moment.
- **Sprint 5 (sync) before Sprint 6 (polish):** encryption and export/delete need to account for the sync path (propagating tombstones, encrypting the backup mirror consistently) — building them before sync exists risks redoing them once it does.
