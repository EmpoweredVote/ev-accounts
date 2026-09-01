#!/usr/bin/env node
/**
 * gen-ga-legislature-migrations.mjs
 *
 * Emits the two GA-2 migrations from data/ga-legislature-roster.json.
 * Structure first, occupancy second, per spec §4 — so a re-seat never re-runs office creation.
 * Reads nothing from the database and writes nothing to it.
 *
 * 🔴 TAKE THE MIGRATION NUMBER LAST. These are written as CC_wip_*.sql on purpose. Rename,
 * apply and commit in one go, after re-counting the free slot against origin/master.
 *
 *   node scripts/gen-ga-legislature-migrations.mjs
 */
import * as fs from 'fs';
import * as path from 'path';
import { fileURLToPath } from 'url';

const HERE = path.dirname(fileURLToPath(import.meta.url));
const ROSTER = path.join(HERE, '..', 'data', 'ga-legislature-roster.json');
const MIGRATIONS = path.join(HERE, '..', 'migrations');

const GOVERNMENT_ID = 'eaeb1bd2-6bdb-4475-9bdc-e29acca8bebf'; // State of Georgia
const SOURCE = 'Georgia General Assembly member list, https://www.legis.ga.gov/members/{house,senate}, ' +
               'reconciled against the Find Your Legislator district map, read 2026-08-31 (GA-2)';

/** 🔴 REUSE, NOT RE-CREATE. Both are already in production as 2026 US House candidates, with
 *  compass answers attached; a second row would split the person in two. Identity confirmed
 *  district-for-district, not by name alone:
 *    Houston Gaines  GA House D120, won the GOP nomination for GA-10  -> our -131001 is the GA-10 candidate
 *    Jasmine Clark   GA House D108, won the Dem nomination for GA-13  -> our -131301 is the GA-13 candidate
 *  🔴 AND TWO NAME MATCHES ARE DIFFERENT PEOPLE, which is why a name match is never identity:
 *    John Carson  -810030 is a COLORADO state senator, not Georgia's HD-46 member
 *    Kim Jackson  -364328 is a UTAH COUNTY treasurer, not Georgia's SD-41 senator
 *  Both of those get a fresh row. This is the Robert Nash failure, caught before it happened. */
const REUSE = new Map([
  ['Houston Gaines', -131001],
  ['Jasmine Clark', -131301],
]);

/** 🔴 SENATE DISTRICT 12 IS VACANT, AND THE STATE'S OWN ROSTER IS WRONG ABOUT IT.
 *  legis.ga.gov still lists Freddie Powell Sims as the sitting senator with no dateVacated.
 *  She resigned 2026-03-23 (WALB, Albany Herald, Early County News, all naming the date).
 *  Open States carries 55 Georgia senators and no District 12 at all. Two independent lines
 *  say the seat is not hers; the chamber's own record is simply stale. This is the Birdwell
 *  class exactly, and seating from the roster alone would have reproduced it.
 *  vacant_since is left NULL: what is documented is the ANNOUNCEMENT, and no authoritative
 *  effective date was published, so no date is invented. */
const VACANT = [{ chamber: 'STATE_UPPER', district: 12, note: 'Freddie Powell Sims resigned 2026-03-23' }];

const CHAMBERS = {
  STATE_LOWER: { name: 'Georgia House of Representatives', title: 'Representative', seats: 180, idBase: -1330000 },
  STATE_UPPER: { name: 'Georgia State Senate', title: 'Senator', seats: 56, idBase: -1330200 },
};

const q = (s) => (s === null || s === undefined ? 'NULL' : `'${String(s).replace(/'/g, "''")}'`);

const data = JSON.parse(fs.readFileSync(ROSTER, 'utf8'));
const isVacant = (r) => VACANT.some((v) => v.chamber === r.chamber && v.district === r.district);
const seated = data.roster.filter((r) => !isVacant(r));

for (const r of seated) {
  if (!r.first_name || !r.last_name) throw new Error(`${r.full_name}: source gave no structured name parts`);
}
const externalId = (r) => (REUSE.has(r.full_name) ? REUSE.get(r.full_name) : CHAMBERS[r.chamber].idBase - r.district);
const newRows = seated.filter((r) => !REUSE.has(r.full_name));
const lowBand = CHAMBERS.STATE_UPPER.idBase - CHAMBERS.STATE_UPPER.seats;   // -1330256
const highBand = CHAMBERS.STATE_LOWER.idBase - 1;                           // -1330001

