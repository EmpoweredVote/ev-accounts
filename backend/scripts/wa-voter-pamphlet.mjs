#!/usr/bin/env node
/**
 * Harvest "Elected Experience" from Washington's online voters' pamphlet.
 *
 * WHY THIS EXISTS
 * ---------------
 * Candidate->person linking needs a DOCUMENT, not a name match. California prints a sworn ballot
 * designation; most states print nothing. Washington was recorded as having no instrument at all,
 * because its certified candidate list is a scanned photocopier image with no text layer.
 *
 * That was a claim about where we looked. The same Secretary of State publishes every candidate's
 * own submitted statement as JSON, over a public endpoint with no key, and its first section is
 * "Elected Experience" -- the candidate saying, in a document mailed to every voter, which offices
 * they hold and when they held them. Measured 2026-10-20 over the 209 unlinked WA rows:
 * 205 matched by ballot name, 193 carried Elected Experience text. 92% coverage.
 *
 * It disconfirms as well as it confirms: a candidate who answers "None." under Elected Experience
 * is not the sitting out-of-state senator their name also matches (CC_0277 refused four that way).
 *
 * THE ENDPOINTS
 * -------------
 *   voterguide.ashx?e=<election>&la=en&c=
 *     -> { Name, ElectionID, Categories[{ CategoryCode, Name, Races[{ RaceID, Name,
 *          Candidates[{ BallotID, BallotName, PartyName, HasStatement }] }] }] }
 *   candidate.ashx?e=<election>&r=<RaceID>&b=<BallotID>&la=en&c=
 *     -> [{ statement: { BallotName, RaceName, RaceJurisdictionName, OrgWebsite, Statement, ... } }]
 *        `Statement` is HTML: <b>Elected Experience</b>, <b>Other Professional Experience</b>,
 *        <b>Education</b>, <b>Community Service</b>, <b>Statement</b>.
 *
 * ⚠ READ THE PRIMARY, NOT THE GENERAL. The primary carries EVERY filed candidate, including the
 * ones who did not advance; the general carries only the survivors. 2026 primary = e=898.
 *
 * ⚠ The statement is a SELF-DESCRIPTION. It is evidence of WHO SOMEONE IS. It is NOT a record of
 * who holds a seat -- occupancy comes from the body's own roster, with dates (see CC_0278).
 *
 * ⚠ Do NOT load this text into `race_candidates.occupational_designation`. That column holds
 * California's three-word sworn ballot designation; a pamphlet paragraph is a different artefact,
 * and mixing them makes "which rows carry a designation?" count two unlike things.
 *
 * USAGE
 *   node scripts/wa-voter-pamphlet.mjs --election 898 --out /tmp/wa.json
 *   node scripts/wa-voter-pamphlet.mjs --election 898 --name "Nikki Torres"
 *
 * With neither --name nor --all, it reads the unlinked WA candidates out of DATABASE_URL and
 * harvests those. Node's own fetch reaches this host fine; no browser is needed.
 */
import fs from 'node:fs';

const arg = (k, d) => {
  const i = process.argv.indexOf(`--${k}`);
  return i > -1 && process.argv[i + 1] ? process.argv[i + 1] : d;
};
const has = (k) => process.argv.includes(`--${k}`);

const ELECTION = arg('election', '898');
const BASE = 'https://voter.votewa.gov/elections';
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

/** Pull one labelled section out of the pamphlet's HTML statement. */
export function section(html, label) {
  if (!html) return '';
  const i = html.indexOf(`<b>${label}</b>`);
  if (i < 0) return '';
  const rest = html.slice(i + label.length + 7);
  const j = rest.search(/<b>/);
  return rest
    .slice(0, j < 0 ? rest.length : j)
    .replace(/<[^>]+>/g, ' ')
    .replace(/&nbsp;/g, ' ')
    .replace(/&amp;/g, '&')
    .replace(/\s+/g, ' ')
    .trim();
}

async function getJson(url) {
  const r = await fetch(url);
  if (!r.ok) throw new Error(`HTTP ${r.status} for ${url}`);
  const text = await r.text();
  // 🔴 A clean 200 lies in several ways; an HTML error page parses as "not JSON", not as empty.
  try {
    return JSON.parse(text);
  } catch {
    throw new Error(`not JSON (${text.length} bytes) from ${url}: ${text.slice(0, 120)}`);
  }
}

