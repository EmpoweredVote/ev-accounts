---
phase: 127-fl-house-rep-stances
plan: 01
status: complete
completed: 2026-06-17
requirements: [USHS-01]
commit: b8279aca
---

# 127-01 SUMMARY — FL House Rep Stances, Batch A

## What was built

Researched and pushed sourced compass stances for the first 14 Florida US House
reps (external_id -12001..-12014) across the 25 federal-relevant live topics, via
the research-stances skill + politician-stance-researcher agents.

- **186 `inform.politician_answers`** rows upserted (ON CONFLICT DO UPDATE)
- **186 `inform.politician_context`** rows — every answer has a paired context row
  with a non-empty `sources` array of real fetched URLs (0 answers without context)
- **62 `essentials.quotes`** inserted; **61 set as Read-&-Rank pick**; 0 surname leaks
- CSV of record: `backend/data/stance-research/2026-06-17-fl-house-batch-a.csv`

## Per-rep stance counts (of 25 federal topics)

Patronis 6, Dunn 14, Cammack 16, Bean 14, Rutherford 13, Fine 11, Mills 7,
Haridopolos 12, Soto 17, Frost 9, Webster 15, Bilirakis 18, Luna 15, Castor 19.

Thin records (Patronis 6, Mills 7, Fine 11) are honest-skips driven by genuine
evidence scarcity (recent Apr-2025 special-election members; federal source 403s),
not guessing — no party-inferred values.

## 3-CONCURRENCY VALIDATED ✅ (key output for the rest of v2.16)

Ran politician-stance-researcher agents **3 at a time** on premium tier. The first
triple (Patronis/Dunn/Cammack) and all four subsequent triples completed with
**zero empty-output / 429 failures**. The old Pro-tier mass-launch failure did NOT
recur. **Concurrency cap for 127-02 and the rest of v2.16 = 3.**

## Key decisions / deviations

- **25 federal topics in scope** (of 44 live): dropped the 11 city-level topics +
  all 7 `judicial-*` topics per the city-skip rule for federal reps.
- **Per-rep output files → merged** into the batch CSV. Each agent wrote its own
  `fl-house-a/<surname>.csv` to avoid a concurrent-write race on one shared file;
  merged + RFC-4180-validated into the batch CSV (all 186 rows valid).
- **Embedded scale via a shared file** (`fl-house-a/_TOPIC_SCALE.txt`, fetched live
  from `inform.compass_topics`) that each agent Reads — satisfies the "use fresh DB
  texts, never hardcoded direction" rule far more token-efficiently than re-embedding.
- **politician_id resolved by external_id→UUID map** (not name) — robust against
  name variants ("John H. Rutherford", "Gus M. Bilirakis").
- **Source-access note for batch B:** house.gov / congress.gov / govtrack /
  clerk.house.gov consistently return 403 to WebFetch. Productive sources were
  Ballotpedia, OnTheIssues (FL/ pages), Wikipedia, LCV scorecard. Several Ukraine /
  redistricting topics were skipped because the specific roll-call vote couldn't be
  confirmed from an accessible URL — correct per the no-guessing rule.

## Reusable artifacts for 127-02

- `backend/data/stance-research/fl-house-a/_TOPIC_SCALE.txt` — the 25-topic federal scale
- `backend/data/stance-research/fl-house-a/_push_quotes_a.ts` — quote-push script
  (swap the PID map + CSV path for batch B)
