# Release Readiness Report — Tend Capture RC

**Sprint:** 2B.8 (Release Candidate stabilization)  
**Build / version:** `1.0.0+1` (release APK with dart-defines; ProGuard rules added)  
**Report date:** 2026-08-08  
**Author:** Cursor agent (2B.8 RC execution) + device QA on AIN065  
**Reference device:** AIN065  
**OS / backend:** Android 16 (API 36), LiteRT-LM **GPU**

---

## Overall RC status

| Field | Value |
|---|---|
| **Status** | **Conditional Pass** (conditions **satisfied**) |
| **Go / No-Go for ~100-user beta** | **Go** |
| **One-line verdict** | Yes — ready to hand to approximately 100 external beta testers. Owner validation complete; product sign-off recorded. |

---

## 1. Summary of testing performed

- **E2E regression (Typed / Voice / OCR / Share; cold + warm):**
  - **Typed:** Full path on device — Capture → extract → confirmation → Create Person → Save → Person Profile (memory saved; relative `yesterday` → `2026-08-07`).
  - **Share cold-start:** `SEND text/plain` launched Share Capture (`Shared text` + Continue); no ANR/black screen; WaitTime ~0.5s after force-stop.
  - **Voice / OCR (engineering):** Ingress screens open with human copy + a11y labels (Recording / Stop / Cancel; Take photo / Gallery).
  - **Voice / OCR / offline (product owner):** Voice→Save, OCR→Save, and airplane-mode extraction (model already on device) completed **2026-08-08** with no release-blocking issues.
- **Prompt / stress corpus:** Official grounding probe **11/11 accepted** (release) on AIN065/GPU.
- **Offline / airplane mode:** Owner-validated — extract + confirm + Isar save with model on disk under airplane mode.
- **Model download / init / restore:** Model present on device; probe prepare/first-ready **11.3 s** (GPU). Release minify previously blocked; **fixed**.
- **Performance / memory / battery:** See §§4–8.
- **Accessibility spot-check:** Capture Continue labeled; Voice Stop/Cancel + Photo primary actions labeled this sprint; confirmation Save labeled; Create Person dialog usable.
- **Automated tests:** `flutter test -j 1` — **25/25 pass**.

---

## 2. Bugs found and fixed

| ID | Severity | Summary | Resolution |
|---|---|---|---|
| RC-01 | **P1** | `assembleRelease` failed (R8 missing ML Kit CJK/Devanagari/etc. classes) | Added `android/app/proguard-rules.pro` + wired in `build.gradle.kts` |
| RC-02 | **P1** | Multi-confirm error UI could show `Exception.toString()` | Human-readable error copy |
| RC-03 | **P1** | Double-tap races on Typed Continue / multi summary Continue / Save | Early-return / navigating / `_saveInFlight` guards |
| RC-04 | **P2** | ShareIntentBootstrap logged exceptions unconditionally | Assert/debug-gated |
| RC-05 | **P2** | Voice Stop/Cancel + Photo primary actions lacked Semantics | Labels/tooltips added |
| RC-06 | **P2** | STT mid-listen errors swallowed | Forwarded via `_activeOnError` to Voice UI |

---

## 3. Remaining known issues

| ID | Severity | Summary | Beta impact / mitigation |
|---|---|---|---|
| K-01 | P2 | Warm share can interrupt an in-progress capture via `router.go` | Rare; document for beta; backlog debounce/confirm |
| K-04 | P3 | Auth error string “missing email or phone” is slightly technical | Backlog copy polish |
| K-05 | P3 | Banner TalkBack may announce “Found N…” twice | Cosmetic a11y |
| K-06 | P3 | Beta builds **must** pass `--dart-define=SUPABASE_*` (unsigned APK without defines shows Startup failed) | Release checklist / CI |

~~K-02 / K-03~~ — **Cleared** by product-owner smoke (Voice→Save, OCR→Save, airplane extract), 2026-08-08.

**Open P0 count:** 0  
**Open P1 count:** 0  

---

## 4. Startup time

| Measurement | Result | Target | Pass? |
|---|---|---|---|
| Cold start → interactive shell (model on disk) | Activity `WaitTime` **2.3–3.0 s** (5 samples; release/debug after force-stop). Authenticated Circle reachable after session restore. | ≤ 5 s | **Yes** |
| Notes | Measured via `am start -W`. Splash→auth depends on session; without dart-defines bootstrap fails (K-06). | | |

---

## 5. Model initialization time

| Measurement | Result | Target | Pass? |
|---|---|---|---|
| Prepare / first inference-ready (model on disk) | **11.332 s** (`coldStartMs` from release grounding probe) | ≤ 15 s | **Yes** |
| Backend used | **GPU** | | |

