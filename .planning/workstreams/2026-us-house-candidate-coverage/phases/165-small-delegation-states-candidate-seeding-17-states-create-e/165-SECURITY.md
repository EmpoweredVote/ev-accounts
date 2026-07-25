# Phase 165 — Security Audit (Small-Delegation States, 17 states, create-e)

**Audited:** 2026-07-08
**Phase:** 165 — Small-delegation states candidate seeding (17 states)
**ASVS Level:** N/A (pure-data seeding phase against PROD; no runtime auth/session/access-control surface)
**Result:** SECURED — 90/90 threats CLOSED (81 mitigate, 9 accept)

This is the first SECURITY.md for this repo; no prior accepted-risk log existed. All verification below
was performed against implemented code (migrations 1250-1281, generator scripts, headshot scripts, stance
push scripts) and the live-executed `165-verify.sql` gate (15/15 PASS on PROD, `165-UAT.md` 6/6 PASS). No
implementation files were modified.

## Method

90 threats declared across 165-01..17-PLAN.md `<threat_model>` blocks, clustering into 6 recurring
mitigation classes plus 9 `accept`-disposition tooling rows. Each class was spot-verified against actual
migration SQL / generator / script content in ≥4 distinct plans; the two structural threats (UT dual-map
NOTOUCH, NV/ME candidates-only reconciliation) were verified exhaustively across all 32 migrations.
SUMMARY.md files for all 17 plans were checked for a `## Threat Flags` section — none present, so there
are no unregistered new-attack-surface flags this phase.

## Class-by-Class Verification

### Class 1 — Tampering (SQLi): unescaped candidate names in generated SQL
**Threats:** T-165-01-01, 01-04(dup id), 02-04, 03-01, 04-01, 05-01, 06-01, 07-01, 08-01 (one per Wave-1 plan)
**Evidence:** `function sqlStr(s: string) { return "'" + s.replace(/'/g, "''") + "'"; }` present in all 15
`backend/scripts/165-*-generate.mts` files (verified via grep, e.g. `165-wy-generate.mts:20`,
`165-ut-generate.mts:54`, `165-ak-generate.mts:46`). Every free-text field (name/first/last/source/
description) in the generator output is wrapped in `sqlStr()` — confirmed by reading `165-wy-generate.mts`
in full and diffing its emitted SQL against migration `1275_seed_wy_2026_house_candidates.sql` (byte-for-byte
match). No migration in the phase contains a raw, unescaped single-quote inside a string literal.
**Status:** CLOSED.

### Class 2 — Repudiation: duplicate politician records (homonyms, dormant pids, state-leader reuse, Chapman fix)
**Threats:** T-165-01-03, 02-02, 03-03, 04-02, 05-02, 06-02, 07-03, 08-02 (dup-incumbent, one per Wave-1 plan)
**Evidence:**
- Ran an exhaustive parity check across all 32 migrations: every `INSERT INTO essentials.politicians` line
  has a matching `WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = ...)` guard
  (0 mismatches), and every `INSERT INTO essentials.race_candidates` line has a matching
  `NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE ...)` guard (0 mismatches).
- Chapman fix-not-recreate: `1250_seed_nv_2026_house_candidates.sql:56-60` — `UPDATE essentials.race_candidates
  SET politician_id = ... WHERE id = '08dfb911-...'::uuid AND politician_id IS NULL;` (targeted, guarded
  update, not a bare UPDATE; no second Chapman row created).
- WY state-leader reuse: `1275_seed_wy_2026_house_candidates.sql:48-52` — Chuck Gray wired via
  `'b503b679-773a-4eee-9c16-e73bff1a723f'::uuid` (v2.18 pid), no `politicians` INSERT for Gray.
- SD state-leader reuse (Jackley) and UT primary-winner reuse (McAdams/Crosby/Udell/Larsen) confirmed same
  pattern in `1253_seed_ut_2026_house_candidates.sql:52-100` (all keyed by known UUID literal, guarded).
