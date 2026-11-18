/**
 * legiscan-evidence-lines — write LegiScan-lane evidence rows for a research batch.
 *
 * Input CSV (header row): full_name, last_name, topic_key, source_url — one row per person and
 * LegiScan URL to cite (a bill page, https://legiscan.com/TX/bill/HB5337/2025, or a roll call,
 * https://legiscan.com/TX/rollcall/SB16/id/1532789). Output CSV: evidence.csv columns (full_name,
 * topic_key, source_url, snippet, snippet_index), one row per canonical line the record holds for
 * that person (src/lib/legiscanEvidence.ts). A pair with no line is reported and left out.
 *
 *   npx tsx scripts/legiscan-evidence-lines.ts --in pairs.csv --out legiscan-evidence.csv [--page-cache <dir>]
 *
 * A source_url that is a legislature's own roll-call page (src/lib/stateRollCallEvidence.ts; a state run
 * from Open States data cites these, having no legiscan.com page) gets its line from that page, fetched with
 * the verifier's own fetch steps. No LegiScan call is made for it.
 *
 * Reads the LegiScan API (LEGISCAN_API_KEY), every call counted against the monthly cap, or the datasets
 * on disk when LEGISCAN_DATASETS is set. Nothing is written to the database except that counter. The lines
 * print no party.
 */
import 'dotenv/config';
import { existsSync, mkdirSync, readFileSync, writeFileSync } from 'node:fs';
import { createHash } from 'node:crypto';
import { join } from 'node:path';
import { parseArgs } from 'node:util';
import { pool } from '../src/lib/db.js';
import { legiscanQuery } from '../src/lib/legiscan/client.js';
import { createLegiscanRecordFetcher, legiscanLinesFor } from '../src/lib/legiscanEvidence.js';
import { loadGovernorTerms } from '../src/lib/governorTerms.js';
import { isStateRollCallUrl, parseStateRollCallRender, stateRollCallLinesFor } from '../src/lib/stateRollCallEvidence.js';
import { createVerificationFetchSession } from '../src/lib/verificationFetch.js';
import { aliasesFrom, lastNameOf } from '../src/lib/researchVerifier.js';

const { values } = parseArgs({ options: { in: { type: 'string' }, out: { type: 'string' }, 'page-cache': { type: 'string' } } });
if (!values.in || !values.out) {
  console.error('usage: legiscan-evidence-lines.ts --in pairs.csv --out legiscan-evidence.csv');
  process.exit(2);
}
const key = process.env.LEGISCAN_API_KEY ?? '';

