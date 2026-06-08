BEGIN;

-- ============================================================
-- Phase 108 final audit snapshot, applied 2026-06-08
-- (matches v2.9 milestone close — LA County City Officials)
--
-- This migration is comment-only: zero DDL/DML between BEGIN and COMMIT.
-- Its purpose is to anchor the audit timestamp into the migrations chain
-- and serve as a single canonical record of what Phase 108 shipped.
--
-- Run: psql "$DATABASE_URL" -f backend/migrations/310_la_wave4_geo_id_audit.sql
-- ============================================================

-- ============================================================
-- PHASE 108 PER-CITY POLITICIAN COUNTS (as of 2026-06-08)
-- Format: <City Name> (geo_id=<FIPS>): <N> politicians, <M> offices, wave
-- ============================================================

-- Wave 1 — Gap-fill existing Tier 1 cities (migrations 293-299)
-- City of Long Beach (geo_id=0643000): 9 politicians, 10 districts (all 9 council + Mayor pre-existing)
-- City of Glendale (geo_id=0630000): 5 politicians, 2 districts (+1 Ara Najarian -700100)
-- City of Burbank (geo_id=0608954): 5 politicians, 3 districts (geo_id backfill only)
-- City of Downey (geo_id=0619766): 6 politicians, 7 districts (+2 Saab -700160, Pelc -700161)
-- City of El Monte (geo_id=0622230): 7 politicians, 5 districts (geo_id backfill only; 6 unique + Mayor)
-- City of Inglewood (geo_id=0636546): 6 politicians, 6 districts (geo_id backfill only)
-- City of Lancaster (geo_id=0640130): 5 politicians, 3 districts (geo_id backfill only)
-- City of Norwalk (geo_id=0652526): 5 politicians, 3 districts (geo_id backfill only)
-- City of Palmdale (geo_id=0655156): 4 politicians, 5 districts (Mayor LOCAL_EXEC left empty — VERIFICATION-PENDING)
-- City of Pasadena (geo_id=0656000): 9 politicians, 9 districts (+1 Jess Rivas -700150)
-- City of Pomona (geo_id=0658072): 6 politicians, 5 districts (geo_id backfill only)
-- City of Santa Clarita (geo_id=0669088): 6 politicians, 6 districts (+1 Cameron Smyth -700180)
-- City of Torrance (geo_id=0680000): 8 politicians, 6 districts (geo_id backfill only; 7 unique)
-- City of West Covina (geo_id=0684200): 5 politicians, 5 districts (geo_id backfill only)

-- Wave 2 — Beverly Hills, Santa Monica, LA City offices (migrations 300-303)
-- City of Beverly Hills (geo_id=0606308): 6 politicians, 5+ offices (+2: Nazarian -700010, Fisher -700011)
-- City of Santa Monica (geo_id=0670000): 10 politicians, 7+ offices (+4: Hall -700030, Raskin -700031, Snell -700032, Zernitskaya -700033)
-- City of Los Angeles / LA City Controller (geo_id=0644000): Kenneth Mejia (-700001) linked; Clerk Patrice Lattimore (-700002, is_appointed=true)

-- Wave 3 — 10 new cities (migrations 304-309)
-- City of South Gate (geo_id=0673080): 5 politicians, 5 offices (range -700200..-700204)
-- City of Compton (geo_id=0615044): 5 politicians, 5 offices (range -700250..-700254; Clerk/Treasurer VERIFICATION-PENDING)
-- City of Carson (geo_id=0611530): 7 politicians, 7 offices (range -700300..-700306; Mayor + 4 council + Clerk + Treasurer)
-- City of Hawthorne (geo_id=0632548): 5 politicians, 5 offices (range -700350..-700354; Mayor + 4 at-large)
-- City of Whittier (geo_id=0685292): 5 politicians, 5 offices (range -700400..-700404; Mayor + 4 by-district)
-- City of Alhambra (geo_id=0600884): 5 politicians, 5 offices (range -700450..-700454; 5 by-district, NO Mayor office per Pitfall 7)
-- City of Gardena (geo_id=0628168): 5 politicians, 5 offices (range -700500..-700504; VERIFICATION-PENDING: Cerda + Tanaka)
-- City of Culver City (geo_id=0617568): 5 politicians, 5 offices (range -700550..-700554; 5 at-large)
-- City of West Hollywood (geo_id=0684410): 5 politicians, 5 offices (range -700600..-700604; FIPS corrected from 0684346)
-- City of El Segundo (geo_id=0622412): 5 politicians, 5 offices (range -700650..-700654; 5 at-large)

