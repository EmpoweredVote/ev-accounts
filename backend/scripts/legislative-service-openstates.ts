/**
 * legislative-service-openstates.ts — PROPOSES essentials.legislative_service rows (CA_0296) from the
 * OpenStates `people` dataset, for the people stance research covers in one state: its seated state
 * legislators AND the current candidates for its state-legislature seats (ruling 2026-09-27, Chris
 * Andrews: "only for people we're researching so candidates and current politicians"). Read-only: it
 * writes a proposal file for a person to review; the write is a separate, reviewed migration.
 *
 *   npx tsx scripts/legislative-service-openstates.ts --openstates <openstates/people checkout> \
 *     --state IN|CA|AZ --out <proposal.json>
 *
 * Matching (fail closed — an unmatched person gets no rows, never a guessed person's):
 *   1. seated: the OpenStates member holding the same chamber + district now, whose surname agrees
 *      (the term-date pass method, CA_0293 / CA_0295);
 *   2. otherwise (candidates, or a seat the first rule cannot place): a UNIQUE OpenStates person of that
 *      state (current or retired) whose family name AND first given name both agree with ours.
 * A candidate who never served matches no one — that is the expected answer, not an error.
 * Every role of type upper/lower in the state becomes one service span, dates exactly as the source
 * gives them ("Don't invent dates": a role with no start_date is start_precision 'unknown').
 */
import 'dotenv/config';
import { readFileSync, readdirSync, existsSync, writeFileSync } from 'node:fs';
import { join } from 'node:path';
import { load as yamlLoad } from 'js-yaml';
import { pool } from '../src/lib/db.js';
import { districtNumber, surnameMatches, type Chamber } from './lib/termStartRules.js';

const arg = (n: string) => { const i = process.argv.indexOf(n); return i > 0 ? process.argv[i + 1] : undefined; };
const osDir = arg('--openstates'); const state = arg('--state'); const out = arg('--out');
const CHAMBERS: Record<string, Record<string, Chamber>> = {
  IN: { 'Indiana State Senate': 'upper', 'Indiana House of Representatives': 'lower' },
  CA: { 'California State Senate': 'upper', 'California State Assembly': 'lower' },
  AZ: { 'State Senate': 'upper', 'House of Representatives': 'lower' },
};
if (!osDir || !state || !out || !CHAMBERS[state]) { console.error('usage: --openstates <dir> --state IN|CA|AZ --out <file>'); process.exit(2); }
const OS_COMMIT = arg('--commit') ?? 'bf4caf10';

interface Role { start_date?: string; end_date?: string; type: string; district: string; jurisdiction?: string }
interface OsPerson { id: string; name: string; given_name?: string; family_name?: string; other_names?: { name: string }[]; roles: Role[] }
const fold = (s: string) => s.normalize('NFD').replace(/[̀-ͯ]/g, '').toLowerCase().trim();
const people: OsPerson[] = [];
for (const sub of ['legislature', 'retired']) {
  const d = join(osDir, 'data', state.toLowerCase(), sub);
  if (!existsSync(d)) continue;
  for (const f of readdirSync(d).filter((x) => x.endsWith('.yml'))) people.push(yamlLoad(readFileSync(join(d, f), 'utf8')) as OsPerson);
}
const jurisdiction = `ocd-jurisdiction/country:us/state:${state.toLowerCase()}/government`;
const legRoles = (p: OsPerson) => (p.roles ?? []).filter((r) => (r.type === 'upper' || r.type === 'lower') && (!r.jurisdiction || r.jurisdiction === jurisdiction));

const { rows } = await pool.query(
  `WITH seated AS (
     SELECT och.politician_id, p.full_name, ch.name AS chamber, d.label AS district_label, 'seated' AS kind
       FROM essentials.office_current_holder och
       JOIN essentials.offices o ON o.id = och.office_id JOIN essentials.chambers ch ON ch.id = o.chamber_id
       JOIN essentials.politicians p ON p.id = och.politician_id LEFT JOIN essentials.districts d ON d.id = o.district_id
      WHERE ch.name = ANY($1::text[]) AND lower(d.state) = $2),
   cand AS (
     SELECT DISTINCT rc.politician_id, p.full_name, ch.name AS chamber, d.label AS district_label, 'candidate' AS kind
       FROM essentials.race_candidates rc
       JOIN essentials.races r ON r.id = rc.race_id JOIN essentials.elections e ON e.id = r.election_id
       JOIN essentials.offices o ON o.id = r.office_id JOIN essentials.chambers ch ON ch.id = o.chamber_id
       JOIN essentials.politicians p ON p.id = rc.politician_id LEFT JOIN essentials.districts d ON d.id = o.district_id
      WHERE ch.name = ANY($1::text[]) AND lower(d.state) = $2 AND rc.politician_id IS NOT NULL AND e.election_date >= DATE '2026-01-01')
   SELECT * FROM seated UNION ALL SELECT * FROM cand`, [Object.keys(CHAMBERS[state]), state.toLowerCase()]);
await pool.end();

// One entry per person: a seated legislator who is also a candidate is matched by the seat first.
type Entry = { politician_id: string; full_name: string; kinds: Set<string>; seats: { chamber: Chamber; district: string | null }[] };
const byPerson = new Map<string, Entry>();
for (const r of rows) {
  const e: Entry = byPerson.get(r.politician_id) ?? { politician_id: r.politician_id, full_name: r.full_name, kinds: new Set<string>(), seats: [] };
  e.kinds.add(r.kind);
  if (r.kind === 'seated') e.seats.push({ chamber: CHAMBERS[state][r.chamber], district: districtNumber(r.district_label ?? '') });
  byPerson.set(r.politician_id, e);
}

