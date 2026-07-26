/** One-off: re-verify the 27 rows retired by retire-fec-amendment-dupes.mjs against the
 *  corrected PER-LINE rule — i.e. confirm the same (amount, date) line really does exist under a
 *  higher file_number in the same report, so those deletions were not delta-amendment losses. */
import 'dotenv/config';
import { readFileSync } from 'fs';
import { fetchWindow } from './lib/fecScheduleAWindow.js';

const snap = JSON.parse(readFileSync('data/fec-amendment-retired-snapshot.json', 'utf8')) as {
  rows: { cmte: string; amount: string; contribution_date: string; donor_name_normalized: string;
          kept_file_number: number; report: string }[];
};
let ok = 0, bad = 0;
for (const r of snap.rows) {
  const date = r.contribution_date.slice(0, 10);
  const y = parseInt(date.slice(0, 4), 10);
  const period = y % 2 === 0 ? y : y + 1;
  const rows = await fetchWindow(r.cmte, period, date);
  const [rt, ry] = r.report.split('|');
  const same = rows.filter((x) => Number(x.amount) === Number(r.amount)
    && x.report_type === rt && String(x.report_year) === ry);
  const files = [...new Set(same.map((x) => x.file_number))].sort((a, b) => Number(a) - Number(b));
  // per-line evidence = this amount appears under >1 file_number in this report, and the kept
  // file_number is the highest of them
  const evidence = files.length > 1 && Number(files[files.length - 1]) === Number(r.kept_file_number);
  if (evidence) ok++; else {
    bad++;
    console.log(`  ✗ ${r.cmte} ${r.report} ${date} $${r.amount} ${r.donor_name_normalized}`
              + `  files=[${files.join(',')}] kept=${r.kept_file_number}`);
  }
}
console.log(`\nper-line evidence CONFIRMED for ${ok} of ${snap.rows.length} already-retired rows`);
if (bad) console.log(`⚠ ${bad} row(s) lack per-line evidence — restore from the snapshot`);
