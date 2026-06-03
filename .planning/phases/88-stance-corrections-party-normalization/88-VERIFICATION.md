---
phase: 88-stance-corrections-party-normalization
verified: 2026-06-03T00:00:00Z
status: human_needed
score: 7/9 must-haves verified
overrides_applied: 0
human_verification:
  - test: "Verify Derek Dooley (b841a475) stance reasoning quality and source accuracy"
    expected: "Dooley's 7 corrected stances should cite his actual Senate campaign positions, not the Wikipedia page for Derek Dooley the football coach (en.wikipedia.org/wiki/Derek_Dooley_(American_football)). Multiple reasoning entries rely on 'conservative Republican candidate' description without specific documented positions."
    why_human: "Cannot programmatically verify whether dooleyforgeorgia.com campaign page content supports each specific stance value, or whether an alternative Wikipedia URL exists for the Senate candidate. Requires browser lookup."
  - test: "Verify Brian W. Jones ukraine-support stance remains flagged / acceptable"
    expected: "Brian W. Jones (CA state senator) has ukraine-support=2 with reasoning that uses prohibited party-inference language ('he likely supports'). The Phase 88 executor documented this as unresolved (no direct evidence found). Determine whether to leave as-is, remove the stance, or flag for future re-search."
    why_human: "The executor explicitly documented this as an unverified inference remaining in the DB. It is a known SACC-02 violation. Human must decide disposition — leave flagged, remove, or accept the gap."
---

# Phase 88: Stance Corrections + Party Normalization Verification Report

**Phase Goal:** Close SACC-02 (re-research and correct all confirmed-inversion politicians from Phase 87 audit) and SACC-03 (normalize party strings in essentials.politicians so 'Democrat' and 'Democratic' are unified as 'Democratic').
**Verified:** 2026-06-03T00:00:00Z
**Status:** human_needed
**Re-verification:** No — initial verification

---

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | All 8 Tier 1 confirmed-inversion politicians have correction migrations applied (116-123) | VERIFIED | Migrations exist on disk; DB shows diverse value distributions for all 8 UUIDs; 0 orphan context rows |
| 2 | All 8 Tier 1 corrections have paired politician_context rows with sources array >= 1 | VERIFIED | DB query: `SELECT COUNT(*) FROM inform.politician_context WHERE politician_id IN (...8 Tier 1 UUIDs...) AND sources IS NULL OR array_length = 0` returns 0 |
| 3 | All 21 Tier 2 borderline politicians have a documented per-politician disposition with rationale | VERIFIED | 88-03-TIER2-DETERMINATIONS.md contains all 21 names; `disposition:` appears 21 times; MA cluster investigation section present |
| 4 | All 25 Republicans with ukraine-support=2 individually verified; 4 corrections applied in migration 125 | VERIFIED | 88-04-UKRAINE-DETERMINATIONS.md has 25 sections; ukraine-republicans.csv has 25 rows fully populated; DB confirms all 4 corrected politicians now at value=4 with non-empty sources |
| 5 | Tier 2 stub migration 124 exists | VERIFIED | File present: `supabase/migrations/20260603000009_124_tier2_borderline_corrections.sql`; contains `SELECT 1` no-op with comment block |
| 6 | Zero corrections rely on party-affiliation inference in CSV research files | UNCERTAIN | Batch-A CSV is clean. Batch-B CSV contains some borderline patterns: Grayson "As a California Democrat" descriptions accompany specific bill votes (acceptable); Dooley's healthcare entry is "As a conservative Republican Georgia Senate candidate…" with no specific bill vote cited (borderline). Most entries are source-backed but Dooley's entries are thin. |
| 7 | SACC-03: SELECT COUNT(*) FROM essentials.politicians WHERE party = 'Democrat' returns 0 | VERIFIED | DB query confirmed: returns 0. Democratic count = 775 (preserved from pre-migration 495+280) |
| 8 | Derek Dooley's politician_context sources are accurate (not football-coach Wikipedia page) | FAILED | All 7 Dooley context entries cite `https://en.wikipedia.org/wiki/Derek_Dooley_(American_football)` — a page for the Tennessee Volunteers football coach, not the 2026 Georgia Senate candidate. The wrong source is persisted to the live DB for all 7 stance rows. |
| 9 | Brian W. Jones ukraine-support stance is free of party-inference language | FAILED | Phase 88-04 executor documented: Jones's original context "explicitly states 'he likely supports continued aid'" — a SACC-02-prohibited party-inference formulation. No correction was applied because no direct evidence was found. The unverified inference remains in the DB. |

