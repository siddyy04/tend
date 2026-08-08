# Sprint 3 — Design Document
### Local Semantic Search: Making Captured Memories Recallable

**Status:** Frozen (design). Phase 3.1 implemented — see [`SPRINT3_1.md`](SPRINT3_1.md). Next: Phase 3.2 spike.  
**Author framing:** Written as a product manager and software architect re-evaluating the product from its actual current state, not continuing a roadmap written before Sprint 2 existed.

---

## 0. The decision this document is really about

Every prior version of the roadmap says "Sprint 3 = Today's Opportunities (Suggestion Engine)." I want to name that plainly and then explain why I'm recommending against it, rather than silently swapping it — you should be able to disagree with this call specifically.

**The argument for Suggestion Engine next:** it's the product's original "magic moment" — a resurfaced memory that makes someone say "I can't believe you remembered." It's what the Bible and PRD always treated as the core differentiator.

**The argument against building it now:** that magic moment fundamentally requires *elapsed real-world time* between capture and resurfacing. "Ask Rahul how his interview went" only works if enough time has actually passed since the interview was captured. A product in its first weeks of real usage — especially a beta cohort of ~100 external testers using it for the first time — has almost no memories old enough for that payoff to be felt. We'd be shipping a feature whose entire value proposition is invisible during exactly the window when we most need early users to feel value.

**Search doesn't have that problem.** The moment there are more than a handful of captured memories — which four capture modes and real beta usage will produce quickly — "what did Rahul say about buying a house?" is answerable and demonstrable in the same session someone captured it. It's also lower-risk in a specific way that matters for a first post-capture milestone: a search that returns nothing is just "no results" — mildly disappointing. A resurfaced suggestion that's wrong, stale, or feels naggy is actively negative, and we have zero real usage data yet to calibrate the timing/decay rules the original Suggestion Engine design was always going to need. Building the "smart resurfacing" feature before we have any evidence about what real capture patterns and real relative-date phrasing actually look like is designing in a vacuum.

There's also a straightforward architecture-sequencing argument: Search's foundation (`EmbeddingProvider`) has existed as a scaffolded interface since Sprint 2A and never been implemented; the local, brute-force, no-ANN-needed search approach was already designed in `SCHEMA.md`. Suggestion Engine's foundational question — *when does a Memory generate a FollowUp* — has been explicitly deferred through every sprint so far specifically because it's a real, unresolved product design question, not an implementation detail. Search is the more shovel-ready of the two.

**Recommendation: Sprint 3 is Search. Suggestion Engine becomes Sprint 4**, revisited once there's real usage data (including, usefully, search-query logs) to inform what's actually worth proactively surfacing — search-before-suggest is a better-sequenced bet than the reverse.

If you disagree with this swap, everything downstream in this document changes — worth confirming before reading further.

---

## 1. Product Goals

1. Let a user recall a specific fact about someone using their own words, not a structured filter — "what did Sarah say about the new job" should work, not just "show me Career memories about Sarah."
2. Every answer is traceable to a real, specific captured memory — never a synthesized or inferred answer. This is the same "AI never invents" principle that governs extraction, now applied to retrieval.
3. Works scoped to one person (from Person Profile) and globally (from the app shell), matching the two natural moments someone wants to recall something: mid-conversation-prep for a specific person, or "wait, who told me about X."
4. Fully on-device, fully offline, same as every other AI capability in the product — no exception carved out for search.

## 2. User Value

Two capture flows are now both real: a user can put a memory in fast (four ways), and — with this sprint — get one back out fast, in their own words. The value compounds with usage: a user who's captured 40 memories about a colleague over six months currently has no way to find "the thing about their kid's allergy" except scrolling a timeline. Search turns an increasingly large, increasingly valuable, increasingly hard-to-manually-browse memory corpus back into something usable in the moment it matters — right before a call, not after scrolling.

This also directly answers the "so what did I actually get out of using this app" question a beta tester will ask in week one, which Suggestion Engine structurally cannot answer that early.

## 3. Why This Belongs in Sprint 3 Specifically (not earlier, not later)