-- ============================================================
-- EXTERNAL_ID RANGE USAGE
-- ============================================================

-- external_id range used: -700654 (lowest) to -700001 (highest); total Phase 108 politicians: 63
-- (5 Wave 1 new + 6 Wave 2 new + 52 Wave 3 new = 63 new; backfills did not use new external_ids)
-- Detailed range breakdown:
--   -700001: Kenneth Mejia (LA City Controller) — external_id assigned to pre-existing row
--   -700002: Patrice Lattimore (LA City Clerk) — new insert
--   -700010: Sharona R. Nazarian (Beverly Hills Council) — new insert
--   -700011: Howard Fisher (Beverly Hills City Treasurer) — new insert
--   -700030: Dan Hall (Santa Monica Council) — new insert
--   -700031: Ellis Raskin (Santa Monica Council) — new insert
--   -700032: Barry Snell (Santa Monica Council) — new insert
--   -700033: Natalya Zernitskaya (Santa Monica Council) — new insert
--   -700100: Ara Najarian (Glendale Council) — new insert
--   -700150: Jess Rivas (Pasadena Council) — new insert
--   -700160: Alex Saab (Downey Council) — new insert
--   -700161: Don Pelc (Downey Council) — new insert
--   -700180: Cameron Smyth (Santa Clarita Council) — new insert
--   -700200..-700204: South Gate (5 at-large members)
--   -700250..-700254: Compton (Mayor + 4 by-district)
--   -700255..-700257: RESERVED for Compton Clerk/Treasurer/Attorney (VERIFICATION-PENDING)
--   -700300..-700306: Carson (Mayor + 4 council + Clerk + Treasurer)
--   -700350..-700354: Hawthorne (Mayor + 4 at-large)
--   -700400..-700404: Whittier (Mayor + 4 by-district)
--   -700450..-700454: Alhambra (5 by-district, no Mayor)
--   -700500..-700504: Gardena (Mayor + 4 at-large)
--   -700550..-700554: Culver City (5 at-large)
--   -700600..-700604: West Hollywood (5 at-large)
--   -700650..-700654: El Segundo (5 at-large)
-- Ranges not yet consumed: -700101..-700149, -700162..-700179, -700181..-700199

-- ============================================================
-- VERIFICATION-PENDING ITEMS COMPILED FROM MIGRATIONS 293-309
-- ============================================================

-- VERIFICATION-PENDING items compiled from migrations 293-309:
-- VP-1 (migration 297): Alex Saab (Downey, -700160) — name confirmed from available records
--       but official cityofdowney.net page not directly fetched. Verify at downeyca.org/government/city-council
-- VP-2 (migration 297): Don Pelc (Downey, -700161) — same as VP-1; spot-verify current roster
-- VP-3 (migration 298): Palmdale Mayor seat — Austin Bishop in DB as Council Member (-201331)
--       but Mayor status uncertain. LOCAL_EXEC district left empty. Verify at cityofpalmdale.org/City-Council
-- VP-4 (migration 305): Compton City Clerk — elected per charter but name unconfirmed (city website
--       inaccessible). Slot -700255 reserved. Verify at comptoncity.org
-- VP-5 (migration 305): Compton City Treasurer — elected per charter but incumbent name unconfirmed
--       (Wikipedia listed Brandon Mims but unverified). Slot -700256 reserved. Verify at comptoncity.org
-- VP-6 (migration 305): Compton City Attorney — VACANT per Wikipedia as of 2026-06-08.
--       Slot -700257 reserved. Insert when post-vacancy occupant confirmed.
-- VP-7 (migration 308): Gardena Mayor Tasha Cerda (-700500) — June 2, 2026 re-election not confirmed.
--       Inserted as is_incumbent=true. Verify at cityofgardena.org or LA County registrar.
--       If she lost, update is_incumbent=false in follow-up migration.
-- VP-8 (migration 308): Gardena Council Rodney G. Tanaka (-700502) — same as VP-7; seat was up June 2026.

