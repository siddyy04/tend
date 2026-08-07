# Extraction Completeness Benchmark

Permanent regression cases for **on-device multi-memory extraction** (Gemma 4 / LiteRT-LM, parallel native FunctionCall — ADR-012).

Use this suite whenever `LiteRtPromptBuilder` (or equivalent) prompts are refined.  
Do **not** change the architectural contract: **one FunctionCall → one `ExtractedMemoryCandidate`**.

Machine-readable twin: `lib/debug/extraction_completeness_cases.dart`.

---

## Protocol constraints (locked)

- Parallel native function calls only
- Flat tool schema (no primary `candidates[]` protocol)
- Prompt-quality fixes only — no protocol redesign

---

## Future prompt refinement goals (when scheduling this work)

Encourage the model to:

1. Treat every independently useful fact as a separate memory.
2. Not skip memories merely because later sentences use pronouns instead of repeating the person’s name.
3. Split multiple independent facts within the same sentence into separate memories where appropriate.
4. Continue avoiding duplicated or merged memories.
5. If the note lacks an explicit stable memory/relationship fact, emit **zero** function calls — never invent to satisfy the tool.

---

## Cases

### C1 — Pronouns + compound continuation (manual repro)

**Note**

> Mom had spinal surgery. She started physiotherapy and is recovering well.

**Expected memories (3)**

1. Mom had spinal surgery  
2. Mom started physiotherapy  
3. Mom is recovering well  

**Observed (2026-08-08, before prompt fix)**  
Only the first memory extracted.

---

### C2 — Same person, multiple memories (pronouns)

**Note**

> Priya joined Google. She moved to Bangalore. She loves her new team. She is saving for a house.

**Expected memories (4)**

1. Priya joined Google  
2. Priya moved to Bangalore  
3. Priya loves her new team  
4. Priya is saving for a house  

---

### C3 — Compound sentence

**Note**

> Rahul likes tea and plays cricket.

**Expected memories (2)**

1. Rahul likes tea  
2. Rahul plays cricket  

---

### C4 — Mixed pronouns

**Note**

> Dad retired last month. He now walks every morning.

**Expected memories (2)**

1. Dad retired last month  
2. Dad now walks every morning  

---

### C5 — Relative dates + pronouns

**Note**

> Mom has a follow-up next week. She started physiotherapy yesterday.

**Expected memories (2)**

1. Mom has a follow-up next week (`dateValueRaw` includes `next week`)  
2. Mom started physiotherapy yesterday (`dateValueRaw` includes `yesterday`)  

---

## Insufficient information (zero memories)

Notes that are only a name, lone word, or otherwise lack an explicit stable memory/relationship fact must produce **no** native function calls and **no** candidates. Hallucinated `eventText` / `quoteEvidence` is a fail even if later rejected by grounding.

### I1 — Bare name “Emily”

**Note:** `Emily`  
**Expected:** 0 FunctionCalls, 0 candidates  

**Observed (2026-08-08):** Model invented “Emily was a volunteer at a local animal shelter”; grounding correctly rejected it.

### I2 — Bare name “John”

**Note:** `John`  
**Expected:** 0 FunctionCalls, 0 candidates  

### I3 — Bare name “Mom”

**Note:** `Mom`  
**Expected:** 0 FunctionCalls, 0 candidates  

### I4 — Lone relative word “Yesterday”

**Note:** `Yesterday`  
**Expected:** 0 FunctionCalls, 0 candidates  

### I5 — Lone preference word “Tea”

**Note:** `Tea`  
**Expected:** 0 FunctionCalls, 0 candidates  

### I6 — Lone entity word “Google”

**Note:** `Google`  
**Expected:** 0 FunctionCalls, 0 candidates  

**Scoring for I-cases:** PASS only if raw native function-call count is 0 (not merely that grounding emptied the list after a hallucinated call).

---

## Scoring (per case)

| Check | Pass if |
|---|---|
| Call count | Native function-call count equals expected memory count (including **0**) |
| Person association | Each call’s `personMentioned` resolves to the intended person (name or clear pronoun binding in event/quote); N/A when expected count is 0 |
| Coverage | Each expected fact is present (no under-extraction); N/A when expected count is 0 |
| No merge | No single call bundling two independent facts |
| No duplicate | No two calls for the same fact |
| Grounding | `quoteEvidence` / `dateValueRaw` still literal in the note |
| No hallucination (I-cases) | Zero calls — invented facts that grounding rejects still fail the case |

Case **PASS** only if all applicable checks pass. Suite **PASS** only if every case passes.

---

## Related

- Backlog: **AI Quality — Improve extraction completeness for pronouns and compound sentences**
- Backlog: **Capture UX — clearer empty-extraction message for insufficient notes**
- ADR-012 — Parallel native function calls for multi-memory extraction
- Spikes: `lib/debug/same_person_multi_memory_spike_main.dart`, `mom_completeness_spike_main.dart` (name-repeated baselines; this suite covers pronoun/compound/insufficient gaps)
