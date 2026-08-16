// 05-build-money-worklist.ts
// Builds the Track B money worklist: EVERY still-`confirmed` bucket-B cal_access link that carries a
// contribution_summary_agg row and that Track A did not already adjudicate. Expect 304.
//
// Plan: docs/superpowers/plans/2026-08-16-cal-access-bucket-b.md (Task 5, step 1)
//
// Run from backend/:  npx tsx scripts/cal-access-bucket-b/05-build-money-worklist.ts
//
// ── WHY THE EXCLUSION IS BY source_id, NOT BY THE MIGRATION NOTE ─────────────────────────────────
// Only Track A's 18 PURGES carry the "WRONG PERSON (migration 1790" note; its 32 KEEPS carry nothing
// distinguishing. Filtering on the note would therefore re-open all 32 verified keeps -- including
// Newsom's $10.68M -- and a name-based rule marks them unknown, because Cal-Access omits an
// incumbent's given name from their own committee. Excluding the full 50-row decision set is the only
// filter that preserves the evidence work.
//
// ── MEMBERSHIP IS "HAS AN AGG ROW", NOT "dollars > 0" ────────────────────────────────────────────
// One link has an agg row totalling $0. Task 7's remainder is defined as "no agg row", so keying both
// on agg-row presence makes the two sets disjoint and exhaustive; keying this one on dollars > 0
// would strand that link in neither pass. 336 with an agg row - 32 Track A = 304.
import 'dotenv/config';
import * as fs from 'fs';
import * as path from 'path';
import { Pool } from 'pg';

const DIR = path.join(process.cwd(), 'data', 'cal-access-bucket-b');
const EXPECTED = Number(process.env.EXPECTED ?? 304);

const SQL = `
WITH b AS (
  SELECT ps.id AS source_id, ps.external_id AS filer_id, p.id AS politician_id,
         p.full_name AS politician_name,
         coalesce(p.first_name,'') AS first_name, coalesce(p.last_name,'') AS last_name,
         coalesce(substring(ps.notes from '"committee_name"\\s*:\\s*"([^"]{0,200})'),'') AS committee_name,
         round(coalesce(sum(g.total_amount),0)::numeric,2) AS dollars,
         count(g.politician_source_id) AS agg_rows
    FROM transparent_motivations.politician_sources ps
    JOIN essentials.politicians p ON p.id = ps.essentials_politician_id
    LEFT JOIN transparent_motivations.contribution_summary_agg g ON g.politician_source_id = ps.id
   WHERE ps.source_system = 'cal_access'
     AND p.is_active
     AND ps.research_status = 'confirmed'
     AND lower(regexp_replace(p.full_name,'^.*\\s','')) = lower(coalesce(p.last_name,''))
     AND ps.id <> ALL($1::uuid[])
   GROUP BY ps.id, ps.external_id, p.id, p.full_name, p.first_name, p.last_name, ps.notes
)
SELECT *, row_number() OVER (ORDER BY dollars DESC) AS rank
  FROM b
 WHERE agg_rows > 0
 ORDER BY dollars DESC;
`;

// Identical to 01-build-worklist.ts: does OUR stored committee name already carry their given name?
function verdictFor(row: any): string {
  const cmt = String(row.committee_name || '').toLowerCase();
  if (cmt === '') return 'no-committee-name';
  const given = String(row.first_name || '').trim().split(/\s+/)[0].toLowerCase();
  if (given && new RegExp('\\b' + given.replace(/[.*+?^${}()|[\]\\]/g, '\\$&') + '\\b').test(cmt)) {
    return 'names-them';
  }
  return 'needs-evidence';
}

async function main() {
  if (!process.env.DATABASE_URL) { console.error('ERROR: DATABASE_URL is not set'); process.exit(1); }

  const trackA = JSON.parse(fs.readFileSync(path.join(DIR, 'track-a-decisions.json'), 'utf8'));
  const trackAIds: string[] = trackA.map((d: any) => d.source_id);
  if (trackAIds.length !== 50) {
    console.error(`ERROR: expected 50 Track A decisions, found ${trackAIds.length}. Stop and reconcile.`);
    process.exit(1);
  }

  const pool = new Pool({ connectionString: process.env.DATABASE_URL, ssl: { rejectUnauthorized: false } });
  const { rows } = await pool.query(SQL, [trackAIds]);
  await pool.end();

  const out = rows.map(r => ({
    source_id: r.source_id, filer_id: r.filer_id, politician_id: r.politician_id,
    politician_name: r.politician_name, first_name: r.first_name, last_name: r.last_name,
    committee_name: r.committee_name, dollars: Number(r.dollars), rank: Number(r.rank),
    verdict: verdictFor(r),
  }));

  fs.mkdirSync(DIR, { recursive: true });
  fs.writeFileSync(path.join(DIR, 'money-worklist.json'), JSON.stringify(out, null, 2));

  const tally: Record<string, { n: number; dollars: number }> = {};
  for (const r of out) {
    tally[r.verdict] ??= { n: 0, dollars: 0 };
    tally[r.verdict].n++; tally[r.verdict].dollars += r.dollars;
  }
  console.log(`wrote ${out.length} rows to money-worklist.json`);
  for (const [k, v] of Object.entries(tally)) console.log(`  ${k}: ${v.n} links, $${v.dollars.toFixed(2)}`);
  console.log(`  TOTAL: $${out.reduce((a, r) => a + r.dollars, 0).toFixed(2)}`);

  // Every link needs a filer record, including `names-them` -- unlike Track A, which auto-kept those.
  // Our stored committee_name came from the same discredited ingest; the filer record is the source.
  const uniqueFilers = [...new Set(out.map(r => r.filer_id))];
  console.log(`  ${uniqueFilers.length} unique filer ids to fetch`);

  if (out.length !== EXPECTED) {
    console.error(`\n🔴 EXPECTED ${EXPECTED} rows, got ${out.length}. Reconcile before fetching.`);
    process.exit(1);
  }
}
main();