**Score:** 7/9 truths verified

---

## Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `data/stance-research/2026-06-02-tier1-batch-a.csv` | Batch A research (Gonzalez, Niello, Nixon, Vindman) | VERIFIED | 38 lines; Gonzalez:10, Niello:10, Nixon:9, Vindman:8 rows |
| `backend/data/stance-research/2026-06-02-tier1-batch-b.csv` | Batch B research (Grayson, Hinson, Dooley, Hinojosa) | VERIFIED (WARNING) | 38 lines; Grayson:13, Hinson:10, Dooley:7, Hinojosa:7; trailing empty column on data rows (WR-01 in REVIEW.md) |
| `supabase/migrations/20260603000001_116_jeff_gonzalez_inversion_correction.sql` | Gonzalez corrections | VERIFIED | BEGIN/COMMIT; 10 UPDATE+upsert pairs; UUID 5ad32852 present; sources arrays populated |
| `supabase/migrations/20260603000002_117_roger_niello_inversion_correction.sql` | Niello corrections | VERIFIED | BEGIN/COMMIT; 10 UPDATE+upsert pairs; UUID 22152e41 present |
| `supabase/migrations/20260603000003_118_angie_nixon_inversion_correction.sql` | Nixon corrections | VERIFIED | BEGIN/COMMIT; 9 UPDATE+upsert pairs; UUID 0ac89151 present |
| `supabase/migrations/20260603000004_119_alex_vindman_inversion_correction.sql` | Vindman corrections | VERIFIED | BEGIN/COMMIT; 8 UPDATE+upsert pairs; UUID a2fee754 present |
| `supabase/migrations/20260603000005_120_tim_grayson_inversion_correction.sql` | Grayson corrections | VERIFIED | BEGIN/COMMIT; UUID 29389f8b; DB shows v1:1, v2:9, v3:2, v4:1 |
| `supabase/migrations/20260603000006_121_ashley_hinson_inversion_correction.sql` | Hinson corrections | VERIFIED | BEGIN/COMMIT; UUID bd20ceb6; DB shows v2:1, v4:10 |
| `supabase/migrations/20260603000007_122_derek_dooley_inversion_correction.sql` | Dooley corrections | STUB (wrong sources) | BEGIN/COMMIT; UUID b841a475; value corrections applied to DB; but all 7 context rows cite wrong Wikipedia URL (football coach page, not Senate candidate) |
| `supabase/migrations/20260603000008_123_adam_hinojosa_inversion_correction.sql` | Hinojosa corrections + party | VERIFIED | BEGIN/COMMIT; party UPDATE as first statement; UUID 0c6c482a; DB confirms party='Republican', v4:5, v5:1 |
| `data/stance-research/2026-06-03-tier2-ma-cluster-investigation.csv` | MA cluster investigation | VERIFIED | 33 lines; 12 politicians across 3 topics |
| `data/stance-research/2026-06-03-tier2-corrections.csv` | Tier 2 corrections CSV | VERIFIED | 1 line (header only — no corrections needed) |
| `.planning/phases/88-stance-corrections-party-normalization/88-03-TIER2-DETERMINATIONS.md` | 21 per-politician dispositions | VERIFIED | All 21 politicians present; 21 `disposition:` entries; MA Cluster Investigation section present; CONFIRMED_CENTRIST label documented |
| `supabase/migrations/20260603000009_124_tier2_borderline_corrections.sql` | Tier 2 stub migration | VERIFIED | `SELECT 1` no-op with explanatory comment block |
| `data/stance-research/2026-06-03-ukraine-republicans.csv` | Ukraine-R verification worksheet | VERIFIED | 25 rows; all have researched_value, source_url_1, disposition populated; verified-correct:20, value-changed:4, insufficient-evidence:1 |
| `.planning/phases/88-stance-corrections-party-normalization/88-04-UKRAINE-DETERMINATIONS.md` | 25 per-politician Ukraine determinations | VERIFIED | 25 `### N.` sections; per-politician rationale + sourced roll call votes |
| `supabase/migrations/20260603000010_125_ukraine_support_republican_corrections.sql` | Ukraine 4 corrections | VERIFIED | BEGIN/COMMIT; scoped to `ukraine-support` topic key; 4 politicians corrected; sources arrays populated; DB confirms all 4 at value=4 |
| `supabase/migrations/20260603000011_126_party_string_normalization.sql` | Party normalization | VERIFIED | Single `UPDATE essentials.politicians SET party = 'Democratic' WHERE party = 'Democrat'`; BEGIN/COMMIT; DB confirms 0 'Democrat' rows, 775 'Democratic' |

