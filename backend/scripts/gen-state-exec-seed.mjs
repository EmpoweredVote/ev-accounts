#!/usr/bin/env node
// gen-state-exec-seed.mjs — Phase 141 (v2.18 State Leaders) seed-migration generator.
// Emits one idempotent, set-based STATE_EXEC seed migration per batch (A-E -> migrations 951-955).
// Roster is the live-verified (June 2026) officeholder set from plans 141-03..07 research agents
// (Wikipedia "List of current ..." + state .gov cross-check, source URL captured per office).
// external_id = -(fips*100000 + seq) EXCEPT the two collision states (preflight-verified 2026):
//   AK (fips 02) -> -200008/-200009  (-2000xx low slots taken by MA execs + a city councillor)
//   AZ (fips 04) -> -400091..-400094 (-4000xx taken by US Senators)
// Every emitted migration self-checks: ext_id < -56000, no ext_id collision, government row exists,
// uppercase state, non-empty FIPS geo_id, role_canonical NOT NULL, correct in-scope count. Idempotent.
import { writeFileSync } from 'node:fs';

const STATE_NAME = {
  AK:'Alaska', AL:'Alabama', AZ:'Arizona', AR:'Arkansas', CO:'Colorado', CT:'Connecticut',
  DE:'Delaware', FL:'Florida', GA:'Georgia', HI:'Hawaii', IA:'Iowa', ID:'Idaho', IL:'Illinois',
  KS:'Kansas', KY:'Kentucky', LA:'Louisiana', MI:'Michigan', MN:'Minnesota', MO:'Missouri',
  MS:'Mississippi', MT:'Montana', NC:'North Carolina', ND:'North Dakota', NE:'Nebraska',
  NH:'New Hampshire', NJ:'New Jersey', NM:'New Mexico', NV:'Nevada', NY:'New York', OH:'Ohio',
  OK:'Oklahoma', PA:'Pennsylvania', RI:'Rhode Island', SC:'South Carolina', SD:'South Dakota',
  TN:'Tennessee', VT:'Vermont', WA:'Washington', WI:'Wisconsin', WV:'West Virginia', WY:'Wyoming',
};
const FIPS = {
  AK:2, AL:1, AZ:4, AR:5, CO:8, CT:9, DE:10, FL:12, GA:13, HI:15, IA:19, ID:16, IL:17, KS:20,
  KY:21, LA:22, MI:26, MN:27, MO:29, MS:28, MT:30, NC:37, ND:38, NE:31, NH:33, NJ:34, NM:35,
  NV:32, NY:36, OH:39, OK:40, PA:42, RI:44, SC:45, SD:46, TN:47, VT:50, WA:53, WI:55, WV:54, WY:56,
};
const pad2 = (n) => String(n).padStart(2, '0');
const splitName = (full) => { const t = full.trim().split(/\s+/); return [t[0], t.slice(1).join(' ')]; };
const D = 'Democrat', R = 'Republican';
// row: [state, title, role_canonical, full_name, party, ext_id_override?]
const BATCHES = {
  // ---- Batch A -> migration 980 (renumbered from 951: concurrent city-stance work collided on 949-955) ----
  A: { mig: 980, rows: [
    ['AK','Governor','governor','Mike Dunleavy',R,-200008],
    ['AK','Lieutenant Governor','lt_governor','Nancy Dahlstrom',R,-200009],
    ['AL','Governor','governor','Kay Ivey',R],
    ['AL','Lieutenant Governor','lt_governor','Will Ainsworth',R],
    ['AL','Attorney General','attorney_general','Steve Marshall',R],
    ['AL','Secretary of State','secretary_of_state','Wes Allen',R],
    ['AL','Treasurer','treasurer','Young Boozer',R],
    ['FL','Governor','governor','Ron DeSantis',R],
    ['FL','Lieutenant Governor','lt_governor','Jay Collins',R],
    ['FL','Attorney General','attorney_general','James Uthmeier',R],
    ['FL','Chief Financial Officer','treasurer','Blaise Ingoglia',R],
    ['IL','Governor','governor','JB Pritzker',D],
    ['IL','Lieutenant Governor','lt_governor','Juliana Stratton',D],
    ['IL','Attorney General','attorney_general','Kwame Raoul',D],
    ['IL','Secretary of State','secretary_of_state','Alexi Giannoulias',D],
    ['IL','Treasurer','treasurer','Mike Frerichs',D],
    ['MS','Governor','governor','Tate Reeves',R],
    ['MS','Lieutenant Governor','lt_governor','Delbert Hosemann',R],
    ['MS','Attorney General','attorney_general','Lynn Fitch',R],
    ['MS','Secretary of State','secretary_of_state','Michael Watson',R],
    ['MS','Treasurer','treasurer','David McRae',R],
    ['NC','Governor','governor','Josh Stein',D],
    ['NC','Lieutenant Governor','lt_governor','Rachel Hunt',D],
    ['NC','Attorney General','attorney_general','Jeff Jackson',D],
    ['NC','Secretary of State','secretary_of_state','Elaine Marshall',D],
    ['NC','Treasurer','treasurer','Brad Briner',R],
    ['NY','Governor','governor','Kathy Hochul',D],
    ['NY','Lieutenant Governor','lt_governor','Antonio Delgado',D],
    ['NY','Attorney General','attorney_general','Letitia James',D],
    ['NY','Comptroller','treasurer','Thomas DiNapoli',D],
    ['SD','Governor','governor','Larry Rhoden',R],
    ['SD','Lieutenant Governor','lt_governor','Tony Venhuizen',R],
    ['SD','Attorney General','attorney_general','Marty Jackley',R],
    ['SD','Secretary of State','secretary_of_state','Monae Johnson',R],
    ['SD','Treasurer','treasurer','Josh Haeder',R],
  ]},
  // ---- Batch B -> migration 952 ----
  B: { mig: 981, rows: [
    ['AR','Governor','governor','Sarah Huckabee Sanders',R],
    ['AR','Lieutenant Governor','lt_governor','Leslie Rutledge',R],
    ['AR','Attorney General','attorney_general','Tim Griffin',R],
    ['AR','Secretary of State','secretary_of_state','Cole Jester',R],
    ['AR','Treasurer','treasurer','John Thurston',R],
    ['GA','Governor','governor','Brian Kemp',R],
    ['GA','Lieutenant Governor','lt_governor','Burt Jones',R],
    ['GA','Attorney General','attorney_general','Chris Carr',R],
    ['GA','Secretary of State','secretary_of_state','Brad Raffensperger',R],
    ['HI','Governor','governor','Josh Green',D],
    ['HI','Lieutenant Governor','lt_governor','Sylvia Luke',D],
    ['IA','Governor','governor','Kim Reynolds',R],
    ['IA','Lieutenant Governor','lt_governor','Chris Cournoyer',R],
    ['IA','Attorney General','attorney_general','Brenna Bird',R],
    ['IA','Secretary of State','secretary_of_state','Paul Pate',R],
    ['IA','Treasurer','treasurer','Roby Smith',R],
    ['MO','Governor','governor','Mike Kehoe',R],
    ['MO','Lieutenant Governor','lt_governor','David Wasinger',R],
    ['MO','Attorney General','attorney_general','Catherine Hanaway',R],
    ['MO','Secretary of State','secretary_of_state','Denny Hoskins',R],
    ['MO','Treasurer','treasurer','Vivek Malek',R],
    ['ND','Governor','governor','Kelly Armstrong',R],
    ['ND','Lieutenant Governor','lt_governor','Michelle Strinden',R],
    ['ND','Attorney General','attorney_general','Drew Wrigley',R],
    ['ND','Secretary of State','secretary_of_state','Michael Howe',R],
    ['ND','Treasurer','treasurer','Thomas Beadle',R],
    ['OK','Governor','governor','Kevin Stitt',R],
    ['OK','Lieutenant Governor','lt_governor','Matt Pinnell',R],
    ['OK','Attorney General','attorney_general','Gentner Drummond',R],
    ['OK','Treasurer','treasurer','Todd Russ',R],
    ['VT','Governor','governor','Phil Scott',R],
    ['VT','Lieutenant Governor','lt_governor','John S. Rodgers',R],
    ['VT','Attorney General','attorney_general','Charity Clark',D],
    ['VT','Secretary of State','secretary_of_state','Sarah Copeland-Hanzas',D],
    ['VT','Treasurer','treasurer','Mike Pieciak',D],
  ]},
  // ---- Batch C -> migration 953 ----
  C: { mig: 982, rows: [
    ['CO','Governor','governor','Jared Polis',D],
    ['CO','Lieutenant Governor','lt_governor','Dianne Primavera',D],
    ['CO','Attorney General','attorney_general','Phil Weiser',D],
    ['CO','Secretary of State','secretary_of_state','Jena Griswold',D],
    ['CO','Treasurer','treasurer','Dave Young',D],
    ['KS','Governor','governor','Laura Kelly',D],
    ['KS','Lieutenant Governor','lt_governor','David Toland',D],
    ['KS','Attorney General','attorney_general','Kris Kobach',R],
    ['KS','Secretary of State','secretary_of_state','Scott Schwab',R],
    ['KS','Treasurer','treasurer','Steven Johnson',R],
    ['MI','Governor','governor','Gretchen Whitmer',D],
    ['MI','Lieutenant Governor','lt_governor','Garlin Gilchrist',D],
    ['MI','Attorney General','attorney_general','Dana Nessel',D],
    ['MI','Secretary of State','secretary_of_state','Jocelyn Benson',D],
    ['NE','Governor','governor','Jim Pillen',R],
    ['NE','Lieutenant Governor','lt_governor','Joe Kelly',R],
    ['NE','Attorney General','attorney_general','Mike Hilgers',R],
    ['NE','Secretary of State','secretary_of_state','Bob Evnen',R],
    ['NE','Treasurer','treasurer','Joey Spellerberg',R],
    ['NJ','Governor','governor','Mikie Sherrill',D],
    ['NJ','Lieutenant Governor','lt_governor','Dale Caldwell',D],
    ['OH','Governor','governor','Mike DeWine',R],
    ['OH','Lieutenant Governor','lt_governor','Jim Tressel',R],
    ['OH','Attorney General','attorney_general','Andy Wilson',R],
    ['OH','Secretary of State','secretary_of_state','Frank LaRose',R],
    ['OH','Treasurer','treasurer','Robert Sprague',R],
    ['PA','Governor','governor','Josh Shapiro',D],
    ['PA','Lieutenant Governor','lt_governor','Austin Davis',D],
    ['PA','Attorney General','attorney_general','Dave Sunday',R],
    ['PA','Treasurer','treasurer','Stacy Garrity',R],
    ['WA','Governor','governor','Bob Ferguson',D],
    ['WA','Lieutenant Governor','lt_governor','Denny Heck',D],
    ['WA','Attorney General','attorney_general','Nick Brown',D],
    ['WA','Secretary of State','secretary_of_state','Steve Hobbs',D],
    ['WA','Treasurer','treasurer','Mike Pellicciotti',D],
  ]},
  // ---- Batch D -> migration 954 ----
  D: { mig: 983, rows: [
    ['CT','Governor','governor','Ned Lamont',D],
    ['CT','Lieutenant Governor','lt_governor','Susan Bysiewicz',D],
    ['CT','Attorney General','attorney_general','William Tong',D],
    ['CT','Secretary of the State','secretary_of_state','Stephanie Thomas',D],
    ['CT','Treasurer','treasurer','Erick Russell',D],
    ['KY','Governor','governor','Andy Beshear',D],
    ['KY','Lieutenant Governor','lt_governor','Jacqueline Coleman',D],
    ['KY','Attorney General','attorney_general','Russell Coleman',R],
    ['KY','Secretary of State','secretary_of_state','Michael Adams',R],
    ['KY','Treasurer','treasurer','Mark Metcalf',R],
    ['MN','Governor','governor','Tim Walz',D],
    ['MN','Lieutenant Governor','lt_governor','Peggy Flanagan',D],
    ['MN','Attorney General','attorney_general','Keith Ellison',D],
    ['MN','Secretary of State','secretary_of_state','Steve Simon',D],
    ['NH','Governor','governor','Kelly Ayotte',R],
    ['NV','Governor','governor','Joe Lombardo',R],
    ['NV','Lieutenant Governor','lt_governor','Stavros Anthony',R],
    ['NV','Attorney General','attorney_general','Aaron Ford',D],
    ['NV','Secretary of State','secretary_of_state','Cisco Aguilar',D],
    ['NV','Treasurer','treasurer','Zach Conine',D],
    ['RI','Governor','governor','Dan McKee',D],
    ['RI','Lieutenant Governor','lt_governor','Sabina Matos',D],
    ['RI','Attorney General','attorney_general','Peter Neronha',D],
    ['RI','Secretary of State','secretary_of_state','Gregg Amore',D],
    ['RI','Treasurer','treasurer','James Diossa',D],
    ['TN','Governor','governor','Bill Lee',R],
    ['WI','Governor','governor','Tony Evers',D],
    ['WI','Lieutenant Governor','lt_governor','Sara Rodriguez',D],
    ['WI','Attorney General','attorney_general','Josh Kaul',D],
    ['WI','Secretary of State','secretary_of_state','Sarah Godlewski',D],
    ['WI','Treasurer','treasurer','John Leiber',R],
    ['WV','Governor','governor','Patrick Morrisey',R],
    ['WV','Attorney General','attorney_general','JB McCuskey',R],
    ['WV','Secretary of State','secretary_of_state','Kris Warner',R],
    ['WV','Treasurer','treasurer','Larry Pack',R],
  ]},
  // ---- Batch E -> migration 955 ----
  E: { mig: 984, rows: [
    ['AZ','Governor','governor','Katie Hobbs',D,-400091],
    ['AZ','Attorney General','attorney_general','Kris Mayes',D,-400092],
    ['AZ','Secretary of State','secretary_of_state','Adrian Fontes',D,-400093],
    ['AZ','Treasurer','treasurer','Kimberly Yee',R,-400094],
    ['DE','Governor','governor','Matt Meyer',D],
    ['DE','Lieutenant Governor','lt_governor','Kyle Evans Gay',D],
    ['DE','Attorney General','attorney_general','Kathy Jennings',D],
    ['DE','Treasurer','treasurer','Colleen Davis',D],
    ['ID','Governor','governor','Brad Little',R],
    ['ID','Lieutenant Governor','lt_governor','Scott Bedke',R],
    ['ID','Attorney General','attorney_general','Raul Labrador',R],
    ['ID','Secretary of State','secretary_of_state','Phil McGrane',R],
    ['ID','Treasurer','treasurer','Julie Ellsworth',R],
    ['LA','Governor','governor','Jeff Landry',R],
    ['LA','Lieutenant Governor','lt_governor','Billy Nungesser',R],
    ['LA','Attorney General','attorney_general','Liz Murrill',R],
    ['LA','Secretary of State','secretary_of_state','Nancy Landry',R],
    ['LA','Treasurer','treasurer','John Fleming',R],
    ['MT','Governor','governor','Greg Gianforte',R],
    ['MT','Lieutenant Governor','lt_governor','Kristen Juras',R],
    ['MT','Attorney General','attorney_general','Austin Knudsen',R],
    ['MT','Secretary of State','secretary_of_state','Christi Jacobsen',R],
    ['NM','Governor','governor','Michelle Lujan Grisham',D],
    ['NM','Lieutenant Governor','lt_governor','Howie Morales',D],
    ['NM','Attorney General','attorney_general','Raul Torrez',D],
    ['NM','Secretary of State','secretary_of_state','Maggie Toulouse Oliver',D],
    ['NM','Treasurer','treasurer','Laura Montoya',D],
    ['SC','Governor','governor','Henry McMaster',R],
    ['SC','Lieutenant Governor','lt_governor','Pamela Evette',R],
    ['SC','Attorney General','attorney_general','Alan Wilson',R],
    ['SC','Secretary of State','secretary_of_state','Mark Hammond',R],
    ['SC','Treasurer','treasurer','Curtis Loftis',R],
    ['WY','Governor','governor','Mark Gordon',R],
    ['WY','Secretary of State','secretary_of_state','Chuck Gray',R],
    ['WY','Treasurer','treasurer','Curt Meier',R],
  ]},
};

