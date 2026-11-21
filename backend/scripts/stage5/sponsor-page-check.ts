/**
 * sponsor-page-check.ts — reader session, after `state_legiscan.py pairs` on the dry batch (any state, any topic):
 * read a sample of the pages this state's sponsorships are cited on, the way the verifier reads a page, and say
 * which do not print the sponsor's name or the bill's number. Writes nothing to the store or the database.
 *
 *   npx tsx scripts/stage5/sponsor-page-check.ts <batch dir> [--n 12]
 *
 * Reads <batch>/legiscan/sponsor-own-page.json. Writes <batch>/legiscan/sponsor-page-check.json:
 *   { on_file, sampled, ok, faults: [{ name, url, instrument, why: no-name | no-bill | unreadable, detail }] }
 * `pilot_batch.py --verdict` reads that file. Exit 0: every sampled page proves its sponsorship (or no sponsorship is
 * left on an official page). Exit 1: a fault, each printed. Exit 2: no verdict (the list is missing).
 *
 * 🔴 A fault here is a question for the runner in the READER session, not at recipe step 9 of a live run: which page
 * proves a sponsorship in this state (South Dakota, Nevada and Oregon cite the introduced text; Hawaii reads the
 * status page from its data host), or whether its sponsorships are held. Why: scripts/lib/sponsorPageCheck.ts.
 */
import { existsSync, readFileSync, writeFileSync } from 'node:fs';
import { join } from 'node:path';
import { createPageFetcher } from '../../src/lib/researchVerifier.js';
import { createVerificationFetchSession } from '../../src/lib/verificationFetch.js';
import { checkSponsorPage, sampleSponsorPages, type SponsorPageFault, type SponsorRow } from '../lib/sponsorPageCheck.js';

const args = process.argv.slice(2);
const batch = args.find((a) => !a.startsWith('--'));
const n = Number(args[args.indexOf('--n') + 1] && args.includes('--n') ? args[args.indexOf('--n') + 1] : 12);
if (!batch || !Number.isInteger(n) || n < 1) { console.error('usage: sponsor-page-check.ts <batch dir> [--n 12]'); process.exit(2); }
const list = join(batch, 'legiscan', 'sponsor-own-page.json');
if (!existsSync(list)) { console.log(`NO VERDICT: ${list} is missing (run state_legiscan.py pairs on the dry batch first)`); process.exit(2); }
const rows = JSON.parse(readFileSync(list, 'utf8')) as SponsorRow[];
const sample = sampleSponsorPages(rows, n);
const fetcher = createPageFetcher(createVerificationFetchSession().fetch);
const faults: SponsorPageFault[] = [];
for (const row of sample) {
  const page = await fetcher(row[1]);
  if (!page.ok) faults.push({ name: row[0], url: row[1], instrument: row[2], why: 'unreadable', detail: `the verifier's reader cannot open the page (${page.reason.slice(0, 160)})` });
  else faults.push(...checkSponsorPage(row, page.text));
}
const bad = new Set(faults.map((f) => f.url));
const out = { on_file: rows.length, sampled: sample.length, ok: sample.length - bad.size, faults };
writeFileSync(join(batch, 'legiscan', 'sponsor-page-check.json'), JSON.stringify(out, null, 1));
if (!rows.length) console.log('sponsor pages: no sponsorship is left on an official page (each is cited on a page the reader already reads)');
else console.log(`sponsor pages: ${rows.length} sponsorship(s) cited on an official page; read ${sample.length} page(s) across sessions and chambers; ${out.ok} prove the sponsorship, ${bad.size} do not`);
for (const f of faults) console.log(`  FAULT ${f.why}: ${f.name}, ${f.instrument}, ${f.url}\n        ${f.detail}`);
if (faults.length) console.log('  Settle in the reader session: which page proves a sponsorship in this state (a path in state_legiscan.py), or hold its sponsorships. Ask the runner here, not in a live run.');
// no process.exit: the fetch session's sockets close on their own (see verify-stance-research.ts)
process.exitCode = faults.length ? 1 : 0;
setTimeout(() => process.exit(process.exitCode ?? 0), 5000).unref();
