---
phase: 164-ky-or-ct-ok-ar-ia-ks-ms-candidate-seeding-create-elections-r
plan: 03
state: OR
status: complete
completed: 2026-07-06
requirements: [USHC3-02, USHC3-03, USHC3-04]
migrations_applied: [1235]
election_name: "OR 2026 General"
---

# 164-03 SUMMARY — OR 2026 US House Seed (candidates-only)

## What was built
OR's decided 2026 US House field wired onto its **6 pre-existing scaffolded races** (candidates-only, D-03 — NO new elections/races). 7 new candidate records + 13 active `race_candidates` (7 challengers + 6 renominated incumbents) across the 6 `OR 2026 General` races. Decided field → NOT PROVISIONAL.

## Key facts (for 164-13 gate)
- **Election name (for downstream/headshot join): `OR 2026 General`.** Race count unchanged **148 → 148** — confirmed NO new races authored (candidates-only reuse). The 6 reused race UUIDs map to geo 4101-4106.
- **Exactly 1 row per (race_id, politician_id)** — 13 pairs, max multiplicity 1 (no duplicate wiring). Idempotent: 2nd run = all `INSERT 0 0`.
- **New-candidate external_id range: -410601 .. -410114** (7 records). D-04: OR-1 uses **seq 14** (`-410114`) because seqs 10-13 are occupied by 4 OR **local** officials (see below). OR-2..6 standard seq 1. No dup external_id/full_name.
- **Incumbents reused (is_incumbent=true, by external_id):** -4102001 Bonamici (OR-1), -4102002 Bentz (OR-2), -4102003 Dexter (OR-3), -4102004 Hoyle (OR-4), -4102005 Bynum (OR-5), -4102006 Salinas (OR-6). All 6 renominated.

## Cross-session collision handling (177/178 OR local session)
The OR-1 band seqs 10-13 (`-410110` Nafisa Fai, `-410111` Pam Treece, `-410112` Jason Snider, `-410113` Jerry Willey) are **OR local officials** (Washington County / Tigard / Hillsboro) owned by the parallel 177/178 session. Handled: (1) D-04 OR-1 new record starts at seq 14, avoiding them; (2) the OR headshot band upper bound is `-410114` (not `-410101`), so the local officials' rows are never touched by this phase.

## Headshots — ALL 7 honest-skip (documented in `_or-house-headshot-results.json`)
No new OR challenger has a free-license personal Wikipedia portrait (guard rejected election-list/senate pages). 0 uploaded, 7 skips. External_ids for 164-13 pin: -410114 Barbara Kahl, -410201 Chris Beck, -410301 Loran Ayles, -410401 Monique DeSpain, -410402 Justin Filip, -410501 Patti Adair, -410601 David Russ.

## Files
- `backend/scripts/164-or-generate.mts`
- `backend/migrations/1235_seed_or_2026_house_candidates.sql`
- `backend/scripts/seed-or-house-headshots.py` + `backend/scripts/_or-house-headshot-results.json` (gitignored)
- `backend/data/seed-or-2026-house/164-03-or-reconciliation.csv`

## Self-Check: PASSED
No new races (148→148); 13 race_candidates, exactly 1 per pair; 6 incumbents reused; 7 new in-band (OR-1 seq 14); 0 dup name; idempotent; local-official rows protected; every new candidate honest-skipped with documentation. Ready for stance research (164-09).