/** name -> [{ raceId, ballotId, hasStatement, category, raceName }] over the whole election. */
async function buildIndex() {
  const guide = await getJson(`${BASE}/voterguide.ashx?e=${ELECTION}&la=en&c=`);
  const byName = new Map();
  let races = 0;
  for (const cat of guide.Categories) {
    if (cat.CategoryCode === 'MEA') continue; // ballot measures have no candidates
    for (const race of cat.Races) {
      races++;
      for (const c of race.Candidates || []) {
        const k = c.BallotName.trim().toLowerCase();
        if (!byName.has(k)) byName.set(k, []);
        byName.get(k).push({
          raceId: c.RaceID, ballotId: c.BallotID, hasStatement: c.HasStatement,
          category: cat.CategoryCode, raceName: race.Name,
        });
      }
    }
  }
  // 🔴 Positive control: a detector that found nothing must say so loudly.
  if (byName.size < 100) throw new Error(`index looks blind: ${byName.size} names over ${races} races`);
  console.error(`index: ${byName.size} ballot names over ${races} races (election ${ELECTION})`);
  return byName;
}

async function fetchStatement(hit) {
  const j = await getJson(
    `${BASE}/candidate.ashx?e=${ELECTION}&r=${hit.raceId}&b=${hit.ballotId}&la=en&c=`);
  const st = j[0]?.statement || {};
  return {
    ...hit,
    ballotName: st.BallotName,
    jurisdiction: st.RaceJurisdictionName,
    raceNameFull: st.RaceName,
    party: st.PartyName,
    website: st.OrgWebsite,
    elected: section(st.Statement, 'Elected Experience'),
    other: section(st.Statement, 'Other Professional Experience'),
  };
}

async function targets() {
  const one = arg('name');
  if (one) return [{ full_name: one }];
  if (!process.env.DATABASE_URL) {
    console.error('no --name and no DATABASE_URL: nothing to look up.');
    process.exit(2);
  }
  const { default: pg } = await import('pg');
  const pool = new pg.Pool({ connectionString: process.env.DATABASE_URL, ssl: { rejectUnauthorized: false } });
  const { rows } = await pool.query(`
    SELECT rc.id AS rc_id, rc.full_name, rc.result, o.title, d.label AS district
      FROM essentials.race_candidates rc
      JOIN essentials.races r ON r.id = rc.race_id
      JOIN essentials.elections e ON e.id = r.election_id
      LEFT JOIN essentials.offices o ON o.id = r.office_id
      LEFT JOIN essentials.districts d ON d.id = o.district_id
     WHERE e.state = 'WA' AND e.election_date >= current_date
       ${has('all') ? '' : 'AND rc.politician_id IS NULL'}
     ORDER BY d.label, o.title, rc.full_name`);
  await pool.end();
  return rows;
}

const index = await buildIndex();
const rows = await targets();
const out = [];
let unmatched = 0, fetched = 0;

for (const r of rows) {
  const hits = index.get(r.full_name.trim().toLowerCase()) || [];
  if (hits.length === 0) { unmatched++; out.push({ ...r, guide: 'NO_NAME_MATCH' }); continue; }
  const rec = { ...r, candidates: [] };
  for (const h of hits) {
    if (!h.hasStatement) { rec.candidates.push({ ...h, elected: '', note: 'NO_STATEMENT' }); continue; }
    try { rec.candidates.push(await fetchStatement(h)); fetched++; }
    catch (e) { rec.candidates.push({ ...h, elected: '', note: `FETCH_ERR ${e.message}` }); }
    await sleep(120); // be a polite guest on a state election server
  }
  out.push(rec);
}

const dest = arg('out');
if (dest) { fs.writeFileSync(dest, JSON.stringify(out, null, 1)); console.error(`wrote ${dest}`); }
else {
  for (const r of out) {
    for (const c of r.candidates || []) {
      if (!c.elected) continue;
      console.log(`${r.full_name} | ${c.jurisdiction || '?'} / ${c.raceNameFull || c.raceName}`);
      console.log(`    ${c.elected}`);
    }
  }
}
console.error(`rows ${rows.length} · matched ${rows.length - unmatched} · unmatched ${unmatched} · statements ${fetched}`);