- Live gate `165-verify.sql` CRITERION 4 (DUPNAME) asserts 0 duplicate `lower(full_name)` per state and
  **passed on PROD** per `165-UAT.md` (`ALL ASSERTIONS PASSED`).
**Status:** CLOSED.

### Class 3 — Information disclosure: party leaking onto the candidate card
**Threats:** T-165-01-04(id), 02-06, 03-05, 04-05, 05-03, 06-06, 07-06, 08-05
**Evidence:** `grep -h "INSERT INTO essentials.race_candidates" <all 32 migrations> | sort -u` returns exactly
one column list: `(race_id, politician_id, full_name, first_name, last_name, is_incumbent,
candidate_status, source)` — no `party`/`party_affiliation` column in any of the 32 migration files. Gate
CRITERION 5 (`165-verify.sql:149-153`) confirms `essentials.race_candidates` itself has no such column
(`information_schema.columns` check), and this passed on PROD.
**Status:** CLOSED.

### Class 4 — Spoofing: wrong-person headshot
**Threats:** T-165-01-05, 02-07, 03-06, 04-06, 05-04, 06-07, 07-07, 08-06
**Evidence:** All 17 `backend/scripts/seed-{state}-house-headshots.py` clones present. Verified identical
guard-function counts (`_NON_PERSON_TITLE`=3, `_BAD_DISAMBIG`=3, `_HISTORICAL_YEAR`/`_desc_is_historical`=5,
`_title_is_candidate_person`=2) across all 17 files. Diffed the guard block of `seed-wy-house-headshots.py`
against the canonical `seed-ms-house-headshots.py` baseline: byte-identical except the two explicitly
documented localization points (place-token `mississippi`→`wyoming`, `RESULTS_JSON` filename) — confirms
the frozen guard suite was cloned unmodified, not weakened.
**Status:** CLOSED.

