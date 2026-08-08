# SPRINT 3.1 IMPLEMENTATION SPECIFICATION
### Target: AI coding agent (Cursor). Read fully before writing any code.

> **Parent design doc:** [`SPRINT3.md`](SPRINT3.md) is frozen and is the architecture source of truth for Sprint 3.  
> **This file** is the authoritative **implementation specification for Phase 3.1 only**.  
> Do **not** implement Phase 3.2+ (embeddings, semantic search, hybrid ranking, Suggestion Engine) in this phase.

You are implementing **Sprint 3 Phase 3.1 only** of the Tend Flutter app. Reference documents already in this repository: `SPRINT3.md`, `ARCHITECTURE.md`, `ADR.md` (especially ADR-003 repository boundary, ADR-008 pure domain rules, ADR-009 manual-first), `FEATURES.md`, `SCHEMA.md`, `BACKLOG.md`, `CURSOR_HANDOFF.md`, `SPRINT0.md`–`SPRINT2B8.md` (prior sprints, already implemented), and `RELEASE_READINESS_REPORT.md` (Capture RC Go).

If anything in this file appears to conflict with `SPRINT3.md`, **`SPRINT3.md` wins on product/architecture intent** — stop and ask rather than expanding scope. If this file is more specific on file layout, ranking rules, or DoD, treat **this file as binding for Phase 3.1 implementation**.

Phase 3.1 must be a **complete, independently reviewable, independently testable, and independently shippable vertical slice** before Phase 3.2 begins.

---

## 0. Cross-Document Consistency Notes (read before building)

1. **`FEATURES.md` and `ARCHITECTURE.md` describe Search as “local embeddings + cosine scan.”** Phase 3.1 deliberately ships **keyword/substring search only**, per `SPRINT3.md` Section 4 / Addendum (keyword-first). Semantic search is Phase 3.2–3.4. Do not implement embeddings, cosine, or hybrid ranking here. Document this as an intentional sequencing choice in CHANGELOG/DEVLOG — not a permanent product retreat.
2. **`DEVELOPMENT_ROADMAP.md` may still list Suggestion Engine as Sprint 3.** `SPRINT3.md` Section 0 supersedes that: Sprint 3 = Search; Suggestion Engine → Sprint 4. Do not build FollowUps / Today’s Opportunities here.
3. **`SCHEMA.md`’s semantic-search snippet and Postgres `embedding` column** stay untouched this phase. `Memory.embedding` remains nullable and unused for search.
4. **Existing stub:** `lib/features/search/search_screen.dart` is a “Coming soon” placeholder wired to the shell Search tab since Sprint 0. Replace it; do not leave a parallel dead screen.
5. **`MemoryRepository` today only exposes `watchAllForPerson`.** Global search requires an active-memories list API (Section 5). Keep Isar access inside the repository (ADR-003).
6. **Foundation Cleanup already resolved** relative-date `dateValue` resolution and `PersonRepository.getByUuid` soft-delete filtering. Search must exclude soft-deleted Memories and Persons.
7. **Capture latency (2B.8 Go metric) must not regress.** Phase 3.1 does not add any work to the capture save path. Search indexing for keyword matching is immediate on existing fields — no background job.

---

## 1. Objective

Deliver production-quality **local keyword/substring Search** so a user can recall a specific captured memory using their own words — scoped to one person (from Person Profile) or across the Circle (from the Search tab) — fully offline, with deterministic relevance ranking, helpful empty states, a pluggable ranking abstraction for later semantic layers, and on-device search-query logging.

**Success metric (product):** a user can find a real memory they captured, using their own words, faster than scrolling a timeline — without any network call and without inventing answers.

---

## 2. Scope

### 2.1 Features included (Phase 3.1 only)

| Feature | Notes |
|---|---|
| Global Search screen | Replace Search tab stub; natural-language-shaped query field |
| Person-scoped Search | Entry from Person Profile; results restricted to that `personUuid` |
| Keyword / substring matching | Over `eventText`, category label/name, person name, and date-related text fields |
| Deterministic relevance ranking | Exact phrase > all-terms > partial; `eventText` beats metadata-only; recency tiebreak |
| Flat results list | Never grouped by person; no sort-mode toggle |
| Result rows | Snippet, category, date, person attribution (global); tap → Person Profile |
| Helpful empty states | Zero results, empty Circle, person with zero memories, blank query idle |
| Pluggable `SearchProvider` | One concrete keyword implementation; interface shaped for later semantic/hybrid |
| Local search-query logging | Query text, result count, tap-through — on-device, CaptureAnalytics-style |
| Offline-first | Query path never calls network; works in airplane mode |