// ── structure ────────────────────────────────────────────────────────────────
const officeValues = data.roster.map((r) => {
  const ch = CHAMBERS[r.chamber];
  return `  (${q(r.geo_id)}, ${q(r.chamber)}, ${q(ch.name)}, ${q(ch.title)})`;
}).join(',\n');

const structure = `-- CC_wip_ga_legislature_structure.sql
-- Knight Foundation program, wave GA-2 (structure half).
--
-- Creates the two Georgia legislative chambers under the existing 'State of Georgia'
-- government, and one office per district: 180 Representatives + 56 Senators = 236.
-- Creates NO people and NO terms -- the incumbents migration does that, and the two are
-- applied back to back.
--
-- 🔴 SENATE DISTRICT 12 IS VACANT AND IS FLAGGED HERE, in the structure migration, not later.
-- legis.ga.gov still lists Freddie Powell Sims as its sitting senator with no vacate date.
-- She RESIGNED 2026-03-23 (WALB, Albany Herald and Early County News all name the date), and
-- Open States carries 55 Georgia senators with no District 12 at all. Two independent lines say
-- the seat is not hers and the chamber's own record is stale. Seating from that roster alone
-- would have put a departed senator in a live seat -- the TX SD-22 Birdwell failure, exactly.
--
-- vacant_since is left NULL. What is documented is the ANNOUNCEMENT of a resignation; no
-- authoritative effective date was published, and CLAUDE.md forbids inventing one.
--
-- Flagging here is load-bearing twice over, same as FL-2:
--   1. check-address-reachability.mjs classifies DEAD_GEOGRAPHY as "reachable AND offices > 0
--      AND active_holders = 0 AND vacant_offices = 0". An unflagged empty office fires a NEW
--      ga|STATE_UPPER bucket and fails the gate.
--   2. essentials.offices_missing_terms separates flagged-vacant rows from unflagged ones, and
--      only the unflagged count is drift. Flagging here keeps that count steady in the window
--      between the two applies.
--
-- Districts and geometry come from scripts/load-state-tiger-boundaries.ts (wave GA-1), not from
-- this migration. 🔴 EVERY JOIN PAIRS geo_id WITH district_type: Georgia's collision is
-- THREE-WAY -- sldl runs 13001..13180, sldu 13001..13056, and 89 of the 159 county GEOIDs fall
-- inside the sldl range, so '13009' is Baldwin County AND House District 9.
--
-- Idempotent: every INSERT is NOT EXISTS-guarded and the vacancy UPDATE is guarded on the
-- current value. Ends with a post-verify gate.

BEGIN;

-- ─── Chambers ────────────────────────────────────────────────────────────────

INSERT INTO essentials.chambers (government_id, name, name_formal, official_count)
SELECT '${GOVERNMENT_ID}', 'Georgia House of Representatives', 'Georgia House of Representatives', 180
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
  WHERE government_id = '${GOVERNMENT_ID}' AND name = 'Georgia House of Representatives');

INSERT INTO essentials.chambers (government_id, name, name_formal, official_count)
SELECT '${GOVERNMENT_ID}', 'Georgia State Senate', 'Georgia State Senate', 56
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
  WHERE government_id = '${GOVERNMENT_ID}' AND name = 'Georgia State Senate');

-- ─── 236 offices, one per district ───────────────────────────────────────────

CREATE TEMP TABLE ga_offices(geo_id text, district_type text, chamber_name text, title text) ON COMMIT DROP;
INSERT INTO ga_offices(geo_id, district_type, chamber_name, title) VALUES
${officeValues};

DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM ga_offices;
  IF n <> 236 THEN RAISE EXCEPTION 'payload: expected 236 offices, got %', n; END IF;
  SELECT count(*) INTO n FROM ga_offices WHERE district_type = 'STATE_LOWER';
  IF n <> 180 THEN RAISE EXCEPTION 'payload: expected 180 House offices, got %', n; END IF;
  -- Every district must already exist from GA-1, matched on geo_id AND district_type.
  SELECT count(*) INTO n
    FROM ga_offices g
   WHERE NOT EXISTS (SELECT 1 FROM essentials.districts d
                      WHERE d.geo_id = g.geo_id AND d.district_type = g.district_type
                        AND lower(d.state) = 'ga');
  IF n <> 0 THEN RAISE EXCEPTION 'precondition: % district(s) from GA-1 are missing', n; END IF;
END $$;

INSERT INTO essentials.offices
       (chamber_id, district_id, title, representing_state, seats,
        is_appointed_position, is_vacant, faces_retention_vote, voting_powers)
SELECT ch.id, d.id, g.title, 'GA', 1, false, false, false, 'full'
  FROM ga_offices g
  JOIN essentials.districts d
    ON d.geo_id = g.geo_id AND d.district_type = g.district_type AND lower(d.state) = 'ga'
  JOIN essentials.chambers ch
    ON ch.government_id = '${GOVERNMENT_ID}' AND ch.name = g.chamber_name
 WHERE NOT EXISTS (SELECT 1 FROM essentials.offices o WHERE o.district_id = d.id);

-- ─── The one vacancy ─────────────────────────────────────────────────────────

UPDATE essentials.offices o
   SET is_vacant = true
  FROM essentials.districts d
 WHERE d.id = o.district_id
   AND d.geo_id = '13012' AND d.district_type = 'STATE_UPPER' AND lower(d.state) = 'ga'
   AND o.is_vacant = false;

-- ─── Post-verify ─────────────────────────────────────────────────────────────

DO $$
DECLARE n_off int; n_low int; n_upp int; n_vac int;
BEGIN
  SELECT count(*) INTO n_off FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'ga' AND d.district_type IN ('STATE_LOWER','STATE_UPPER');
  IF n_off <> 236 THEN RAISE EXCEPTION 'expected 236 GA legislative offices, got %', n_off; END IF;

  SELECT count(*) INTO n_low FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'ga' AND d.district_type = 'STATE_LOWER';
  SELECT count(*) INTO n_upp FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'ga' AND d.district_type = 'STATE_UPPER';
  IF n_low <> 180 OR n_upp <> 56 THEN
    RAISE EXCEPTION 'expected 180 House / 56 Senate offices, got % / %', n_low, n_upp;
  END IF;

  -- Exactly one flagged vacancy, and it is SD-12.
  SELECT count(*) INTO n_vac FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'ga' AND d.district_type IN ('STATE_LOWER','STATE_UPPER') AND o.is_vacant;
  IF n_vac <> 1 THEN RAISE EXCEPTION 'expected exactly 1 flagged vacancy, got %', n_vac; END IF;

  SELECT count(*) INTO n_vac FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE d.geo_id = '13012' AND d.district_type = 'STATE_UPPER' AND lower(d.state) = 'ga'
     AND o.is_vacant AND o.vacant_since IS NULL;
  IF n_vac <> 1 THEN RAISE EXCEPTION 'SD-12 is not flagged vacant with a NULL vacant_since'; END IF;

  RAISE NOTICE 'OK: 236 Georgia legislative offices (180 House, 56 Senate); SD-12 flagged vacant';
END $$;

COMMIT;
`;

