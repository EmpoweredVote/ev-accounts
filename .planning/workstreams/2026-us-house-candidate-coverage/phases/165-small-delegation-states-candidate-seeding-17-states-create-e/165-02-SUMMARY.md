---
phase: 165-small-delegation-states-candidate-seeding-17-states-create-e
plan: 02
state: UT
status: complete
completed: 2026-07-07
requirements: [USHC3-02, USHC3-03, USHC3-04]
migrations_applied: [1252, 1253]
election_name: "UT 2026 Statewide General"
---

# 165-02 SUMMARY — UT court-ordered re-key (binding 164.1-ut-wiring-contract executed verbatim)

## What was built
'UT 2026 Statewide General' (general, 2026-11-03) + 4 races on UT's **EXISTING NATIONAL_LOWER offices** (geo_ids 4901–4904 persist), with incumbents re-linked onto their **NEW** district's race per the LWV v. Utah Legislature correspondence table. 12 new challengers + 7 reused pids. Offices proven untouched.

## Key facts (for 165-17 gate)
- **NOTOUCH md5 (FIPS-49 offices, id:district_id:representing_state ORDER BY id): `4d8bbfb221d4babca6e9f7201bce391e` before = after** — byte-identical to the 1641-verify.sql pinned baseline. grep of both migrations: **0 forbidden-write strings** (offices/geo-districts/user-districts never written; migration comments deliberately avoid the literal strings).
- **Incumbent re-link (candidacy ≠ office):** Moore e365a1d4 → 4902 race, Maloy a7983eb6 → 4903, Kennedy 9e3164d5 → 4904, all is_incumbent=true, existing pids (0 new records). Offices remain OLD-keyed (4901→Moore, 4902→Maloy, 4903→Kennedy, 4904→Owens) — correct until Jan-2027 promotion.
- **Owens cb87ddbb: 0 race_candidates rows anywhere** (retired). All Jun-23 primary-losers: 0 rows.
- **4901 OPEN** (new compact SLC district): McAdams b78f058c (reuse) + Riley Owen -490101 + Jesse West -490102 + Elias Henry Montgomery -490103.
- **Primary-winner pid reuse (race_candidates only):** Crosby e3cbc264 (4902), Udell a7e29796 (4903), Larsen 6708ceaa (4904).
- **New challenger external_ids (-490402..-490101, band was empty live):** 4902: Cottam -490201, Bowen -490202, Moesinger -490203; 4903: Easley -490301, Hooslyn -490302, Scott -490303, Stoddard -490304; 4904: Wright -490401, Burt -490402.
- **Active counts:** 4901=4, 4902=5, 4903=6, 4904=4 (19 total). 4 races, 0 NULL office_id. Idempotent: 2nd run = 31× `INSERT 0 0`.

## Headshots — ALL 12 honest-skip (documented in `_ut-house-headshot-results.json`)
No new UT challenger has a free-license candidate-person Wikipedia page (guard rejected election-list/senate/list pages). Reused pids (incumbents + McAdams/Crosby/Udell/Larsen) have no external_id → outside band, already imaged. Pin list: -490101 Owen, -490102 West, -490103 Montgomery, -490201 Cottam, -490202 Bowen, -490203 Moesinger, -490301 Easley, -490302 Hooslyn, -490303 Scott, -490304 Stoddard, -490401 Wright, -490402 Burt.

## Files
- `backend/scripts/165-ut-generate.mts`
- `backend/migrations/1252_seed_ut_2026_house_election_races.sql` + `1253_seed_ut_2026_house_candidates.sql`
- `backend/scripts/seed-ut-house-headshots.py` (+ gitignored results JSON)
- `backend/data/seed-ut-2026-house/165-02-ut-reconciliation.csv`

## Self-Check: PASSED
4 races on existing offices, 0 NULL office_id; NOTOUCH md5 identical; 0 forbidden writes (grep both files = 0); Moore/Maloy/Kennedy on 4902/4903/4904 is_incumbent=true; 4901 open; Owens 0 rows; 0 dup full_name; idempotent verified; every new challenger honest-skipped with documentation. Ready for stance research (165-10) + Jan-2027 promotion.