### 2.2 Features explicitly excluded (do not build)

- Embeddings / `EmbeddingProvider` concrete implementation / writing `Memory.embedding`
- Semantic / paraphrase search / cosine similarity / ANN / vector indexes
- Hybrid ranking (keyword + semantic)
- Suggestion Engine, FollowUps, Today’s Opportunities, notifications
- Sort-mode toggle (“Most Relevant” / “Newest”)
- Results grouped by person
- Ranking personalization / learned relevance from clicks
- Searching raw photo/audio bytes (only already-captured text fields)
- Sync / Supabase / remote search
- Cross-person Connection search (FEATURES P1)
- Settings / export / account deletion
- Changing LiteRT extraction protocol or capture pipeline
- Any Phase 3.2–3.5 work “while we’re here”

If an implementation detail seems to require any excluded item to feel complete, **it doesn’t** — stop and flag it.

---

## 3. Architecture Overview

```
UI (SearchScreen / PersonSearchScreen)
  → Riverpod SearchController (query debounce, scope, analytics hooks)
    → SearchProvider.search(SearchQuery)     // pluggable ranking strategy
         → KeywordSearchProvider (Phase 3.1 concrete)
              → domain/rules/search_ranking_rules.dart  // pure match + score
              → MemoryRepository (active memories, soft-delete filtered)
              → PersonRepository / people snapshot (names for matching + attribution)
    → SearchAnalytics (local debug/no-op sink; on-device only)
```

**Binding constraints:**

- **ADR-003:** Isar is touched only through repositories. Matching/ranking live in provider + pure domain rules — not inside `IsarMemoryRepository` as a second business brain.
- **ADR-008:** Ranking / tokenization / field-match classification are pure functions (unit-testable with no Flutter/Isar).
- **ADR-009 applied to Search:** keyword (manual-analog) ships before AI/semantic layers — same pattern as CRUD before AI capture.
- **No model / LiteRT involvement** in the Phase 3.1 query path.
- **Pluggable from day one:** UI and controller depend on `SearchProvider`, never on `KeywordSearchProvider` by type (except DI wiring).

### 3.1 Why not put keyword filters only in Isar

Isar can help with coarse filtering, but Phase 3.1 ranking needs multi-field scoring, phrase vs term classification, and person-name joins. Spec approach:

1. Repository returns **active (non-deleted) Memory rows** (optionally already scoped by `personUuid`).
2. `KeywordSearchProvider` joins person names in memory, scores, sorts, returns `List<SearchHit>`.
3. Optional later optimization (out of 3.1 DoD unless needed for latency): Isar `contains` prefilter — only if measured latency fails targets on a realistic corpus.

At MVP / early-beta corpus sizes, an in-Dart scan of active memories is the intentional default (aligned with `SCHEMA.md` / `ARCHITECTURE.md` “brute-force at MVP scale” philosophy — here applied to keyword candidates, not embeddings).

---

## 4. Files to Create

```
lib/
  ai/
    providers/
      search/
        search_provider.dart              # abstract SearchProvider + SearchQuery + SearchHit + MatchKind
        keyword_search_provider.dart      # concrete KeywordSearchProvider
  core/
    analytics/
      search_analytics.dart               # SearchAnalytics + NoOpSearchAnalytics + provider
  domain/
    rules/
      search_ranking_rules.dart           # tokenize, field haystacks, score, sort (pure)
  features/
    search/
      search_providers.dart               # Riverpod: activeSearchProvider, controllers
      search_controller.dart              # query state, debounce, run search, log events
      search_screen.dart                  # REPLACE stub — global Search tab
      person_search_screen.dart           # person-scoped Search
      widgets/
        search_query_field.dart           # NL-shaped input + clear
        search_results_list.dart          # flat list
        search_result_tile.dart           # snippet + meta + person
        search_empty_state.dart           # idle / no-results / no-corpus variants

test/
  domain/rules/search_ranking_rules_test.dart
  ai/providers/search/keyword_search_provider_test.dart   # with fake repos or in-memory fixtures
```

