/**
 * iga-evidence-lines — write Indiana roll-call lines for a research batch (STAGE5 step 7).
 *
 * Input CSV (header row): full_name, last_name, topic_key, source_url — one row per person and
 * iga.in.gov roll-call PDF (…/rollcalls/SB0010.340_H.pdf). Output CSV: evidence.csv columns
 * (full_name, topic_key, source_url, snippet, snippet_index), one row per canonical line the roll call
 * holds for that person (src/lib/igaRollCallEvidence.ts). A pair with no line is reported and left out:
 * usually a name the clerk prints another way, or a roll call that did not read cleanly.
 *
 *   npx tsx --env-file=.env scripts/stage5/iga-evidence-lines.ts --in pairs.csv --out iga-evidence.csv
 *
 * Reads the MyIGA API (IGA_API_KEY). Writes nothing to the database. The lines print no party.
 */
import { readFileSync, writeFileSync } from 'node:fs';
import { parseArgs } from 'node:util';
import { fetchIgaPageText } from '../../src/lib/adapters/igaAdapter.js';
import { igaRollCallLinesFor, isIgaRollCallUrl } from '../../src/lib/igaRollCallEvidence.js';
import { readCsv } from './lib.js';

const { values } = parseArgs({ options: { in: { type: 'string' }, out: { type: 'string' } } });
if (!values.in || !values.out) { console.error('usage: iga-evidence-lines.ts --in pairs.csv --out iga-evidence.csv'); process.exit(2); }
if (!process.env.IGA_API_KEY) { console.error('IGA_API_KEY is not set'); process.exit(2); }

const csvField = (s: string): string => (/[",\n]/.test(s) ? `"${s.replace(/"/g, '""')}"` : s);
const pages = new Map<string, string | null>();
const out = ['full_name,topic_key,source_url,snippet,snippet_index'];
const index = new Map<string, number>();
let missing = 0;
for (const r of readCsv(readFileSync(values.in, 'utf8'))) {
  const [fullName, lastName, topic, url] = [r.full_name, r.last_name, r.topic_key, r.source_url].map((s) => (s ?? '').trim());
  if (!isIgaRollCallUrl(url)) { missing++; console.warn(`not a roll-call PDF: ${fullName} ${url}`); continue; }
  if (!pages.has(url)) pages.set(url, await fetchIgaPageText(url));
  const text = pages.get(url);
  const found = text ? igaRollCallLinesFor(url, text, lastName, fullName) : [];
  if (found.length !== 1) {
    missing++;
    console.warn(`${found.length ? `${found.length} lines (ambiguous)` : 'no line'}: ${fullName} ${url}`);
    continue; // two members who both fit the name: hold the person, never guess
  }
  const k = `${fullName}\u0000${topic}`;
  const n = (index.get(k) ?? 0) + 1;
  index.set(k, n);
  out.push([fullName, topic, url, found[0], String(n)].map(csvField).join(','));
}
writeFileSync(values.out, `${out.join('\n')}\n`);
console.info(`${out.length - 1} lines written to ${values.out}; ${missing} pairs had none`);
