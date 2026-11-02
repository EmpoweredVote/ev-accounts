/**
 * iga-votes — cite Indiana votes from the official roll-call PDFs (STAGE5 step 7, Indiana).
 *
 *   npx tsx --env-file=.env scripts/stage5/iga-votes.ts <batch dir> <store findings dir> --topic <key>
 *
 * For every seated row, each vote finding (yea / nay) on a cited iga.in.gov page is mapped to its
 * official roll-call PDF: the bill's record in the MyIGA API lists every roll call by chamber and
 * number, and its PDF link resolves to iga.in.gov/pdf-documents/…/rollcalls/<BILL>.<n>_<H|S>.pdf.
 * The PDF is read into its party-free render (src/lib/adapters/igaAdapter.ts) and the person's
 * canonical line is cut from it (src/lib/igaRollCallEvidence.ts):
 *
 *   Indiana House roll call 340 (2025), SB 10 - Culp - 3rd Reading: Culp voted Yea.
 *
 * Then, in the batch: the PDF is cited and its line added to evidence.csv; the official page the
 * finding cited is uncited once every vote on it has a line and evidence.csv holds no other snippet
 * for it. Each line's vote is cross-checked against the finding's act.
 *
 * Writes iga/lines.csv, iga/unmapped.json (votes with no line: a roll call not found, a name printed
 * another way, two members who fit one name — hold that person, never guess), iga/crosscheck.json and
 * iga-votes-log.json; rewrites research.csv and evidence.csv (originals kept as *-pre-iga.csv).
 * Exit 1 when any line disagrees with its finding. Reads the MyIGA API (IGA_API_KEY); writes nothing
 * to the database.
 */
import { copyFileSync, existsSync, mkdirSync, readFileSync, writeFileSync } from 'node:fs';
import { join } from 'node:path';
import { API_BASE, fetchIgaPageText, igaGet, igaRedirectTarget } from '../../src/lib/adapters/igaAdapter.js';
import { igaRollCallLinesFor, parseIgaRollCallLine, type IgaVote } from '../../src/lib/igaRollCallEvidence.js';
import { readCsv } from './lib.js';

const args = process.argv.slice(2);
const opt = (k: string) => (args.includes(k) ? args[args.indexOf(k) + 1] : undefined);
const [B, F] = args.filter((a, i) => !a.startsWith('--') && !args[i - 1]?.startsWith('--'));
const TOPIC = opt('--topic');
if (!B || !F || !TOPIC) { console.error('usage: iga-votes.ts <batch dir> <store findings dir> --topic <key>'); process.exit(2); }
if (!process.env.IGA_API_KEY) { console.error('IGA_API_KEY is not set'); process.exit(2); }

