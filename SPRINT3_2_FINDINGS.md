# SPRINT3_2_FINDINGS.md — Phase 3.2 Embedding Provider Spike
### Outcome document (plan is `SPRINT3_2.md`)

**Spike window:** 2026-08-08 (within two-working-day timebox)  
**Reference device:** AIN065 (Android 16, same tier as Sprint 2B.8 RC)  
**Harness:** `lib/debug/embedding_spike_main.dart` + `lib/debug/embedding_spike_cases.dart`  
**Status:** Complete — recommendation issued

---

## 1. Recommendation

### **Conditional Go** for Phase 3.3 semantic search — **not** via Gemma 4 E2B

| | |
|---|---|
| **Provider** | Dedicated on-device embedder: **Gecko-110m-en** (`Gecko_256_quant.tflite`) via `flutter_gemma_embeddings` / `LiteRtEmbeddingBackend` |
| **Dimension** | **768** (float32) |
| **Versioning** | Persist `embeddingModelVersion` (e.g. `gecko-110m-en-seq256-v1`) beside `Memory.embedding` before comparing vectors |
| **Ranking** | Additive signal on top of Phase 3.1 keyword `SearchProvider` — never a replacement |
| **Do not use** | Gemma 4 E2B for embeddings (not exposed); EmbeddingGemma-300m for MVP download (HF gated, same class of ADR-010 failure) |

**Conditions that must hold before / during Phase 3.3:**

1. Keyword search remains the default / always-on path; semantic is pluggable and disable-able.
2. Schema adds `embeddingModelVersion` (and optionally `embeddingDim`) before production writes.
3. Backfill is batched, resumable, opportunistic (idle/charging preferred for large corpora).
4. Negative / no-match calibration is addressed (see §4 — absolute cosine scores stay high even for unrelated queries).
5. Production never registers `embeddingBackends` until Phase 3.3 wires a real provider behind `EmbeddingProvider`.

**If conditions cannot be met soon:** fall back to **Option 3 — stay keyword-only** (Phase 3.1 already ships real search). That remains a first-class outcome.

---

## 2. Research questions — answers

### RQ1 — Does Gemma 4 E2B expose embeddings through the current bridge?

**No.** Evidence:

- `InferenceModel` API has `createSession` / `createChat` only — **no** `generateEmbedding`.
- Embeddings require a separate `EmbeddingModel` from `FlutterGemma.getActiveEmbedder()` after `installEmbedder()` + `flutter_gemma_embeddings`.
- Device log: `getActiveEmbedder` without an embedder → `Bad state: No embedding backend registered` / no active embedding model.
- `EXP1_RESULT=NOT_CAPABLE`

### RQ2 — Dim / latency / RAM if RQ1 yes?

**N/A for Gemma 4.** For Option 2 (Gecko), see §3.

### RQ3 — Retrieval quality on Tend-shaped text?

**Directional yes for paraphrase on the fixed micro-set** (Gecko). See §4. Not a large statistical benchmark.

### RQ4 — Dedicated alternative cost/delivery?

**Gecko-110m-en** evaluated as the single credible public alternative:

| Item | Value |
|---|---|
| Artifact | `Gecko_256_quant.tflite` + `sentencepiece.model` |
| Source | `litert-community/Gecko-110m-en` (public HTTPS; `needsAuth: false` in flutter_gemma example) |
| Size | **~114 MB** model (+ ~0.8 MB tokenizer) |
| Dim | **768** |
| Cold embed | **187 ms** (AIN065, CPU preferredBackend) |
| Warm avg (N=8) | **172.1 ms** |

**EmbeddingGemma-300m:** HF resolve without token → **HTTP 401**. Disqualified for MVP in-app download (ADR-010 / SPRINT3_2 §8), regardless of quality.

### RQ5 — Backfill cost?

Using warm **172.1 ms/item** (document embedding):

| Corpus size | Extrapolated time |
|---|---|
| 50 | ~8.6 s |
| 200 | ~34 s |
| 500 | ~1.4 min |
| 2000 | ~5.7 min |

**Current real corpus size on device:** unknown this spike (not queried from Isar — timeboxed; no production backfill run). Treat 50–200 as early-beta plausible; 500–2000 as growth scenarios.

**Battery:** Exp 6 cut (timebox cut order). Unknown — soft-gate style check deferred to Phase 3.3 if go proceeds.

### RQ6 — Re-embed migration risk?

**High without versioning.** Project already swapped models twice. Different providers/dims must never be compared silently. Recommend `embeddingModelVersion` string on Memory (SCHEMA proposal in ADR-013) — Phase 3.3 implements the field.

### RQ7 — Distribution / hub gating?

| Candidate | Public no-login download? |
|---|---|
| Gemma 4 E2B (already installed) | Yes — but **no embed API** |
| EmbeddingGemma-300m | **No** (401 without token / license gate) |
| Gecko-110m-en | **Yes** (302 → public CDN; host download succeeded) |

