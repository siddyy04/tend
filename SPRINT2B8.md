# SPRINT 2B.8 — Release Candidate (RC) Stabilization

### Target: AI coding agent (Cursor). Read fully before writing any code.

> **Prerequisite:** Sprint **2B.7** (Capture UX Polish) is complete.  
> **Gate:** Do **not** begin Sprint 3 until this sprint reaches release-candidate quality and is marked done.

You are executing **Sprint 2B.8 only**. This is a **Release Candidate stabilization sprint**, not a feature-development sprint.

Reference: `ARCHITECTURE.md`, `ADR.md`, `SPRINT2B.md`, `EVALUATION_TEST.md`, `BACKLOG.md`, `CHANGELOG.md`, `CURSOR_HANDOFF.md`.

---

## 0. Mindset (binding)

Treat every task as answering:

> **"If we had to ship this app to 100 external beta testers tomorrow, what would we improve or fix first?"**

Priorities, in order:

1. **Quality** — correct behaviour, no crashes, no data loss  
2. **Reliability** — download, offline, interrupted ops, warm/cold paths  
3. **Consistency** — Typed / Voice / OCR / Share feel like one product  
4. **Production readiness** — performance, battery, a11y, docs, release notes  

**Unless a critical issue is discovered, do not introduce new user-facing features.**  
Fix, harden, measure, clean up, and document. Prefer filing non-critical ideas in `BACKLOG.md` over shipping them in 2B.8.

**Do not** change the LiteRT extraction protocol (ADR-012).  
**Do not** start Sprint 3 work here.

---

## 1. Sprint Goal

Deliver a **beta-ready Capture Release Candidate**: Typed, Voice, OCR, and Share → extract → confirm → save, stable enough for ~100 external testers.

Success looks like:

- Capture works end-to-end on real devices without ANRs, black screens, or silent failures  
- Failures are recoverable and human-readable  
- Latency / memory / battery behaviour is known and documented  
- Code and docs are tidy enough to support a beta cut  

---

## 2. Workstreams (where applicable)

### 2.1 End-to-end regression

- Typed, Voice, OCR, Share — **cold and warm** where relevant  
- Success / empty / failure / multi-memory / Create Person / ambiguous person  
- Share: warm-start and cold-start (no Circle flash, no ANR)  
- Record results in a QA matrix (DEVLOG or dedicated checklist section)

### 2.2 Stress / real-world prompts

- Large, diverse corpus (expand `EVALUATION_TEST.md` + on-device runs)  
- Short notes, long notes, multi-person, multi-fact, noisy chat paste  
- Log systematic misses to `BACKLOG.md` — do not silently accept regressions

### 2.3 Performance profiling

- App startup time (cold / warm)  
- Extraction latency (cold first inference vs warm)  
- UI responsiveness during extract / confirm (jank, skipped frames)  
- Document baselines; optimize **only with evidence** and without protocol churn

### 2.4 Memory and leaks

- Heap / RSS during model load + extract + confirm  
- Repeat capture loops; watch for growth  
- Fix leaks or leaks-like retention (controllers, subscriptions, plugin listeners)

### 2.5 Battery / on-device inference

- Spot-check battery impact of model prepare + a short capture session  
- Note GPU vs CPU backend behaviour if observable  
- No new power-management features unless critical

### 2.6 Model download and initialization

- First-run download, checksum, prepare, kill/restore  
- Interrupted download / offline during download  
- Unsupported / low-RAM tier: graceful fallback, no crash

### 2.7 Offline-first

- Airplane mode: capture, extract (model already on device), confirm, save to Isar  
- Auth edge cases when offline (document expected behaviour; no Sprint 3 sync work)

### 2.8 Error recovery

- Interrupted extract, failed OCR/STT permissions, empty share, model not ready  
- Ensure every path has a human message and a next action (retry / edit / manual)  
- No technical / debug strings in UI

### 2.9 Edge cases

