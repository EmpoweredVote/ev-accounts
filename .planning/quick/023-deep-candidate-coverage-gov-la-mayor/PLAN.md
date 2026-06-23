---
slug: deep-candidate-coverage-gov-la-mayor
created: 2026-06-23
status: in-progress
---

# Quick Task: Deep candidate coverage — CA Governor + LA Mayor head-to-heads

## Goal
Give voters rich, sourced, head-to-head-comparable information on two marquee 2026
California races. Fill each candidate's stance coverage to the full topic set for
their office tier so the compass comparison view shows both candidates on every
relevant issue, and refresh Steve Hilton's stale headshot.

## Scope (4 candidates, 2 races)

**CA Governor (state-tier = 26 topics; bring both to full):**
- Steve Hilton (R) — `external_id -6003003`, UUID `9a60d603-194d-410f-ae01-85bd6293f1a7`
  - Currently 16/26 state topics. Missing 10: campaign-finance, childcare,
    economic-development, growth-and-development, jail-capacity, medicare/aid,
    religious-freedom, rent-regulation, same-sex-marriage, transportation-priorities
  - PLUS fresh headshot (current = stale Ballotpedia image)
- Xavier Becerra (D) — `external_id -6003001`, UUID `0f74219c-7d10-4d29-85fe-0f1d834df8a7`
  - Currently 20/26 state topics. Missing 6: economic-development,
    growth-and-development, jail-capacity, misinformation, rent-regulation,
    transportation-priorities

**LA Mayor (local-tier = 22 topics; bring both to full):**
- Karen Bass (incumbent) — `external_id 683865`, UUID `21c9e711-fb18-4afb-884f-08acd2b598ba`
  - Currently 20/22 local topics. Missing 2: data-centers, jail-capacity
- Nithya Raman — `external_id 695261`, UUID `26dbe16a-9dff-42c0-939f-5b5e529063ca`
  - Currently 18/22 local topics. Missing 4: data-centers, jail-capacity,
    religious-freedom, trans-athletes

Total: ~22 net-new sourced stances + 1 headshot.

## Method (reuses project stance pipeline)
1. Dispatch `politician-stance-researcher` agents (≤3 concurrent per [[feedback_stance_research_one_at_a_time]]),
   one per candidate, each handed ONLY its gap topics + the embedded 1-5 scale texts
   from `_TOPIC_SCALE.txt`. Evidence-only — every row needs a real fetched URL; honest-skip
   any topic with no genuine evidence ([[feedback_stance_no_assumption]]).
2. Each agent writes a CSV: `<candidate>.csv` with columns
   `full_name,external_id,topic_key,value,reasoning,source_url_1,source_url_2,source_url_3,quote_text,quote_deidentified`.
3. Refresh Steve Hilton headshot via `find-headshots`.
4. Push via a `_push.ts` modeled on existing pipeline scripts (answers + context + quotes,
   ON CONFLICT upsert).
5. Verify: re-run the per-candidate tier coverage matrix; confirm gaps closed (minus any
   documented honest-skips), 0 unsourced.

## Out of scope
- Existing already-sourced stances are left intact (not re-researched).
- Other 38 Governor candidates / 12 LA Mayor candidates.
- Mayor candidates on state/federal-only topics; Governors on local-only topics.

## Files
- `backend/data/stance-research/quick-candidates-2026/` — scale ref, CSVs, push script
