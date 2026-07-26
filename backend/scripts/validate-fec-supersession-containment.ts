/**
 * GO/NO-GO check for retiring the pre-fix FEC amendment backlog.
 *
 * The shipped FEC-04b predicate deletes EVERY row of a report below that report's highest
 * `file_number`. That is only sound if an amendment RE-REPORTS THE WHOLE REPORT — i.e. the later
 * filing's line set is a SUPERSET of the earlier one's. If FEC amendments instead carried only
 * the DELTA lines, that predicate would destroy real contributions.
 *
 * Nothing in the FEC-04b work tested that: its unit tests assert the SQL fires, not that the
 * surviving filing still contains the retired filing's money. This checks it against live data.
 *
 * Method: per (report_year, report_type) within one contribution-date window, compare each
 * superseded filing's lines against the surviving filing's as a MULTISET on
 * (contributor_name, amount, date) — a multiset, so FEC's legitimate repeated identical lines
 * (five $1.00 recurring donations on one day) are compared by COUNT rather than collapsed.
 *
 *   tsx scripts/validate-fec-supersession-containment.ts <detector.json> [--windows N]
 *
 * Read-only: no database connection, no writes. Shares the cron's FEC rate budget.
 */

import 'dotenv/config';
import { readFileSync, writeFileSync } from 'fs';
import { fetchWindow, lineKey, byReportAndFiling } from './lib/fecScheduleAWindow.js';

const reportPath = process.argv[2];
if (!reportPath) {
  console.error('usage: tsx scripts/validate-fec-supersession-containment.ts <detector.json> [--windows N]');
  process.exit(2);
}
const wIdx = process.argv.indexOf('--windows');
const MAX = wIdx > -1 ? parseInt(process.argv[wIdx + 1]!, 10) : 25;

interface Detail { cmte: string; donor: string; amount: number; date: string }
const det = JSON.parse(readFileSync(reportPath, 'utf8')) as {
  findings: { politician_source_id: string; detail: Detail[] }[];
};

// One window per (committee, period, date) that the detector implicated.
const windows = new Map<string, { cmte: string; period: number; date: string }>();
for (const f of det.findings) {
  for (const g of f.detail) {
    const date = String(g.date).slice(0, 10);
    const y = parseInt(date.slice(0, 4), 10);
    const period = y % 2 === 0 ? y : y + 1;
    windows.set(`${g.cmte}|${period}|${date}`, { cmte: g.cmte, period, date });
  }
}
const list = [...windows.values()];
console.log(`${list.length} date window(s) implicated; checking ${Math.min(MAX, list.length)}\n`);

let superset = 0, notSuperset = 0, single = 0, failed = 0;
const violations: unknown[] = [];

for (const w of list.slice(0, MAX)) {
  let rows;
  try { rows = await fetchWindow(w.cmte, w.period, w.date); }
  catch (e) { failed++; console.log(`  ? ${w.cmte} ${w.period} ${w.date}: ${(e as Error).message}`); continue; }

  for (const [rk, files] of byReportAndFiling(rows)) {
    if (files.size < 2) { single++; continue; }
    const nums = [...files.keys()].sort((a, b) => a - b);
    const keep = nums[nums.length - 1]!;

    const keepCount = new Map<string, number>();
    for (const r of files.get(keep)!) keepCount.set(lineKey(r), (keepCount.get(lineKey(r)) ?? 0) + 1);

    for (const n of nums.slice(0, -1)) {
      const loseCount = new Map<string, number>();
      for (const r of files.get(n)!) loseCount.set(lineKey(r), (loseCount.get(lineKey(r)) ?? 0) + 1);

      const missing: { line: string; in_superseded: number; in_survivor: number }[] = [];
      for (const [k, c] of loseCount) {
        const have = keepCount.get(k) ?? 0;
        if (have < c) missing.push({ line: k, in_superseded: c, in_survivor: have });
      }
      if (missing.length === 0) {
        superset++;
        console.log(`  OK  ${w.cmte} ${rk} ${w.date}: file ${n} (${files.get(n)!.length}) ⊆ file ${keep} (${files.get(keep)!.length})`);
      } else {
        notSuperset++;
        const lost = missing.reduce((a, m) =>
          a + (m.in_superseded - m.in_survivor) * Number(m.line.split('|')[1] || 0), 0);
        console.log(`  ✗ NOT-SUPERSET ${w.cmte} ${rk} ${w.date}: ${missing.length} line(s) of file ${n}`
                  + ` absent from survivor ${keep} → $${lost.toLocaleString()} at risk`);
        for (const m of missing.slice(0, 4)) console.log(`        ${m.line} (${m.in_superseded} vs ${m.in_survivor})`);
        violations.push({ ...w, report: rk, superseded_file: n, survivor_file: keep, missing, lost_money: lost });
      }
    }
  }
}

console.log(`\nreports with one filing in-window (nothing to retire): ${single}`);
console.log(`superseded filings that ARE a subset of the survivor  : ${superset}`);
console.log(`superseded filings that are NOT                       : ${notSuperset}`);
if (failed) console.log(`windows that failed to fetch                         : ${failed}`);

if (violations.length) {
  writeFileSync('data/fec-supersession-violations.json', JSON.stringify(violations, null, 2));
  console.log('\n⚠ WHOLE-REPORT retirement would LOSE data — see data/fec-supersession-violations.json.');
  console.log('  Per-LINE retirement (retire-fec-superseded-local.ts) stays safe regardless: it only');
  console.log('  deletes a row when the SAME line is confirmed present under a higher file_number.');
} else {
  console.log('\n✅ whole-report retirement is lossless on this sample; per-line retirement is safe a fortiori.');
}