/** Minimal CSV: quoted fields with doubled quotes, no embedded newlines (the input is hand-made). */
function parseLine(line: string): string[] {
  const out: string[] = [];
  let cur = '', quoted = false;
  for (let i = 0; i < line.length; i++) {
    const c = line[i];
    if (quoted) {
      if (c === '"' && line[i + 1] === '"') { cur += '"'; i++; } else if (c === '"') quoted = false; else cur += c;
    } else if (c === '"') quoted = true;
    else if (c === ',') { out.push(cur); cur = ''; } else cur += c;
  }
  out.push(cur);
  return out;
}
const csvField = (s: string): string => (/[",\n]/.test(s) ? `"${s.replace(/"/g, '""')}"` : s);

const [header, ...lines] = readFileSync(values.in, 'utf8').split(/\r?\n/).filter((l) => l.trim());
const cols = parseLine(header);
const col = (name: string) => {
  const i = cols.indexOf(name);
  if (i < 0) throw new Error(`input is missing the ${name} column`);
  return i;
};
const [iName, iLast, iTopic, iUrl] = ['full_name', 'last_name', 'topic_key', 'source_url'].map(col);

const records = createLegiscanRecordFetcher((op, params) => {
  // Datasets on disk need no key; the live API does.
  if (!key && !process.env.LEGISCAN_DATASETS) throw new Error('LEGISCAN_API_KEY is not set');
  return legiscanQuery(key, op, params);
});
// A legislature's own roll-call page (stateRollCallEvidence.ts) is read through the verifier's own fetch
// steps, so a line is built from exactly the text the verifier will check it against.
// The fetch paces itself by the site's Crawl-delay (adapters/stateRollCallAdapter.ts).
// --page-cache <dir>: keep each page's render there, so a second run fetches nothing. Only a render is kept:
// a page the reader refused (or the site refused to serve) is asked for again next time.
const pages = createVerificationFetchSession();
const pageCache = values['page-cache'];
if (pageCache) mkdirSync(pageCache, { recursive: true });
const pageText = new Map<string, Promise<string>>();
const fetchPage = async (url: string): Promise<string> => {
  const file = pageCache ? join(pageCache, `${createHash('sha1').update(url).digest('hex')}.txt`) : '';
  if (file && existsSync(file)) return readFileSync(file, 'utf8');
  const text = await pages.fetch(url);
  if (file && parseStateRollCallRender(text, url)) writeFileSync(file, text);
  return text;
};
const page = (url: string): Promise<string> => {
  let hit = pageText.get(url);
  if (!hit) { hit = fetchPage(url); pageText.set(url, hit); }
  return hit;
};
// A governor's signing line needs the person's dated terms as governor: names resolve to one
// politician by exact full name (case folded); a name that matches none or several gets no terms.
const allNames = [...new Set(lines.map((l) => (parseLine(l)[iName] ?? '').trim()))];
const { rows: byName } = await pool.query<{ id: string; full_name: string; alternate_names: unknown }>(
  `SELECT id::text AS id, full_name, alternate_names FROM essentials.politicians WHERE lower(full_name) = ANY(SELECT lower(n) FROM unnest($1::text[]) AS n)`,
  [allNames]);
const idOf = new Map<string, string | null>();
for (const r of byName) { const k = r.full_name.toLowerCase(); idOf.set(k, idOf.has(k) ? null : r.id); }
// The other names a person is published under: a roll call prints the name a member held on the day. Only for a name
// that resolves to one politician.
const otherNames = new Map(byName.filter((r) => idOf.get(r.full_name.toLowerCase())).map((r) =>
  [r.full_name.toLowerCase(), aliasesFrom(r.alternate_names).map((n) => ({ fullName: n, lastName: lastNameOf(n) }))]));
const terms = await loadGovernorTerms((q, p) => pool.query(q, p as unknown[]), [...idOf.values()].filter((v): v is string => !!v));
const out = ['full_name,topic_key,source_url,snippet,snippet_index'];
const index = new Map<string, number>();
let missing = 0;
for (const raw of lines) {
  const f = parseLine(raw);
  const [fullName, lastName, topic, url] = [f[iName], f[iLast], f[iTopic], f[iUrl]].map((s) => (s ?? '').trim());
  let found: string[] = [];
  try {
    if (isStateRollCallUrl(url)) {
      found = stateRollCallLinesFor(url, await page(url), lastName, fullName, otherNames.get(fullName.toLowerCase()) ?? []);
    } else {
      const id = idOf.get(fullName.toLowerCase());
      found = legiscanLinesFor(url, await records(url), { fullName, lastName, governorTerms: id ? terms.get(id) : undefined });
    }
  } catch (err) {
    console.warn(`${fullName} ${url}: ${(err as Error).message}`);
  }
  if (!found.length) { missing++; console.warn(`no line: ${fullName} ${url}`); }
  for (const line of found) {
    const k = `${fullName}\u0000${topic}`;
    const n = (index.get(k) ?? 0) + 1;
    index.set(k, n);
    out.push([fullName, topic, url, line, String(n)].map(csvField).join(','));
  }
}
writeFileSync(values.out, `${out.join('\n')}\n`);
console.info(`${out.length - 1} lines written to ${values.out}; ${missing} pairs had none`);
await pool.end();