Optional (only if needed for clarity; prefer not inventing unused scaffolding):

```
lib/features/search/search_models.dart    # if SearchHit should live outside ai/providers
```

Prefer keeping `SearchQuery` / `SearchHit` / `MatchKind` next to `SearchProvider` (same pattern as `ExtractionResult` living with `ExtractionProvider`).

---

## 5. Files to Modify

| File | Change |
|---|---|
| `lib/domain/repositories/memory_repository.dart` | Add `Future<List<Memory>> getActiveMemories()` and `Future<List<Memory>> getActiveMemoriesForPerson(String personUuid)` (or one method with optional `personUuid`). Soft-delete filtered. Do **not** embed ranking here. |
| `lib/features/search/search_screen.dart` | Replace “Coming soon” with real Global Search UI |
| `lib/features/person_profile/person_profile_screen.dart` | AppBar action: Search → person-scoped search route |
| `lib/app/app_routes.dart` | Add person-scoped search route helper, e.g. `personSearch(String personUuid)` |
| `lib/app/router.dart` | Register person-scoped search route; keep shell Search tab on existing `AppRoutes.search` |
| `lib/features/person_profile/person_profile_providers.dart` / circle providers | Only if needed to expose people map for attribution — prefer reading existing `allPeopleProvider` / person stream |
| `CHANGELOG.md` | Phase 3.1 entry |
| `DEVLOG.md` | Phase 3.1 notes + latency spot-check |
| `CURSOR_HANDOFF.md` | Phase 3.1 done → next Phase 3.2 (when this phase ships) |
| `BACKLOG.md` | File any deferred polish discovered (sort toggle, grouping, highlight-on-profile) |

**Do not modify** for Phase 3.1:

- Capture / confirmation / LiteRT providers
- `EmbeddingProvider` interface contract
- FollowUp / SuggestionLog collections
- Supabase client / sync

---

## 6. Data Flow

### 6.1 Global search

```
User opens Search tab
  → idle empty state (prompt examples; no query yet)
  → types query (debounced ~250–400 ms)
  → SearchController builds SearchQuery(scope: global, text: trimmed)
  → SearchProvider.search(query)
       → MemoryRepository.getActiveMemories()
       → resolve Person names for active people (exclude deleted)
       → keyword match + rank → List<SearchHit>
  → SearchAnalytics.searchPerformed(query, resultCount)
  → UI renders flat ranked list
  → user taps hit
       → SearchAnalytics.searchResultTapped(...)
       → navigate to Person Profile (personUuid)
```

### 6.2 Person-scoped search

```
User on Person Profile → taps Search
  → PersonSearchScreen(personUuid) (title includes person name)
  → same pipeline with SearchQuery(scope: person, personUuid: ...)
  → MemoryRepository.getActiveMemoriesForPerson(personUuid)
  → never include another person’s memories (isolation AC)
  → tap → Person Profile (same person; already on their corpus)
```

### 6.3 Freshness

Newly saved memories (any of four capture modes, or manual form) must appear in keyword search **immediately** on the next query — they already have `eventText` / category / dates on the Isar row. No embedding wait. Prefer re-querying repository on each debounced search (simple, correct) rather than a long-lived cached corpus that can go stale after capture.

---

## 7. State Management Approach

- **Riverpod, manual-style** (match Capture / Circle / Profile — not codegen-required).
- `searchControllerProvider` — autoDispose; holds current query string, last `AsyncValue<List<SearchHit>>`, scope.
- Person-scoped: `personSearchControllerProvider` family keyed by `personUuid`, **or** one controller parameterized by `SearchScope` args — pick one pattern and stay consistent with `memoryFormControllerProvider` / `captureConfirmationControllerProvider` families.
- `activeSearchProvider` → `Provider<SearchProvider>` returning `KeywordSearchProvider` (wired with repos).
- `searchAnalyticsProvider` → `NoOpSearchAnalytics` (debug assert prints), mirroring `captureAnalyticsProvider`.
- Debounce in the controller (Timer) or via a small helper — do not fire a full scan on every keystroke without debounce.
- Cancel / ignore stale responses if a newer query supersedes an in-flight search (sequence number or request id).