| Case | Expectation |
|---|---|
| Empty input | No extract; friendly block |
| Extremely long input | No ANR; acceptable truncate/timeout UX if needed |
| Malformed / empty OCR | Empty panel, no Gemma on empty |
| Duplicate memories / multi-fact | Multi confirm still sane |
| Ambiguous people | Clarification note + picker; save still works |
| Rapid share / double Continue | No double-save / black screen |

### 2.10 UX consistency

- Loading copy, empty panels, confirmation banners, button hierarchy  
- Same emotional tone across Typed / Voice / OCR / Share  
- Polish only; no redesign

### 2.11 Accessibility

- Primary actions labeled; loading announced; disabled states clear  
- Large text / TalkBack spot-check on Capture + confirmation

### 2.12 Code cleanup and debt

- Remove obsolete TODOs, TEMP debug, dead code, unused imports  
- File remaining debt in `BACKLOG.md` with priority  
- Verify `CaptureAnalytics` hooks still fire (no backend required)

### 2.13 Documentation and release notes

- Update `CHANGELOG.md` for RC / beta cut  
- DEVLOG: latency, device notes, known issues  
- `CURSOR_HANDOFF.md`: **Next = Sprint 3** only when RC is signed off  
- Short “known limitations for beta” list if needed

---

## 3. Out of scope

- Sprint 3 features (Today’s Opportunities, search ranking, sync polish)  
- New capture ingress types or new AI capabilities  
- Changing parallel function-call protocol  
- Interactive / conversational clarification  
- Embeddings / FollowUp  
- “Nice to have” UX features that are not beta-blocking  

---

## 4. Explicit RC exit criteria (binding)

Sprint 2B.8 does **not** end when “testing feels done.”  
It ends only when **all must-pass criteria below are satisfied** (or a **Conditional Pass** is recorded with every open P0/P1 resolved and residual risks explicitly accepted in the Release Readiness Report).

### 4.1 Severity definitions

| Severity | Meaning | RC rule |
|---|---|---|
| **P0** | Crash, data loss, ANR, black screen blocking Capture, or cannot complete a primary capture path | **Must be 0 open** |
| **P1** | Major broken behaviour on a primary path (wrong save, share broken, offline extract fails with model present, unusable error UX) | **Must be 0 open** |
| **P2** | Annoying but workaround exists | May remain if documented in report |
| **P3** | Polish / backlog | File in `BACKLOG.md` |

### 4.2 Reference device and performance targets

**Reference device for RC numbers:** primary physical QA device used during 2B.8 (default historical: **AIN065** / mid-high Android with GPU backend). Record exact model, OS, and backend in the report.

| Metric | Target (must meet or Conditional Pass with justification) | Notes |
|---|---|---|
| **App cold start** to interactive shell (model already on disk; not counting first download) | **≤ 5 s** to first interactive frame / Circle usable | Splash → auth restore → Circle |
| **Model initialization** (prepare / first chat ready after app start, model on disk) | **≤ 15 s** on reference device | Document GPU/NPU/CPU |
| **Warm extraction latency** (Continue → confirmation with candidates) | **≤ 8 s** average over ≥5 warm runs | Aligns with product “under ~10s” including confirm tap |
| **Cold first extraction** after prepare | **≤ 15 s** | Known ~11s historical; do not fail RC solely for exceeding 10s if ≤15s and documented |
| **Full warm capture path** (text ready → confirm → Save) | **≤ 10 s** excluding user think-time | FEATURES / roadmap intent |
| **Memory** | No sustained leak across **≥20** capture loops; RSS after session returns near baseline (±reasonable model residency) | Peak ~1.1 GB with Gemma E2B is historically expected |
| **Battery** | No catastrophic drain; ≤ **~5% battery / 10 warm extracts** as a soft check on reference device, or qualitative “acceptable for beta” with notes | Soft gate — hard fail only if clearly pathological |

Targets may be tightened in the report if measured baselines are better; they must not be silently loosened without Conditional Pass + risk note.

### 4.3 Must-pass checklist

