# Tend — MVP Feature List (Cursor / Flutter build reference)

**Supersedes:** `01-mvp-feature-list.md`. Aligned to `ARCHITECTURE.md` (ADR-0001).
**How to use this with Cursor:** paste this whole file into the repo as `FEATURES.md` and reference it at the start of a session: *"Only build P0 items unless I explicitly ask for P1/P2. Never build anything under Explicitly Out of Scope."*

---

## P0 — Build Now (MVP)

### Screens
| Screen | Notes |
|---|---|
| Onboarding & Auth | Supabase Auth (email/phone OTP). Includes device capability check + optional AI model download (see Model Management, below) |
| My Circle (home) | People list grouped by `circleTier`, reading live from Isar |
| Add / Edit Person | Name, circle tier, free-text relationship type |
| Person Profile | Timeline, upcoming/recent, category filter, search entry point |
| Capture (global modal) | Voice (default), text, photo, OS share-sheet |
| Capture Confirmation Card | Editable structured fields before save — never auto-save below confidence threshold |
| Today's Opportunities | Max 5 items/day, each with a one-line "why this surfaced" |
| Search | Natural-language, person-scoped and global — local embeddings, no network required |
| Settings | Data export, delete person/memory/account, backup/sync toggle (default OFF) |

### Capabilities
| Capability | P0 scope | Deferred to |
|---|---|---|
| Person CRUD | Full, against Isar (source of truth) | — |
| Memory capture: voice + text | Full, with **on-device** AI extraction via the `ExtractionProvider` abstraction (Gemma 3n E2B initial implementation) | — |
| Memory capture: photo | Platform-native on-device OCR (ML Kit / Vision) on screenshots — **not routed through the LLM** | Vision captioning of scene photos via the LLM → P1 |
| Voice transcription | Platform-native speech-to-text — **not routed through the LLM** | — |
| Confidence-gated confirmation | Full — low `extractionConfidence` or `personMatchConfidence` routes to manual confirm | — |
| Suggestion Engine | Rule-based scoring (unchanged logic), run as a **local scheduled background task** against Isar — no cloud job | Per-user learned weighting → P1 |
| Natural language search | Local embeddings (via `EmbeddingProvider`) + brute-force cosine scan in Dart over Isar records | ANN indexing → only if real usage data shows it's needed |
| Offline operation | **Default mode, not a fallback.** Every P0 feature works fully offline; sync is an optional add-on, not a dependency | — |
| Backup / sync | Opt-in, default OFF. Supabase mirror, last-write-wins conflict resolution | Real-time multi-device sync, shared circles → P1 |
| Model management | On-demand model download (not bundled), device capability check, graceful manual-mode fallback for unsupported devices | Fine-tuned specialist model swap-in → P1 |

## P1 — Build After MVP Validates
- Connection layer (cross-person insight suggestions, e.g. "three friends moved to Bangalore")
- Calendar integration (read-only, opt-in)
- Email forwarding capture
- Shared/family circles (requires moving off last-write-wins conflict resolution — see gaps below)
- Per-user learned suggestion weighting
- Vision captioning for scene photos (not just screenshot OCR)
- Fine-tuned FunctionGemma (270M) as a swapped-in `ExtractionProvider`, once real capture data exists to fine-tune on — see `ARCHITECTURE.md` Section 7

## P2 — Future Phases
- Relationship Pulse (only once trust + data volume justify it)
- Team/professional tier (recruiters, sales orgs)
- Multi-modal capture (video, sentiment cues used only for internal prioritization, never shown to the user)
- Cloud-model fallback option (opt-in, for users who want higher extraction accuracy at the cost of privacy/cost trade-offs) — the provider abstraction already supports this without a rearchitecture

## Explicitly Out of Scope — do not build without a deliberate re-scoping conversation
Social feed · Messaging · Calling · AI companion/therapy · Journaling · Relationship score · Habit tracking · Calendar replacement · Full CRM functionality · Gamification · Social sharing

---

## P0 Acceptance Criteria (quick reference)

| Feature | Done when |
|---|---|
| Capture (voice/text) | User can go from opening the app to a saved memory in under 10 seconds, including the confirmation tap — entirely offline, no network call in the critical path |
| Confirmation card | Every field is editable inline; nothing saves silently below the confidence threshold |
| Today's Opportunities | Never shows more than 5; never shows a suggestion with no grounding memory; computed entirely from local Isar data |
| Search | A natural-language query returns an answer traceable to a specific memory, computed entirely on-device |
| Model download | A user on an unsupported/low-RAM device is never blocked from using the app — they land in manual mode automatically, not an error state |
| Backup/sync (if enabled) | Enabling sync never blocks or slows down any core action; disabling it again leaves all local data fully intact |
| Data export/delete | Deleting a person cascades to all their memories, follow-ups, and suggestion history locally; if synced, the tombstone propagates correctly — no orphaned rows on either side |

## Suggested build order within P0
1. Auth + My Circle + Person CRUD against Isar (Sprint 1A — validates Person schema and navigation)
2. Manual memory entry + Person Profile timeline (Sprint 1B — validates the Memory data model end to end)
3. On-device capture: platform ASR/OCR + Gemma 3n extraction (via provider abstraction) + confirmation card + model download/device-tiering flow
4. Today's Opportunities (local rule-based engine)
5. Local semantic search
6. Sync engine (push/pull/conflict resolution/tombstones) — new, dedicated step per the ADR, not a late-stage polish item
7. Data export/delete, encryption, empty states, onboarding polish

*(Full sprint-by-sprint detail is in `DEVELOPMENT_ROADMAP.md`.)*