---

## 8. UI / UX Flow

### 8.1 Copy & framing

Per `SPRINT3.md` Section 10: prefer grounded “ask about a memory” framing over dry “filter.”

- Global AppBar title: **Search** (shell tab label stays Search).
- Query field hint examples (rotate or show under idle state), e.g.:
  - “What did Mom say about physiotherapy?”
  - “Who mentioned Bangalore?”
  - “Promises about a gift”
- Person-scoped AppBar: **Search · {Name}** (or subtitle with name).
- Avoid implying the model is answering live (“AI is thinking…”) — Phase 3.1 is local keyword retrieval, not generative QA. Results must always look like **memory cards**, not chatbot answers.

### 8.2 Result tile

Each `SearchHit` row shows:

1. **Primary:** snippet from `eventText` (prefer a window around the first match; fallback to truncated `eventText`).
2. **Secondary:** category label · date label (reuse profile timeline date formatting patterns).
3. **Attribution (global only):** person display name.
4. Optional: subtle match cue is fine; **no** confidence chips, **no** “semantic score,” **no** embedding badges.

### 8.3 Empty / edge states (required, not afterthoughts)

| Situation | UX |
|---|---|
| Blank / whitespace-only query | Idle coaching state with example prompts — **do not** run search or show “No results” |
| Circle has zero people / zero memories (global) | Explain that Search needs captured memories; CTA toward Capture / Circle |
| Person has zero memories (scoped) | Explain; CTA to add a memory for this person |
| Query with zero matches | Helpful copy: try different words, a name, a place, or a shorter phrase; examples of simpler queries. Must not feel like a crash or “Coming soon” |
| Soft-deleted only matches | Treated as non-existent (filtered at repo) |

### 8.4 Navigation

- Tap result → `context.push` / `go` to existing Person Profile route for `hit.personUuid`.
- **Out of Phase 3.1 DoD (optional stretch, file in backlog if skipped):** deep-link / scroll-to specific `memoryUuid` on the timeline. Default is profile open is enough for ship.

### 8.5 Accessibility

- Query field: clear `Semantics` / labels (“Search memories”).
- Result tiles: button semantics including person + snippet summary.
- Empty states: readable headings, not icon-only.
- Loading: announce “Searching” via existing live-region patterns where easy (`Semantics(liveRegion: true)`).
- Large text: list tiles must not clip essential metadata.

---

## 9. Business Rules

### 9.1 Corpus rules

- Only Memories with `deletedAt == null`.
- Only attribute / match person names for People with `deletedAt == null`.
- Person-scoped search: `memory.personUuid == scopePersonUuid` exclusively.
- Do not search soft-deleted people by name into other people’s results.

### 9.2 Searchable field haystack (per memory)

Build a case-insensitive searchable representation from:

| Field | How |
|---|---|
| `eventText` | Primary; full string |
| `category` | Both enum `.name` and `memoryCategoryLabel(category)` |
| Person name | Active `Person.name` for `memory.personUuid` |
| `dateValueRaw` | If non-null |
| `dateValue` | Formatted calendar date string(s) suitable for substring match (reuse timeline date formatting where practical) |
| `quoteEvidence` | **Optional include** — prefer **yes** for recall (“what was the quote”), but ranking must still prefer `eventText` matches (Section 9.4) |

Do **not** search: `uuid`, `sourceRef` paths, embeddings, sync status, raw confidence doubles (except as non-search metadata).

### 9.3 Query normalization

- Trim; collapse internal whitespace.
- Case-insensitive matching.
- Tokenize on whitespace and simple punctuation for term matching.
- Empty after trim → no search (idle state).
- Very short queries (e.g. 1 character): still allowed; may return many hits — rank deterministically; do not special-case block unless UX proves noisy (backlog, don’t invent thresholds without need).

### 9.4 Match classification (`MatchKind`) — deterministic

For each memory that matches at all, classify the **best** kind present:

| Kind | Definition | Rank tier (higher = better) |
|---|---|---|
| `exactPhrase` | Normalized query string appears as a contiguous substring in `eventText` (preferred) or full haystack if you document why | 3 |
| `allTerms` | Every query token appears somewhere in the haystack (not necessarily contiguous) | 2 |
| `partial` | At least one query token / substring hits, but not all terms | 1 |

