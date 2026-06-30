---
phase: 151-fl-candidate-seeding-provisional-qualified-field
plan: 03
wave: 2
status: complete
requirements: [USHC-02, USHC-03]
---

# 151-03 SUMMARY — 155→158 records + full provisional race_candidates field

## Outcome
Migration `1116_seed_fl_2026_house_candidates.sql` applied to prod. Inserted **158 NEW politicians + 181 race_candidates** (full provisional field across all 28 FL races). Verified, idempotent. Gate now PASSES USHC-03a/b/c, D-04, USHC-02a/b/c, D-05, and the 17-independent in-scope resolution (fails only at USHC-04/05 — no headshots/stances yet, expected pre-W3).

## Counts (corrected from the 148 ~155 estimate)
- **181 total qualified candidates** across 28 FL districts (the true `general_candidates` sum; the earlier "209" was a bad formula).
- **23 REUSE**: 20 sitting renominated home incumbents (`is_incumbent=true`, 148 incumbent_pid) + **3 cross-district** redistricted incumbents (`is_incumbent=false`): Frankel `-12022`→FL-23, Moskowitz `-12023`→FL-25, Wasserman Schultz `-12025`→FL-20.
- **158 NEW** records (band `-(1210000+cd*100+seq)`, -1210101..-1212802; band verified empty pre-insert). This is **3 more than 148's `new_records_needed`=155** because 148 wrongly classified Cherfilus-McCormick + 2 others as reuse (the D-03 naive-match caveat).

## Dedup (D-03, live-verified 2026-06-29)
- Home incumbents matched by **accent-normalized last name** within renominated districts (display names differ from the map: "Greg Steube"≠"W. Gregory Steube", "Carlos Giménez"≠"Carlos A. Gimenez", etc.) — all 20 matched.
- Cross-district 3 matched by **exact external_id** (not name substring — FEC-noise guard).
- **Cherfilus-McCormick = NEW** (0 prior records, Pitfall 3 — corrects CONTEXT D-03).
- **3 common-name collisions inspected and kept NEW** (unrelated people): `Mike Johnson` FL-7 (NOT Speaker Mike Johnson -22004, has office), `James Martin` FL-21 (null-ext, no office — noise), `Michael Thompson` FL-22 (null-ext... has office — different officeholder). Reusing any would link a wrong person; kept NEW per D-03 safety.
- Retired/redistricted incumbents (FL-2 Dunn/-16 Buchanan/-19 Donalds/-24 Wilson + FL-22/23/25 redistricted) confirmed ABSENT in their old seat.

## The 17-independent external_ids (for 151-04 headshots + 151-05 stances — the USHC-04/05 in-scope set)
| Dist | Name | external_id |
|------|------|-------------|
| FL-1 | Tyler Davis | -1210104 |
| FL-3 | Mike Klein | -1210305 |
| FL-4 | Todd Schaefer | -1210405 |
| FL-6 | Andrew Parrott | -1210609 |
| FL-6 | Alec Pavlik | -1210610 |
| FL-12 | Branden Scrivener | -1211203 |
| FL-13 | Tony D'Arrigo | -1211304 |
| FL-16 | Mark Davis | -1211609 |
| FL-17 | Michael Quirk | -1211703 |
| FL-18 | Deva Simmons | -1211802 |
| FL-19 | Seth Haskins | -1211914 |
| FL-20 | Kedner MaximeDe | -1212009 |
| FL-21 | Alexander Cooke | -1212103 |
| FL-24 | Andy Daro | -1212409 |
| FL-24 | Patricia Gonzalez | -1212410 |
| FL-26 | Deborah Ann Meidinger Hosey | -1212602 |
| FL-28 | Eddy Rojas | -1212802 |

## Verification
- DB: 28 races, 181 active rc, 0 null politician_id, 0 dup full_name. Idempotent (`INSERT 0 0` ×2 on re-run).
- Gate: PASS through D-05 + in-scope resolution; USHC-04/05 fail pre-W3 (documented).

## Artifacts
- `backend/migrations/1116_seed_fl_2026_house_candidates.sql`
- `backend/data/seed-fl-2026-house/151-03-fl-reconciliation.csv` (181 rows) + `build_reconciliation.py` / `build_migration.py` (reproducible generators).

## Gate-syntax fix applied (151-02 follow-up)
Removed invalid `ORDER BY` after `INSERT ... VALUES` on `_reuse_pid` / `_lost` (Postgres rejects it; "column external_id does not exist"). Those tables are used in order-independent NOT EXISTS/JOIN checks, so ORDER BY was unnecessary. The 143 honest-skip ORDER-BY lesson still applies to `_stance_skip`/`_headshot_skip` (SELECT FROM VALUES ORDER BY), which W3 populates.
