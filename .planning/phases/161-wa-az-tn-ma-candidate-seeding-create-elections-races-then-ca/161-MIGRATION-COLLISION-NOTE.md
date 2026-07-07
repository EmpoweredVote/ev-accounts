# Phase 161 — Migration Number Collision (known, non-blocking)

The parallel Hillsboro/Tigard OR session (Phases 177/178) independently claimed
migration numbers that collide with Phase 161's AZ/WA seed migrations:

| Number | Phase 161 file | Parallel-session file |
|--------|----------------|-----------------------|
| 1187 | 1187_seed_az_2026_house_elections_races.sql | 1187_sherwood_city_council.sql |
| 1188 | 1188_seed_az_2026_house_candidates.sql | 1188_sherwood_headshots.sql |
| 1189 | 1189_seed_wa_2026_house_elections_races.sql | 1189_rosener_stances.sql |

**Assessment:** NON-BLOCKING. Each file is a distinct filename that already applied
once to prod (idempotency-verified); the repo already tolerates duplicate migration
numbers (historical dupes: 230/231/244/253/267/276/293/365/949/950), so applyMigrations
keys on full filename, not number. AZ/WA and the Sherwood/Rosener data touch disjoint
tables — apply order is irrelevant. NOT renumbered (renaming applied migrations risks
re-run confusion for zero benefit).

**Action for downstream Phase 161 plans:** the true high-water mark is now **1193**
(1193_mays_stances.sql). TN seed (161-06) and MA seed (161-08) MUST start at 1194+ and
re-check `ls backend/migrations | sort | tail -5` live at author time.