---

## 3. Latency / footprint / storage (Gecko)

| Metric | Measured |
|---|---|
| Cold | 187 ms |
| Warm avg | 172.1 ms |
| Vector length | 768 |
| Peak RSS delta | **Unknown** (not instrumented this spike — cut after primary quality/latency) |
| Storage / memory | 768 × 4 = **3072 bytes** ≈ 3 KB |
| 5,000 memories | ≈ **14.6 MB** Isar growth (negligible vs ~2.4 GB Gemma) |
| Cumulative download | Gemma 4 E2B ≈2.4 GB + Gecko ≈114 MB ≈ **2.5 GB+** |

---

## 4. Retrieval quality micro-benchmark (Gecko)

Fixed set: `embedding_spike_cases.dart` (7 docs, 7 queries). Cosine similarity, query=`TaskType.retrievalQuery`, docs=`TaskType.retrievalDocument`.

| Query | Kind | Top-3 (id:score) | Expected | Hit? |
|---|---|---|---|---|
| OpenAI | exact | d_openai:0.730, … | d_openai | yes (top1) |
| physiotherapy | exact | d_physio:0.786, … | d_physio | yes (top1) |
| Where did Rahul get a new job? | paraphrase | d_openai:0.771, d_cricket:0.768, d_tea:0.758 | d_openai | yes (top1; **narrow margin**) |
| Is Mom recovering with physical therapy? | paraphrase | d_physio:0.764, d_surgery:0.721, … | physio/surgery | yes |
| Who relocated to a new city? | paraphrase | d_bangalore:0.732, … | d_bangalore | yes |
| health updates about Mom | category | d_physio:0.751, d_surgery:0.747, … | physio/surgery | yes |
| wedding anniversary plans | negative | d_house:0.655, d_bangalore:0.655, … | none | scores still ~0.65 — **poor absolute calibration** |

**Summary:** `exact_top1=2/2`, `paraphrase_top3=3/3` on this tiny set.

**Caveats:**

- Synthetic corpus only; Phase 3.1 on-device search-query log was **not** ingested this run (empty in-repo placeholders; device prefs not read) — unknown real-query behavior.
- Negative queries still get mid-0.6 cosine scores → Phase 3.3 needs a threshold / hybrid-with-keyword gate so semantic alone does not invent relevance.
- Paraphrase job vs cricket margin was ~0.003 — fragile; keyword boost remains essential.

---

## 5. Backfill strategy recommendation (not implemented)

1. **Batched** (e.g. 10–25 memories per tick), never all-at-once on UI thread.  
2. **Resumable / idempotent** keyed by `memory.uuid` + `embeddingModelVersion` (same spirit as relative-date backfill).  
3. **Opportunistic** for corpora ≫200: prefer charging + idle; for tiny beta corpora, fire-and-forget after save is acceptable (~0.17 s incremental).  
4. **Per-capture:** generate embedding after `MemoryRepository.create/update` succeeds — do not block confirmation UX on embed latency.  
5. Progress UI: only if backfill estimate > ~30–60 s for the user’s corpus.

---

## 6. Experiments skipped / unknowns (honest timebox)

| Item | Status |
|---|---|
| Exp 6 battery spot-check | **Cut** (timebox cut order) |
| Peak RSS during embed | **Unknown** |
| Real search-query-log cases | **Unknown** (not pulled) |
| Current Isar corpus cardinality | **Unknown** |
| Second alternative model beyond Gecko | **Not needed** (Gecko ran; EmbeddingGemma disqualified on distribution) |
| Production `EmbeddingProvider` wiring | **Out of scope** (correctly not done) |

---

## 7. Architecture implications

- Option 1 (reuse Gemma 4) is **closed** for the current bridge.
- Option 2 (Gecko) is **viable** for a Conditional Go into Phase 3.3.
- Option 3 (keyword-only) remains valid if product prefers zero second-model cost until real query-log demand for paraphrase is proven.

New dependency present for spike: `flutter_gemma_embeddings` in `pubspec.yaml`. **Production `FlutterGemma.initialize` must not register embedding backends until Phase 3.3.** Spike-only registration lives in `embedding_spike_main.dart`.

---

## 8. Deliverables checklist

- [x] This findings document  
- [x] Draft ADR-013 in `ADR.md`  
- [x] Debug harness + cases under `lib/debug/`  
- [x] DEVLOG / BACKLOG / handoff updates  
- [x] SCHEMA versioning recommendation (in ADR — not implemented in Isar)

---

**Bottom line:** Do **not** block on Gemma-4-as-embedder. If Phase 3.3 proceeds, use **public Gecko** behind `EmbeddingProvider`, keep keyword search primary, version embeddings, and calibrate no-match behavior. Otherwise stay on Phase 3.1 keyword search with no regret.
