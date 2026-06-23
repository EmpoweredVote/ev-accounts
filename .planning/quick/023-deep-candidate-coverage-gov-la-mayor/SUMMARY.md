---
slug: deep-candidate-coverage-gov-la-mayor
status: complete
completed: 2026-06-23
---

# Summary: Deep candidate coverage — CA Governor + LA Mayor head-to-heads

## Outcome
Filled stance coverage to the full per-office tier (where evidence exists) for the four
candidates in two marquee 2026 California races, and replaced two headshots from a single
user-supplied dual portrait. All stance rows are evidence-only (real fetched URLs);
gaps with no genuine source are documented honest-skips, never inferred.

## What shipped

**Stances pushed (11 net-new, sourced):**
- **Steve Hilton (R, Gov)** — `external_id -6003003`: +7 state-tier topics
  (jail-capacity 5, rent-regulation 5, economic-development 5, growth-and-development 5,
  medicare/aid 4, transportation-priorities 4, childcare 4). Now **23/26** state topics.
  Honest-skip (no documented position found): campaign-finance, religious-freedom, same-sex-marriage.
- **Xavier Becerra (D, Gov)** — `external_id -6003001`: +4 state-tier topics
  (economic-development 3, growth-and-development 4, jail-capacity 2, rent-regulation 3).
  Now **24/26** state topics. Honest-skip: misinformation, transportation-priorities.
- **Karen Bass (LA Mayor, incumbent)** — `external_id 683865`: 0 net-new. Both gap topics
  (data-centers, jail-capacity) honest-skipped — no city-mayoral record exists; jails are a
  county/sheriff function. Stays **20/22** local-tier (already near-complete).
- **Nithya Raman (LA Mayor)** — `external_id 695261`: 0 net-new. All four gap topics
  (data-centers, jail-capacity, religious-freedom, trans-athletes) honest-skipped — no
  documented councilmember position. Stays **18/22** local-tier.

Each pushed row wrote `politician_answers` (value) + `politician_context` (reasoning + sources[])
+ a `quotes` row with de-identified text selected for the blind compare view. 0 surname leaks.

**Headshots replaced (2), from user-supplied `C:\tmp\Steve Hilton and Becerra.jpg`:**
- Split the 1600×900 dual portrait into two 4:5 crops → resized 600×750 → upserted to
  Supabase storage at the canonical `{politician_id}-headshot.jpg` path (overwrote stale images).
- Hilton: clean studio portrait (was a stale Ballotpedia photo). Becerra: campaign-backdrop portrait.
- Both `photo_license` set to `press_use`; `photo_origin_url` set to each campaign site; URLs
  cache-busted with `?v=20260623`.

## Why the LA Mayor side produced no net-new stances
Both mayors were already near-complete on local-tier topics. Their remaining gaps are topics
that genuinely fall outside a city mayor's record (jails = county; data-centers, trans-athletes,
religious-freedom = no documented municipal position). Per project standard
([[feedback_stance_no_assumption]]) these are honest-skipped, not guessed. The Bass↔Raman
head-to-head was already strong (~18–20 shared local topics with sourced reasoning).

## Method
Reused the project stance pipeline: 4 `politician-stance-researcher` agents (3 concurrent,
1 follow-up) each handed only its gap topics + the DB-derived 1–5 scale texts in
`backend/data/stance-research/quick-candidates-2026/_TOPIC_SCALE.txt`; per-candidate CSVs →
`_push.ts` (copied verbatim from `exec-w2-batch-a`) → prod upsert. Coverage re-verified by SQL.

## Verification
- Governor state-tier matrix re-queried post-push: Hilton 23/26, Becerra 24/26; all 52 context
  rows have non-empty reasoning + ≥1 source (0 bad).
- Image rows confirmed `press_use` + cache-busted URLs for both.

## Files
- `backend/data/stance-research/quick-candidates-2026/` — `_TOPIC_SCALE.txt`, `hilton.csv`,
  `becerra.csv`, `bass.csv` (header-only), `raman.csv` (header-only), `_push.ts`,
  `headshots/` (source dual + two finals).
