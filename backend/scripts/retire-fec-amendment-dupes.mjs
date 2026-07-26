/**
 * Retire the PRE-FIX FEC amendment double-count backlog.
 *
 * Why this cannot be a simple DELETE: the detector's signature (same committee/donor/
 * amount/date across >1 sub_id load-date prefix) catches TWO different things, measured
 * on an 18-group sample 2026-07-25:
 *   11  TRUE AMENDMENT  — versions share (report_type, report_year), differ in file_number.
 *                          The later filing supersedes: retire the earlier. SAFE.
 *    4  CROSS-REPORT    — versions sit in DIFFERENT reports (e.g. Q1/2020 and Q3/2020).
 *                          Not a supersession. Retiring these would destroy real rows.
 *    3  UNRESOLVABLE    — the live API no longer returns 2 matches, so we cannot decide.
 * Deleting on the sub_id prefix alone would therefore wrongly remove ~39% of the backlog.
 *
 * So every group is classified against the FEC API first, and ONLY same-report groups are
 * retired — keeping the row whose sub_id belongs to the highest file_number.
 *
 * Pre-fix rows carry no file_number (that is why the shipped FEC-04b fix skips them), so the
 * mapping from a stored row to its filing comes from the API response's sub_id -> file_number.
 * That makes the survivor a resolved fact, never an inference from the prefix.
 *
 *   node scripts/retire-fec-amendment-dupes.mjs <detector.json> [--groups N] [--apply]
 *
 * Dry run by default. Snapshots every row it deletes. Self-throttled (5s/request) because the
 * FEC key is shared with the production daily ingest and its 15/min limiter is per-process.
 */
import 'dotenv/config';
import { readFileSync, writeFileSync, existsSync } from 'fs';
import { Pool } from 'pg';

const report = process.argv[2];
if (!report) { console.error('usage: retire-fec-amendment-dupes.mjs <detector.json> [--groups N] [--apply]'); process.exit(2); }
const gi = process.argv.indexOf('--groups');
const MAX = gi > -1 ? parseInt(process.argv[gi + 1], 10) : 25;
const APPLY = process.argv.includes('--apply');
const KEY = process.env.FEC_API_KEY;
if (!KEY) { console.error('FEC_API_KEY not set'); process.exit(2); }

const SNAP = 'data/fec-amendment-retired-snapshot.json';
const STATE = 'data/fec-amendment-retire-state.json';
const done = existsSync(STATE) ? new Set(JSON.parse(readFileSync(STATE, 'utf8')).done) : new Set();
const snapshot = existsSync(SNAP) ? JSON.parse(readFileSync(SNAP, 'utf8')) : { retired_at: null, rows: [] };

const det = JSON.parse(readFileSync(report, 'utf8'));
const groups = det.findings.flatMap((f) => f.detail.map((g) => ({ ...g, ps: f.politician_source_id })));
const pool = new Pool({ connectionString: process.env.DATABASE_URL, ssl: { rejectUnauthorized: false } });
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
const gkey = (g) => `${g.ps}|${g.cmte}|${g.donor}|${g.amount}|${String(g.date).slice(0, 10)}`;

let amend = 0, cross = 0, unres = 0, deleted = 0, processed = 0;
for (const g of groups) {
  if (processed >= MAX) break;
  const k = gkey(g);
  if (done.has(k)) continue;
  processed++;

  const surname = String(g.donor).replace(/[^a-z ]/g, '').trim().split(/\s+/).pop().toUpperCase();
  const yr = parseInt(String(g.date).slice(0, 4), 10);
  const per = yr % 2 === 0 ? yr : yr + 1;
  const url = `https://api.open.fec.gov/v1/schedules/schedule_a/?api_key=${KEY}`
            + `&committee_id=${g.cmte}&two_year_transaction_period=${per}`
            + `&contributor_name=${encodeURIComponent(surname)}&per_page=50`;
  let live = [];
  try {
    const res = await fetch(url, { signal: AbortSignal.timeout(60_000) });
    if (!res.ok) throw new Error(`HTTP ${res.status}`);
    live = (await res.json()).results ?? [];
  } catch (e) {
    console.log(`  ? ${g.cmte} ${surname}: fetch failed (${e.message}) — skipped, not marked done`);
    await sleep(5000); continue;
  }
  const m = live.filter((x) => Number(x.contribution_receipt_amount) === Number(g.amount)
    && String(x.contribution_receipt_date ?? '').slice(0, 10) === String(g.date).slice(0, 10));

  const reports = new Set(m.map((x) => `${x.report_type}|${x.report_year}`));
  if (m.length < 2) {
    unres++; done.add(k);
    console.log(`  - UNRESOLVABLE ${g.cmte} ${surname} $${g.amount} (API returns ${m.length})`);
  } else if (reports.size > 1) {
    cross++; done.add(k);
    console.log(`  - CROSS-REPORT  ${g.cmte} ${surname} $${g.amount} across ${[...reports].join(', ')} — KEPT`);
  } else {
    // same report, so the highest file_number is the surviving version
    const best = m.reduce((a, b) => (Number(b.file_number || 0) > Number(a.file_number || 0) ? b : a));
    const losers = m.filter((x) => x.sub_id !== best.sub_id).map((x) => x.sub_id);
    amend++;
    if (losers.length === 0) { done.add(k); continue; }
    const { rows: victims } = await pool.query(
      `SELECT id, source_transaction_id, amount, contribution_date, donor_name_normalized,
              raw_record->>'committee_id' AS cmte
         FROM transparent_motivations.contributions
        WHERE data_source='fec' AND politician_source_id=$1 AND source_transaction_id = ANY($2::text[])`,
      [g.ps, losers]);
    console.log(`  * AMENDMENT     ${g.cmte} ${surname} $${g.amount} keep file ${best.file_number}`
              + ` (sub ${best.sub_id}); retire ${victims.length} row(s)`);
    if (APPLY && victims.length) {
      snapshot.rows.push(...victims.map((v) => ({ ...v, kept_sub_id: best.sub_id,
        kept_file_number: best.file_number, report: [...reports][0] })));
      const res = await pool.query(
        `DELETE FROM transparent_motivations.contributions
          WHERE data_source='fec' AND politician_source_id=$1 AND source_transaction_id = ANY($2::text[])`,
        [g.ps, losers]);
      deleted += res.rowCount ?? 0;
    }
    done.add(k);
  }
  await sleep(5000);   // shared FEC key — stay well under the 15/min production budget
}

console.log(`\nprocessed ${processed} group(s) of ${groups.length} detected (${done.size} cumulatively resolved)`);
console.log(`  TRUE AMENDMENT : ${amend}`);
console.log(`  CROSS-REPORT   : ${cross}  (kept — not a supersession)`);
console.log(`  UNRESOLVABLE   : ${unres}  (kept — API cannot confirm)`);
console.log(APPLY ? `  DELETED ROWS   : ${deleted}` : '  DRY RUN — pass --apply to delete');
if (APPLY) {
  snapshot.retired_at = new Date().toISOString();
  writeFileSync(SNAP, JSON.stringify(snapshot, null, 2));
  writeFileSync(STATE, JSON.stringify({ done: [...done] }, null, 2));
  console.log(`  snapshot -> ${SNAP} (${snapshot.rows.length} rows cumulative)`);
}
await pool.end();