A memory that fails all of the above is not a hit.

### 9.5 Field boost

Within the same `MatchKind` tier:

1. Match involving **`eventText`** outranks match found **only** in category / person name / date / quote.
2. Implement as a boolean `matchedInEventText` (or an ordinal `fieldTier`) on the scored hit.

### 9.6 Final sort key (stable, documented)

Sort `SearchHit`s by, in order:

1. `MatchKind` tier descending  
2. `matchedInEventText` true before false  
3. Recency descending — prefer `dateValue` if non-null, else `createdAt`  
4. Stable tiebreak: `memory.uuid` ascending (prevents shuffle across identical scores)

**Never** sort by Isar insertion / raw list order alone.

### 9.7 Grounding / “AI never invents”

- Every result is exactly one existing Memory row.
- UI must not synthesize summary answers (“Mom is recovering well because…”).
- Snippet text must come from stored fields (primarily `eventText`).

### 9.8 Search analytics (local only)

Mirror `CaptureAnalytics`:

```dart
abstract class SearchAnalytics {
  void searchPerformed({
    required String query,
    required int resultCount,
    required SearchScope scope, // global | person
    String? personUuid,
  });

  void searchResultTapped({
    required String query,
    required String memoryUuid,
    required String personUuid,
    required int resultIndex,
    required SearchScope scope,
  });
}
```

- Persist **nothing** off-device.
- Phase 3.1 minimum: debug `assert` / `debugPrint` sink (NoOp pattern).
- **Allowed enhancement within 3.1** (recommended if small): append-only local log via SharedPreferences or a tiny Isar collection / JSON file — still device-local — so Phase 3.2/3.4 can read real queries later. If implemented, document schema in this phase’s DEVLOG and keep PII on-device only. If deferred, NoOp debug hooks still satisfy “logging exists” for wiring, but **prefer a durable local log** because `SPRINT3.md` AC #8 treats the log as decision input for later phases.

**Decision for implementers:** implement a **durable on-device query log** (append-only, capped, e.g. last N=200 entries) unless blocked by unexpected complexity — then fall back to NoOp + backlog item. Cap size so beta devices don’t grow unbounded.

### 9.9 Privacy

- Search log must not sync to Supabase.
- Do not include `sourceRef` filesystem paths in analytics payloads.

---

## 10. `SearchProvider` Contract (pluggable)

```dart
enum SearchScope { global, person }

enum MatchKind { exactPhrase, allTerms, partial }

class SearchQuery {
  final String text;
  final SearchScope scope;
  final String? personUuid; // required when scope == person
}

class SearchHit {
  final String memoryUuid;
  final String personUuid;
  final String personName;
  final String eventText;
  final String snippet;
  final MemoryCategory category;
  final DateTime? dateValue;
  final String? dateValueRaw;
  final DatePrecision datePrecision;
  final MatchKind matchKind;
  final bool matchedInEventText;
}

abstract class SearchProvider {
  Future<List<SearchHit>> search(SearchQuery query);
}
```

Phase 3.1 concrete: `KeywordSearchProvider`.

**Forward compatibility (do not implement now, but do not paint into a corner):**

- Later `HybridSearchProvider` / semantic provider should implement the same `SearchProvider.search` and return the same `SearchHit` shape.
- Do not add semantic-only fields to `SearchHit` in 3.1 “for later.”
- Do not call `EmbeddingProvider` from `KeywordSearchProvider`.

---

## 11. Acceptance Criteria

These map to `SPRINT3.md` §6 items 1–8 and must all pass before Phase 3.1 is Done:

1. **Person-scoped isolation:** A keyword query on person A returns only A’s active memories; never B’s.
2. **Global attribution:** Global Search returns hits across the Circle; each row shows the correct person name; tap opens that person’s profile.
3. **Traceability:** Every result corresponds 1:1 to a stored Memory; UI shows stored `eventText`/snippet — no generated answer.
4. **Immediate keyword availability:** After saving a memory via Typed / Voice / OCR / Share / manual form, a keyword from its `eventText` finds it without waiting for any background job.
5. **Deterministic flat ranking:** Results are a single list ordered by Section 9.6 — not insertion order, not grouped by person, no sort toggle.
6. **Helpful empty state:** A legitimate non-matching query shows coaching empty UI (not blank, not “Coming soon”, not an error crash).
7. **Offline:** Airplane mode — open Search, run global and person-scoped queries, see results or empty states — zero network dependency in the query path.
8. **Local query logging:** Performing a search and tapping a result emits analytics events (and durable local log if implemented per §9.8) containing query text, result count, and tap identity fields — nothing leaves the device.