- **Not earlier:** search over an empty or near-empty corpus (Sprints 0–2) demonstrates nothing. It needed a real capture pipeline first — which now exists.
- **Not later:** every sprint after this one benefits from search existing. A future Suggestion Engine (Sprint 4) surfacing "why this matters" copy benefits from the same retrieval infrastructure. A future Settings/export sprint benefits from users being able to find what they're exporting. Waiting delays the first moment the captured corpus becomes genuinely useful, not just captured.
- **Matches the project's own technical readiness:** the embedding interface and local brute-force search design already exist on paper; nothing else in the product is this close to shovel-ready.

## 4. Sprint Breakdown Into Phases

Mirroring the granular phase structure that worked well for Sprint 2B (2B.1–2B.8) — small, independently gated phases rather than one large undifferentiated sprint.

**Sequencing note:** this section originally proposed an embedding-spike-first order. On review, that was the wrong call — see the addendum at the end of this document for the full reasoning. The order below is vertical-slice-first: ship a complete, production-quality keyword search experience before any embedding/semantic work begins, so the product gets real search value immediately and the riskiest technical unknown (Phase 3.4's spike) is isolated as an additive enhancement rather than a blocking dependency for shipping search at all.

### Phase 3.1 — Search UI, person-scoped and global, keyword/substring search
Build out the Search tab stub that's existed since Sprint 0, plus the person-scoped search entry point on Person Profile listed in `FEATURES.md` since the beginning and never built. Query matching is deterministic keyword/substring matching over `eventText`, `category`, `personName`, and date fields — using Isar's native indexed/word query support rather than any embedding. Natural-language-shaped input box (so the UI doesn't need to change later when semantic ranking is added), results list showing the matched snippet, category/date, and the person it belongs to, tapping through to that person's timeline. A genuinely good empty-results state — not an afterthought: keyword-only matching means real, legitimate queries will sometimes return nothing, and the empty state needs to gracefully suggest trying different words, not feel like a broken feature.

**Result presentation:** a single flat list, ranked by a default relevance heuristic — never arbitrary/insertion order. A simple, deterministic ranking is required even for keyword matching: exact phrase match ranks above all-terms match, which ranks above partial/substring match; a match in `eventText` ranks above a match found only in `category`/`personName`; recency as the tiebreak. **Not grouped by person.** Global search's distinct value over person-scoped search is precisely the cross-person recall case ("someone told me about X, I don't remember who") — clustering results back into per-person groups works against that, and introduces an under-specified second ranking question (how are groups themselves ordered) with no clear answer yet. Revisit only if Phase 3.1's search-query log shows a real pattern of queries returning multiple hits clustered around a small number of people.

**No explicit sort-mode toggle ("Most Relevant" / "Newest") in this phase.** The default relevance ordering above is mandatory; a user-facing control to switch modes is a separable, deferrable feature — consistent with this phase's broader discipline of shipping the minimal correct slice and letting the query log (not assumption) justify each addition. A person specifically wanting newest-first can already get that from a Person Profile's timeline, which is already reverse-chronological.

**Architecture requirement for this phase specifically:** shape the query path as a pluggable ranking strategy from the start (a `SearchProvider`-style abstraction with one concrete keyword implementation today), even though only one implementation exists yet — this is what makes Phase 3.2's semantic layer additive later instead of a rebuild.

**Also in this phase:** lightweight local search-query logging (mirroring the existing `CaptureAnalytics` debug-hook pattern) — capturing query text, result count, and whether a result was tapped, kept entirely on-device. This is what turns "search behavior teaches us what to build next" from a nice idea into an actual, evidence-backed Phase 3.2 go/no-go decision — and is also the evidence source for revisiting grouping and sort-mode later, if warranted.

### Phase 3.2 — Embedding provider spike and decision
Now that keyword search is real and shipped, resolve the genuinely open technical question before building on it: does `flutter_gemma_litertlm` / Gemma 4 E2B expose an embedding endpoint through the current bridge? If yes, implement `LiteRtEmbeddingProvider` reusing the model already on-device — no second download, no new footprint. If no, evaluate a lightweight dedicated compact embedding model as a second on-device artifact, explicitly weighing download-size/RAM cost against search quality — and write the outcome down as an ADR, the same way ADR-012 came out of a spike rather than a guess. **Because Phase 3.1 already shipped a complete search feature, this spike no longer blocks anything if it goes badly** — worst case, semantic search is deferred or descoped and the product still has real, working search.

### Phase 3.3 — Semantic search and backfill
Generate and store an embedding on every new Memory at save time going forward (both manual entry and AI capture paths), as a background, non-blocking step — never inside the synchronous save path, to protect the capture-latency numbers Sprint 2B.8 worked to establish. Implement the local brute-force cosine scan per the approach already designed in `SCHEMA.md`. Run a one-time, batched, resumable backfill for every Memory that predates this phase.

### Phase 3.4 — Hybrid ranking
Combine keyword and semantic signals so an exact match is never outranked by a semantically-adjacent-but-wrong result, while paraphrase queries that keyword search alone would miss now succeed. Use Phase 3.1's search-query log to validate this against real query patterns rather than synthetic test cases alone — if that data shows keyword alone was already satisfying most real queries, that's a legitimate signal to keep this phase lightweight rather than over-invest in ranking sophistication.

### Phase 3.5 — Stabilization
A short RC-style pass mirroring Sprint 2B.8's discipline: latency measurement for both keyword and semantic paths, backfill verification on the real existing corpus, offline verification, capture-latency regression check, and a documentation/changelog close-out.

## 5. Architecture Considerations

- **New/changed components:** Phase 3.1 introduces a `SearchProvider`-style pluggable ranking abstraction with one concrete keyword/substring implementation; Phase 3.2/3.3 add `LiteRtEmbeddingProvider` (or a second dedicated embedding model, pending the spike outcome) behind the existing `EmbeddingProvider` interface as a second, additive signal — no change to that interface's contract, consistent with how the Gemma→LiteRT and Qwen→Gemma-4 swaps never touched Capture/Confirmation/repositories.
- **Do not block capture latency on embedding generation**, once Phase 3.2/3.3 introduce it. Generate it as a fire-and-forget background task immediately after `MemoryRepository.create()`/`update()` succeeds, updating the record once ready — the memory is fully usable (visible in timeline, editable, and keyword-searchable from Phase 3.1) before its embedding exists; semantic search simply won't surface it until that background step completes.
- **Repository boundary preserved:** search logic (keyword matching, later semantic scoring, later hybrid ranking) lives in a Riverpod provider/controller layer consuming a flat list from `MemoryRepository`, not inside the repository itself — same discipline as every prior sprint (ADR-003).
- **Embedding dimension must be pinned once the concrete provider is chosen** (`SCHEMA.md` deliberately left this open) — and the "what happens if the provider ever changes and old embeddings become incomparable" gap flagged back in `SCHEMA.md`'s original text becomes real for the first time in Phase 3.2/3.3, not just theoretical. Worth an explicit, documented policy (e.g. "changing embedding providers requires a full re-embed pass") rather than leaving it implicit.
- **Backfill must be a background, batched, resumable job**, not a startup-blocking pass — by the time Phase 3.3 runs, the existing corpus (across all prior sprints and any beta usage, now including real search usage from Phase 3.1) could be nontrivial in size, and a slow, unbatched backfill blocking app launch would be a bad first impression for exactly the beta cohort this needs to work well for.
- **No Supabase/sync involvement.** Consistent with every prior sprint — search is entirely local, and the backup-mirror `embedding` column in `SCHEMA.md`'s Postgres section stays dormant until Sprint 5, same as before.

## 6. Acceptance Criteria

**Satisfied by Phase 3.1 alone (search is real and shippable before any embedding work exists):**
1. A keyword/substring query against a person's timeline returns results drawn only from that person's actual memories, each traceable to a specific Memory record.
2. A keyword/substring query from the global Search tab returns results across the full Circle, each correctly attributed to the right person.
3. Every returned result can be traced back to source text — no synthesized or inferred answer that isn't grounded in an actual captured memory.
4. Newly captured memories (via any of the four capture modes) are keyword-searchable immediately on save — no background step required for this phase.
5. Results render as a single flat list ordered by a deterministic default relevance heuristic (never arbitrary/insertion order) — not grouped by person, and with no user-facing sort-mode toggle in this phase.
6. A query with no matching results renders a genuinely helpful empty state (not just graceful — actively suggesting different phrasing), since keyword-only matching will produce real, legitimate empty results.
7. Search works with the device fully offline — no network call anywhere in the query path.
8. Local search-query logging captures query text, result count, and tap-through, entirely on-device, feeding the Phase 3.4 hybrid-ranking decision (and any future grouping/sort-mode reconsideration).

**Added by Phase 3.2/3.3 (semantic layer, additive):**
9. A paraphrase query (no literal keyword overlap with the target memory's text) returns the correct result via semantic matching.
10. The full existing memory corpus is fully searchable semantically after the one-time backfill completes.
11. Capture latency (the Sprint 2B.8-protected metric) shows no regression from the new background embedding step.

**Added by Phase 3.4 (hybrid):**
12. An exact keyword/name/date match in a memory is never outranked into invisibility by a semantically-adjacent-but-wrong result.

**Measured in Phase 3.5:**
13. Search latency feels immediate for both keyword and semantic paths at realistic corpus sizes — measured and documented, not assumed.

## 7. Risks

- **Embedding provider availability is still a genuine open question — but no longer a blocking one.** If Gemma 4 E2B doesn't cleanly expose embeddings through the current LiteRT-LM bridge, Phase 3.2 could reveal a real architecture decision (a second on-device model) with real download-size and RAM consequences. Because Phase 3.1 ships a complete, working keyword search first, this risk is now isolated — a bad outcome here delays or descopes the semantic layer without leaving the product without search.
- **Search relevance quality on short, structured memory text is genuinely unproven for the semantic layer.** Semantic embeddings were designed and validated for prose; a memory's `eventText` is short and structured. A "Search Relevance Benchmark" (mirroring `EXTRACTION_COMPLETENESS_BENCHMARK.md`'s format) should be built using Phase 3.1's real query log, not synthetic cases alone.
- **Organizational risk: shipping "good enough" keyword search in Phase 3.1 could quietly remove urgency to build Phases 3.2–3.4 at all.** Mitigated by treating the Phase 3.1 query log as the actual decision input — if it shows semantic search wouldn't meaningfully help, deprioritizing it is a legitimate, evidence-based call, not scope creep left unfinished. If it shows real paraphrase-query failure, that's the case for continued investment, made with real data instead of assumption.
- **Backfill cost is unknown until Phase 3.2/3.3 measure it** — for a beta cohort that's been dogfooding through several sprints, the existing corpus size and backfill duration aren't yet known quantities.
- **Battery/performance cost of background embedding generation** on capture-heavy sessions, once Phase 3.2/3.3 introduce it — same category of risk 2B.8 spent real effort measuring for extraction; deserves the same rigor here, not an assumption that "it's just an embedding, it's cheap."

## 8. Explicitly Out of Scope

- Suggestion Engine / `FollowUp` / Today's Opportunities in any form — resequenced to Sprint 4, not abandoned, per Section 0's reasoning.
- Sync, backup, or any Supabase app-data table — unchanged from every prior sprint's boundary.
- ANN indexing / vector database infrastructure — brute-force is the deliberate design choice at MVP scale; revisit only with evidence it's actually needed.
- Ranking personalization or learned relevance (e.g. weighting by what a user clicks on) — a plain, deterministic ranking for v1.
- Searching within photo/audio content directly (as opposed to their already-transcribed/OCR'd text) — out of scope, same as it's always been for those capture modes.
- Settings, data export, account deletion — real and still pending, but a separate thread, not part of this sprint's scope.
- Cross-person "Connection" search (P1 per `FEATURES.md`) — unrelated to this sprint's single-memory-recall goal.

## 9. Manual QA Plan

- **Phase 3.1 can be fully QA'd and shipped independent of anything semantic** — keyword/substring matching, person-scoped and global, empty states, offline behavior, and search-query logging all verifiable on their own before Phase 3.2 begins.
- **Relevance benchmark suite** (new, mirroring `EXTRACTION_COMPLETENESS_BENCHMARK.md`'s format), built once Phase 3.1's real query log exists — covering paraphrase recall (a case keyword search is expected to miss and semantic should catch), exact factual recall (names, dates — where keyword should already succeed), and negative cases.
- **Backfill verification (Phase 3.3):** run against a realistic pre-existing corpus; spot-check that memories captured across every prior sprint (manual 1B entries, AI captures via all four modes) are all semantically searchable afterward, and remain keyword-searchable throughout (no regression from Phase 3.1).
- **Latency measurement:** query-to-results time for keyword search (Phase 3.1) and semantic/hybrid search (Phase 3.3/3.4), both person-scoped and global, at a few realistic corpus sizes — documented with real numbers, not assumed.
- **Capture-latency regression check**, once Phase 3.2/3.3 introduce background embedding generation — re-run Sprint 2B.8's existing warm/cold capture timing tests to confirm no quiet regression.
- **Offline verification:** airplane mode, full search flow, person-scoped and global, at every phase.
- **Empty-state and edge cases:** zero-result query, empty Circle, a person with zero memories, a very short/ambiguous query — especially important for Phase 3.1, where legitimate empty results will be more common than in the eventual hybrid system.
- **Cross-person isolation:** confirm a person-scoped search never leaks another person's memories into results.
- **Search-query log verification:** confirm logging is local-only, captures what Phase 3.4's hybrid-ranking decision actually needs, and never leaves the device.

## 10. Additional Considerations for a High-Quality Spec

- **Success metric for this sprint:** not "search works" in the abstract, but "a user can find a specific real memory they captured, using their own words, faster than they could by scrolling a timeline" — worth actually testing that comparison during Phase 3.5 rather than assuming it's true.
- **This sprint produces real signal for Sprint 4's design question.** What people search for is a strong, cheap proxy for what they'd want proactively surfaced — worth deliberately logging (locally, privately, same as `CaptureAnalytics`'s existing debug-hook pattern) what gets searched for, so Sprint 4's Suggestion Engine design isn't starting from the same hypothesis-only position the original Bible design was in.
- **Naming continuity:** the very first product vision document named this capability "AI Search" on the Person Profile screen with example queries like "What promise did I make to Aman?" — worth keeping that framing in UI copy rather than "search," which undersells what's actually being built (a grounded question-answering feature, not a keyword filter).
- **This document is a design-level proposal, not an implementation specification.** Once reviewed and agreed, the next step is breaking Section 4's phases into the same Cursor-facing implementation-spec format used for `SPRINT0.md`/`SPRINT1A.md`/`SPRINT2A.md` — files to create, exact acceptance criteria per phase, pitfalls, Definition of Done. Deliberately not written that way here, per your instruction.

---

## Addendum — Sequencing Reversal (keyword-first, semantic-second)

The first draft of this document proposed an embedding-spike-first phase order. On review, that was reconsidered and reversed: Phase 3.1 now ships a complete, production-quality keyword/substring search experience — UI, person-scoped and global search, empty states, local search-query logging — with no embedding or semantic work at all. The embedding-provider spike, semantic search, and hybrid ranking move to Phases 3.2–3.4, additive on top of a search feature that already works and has already shipped.

**Why this is better, across the axes that matter:**
- **UX:** ships real value immediately; for this product's short, structured, named-entity-heavy memory text, keyword matching likely covers more real recall attempts than initially assumed.
- **Engineering complexity:** Phase 3.1 requires no model spike, no embedding-dimension decision, no background-generation engineering, no backfill — meaningfully simpler first release.
- **Risk:** isolates the one large open unknown (embedding provider availability) into a later, non-blocking phase — a bad outcome there no longer means the product has no search.
- **Learning value:** turns "should we build semantic search" from an assumption into a question answerable from real query-log data, collected specifically because Phase 3.1 includes local search-analytics logging.
- **Long-term architecture:** neutral to positive, provided Phase 3.1 is built with a pluggable ranking-strategy abstraction from the start (a stated architecture requirement in Phase 3.1, not an afterthought) — semantic and hybrid ranking then compose onto the same UI rather than requiring a rebuild.

This also isn't a new pattern for this project — it's ADR-009 ("Manual-first before AI") applied to Search, the same philosophy that already shaped Person/Memory CRUD (Sprints 1A/1B) shipping before AI capture (Sprint 2A+) was layered on top.