-- ============================================================
-- LAOF REQUIREMENT CLOSURE CONFIRMATIONS
-- ============================================================

-- LAOF-01 closed: true
--   Basis: Migrations 293-299 (Wave 1). All 14 Tier 1 cities have >= 1 politician.
--   Verification gate: Assertion 3 in verify-la-county-108.sql (all 14 geo_ids return >= 1 politician).
--   Deferred: Palmdale Mayor (VP-3); does not block LAOF-01 (city has council members).
-- LAOF-02 closed: true
--   Basis: Migrations 300-303 (Wave 2). BH=6, SM=10, Controller+Clerk linked.
--   Verification gate: Assertions 4 and 5 in verify-la-county-108.sql.
--   Note: City Attorney office left vacant (Feldstein Soto lost June 2026 primary — RESEARCH.md Critical Finding 1).
-- LAOF-03 closed: true
--   Basis: Migrations 304-309 (Wave 3). All 10 new city governments created; 52 politician records.
--   Verification gate: Assertion 6 in verify-la-county-108.sql (new_governments=10, wave3_politicians>=45).
--   Deferred: Compton Clerk/Treasurer/Attorney (VP-4/5/6); Gardena Cerda/Tanaka (VP-7/8).
-- LAOF-04 closed: true
--   Basis: All 26 Phase 108 FIPS codes present in essentials.districts.geo_id across Waves 1-3.
--   Verification gate: Assertion 2 in verify-la-county-108.sql (all 26 geo_ids return district_rows >= 1).
--   West Hollywood FIPS 0684410 verified (corrected from RESEARCH.md inferred 0684346).
-- LAOF-05 closed: true
--   Basis: All 63 Phase 108 politicians (external_id BETWEEN -700699 AND -700001) have:
--     photo_origin_url IS NOT NULL, office_id IS NOT NULL, party IS NULL, is_incumbent = true.
--   Verification gate: Assertion 1 in verify-la-county-108.sql (failures = 0).
-- LAOF-06 closed: true
--   Basis: No at-large city (Alhambra, Culver City, West Hollywood, El Segundo, South Gate)
--     has a Mayor chamber or LOCAL_EXEC district created by Phase 108. Pre-existing LOCAL_EXEC
--     rows from race migrations are present but hold no Phase 108 politicians.
--   Verification gate: Assertion 7 in verify-la-county-108.sql (wave3_politicians_in_local_exec = 0).

-- ============================================================
-- PHASE 108 STATISTICS SUMMARY
-- ============================================================

-- Phase 108 total new politician records: 63
-- Phase 108 total migrations applied: 18 (migrations 293-310)
-- Phase 108 cities covered: 27 (14 Tier 1 gap-fill + BH + SM + LA City + 10 new)
-- Phase 108 distinct FIPS codes populated on essentials.districts: 26
-- Phase 108 verification script: backend/scripts/verify-la-county-108.sql (8 assertions)
-- Phase 108 smoke test script: backend/scripts/smoke-la-representatives-me.ts
-- Phase 108 VERIFICATION-PENDING items deferred to follow-up: 8 (VP-1 through VP-8)
-- Phase 108 Milestone: v2.9 — LA County City Officials

COMMIT;