- [ ] **No open P0 or P1 bugs** (all fixed or proven not reproducible)  
- [ ] **All capture flows** (Typed, Voice, OCR, Share) complete successfully **without crashes** on the reference device (cold + warm Share)  
- [ ] **Fully offline** after model downloaded (airplane mode: extract + confirm + Isar save)  
- [ ] **Cold-start time** meets target (§4.2)  
- [ ] **Extraction latency** meets warm (+ cold) targets (§4.2)  
- [ ] **No memory leaks** detected in extended capture-loop testing (§4.2)  
- [ ] **Battery impact** within acceptable limits for repeated AI extraction (§4.2)  
- [ ] **All automated tests pass** (`flutter test` / project CI suite)  
- [ ] **No production debug logging** of secrets/PII; no obsolete TEMP / TendShare QA spam; obsolete TODOs removed or backlog’d  
- [ ] **Accessibility review completed** (Capture + confirmation spot-check)  
- [ ] **Documentation finalized:** `CHANGELOG.md`, `DEVLOG.md`, `CURSOR_HANDOFF.md`, and **Release Readiness Report**  

### 4.4 Release Readiness Report (required deliverable)

At the end of 2B.8, produce / finalize:

**[`RELEASE_READINESS_REPORT.md`](RELEASE_READINESS_REPORT.md)**

The report must answer:

> **Is this build ready to hand to approximately 100 external beta testers?**

Required sections:

1. Overall RC status: **Pass** / **Conditional Pass** / **Fail**  
2. Summary of testing performed  
3. Bugs found and fixed  
4. Remaining known issues (P2/P3 only if Pass/Conditional)  
5. Startup time (measured)  
6. Model initialization time (measured)  
7. Average extraction latency (warm + cold)  
8. Memory usage observations  
9. Battery observations  
10. Test coverage summary (automated + manual matrix)  
11. Devices tested  
12. Risk assessment  
13. **Go / No-Go** recommendation for a 100-user beta release  

**Status meanings:**

| Status | Meaning | Sprint 3? |
|---|---|---|
| **Pass** | All must-pass criteria met; Go for beta | Yes |
| **Conditional Pass** | No P0/P1; specific non-blocking risks accepted in writing; still **Go** for beta | Yes, after conditions recorded |
| **Fail** | Any open P0/P1, or failed hard performance/offline/crash criteria | **No** — fix blockers, re-run report |

---

## 5. Workstream acceptance (supports exit criteria)

1. E2E regression matrix completed for Typed, Voice, OCR, Share.  
2. Diverse prompt stress run completed; systematic gaps filed in backlog.  
3. Model download / init / restore verified; unsupported tier does not crash.  
4. Error recovery reviewed; no debug strings in Capture UI.  
5. Edge-case list (§2.9) exercised or ticketed as P2+.  
6. UX consistency + a11y spot-check done.  
7. Cleanup landed; release notes ready.  

---

## 6. Definition of Done

- [x] §4.3 must-pass checklist complete (Conditional Pass conditions satisfied by product-owner smokes 2026-08-08)
- [x] `RELEASE_READINESS_REPORT.md` filled with measured numbers and **Go / No-Go**
- [x] RC status is **Pass** or **Conditional Pass** (not Fail)
- [x] `CHANGELOG.md` / beta release notes ready
- [x] `CURSOR_HANDOFF.md`: Sprint 2 closed; **Next = Sprint 3 planning** (no implementation yet)
- [x] Product/owner acknowledgement of Go for ~100 beta testers  

---

## 7. Explicit gate

**Sprint 3 must not begin until:**

1. Sprint 2B.8 RC exit criteria (§4) are met, **and**  
2. The Release Readiness Report concludes **Go** (Pass or Conditional Pass with no open P0/P1).  

If the report is **Fail** or **No-Go**, remain on 2B.8 until blockers are resolved and the report is re-issued.

Non-critical product ideas discovered during RC go to `BACKLOG.md` — not into new 2B.8 feature scope.
