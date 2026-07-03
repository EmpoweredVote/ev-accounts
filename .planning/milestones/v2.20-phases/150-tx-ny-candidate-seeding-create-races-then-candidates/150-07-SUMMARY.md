# 150-07 SUMMARY — TX-1..10 federal-24 stances (Playwright-verified)

**Status:** ✅ Complete
**Wave:** 3 (executed inline per operator pacing decision — wave 3 plans 08–11 remain)
**Requirement:** USHC-05 (TX batch 1 of 4)

## Method (validated, repeatable for 150-08..11)

Orchestrator-run **Playwright**, single shared browser, sequential — NOT subagent dispatch. WebFetch
is 403/Cloudflare-walled on every primary stance source (Ballotpedia, congress.gov, house.gov,
local news); `politician-stance-researcher` agents fall back to aggregators and over-read (documented
149/PROGRESS finding). Playwright bypasses the walls. Per candidate:
- **Incumbents:** Ballotpedia member **"Key votes"** (119th-Congress roll calls) → map ONLY Yea votes
  to chairs (chairs-not-polarity: a Nay does not pin a chair). For the lone TX-1..10 Democratic
  incumbent (Fletcher), Key votes were all Nay → used her **house.gov issue pages** for positive
  stated positions instead.
- **Challengers:** Ballotpedia **Candidate Connection survey** (self-reported; hidden answers read via
  DOM `textContent`) or the **"campaign website stated the following"** quote block. Campaign-site
  quotes on Ballotpedia are the citable source.

Every value = the exact scale position the fetched evidence supports; per-topic honest-skip where the
source states no position; whole-record skip where no fetchable record. **0 party inference.**

## In-scope set: 20 candidates (7 incumbents + 13 new challengers)

**0 unsourced** for all 20 pids (USHC-05a slice PASS). 19 stanced + 1 whole-record honest-skip.

### New this session — 64 stances across 13 candidates (`_push.ts`, external_id path, 0 surname leaks)
| pid | candidate | n | topics |
|-----|-----------|---|--------|
| -100307 | Lizzie Fletcher (D, TX-7) | 5 | abortion2, immigration2, healthcare2, climate3, fossil3 (Houston-Dem chairs-not-polarity: climate/fossil=3 not 1/2) |
| -4810201 | Shaun Finnie (D, TX-2) | 4 | tariffs1, abortion2, social-security3, medicare/aid3 |
| -4810301 | Evan Hunt (D, TX-3) | 7 | healthcare2, immigration3, deportation3, school-vouchers1, campaign-finance2, childcare2, housing2 |
| -4810401 | Jason Pearce (D, TX-4) | 10 | taxes1, medicare/aid1, healthcare2, housing2, campaign-finance1, redistricting1, voting-rights2, ai3, childcare2, social-security2 |
| -4810501 | Chelsey Hockett (D, TX-5) | 8 | abortion2, healthcare2, immigration2, ai4, voting-rights2, school-vouchers1, social-security2, civil-rights2 |
| -4810601 | Danny Minton (D, TX-6) | 7 | healthcare2, school-vouchers1, taxes2, immigration3, deportation3, voting-rights2, redistricting1 |
| -4810701 | Alexander Hale (R, TX-7) | 4 | fossil-fuels4, immigration4, school-vouchers4, taxes4 |
| -4810801 | Jessica Steinmann (R, TX-8) | 4 | immigration4, religious-freedom4, trans-athletes4, civil-rights4 |
| -4810802 | Laura Jones (D, TX-8) | 2 | healthcare1, childcare2 |
| -4810901 | Leticia Gutierrez (D, TX-9) | 1 | immigration2 |
| -4810902 | Alex Mealer (R, TX-9) | 4 | immigration4, trans-athletes4, taxes4, fossil-fuels4 |
| -4811001 | Chris Gober (R, TX-10) | 3 | immigration4, voting-rights4, taxes4 |
| -4811002 | Caitlin Rourk (D, TX-10) | 5 | healthcare2, childcare2, taxes2, abortion2, ai3 |

### Pre-existing, verified-sourced this session (not re-researched)
- **5 GOP incumbents** Moran -100301 / Self -100303 / Fallon -100304 / Gooden -100305 / Ellzey -100306:
  4 roll-call-backed stances each (deportation4, voting-rights4, trans-athletes4, taxes4 — Laken
  Riley / SAVE / Women&Girls-in-Sports / 2025 reconciliation Yea votes). The other 20 federal topics
  are **honest per-topic skips** — Ballotpedia "Key votes" maps cleanly only to those 4; issues-page
  enrichment deferred (gate floor already met). Pushed in a prior session.
- **Steve Toth -100515** (TX-2 active, reuse): 14 stances from his state-rep record — confirmed
  0-unsourced this session (USHC-05a satisfied).

## Honest-skips (pinned for the gate)
- **Whole-record:** Yolanda Prince -4810101 (TX-1, D) — no completed Candidate Connection survey, no
  Ballotpedia campaign-site quote; KETK/nbcrightnow coverage Cloudflare-walled on every fetch attempt;
  party-inference refused. **Pinned by UUID `e6908ff7-834c-4078-9e35-593d000982dd` in `_stance_skip`**
  of `scripts/150-verify.sql` (WITH ORDER BY, 143 lesson).
- **Per-topic:** pervasive and expected (chairs-not-polarity) — e.g. climate skipped where a candidate
  only signaled concern without a policy chair (Hockett, Jones, Rourk); same-sex-marriage skipped on
  general-LGBTQ statements with no marriage-specific position (Jones — 149 over-read lesson).

## Verification
- Rows deleted in primary-source pass: **0** — values were mapped conservatively from the fetched
  source at write time (no speculative rows created), so no over-reads required deletion.
- Merge/repair: `_merge_validate.mjs` (149 relax-parse + canonical re-stringify + source_url_1
  alignment guard) — 13 CSVs → 64 rows, 0 issues, 0 dup (external_id,topic_key).
- Gate slice: 0 unsourced for all 20 TX-1..10 pids.

## Files
- `backend/data/stance-research/tx-2026-house-b1/` — 13 per-candidate CSVs + `tx-b1-new-batch.csv`
  (merged) + `_merge_validate.mjs` (gitignored scratch; DB is source of truth).
- `backend/scripts/150-verify.sql` — Prince pinned in `_stance_skip`.

## Remaining in Wave 3 (deferred per pacing decision)
150-08 (TX-11..20), 150-09 (TX-21..30), 150-10 (TX-31..38 incl. Casar + Barrios top-up), 150-11 (NY new 33). Then 150-12 (Wave 4 coordinate gate).