// ── occupancy ────────────────────────────────────────────────────────────────
const peopleValues = newRows.map((r) => {
  const ext = externalId(r);
  return `  (${ext}, ${q(r.full_name)}, ${q(r.first_name)}, ${q(r.last_name)})`;
}).join(',\n');

const seatValues = seated.map((r) => {
  return `  (${externalId(r)}, ${q(r.geo_id)}, ${q(r.chamber)}, ${q(r.full_name)})`;
}).join(',\n');

const occupancy = `-- CC_wip_ga_legislature_incumbents.sql
-- Knight Foundation program, wave GA-2 (occupancy half).
--
-- Seats ${seated.length} Georgia legislators: ${seated.filter((r) => r.chamber === 'STATE_LOWER').length} Representatives + ${seated.filter((r) => r.chamber === 'STATE_UPPER').length} Senators.
-- ${newRows.length} new politician rows + ${REUSE.size} REUSED. Senate District 12 gets NO person and NO term:
-- the structure migration flagged it vacant, and the reason is in that file's header.
--
-- ─────────────────────────────────────────────────────────────────────────────
-- 🔴 NO term_start IS ASSERTED, BECAUSE GEORGIA PUBLISHES NONE.
-- A Georgia member page carries name, district, party, city, capitol and district addresses,
-- staff, birthday and spouse -- and no service-start of any kind. Checked against a member who
-- arrived after a 2025-10-12 vacancy: the whole About block is "Birthday / Spouse". FL-2 could
-- lift continuous occupancy from each member's own "Legislative Service" line; there is no
-- equivalent here. So every term goes in OPEN-ENDED with start_precision 'unknown', which is
-- what the NC waves did for the same reason.
-- ⚠ The 2024 general election date is the start of the current TERM, not of continuous
-- occupancy, and re-election does not end an occupancy. Do not reach for it.
-- ⚠ Ballotpedia publishes assumed-office dates for some members. It is a third party, and this
-- wave does not write dates it cannot source from the body itself.
--
-- 🔴 IDENTITY IS KEYED ON external_id, AND A NAME MATCH IS NOT IDENTITY. Four roster names
-- already existed in production and only TWO of them are the same person:
--
--   Houston Gaines  -131001  REUSED. GA House D120, and our row is the GA-10 US House
--                            candidate he won the nomination for in May 2026. Same person;
--                            he already carries compass answers, so a second row would split him.
--   Jasmine Clark   -131301  REUSED. GA House D108, and our row is the GA-13 candidate.
--   John Carson     -810030  NOT REUSED -- that row is a COLORADO STATE SENATOR.
--   Kim Jackson     -364328  NOT REUSED -- that row is a UTAH COUNTY TREASURER.
--
-- The last two are the Robert Nash failure waiting to happen: a name-based guard would have
-- seated a Colorado senator and a Utah treasurer in the Georgia General Assembly. Both get a
-- fresh row here.
--
-- 🔴 NO NAME PARSING. Georgia publishes structured name parts (first / last / middle / suffix /
-- nickname), so first_name and last_name are taken from the source rather than split out of a
-- display string. splitName() is not involved, and the four shapes that would have broken it --
-- Reynaldo "Rey" Martinez, Noel Williams Jr., Regina Lewis-Ward, Holly El-Mahdi -- never need
-- splitting.
--
-- Party is deliberately absent. Party lives on races.primary_party, never on a person.
--
-- Idempotent: politicians are NOT EXISTS-guarded on external_id, terms on (office_id, politician_id).
-- Ends with a post-verify gate.

BEGIN;

-- ─── The people ──────────────────────────────────────────────────────────────

CREATE TEMP TABLE ga_people(ext_id int, full_name text, first_name text, last_name text) ON COMMIT DROP;
INSERT INTO ga_people(ext_id, full_name, first_name, last_name) VALUES
${peopleValues};

CREATE TEMP TABLE ga_seats(ext_id int, geo_id text, district_type text, full_name text) ON COMMIT DROP;
INSERT INTO ga_seats(ext_id, geo_id, district_type, full_name) VALUES
${seatValues};

DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM ga_people;
  IF n <> ${newRows.length} THEN RAISE EXCEPTION 'payload: expected ${newRows.length} new people, got %', n; END IF;
  SELECT count(*) INTO n FROM ga_seats;
  IF n <> ${seated.length} THEN RAISE EXCEPTION 'payload: expected ${seated.length} seats, got %', n; END IF;
  SELECT count(*) INTO n FROM (SELECT ext_id FROM ga_people GROUP BY ext_id HAVING count(*) > 1) x;
  IF n <> 0 THEN RAISE EXCEPTION 'payload: % duplicate external_id(s)', n; END IF;

  -- 🔴 BAND GUARD, IN THE SHAPE FL-6 ARRIVED AT: every new id inside the new sub-range, and
  -- exactly the declared reuses outside it -- asserted POSITIVELY, by id and by name.
  SELECT count(*) INTO n FROM ga_people WHERE ext_id NOT BETWEEN ${lowBand} AND ${highBand};
  IF n <> 0 THEN RAISE EXCEPTION '% new id(s) fall outside the GA-2 band', n; END IF;

  SELECT count(*) INTO n FROM ga_seats WHERE ext_id NOT BETWEEN ${lowBand} AND ${highBand};
  IF n <> ${REUSE.size} THEN RAISE EXCEPTION 'expected exactly ${REUSE.size} reused id(s) outside the band, got %', n; END IF;

  -- Each reused id must ALREADY exist and still be the person we checked.
${[...REUSE.entries()].map(([name, id]) => `  SELECT count(*) INTO n FROM essentials.politicians WHERE external_id = ${id} AND full_name = ${q(name)};
  IF n <> 1 THEN RAISE EXCEPTION 'reuse ${id} does not resolve to a single ${name.replace(/'/g, "''")} -- re-verify identity before proceeding'; END IF;`).join('\n')}

  -- And the two look-alikes must NOT be reused.
  SELECT count(*) INTO n FROM ga_people WHERE ext_id IN (-810030, -364328);
  IF n <> 0 THEN RAISE EXCEPTION 'a Colorado senator or a Utah treasurer is being written as a Georgia legislator'; END IF;
