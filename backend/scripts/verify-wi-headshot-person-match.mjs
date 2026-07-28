// Correct-person guard for the WI legislature headshot import.
//
// Usage (DATABASE_URL in env): node scripts/verify-wi-headshot-person-match.mjs
//
// Attaching a photo to the wrong politician is the one error that is both easy to make and hard to
// notice, so this checks FIRST names too — the earlier occupancy cross-check compared surnames only,
// which would happily pass a "Smith" for a different "Smith".
//
// Keys on (chamber, district) via office_current_holder — never on name. Exits non-zero on any
// disagreement. Read-only.
import { Pool } from 'pg';
import { readFileSync, writeFileSync } from 'node:fs';
import { join } from 'node:path';

const DIR = join('data', 'stance-research', 'wi-2026-state-leg');

function parseCsv(t) {
  const rows = []; let row = [], f = '', q = false;
  for (let i = 0; i < t.length; i++) { const c = t[i];
    if (q) { if (c === '"') { if (t[i+1] === '"') { f += '"'; i++; } else q = false; } else f += c; }
    else if (c === '"') q = true;
    else if (c === ',') { row.push(f); f = ''; }
    else if (c === '\n') { row.push(f); rows.push(row); row = []; f = ''; }
    else if (c !== '\r') f += c; }
  if (f || row.length) { row.push(f); rows.push(row); }
  const cols = rows.shift();
  return rows.filter(r => r.length === cols.length).map(r => Object.fromEntries(cols.map((c, i) => [c, r[i]])));
}

const norm = (s) => (s || '').toLowerCase().normalize('NFD').replace(/[̀-ͯ]/g, '').replace(/[^a-z]/g, '');
// Roster renders formal names; the DB may hold a preferred name. These are the same person.
const NICKNAMES = [
  ['robert', 'rob'], ['robert', 'bob'], ['william', 'bill'], ['richard', 'rick'], ['richard', 'dick'],
  ['james', 'jim'], ['michael', 'mike'], ['david', 'dave'], ['daniel', 'dan'], ['thomas', 'tom'],
  ['christopher', 'chris'], ['joseph', 'joe'], ['thereseanne', 'tip'], ['patrick', 'pat'],
  ['kenneth', 'ken'], ['edward', 'ed'], ['thereasa', 'terri'], ['deborah', 'deb'], ['debra', 'deb'],
  ['jeffrey', 'jeff'], ['gregory', 'greg'], ['nicholas', 'nick'], ['anthony', 'tony'],
  ['steven', 'steve'], ['stephen', 'steve'], ['timothy', 'tim'], ['ronald', 'ron'], ['donald', 'don'],
  ['charles', 'chuck'], ['margaret', 'peggy'], ['elizabeth', 'liz'], ['kathleen', 'kathy'],
  ['samantha', 'sam'], ['benjamin', 'ben'], ['alexander', 'alex'], ['andrew', 'andy'],
  ['francesca', 'fran'], ['jonathan', 'jon'], ['matthew', 'matt'], ['douglas', 'doug'],
  ['vincent', 'vinnie'], ['vincent', 'vince'],
];

// Seats where prod's first name disagrees with the official roster but the person is CONFIRMED the
// same, by fetching that legislator's own page on docs.legis.wisconsin.gov. Each entry records what
// was verified. This unblocks the photo only — it does NOT correct prod's name, which is a separate
// data fix and not something a headshot import should do silently.
const VERIFIED_SAME_PERSON = {
  'Assembly-55': {
    prod: 'Gus Gustafson',
    official: 'Nate L. Gustafson',
    evidence: 'docs.legis.wisconsin.gov/2025/legislators/assembly/2736 — "Nate L. Gustafson", District 55, Omro, R. District + surname + party all agree; prod first name "Gus" appears to be a prod-side error.',
  },
};
function firstNamesAgree(a, b) {
  if (!a || !b) return false;
  if (a === b) return true;
  if (a.startsWith(b) || b.startsWith(a)) return true;         // Dan / Daniel
  return NICKNAMES.some(([f, n]) => (a === f && b === n) || (a === n && b === f));
}

const scraped = parseCsv(readFileSync(join(DIR, 'wi_legis_members.csv'), 'utf8'));
const pool = new Pool({ connectionString: process.env.DATABASE_URL });