---

## Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| Migration 116-119 | `inform.politician_answers` | Bare UPDATE by politician_id + topic_id subquery | WARNING (CR-01) | UPDATE succeeds when row pre-exists (confirmed by DB). But bare UPDATE silently no-ops if row missing — no INSERT fallback. DB state is correct for current environment; risk is replay on fresh DB. |
| Migration 116-119 | `inform.politician_context` | INSERT ON CONFLICT upsert with sources array | VERIFIED | Upsert pattern used correctly; 0 orphan context rows confirmed by DB query |
| Migration 120-123 | `inform.politician_answers` | Same bare UPDATE pattern (same CR-01 risk) | WARNING | Applied correctly; DB values confirmed |
| Migration 123 | `essentials.politicians` | `UPDATE essentials.politicians SET party = 'Republican'` | VERIFIED | DB confirms Hinojosa party = 'Republican' |
| Migration 125 | `inform.politician_answers` | Bare UPDATE for 4 ukraine-Rs | WARNING (CR-01) | Same pattern; DB confirmed correct (all 4 at value=4) |
| Migration 126 | `essentials.politicians` | `UPDATE SET party = 'Democratic' WHERE party = 'Democrat'` | VERIFIED | DB: 0 Democrat rows; 775 Democratic rows |
| TIER2-DETERMINATIONS.md | Migration 124 | All 21 dispositions = correct-as-is → stub migration | VERIFIED | Stub migration exists with comment citing the determination document |
| UKRAINE-DETERMINATIONS.md | Migration 125 | 4 value-changed politicians → correction migration | VERIFIED | Migration contains exactly the 4 corrected UUIDs from determinations |

---

## Data-Flow Trace (Level 4)

Not applicable. Phase produces data migrations and research artifacts, not rendering components. No dynamic data rendering path to trace.

---

## Behavioral Spot-Checks

| Behavior | Result | Status |
|----------|--------|--------|
| `SELECT COUNT(*) FROM essentials.politicians WHERE party = 'Democrat'` | 0 | PASS |
| `SELECT DISTINCT party FROM essentials.politicians WHERE party ILIKE 'democra%'` | ['Democratic'] | PASS |
| Hinojosa party in DB | 'Republican' | PASS |
| Ukraine 4 politicians (Barrasso, Blackburn, Obernolte, Collins) all at value=4 | Confirmed | PASS |
| 0 orphan context rows for all 8 Tier 1 politicians | 0 | PASS |
| All 8 Tier 1 value distributions are diverse (not monotonic) | Confirmed (all have 2+ distinct values) | PASS |
| Tier 2 corrections CSV header-only (no corrections needed) | 1 line | PASS |
| Ukraine CSV: 25 rows fully populated | 25 rows with researched_value + source + disposition | PASS |

---

## Requirements Coverage

| Requirement | Source Plan(s) | Description | Status | Evidence |
|-------------|---------------|-------------|--------|----------|
| SACC-02 | 88-01, 88-02, 88-03, 88-04 | All politicians with accuracy issues re-researched with real sources and corrected via migration(s) | PARTIAL | 8 Tier 1 corrections verified + 21 Tier 2 all correct-as-is + 4 Ukraine Rs corrected. Gap: Derek Dooley's 7 context rows cite wrong Wikipedia page (football coach) — sourcing is wrong though values may be correct. Brian W. Jones ukraine-support entry has prohibited party-inference language left in DB (executor documented but did not fix). |
| SACC-03 | 88-05 | Party string inconsistency resolved — no mixed 'Democrat'/'Democratic' entries | VERIFIED | DB: 0 'Democrat' rows; 775 'Democratic'; all other party counts unchanged |