END $$;

INSERT INTO essentials.politicians
       (external_id, full_name, first_name, last_name, is_active, is_incumbent,
        alternate_names, photo_custom_url_manual_override, bio_text_manual_override,
        full_name_manual_override)
SELECT s.ext_id, s.full_name, s.first_name, s.last_name, true, true, '{}', false, false, false
  FROM ga_people s
 WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians p WHERE p.external_id = s.ext_id);

-- ─── The terms ───────────────────────────────────────────────────────────────
-- Open-ended, start_precision 'unknown'. See the header: Georgia publishes no service-start.

INSERT INTO essentials.office_terms
       (office_id, politician_id, term_start, start_precision, how_started, source)
SELECT o.id, p.id, NULL, 'unknown', 'unknown', ${q(SOURCE)}
  FROM ga_seats s
  JOIN essentials.districts d
    ON d.geo_id = s.geo_id AND d.district_type = s.district_type AND lower(d.state) = 'ga'
  JOIN essentials.offices o ON o.district_id = d.id
  JOIN essentials.politicians p ON p.external_id = s.ext_id
 WHERE NOT EXISTS (SELECT 1 FROM essentials.office_terms t WHERE t.office_id = o.id);

-- ─── Post-verify ─────────────────────────────────────────────────────────────

DO $$
DECLARE n_seated int; n_off int; n_wrong int; n_sd12 int;
BEGIN
  -- office_current_holder LEFT JOINs from offices, so a vacancy is a NULL politician_id, never
  -- an absent row. Count the politician_id.
  SELECT count(*), count(och.politician_id) INTO n_off, n_seated
    FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
    LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
   WHERE lower(d.state) = 'ga' AND d.district_type IN ('STATE_LOWER','STATE_UPPER');
  IF n_off <> 236 THEN RAISE EXCEPTION 'expected 236 GA legislative offices, got %', n_off; END IF;
  IF n_seated <> ${seated.length} THEN RAISE EXCEPTION 'expected ${seated.length} seated, got %', n_seated; END IF;

  -- The right person in the right seat, for every one of them.
  SELECT count(*) INTO n_wrong
    FROM ga_seats s
    JOIN essentials.districts d
      ON d.geo_id = s.geo_id AND d.district_type = s.district_type AND lower(d.state) = 'ga'
    JOIN essentials.offices o ON o.district_id = d.id
    LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
    LEFT JOIN essentials.politicians p ON p.id = och.politician_id
   WHERE p.full_name IS DISTINCT FROM s.full_name;
  IF n_wrong <> 0 THEN RAISE EXCEPTION '% Georgia legislative seat(s) hold the wrong person', n_wrong; END IF;

  -- SD-12 must hold NOBODY and stay flagged.
  SELECT count(och.politician_id) INTO n_sd12
    FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
    LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
   WHERE d.geo_id = '13012' AND d.district_type = 'STATE_UPPER' AND lower(d.state) = 'ga';
  IF n_sd12 <> 0 THEN RAISE EXCEPTION 'SD-12 was seated; it is vacant'; END IF;

  RAISE NOTICE 'OK: ${seated.length} Georgia legislators seated across 236 offices; SD-12 vacant';
END $$;

COMMIT;
`;

fs.writeFileSync(path.join(MIGRATIONS, 'CC_wip_ga_legislature_structure.sql'), structure);
fs.writeFileSync(path.join(MIGRATIONS, 'CC_wip_ga_legislature_incumbents.sql'), occupancy);
console.log('wrote migrations/CC_wip_ga_legislature_structure.sql   (236 offices, 1 flagged vacant)');
console.log(`wrote migrations/CC_wip_ga_legislature_incumbents.sql  (${newRows.length} new people, ${REUSE.size} reused, ${seated.length} seats)`);
console.log(`  external_id band: ${lowBand} .. ${highBand}`);
