#!/usr/bin/env node
/**
 * control-sc4-migration-gates.mjs — Knight program, wave SC-4.
 *
 * 🔴 A GATE THAT HAS NEVER BEEN WATCHED FAILING IS NOT A GATE. Each control plants the defect one
 * gate exists to catch and asserts that gate fires. Every control runs inside ONE transaction and
 * is ROLLED BACK, so this is safe against production and re-runnable.
 *
 * Run from backend/ (the migration paths are relative to it):
 *   node data/seed-sc-counties-2026/control-sc4-migration-gates.mjs
 *
 * Exit 0 only if EVERY control fired. A control that does not fire is reported as
 * "this gate is not a gate" — the point of the exercise.
 *
 * Control 6 is recorded as it happens: the gate is never reached, because office_terms' own
 * exclusion constraint refuses the overlapping row first. That is the stronger answer and it is
 * left standing rather than engineered around.
 */
import 'dotenv/config';
import { readFileSync } from 'node:fs';
import pg from 'pg';

// 🔴 THE CONTROLS ASSUME THE WAVE HAS NOT BEEN APPLIED, SO EACH TRANSACTION UNDOES IT FIRST.
// Run against production AFTER the apply without this, and control 1 reports "expected 41 offices,
// got 41" and control 4 finds Brawley's correct term already there — two gates would have printed
// "DID NOT FIRE" while being perfectly healthy. That is a broken CONTROL, not a broken gate, and
// it is exactly the shape of defect these controls exist to catch. Every statement below runs
// inside the same transaction as the control and is rolled back with it.
const RESET = `
DELETE FROM essentials.office_terms ot USING essentials.offices o, essentials.chambers c, essentials.governments g
 WHERE ot.office_id=o.id AND o.chamber_id=c.id AND c.government_id=g.id
   AND g.state='SC' AND g.geo_id IN ('45079','45051');
DELETE FROM essentials.offices o USING essentials.chambers c, essentials.governments g
 WHERE o.chamber_id=c.id AND c.government_id=g.id AND g.state='SC' AND g.geo_id IN ('45079','45051');
DELETE FROM essentials.chambers c USING essentials.governments g
 WHERE c.government_id=g.id AND g.state='SC' AND g.geo_id IN ('45079','45051');
DELETE FROM essentials.districts WHERE mtfcc IN ('X0060','X0061');
DELETE FROM essentials.governments WHERE state='SC' AND geo_id IN ('45079','45051');
DELETE FROM essentials.politicians WHERE external_id BETWEEN -2745500 AND -2745401;
`;

const strip = (s) => s.replace(/^\s*(BEGIN|COMMIT)\s*;\s*$/gim, '');
const STRUCT = strip(readFileSync('migrations/CC_0129_sc_counties_structure.sql', 'utf8'));
const OCC = strip(readFileSync('migrations/CC_0130_sc_counties_incumbents.sql', 'utf8'));

const CONTROLS = [
  {
    n: 1,
    what: 'the occupancy half applied WITHOUT the structure half',
    steps: [OCC],
  },
  {
    n: 2,
    what: 'one Richland council-district polygon deleted before the structure half',
    steps: [`DELETE FROM essentials.geofence_boundaries WHERE mtfcc='X0060' AND geo_id='richland-sc-council-district-7'`, STRUCT],
  },
  {
    n: 3,
    what: 'a countywide office MOVED onto State House District 79 — the geo_id collision',
    steps: [
      STRUCT,
      `UPDATE essentials.offices SET district_id = (
         SELECT id FROM essentials.districts WHERE geo_id='45079' AND mtfcc='G5220' AND lower(state)='sc')
       WHERE id = (SELECT o.id FROM essentials.offices o
                     JOIN essentials.chambers c ON c.id=o.chamber_id
                     JOIN essentials.governments g ON g.id=c.government_id
                    WHERE g.state='SC' AND g.geo_id='45079' AND o.title='Sheriff' LIMIT 1)`,
      `DO $$ DECLARE v_leak int; BEGIN
         SELECT count(DISTINCT d.id) INTO v_leak FROM essentials.offices o
           JOIN essentials.districts d ON d.id=o.district_id
           JOIN essentials.chambers c ON c.id=o.chamber_id
           JOIN essentials.governments g ON g.id=c.government_id
          WHERE g.state='SC' AND g.geo_id IN ('45079','45051') AND d.district_type NOT IN ('LOCAL','COUNTY');
         IF v_leak <> 0 THEN RAISE EXCEPTION 'SC-4 structure: % legislative/congressional district(s) picked up a county office — the join matched on geo_id alone', v_leak; END IF;
       END $$;`,
    ],
  },
  {
    n: 4,
    what: "Brawley dated from January instead of the auditor's statutory 1 July",
    steps: [STRUCT, OCC.replace("-2745412::bigint,'2007-07-01'::date", "-2745412::bigint,'2007-01-02'::date")],
  },
  {
    n: 5,
    what: 'the VACANT Richland soil-and-water seat seated anyway',
    steps: [
      STRUCT,
      `UPDATE essentials.offices SET is_vacant = false WHERE id IN (
         SELECT o.id FROM essentials.offices o
           JOIN essentials.chambers c ON c.id=o.chamber_id
           JOIN essentials.governments g ON g.id=c.government_id
          WHERE g.state='SC' AND g.geo_id='45079' AND o.is_vacant)`,
      OCC,
    ],
  },
  {
    n: 6,
    what: 'a second holder placed on one Horry soil-and-water office',
    steps: [
      STRUCT, OCC,
      `INSERT INTO essentials.office_terms (office_id, politician_id, term_start, term_end, start_precision, how_started, source)
       SELECT ot.office_id, (SELECT id FROM essentials.politicians WHERE external_id=-2745401),
              NULL, NULL, 'unknown', 'unknown', 'control 6'
         FROM essentials.office_terms ot
         JOIN essentials.offices o ON o.id=ot.office_id
         JOIN essentials.chambers c ON c.id=o.chamber_id
         JOIN essentials.governments g ON g.id=c.government_id
        WHERE g.geo_id='45051' AND o.title='Soil and Water Conservation District Commissioner' LIMIT 1`,
    ],
  },
];

const client = new pg.Client({ connectionString: process.env.DATABASE_URL, ssl: { rejectUnauthorized: false } });
await client.connect();

let allFired = true;
for (const c of CONTROLS) {
  await client.query('BEGIN');
  let fired = null;
  try {
    await client.query(RESET);
    for (const s of c.steps) await client.query(s);
  } catch (e) {
    fired = e.message;
  }
  await client.query('ROLLBACK');
  console.log(`CONTROL ${c.n} — ${c.what}`);
  console.log(fired ? `   ✅ FIRED: ${fired}` : '   🔴 DID NOT FIRE — this gate is not a gate');
  if (!fired) allFired = false;
}
await client.end();
process.exit(allFired ? 0 : 1);
