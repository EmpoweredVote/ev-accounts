# 159-02 SUMMARY — MI new-candidate headshots + federal-24 stances

**Status: COMPLETE ✅ 2026-07-02** (resumed from pre-merge checkpoint after power loss; USHC2-04 + USHC2-05 MI slice delivered)

## Final tallies (in-scope = 56 new MI candidates, external_id -260101..-261307)

- **Stanced: 46 candidates / 344 answer rows / 0 unsourced** (every answer paired to `inform.politician_context` with non-empty sources[]) — USHC2-05a MI slice PASS
- **Whole-record stance honest-skips: 10** (pinned below for 159-06 gate)
- **Quotes: 192 inserted, 192 readrank-selected, 0 surname leaks**
- **Headshots: 4 attached / 52 honest-skips** (Brink -260701, Moss -261103, McKinney -261302, Waters -261303; Bouchard -261004 was attached in the first pass and **REVERTED — wrong person**, see incidents)
- **All 13 MI incumbents untouched** (band query ≤ -260101 excludes them by construction; pre/post counts confirmed)

## Whole-record stance honest-skips (pin in 159-verify.sql)

| external_id | pid | name | reason |
|---|---|---|---|
| -260104 | a5cfcdfd-b283-45d4-9219-10f96d9120c3 | Matthew DenOtter | only row (abortion) deleted in verification — evidence can't distinguish scale 4 vs 5 |
| -260107 | c7f8c3fc-f71a-4117-af05-153fd204d801 | Thomas Latza | campaign site set to private (401); FEC committee reg only |
| -260704 | f1c090ce-2c1c-4e43-9fd7-c9da1375935e | Muhammad Salman Rais | 2 candidate-trackers confirm zero disclosed positions; likely off ballot |
| -260803 | 39f08a9e-bfc7-4c97-bdb6-6cc8599b683f | Thomas J. Smith | zero public footprint (no site/FEC/news) despite ballot listing |
| -261104 | b4571244-3613-4005-a368-bbb04b24dc57 | Michelle Mary Murphy | disqualified from primary; no record |
| -261107 | 7e5a7727-e7c9-4c7a-8cee-b2bd29225c43 | Ethan Baker | deliberately policy-free "unity" campaign; Ballotpedia homonym trap avoided |
| -261108 | e6dec5d3-f972-4902-8a29-dfc55f67244a | Tony J. Prieto | campaign site template unfetchable; possibly disqualified |
| -261201 | a0f0857f-0d02-4a99-bef9-b952e9d8846a | Allen Downer | absent from Wikipedia/Ballotpedia race trackers; no domain |
| -261305 | f713af11-d8df-4610-a46a-d0cd1baa36d7 | Raphiel King | disqualified per PredictionEdge; no platform anywhere |
| -261307 | c794d0d1-7c27-4b6d-955c-c84726702d2d | Maurice Morton | single-page NationBuilder values-only site; no subpages |

## Per-candidate stance counts (46 stanced)

barr 20, stiles 11, blomquist 15, michal 3, featherly 8 (MI-1) · ambrose 4, hill 6, welford 5 (MI-2) · cushman 5, deboer 7 (MI-3) · harris-ii 8, mccann 4, tanis 4 (MI-4) · vukasovich 3, bronke 4 (MI-5) · smiley 23, shabazz 1 (MI-6) · brink 10, lawrence 6, maasdam 12, prieditis 3 (MI-7) · hassan 10, lemmo 23 (MI-8) · pooley 9, cartwright 1, valdez 1 (MI-9) · chung 15, greimel 4, bertrand-hines 10, bouchard 2, demetropoulos 1, kirk 2, lulgjuraj 5 (MI-10) · stu-baker 9, farooqi 10, moss 12, torres 12, ufford 13 (MI-11) · jackson 6, nolen 1, hooper 7 (MI-12) · goci 12, mckinney 11, waters 3, bivings 2, nykoriak 1 (MI-13)

## Incidents & lessons (IMPORTANT for 159-04 retro-audit + future phases)

1. **Rate-limit false-skip epidemic.** The pre-power-out session's run left 25 header-only "honest-skip" CSVs. Re-research proved **21 of 25 were FALSE skips** (real fetchable records existed — e.g. Maasdam 12 topics, Blomquist 15, Torres 12+, Farooqi 10). Root causes: session usage-limit kills mid-run (agents die returning limit message), unfetched campaign domains (name-guess ≠ real domain), one URL typo (Maasdam's own site misspells `/priorites/`). **Rule: a header-only CSV from a rate-limited run is NOT a documented honest-skip — only a skip with a written search trail counts.** VA (159-04) CSVs were pushed pre-crash but the same session produced them — spot-audit recommended.
2. **Bouchard wrong-person (father/son homonym).** The 2026 MI-10 candidate is "Captain Mike Bouchard" (Army NG), the SON of Oakland County Sheriff Mike Bouchard. First pass attributed the father's 2006 Senate stances (ontheissues.org) — all 9 rows deleted — and manually attached the father's 2006 photo after the auto-guard **correctly** rejected it on first-name mismatch (manual override was the error; politician_images row + storage object deleted). Son re-researched from bouchardforcongress.com: 2 rows (deportation 4, housing 4). **Lesson: treat guard rejections as signal; never manual-override without confirming the person, not just the name.**
3. **Verification pass yield.** ~60 rows deleted / ~35 fixed across the full corpus (pre-crash batch worst: Moss had bills misattributed to him; Hines/Stiles/Smiley had paraphrases in quote_text presented as verbatim). Recurring rescale: "protect from cuts" = status-quo 3, not expansion 2. Recurring deletion: generic anti-war/anti-Pentagon quotes force-fit onto ukraine-support (3 deleted); GND rhetoric force-fit onto fossil-fuels (2 deleted); absence-of-evidence scored as opposition.
4. **Source intel:** Ballotpedia hard-walled all day (direct empty, r.jina.ai 451); BallotReady = high-value itemized platform summaries; Michigan Advance voter guides work via r.jina.ai and double as ballot-status oracles; `[name]forcongress.com` direct-guess + DDG-via-jina domain discovery beat name-guess domains; Bluesky public JSON API bypasses JS walls.

## Ballot-status flags → carry-forward to 159-05 cull (do NOT act before Aug-5)

Disqualified/off-ballot signals found during research (verify against official MI SoS results at cull time): **Prieto (-261108), Goci (-261301), King (-261305), Murphy (-261104), Stu Baker (-261101) disqualified; Rais (-260704) off-ballot.** Michigan Advance MI-11 guide lists only E. Baker/Farooqi/Moss/Torres/Ufford.

## Artifacts

- `backend/scripts/seed-mi-house-headshots.py` (Task 1, committed 1e2891f7)
- `backend/data/seed-mi-2026-house/159-02-mi-headshots.manual.txt` (incl. Bouchard revert annotation)
- `backend/data/stance-research/mi-2026-house/` — 56 per-candidate CSVs + `_push.ts` (external_id-keyed, transactional, quote+readrank+surname-guard)
- Push: per-file `_push.ts` runs, all committed in one transaction each; `tp-nykoriak.csv` needed explicit push (missing trailing newline broke the `wc -l` loop filter — add `-gt 0` on data-row count next time)
