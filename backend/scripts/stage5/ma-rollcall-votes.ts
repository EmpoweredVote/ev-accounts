/**
 * ma-rollcall-votes — cite Massachusetts House votes from the official roll-call PDFs (STAGE5 step 7, MA).
 *
 *   npx tsx --env-file=.env scripts/stage5/ma-rollcall-votes.ts <batch dir> <store findings dir> --topic <key>
 *       [--instruments <dir>]   (default data/source-store/instruments/state-ma)
 *       [--pdf-dir <dir>]       (read saved copies <dir>/<General Court>-HouseRollCall<n>.pdf instead of fetching)
 *
 * Some Massachusetts House roll calls are not in LegiScan at all, and the official PDF prints only a vote
 * mark and a surname, so an ordinary snippet from it never verifies (name_not_present). For every seated
 * row, each House vote finding (yea / nay) on a cited page is matched to its store instrument's House vote
 * (same date and motion), whose `urls` list the roll-call PDF (malegislature.gov/RollCall/<GC>/HouseRollCall<n>.pdf).
 * The PDF is read into its party-free render (src/lib/adapters/maLegislatureAdapter.ts, the verifier's own
 * reader) and the person's canonical line is cut from it (src/lib/maRollCallEvidence.ts):
 *
 *   Massachusetts House roll call 135 (193rd General Court), H.4885 - On acceptance of the report: Kilcoyne voted Yea.
 *
 * The label comes from the PDF, never from a list keyed by surname: it must fit the person's surname (and
 * first initial when printed), and a bare surname two members share yields no line. Then, in the batch: the
 * PDF is cited and its line added to evidence.csv; the page the finding cited is uncited once every vote on
 * it has a line, no other finding of that person rests on it, and evidence.csv holds no other snippet for
 * it. Each line's vote is cross-checked against the finding's act, and its bill against the instrument.
 *
 * Writes ma-rollcall/lines.csv, ma-rollcall/unmapped.json (votes with no line, and why — hold that person,
 * never guess), ma-rollcall/crosscheck.json and ma-rollcall-votes-log.json; rewrites research.csv and
 * evidence.csv (originals kept as *-pre-ma-rollcall.csv). Exit 1 when any line disagrees with its finding.
 * Reads malegislature.gov (public, robots.txt allows it) with the verifier's honest user-agent; writes
 * nothing to the database. The lines print no party.
 */
import { copyFileSync, existsSync, mkdirSync, readFileSync, readdirSync, writeFileSync } from 'node:fs';
import { join } from 'node:path';
import { fetchMaRollCallText, renderMaRollCallBytes } from '../../src/lib/adapters/maLegislatureAdapter.js';
import { maRollCallLinesFor, parseMaRollCallLine, parseMaRollCallUrl, type MaVote } from '../../src/lib/maRollCallEvidence.js';
import { EMPOWERED_VOTE_UA, robotsAllows } from '../../src/lib/verificationFetch.js';
import { readCsv } from './lib.js';

const args = process.argv.slice(2);
const opt = (k: string) => (args.includes(k) ? args[args.indexOf(k) + 1] : undefined);
const [B, F] = args.filter((a, i) => !a.startsWith('--') && !args[i - 1]?.startsWith('--'));
const TOPIC = opt('--topic');
const INSTR = opt('--instruments') ?? 'data/source-store/instruments/state-ma';
const PDF_DIR = opt('--pdf-dir');
if (!B || !F || !TOPIC) {
  console.error('usage: ma-rollcall-votes.ts <batch dir> <store findings dir> --topic <key> [--instruments <dir>] [--pdf-dir <dir>]');
  process.exit(2);
}

