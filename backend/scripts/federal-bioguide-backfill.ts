/**
 * federal-bioguide-backfill — match every sitting member of Congress in essentials to congress.gov's
 * current-member list, to fill politicians.bioguide_id (the federal vote loader matches members by it).
 *
 *   ADMIN_INGEST_TOKEN=placeholder npx tsx --env-file=.env scripts/federal-bioguide-backfill.ts --out <dir> [--congress 119]
 *
 * DRY RUN ONLY: reads the database, never writes it. Fetches /member/congress/<n>?currentMember=true
 * (CONGRESS_GOV_API_KEY), saves the raw pages in <dir>/congress-gov/, and writes <dir>/report.json and
 * <dir>/report.md. Matching is by SEAT (House: state + district; Senate: state + surname of the two),
 * with the surname as a check; never by surname alone (scripts/lib/bioguideMatch.ts). Party is not read.
 */
import { mkdirSync, writeFileSync } from 'node:fs';
import { join } from 'node:path';
import { pool } from '../src/lib/db.js';
import { ALL_STATES } from '../src/lib/federalCoverage.js';
import { USPS_TO_FIPS } from '../src/lib/usStateCodes.js';
import { matchHolders, type MatchClass, type OfficialMember, type OurHolder } from './lib/bioguideMatch.js';

const arg = (k: string, d?: string) => { const i = process.argv.indexOf(k); return i >= 0 ? process.argv[i + 1] : d; };
const out = arg('--out');
const congress = arg('--congress', '119');
const key = process.env.CONGRESS_GOV_API_KEY;
if (!out || !key) { console.error('usage: federal-bioguide-backfill.ts --out <dir> [--congress 119]   (needs CONGRESS_GOV_API_KEY)'); process.exit(2); }
mkdirSync(join(out, 'congress-gov'), { recursive: true });

// ── Official side: congress.gov current members ──────────────────────────────────────────────
const officials: OfficialMember[] = [];
for (let offset = 0; ; offset += 250) {
  const url = `https://api.congress.gov/v3/member/congress/${congress}?currentMember=true&limit=250&offset=${offset}&format=json`;
  const res = await fetch(url, { headers: { 'X-Api-Key': key } });
  if (!res.ok) throw new Error(`congress.gov ${res.status} at offset ${offset}`);
  const body = await res.json() as { members?: any[] };
  writeFileSync(join(out, 'congress-gov', `members-${offset}.json`), JSON.stringify(body, null, 1));
  for (const m of body.members ?? []) {
    const terms: any[] = m.terms?.item ?? [];
    const now = terms.find((t) => !t.endYear) ?? terms[terms.length - 1];
    if (!now || now.endYear) continue; // no open term: not serving now
    officials.push({
      bioguideId: m.bioguideId, name: m.name, state: m.state,
      district: m.district ?? null, chamber: /senate/i.test(now.chamber) ? 'Senate' : 'House',
    });
  }
  if ((body.members ?? []).length < 250) break;
}
// congress.gov prints "Virgin Islands"; our table may add "U.S.": compare without it.
const bare = (n: string) => n.replace(/^U\.S\.\s+/, '');
const fipsByName = new Map(ALL_STATES.map((s) => [bare(s.name), s.fips]));

// ── Our side: sitting House and Senate incumbents, one row per held seat ───────────────────────
const { rows } = await pool.query(`
  SELECT p.id::text AS politician_id, p.full_name, p.last_name, nullif(p.bioguide_id, '') AS bioguide_id,
         d.district_type, d.geo_id, d.state
    FROM essentials.office_current_holder och
    JOIN essentials.offices o     ON o.id = och.office_id
    JOIN essentials.districts d   ON d.id = o.district_id
    JOIN essentials.politicians p ON p.id = och.politician_id
   WHERE d.district_type IN ('NATIONAL_LOWER', 'NATIONAL_UPPER') AND p.is_incumbent`);
const holders: OurHolder[] = rows.map((r) => ({
  politician_id: r.politician_id, full_name: r.full_name, last_name: r.last_name, bioguide_id: r.bioguide_id,
  chamber: r.district_type === 'NATIONAL_LOWER' ? 'House' : 'Senate',
  seat: r.district_type === 'NATIONAL_LOWER' ? String(r.geo_id) : (USPS_TO_FIPS[String(r.state).toUpperCase()] ?? String(r.state)),
}));
const owners = new Map<string, string[]>();
for (const r of (await pool.query(`SELECT id::text, bioguide_id FROM essentials.politicians WHERE coalesce(bioguide_id, '') <> ''`)).rows) {
  owners.set(r.bioguide_id, [...(owners.get(r.bioguide_id) ?? []), r.id]);
}
await pool.end();

const { matches, officialsWithoutSeat } = matchHolders(holders, officials, (n) => fipsByName.get(bare(n)), owners);

// ── Report ───────────────────────────────────────────────────────────────────────────────────
const ORDER: MatchClass[] = ['clean', 'already-set', 'name-differs', 'no-official', 'id-differs', 'id-taken'];
const count = (ch: string, c: MatchClass) => matches.filter((m) => m.holder.chamber === ch && m.cls === c).length;
writeFileSync(join(out, 'report.json'), JSON.stringify({ congress, officials: officials.length, holders: holders.length, matches, officialsWithoutSeat }, null, 1));
const md = [
  `# Federal bioguide backfill — dry run (${new Date().toISOString().slice(0, 10)}, Congress ${congress})`, '',
  `Official current members: ${officials.length} (House ${officials.filter((m) => m.chamber === 'House').length}, Senate ${officials.filter((m) => m.chamber === 'Senate').length}). Our sitting incumbents: ${holders.length}.`, '',
  '| Class | House | Senate |', '|---|---|---|',
  ...ORDER.map((c) => `| ${c} | ${count('House', c)} | ${count('Senate', c)} |`), '',
  ...ORDER.filter((c) => c !== 'clean' && c !== 'already-set').flatMap((c) => {
    const ms = matches.filter((m) => m.cls === c);
    return ms.length ? [`## ${c} (${ms.length})`, '', ...ms.map((m) => `- ${m.holder.full_name} (${m.holder.chamber} ${m.holder.seat}, ${m.holder.politician_id.slice(0, 8)}): ${m.note}`), ''] : [];
  }),
  `## Official members with no matching seat in our data (${officialsWithoutSeat.length})`, '',
  ...officialsWithoutSeat.map((m) => `- ${m.name} (${m.chamber}, ${m.state}${m.chamber === 'House' ? ` ${m.district ?? 'at-large'}` : ''}, ${m.bioguideId})`),
];
writeFileSync(join(out, 'report.md'), md.join('\n') + '\n');
console.log(md.slice(0, 12).join('\n'));