const csvField = (s: string): string => (/[",\n\r]/.test(s) ? `"${s.replace(/"/g, '""')}"` : s);
const writeCsv = (path: string, cols: string[], rows: Record<string, string>[]) =>
  writeFileSync(path, [cols.join(','), ...rows.map((r) => cols.map((c) => csvField(r[c] ?? '')).join(','))].join('\n') + '\n');
const headerOf = (path: string) => readFileSync(path, 'utf8').split(/\r?\n/, 1)[0].split(',');

for (const f of ['research', 'evidence']) {
  if (!existsSync(join(B, `${f}-pre-iga.csv`))) copyFileSync(join(B, `${f}.csv`), join(B, `${f}-pre-iga.csv`));
}
const rows = readCsv(readFileSync(join(B, 'research-pre-iga.csv'), 'utf8'));
const cols = headerOf(join(B, 'research-pre-iga.csv'));
const evidence = readCsv(readFileSync(join(B, 'evidence-pre-iga.csv'), 'utf8'));
const pol: { full_name: string; politician_id: string }[] = JSON.parse(readFileSync(join(B, 'politicians.json'), 'utf8'));
const pid = new Map(pol.map((p) => [p.full_name, p.politician_id]));
const SUF = new Set(['jr', 'sr', 'ii', 'iii', 'iv']);
const lastOf = (n: string) => n.replace(/,/g, ' ').split(/\s+/).filter((w) => w && !SUF.has(w.toLowerCase().replace(/\.$/, ''))).pop() ?? '';

/** "IN-SB-10-2025" → API session and bill name. */
function billOf(instrument: string): { session: string; bill: string } | null {
  const m = /^IN-([A-Z]{2,3})-(\d+)-(\d{4}(?:ss\d)?)$/i.exec(instrument);
  if (!m) return null;
  const t = m[1].toUpperCase().replace(/^([HS])(?:B)$/, '$1B').replace(/^([HS])JR$/, '$1J').replace(/^([HS])CR$/, '$1C');
  return t.length === 2 ? { session: m[3].toLowerCase(), bill: `${t}${m[2].padStart(4, '0')}` } : null;
}

/** Roll-call API link by `${session}/${bill}/${H|S}/${n}`, from each bill's API record. */
const linkIndex = new Map<string, string>();
const pdfIndex = new Map<string, string | null>();
const billsRead = new Set<string>();
async function rollCallPdf(session: string, bill: string, chamber: 'H' | 'S', n: string): Promise<string | null> {
  const key = `${session}/${bill}`;
  if (!billsRead.has(key)) {
    billsRead.add(key);
    const res = await igaGet(`${API_BASE}/${session}/bills/${bill.toLowerCase()}`, 'application/json');
    const b = res ? await res.json().catch(() => null) : null;
    for (const r of Array.isArray(b?.all_rollcalls) ? b.all_rollcalls : []) {
      const ch = r?.chamber?.name === 'House' ? 'H' : r?.chamber?.name === 'Senate' ? 'S' : null;
      if (!ch || !r?.rollcall_number || !r?.link) continue;
      linkIndex.set(`${key}/${ch}/${r.rollcall_number}`, String(r.link));
    }
  }
  // The API's ids are opaque (docs: "subject to change"); its PDF form redirects to the public file,
  // and only that public URL is ever cited.
  const k = `${key}/${chamber}/${n}`;
  if (!pdfIndex.has(k)) {
    const link = linkIndex.get(k);
    const target = link ? await igaRedirectTarget(`${API_BASE}${link}?format=pdf`) : null;
    pdfIndex.set(k, target && /\/rollcalls\/[A-Z]{2}\d{4}\.\d+_[HS]\.pdf$/i.test(target) ? target : null);
  }
  return pdfIndex.get(k) ?? null;
}

const HOUSE = /\bIN House\b|House (?:third reading|concurrence|floor|roll call|vote)|_H\.pdf/i;
const SENATE = /\bIN Senate\b|Senate (?:third reading|concurrence|floor|roll call|vote)|_S\.pdf/i;
const ACT: Record<string, IgaVote> = { yea: 'Yea', nay: 'Nay' };
const pages = new Map<string, string | null>();
const urlCols = () => cols.filter((c) => c.startsWith('source_url_'));

const lines: Record<string, string>[] = [];
const unmapped: string[][] = [];
const cross: Record<string, unknown>[] = [];
const log: string[][] = [];
/** person → official page → did every vote on it get a line? */
const covered = new Map<string, Map<string, boolean>>();

for (const r of rows) {
  if (r.evidence_type === 'blank') continue;
  const name = r.full_name;
  const cited = urlCols().map((c) => r[c]).filter(Boolean);
  const id = pid.get(name);
  if (!id || !existsSync(join(F, `${id}.json`))) continue;
  const d = JSON.parse(readFileSync(join(F, `${id}.json`), 'utf8'));
  const fs: any[] = Array.isArray(d) ? d : d.findings;
  for (const f of fs) {
    const u = String(f.url ?? '');
    if (f.kind !== 'record' || !cited.includes(u) || !u.includes('iga.in.gov') || !(f.act in ACT)) continue;
    const per = covered.get(name) ?? covered.set(name, new Map()).get(name)!;
    if (!per.has(u)) per.set(u, true);
    const miss = (why: string) => { unmapped.push([name, u, f.instrument_id ?? '', why]); per.set(u, false); };
    if (/committee/i.test(String(f.motion ?? ''))) { miss('committee vote (no floor roll call)'); continue; }
    const txt = `${f.note ?? ''} ${f.motion ?? ''} ${u}`;
    const ch = HOUSE.test(txt) ? 'H' : SENATE.test(txt) ? 'S' : null;
    const n = /roll call\D{0,3}(\d+)/i.exec(txt)?.[1] ?? /\.(\d+)_[HS]\.pdf$/.exec(u)?.[1];
    const bill = billOf(String(f.instrument_id ?? ''));
    if (!ch || !n || !bill) { miss(`cannot tell chamber/roll call/bill: ${String(f.motion ?? '').slice(0, 80)}`); continue; }
    const pdf = await rollCallPdf(bill.session, bill.bill, ch, n);
    if (!pdf) { miss(`roll call ${ch} ${n} not in the API record of ${bill.bill} (${bill.session})`); continue; }
    if (!pages.has(pdf)) pages.set(pdf, await fetchIgaPageText(pdf));
    const text = pages.get(pdf);
    const found = text ? igaRollCallLinesFor(pdf, text, lastOf(name), name) : [];
    if (found.length !== 1) { miss(found.length ? `${found.length} members fit the name` : `no line (${pdf})`); continue; }
    const line = found[0];
    const got = parseIgaRollCallLine(line)!.vote;
    cross.push({ name, official: u, pdf, line_vote: got, finding_act: f.act, agree: got === ACT[f.act] });
    if (!lines.some((l) => l.full_name === name && l.source_url === pdf)) lines.push({ full_name: name, topic_key: TOPIC, source_url: pdf, snippet: line });
  }
}

// Merge: cite the PDF, uncite a fully covered official page with no other snippet, re-index evidence.
const lineKeys = new Set(lines.map((l) => `${l.full_name}\u0000${l.source_url}`));
for (const r of rows) {
  const per = covered.get(r.full_name);
  if (!per) continue;
  let urls = urlCols().map((c) => r[c]).filter(Boolean);
  for (const l of lines.filter((x) => x.full_name === r.full_name)) {
    if (!urls.includes(l.source_url)) { urls.push(l.source_url); log.push([r.full_name, 'cite roll-call PDF', l.source_url]); }
  }
  for (const [off, all] of per) {
    const other = evidence.some((e) => e.full_name === r.full_name && e.source_url === off);
    if (all && !other && urls.includes(off)) { urls = urls.filter((x) => x !== off); log.push([r.full_name, 'uncite (every vote on it has a roll-call line)', off]); }
  }
  while (urls.length > urlCols().length) cols.push(`source_url_${urlCols().length + 1}`);
  urlCols().forEach((c, i) => { r[c] = urls[i] ?? ''; });
}
const cited = new Set(rows.flatMap((r) => urlCols().map((c) => `${r.full_name}\u0000${r[c]}`)));
const ev = [
  // A roll-call PDF's old snippets (cut from columns of names) are replaced by its line.
  ...evidence.filter((e) => cited.has(`${e.full_name}\u0000${e.source_url}`) && !lineKeys.has(`${e.full_name}\u0000${e.source_url}`)),
  ...lines.filter((l) => cited.has(`${l.full_name}\u0000${l.source_url}`)),
];
const idx = new Map<string, number>();
for (const e of ev) { const k = `${e.full_name}\u0000${e.topic_key}`; idx.set(k, (idx.get(k) ?? 0) + 1); e.snippet_index = String(idx.get(k)); }

mkdirSync(join(B, 'iga'), { recursive: true });
writeCsv(join(B, 'iga', 'lines.csv'), ['full_name', 'topic_key', 'source_url', 'snippet'], lines);
writeFileSync(join(B, 'iga', 'unmapped.json'), JSON.stringify(unmapped, null, 1));
writeFileSync(join(B, 'iga', 'crosscheck.json'), JSON.stringify(cross, null, 1));
writeFileSync(join(B, 'iga-votes-log.json'), JSON.stringify(log, null, 1));
writeCsv(join(B, 'research.csv'), cols, rows);
writeCsv(join(B, 'evidence.csv'), ['full_name', 'topic_key', 'source_url', 'snippet', 'snippet_index'], ev);
const dis = cross.filter((c) => !c.agree);
console.info(`people ${covered.size} · lines ${lines.length} · unmapped ${unmapped.length} · cross-checked ${cross.length} · disagree ${dis.length} · official uncited ${log.filter((l) => l[1].startsWith('uncite')).length}`);
for (const c of dis) console.info('DISAGREE', JSON.stringify(c));
process.exit(dis.length ? 1 : 0);
