// 01-build-worklist.ts
// Builds the Track A worklist: the top-N money-bearing cal_access links on active politicians whose
// last full_name token IS their stored surname (bucket B), classified by whether the committee name
// names the politician.
//
// Plan: docs/superpowers/plans/2026-08-16-cal-access-bucket-b.md (Task 1)
// Spec: docs/superpowers/specs/2026-08-16-cal-access-bucket-b-design.md
//
// Run from backend/:  npx tsx scripts/cal-access-bucket-b/01-build-worklist.ts
import 'dotenv/config';
import * as fs from 'fs';
import * as path from 'path';
import { Pool } from 'pg';

const TOP_N = Number(process.env.TOP_N ?? 50);
const OUT_DIR = path.join(process.cwd(), 'data', 'cal-access-bucket-b');

// Money comes from contribution_summary_agg, never from contributions -- aggregates over the latter
// blow the statement timeout, even scoped to one politician.
const SQL = `
WITH b AS (
  SELECT ps.id AS source_id, ps.external_id AS filer_id, p.id AS politician_id,
         p.full_name AS politician_name,
         coalesce(p.first_name,'') AS first_name, coalesce(p.last_name,'') AS last_name,
         coalesce(substring(ps.notes from '"committee_name"\\s*:\\s*"([^"]{0,200})'),'') AS committee_name,
         round(coalesce(sum(g.total_amount),0)::numeric,2) AS dollars
    FROM transparent_motivations.politician_sources ps
    JOIN essentials.politicians p ON p.id = ps.essentials_politician_id
    LEFT JOIN transparent_motivations.contribution_summary_agg g ON g.politician_source_id = ps.id
   WHERE ps.source_system = 'cal_access'
     AND p.is_active
     AND lower(regexp_replace(p.full_name,'^.*\\s','')) = lower(coalesce(p.last_name,''))
   GROUP BY ps.id, ps.external_id, p.id, p.full_name, p.first_name, p.last_name, ps.notes
)
SELECT *, row_number() OVER (ORDER BY dollars DESC) AS rank
  FROM b
 WHERE dollars > 0
 ORDER BY dollars DESC
 LIMIT $1;
`;

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
  const pool = new Pool({ connectionString: process.env.DATABASE_URL, ssl: { rejectUnauthorized: false } });
  const { rows } = await pool.query(SQL, [TOP_N]);
  await pool.end();

  const out = rows.map(r => ({
    source_id: r.source_id, filer_id: r.filer_id, politician_id: r.politician_id,
    politician_name: r.politician_name, first_name: r.first_name, last_name: r.last_name,
    committee_name: r.committee_name, dollars: Number(r.dollars), rank: Number(r.rank),
    verdict: verdictFor(r),
  }));

  fs.mkdirSync(OUT_DIR, { recursive: true });
  fs.writeFileSync(path.join(OUT_DIR, 'worklist.json'), JSON.stringify(out, null, 2));

  const tally: Record<string, { n: number; dollars: number }> = {};
  for (const r of out) {
    tally[r.verdict] ??= { n: 0, dollars: 0 };
    tally[r.verdict].n++; tally[r.verdict].dollars += r.dollars;
  }
  console.log(`wrote ${out.length} rows to ${path.join(OUT_DIR, 'worklist.json')}`);
  for (const [k, v] of Object.entries(tally)) console.log(`  ${k}: ${v.n} links, $${v.dollars.toFixed(2)}`);
  console.log(`  TOTAL: $${out.reduce((a, r) => a + r.dollars, 0).toFixed(2)}`);
}
main();
