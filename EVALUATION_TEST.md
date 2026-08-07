# Tend LLM Evaluation Suite v1.0

## Objective

Evaluate candidate on-device LLMs for Tend using realistic relationship-memory tasks.

This benchmark should be run **without changing any prompts** so that results are comparable across different models.

---

# Instructions

For every prompt:

1. Use the exact same memory database.
2. Do not modify the prompt.
3. Capture the model's full response.
4. Score the response using the rubric at the end of this document.
5. Record latency (optional).
6. Record pass/fail.

---

# Category 1 – Simple Recall (5 Prompts)

### Prompt 1

What city did Priya move to after changing jobs?

---

### Prompt 2

When is Rahul's birthday?

---

### Prompt 3

Which restaurant did Sarah say she loved?

---

### Prompt 4

What book was Alex reading?

---

### Prompt 5

What gift did I promise to buy Mom?

---

# Category 2 – Multi-Fact Recall (5 Prompts)

### Prompt 6

Tell me everything I know about Priya's new job.

---

### Prompt 7

Summarize Rahul's travel plans.

---

### Prompt 8

What health issues has Dad mentioned recently?

---

### Prompt 9

What promises have I made to Sarah?

---

### Prompt 10

List all birthdays coming up next month.

---

# Category 3 – Realistic User Queries (10 Prompts)

### Prompt 11

I remember Priya telling me something about changing jobs a few weeks ago. She was worried about leaving her current team but was also excited about the salary increase. Can you remind me exactly what she was concerned about?

---

### Prompt 12

Rahul and I spoke about our Goa trip sometime recently. I vaguely remember there being some issue with the hotel booking and I think we also discussed renting a bike. Can you remind me of all the details?

---

### Prompt 13

I promised Sarah I'd help her prepare for an interview. I don't remember when it's scheduled or which company it was for. Can you check?

---

### Prompt 14

I think Mom mentioned a doctor's appointment and some test results recently. Can you summarize everything related to her health?

---

### Prompt 15

I can't remember what gift ideas I had for Dad. Can you remind me of all of them?

---

### Prompt 16

My cousin recently got engaged. Can you tell me everything we've talked about regarding the wedding?

---

### Prompt 17

I'm meeting Priya tomorrow. Remind me of everything important I should remember before I meet her.

---

### Prompt 18

Can you summarize everything we've discussed about Rahul over the past month?

---

### Prompt 19

What important promises have I made recently that I still need to follow up on?

---

### Prompt 20

I feel like I'm forgetting something important about Sarah. Can you remind me of everything significant?

---

# Category 4 – Ambiguous Queries (5 Prompts)

The correct behaviour is **to ask a clarifying question instead of guessing**.

### Prompt 21

When is her birthday?

Expected Behaviour:
Ask who "her" refers to.

---

### Prompt 22

What did he tell me last week?

Expected Behaviour:
Ask who "he" refers to.

---

### Prompt 23

Remind me what we decided.

Expected Behaviour:
Ask which conversation.

---

### Prompt 24

Did I promise anything?

Expected Behaviour:
Ask which person or timeframe.

---

### Prompt 25

Where are we meeting?

Expected Behaviour:
Ask which meeting is being referred to.

---

# Category 5 – Hallucination Resistance (5 Prompts)

The correct behaviour is **to admit that the information is unavailable if it does not exist in memory.**

### Prompt 26

What is Priya's passport number?

Expected Behaviour:
State that the information is unavailable.

---

### Prompt 27

What salary did Rahul get at Google?

Expected Behaviour:
Only answer if present in memory. Never invent.

---

### Prompt 28

What medicines is Sarah taking?

Expected Behaviour:
Only answer if explicitly stored.

---

### Prompt 29

Did Mom say she has diabetes?

Expected Behaviour:
Only answer if supported by memory.

---

### Prompt 30

What happened during my meeting yesterday?

Expected Behaviour:
If no memory exists, explicitly say you don't know.

---

# Scoring Rubric

Each prompt receives a score out of **5**.

| Criterion                                     | Points |
| --------------------------------------------- | -----: |
| Correct retrieval                             |      2 |
| No hallucinations                             |      1 |
| Complete answer                               |      1 |
| Correct instruction following / output format |      1 |

Maximum score:
**150 points**

---

# Evaluation Report Format

For every prompt record:

* Prompt ID
* Model response
* Score (/5)
* Pass / Fail
* Notes
* Latency (optional)

At the end provide:

* Total Score (/150)
* Pass Rate
* Average Latency
* Hallucination Count
* Clarification Success Rate
* Retrieval Accuracy
* Overall Recommendation (Production Ready / Needs Improvement / Not Suitable)

---

# Success Criteria

| Score    | Recommendation                 |
| -------- | ------------------------------ |
| 135–150  | Production Ready               |
| 120–134  | Minor Improvements Required    |
| 100–119  | Promising but Not Ready        |
| 80–99    | Significant Improvement Needed |
| Below 80 | Not Suitable for Tend          |
