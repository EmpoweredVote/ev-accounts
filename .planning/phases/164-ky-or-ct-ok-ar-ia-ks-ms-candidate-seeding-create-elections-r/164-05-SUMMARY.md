---
phase: 164-ky-or-ct-ok-ar-ia-ks-ms-candidate-seeding-create-elections-r
plan: 05
state: OK+IA
status: complete
completed: 2026-07-06
requirements: [USHC3-02, USHC3-03, USHC3-04]
migrations_applied: [1238, 1239, 1240, 1241]
---

# 164-05 SUMMARY — OK + IA 2026 US House Seed

Two decided vanilla single-election states. Both seeded on **prod**, NOT provisional.

## OK — 1 election, 5 races, 10 new + 4 incumbent reuse (14 active)
- **Election:** `OK 2026 Statewide General`. 5 races, all `office_id` NOT NULL (geo 4001-4005). Description `Confirmed 2026 general-election field`.
- **New external_id range: -400503 .. -400144** (10 records). **D-04 correction (deviation):** the audit's `safe_start_seq=200` for OK-1 is UNSAFE — OK-1 has 2 records, so seq 200/201 = `-400300`/`-400301`, and `-400301` collides with **OK-3 seq 1** (Suzie Byrd). Instead OK-1 uses the first free **in-century** seqs **44/45** (`-400144`/`-400145`), past the 43 occupied (US-Senate-cycle records) and within cd=1's range. No dup external_id/full_name.
- **Incumbents reused (is_incumbent):** -40002 Brecheen, -40003 Lucas, -40004 Cole, -40005 Bice.
- **OPEN SEAT (D-05):** Hern `-40001` (OK-1, retired → Tedford R nominee) — 0 rows. OK-1 = 2 candidates.
- Headshots: **1 uploaded** — Mark Tedford `-400144` (public_domain, OK-House official portrait, verified = OK-1 nominee/state rep). 9 honest-skip: -400145 Croisant, -400201 Wade, -400202 Hopkins, -400301 Byrd, -400401 Jacob, -400402 Bonacci, -400501 Nelson, -400502 Henri, -400503 Nieves.

## IA — 1 election, 4 races, 9 new + 2 incumbent reuse (11 active)
- **Election:** `IA 2026 Statewide General`. 4 races, all `office_id` NOT NULL (geo 1901-1904). Band `-190499..-190101` was empty pre-seed (no collisions).
- **New external_id range: -190402 .. -190101** (9 records, standard seq 1). No dup.
- **Incumbents reused (is_incumbent):** -19001 Miller-Meeks (IA-1), -19003 Nunn (IA-3).
- **OPEN SEATS (D-05):** Hinson `-19002` (IA-2, retired → Joe Mitchell R) + Feenstra `-19004` (IA-4, retired → Chris McGowan R) — both 0 rows. IA-2 = 4 candidates, IA-4 = 2 candidates.
- Headshots: **3 uploaded** (all verified correct Iowa figures) — Christina Bohannan `-190101`, Joe Mitchell `-190201` (page "Joe Mitchell (politician)" confirmed = IA-2 nominee, ex-IA-House), Sarah Trone Garriott `-190301`. 6 honest-skip: -190102 Bridgford, -190202 Lindsay James, -190203 Bushaw, -190204 Stewart, -190401 McGowan, -190402 Dawson.

## Verification (both states)
- OK: 5 races/0 null; 14 active/4 incumbent; OK-1=2; Hern 0 rows; 0 dup; idempotent.
- IA: 4 races/0 null; 11 active/2 incumbent; IA-2=4/IA-4=2; Hinson+Feenstra 0 rows; 0 dup; idempotent.

## Files
- `backend/scripts/164-ok-generate.mts`, `backend/scripts/164-ia-generate.mts`
- `backend/migrations/1238`, `1239` (OK), `1240`, `1241` (IA)
- `backend/scripts/seed-ok-house-headshots.py`, `backend/scripts/seed-ia-house-headshots.py` (+ gitignored results JSONs)
- `backend/data/seed-ok-2026-house/164-05-ok-reconciliation.csv`, `backend/data/seed-ia-2026-house/164-05-ia-reconciliation.csv`

## Self-Check: PASSED
Both states seeded, open-seat exclusions verified (Hern/Hinson/Feenstra 0 rows), OK-1 collision avoided via in-century sub-band, 4 headshots verified correct, 15 documented honest-skips. Ready for stance research (164-11).
