/**
 * term-dates-openstates.ts — PROPOSES office_terms.term_start for a state's seated legislators from
 * the OpenStates `people` dataset (term-date roster pass, IN + CA pilot, 2026-09-25). Read-only: it
 * writes a proposal file for a person to review; the write is a separate, reviewed migration.
 *
 *   npx tsx scripts/term-dates-openstates.ts --openstates <path to openstates/people checkout> \
 *     --state IN|CA --out <proposal.json>
 *
 * Per seat: match the OpenStates member holding the same chamber + district now; require the surname
 * to agree with our seat holder (else flag `holder-mismatch` — our seat data may be stale); take the
 * start of the unbroken tenure in that seat; classify it against the state's legal term-start day
 * (scripts/lib/termStartRules.ts). Every flagged row needs a person before it is written.
 */
import 'dotenv/config';
import { readFileSync, readdirSync, writeFileSync } from 'node:fs';
import { join } from 'node:path';
import { load as yamlLoad } from 'js-yaml';
import { pool } from '../src/lib/db.js';
import { tenureStartInSeat, classifyStart, districtNumber, surnameMatches, officialSurname, type Chamber, type OsRole } from './lib/termStartRules.js';

const arg = (n: string) => { const i = process.argv.indexOf(n); return i > 0 ? process.argv[i + 1] : undefined; };
const osDir = arg('--openstates'); const state = arg('--state'); const out = arg('--out'); const officialDir = arg('--official');
if (!osDir || !state || !out || !['IN', 'CA'].includes(state)) { console.error('usage: --openstates <dir> --state IN|CA --out <file> [--official <dir of <STATE>-upper|lower.json>]'); process.exit(2); }

const CHAMBERS: Record<string, Record<string, Chamber>> = {
  IN: { 'Indiana State Senate': 'upper', 'Indiana House of Representatives': 'lower' },
  CA: { 'California State Senate': 'upper', 'California State Assembly': 'lower' },
};

// Official chamber rosters (district → member name), read from each chamber's own site. A seat whose
// district the official roster lists under a different surname, or not at all, is flagged: the date may
// be right, but our seat holder may not be.
const official = new Map<string, string[]>(); // `${chamber}|${district}` → names
if (officialDir) {
  for (const ch of ['upper', 'lower'] as const) {
    const f = join(officialDir, `${state}-${ch}.json`);
    const roster = JSON.parse(readFileSync(f, 'utf8')) as { members: [string, string][] };
    for (const [d, n] of roster.members) official.set(`${ch}|${d}`, [...(official.get(`${ch}|${d}`) ?? []), n]);
  }
}

interface OsPerson { id: string; name: string; family_name?: string; roles: OsRole[]; links?: { url: string }[] }
const people: OsPerson[] = readdirSync(join(osDir, 'data', state.toLowerCase(), 'legislature'))
  .filter((f) => f.endsWith('.yml'))
  .map((f) => yamlLoad(readFileSync(join(osDir, 'data', state.toLowerCase(), 'legislature', f), 'utf8')) as OsPerson);

const { rows: seats } = await pool.query(
  `SELECT ot.id AS term_id, och.office_id, och.politician_id, p.full_name, ch.name AS chamber, d.label AS district_label,
          ot.term_start::text, ot.start_precision
     FROM essentials.office_current_holder och
     JOIN essentials.offices o      ON o.id = och.office_id
     JOIN essentials.chambers ch    ON ch.id = o.chamber_id
     JOIN essentials.politicians p  ON p.id = och.politician_id
     LEFT JOIN essentials.districts d ON d.id = o.district_id
     JOIN essentials.office_terms ot ON ot.office_id = och.office_id AND ot.politician_id = och.politician_id AND ot.term_end IS NULL
    WHERE ch.name = ANY($1::text[])
    ORDER BY ch.name, d.label`, [Object.keys(CHAMBERS[state])]);
await pool.end();

const proposals = seats.map((s) => {
  const chamber = CHAMBERS[state][s.chamber];
  const district = districtNumber(s.district_label ?? '');
  const base = { term_id: s.term_id, office_id: s.office_id, politician_id: s.politician_id, full_name: s.full_name,
    chamber: s.chamber, district, current: { term_start: s.term_start, start_precision: s.start_precision } };
  if (!district) return { ...base, proposal: null, flags: ['no-district-number'] };
  const holders = people.filter((p) => p.roles.some((r) => r.type === chamber && String(r.district) === district && !r.end_date));
  if (holders.length !== 1) {
    const f = [`openstates-holders-${holders.length}`];
    if (officialDir && !(official.get(`${chamber}|${district}`) ?? []).length) f.push('official-roster-absent');
    return { ...base, proposal: null, flags: f };
  }
  const os = holders[0];
  const flags: string[] = [];
  if (!surnameMatches(s.full_name, os.family_name ?? os.name.split(' ').pop()!)) flags.push(`holder-mismatch openstates="${os.name}"`);
  if (officialDir) {
    const names = official.get(`${chamber}|${district}`) ?? [];
    if (names.length === 0) flags.push('official-roster-absent');
    else if (!names.some((n) => surnameMatches(s.full_name, officialSurname(n)))) flags.push(`official-mismatch roster="${names.join('/')}"`);
  }
  const start = tenureStartInSeat(os.roles, chamber, district);
  if (!start) return { ...base, openstates: { id: os.id, name: os.name }, proposal: null, flags: [...flags, 'no-current-role-start'] };
  const c = classifyStart(state, chamber, start);
  if (c.flag) flags.push(c.flag);
  return { ...base, openstates: { id: os.id, name: os.name, tenure_start: start, official_links: (os.links ?? []).map((l) => l.url).slice(0, 3) },
    proposal: { term_start: c.term_start, start_precision: c.start_precision }, flags };
});

writeFileSync(out, JSON.stringify({ state, generated_at: new Date().toISOString(), openstates_dir: osDir, proposals }, null, 2));
const clean = proposals.filter((p) => p.proposal && p.flags.length === 0).length;
console.log(`${state}: ${proposals.length} seats — ${clean} clean (day precision, holder matches), ${proposals.length - clean} flagged → ${out}`);
const byFlag = new Map<string, number>();
for (const p of proposals) for (const f of p.flags) byFlag.set(f.split(' ')[0], (byFlag.get(f.split(' ')[0]) ?? 0) + 1);
for (const [f, n] of byFlag) console.log(`  ${f}: ${n}`);
