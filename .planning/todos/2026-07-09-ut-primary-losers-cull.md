# UT June-23-2026 primary losers — CULL EXECUTED 2026-07-12 (mig 1323); data flags below still OPEN

**DONE 2026-07-12: all 10 losers below set candidate_status='withdrawn' via
`backend/migrations/1323_ut_primary_losers_cull.sql` (verified 10/10 on prod).
Dan McCay was already withdrawn when the migration ran — untouched.**

**SLCo FIXES DONE 2026-07-12 (mig 1324):** Assessor (both party shells) + Surveyor races
DELETED as 2024-cycle carryovers (candidate rows were the literal 2024 matchups with sitting
officeholders Stavros/Park seeded as non-incumbent "candidates"). The Setterberg party flag
was resolved BY the deletion — the wrong 'Republican' lived on the deleted Surveyor race's
primary_party. All four politician rows kept.

**UFP FIELD SEEDED 2026-07-12 (mig 1325):** created "2026 Utah General" (11/3) + general
races (primary_party='', NE/Osborn model but WITH district office_id for geofencing) for the
8 UFP districts, full fields = primary winners + third-party: 8 UFP candidates (J. Lowry
Snow SD-9 — NOT the Adam Snow homonym, Buss SD-11 INC, C. Smith SD-13, Woodfield SD-21,
C. Nelson HD-23, Nematollahi HD-28, T. Bean HD-29, J. Boyd HD-53) + BONUS Jonathan Garrard
(Constitution, HD-29). Emily Buss already EXISTED as politician -334574 w/ SD-11 office
(todo's "missing" = race membership only); her party set to Utah Forward Party. 25 rc rows
total. Source: BP office pages (2 snapshots, 7/09 + 7/12); SOS list is behind the
address-keyed votesearch app — ~Sept-Oct voteinfo.utah.gov pamphlet re-check re-verifies.
NOTE for Phase 166 / UT-REKEY: these 8 districts NOW HAVE general races — a future
primary→general conversion of UT must dedup against them. New third-party candidates have
zero stances/photos — they join the UT stance + pamphlet-headshot queues.

**HD-38 GENERAL SEEDED 2026-07-12 (mig 1326):** McConnehey existed (active in R primary,
copied to general); Sergio Sotelo CREATED (party='Unaffiliated' — Utah's official ballot
designation, kept over NE's 'Independent' label) + general race on the 2026 Utah General
(now 9 UT general races total — same Phase 166/UT-REKEY dedup note as mig 1325).
BP-verified 7/12 ("no incumbents in this race").

**FINAL TWO FLAGS CLOSED 2026-07-12 — THIS TODO IS FULLY RESOLVED:**
- **BP withdrawn/DQ list: clean no-op.** None of the 8 (Sloan/Farrell/Bagwell/Brough/
  Dean/Jackson/Miller/Tautuaa) was ever seeded into any UT race — the seed postdated
  their withdrawals.
- **Kaufusi title check → found a NEW LEAK VARIANT (fixed, mig 1327).** No "Mayor of
  Provo" title anywhere. BUT all 6 UtahCo Commission 2026 candidates (incl. Kaufusi +
  the 3 culled primary losers) held PLAIN-TITLED "Utah County Commissioner" office rows
  (is_vacant=false) — officeholder titles, so the standing `NOT ILIKE 'Candidate for%'`
  guard could NOT catch them; all 6 surfaced as sitting commissioners. Deleted (no race
  referenced the office ids; politicians.office_id denorm cleared). Pattern was exactly
  these 6 rows — no SLCo equivalent exists.
- **CORRECTION (same day): the "real commissioners unseeded" claim was WRONG** — a scope-query
  artifact (filtered title ILIKE '%Utah County Commission%'; the real rows are titled plainly
  "Commissioner"/"Commissioner (Chair)" etc.). Utah County 49049 COUNTY district has a FULL
  officials roster: Powers Gardner + Gordon + Beltran (Chair) + Assessor/Auditor/Clerk/County
  Attorney/Recorder/Sheriff/Surveyor/Treasurer, all is_incumbent=true with headshots; Seat A/B
  races' office_id correctly reference the real commissioner offices. NO county-officials wave
  needed for UtahCo. (Mig 1327's 6 deletions remain correct — they were DUPLICATE fabricated
  rows for candidates alongside these real ones.)

Found 2026-07-09 during the UT headshot sweep (Ballotpedia district pages, primary results
sections; vote totals "may change until results are certified" but margins are decisive).
All seven should be moved off `candidate_status IN ('active','filed')` for the general.
Photos deliberately withheld for all seven.

| Candidate | pid | Race | Result |
|---|---|---|---|
| Evan Done (D) | 77dc9a42-5f37-4608-89a1-10e60f86a3a1 | UT SD-13 | Lost D primary to Silvia Catten 44.1–32.8 |
| Taylor Paden (D) | 327298e7-e42c-4dfa-9f1d-55cfd48e0659 | UT SD-13 | Lost D primary (23.0%) |
| Tayler Khater (D) | 28df85e8-73c8-4def-bdd1-6929ff083590 | UT SD-14 | Lost D primary to inc. Pitcher 77.6–22.4 |
| Kelly Smith (R) | 92dba8fc-2bd1-4a68-ad69-ada24e3ff6f4 | UT SD-21 | Lost R primary to inc. Brammer 56.8–43.2 |
| Alexis Wheeler (R) | 860cd9e1-75ed-4094-8657-5b5d8dc02539 | UT HD-29 | Lost R primary to Birch 64.9–35.1 |
| Gloria Vindas (R) | 1ff4157d-be90-46d0-9ad8-121255277473 | UT HD-38 | Lost R primary to McConnehey 60.6–39.4 |
| Eryn Russo (R) | 62146875-3316-42e5-91f6-fdac6c420b32 | UT HD-41 | Lost R primary to Croft 62.5–37.5 |

Source: ballotpedia.org district pages (Utah State Senate District 13/14/21, Utah House of
Representatives District 29/38/41), fetched 2026-07-09 via /wiki/api.php parse.

**#8 — Dan McCay (R), UT SD-18, `is_incumbent=true`, still `active` in DB (verified live
2026-07-09): lost R primary to Doug Fiefia 69.5–30.5.** Fiefia already in DB with photo, good.