const csvField = (s: string): string => (/[",\n\r]/.test(s) ? `"${s.replace(/"/g, '""')}"` : s);
const writeCsv = (path: string, cols: string[], rows: Record<string, string>[]) =>
  writeFileSync(path, [cols.join(','), ...rows.map((r) => cols.map((c) => csvField(r[c] ?? '')).join(','))].join('\n') + '\n');
const headerOf = (path: string) => readFileSync(path, 'utf8').split(/\r?\n/, 1)[0].split(',');

for (const f of ['research', 'evidence']) {
  if (!existsSync(join(B, `${f}-pre-ma-rollcall.csv`))) copyFileSync(join(B, `${f}.csv`), join(B, `${f}-pre-ma-rollcall.csv`));
}
const rows = readCsv(readFileSync(join(B, 'research-pre-ma-rollcall.csv'), 'utf8'));
const cols = headerOf(join(B, 'research-pre-ma-rollcall.csv'));
const evidence = readCsv(readFileSync(join(B, 'evidence-pre-ma-rollcall.csv'), 'utf8'));
const polRaw = JSON.parse(readFileSync(join(B, 'politicians.json'), 'utf8'));
const pol: { full_name: string; politician_id: string }[] = Array.isArray(polRaw) ? polRaw : polRaw.politicians;
const pid = new Map(pol.map((p) => [p.full_name, p.politician_id]));
const SUF = new Set(['jr', 'sr', 'ii', 'iii', 'iv']);
const lastOf = (n: string) => n.replace(/,/g, ' ').split(/\s+/).filter((w) => w && !SUF.has(w.toLowerCase().replace(/\.$/, ''))).pop() ?? '';

// ── store instruments: instrument id → its House votes and its roll-call PDF URLs ─────────────────
interface InstrVote { date: string; body: string; motion: string }
const instruments = new Map<string, { votes: InstrVote[]; urls: string[] }>();
for (const f of readdirSync(INSTR)) {
  if (!f.endsWith('.json')) continue;
  const d = JSON.parse(readFileSync(join(INSTR, f), 'utf8'));
  instruments.set(String(d.id), { votes: Array.isArray(d.votes) ? d.votes : [], urls: Array.isArray(d.urls) ? d.urls.map(String) : [] });
}
/** "MA-H-4885-2024" → "H.4885" (the bill as the roll call prints it). */
const billOf = (id: string): string | null => {
  const m = /^MA-([HS])-(\d+)-\d{4}$/i.exec(id);
  return m ? `${m[1].toUpperCase()}.${m[2]}` : null;
};
const ROLL_NO = /(?:Roll Call No\.?|Yea and Nay No\.?)\s*(\d+)/i;

const pages = new Map<string, string | null>();
async function render(pdf: string): Promise<string | null> {
  if (pages.has(pdf)) return pages.get(pdf)!;
  let t: string | null = null;
  const ref = parseMaRollCallUrl(pdf)!;
  if (PDF_DIR) {
    const p = join(PDF_DIR, `${ref.court}-HouseRollCall${ref.rollNum}.pdf`);
    t = existsSync(p) ? await renderMaRollCallBytes(new Uint8Array(readFileSync(p)), pdf) : null;
  } else if (await robotsAllows(pdf)) {
    t = await fetchMaRollCallText(pdf, { userAgent: EMPOWERED_VOTE_UA });
  }
  pages.set(pdf, t);
  return t;
}

const ACT: Record<string, MaVote> = { yea: 'Yea', nay: 'Nay' };
const urlCols = () => cols.filter((c) => c.startsWith('source_url_'));

const lines: Record<string, string>[] = [];
const unmapped: string[][] = [];
const cross: Record<string, unknown>[] = [];
const log: string[][] = [];
/** person → cited page → did every House vote on it get a line? */
const covered = new Map<string, Map<string, boolean>>();
/** person → pages that also carry a finding this tool does not replace (a sponsorship, a Senate vote …). */
const otherUse = new Map<string, Set<string>>();

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
    const inst = instruments.get(String(f.instrument_id ?? ''));
    const vote = inst?.votes.find((v) => v.body === 'MA House' && v.date === f.date && v.motion === f.motion);
    const isVote = f.kind === 'record' && !!inst && !!vote && f.act in ACT;
    const n = isVote ? ROLL_NO.exec(String(f.motion ?? ''))?.[1] : undefined;
    const pdf = n ? inst!.urls.find((x) => parseMaRollCallUrl(x)?.rollNum === Number(n)) : undefined;
    // The finding counts when the row cites its page, or already cites its roll-call PDF (a re-run, or an
    // earlier pass that cited the PDF with a grid snippet).
    if (!cited.includes(u) && !(pdf && cited.includes(pdf))) continue;
    if (!isVote) {
      (otherUse.get(name) ?? otherUse.set(name, new Set()).get(name)!).add(u);
      continue;
    }
    const per = covered.get(name) ?? covered.set(name, new Map()).get(name)!;
    if (cited.includes(u) && !per.has(u)) per.set(u, true);
    const miss = (why: string) => { unmapped.push([name, u, f.instrument_id ?? '', why]); if (per.has(u)) per.set(u, false); };
    if (!pdf) { miss(`no House roll-call PDF for "${String(f.motion ?? '').slice(0, 80)}" in the instrument's urls`); continue; }
    const text = await render(pdf);
    if (!text) { miss(`roll call did not read cleanly (${pdf})`); continue; }
    const found = maRollCallLinesFor(pdf, text, lastOf(name), name);
    if (found.length !== 1) { miss(found.length ? `${found.length} labels fit the name` : `no label fits the name (${pdf})`); continue; }
    const line = found[0];
    const l = parseMaRollCallLine(line)!;
    const billOk = l.bill === billOf(String(f.instrument_id));
    cross.push({ name, official: u, pdf, label: l.name, line_vote: l.vote, finding_act: f.act, bill: l.bill, agree: l.vote === ACT[f.act] && billOk });
    if (!lines.some((x) => x.full_name === name && x.source_url === pdf)) lines.push({ full_name: name, topic_key: TOPIC, source_url: pdf, snippet: line });
  }
}

// Merge: cite the PDF, uncite a fully covered page with no other use and no other snippet, re-index evidence.
const lineKeys = new Set(lines.map((l) => `${l.full_name}\u0000${l.source_url}`));
const disagreeKeys = new Set(cross.filter((c) => !c.agree).map((c) => `${c.name}\u0000${c.pdf}`));
for (const r of rows) {
  const per = covered.get(r.full_name);
  if (!per) continue;
  let urls = urlCols().map((c) => r[c]).filter(Boolean);
  for (const l of lines.filter((x) => x.full_name === r.full_name)) {
    if (disagreeKeys.has(`${l.full_name}\u0000${l.source_url}`)) continue; // never cite a line that disagrees
    if (!urls.includes(l.source_url)) { urls.push(l.source_url); log.push([r.full_name, 'cite roll-call PDF', l.source_url]); }
  }
  for (const [page, all] of per) {
    const snippet = evidence.some((e) => e.full_name === r.full_name && e.source_url === page);
    const used = otherUse.get(r.full_name)?.has(page) ?? false;
    if (all && !snippet && !used && urls.includes(page)) {
      urls = urls.filter((x) => x !== page);
      log.push([r.full_name, 'uncite (every House vote on it has a roll-call line)', page]);
    }
  }
  while (urls.length > urlCols().length) cols.push(`source_url_${urlCols().length + 1}`);
  urlCols().forEach((c, i) => { r[c] = urls[i] ?? ''; });
}
const citedSet = new Set(rows.flatMap((r) => urlCols().map((c) => `${r.full_name}\u0000${r[c]}`)));
const ev = [
  // A roll-call PDF's old snippets (cut from the grid of marks and surnames) are replaced by its line.
  ...evidence.filter((e) => citedSet.has(`${e.full_name}\u0000${e.source_url}`) && !lineKeys.has(`${e.full_name}\u0000${e.source_url}`)),
  ...lines.filter((l) => citedSet.has(`${l.full_name}\u0000${l.source_url}`)),
];
const idx = new Map<string, number>();
for (const e of ev) { const k = `${e.full_name}\u0000${e.topic_key}`; idx.set(k, (idx.get(k) ?? 0) + 1); e.snippet_index = String(idx.get(k)); }

mkdirSync(join(B, 'ma-rollcall'), { recursive: true });
writeCsv(join(B, 'ma-rollcall', 'lines.csv'), ['full_name', 'topic_key', 'source_url', 'snippet'], lines);
writeFileSync(join(B, 'ma-rollcall', 'unmapped.json'), JSON.stringify(unmapped, null, 1));
writeFileSync(join(B, 'ma-rollcall', 'crosscheck.json'), JSON.stringify(cross, null, 1));
writeFileSync(join(B, 'ma-rollcall-votes-log.json'), JSON.stringify(log, null, 1));
writeCsv(join(B, 'research.csv'), cols, rows);
writeCsv(join(B, 'evidence.csv'), ['full_name', 'topic_key', 'source_url', 'snippet', 'snippet_index'], ev);
const dis = cross.filter((c) => !c.agree);
console.info(`people ${covered.size} · lines ${lines.length} · unmapped ${unmapped.length} · cross-checked ${cross.length} · disagree ${dis.length} · official uncited ${log.filter((l) => l[1].startsWith('uncite')).length}`);
for (const c of dis) console.info('DISAGREE', JSON.stringify(c));
for (const u of unmapped) console.info('UNMAPPED', JSON.stringify(u));
process.exit(dis.length ? 1 : 0);