try {
  const { rows: prod } = await pool.query(`
    SELECT CASE d.district_type WHEN 'STATE_LOWER' THEN 'Assembly' ELSE 'Senate' END AS chamber,
           split_part(d.ocd_id, ':', 4)::int AS district,
           p.id AS politician_id, p.external_id, p.full_name, p.first_name, p.last_name,
           p.preferred_name, p.party,
           (SELECT count(*) FROM essentials.politician_images pi WHERE pi.politician_id = p.id) AS existing_images
      FROM essentials.offices o
      JOIN essentials.districts d ON d.id = o.district_id
      JOIN essentials.office_current_holder och ON och.office_id = o.id
      JOIN essentials.politicians p ON p.id = och.politician_id
     WHERE lower(d.state) = 'wi' AND d.district_type IN ('STATE_LOWER','STATE_UPPER')`);

  const key = (c, d) => `${c}-${Number(d)}`;
  const byKey = new Map(prod.map((r) => [key(r.chamber, r.district), r]));

  const ok = [], surnameFail = [], firstFail = [], unmatched = [], noExternalId = [], alreadyHasImage = [], overridden = [];
  for (const s of scraped) {
    const k = key(s.chamber, s.district);
    const p = byKey.get(k);
    if (!p) { unmatched.push(`${k} roster=${s.roster_name}`); continue; }
    const sLast = norm(s.last_name), sFirst = norm(s.first_name.split(/\s+/)[0]);
    const pLast = norm(p.last_name) || norm(p.full_name.split(/\s+/).slice(-1)[0]);
    const pFirstCands = [norm(p.first_name), norm(p.preferred_name), norm(p.full_name.split(/\s+/)[0])].filter(Boolean);

    if (!pLast.includes(sLast) && !sLast.includes(pLast)) {
      surnameFail.push({ k, roster: s.roster_name, prod: p.full_name });
      continue;
    }
    if (!pFirstCands.some((pf) => firstNamesAgree(pf, sFirst))) {
      const ov = VERIFIED_SAME_PERSON[k];
      if (ov && norm(ov.prod) === norm(p.full_name)) {
        overridden.push({ k, ...ov });
      } else {
        firstFail.push({ k, roster: `${s.first_name} ${s.last_name}`, prod: p.full_name, prodFirst: p.first_name, preferred: p.preferred_name });
        continue;
      }
    }
    if (p.external_id === null) noExternalId.push(`${k} ${p.full_name}`);
    if (Number(p.existing_images) > 0) alreadyHasImage.push(`${k} ${p.full_name} (${p.existing_images})`);
    ok.push({ ...s, politician_id: p.politician_id, external_id: p.external_id, prod_name: p.full_name });
  }

  console.log(`=== correct-person guard: WI roster vs prod office_current_holder (keyed chamber+district) ===`);
  console.log(`  first AND last name agree: ${ok.length}/${scraped.length}`);
  console.log(`  surname disagreement:      ${surnameFail.length}`);
  console.log(`  FIRST-name disagreement:   ${firstFail.length}`);
  console.log(`  unmatched seats:           ${unmatched.length}`);
  for (const f of surnameFail) console.log(`    SURNAME  ${f.k.padEnd(12)} roster="${f.roster}" prod="${f.prod}"`);
  for (const f of firstFail) console.log(`    FIRST    ${f.k.padEnd(12)} roster="${f.roster}" prod="${f.prod}" (first=${f.prodFirst}, preferred=${f.preferred || '-'})`);
  for (const u of unmatched) console.log(`    UNMATCHED ${u}`);

  if (overridden.length) {
    console.log(`\n  name mismatches OVERRIDDEN as verified-same-person: ${overridden.length}`);
    for (const o of overridden) console.log(`    ${o.k}  prod="${o.prod}" official="${o.official}"\n      ${o.evidence}`);
  }
  console.log(`\n  politicians with NULL external_id: ${noExternalId.length}${noExternalId.length ? ' — ' + noExternalId.join('; ') : ''}`);
  console.log(`  politicians that ALREADY have an image: ${alreadyHasImage.length}${alreadyHasImage.length ? ' — ' + alreadyHasImage.join('; ') : ''}`);
  console.log(`  => ${ok.length - alreadyHasImage.length} seats need a new image`);

  writeFileSync(join(DIR, 'wi_headshot_import_manifest.csv'),
    'chamber,district,legis_id,politician_id,external_id,prod_name,roster_name,party,headshot_url\n' +
    ok.map((r) => [r.chamber, r.district, r.legis_id, r.politician_id, r.external_id,
      `"${r.prod_name}"`, `"${r.roster_name}"`, r.party, r.headshot_url].join(',')).join('\n') + '\n');
  console.log(`  wrote wi_headshot_import_manifest.csv (${ok.length} rows)`);

  const blocking = surnameFail.length + firstFail.length + unmatched.length;
  if (blocking > 0) {
    console.log(`\nGUARD FAILED: ${blocking} seat(s) could not be confirmed. Do NOT import.`);
    process.exit(1);
  }
  console.log(`\nGUARD PASSED: all ${ok.length} seats confirmed by first+last name on a district key.`);
} finally {
  await pool.end();
}
