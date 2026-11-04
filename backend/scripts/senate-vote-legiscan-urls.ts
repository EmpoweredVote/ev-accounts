/**
 * senate-vote-legiscan-urls — re-point senate.gov roll-call citations at LegiScan, for the LegiScan lane.
 *
 * Input CSV (header row): full_name, last_name, topic_key, source_url — the same pairs file
 * legiscan-evidence-lines.ts reads. Each senate.gov roll-call URL
 * (https://www.senate.gov/legislative/LIS/roll_call_votes/vote1192/vote_119_2_00057.htm) is replaced by
 * the LegiScan roll-call page for the same vote (https://legiscan.com/US/rollcall/SB1383/id/1665236).
 * Rows with any other URL are left out. Output: the same columns plus senate_url, ready for
 *
 *   npx tsx scripts/senate-vote-legiscan-urls.ts --in pairs.csv --out pairs-legiscan.csv
 *   npx tsx scripts/legiscan-evidence-lines.ts --in pairs-legiscan.csv --out legiscan-evidence.csv
 *
 * How (src/lib/senateRollCall.ts): Voteview's S<congress>_rollcalls.csv gives the bill and date of
 * each senate.gov vote; LegiScan's bill record gives the roll call with that date and "RC# <n>".
 * Voteview files are cached in --cache (default: the OS temp dir). LegiScan calls go through the
 * counted client (LEGISCAN_API_KEY): about one master list per Congress plus one bill per vote.
 * senate.gov itself is never fetched.
 */
import 'dotenv/config';
import { existsSync, readFileSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { parseArgs } from 'node:util';
import { pool } from '../src/lib/db.js';
import { legiscanQuery } from '../src/lib/legiscan/client.js';
import {
  congressStartYear, legiscanBillNumber, parseSenateVoteUrl, pickLegiscanRollCall, voteviewRow, type VoteviewRollCall,
} from '../src/lib/senateRollCall.js';

const { values } = parseArgs({ options: { in: { type: 'string' }, out: { type: 'string' }, cache: { type: 'string' } } });
if (!values.in || !values.out) {
  console.error('usage: senate-vote-legiscan-urls.ts --in pairs.csv --out pairs-legiscan.csv [--cache dir]');
  process.exit(2);
}
const key = process.env.LEGISCAN_API_KEY;
if (!key) {
  console.error('LEGISCAN_API_KEY is not set');
  process.exit(2);
}
const cacheDir = values.cache ?? tmpdir();

/** Minimal CSV: quoted fields with doubled quotes, no embedded newlines. */
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

const voteview = new Map<number, Promise<VoteviewRollCall[]>>();
function voteviewRows(congress: number): Promise<VoteviewRollCall[]> {
  let hit = voteview.get(congress);
  if (!hit) {
    hit = (async () => {
      const file = join(cacheDir, `S${congress}_rollcalls.csv`);
      if (!existsSync(file)) {
        const res = await fetch(`https://voteview.com/static/data/out/rollcalls/S${congress}_rollcalls.csv`,
          { signal: AbortSignal.timeout(60_000) });
        if (!res.ok) throw new Error(`Voteview S${congress} rollcalls: HTTP ${res.status}`);
        writeFileSync(file, await res.text());
      }
      const [head, ...rows] = readFileSync(file, 'utf8').split(/\r?\n/).filter((l) => l.trim());
      const h = parseLine(head);
      const at = (r: string[], name: string) => r[h.indexOf(name)] ?? '';
      return rows.map(parseLine).map((r) => ({
        session: Number(at(r, 'session')), clerk_rollnumber: Number(at(r, 'clerk_rollnumber')),
        date: at(r, 'date'), bill_number: at(r, 'bill_number'),
      }));
    })();
    voteview.set(congress, hit);
  }
  return hit;
}

const memo = new Map<string, Promise<any>>(); // eslint-disable-line @typescript-eslint/no-explicit-any
const once = (op: string, params: Record<string, string>) => {
  const k = `${op}:${JSON.stringify(params)}`;
  if (!memo.has(k)) memo.set(k, legiscanQuery(key, op, params));
  return memo.get(k)!;
};

/** senate.gov vote URL → LegiScan roll-call URL, or the reason there is none. */
async function legiscanUrlFor(url: string): Promise<string | { why: string }> {
  const ref = parseSenateVoteUrl(url);
  if (!ref) return { why: 'not a senate.gov roll-call URL' };
  const row = voteviewRow(await voteviewRows(ref.congress), ref);
  if (!row) return { why: `Voteview has no Senate vote ${ref.congress}-${ref.session} #${ref.vote}` };
  const bill = legiscanBillNumber(row.bill_number);
  if (!bill) return { why: `vote is not on a bill (Voteview bill "${row.bill_number}")` };
  const year = congressStartYear(ref.congress);
  const sessions = (await once('getSessionList', { state: 'US' })).sessions ?? [];
  const s = sessions.find((x: { year_start: number; special: number }) => Number(x.year_start) === year && !Number(x.special));
  if (!s) return { why: `LegiScan has no US session starting ${year}` };
  const list = (await once('getMasterListRaw', { id: String(s.session_id) })).masterlist ?? {};
  const hit = Object.entries(list).find(([k, b]) => k !== 'session' && (b as { number?: string })?.number === bill);
  if (!hit) return { why: `LegiScan has no ${bill} in the ${ref.congress}th Congress` };
  const record = (await once('getBill', { id: String((hit[1] as { bill_id: number }).bill_id) })).bill;
  const rc = pickLegiscanRollCall(record, row.date, ref.vote);
  if (!rc?.url) return { why: `LegiScan ${bill} has no single Senate roll call RC# ${ref.vote} on ${row.date}` };
  return rc.url;
}

const [header, ...lines] = readFileSync(values.in, 'utf8').split(/\r?\n/).filter((l) => l.trim());
const cols = parseLine(header);
const iUrl = cols.indexOf('source_url');
if (iUrl < 0) throw new Error('input is missing the source_url column');
const out = [[...cols, 'senate_url'].join(',')];
let missing = 0;
for (const raw of lines) {
  const f = parseLine(raw);
  const url = (f[iUrl] ?? '').trim();
  if (!parseSenateVoteUrl(url)) continue;
  let found: string | { why: string };
  try {
    found = await legiscanUrlFor(url);
  } catch (err) {
    found = { why: (err as Error).message };
  }
  if (typeof found !== 'string') { missing++; console.warn(`no LegiScan roll call: ${url}: ${found.why}`); continue; }
  const row = [...f];
  row[iUrl] = found;
  out.push([...row, url].map(csvField).join(','));
}
writeFileSync(values.out, `${out.join('\n')}\n`);
console.info(`${out.length - 1} rows written to ${values.out}; ${missing} senate.gov votes had no LegiScan roll call`);
await pool.end();