---

## 6. Average extraction latency

| Measurement | Result | Target | Pass? |
|---|---|---|---|
| Warm extract (Continue → confirmation), n≥5 | **warmAvgMs = 6318** (~6.3 s avg over probe suite) | ≤ 8 s | **Yes** |
| Cold first extract after prepare | Included in cold prepare path; first cases ~5–7 s after ready | ≤ 15 s | **Yes** |
| Full warm path to Save (excl. user think-time) | Typed device path: extract ~≤8 s + create person + save; save itself instantaneous; total machine time **well under 10 s** excluding dialog typing | ≤ 10 s | **Yes** |

---

## 7. Memory usage observations

- Peak RSS during extract: **~1146 MB** (probe `peakRssMb`)
- After ≥20 capture loops: Not run as a dedicated 20× UI loop; **11 consecutive probe extracts** + device Typed save showed no crash / growth alarm
- Leak assessment: **None observed** (expected ~1.1 GB model residency)
- Notes: Matches historical AIN065 Gemma 4 E2B footprint

---

## 8. Battery observations

- Protocol: Full release grounding probe (11 extracts) + Typed E2E + Share/Voice/Photo smoke
- Battery delta: **~88% → ~81%** over the RC session (includes probe + UI automation; not an isolated 10-extract lab)
- Assessment: **Acceptable for beta** (no pathological drain observed)
- Notes: Soft gate only

---

## 9. Test coverage summary

| Layer | Result |
|---|---|
| `flutter test` (automated) | **Pass (25/25)** |
| Manual E2E matrix | **Pass** — Typed + Share cold (engineering) + Voice→Save, OCR→Save, airplane extract (owner) |
| EVALUATION / prompt corpus | Official grounding probe **11/11** on device |

### QA matrix (AIN065, 2026-08-08)

| Flow | Cold | Warm | Result |
|---|---|---|---|
| Typed extract → confirm → save | — | Yes | **Pass** (Create Person + relative date) |
| Share → Share Capture | Cold SEND | — | **Pass** (no ANR/black screen) |
| Voice → extract → confirm → save | — | Yes | **Pass** (owner smoke) |
| OCR → extract → confirm → save | — | Yes | **Pass** (owner smoke) |
| Airplane mode extract (model on disk) | — | Yes | **Pass** (owner smoke) |
| Empty Continue | — | Yes | **Pass** (no extract when empty / disabled path) |
| Validation (save w/o person) | — | Yes | **Pass** (human error) |

---

## 10. Devices tested

| Device | OS | Role | Notes |
|---|---|---|---|
| AIN065 | Android 16 | Reference | GPU backend; primary RC numbers + owner smokes |
| Host Windows | — | Unit tests / release build | R8 fix verified |

---

## 11. Risk assessment

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| Beta APK missing dart-defines | Medium if process slips | App won’t boot past startup error | Bake defines into CI/release script (K-06) |
| Share interrupts in-progress capture | Low | Lost draft context | Document; backlog (K-01) |
| High RSS (~1.1 GB) on mid devices | Medium on low-RAM | OOM / slow | Capability gate + ManualFallback already exist |

---

## 12. Go / No-Go recommendation

**Recommendation:** **Go**

**Rationale:**  
No open P0/P1. Release builds succeed. Extraction latency, model init, cold Activity start, grounding quality, and all primary capture paths (Typed / Voice / OCR / Share) plus offline extract meet RC exit criteria on the reference device. Residual P2/P3 items are documented and accepted for beta.

**Conditional Pass conditions — status:**

| # | Condition | Status |
|---|---|---|
| 1 | Distribute beta APKs built **with** `SUPABASE_URL` / `SUPABASE_ANON_KEY` dart-defines | **Accepted** — release process requirement (K-06); owner aware |
| 2 | Owner completes Voice→save, OCR→save, airplane-mode extract (model on disk) | **Satisfied** — completed 2026-08-08, no release-blocking issues |
| 3 | Accept documented P2/P3 items without expanding 2B.8 into new features | **Accepted** |

**Sprint 3:** Gate cleared for **planning**. Implementation must not start until after architecture / sprint-planning review.

---

## Sign-off

| Role | Name | Date | Signature |
|---|---|---|---|
| Engineering | Cursor agent (2B.8 execution) | 2026-08-08 | Report filed — Conditional Pass / Go; conditions later satisfied |
| Product / owner | Siddharth | 2026-08-08 | **Acknowledged** — owner smokes complete; Conditional Pass conditions satisfied; **Go** for ~100-user beta; Sprint 2 closed; next = Sprint 3 **planning** (no implementation yet) |
