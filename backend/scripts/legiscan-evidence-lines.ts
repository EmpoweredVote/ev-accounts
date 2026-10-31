/**
 * legiscan-evidence-lines — write LegiScan-lane evidence rows for a research batch.
 *
 * Input CSV (header row): full_name, last_name, topic_key, source_url — one row per person and
 * LegiScan URL to cite (a bill page, https://legiscan.com/TX/bill/HB5337/2025, or a roll call,
 * https://legiscan.com/TX/rollcall/SB16/id/1532789). Output CSV: evidence.csv columns (full_name,
 * topic_key, source_url, snippet, snippet_index), one row per canonical line the record holds for
 * that person (src/lib/legiscanEvidence.ts). A pair with no line is reported and left out.
 *
 *   npx tsx scripts/legiscan-evidence-lines.ts --in pairs.csv --out legiscan-evidence.csv
 *
 * Reads the LegiScan API (LEGISCAN_API_KEY), every call counted against the monthly cap. Nothing
 * is written to the database except that counter. The lines print no party.
 */
import 'dotenv/config';
import { readFileSync, writeFileSync } from 'node:fs';
import { parseArgs } from 'node:util';
import { pool } from '../src/lib/db.js';
import { legiscanQuery } from '../src/lib/legiscan/client.js';
import { createLegiscanRecordFetcher, legiscanLinesFor } from '../src/lib/legiscanEvidence.js';
import { loadGovernorTerms } from '../src/lib/governorTerms.js';

const { values } = parseArgs({ options: { in: { type: 'string' }, out: { type: 'string' } } });
if (!values.in || !values.out) {
  console.error('usage: legiscan-evidence-lines.ts --in pairs.csv --out legiscan-evidence.csv');
  process.exit(2);
}
const key = process.env.LEGISCAN_API_KEY;
if (!key) {
  console.error('LEGISCAN_API_KEY is not set');
  process.exit(2);
}

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

const records = createLegiscanRecordFetcher((op, params) => legiscanQuery(key, op, params));
// A governor's signing line needs the person's dated terms as governor: names resolve to one
// politician by exact full name (case folded); a name that matches none or several gets no terms.
const allNames = [...new Set(lines.map((l) => (parseLine(l)[iName] ?? '').trim()))];
const { rows: byName } = await pool.query<{ id: string; full_name: string }>(
  `SELECT id::text AS id, full_name FROM essentials.politicians WHERE lower(full_name) = ANY(SELECT lower(n) FROM unnest($1::text[]) AS n)`,
  [allNames]);
const idOf = new Map<string, string | null>();
for (const r of byName) { const k = r.full_name.toLowerCase(); idOf.set(k, idOf.has(k) ? null : r.id); }
const terms = await loadGovernorTerms((q, p) => pool.query(q, p as unknown[]), [...idOf.values()].filter((v): v is string => !!v));
const out = ['full_name,topic_key,source_url,snippet,snippet_index'];
const index = new Map<string, number>();
let missing = 0;
for (const raw of lines) {
  const f = parseLine(raw);
  const [fullName, lastName, topic, url] = [f[iName], f[iLast], f[iTopic], f[iUrl]].map((s) => (s ?? '').trim());
  let found: string[] = [];
  try {
    const id = idOf.get(fullName.toLowerCase());
    found = legiscanLinesFor(url, await records(url), { fullName, lastName, governorTerms: id ? terms.get(id) : undefined });
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