Additional Phase 3.1 engineering ACs:

9. UI/controller depend on `SearchProvider` abstraction; swapping the concrete provider requires DI-only change.
10. Soft-deleted memories never appear.
11. Soft-deleted people never appear as attribution targets; their memories (if any still active — normally cascaded later) still must not leak via name match to a deleted person record.
12. Unit tests cover ranking pure functions (phrase vs all-terms vs partial; eventText boost; recency tiebreak).
13. Capture / confirmation codepaths unchanged (no embedding write, no search hooks inside save).

---

## 12. Definition of Done

- [ ] All Section 11 acceptance criteria satisfied  
- [ ] Global Search tab is real (stub removed)  
- [ ] Person Profile has Search entry → person-scoped screen  
- [ ] `SearchProvider` + `KeywordSearchProvider` shipped  
- [ ] Ranking rules covered by unit tests  
- [ ] Keyword provider / repository integration covered by tests (see §14)  
- [ ] Manual QA checklist (§14.4) executed on a physical device  
- [ ] No Phase 3.2+ code merged  
- [ ] `CHANGELOG.md` + `DEVLOG.md` updated for Phase 3.1  
- [ ] `CURSOR_HANDOFF.md` updated: Phase 3.1 done; **next = Phase 3.2 planning/spike** (not Suggestion Engine)  
- [ ] Residual polish filed in `BACKLOG.md`, not silently shipped mid-phase  

---

## 13. Risks and Implementation Pitfalls

| Risk / pitfall | Mitigation |
|---|---|
| Accidentally building semantic/hybrid “while here” | Hard exclude list §2.2; PR checklist |
| Putting ranking inside `MemoryRepository` | Violates ADR-003; keep scoring in domain rules + SearchProvider |
| Stale corpus after capture | Re-fetch on each search; don’t cache forever in a provider without invalidation |
| Case/diacritic surprises | Document normalization; start with casefold + trim; advanced Unicode folding is backlog |
| Person-name collisions (“John”) | Global search may return multiple Johns — correct; do not auto-merge. Attribution must show enough context (name as stored) |
| Performance fear → premature Isar index complexity | Measure first; Dart scan is default |
| Empty state feels broken | Design copy before coding list UI; QA specifically |
| Logging PII to crashlytics / network | Local-only sinks; no Supabase |
| Navigating to deleted person | Use active person lookup; if person missing, still show hit defensively or skip — prefer skip with log |
| Debounce races showing wrong results | Monotonic request id |
| Using `PersonRepository.getByUuid` for deleted | Already fixed in Foundation Cleanup; still filter active people lists |
| Deep-link scope creep (scroll to memory) | Optional; not blocking DoD |
| FEATURES.md wording pressure toward embeddings | Sequencing note in CHANGELOG; SPRINT3 wins |

---

## 14. Testing Strategy

### 14.1 Unit tests (required)

`test/domain/rules/search_ranking_rules_test.dart`:

- exact phrase beats all-terms beats partial  
- `eventText` match beats category-only match at same kind  
- recency tiebreak (`dateValue` / `createdAt`)  
- tokenization / case insensitivity  
- empty query → no hits (or not called)  
- soft rules for multi-token queries  

### 14.2 Provider / repository tests

- Person-scoped filter never leaks another `personUuid`  
- Deleted memories excluded  
- Global search attaches correct `personName`  
- Ranking order stable for fixture corpus  

Use temp Isar (existing `test/support/isar_test_init.dart`) or fake repositories — prefer fakes for pure ranking integration if faster; use Isar for repository soft-delete guarantees.

### 14.3 Widget tests (lightweight)

- Idle empty state renders on blank query  
- Results list renders N tiles from injected hits  
- Tap triggers navigation callback / analytics  