const sq = (s) => s.replace(/'/g, "''"); // SQL single-quote escape

function buildRows(rows) {
  // assign per-state seq for ext_id where not overridden
  const seqByState = {};
  return rows.map(([st, title, role, full, party, override]) => {
    const fips = FIPS[st];
    seqByState[st] = (seqByState[st] || 0) + 1;
    const ext = override ?? -(fips * 100000 + seqByState[st]);
    const [first, last] = splitName(full);
    return { st, fips, geo: pad2(fips), sname: STATE_NAME[st], title, role, full, first, last, party, ext };
  });
}

function emit(batchKey) {
  const { mig, rows } = BATCHES[batchKey];
  const R2 = buildRows(rows);
  const states = [...new Set(R2.map(r => r.st))];
  const total = R2.length;
  const fname = `951`; // placeholder; set below
  const values = R2.map(r =>
    `  ('${r.st}', ${r.fips}, '${r.geo}', '${sq(r.sname)}', '${sq(r.title)}', '${r.role}', '${sq(r.full)}', '${sq(r.first)}', '${sq(r.last)}', '${r.party}', ${r.ext})`
  ).join(',\n');

  const sql = `-- ${mig}_state_exec_seed_batch_${batchKey.toLowerCase()}.sql
-- Phase 141 (v2.18 State Leaders), plan 141-0${batchKey === 'A' ? 3 : batchKey === 'B' ? 4 : batchKey === 'C' ? 5 : batchKey === 'D' ? 6 : 7}.
-- GENERATED by backend/scripts/gen-state-exec-seed.mjs from live-verified (June 2026) roster.
-- Seeds ${total} in-scope elected Big-5 offices across: ${states.join(', ')}.
-- Idempotent (NOT EXISTS / ON CONFLICT guards). external_id = -(fips*100000+seq) except AK/AZ collision offsets.
-- Run: psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f backend/migrations/${mig}_state_exec_seed_batch_${batchKey.toLowerCase()}.sql

BEGIN;

CREATE TEMP TABLE _seed (
  state text, fips int, geo_id text, state_name text, title text, role_canonical text,
  full_name text, first_name text, last_name text, party text, ext_id bigint
) ON COMMIT DROP;

INSERT INTO _seed (state, fips, geo_id, state_name, title, role_canonical, full_name, first_name, last_name, party, ext_id) VALUES
${values};

-- PREFLIGHT 1 (D-04): every proposed external_id is below the federal US-House band (< -56000).
DO $$ DECLARE v INT; BEGIN
  SELECT count(*) INTO v FROM _seed WHERE ext_id > -56000;
  IF v > 0 THEN RAISE EXCEPTION 'PREFLIGHT 1 FAILED: % external_id(s) within/above the federal band', v; END IF;
END $$;

-- PREFLIGHT 2 (D-04): no proposed external_id is held by a DIFFERENT politician (true collision).
-- Idempotent: on re-run our own seeded politicians match full_name and are exempt; a real collision
-- (ext_id on someone else) still RAISES.
DO $$ DECLARE v TEXT; BEGIN
  SELECT string_agg(s.ext_id::text, ', ') INTO v
  FROM _seed s JOIN essentials.politicians p ON p.external_id = s.ext_id
  WHERE p.full_name <> s.full_name;
  IF v IS NOT NULL THEN RAISE EXCEPTION 'PREFLIGHT 2 FAILED: external_id collision with a different politician: %', v; END IF;
END $$;

-- PREFLIGHT 3 (Pitfall 4 safe): every state has its 'State of <Name>' government row.
DO $$ DECLARE v TEXT; BEGIN
  SELECT string_agg(DISTINCT s.state, ', ') INTO v FROM _seed s
  WHERE NOT EXISTS (SELECT 1 FROM essentials.governments g WHERE g.state = s.state AND g.name = 'State of ' || s.state_name);
  IF v IS NOT NULL THEN RAISE EXCEPTION 'PREFLIGHT 3 FAILED: missing government row for: %', v; END IF;
END $$;

-- 1) One labeled STATE_EXEC district per office ('<State> <Title>', uppercase state, FIPS geo_id).
INSERT INTO essentials.districts (id, district_type, state, geo_id, label, district_id, mtfcc)
SELECT gen_random_uuid(), 'STATE_EXEC', s.state, s.geo_id, s.state_name || ' ' || s.title, '', ''
FROM _seed s
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts d
  WHERE d.district_type='STATE_EXEC' AND d.state=s.state AND d.label = s.state_name || ' ' || s.title
);

-- 2) One chamber per office under the state's government (name=title; slug is GENERATED ALWAYS - excluded).
INSERT INTO essentials.chambers (id, name, name_formal, government_id)
SELECT gen_random_uuid(), s.title, s.title || ' of ' || s.state_name, g.id
FROM _seed s
JOIN essentials.governments g ON g.state=s.state AND g.name='State of ' || s.state_name
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers c WHERE c.government_id=g.id AND c.name=s.title
);

-- 3) Politicians (idempotent on external_id).
INSERT INTO essentials.politicians
  (id, full_name, first_name, last_name, party, is_active, is_appointed, is_vacant, is_incumbent, external_id)
SELECT gen_random_uuid(), s.full_name, s.first_name, s.last_name, s.party, true, false, false, true, s.ext_id
FROM _seed s
ON CONFLICT (external_id) DO NOTHING;

-- 4) Offices linking politician+district+chamber, role_canonical set (guard on district+chamber).
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state, is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(), d.id, c.id, p.id, s.title, s.state, false, false, s.role_canonical
FROM _seed s
JOIN essentials.districts d ON d.district_type='STATE_EXEC' AND d.state=s.state AND d.label = s.state_name || ' ' || s.title
JOIN essentials.governments g ON g.state=s.state AND g.name='State of ' || s.state_name
JOIN essentials.chambers c ON c.government_id=g.id AND c.name=s.title
JOIN essentials.politicians p ON p.external_id=s.ext_id
WHERE NOT EXISTS (SELECT 1 FROM essentials.offices o WHERE o.district_id=d.id AND o.chamber_id=c.id);

-- 5) office_id backfill (idempotent).
UPDATE essentials.politicians p SET office_id = o.id
FROM essentials.offices o, _seed s
WHERE o.politician_id=p.id AND p.external_id=s.ext_id AND p.office_id IS NULL;

-- ============================ POST ASSERTIONS ============================
DO $$ DECLARE v_cnt INT; v_bad INT; v_null INT; BEGIN
  SELECT count(*) INTO v_cnt
  FROM essentials.offices o JOIN essentials.districts d ON d.id=o.district_id
  WHERE d.district_type='STATE_EXEC' AND d.state IN (${states.map(s=>`'${s}'`).join(', ')})
    AND o.role_canonical IN ('governor','lt_governor','attorney_general','secretary_of_state','treasurer');
  IF v_cnt <> ${total} THEN RAISE EXCEPTION 'POST FAILED: in-scope office count=% (expected ${total})', v_cnt; END IF;

  SELECT count(*) INTO v_bad FROM essentials.districts d
  WHERE d.district_type='STATE_EXEC' AND d.state IN (${states.map(s=>`'${s}'`).join(', ')})
    AND (d.state <> upper(d.state) OR d.geo_id IS NULL OR d.geo_id='');
  IF v_bad <> 0 THEN RAISE EXCEPTION 'POST FAILED: % districts with lowercase state or empty geo_id', v_bad; END IF;

  SELECT count(*) INTO v_null FROM essentials.offices o
  JOIN essentials.politicians p ON p.id=o.politician_id, _seed s
  WHERE p.external_id=s.ext_id AND o.role_canonical IS NULL;
  IF v_null <> 0 THEN RAISE EXCEPTION 'POST FAILED: % seeded offices with NULL role_canonical', v_null; END IF;

  RAISE NOTICE 'Migration ${mig} OK: % in-scope Big-5 offices seeded across ${states.length} states (${states.join('/')})', v_cnt;
END $$;

COMMIT;
`;
  const path = `backend/migrations/${mig}_state_exec_seed_batch_${batchKey.toLowerCase()}.sql`;
  writeFileSync(path, sql);
  console.log(`wrote ${path} (${total} offices, ${states.length} states: ${states.join(',')})`);
}

for (const k of ['A','B','C','D','E']) emit(k);
console.log('done');
