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
2. Not skip memories merely because later sentences use pronouns instead of repeating the person’s name; set `personMentioned` to the named person (never the pronoun).
3. Split multiple independent facts within the same sentence into separate memories where appropriate.
4. Continue avoiding duplicated or merged memories.
5. If the note lacks an explicit stable memory/relationship fact, emit **zero** function calls — never invent to satisfy the tool.

**App-layer complement (deterministic, not NLP):** after mapping FunctionCalls in a single note, `bindPronounPersonMentions` rewrites empty/pronoun `personMentioned` to the sole prior explicit name when exactly one distinct person has appeared so far; otherwise leaves unchanged (fail safe).

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

### C6 — Rahul / OpenAI pronoun QA repro

**Note**

> Met Rahul yesterday.  
> He got selected by OpenAI.

**Expected memories (2)**

1. Met Rahul yesterday (`dateValueRaw` includes `yesterday`)  
2. Rahul got selected by OpenAI (`personMentioned=Rahul`, not `He`)

**Observed (2026-08-08, pre-fix device trace)**  
`ONE_FUNCTION_CALL`: merged into a single career memory (`personMentioned=Rahul`, quote=`He got selected by OpenAI`, `dateValueRaw=yesterday`) — meeting fact dropped.

**Fix**  
Minimal prompt completeness line + example; app-layer `bindPronounPersonMentions` for empty/pronoun `personMentioned` when a sole prior explicit name exists.

---

### C7 — Ambiguous pronoun (fail safe)

**Note**

> Rahul joined OpenAI. Priya moved to Berlin. He loves tea.

**Expected**  
At least the two explicit-name facts (Rahul, Priya). A third call with `He` must **not** be auto-bound by the app when two distinct people already appeared — leave unresolved / drop (fail safe). Ideal model behavior: omit the ambiguous third call or ask via confirmation later; do not invent.

---

### C8 — Multiple people, explicit names

**Note**

> Rahul likes tea. Priya plays cricket.

**Expected memories (2)** — Rahul / Priya respectively; no pronoun binding.

---

### C9 — Mixed family + ambiguous He

**Note**

> Dad retired last month. Mom started physiotherapy. He walks every morning.

**Expected**  
At least Dad + Mom facts. `He walks…` must not be bound by the app after two distinct names (fail safe). Prefer model sets `personMentioned=Dad` if it emits a third call.

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
- Spikes: `lib/debug/same_person_multi_memory_spike_main.dart`, `mom_completeness_spike_main.dart`, `pronoun_rahul_trace_main.dart`
- Unit tests: `test/domain/rules/pronoun_person_binding_test.dart`