### Class 5 — Spoofing: retired/withdrawn candidates surfacing on the 2026 ballot
**Threats:** T-165-02-03(Owens), 04-04(Bacon), 06-04(Pappas), 07-04(Hageman), 08-04(Zinke/Johnson),
04-03/06-03/08-03(non-certified pending independents)
**Evidence:**
- Grepped candidate migrations for the retired incumbents' full names — zero `INSERT INTO
  essentials.race_candidates` rows for "Don Bacon" (1259), "Chris Pappas" (1267), "Ryan Zinke" (1277),
  "Dusty Johnson" (1281); each migration's own header comment documents the `NO row` / `REUSE-NO-ROW`
  decision.
- UT: gate CRITERION 8 (`165-verify.sql:216-218`) asserts retired Owens
  (`cb87ddbb-5a83-45b7-b67a-789e63f0e58b`) has 0 active `race_candidates` rows — **passed on PROD**.
- Excluded pending-independents (Ahlman/Budke/Cohen NE; Black/Mahrou/Sykes NH; Persico/Eisenhauer MT;
  Neville/Tuttle ND) confirmed absent from any `INSERT INTO essentials.politicians` line in their
  respective migrations — the only occurrences of these names are in explanatory header comments.
**Status:** CLOSED.

### Class 6 — Tampering: structural traps (UT dual-map NOTOUCH; NV/ME candidates-only reconciliation)
**Threats:** T-165-02-01, 02-05, 17-01, 17-02, 17-03, 17-06 — **verified exhaustively (all 32 migrations),
per task instruction.**
**Evidence:**
- `grep -niE "UPDATE|INSERT INTO|DELETE FROM essentials\.(offices|districts|geo_districts|user_districts)"`
  across all 32 Phase-165 migration files (1250-1281): **zero matches**. `1252_seed_ut_2026_house_election_
  races.sql` and `1253_seed_ut_2026_house_candidates.sql` (the only two files touching UT/FIPS-49) contain
  only `INSERT INTO essentials.elections/races/politicians` and `INSERT INTO essentials.race_candidates`
  statements — no office/district writes anywhere, confirming the binding 164.1-ut-wiring-contract negative
  constraint is honored in the actual SQL, not just in comments.
- `1253_seed_ut_2026_house_candidates.sql:59-100` re-links Moore→4902/Maloy→4903/Kennedy→4904 by known UUID
  literal, keyed via `d.geo_id = '490X'` joins — matches the correspondence table exactly (no
  Moore-on-4901 misrouting).
- Gate CRITERION 8 (UT-REKEY, `165-verify.sql:198-219`) computes a live md5 over FIPS-49 `essentials.offices`
  rows and asserts byte-identity to the pre-migration baseline `4d8bbfb221d4babca6e9f7201bce391e` — **passed
  on PROD**, i.e. empirically confirmed zero office/district perturbation, not just static-analysis absence.
- `1250_seed_nv_2026_house_candidates.sql` and `1251_seed_me_2026_house_candidates.sql`: grepped for
  `INSERT INTO essentials.elections` / `INSERT INTO essentials.races` — **zero matches** in both files.
  Only `politicians` INSERTs, `race_candidates` INSERTs, and one guarded status-normalization `UPDATE`
  (ME, `filed`→`active`, idempotent). Confirms no new NV/ME election or race was authored.
- Gate CRITERIA 6/7 (NV-RECONCILE/ME-RECONCILE, `165-verify.sql:156-190`) assert exactly the 4 pre-existing
  NV race UUIDs and 2 pre-existing ME race UUIDs are in use, 1 election each, 0 races outside that set —
  **passed on PROD**.
**Status:** CLOSED (all sub-threats).

### Stance-pipeline threats (T-165-09..16, 27 threats across 8 plans)
**Categories:** Repudiation (unsourced/party-inferred rows, zero-tier/UUID-keyed coverage gaps), Tampering
(surname-leak in selected quotes), Denial of service (stance-agent rate-limit death)
**Evidence:**
- `_push.ts` and `_push_uuid.ts` present in all 17 `backend/data/stance-research/{state}-2026-house/`
  directories; surname-leak guard (`grep -c "surname\|leak"` = 7 in both files, all 17 states) confirmed as
  a real functional check (read in full for `wy-2026-house/_push.ts:80-90`): regex-escapes the candidate's
  surname and skips `readrank_selected` if the de-identified quote text contains it as a whole word.
- UUID-keyed re-link path used in practice, not just available: `ut-2026-house/` contains
  `_uuid-ben-mcadams.csv`, `_uuid-jonny-larsen.csv`, `_uuid-kent-udell.csv`, `_uuid-peter-crosby.csv`.
- 0-unsourced / coverage: gate CRITERIA USHC3-05a/b/c (`165-verify.sql:358-411`) directly query
  `inform.politician_answers`/`inform.politician_context` on PROD and assert 0 unsourced rows, every banded
  new candidate covered or pinned, and the 7 UUID-keyed targets (Pingree + McAdams/Crosby/Udell/Larsen/
  Gray/Jackley) each have ≥1 sourced stance — **all passed on PROD** per `165-UAT.md`.
- 3-concurrency discipline: corroborated in `165-09-SUMMARY.md` ("3-concurrency held throughout; first wave
  validated before further dispatch"), `165-14-SUMMARY.md` ("pushed to PROD in multiple 3-concurrency
  waves"), `165-15-SUMMARY.md` (WY's 18-field "run as its own multi-wave sequence").
**Status:** CLOSED (all 27).

### Gate-level threats (T-165-17-01..06)
Directly correspond to Class 6 (UT-REKEY, NV/ME-RECONCILE) and the PROVISIONAL/COLLISION-BAND/pin-ordering
concerns already verified above at the migration level (PROVISIONAL marker present on exactly the 7
late-primary states AK/HI/NH/RI/DE/VT/WY and absent from the 7 decided states NM/NE/WV/ID/MT/ND/SD, checked
directly against all 14 election-migration files; DE's Earl Cooper seeded at `-100048`, respecting the
`safe_start_seq=48` collision floor). All re-asserted live by `165-verify.sql` and passed on PROD.
**Status:** CLOSED (all 6).

## Accepted Risks Log (disposition = accept)

| Threat ID | Component | Accepted Risk | Evidence of No New Exposure |
|-----------|-----------|----------------|------------------------------|
| T-165-01-SC | npm/psql tooling | Zero new package installs this phase | `git log --oneline -- backend/package.json` shows no `package.json` commit accompanying any Phase-165 migration commit (checked against `098deaa7` NV/ME, `39a36bb8` MT/ND/SD); last package.json change (`1494b4a4`, pdf-parse) predates and is unrelated to Phase 165 |
| T-165-02-SC | npm/psql tooling | Zero new package installs (UT track) | Same as above |
| T-165-03-SC | npm/psql tooling | Zero new package installs (AK track) | Same as above |
| T-165-04-SC | npm/psql tooling | Zero new package installs (NM+NE track) | Same as above |
| T-165-05-SC | npm/psql tooling | Zero new package installs (WV+ID track) | Same as above |
| T-165-06-SC | npm/psql tooling | Zero new package installs (HI+NH track) | Same as above |
| T-165-07-SC | npm/psql tooling | Zero new package installs (RI+DE+VT+WY track) | Same as above |
| T-165-08-SC | npm/psql tooling | Zero new package installs (MT+ND+SD track) | Same as above |
| T-165-17-SC | npm/psql tooling | Zero new package installs (gate/smoke track) | Same as above |

All 9 `accept` rows are CLOSED — the accepted risk is documented here (first entry in this log) and
independently confirmed by absence of any `package.json` change in the phase's commits.

## Unregistered Flags

None. All 17 SUMMARY.md files were checked for a `## Threat Flags` section; none exists in this phase's
summaries, so there is no new attack surface reported by the executor beyond the 90 registered threats.

