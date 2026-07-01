# 156-05 SUMMARY — NC House candidate seeding

**Status:** COMPLETE ✅
**Migration:** `backend/migrations/1130_seed_nc_2026_house_candidates.sql`
**Reconciliation:** `backend/data/seed-nc-2026-house/156-05-nc-reconciliation.csv` (39 rows)

## Result
- 14 NC races each carry their active field: **39 active race_candidates** (14 renominated incumbents REUSED + **25 NEW** — the heaviest field of the three states).
- All 14 incumbents renominated, incl. **NC-6 Addison P. McDowell (-37006)** reused as active is_incumbent=true (his full-24 stances pushed in 156-09, NOT here).
- 0 NULL politician_id; 0 duplicate full_name within NC.

## D-02 third-party seed-all
Libertarians NC-1 Bailey / NC-2 Laszacs / NC-3 Cavender / NC-4 Meilleur / NC-5 Luffman / NC-7 Abu-Ghazalah / NC-10 Feldman / NC-11 Groo / NC-13 Swinton; Green NC-13 Anthony Aguilar; Independent NC-11 John Rogers. None dropped.

## Dedup (D-03, live-verified)
Richard Ojeda (≠ Luis A. Ojeda -258200010), Laurie Buckhout (2024 nominee), John Rogers (≠ KY John H. Rogers -210145) all returned 0 prior real records. All 25 genuinely NEW.

## New-candidate external_id list (for 156-06 + 156-09; McDowell -37006 is EXISTING, stances in 156-09)
-370101 Laurie Buckhout(R), -370102 Tom Bailey(L), -370201 Gene Douglass(R), -370202 Matt Laszacs(L), -370301 Raymond Smith Jr.(D), -370302 Daniel Cavender(L), -370401 Max Ganorkar(R), -370402 Guy Meilleur(L), -370501 Chuck Hubbard(D), -370502 Robert Luffman(L), -370601 Cyril Jefferson(D), -370701 Kimberly Hardy(D), -370702 Maad Abu-Ghazalah(L), -370801 Colby Watson(D), -370901 Richard Ojeda(D), -371001 Ashley Bell(D), -371002 Steven Feldman(L), -371101 Jamie Ager(D), -371102 Travis Groo(L), -371103 John Rogers(I), -371201 Jack Codiga(R), -371301 Paul Barringer(D), -371302 Anthony Aguilar(Green), -371303 Steven Swinton(L), -371401 Lakesha Womack(D).

## Verification
`NC OK: 14 races, 39 active rc, 14 incumbents, 0 null pid, 0 dup`. Idempotent.

## Post-Wave-2 full-gate state
156-verify.sql: all structural assertions PASS (USHC2-03a/b, 02a, 02c incl. McDowell, D-04-GA, D-04-GA13, D-02); first fail is USHC2-04 (headshots, Wave 3) listing all 62 new candidates — expected.