Do not require full app+Isar widget tests for DoD if unit+provider tests + manual QA cover behavior.

### 14.4 Manual QA (required before Phase 3.1 ship)

On a real device (AIN065 or equivalent), with a non-trivial corpus (≥1 person, ≥5 memories preferred):

| # | Case | Expect |
|---|---|---|
| M1 | Global search exact word from a known `eventText` | Hit ranked near top; correct person |
| M2 | Person-scoped search | Only that person’s memories |
| M3 | Cross-person isolation | Query that exists only on B never appears in A’s scoped search |
| M4 | Zero-result query | Helpful empty state |
| M5 | Empty Circle / new account | Corpus empty state |
| M6 | Airplane mode global + scoped | Works offline |
| M7 | Capture new memory → search its keyword | Immediate hit |
| M8 | Tap result | Opens correct Person Profile |
| M9 | Soft-delete memory → search | Gone from results |
| M10 | Query logging | Debug log and/or local durable log updated on search + tap |

---

## 15. Performance Expectations

| Metric | Target | Notes |
|---|---|---|
| Debounced query → first results paint | **≤ 300 ms** felt as immediate on reference device for ≤ ~500 active memories | Measure and record in DEVLOG |
| Keystroke debounce | **250–400 ms** | Prevents scan spam |
| Capture save latency | **No regression** vs 2B.8 | Phase 3.1 must not add sync work to save |

If corpus growth makes scans visibly slow during beta, file Phase 3.x optimization backlog (Isar prefilter / indexes) — do not expand 3.1 into ANN.

---

## 16. Accessibility Considerations

- Labeled search field and clear button  
- Result tiles as buttons with summarized labels  
- Empty states with text headings  
- Respect system font scaling in tiles and empty panels  
- Do not rely on color alone for match emphasis  

---

## 17. Documentation Updates Required

| Doc | Update |
|---|---|
| `CHANGELOG.md` | User-visible Search: global + person-scoped keyword search |
| `DEVLOG.md` | Architecture notes, latency measurement, logging location |
| `CURSOR_HANDOFF.md` | Phase 3.1 complete; next Phase 3.2 embedding spike (not Sprint 4 suggestions) |
| `BACKLOG.md` | Sort toggle, grouping revisit, scroll-to-memory, Unicode folding, etc. as discovered |
| `SPRINT3.md` | Leave frozen; optionally add a one-line status note at top only if product wants (“Phase 3.1 spec: SPRINT3_1.md”) — do not rewrite the design doc mid-flight |

Do **not** rewrite `FEATURES.md` to remove semantic search — semantic remains the longer-term Search capability; Phase 3.1 is the first shippable slice.

---

## 18. Handoff Criteria for Phase 3.2

Phase 3.2 (embedding provider spike) may begin only when:

1. Phase 3.1 Definition of Done is complete.  
2. Keyword Search is merged and usable on the main branch used for beta.  
3. Local search-query logging is producing inspectable on-device evidence (or an explicit backlog waiver if only NoOp hooks shipped — avoid this).  
4. No open P0/P1 in Search.  
5. Product agrees Phase 3.2 spike may start — spike outcome becomes an ADR; **semantic search still must not block** declaring Phase 3.1 valuable.

**Phase 3.2 must not** reopen Phase 3.1 UI unless required for wiring a second `SearchProvider`. Prefer additive DI.

**Explicitly still not next:** Suggestion Engine / FollowUps (Sprint 4 per `SPRINT3.md`).

---

## 19. Suggested Implementation Order (within 3.1)

1. Domain ranking pure functions + unit tests  
2. `SearchProvider` types + `KeywordSearchProvider`  
3. `MemoryRepository` active-list APIs + tests  
4. `SearchAnalytics` (+ durable local log if pursuing §9.8 recommendation)  
5. Global `SearchScreen` + widgets  
6. Router + Person Profile entry + `PersonSearchScreen`  
7. Manual QA matrix  
8. Docs / handoff  

---

## 20. Out-of-Scope Reminder (final)

Do not implement embeddings, semantic search, hybrid ranking, FollowUps, Suggestion Engine, ANN, sync, or sort/grouping toggles in Phase 3.1.

**Phase 3.1 ships real Search.** Everything smarter comes later, on top of the pluggable `SearchProvider` boundary defined here.
