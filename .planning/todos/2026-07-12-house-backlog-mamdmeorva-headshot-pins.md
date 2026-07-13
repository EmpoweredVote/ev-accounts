# MA/MD/ME/OR/VA House backlog headshot pins — post-BP-race-page-pass (2026-07-12)

Two waves complete same day. Wave 1 (context-mine + BP profiles + campaign sites): 42 imported.
Wave 2 (**BP RACE-page pass**): **18 imported, Chris-approved** ("everyone is ok" + explicit
Bruner include / Sabio keep-pinned) — 6 never-chased targets (M.Q. Jones MA-06, Collier MD-07,
Kopp + Cywinski VA-01, Staten VA-02, Duffin VA-08) + 12 pin lifts (Samman, Swallow, D.Wallace,
Riley, Mosolf, Rivera, Lucero, Tracinski, Harding, Bruner, Powers, Perry).

LESSON (memorialized in sweep-program memory): BP RACE pages carry candidate-submitted uploads
that api.php PROFILE pulls + context-mine miss — 12 of 16 pins lifted this way. Always re-run
race-page pass on pinned candidates.

Verify query (active/filed 2026 race_candidates, position_name LIKE 'U.S. House %', no
politician_images row) returns **exactly the 15 below** (checked post-import 2026-07-12).

## 4 standing pins (searched: context-mine + BP profile + BP race page)

- **Tony Sabio VA-08** — campaign poster face AI-GENERATED (case #3); his 2026 BP race-page
  upload (Tony_Sabio_2026.JPG) is ALSO suspect-AI (waxy skin, painted fabric weave).
  **Chris ruling 2026-07-12: keep pinned.** Re-check only if a verifiable real photo appears.
- Gary J. Grossi MA-03 — site logo-only; no BP race-page photo.
- Brian Jordan MD-05 — site yard-sign + AI illustrations; no BP race-page photo.
- Nancy Wallace MD-08 — only a 240px full-body cutout anywhere (BP race page serves the same
  file); too small.

## 11 zero-photo after BP race-page search (next: targeted agent wave, or wait for Aug-4 VA culls)

- R. Tyler MacAllister MA-09
- Jonathan Burruss MD-05
- Loran Ayles OR-03
- Makiba Gaines VA-02
- James "Zeb" Taylor VA-03
- Andre Kersey VA-04
- Brandi Hall VA-09
- Brandon Cook VA-09
- Michael Jackson VA-09
- Anthony Suttles VA-10
- Nathan Headrick VA-11
- (Micah Quinney Jones MA-06 RESOLVED via BP race page — the Fox News/ussanews chase noted
  in the earlier version of this file is moot.)

## Method notes (carried forward)

- BP api.php profile pull = richest bulk source; BP RACE pages = second pass that catches
  fresh candidate uploads (Rivera 7/10, Harding 7/01, Bruner 7/03 all post-dated the pins).
- CDN transform-strip: drop wsimg `/:/rs=...` / base44 `/v1/fill/...` for originals.
- Squarespace og:image is usually a logo; real portrait lives in page <img>s.
- Wikimedia needs descriptive UA; plain Mozilla UA gets 429.
- VA primaries Aug-4: re-run verify query after culls before batching any agent wave.