---

## Anti-Patterns Found

| File | Pattern | Severity | Impact |
|------|---------|----------|--------|
| `supabase/migrations/20260603000007_122_derek_dooley_inversion_correction.sql` (all 7 context upserts) | Wrong source URL: `en.wikipedia.org/wiki/Derek_Dooley_(American_football)` cited for all 7 Dooley stances | BLOCKER | The URL is for a football coach, not the Georgia Senate candidate. All 7 of Dooley's `inform.politician_context` source arrays in the live DB contain this incorrect URL. |
| `inform.politician_context` (Brian W. Jones, ukraine-support) | "he likely supports continued aid" — party-inference language documented as present in existing context row | WARNING | SACC-02 prohibits party-inference language in context rows. Executor documented this but left value and context unchanged. |
| Migrations 116-119, 125 | Bare `UPDATE inform.politician_answers` with no INSERT fallback (CR-01) | WARNING | Silent no-op if `politician_answers` row doesn't pre-exist (e.g., fresh environment). Current DB is correct but pattern is not self-healing. |
| `backend/data/stance-research/2026-06-02-tier1-batch-b.csv` | Trailing empty column on all data rows (8 fields vs 7-column header) | INFO | CSV parsers enforcing strict column count will fail. Does not affect the DB since migration content was manually written, not auto-parsed from the CSV. |

---

## Human Verification Required

### 1. Derek Dooley Source Correction

**Test:** Open `https://en.wikipedia.org/wiki/Derek_Dooley_(American_football)` and confirm it is the football coach page, not the Georgia 2026 Senate candidate. Then search for the correct Wikipedia page or reliable source for Derek Dooley the Senate candidate and determine whether one exists.

**Expected:** Either (a) a correct Wikipedia URL is found and a follow-up migration updates all 7 Dooley context rows with the correct sources array, or (b) no Wikipedia page exists for the Senate candidate, in which case the sources arrays should be updated to use only `https://dooleyforgeorgia.com/` and any other directly-cited campaign sources.

**Why human:** Cannot verify whether `https://dooleyforgeorgia.com/` content actually supports each specific stance value assignment (abortion=4, civil-rights=4, climate-change=4, healthcare=4, immigration=4, taxes=4, voting-rights=4). Requires browser review of the campaign site. The value corrections themselves (2→4) appear plausible for a Georgia Republican candidate but the sourcing is the open question.

---

### 2. Brian W. Jones Ukraine-Support Party-Inference Disposition

**Test:** Check the current `inform.politician_context` entry for Brian W. Jones on the `ukraine-support` topic. Confirm the existing reasoning text contains "he likely supports continued aid" (or similar prohibited language). Decide: (a) remove the stance + context row entirely since no real source was found, (b) leave as-is and accept the gap with a note, or (c) attempt additional research.

**Expected:** A resolution to the open SACC-02 violation documented in 88-04-SUMMARY.md. The executor confirmed this politician's original context contained party-inference language and could not find direct evidence to replace it.

**Why human:** This is a judgment call about acceptable data quality. Removing the row entirely is safe (the politician has no verified position on this topic). Leaving it is pragmatically acceptable if coverage is prioritized over accuracy for state-level politicians on federal topics. The executor surfaced but did not close it — human decision required.

---

## Gaps Summary

Two gaps block full SACC-02 closure:

1. **Derek Dooley wrong source URL (all 7 context rows)**: The live DB contains factually wrong Wikipedia sourcing for a Georgia Senate candidate's political stances. The values assigned (all value=4) may be correct but the sourcing documentation is wrong. A follow-up migration correcting the sources arrays is needed. This is a data integrity issue, not just a documentation issue — users and auditors consulting these context rows will see a link to a football coach as the evidence for a politician's positions.

2. **Brian W. Jones party-inference in ukraine-support context**: A single context row for a CA state senator contains "likely supports" language — the exact pattern SACC-02 prohibits. The executor documented it and explicitly left it unresolved. Human disposition decision needed before SACC-02 can be fully closed.

Both gaps relate to SACC-02 (not SACC-03). SACC-03 is fully closed.

---

_Verified: 2026-06-03T00:00:00Z_
_Verifier: Claude (gsd-verifier)_
