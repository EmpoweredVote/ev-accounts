# TN Old-vs-New Congressional Map Correspondence Audit (D-01a)

**Phase:** 161-wa-az-tn-ma-candidate-seeding-create-elections-races-then-ca
**Task:** 161-01 (Task 1 + Task 2 — gather + score)
**Executed:** 2026-07-03
**Purpose:** Score each of TN's 9 old-numbered congressional districts (geo_id 4701-4709) for old-vs-new boundary-shift severity, so 161-06 (TN seed) knows which districts to seed-but-withhold from `/elections` (D-01b) rather than serve an actively-wrong address→race lookup against the stale 2024-TIGER polygon.

**No DB writes. No code. `essentials.offices` was not touched. Pure research artifact.**

---

## Background (from named sources)

Tennessee's General Assembly, in a Second Extraordinary Session (May 5-7, 2026), repealed a decades-old law barring mid-decade congressional redistricting and enacted a new map (HB 7003/SB 7001) days after the U.S. Supreme Court's *Louisiana v. Callais* ruling (April 29, 2026) partially struck down Section 2 of the Voting Rights Act. Governor Bill Lee signed the bill into law May 7, 2026. The stated goal (per multiple Republican legislators quoted in named sources) was to flip the state's sole Democratic, majority-Black seat (old TN-9, Memphis/Shelby County, Rep. Steve Cohen) and push the state's congressional delegation from 8-1 to 9-0 Republican. The candidate qualifying deadline was extended from March 10 to May 15, 2026 to accommodate the new map; the official qualified-candidate list was certified May 29, 2026 (per Phase-160's field-resolution work). Primaries remain scheduled for August 6, 2026.

Litigation status as of this audit (re-verified 2026-07-03, same-day as execution — well within the 7-day freshness window flagged in 161-RESEARCH.md): the map is **currently in effect and has NOT been enjoined**. A Davidson County Chancery Court NAACP state-law challenge was **dismissed** (per Tennessee Lookout, June 10, 2026 recap: "NAACP's state lawsuit was dismissed last month" = May 2026). A federal three-judge panel **upheld** the redistricting May 26, 2026 (Tennessee Lookout, "Three-judge panel upholds Tennessee redistricting," May 26, 2026). Two federal suits remain **pending but without an injunction**: the NAACP/League of Women Voters consolidated suit (NAACP filed a preliminary-injunction motion June 10, 2026, still undecided) and a separate ACLU suit (filed May 12, 2026). A federal judge denied an earlier temporary restraining order request May 14, 2026. Tennessee Lookout's Politics section (checked through July 2, 2026, the most recent available article at audit time) shows ongoing 2026 primary-race coverage under the new map (e.g., a June 24, 2026 TN-6 primary preview, a June 30, 2026 TN-1 primary preview) with **no reported injunction, stay, or map reversal** — the new map is the operative map for the August 6, 2026 primary and the November 3, 2026 general. This confirms the phase's D-01 premise: the seeded candidate/race/stance data should be keyed to the new map, and only the address→polygon join is stale.

---

## Severity Rubric

A district is scored **SEVERE** if either condition holds:
1. **>25% of the district's population moved to a different congressional district** between the old (2022, currently-live-in-`essentials.districts`) map and the new (2026) map, OR
2. **The district's core anchor city/county changed** — i.e., the metro area or county that defined the district's political and geographic identity under the old map is no longer the anchor under the new map (either lost entirely to another district, or a new metro anchor was added that wasn't previously present).

Otherwise a district is scored **NOT-SEVERE**.

**Evidence basis:** No shapefile/GIS diff was performed (per 161-RESEARCH.md's Don't-Hand-Roll guidance — a qualitative county-level breakdown from named reporting is sufficient and avoids installing any new GIS dependency). Severity is derived from (a) explicit county-reassignment reporting in named sources, (b) a quantitative proxy — the shift in each district's notional 2024 presidential-election result when recalculated under the new boundaries vs. the old boundaries (Wikipedia's "2026 Tennessee redistricting" partisan-breakdown table, itself sourced to Dave's Redistricting App), and (c) explicit "anchor changed" statements from named reporting (e.g., a district gaining or losing a metro core).

---

## Per-District Severity Table

| geo_id | old_cd | incumbent | anchor_county_old | anchor_county_new | pct_population_moved (proxy: pres.-result pt swing, old→new map) | severity | rationale |
|--------|--------|-----------|--------------------|--------------------|---------------------------------------------------------------------|----------|-----------|
| 4701 | TN-1 | Diana Harshbarger | Sullivan/Washington (Tri-Cities, NE TN) | Sullivan/Washington (unchanged) | LOW (~0.00 pt swing; Trump +57.84% both maps) | NOT-SEVERE | East TN reported unaffected by every source found; zero measured partisan-composition change; no county-reassignment reported for TN-1 |
| 4702 | TN-2 | Tim Burchett | Knox County (Knoxville) | Knox County (unchanged) | LOW (~0.00 pt swing; Trump +33.86% both maps) | NOT-SEVERE | East TN reported unaffected; zero measured change |
| 4703 | TN-3 | Chuck Fleischmann | Hamilton County (Chattanooga) | Hamilton County (largely unchanged) | LOW (-0.16 pt swing; +35.89%→+35.73%) | NOT-SEVERE | Negligible measured change; not named in any Memphis/Nashville reassignment reporting |
| 4704 | TN-4 | Scott DesJarlais | Rural southeastern Middle TN (Coffee/Franklin/Bedford/Lincoln-area; this was Van Hilleary's old-TN-4 footprint) | Reconfigured to absorb a Davidson County (Nashville) slice under the new CD-4/6/7 three-way Davidson split, per Tennessee Lookout's June 24, 2026 TN-6 report ("Hilleary represented the old 4th Congressional District that stretched mainly across southeastern Middle Tennessee" — now running in the *new* 6th, confirming old-TN-4 territory was substantially redistributed) | HIGH (-19.65 pt swing; +43.58%→+23.93%, the 2nd-largest shift after TN-9/TN-8) | **SEVERE** | Anchor-changed (gained urban Davidson territory absent from the old district) AND one of the three districts (4/5/9) the Tennessee Lookout's data analysis (May 20, 2026) found were deliberately engineered to match Sen. Blackburn's razor-thin (≤0.4%) 2018 district-level margins — evidence of substantial, intentional boundary redrawing, not incidental drift |
| 4705 | TN-5 | Andrew Ogles | Davidson County (Nashville) + Williamson County suburbs | **Loses both** — Davidson reassigned to new CD-4/6/7 (per interfaces/CONTEXT known-facts and the TN-6 source confirming a Davidson slice moved to new CD-6); Williamson County reassigned to new CD-9 (NPR, May 13, 2026: new TN-9 "ends more than 200 miles away in suburban Williamson County south of Nashville") | MED-per-proxy but anchor-decisive (+5.18 pt swing; +17.90%→+23.08%) | **SEVERE** | Anchor-city-changed: TN-5's entire prior anchor (Nashville + Williamson) is reassigned away in the new map — a complete anchor replacement, not a marginal edge shift. Also one of the three districts explicitly named in the original May 6-7, 2026 Memphis-carve-up reporting ("Memphis and Shelby County carved up three ways between the 5th, 8th, and 9th") and one of the three Blackburn-margin-engineered districts (4/5/9) |
| 4706 | TN-6 | John W. Rose (retiring) | Rural Upper Cumberland (Cookeville area; no urban core) | Downtown Nashville + most of northeast Davidson County + slivers of Sumner/Wilson counties + northern Middle TN to the Cumberland Plateau (Tennessee Lookout, June 24, 2026, quoting the new district's shape directly) | MED-per-proxy but anchor-decisive (-8.65 pt swing; +35.16%→+26.51%) | **SEVERE** | Anchor-city-added: the new TN-6 gains a major metro core (downtown Nashville) that was entirely absent from the old, rural-only TN-6 — a textbook anchor change even though the presidential-swing proxy alone is moderate, not extreme |
| 4707 | TN-7 | Matt Van Epps | Suburban Middle TN (Williamson/Franklin-area) | Retains suburban Middle TN core; gains "the rest of Sumner County" (Tennessee Lookout, June 24, 2026: "the rest of Sumner County was placed in the 7th District") | LOW (+0.19 pt swing; +22.21%→+22.40%, near-zero) | NOT-SEVERE | Single-county gain (most of Sumner) with a near-zero net partisan/composition change and no reported loss of the district's suburban-Middle-TN anchor; incumbent Van Epps unchanged. Flagged as a genuine boundary change (not "no change") but below the severe threshold on both rubric prongs |
| 4708 | TN-8 | David Kustoff | West TN / Memphis-suburb Shelby County share + rural West TN | Reconfigured Shelby County share under the new three-way Memphis split (5th/8th/9th); retains West TN rural core but with a differently shaped Memphis-suburb boundary | HIGH (-21.49 pt swing; +41.63%→+20.14%, 3rd-largest shift) | **SEVERE** | One of the three districts explicitly named in the original May 6-7, 2026 "carved up three ways between the 5th, 8th, and 9th" reporting; large measured partisan-composition shift |
| 4709 | TN-9 | Steve Cohen (redistricted; withdrew from re-election in any of the 3 Memphis-touching districts, per Tennessee Lookout, May 15, 2026) | City of Memphis / Shelby County (~60% Black, majority-minority, D+42.66 under the old map) | Memphis (partial) + rural southern-Middle-TN corridor + suburban Williamson County near Nashville — NPR (May 13, 2026): the new 9th "starts in Memphis, meanders across rural southern Tennessee and ends more than 200 miles away in suburban Williamson County south of Nashville" | HIGH (+63.81 pt swing; -42.66%→+21.15%, by far the largest shift — a full partisan flip) | **SEVERE** | Explicitly dismantled per every named source; the incumbent withdrew citing the new map (nominee_status=redistricted in 160-field-table-p161.csv); the largest measured shift of any TN district by an order of magnitude; textbook case for D-01b withholding |

---

## Severe geo_id list: 4704, 4705, 4706, 4708, 4709

(5 of 9 TN districts scored severe; 4701, 4702, 4703, 4707 scored not-severe.)

---

## Notes for downstream consumers (161-06, 161-11)

- **TN-9 (4709)** is the unambiguous, expected-severe case (old Cohen seat, dismantled) — matches the CONTEXT.md/RESEARCH.md pre-audit expectation exactly.
- **TN-1/2/3 (4701-4703)** are confirmed not-severe, matching the CONTEXT.md/RESEARCH.md pre-audit expectation (East TN unaffected).
- **TN-4, TN-5, TN-6, TN-8** were the open question flagged in 161-RESEARCH.md's Assumptions Log (A3) and Open Questions §1 ("whether TN-4/5/6/7/8 individually cross a severe threshold"). This audit resolves that question: **TN-4, TN-5, TN-6, and TN-8 all score severe** (anchor-changed and/or >20-point presidential-swing evidence for each), while **TN-7 scores not-severe** (single-county gain, near-zero swing, anchor preserved).
- This is a larger severe set (5/9) than the RESEARCH.md's working assumption ("possibly only TN-9, and possibly TN-8"). The evidence driving the expansion: (1) direct, named-source confirmation that the new TN-6 now includes downtown Nashville (an anchor entirely absent from the old, rural-only TN-6), and (2) direct, named-source confirmation that TN-5 loses BOTH of its old anchors (Davidson AND Williamson counties) to other districts. Both are anchor-changed calls under the rubric's second prong, independent of the more modest presidential-swing proxy values for those two districts.
- **Re-verify litigation status before TN race authoring in 161-06** if more than a few days have elapsed since 2026-07-03 (the 7-day freshness window in 161-RESEARCH.md) — two federal suits (NAACP/LWV consolidated; ACLU) remain pending without injunction as of this audit, and either could theoretically result in a stay before the August 6 primary.

---

## Source URLs (all fetched directly during this audit, 2026-07-03)

- [2026 Tennessee redistricting — Wikipedia](https://en.wikipedia.org/wiki/2026_Tennessee_redistricting) — legislative history, partisan-breakdown table (source of the presidential-swing proxy), litigation timeline through mid-June 2026
- [Tennessee Secretary of State — 2026 Congressional Redistricting announcement](https://sos.tn.gov/announcements/2026-congressional-redistricting) — official confirmation the revised boundaries were adopted in the Second Extraordinary Session of the 114th General Assembly
- [Tennessee Lookout — "Tennessee Republicans pass US House map carving up Memphis days after SCOTUS guts Voting Rights Act"](https://tennesseelookout.com/2026/05/07/tenn-passes-new-potential-9-0-gop-u-s-house-map-eight-days-after-scotus-guts-voting-rights-act/) (May 7, 2026) — Memphis/Shelby split three ways among CD-5/8/9; May 15 qualifying deadline; competitive primaries note (Districts 5 and 6)
- [Tennessee Lookout — "Lawmakers mum on where new US House map came from, but data shows two clear criteria"](https://tennesseelookout.com/2026/05/20/lawmakers-mum-on-where-new-us-house-map-came-from-but-data-shows-two-clear-criteria/) (May 20, 2026) — districts 4, 5, 9 engineered to Blackburn's ≤0.4% 2018 margins; Sumner County split between new CD-6 (sliver) and CD-7 (rest); Eads (Shelby) drawn into new CD-9
- [Tennessee Lookout — "Former congressman squares off with state House member in 6th District GOP primary"](https://tennesseelookout.com/2026/06/24/former-congressman-squares-off-with-state-house-member-in-6th-district-gop-primary/) (June 24, 2026) — direct confirmation new TN-6 = downtown Nashville + NE Davidson County + Sumner/Wilson slivers + northern Middle TN to Cumberland Plateau; old TN-4 (Hilleary's former seat) territory redistributed; TN-7 = "rest of Sumner County"
- [Tennessee Lookout — "NAACP files for federal court injunction to stop new Tennessee congressional map"](https://tennesseelookout.com/2026/06/10/naacp-files-for-federal-court-injunction-to-stop-new-tennessee-congressional-map/) (June 10, 2026) — litigation status: NAACP state suit dismissed, federal NAACP/LWV suit + ACLU suit both pending without injunction
- [Tennessee Lookout — "Three-judge panel upholds Tennessee redistricting"](https://tennesseelookout.com/2026/05/26/three-judge-panel-upholds-tennessee-redistricting/) (May 26, 2026, referenced via the Lookout's article index) — state three-judge panel upheld the map
- [NPR — "What Tennessee's new redistricting map looks like from the ground"](https://www.npr.org/2026/05/13/nx-s1-5818509/what-tennessees-new-redistricting-map-looks-like-from-the-ground) (May 13, 2026) — new TN-9 spans Memphis to suburban Williamson County (~200 miles); confirms the 5th/8th/9th Shelby County three-way split from the ground
- [Tennessee Lookout Politics section index](https://tennesseelookout.com/category/politics/) (checked through July 2, 2026) — confirms ongoing normal primary-race coverage under the new map with no reported injunction/stay as of audit date

---

*Audit completed 2026-07-03 as Task 1+2 of Phase 161 Plan 01. Consumed downstream by 161-06 (TN seed — withhold severe-district races per D-01b/Pitfall-#1 mechanism) and 161-11 (verify.sql severe-race non-surfacing assertion).*
