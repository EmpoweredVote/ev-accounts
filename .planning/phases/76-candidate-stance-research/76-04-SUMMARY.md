---
plan: 76-04
status: complete
commit: a168e49
---

# Plan 76-04 Summary — Appointed Senator Gap-Fill (Armstrong OK + Husted OH)

## What Was Done

Researched and ingested gap-fill stance data for the two appointed incumbent
senators: Alan Armstrong (OK, seated 2026-03-24) and Jon Husted (OH, seated
2025-01). Both had stances from Phase 74 but were missing topics that had
no evidence at that time.

**Task 1: Research (CSVs)**
- `backend/data/stance-research/2026-05-22-armstrong-gapfill.csv` — 3 stances
- `backend/data/stance-research/2026-05-22-husted-gapfill.csv` — 6 stances
- Total: 9 new stance rows

**Task 2: Migration 210**
- File: `backend/migrations/210_appointed_senator_gapfill_stances.sql`
- Applied via psql to remote Supabase
- Generated from CSVs via `gen_migration.py` (GAPFILL_CANDIDATES batch added)
- Committed in `a168e49`

## Per-Senator Before/After

| Senator | State | Party | Before | After | New Topics |
|---------|-------|-------|--------|-------|------------|
| Alan Armstrong | OK | R | 14 | 17 | trans-athletes, judicial-interpretation, judicial-criminal-justice |
| Jon Husted | OH | R | 24 | 30 | housing, homelessness, homelessness-response, jail-capacity, judicial-criminal-justice, judicial-interpretation |

## Topics Filled vs. Skipped

### Alan Armstrong (OK) — 3 filled, 13 skipped

**Filled:**
- `trans-athletes` (4) — Voted YEA on S.1383 procedural motions (votes 67+68, March 24 2026, his first day seated)
- `judicial-interpretation` (4) — Unanimous YEA on all Trump Federalist Society judicial nominees (Wolfe, Davis, Shepherd, Clarke — April-May 2026)
- `judicial-criminal-justice` (4) — Same judicial confirmations + ATF Director (Cekada, v109, April 29 2026)

**Skipped (no usable evidence):**
ai-regulation, campaign-finance, civil-rights, economic-development, homelessness,
homelessness-response, jail-capacity, misinformation, public-safety-approach, redistricting,
religious-freedom, same-sex-marriage, school-vouchers

**Reason for skips:** Armstrong was seated March 24, 2026. Comprehensive scan of
119th Congress 2nd session votes 66–130 confirmed no floor votes on any of
these 13 topics during his first ~2 months. His senate.gov bio page 404s;
Ballotpedia and OTI returned empty content. All 14 original topics were
already in DB from Phase 74.

### Jon Husted (OH) — 6 filled, 0 skipped

- `housing` (4) — YEA on H.R. 6644 (supply-side housing bill, 89-10, March 12 2026); NAY on hedge fund homeownership amendment (April 23 2026)
- `homelessness` (4) — "Protect people, property" philosophy; backed Protect and Serve Act; no decriminalization advocacy
- `homelessness-response` (4) — Enforcement-priority orientation; no housing-first advocacy
- `jail-capacity` (4) — YEA on U.S. Marshals Director confirmation (Session 1, v460); no prison diversion support
- `judicial-criminal-justice` (4) — "Cannot go back to Biden's dangerous policies of high crime"; YEA on Kash Patel for FBI; backed Protect and Serve Act
- `judicial-interpretation` (4) — YEA on all Trump judicial nominees including LaCour, Maxwell, Chamberlin, Bragdon, Rikhye (party-line 51-47 to 53-45 votes)

## 119th Congress 2nd Session Evidence (SRES-03)

**Alan Armstrong — representative 2nd session URL:**
`https://www.senate.gov/legislative/LIS/roll_call_votes/vote1192/vote_119_2_00067.htm`
(S.1383 procedural vote, March 24 2026 — trans-athletes)

**Jon Husted — representative 2nd session URL:**
`https://www.senate.gov/legislative/LIS/roll_call_lists/roll_call_vote_cfm.cfm?congress=119&session=2&vote=00053`
(H.R. 6644 housing bill final passage, March 12 2026 — housing)

SRES-03 satisfied: both senators have at least one 119th Congress 2nd session vote citation.

## Verification Results

- Armstrong: 14 → 17 stances ✓ (>= 15 required)
- Husted: 24 → 30 stances ✓ (>= 25 required, full 30-topic coverage achieved)
- 0 unpaired answers ✓
- 0 empty sources ✓
- Both senators have 119th 2nd session evidence ✓
- Idempotency: migration applied twice, counts unchanged ✓

## Notable Issues

- **Researcher misidentification on first attempt:** The first researcher agent
  confused "Kelly Armstrong" (ND Governor) with "Alan Armstrong" (OK Senator).
  The bad CSV was deleted and a fresh agent was dispatched with explicit
  disambiguation. Alan Armstrong is a former Williams Companies CEO with no
  prior elected office — his pre-Senate record is nearly empty, which is why
  only 3 of 16 gap topics had usable evidence.

## Phase 76 Full Verification (SC-1 through SC-5)

| Check | Result | Notes |
|-------|--------|-------|
| SC-1: Phase 75 candidates >= 10 stances | ⚠ 1 exception | James Byrd (WY, D) has 5 stances — documented floor case; announced candidacy Feb 2026 with almost no public policy record |
| SC-2: Every stance has paired context + source | ✓ 0 gaps | |
| SC-3: Armstrong >= 15, Husted >= 25 | ✓ Armstrong=17, Husted=30 | |
| SC-4: 119th 2nd session evidence for both | ✓ 2 rows | Armstrong=17 rows, Husted=3 rows with session=2 URLs |
| SC-5: FK chain (NATIONAL_UPPER) | ✓ 5 rows sampled | All resolve correctly |

SC-1 technically fails due to James Byrd. All available evidence was used;
fabrication was not acceptable. This is a data availability limitation, not
a process failure.

## Migration Numbers

- Migration consumed: 210
- Next available: 211
