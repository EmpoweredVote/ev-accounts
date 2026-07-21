---
phase: 164-ky-or-ct-ok-ar-ia-ks-ms-candidate-seeding-create-elections-r
plan: 04
state: KY
status: complete
completed: 2026-07-06
requirements: [USHC3-02, USHC3-03, USHC3-04]
migrations_applied: [1236, 1237]
---

# 164-04 SUMMARY — KY 2026 US House Seed

## What was built
Full decided 2026 KY US House field seeded on **prod**: 1 election, 6 races, **15 new** candidate records + 19 active `race_candidates` (15 new + 4 renominated incumbents). Two open seats. KY is NOT redistricted — vanilla single-election, decided field (NOT provisional).

## Key facts (for 164-13 gate)
- **Election:** `KY 2026 Statewide General` (general, 2026-11-03, state, KY). 6 races, all `office_id` NOT NULL → NATIONAL_LOWER offices geo 2101-2106. Description = `Confirmed 2026 general-election field`.
- **New-candidate external_id range: -210604 .. -210201** (15 records). **D-04: KY-1 uses seq 200 (`-210300`)** because KY-1 seqs 1-98 (`-210101..-210198`) are occupied by **98 MA state legislators** (external-id scheme collision). KY-2..6 standard seq 1. No dup external_id/full_name.
- **Incumbents reused (is_incumbent=true):** -21001 James Comer (KY-1), -21002 Brett Guthrie (KY-2), -21003 Morgan McGarvey (KY-3), -21005 Harold Rogers (KY-5).
- **OPEN SEATS (D-05) — departing incumbents EXCLUDED (0 rows anywhere):** **Massie `-21004`** (KY-4, lost primary → Ed Gallrein R nominee) and **Barr `-21006`** (KY-6, retired → Ralph Alvarado R nominee). Verified: `p.external_id IN (-21004,-21006)` → 0 active rows. KY-4 = 4 candidates (no Massie), KY-6 = 4 candidates (no Barr).
- Idempotent: both migrations re-run = all `INSERT 0 0`.

## Headshots — 2 uploaded, 13 honest-skip (documented in `_ky-house-headshot-results.json`)
- **Uploaded (verified correct, distinctive surnames):** Ralph Alvarado `-210601` (cc_by-sa_3.0, KY-6 nominee, Gage Skidmore photo), Ed Gallrein `-210401` (public_domain, KY-4 nominee, filename `Ed_Gallrein.jpg` matches).
- Guard correctly rejected a historical homonym for Drew Williams ("John Y. Brown, born 1835").
- **Honest-skip external_ids (13) for 164-13 pin:** -210201 Megan Wingfield, -210202 Thomas A. Loecken, -210300 John "Drew" Williams, -210301 Maria Teresa Rodriguez, -210402 Melissa Claire Strange, -210403 Mohammad Wael Ahmad, -210404 Jeremy Todd, -210501 Ned Pillersdorf, -210502 Gerardo Serrano, -210503 Mikel Wein, -210602 Zach Dembo, -210603 Jay J Bowman, -210604 Pete Lynch.

## Files
- `backend/scripts/164-ky-generate.mts`
- `backend/migrations/1236_seed_ky_2026_house_elections_races.sql`
- `backend/migrations/1237_seed_ky_2026_house_candidates.sql`
- `backend/scripts/seed-ky-house-headshots.py` + `backend/scripts/_ky-house-headshot-results.json` (gitignored)
- `backend/data/seed-ky-2026-house/164-04-ky-reconciliation.csv`

## Self-Check: PASSED
6 races/0 null; 19 active (4 incumbent); 15 new in D-04 bands (KY-1 seq 200); Massie/Barr 0 rows; KY-4/KY-6 = 4 each; 0 dup name; idempotent; 2 headshots verified + 13 documented skips. Ready for stance research (164-10).