## Standing Invariants for Phase 166 (carried forward, not this phase's responsibility to re-verify)

Per `165-verify.sql`'s own header and CRITERION comments, Phase 166's consolidated gate must inherit:
NV-RECONCILE + ME-RECONCILE + UT-REKEY (the Class-6 structural invariants) alongside the pre-existing 164
OPEN-SEAT/OR-REUSE invariants. This is a forward-looking note, not an open item for Phase 165.

## Summary Table

| Threat ID(s) | Category | Disposition | Evidence |
|---|---|---|---|
| T-165-0{1-8}-01/04 (SQLi, 8 threats) | Tampering | mitigate | `sqlStr()` in all 15 generators; verified against migration output |
| T-165-0{1-8}-0x (dup records, 8 threats) | Repudiation | mitigate | NOT EXISTS guard parity (32/32 migrations, 0 mismatches); Chapman UPDATE; Gray/Jackley UUID reuse |
| T-165-0{1-8}-0x (party disclosure, 8 threats) | Information disclosure | mitigate | Single column-list across all 32 migrations, no party column |
| T-165-0{1-8}-0x (headshot, 8 threats) | Spoofing | mitigate | Frozen guard suite, byte-diffed, all 17 states |
| T-165-0{2,4,6,7,8}-0x (retired/excluded, 9 threats) | Spoofing | mitigate | Zero INSERT rows for Bacon/Pappas/Zinke/Johnson/Owens/excluded independents |
| T-165-{02,17}-0x (structural NOTOUCH/RECONCILE, 6 threats) | Tampering | mitigate | Exhaustive migration grep + live md5/UUID gate assertions, PASS on PROD |
| T-165-09..16 (stance pipeline, 27 threats) | Repudiation/Tampering/DoS | mitigate | Surname-leak guard (17/17), UUID push path used, 0-unsourced gate PASS, 3-concurrency corroborated in SUMMARYs |
| T-165-06/07-05, 17-06 (PROVISIONAL/collision, 5 threats) | Tampering | mitigate | Marker presence/absence checked directly on all 14 election migrations; DE floor=48 confirmed |
| T-165-0{1-8}-SC + 17-SC (9 threats) | Tampering (tooling) | accept | No package.json changes in Phase 165 commits |

**Total: 90/90 CLOSED.**