**#9–11 — Utah County Commission (Daily Herald, June 23 primary results,
heraldextra.com/news/2026/jun/23/utah-county-primary-maloy-leads-lyman-spencer-kaufusi-ahead-in-county-commission-races/):**
| Brent Bowles (R) | b71ec1b6-7d9e-406b-a30a-8c0710278d5e | UtahCo Comm Seat A | Lost R primary to Kaufusi 55.73–44.27 |
| Isaac Paxman (R) | b4aac990-f353-4ea7-bdb3-d5cf2cd232c8 | UtahCo Comm Seat B | 2nd of 3 (35.21%), Spencer advanced |
| Carolina Herrin (R) | 2ddafa6c-f5b8-40d6-a8d8-fce8f4849463 | UtahCo Comm Seat B | 3rd of 3 (22.68%) |

Corroborating official results: electionresults.utah.gov Primary06232026 utah-county-ut.
DATA FLAG: Michelle Kaufusi (abf34eb9) is the FORMER Provo mayor — voted out in 2025 after two
terms (Daily Herald) — if any DB title/office says "Mayor of Provo", update it.

## Salt Lake County race-cycle flags (agent-verified 2026-07-09)
- **SLCo Assessor + SLCo Surveyor are NOT 2026 races** — the official SLCo Clerk 2026 candidate
  JSON (apps.saltlakecounty.gov CandidateReporting API, 220 filers) has neither office; both are
  presidential-cycle (2024) races. Our DB rows "Salt Lake County Assessor 2026" (Joel Frost,
  7a92924f) and "Salt Lake County Surveyor 2026" (Kent Setterberg, 94e70501) look like
  wrong-cycle carryovers — verify the race rows' election ids and fix/retire.
- **Kent Setterberg party wrong**: DB race says Republican; he ran as the DEMOCRATIC candidate
  (slcountydems.com + LinkedIn "Democratic Candidate"). Fix party on the race/candidate row.
- Kent Davis (SLCo DA, R) IS a confirmed 2026 general candidate (unopposed in primary) — that row is fine.

## Related data flags (same source, informational)
- **SD-18**: Doug Fiefia (R) DEFEATED incumbent Dan McCay (R) in the primary — check whether
  McCay is still marked active/incumbent-running anywhere; general is Fiefia (R) vs A. Dane Anderson (D).
- **HD-38 is an open seat**: general = Chris McConnehey (R) vs Sergio Sotelo (Unaffiliated) —
  check whether McConnehey/Sotelo exist in DB (only Vindas was in our missing-photo set).
- BP-listed withdrawn/disqualified (verify status if present in DB): Chris Sloan (R, SD-11),
  Michael Farrell (D, HD-23), Stephanie Bagwell (R, HD-28), Sarah Brough (D, HD-39),
  Lisa Dean (R) + Ryan Jackson (R) (HD-39), Stephen Miller (D, HD-41), Charlie Tautuaa (R, HD-52).
- Utah Forward Party candidates appear in several generals (Buss SD-11 incumbent!, Colin Smith
  SD-13, Woodfield SD-21, Snow SD-9, Nelson HD-23, Nematollahi HD-28, Bean HD-29, Boyd HD-53) —
  check DB coverage of the UFP field; SD-11's incumbent Emily Buss is Utah Forward Party per BP.
  **Verified live 2026-07-09: SD-11 race has only Benson (R) + Miller (D) — incumbent Buss is
  MISSING from the DB race. SD-13 has no Colin Smith row either. UFP field looks unseeded.**
