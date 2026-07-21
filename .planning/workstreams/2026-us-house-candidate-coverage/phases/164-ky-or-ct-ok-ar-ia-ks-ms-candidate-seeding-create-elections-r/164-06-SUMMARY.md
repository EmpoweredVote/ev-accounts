---
phase: 164-ky-or-ct-ok-ar-ia-ks-ms-candidate-seeding-create-elections-r
plan: 06
state: AR+MS
status: complete
completed: 2026-07-06
requirements: [USHC3-02, USHC3-03, USHC3-04]
migrations_applied: [1242, 1243, 1244, 1245]
---

# 164-06 SUMMARY — AR + MS 2026 US House Seed

Two smallest decided states. Both vanilla single-election, ALL incumbents renominated (no open seats, no collision sub-bands). Seeded on **prod**, NOT provisional.

## AR — 1 election, 4 races, 6 new + 4 incumbent reuse (10 active)
- **Election:** `AR 2026 Statewide General`. 4 races, all `office_id` NOT NULL (geo 0501-0504). Band `-50499..-50101` empty pre-seed.
- **New external_id range: -50401 .. -50101** (6 records, standard seq 1). No dup.
- **Incumbents reused (is_incumbent):** -5001 Eric A. "Rick" Crawford, -5002 J. French Hill, -5003 Steve Womack, -5004 Bruce Westerman.
- Headshots: **0 uploaded, 6 honest-skip:** -50101 Terri Yarbrough Green, -50102 Steve Parsons, -50201 Chris Jones, -50301 Robb Ryerse, -50302 Bobby Wilson, -50401 James Russell.

## MS — 1 election, 4 races, 8 new + 4 incumbent reuse (12 active)
- **Election:** `MS 2026 Statewide General`. 4 races, all `office_id` NOT NULL (geo 2801-2804). Band `-280499..-280101` empty pre-seed.
- **New external_id range: -280402 .. -280101** (8 records, standard seq 1). No dup.
- **Incumbents reused (is_incumbent):** -28001 Trent Kelly, -28002 Bennie G. Thompson, -28003 Michael Guest, -28004 Mike Ezell.
- Headshots: **1 uploaded** — Jeffrey Hulum III `-280401` (cc_by_2.0, image `Rep._Jeffrey_Hulum_III_(cropped).jpg`, MS state rep, verified). **7 honest-skip:** -280101 Cliff Johnson, -280102 Johnny Baucom, -280201 Ron Eller, -280202 Bennie Foster, -280301 Michael Chiaradio, -280302 Erik Kiehle, -280402 Carl Boyanton.

## Verification (both states)
- AR: 4 races/0 null; 10 active/4 incumbent; 0 dup; idempotent.
- MS: 4 races/0 null; 12 active/4 incumbent; 0 dup; idempotent.

## Files
- `backend/scripts/164-ar-generate.mts`, `backend/scripts/164-ms-generate.mts`
- `backend/migrations/1242`, `1243` (AR), `1244`, `1245` (MS)
- `backend/scripts/seed-ar-house-headshots.py`, `backend/scripts/seed-ms-house-headshots.py` (+ gitignored results JSONs)
- `backend/data/seed-ar-2026-house/164-06-ar-reconciliation.csv`, `backend/data/seed-ms-2026-house/164-06-ms-reconciliation.csv`

## Self-Check: PASSED
Both states seeded, all incumbents renominated (no open seats), 1 headshot verified (Hulum), 13 documented honest-skips, idempotent, 0 dup. Ready for stance research (164-12). **Wave 1 (all 6 seed plans) complete.**