const precisionOf = (d?: string) => (!d ? 'unknown' : /^\d{4}-\d{2}-\d{2}$/.test(d) ? 'day' : /^\d{4}-\d{2}$/.test(d) ? 'month' : /^\d{4}$/.test(d) ? 'year' : 'bad');
const asDate = (d?: string) => (!d ? null : d.length === 4 ? `${d}-01-01` : d.length === 7 ? `${d}-01` : d);

const proposals = [...byPerson.values()].map((e) => {
  const flags: string[] = [];
  let os: OsPerson | undefined; let method = '';
  for (const s of e.seats) {
    if (!s.district) continue;
    const hit = people.filter((p) => legRoles(p).some((r) => r.type === s.chamber && String(r.district) === s.district && !r.end_date)
      && surnameMatches(e.full_name, p.family_name ?? p.name.split(' ').pop()!));
    if (hit.length === 1) { os = hit[0]; method = `seat ${s.chamber} ${s.district} + surname`; break; }
  }
  if (!os) {
    // Name match: our surname must be the person's family name AT THE END of our name (suffixes
    // dropped), and our first word must be their given name. OpenStates other_names carry
    // "Last, First" forms ("Miranda, Catherine"): read the part after the comma as the given name,
    // or "Miranda Lopez" matches Catherine Miranda (found 2026-09-27).
    const toks = fold(e.full_name).replace(/[.,]/g, ' ').split(/\s+/).filter((t) => t && !/^(jr|sr|ii|iii|iv)$/.test(t));
    const first = toks[0];
    const endsWith = (fam: string) => { const f = fold(fam).replace(/[.,]/g, ' ').split(/\s+/).filter(Boolean); return f.length > 0 && f.length < toks.length && f.every((w, j) => toks[toks.length - f.length + j] === w); };
    const givens = (p: OsPerson) => [p.given_name ?? p.name.split(' ')[0],
      ...(p.other_names ?? []).map((o) => (o.name.includes(',') ? o.name.split(',')[1].trim().split(/\s+/)[0] : o.name.split(/\s+/)[0]))];
    const hit = people.filter((p) => legRoles(p).length > 0 && endsWith(p.family_name ?? p.name.split(' ').pop()!)
      && givens(p).some((g) => fold(g ?? '').replace(/[.,]/g, '') === first));
    if (hit.length === 1) { os = hit[0]; method = 'family + first given name (unique in state)'; }
    else if (hit.length > 1) flags.push(`openstates-ambiguous-${hit.length}`);
    else flags.push(e.kinds.has('seated') ? 'openstates-no-match-seated' : 'openstates-no-match');
  }
  const spans = os ? legRoles(os).map((r) => {
    const sp = precisionOf(r.start_date), ep = r.end_date ? precisionOf(r.end_date) : null;
    if (sp === 'bad' || ep === 'bad') flags.push('unparsed-date');
    return { chamber: r.type as Chamber, district: String(r.district ?? ''), service_start: asDate(r.start_date), start_precision: sp,
      service_end: asDate(r.end_date), end_precision: ep };
  }).filter((sp) => {
    // A role that ends before it starts is a source error (Harold Slager, IN House 15: start 2020-11-04,
    // end 2018-11-06 — two stints merged). Drop it and flag it; never repair a date by guessing.
    if (sp.service_start && sp.service_end && sp.service_start > sp.service_end) { flags.push('source-span-inverted'); return false; }
    return true;
  }) : [];
  return { politician_id: e.politician_id, full_name: e.full_name, kinds: [...e.kinds].sort(), openstates_id: os?.id ?? null, openstates_name: os?.name ?? null,
    match: method || null, flags, spans, source: os ? `OpenStates people @${OS_COMMIT} ${os.id} (${method})` : null };
});

writeFileSync(out, JSON.stringify({ state, openstates_commit: OS_COMMIT, generated_at: new Date().toISOString(), proposals }, null, 2));
const matched = proposals.filter((p) => p.openstates_id);
const spans = matched.flatMap((p) => p.spans);
const closed = spans.filter((s) => s.service_end);
console.log(`${state}: ${proposals.length} people (${proposals.filter((p) => p.kinds.includes('seated')).length} seated, ${proposals.filter((p) => !p.kinds.includes('seated')).length} candidates only)`);
console.log(`  matched ${matched.length}; spans ${spans.length} (closed ${closed.length}, closed with unknown start ${closed.filter((s) => s.start_precision === 'unknown').length})`);
console.log(`  people with a closed span in the OTHER chamber from a current seat: ${matched.filter((p) => { const cur = p.spans.filter((s) => !s.service_end).map((s) => s.chamber); return p.spans.some((s) => s.service_end && cur.length && !cur.includes(s.chamber)); }).length}`);
const flagCounts = new Map<string, number>(); for (const p of proposals) for (const f of p.flags) flagCounts.set(f, (flagCounts.get(f) ?? 0) + 1);
console.log(`  flags: ${[...flagCounts].map(([k, v]) => `${k} ${v}`).join(', ') || 'none'}`);
