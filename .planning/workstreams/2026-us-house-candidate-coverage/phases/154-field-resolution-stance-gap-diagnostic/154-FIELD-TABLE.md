# Phase 154 — Wave-2 US House Field Table (Nov 3, 2026)
**Generated:** 2026-06-30 · **Read-only diagnostic** (gates Phases 155/156/157/159) · **113 districts**

## Scope split
- **Decided (89):** PA 17 / IL 17 / OH 15 / GA 14 / NC 14 / NJ 12 — primaries held; Nov-3 field resolved from results sources.
- **Pending-primary Aug-4 (24):** MI 13 + VA 11 — both 2026 congressional primaries are Aug 4, 2026; nominees deferred to date-gated Phase 159. Incumbent map built now; nominees NOT resolved.

## Per-state district counts
| State | Districts | Status | New records (decided) |
|---|---|---|---|
| PA | 17 | decided | 20 |
| IL | 17 | decided | 28 |
| OH | 15 | decided | 19 |
| GA | 14 | decided | 18 |
| NC | 14 | decided | 25 |
| NJ | 12 | decided | 15 |
| MI | 13 | pending-primary (Aug-4) | (deferred to 159) |
| VA | 11 | pending-primary (Aug-4) | (deferred to 159) |

## Non-incumbent-nominee decided districts (incumbent is NOT the 2026 nominee)
Resolved from official/results sources, never from incumbency (D-04). The sitting incumbent keeps their existing `politician_id` (still in office through Jan 2027) but is flagged via the nominee-status taxonomy; the actual nominees are new-record needs.

| District | nominee_status | Sitting incumbent (not running) | 2026 nominees (new records) |
|---|---|---|---|
| GA-1 | open-seat-vacancy | Earl L. "Buddy" Carter | Jim Kingston; Amanda Hollowell |
| GA-10 | open-seat-vacancy | Mike Collins | Houston Gaines; Pamela DeLancy |
| GA-11 | retired | Barry Loudermilk | John Cowan; Chris Harden |
| GA-13 | open-seat-vacancy | VACANT | Jasmine Clark; Jonathan Chavez |
| IL-2 | retired | Robin L. Kelly | Donna Miller; Michael Noack; Ashley Banks |
| IL-4 | retired | Jesús G. "Chuy" García | Patty Garcia; Lupe Castillo; Ed Hershey; Chris Getty; Mayra Macias; Byron Sigcho-Lopez; Lindsay Church |
| IL-7 | retired | Danny K. Davis | La Shawn Ford; Chad Koppie |
| IL-8 | retired | Raja Krishnamoorthi | Melissa Bean; Jennifer Davis |
| IL-9 | retired | Janice D. Schakowsky | Daniel Biss; John Elleson |
| NJ-11 | special-seated | Analilia Mejia | Joe Hathaway |
| NJ-12 | retired | Bonnie Watson Coleman | Adam Hamawy; Gregg Mele |
| PA-3 | retired | Dwight Evans | Chris Rabb |

## Four flagged special / vacancy seats
Verified against the live DB by Wave-1 (`154-incumbent-map.csv`) — three of four are already correctly seeded incumbents:

- **GA-13 (1313):** True 0-holder VACANCY (David Scott died Apr 2026). Nov-3 field DECIDED: **Jasmine Clark (D) vs Jonathan Chavez (R)** — both new records. (July 28 special not relied upon.)
- **GA-14 (1314):** **Clay Fuller (R)** already seeded as incumbent (won Apr 7 2026 special replacing MTG). `renominated`; faces Shawn Harris (D). NOT a new record.
- **NJ-11 (3411):** **Analilia Mejia (D)** already seeded as incumbent (won Apr 16 2026 special after Sherrill → NJ governor). `special-seated`; faces Joe Hathaway (R). NOT a stale Sherrill row — the DB is current.
- **VA-11 (5111):** **James Walkinshaw (D)** already seeded as incumbent (won Sep 2025 special after Connolly died). `special-seated`; field `pending-primary (Aug-4)` — VA primary is Aug 4, nominee deferred to Phase 159.

## Stance-gap note (report-only, D-02)
Every one of the 112 mapped incumbents is **partial** (1–23 federal-24 stances; 0 at the full 24). Per D-02, partial incumbents are NOT topped up. The only zero-stance incumbent is **NC-6 Addison P. McDowell** — the sole incumbent stance-research target (Phase 156). New challengers + open/special candidates get stance research in their seeding phase.

## Inclusion bar (D-03)
Every candidate ballot-qualified for the Nov-3 general (major-party nominees + ballot-qualified independents/third-party). Primary-only also-rans and uncertified write-ins excluded. Minor independent/write-in candidates whose ballot qualification was unconfirmed at research time were omitted; seeding phases re-confirm against state certified lists.

## existing_race_id — VA races already scaffolded (Wave-1 baseline finding)
**The 11 VA rows carry a populated `existing_race_id`** — VA's 11 US House races already exist in the DB (0 candidates each) under the existing **"2026 Virginia General Election"** (election_date 2026-11-03). **Phase 159 must REUSE these race rows** (wire `race_candidates` onto them), NOT create duplicates. The other **102 rows are BLANK** (PA/IL/OH/GA/NC/NJ/MI have no pre-seeded 2026 House races) — Phases 155/156/157 + MI-159 author `elections` + `races` first. `154-verify.sql` A2 asserts **0 `race_candidates`** on any 2026-11-03 Wave-2 House race (candidates not yet seeded anywhere) and confirms the VA-11/non-VA-0 race split.
