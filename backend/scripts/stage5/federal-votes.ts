/**
 * federal-votes — cite federal votes from the official roll calls (STAGE5 step 7, federal unit).
 *
 *   npx tsx --env-file=.env scripts/stage5/federal-votes.ts <batch dir> <store findings dir> --topic <key>
 *
 * For every seated row, each vote finding (yea / nay / abstain) on a `US-` instrument whose page the row cites
 * is paired with its roll call in essentials.legislative_votes (read only): the store vote the finding points to
 * (instrument, date and motion, else its one vote that date; tallies from <store>/instruments, the parent of the
 * findings dir) must match exactly one table roll call, and the person is found on it by politician id, never by
 * name. The person's table position is cross-checked against the finding's act (federalVotesPlan.ts). Then:
 *
 *   House:  the Clerk XML (clerk.house.gov/evs/<year>/roll<NNN>.xml, roll number from the table) is fetched once
 *           per roll call through the verifier's own fetch (src/lib/verificationFetch.ts), and the person's line
 *           is cut from it by bioguide id (`name-id`), with no party (src/lib/rollCallEvidence.ts):
 *
 *             House roll call 345 (2024), H R 8281, On Passage: Guthrie (KY) voted Aye.
 *
 *           The XML is cited and its line added to evidence.csv; the page the finding cited is uncited once every
 *           record act of the person on it (any vote or authorship) has a line, none of them is a Senate vote, and
 *           evidence.csv holds no other snippet for it. Each line's vote is cross-checked against the finding's act.
 *   Senate: (115th Congress on) nothing is fetched and LegiScan is not called here. The LegiScan roll-call URL is
 *           built from the table id (`legiscan-<id>`) and written to legiscan/pairs.csv and legiscan/needs.json,
 *           in the shapes legiscan_pairs.py writes. The runner then runs, unchanged:
 *             npx tsx scripts/legiscan-evidence-lines.ts --in <batch>/legiscan/pairs.csv --out <batch>/legiscan/legiscan-evidence.csv
 *             python3 -I scripts/stage5/legiscan_merge.py <batch> --host <official host>
 *           legiscan_merge.py uncites a page once every needs.json entry for it has a LegiScan line; it cannot see
 *           a House vote or an authorship on the same page that has none, or another snippet on it. So needs.json
 *           also carries BLOCKING entries for such a page: url = the page itself, which holds no /rollcall/ and
 *           never gets a line, so the merge keeps the page cited (and neither cites nor cross-checks the entry).
 *           Each such page is printed as WARN too. A cited page that is itself a LegiScan roll call cannot block
 *           that way, so its Senate votes are held and no pair is written for it. legiscan/unmapped.json lists
 *           this run's Senate holds.
 *
 * Held, never guessed (federal/unmapped.json): no single store vote or table roll call, no bioguide id, no table
 * position, a Senate roll call before the 115th Congress, an XML that could not be read or whose bill or roll
 * number is not the matched roll call's, or a member the XML does not list or whose line the format refuses.
 * Hold that person.
 *
 * Writes federal/lines.csv, federal/unmapped.json, federal/crosscheck.json, federal-votes-log.json,
 * legiscan/pairs.csv, legiscan/needs.json and legiscan/unmapped.json; rewrites research.csv and evidence.csv (originals kept as
 * *-pre-federal.csv). Exit 1 when any table position or line disagrees with its finding. Reads the database
 * (DATABASE_URL, read only) and clerk.house.gov; writes nothing to the database.
 */
import { copyFileSync, existsSync, mkdirSync, readFileSync, writeFileSync } from 'node:fs';
import { join } from 'node:path';
import { createVerificationFetchSession } from '../../src/lib/verificationFetch.js';
import { houseRollCallIsFor, houseRollCallLineFor, parseRollCallLine } from '../../src/lib/rollCallEvidence.js';
import { InstrumentSchema, type Instrument, type Vote } from '../lib/sourceStore.js';
import { instrumentBill } from '../lib/federalTableVotes.js';
import { readTableRollCalls } from '../lib/federalTableRead.js';
import { findStoreVote, markActs, pageDecisions, planCitations, voteKey, type NeedsEntry, type PageAct, type SeatedVote, type Unmapped } from './federalVotesPlan.js';
import { readCsv } from './lib.js';

const args = process.argv.slice(2);
const opt = (k: string) => (args.includes(k) ? args[args.indexOf(k) + 1] : undefined);
const [B, F] = args.filter((a, i) => !a.startsWith('--') && !args[i - 1]?.startsWith('--'));
const TOPIC = opt('--topic');
if (!B || !F || !TOPIC) { console.error('usage: federal-votes.ts <batch dir> <store findings dir> --topic <key>'); process.exit(2); }

const csvField = (s: string): string => (/[",\n\r]/.test(s) ? `"${s.replace(/"/g, '""')}"` : s);
const writeCsv = (path: string, cols: string[], rows: Record<string, string>[]) =>
  writeFileSync(path, [cols.join(','), ...rows.map((r) => cols.map((c) => csvField(r[c] ?? '')).join(','))].join('\n') + '\n');
const headerOf = (path: string) => readFileSync(path, 'utf8').split(/\r?\n/, 1)[0].split(',');

for (const f of ['research', 'evidence']) {
  if (!existsSync(join(B, `${f}-pre-federal.csv`))) copyFileSync(join(B, `${f}.csv`), join(B, `${f}-pre-federal.csv`));
}
const rows = readCsv(readFileSync(join(B, 'research-pre-federal.csv'), 'utf8'));
const cols = headerOf(join(B, 'research-pre-federal.csv'));
const evidence = readCsv(readFileSync(join(B, 'evidence-pre-federal.csv'), 'utf8'));
const pol: { full_name: string; politician_id: string }[] = JSON.parse(readFileSync(join(B, 'politicians.json'), 'utf8'));
const pid = new Map(pol.map((p) => [p.full_name, p.politician_id]));
const SUF = new Set(['jr', 'sr', 'ii', 'iii', 'iv']);
const lastOf = (n: string) => n.replace(/,/g, ' ').split(/\s+/).filter((w) => w && !SUF.has(w.toLowerCase().replace(/\.$/, ''))).pop() ?? '';
const urlCols = () => cols.filter((c) => c.startsWith('source_url_'));

const ACTS = new Set(['yea', 'nay', 'abstain']);
const instruments = new Map<string, Instrument | null>();
function instrument(id: string): Instrument | null {
  if (!instruments.has(id)) {
    const file = join(F, '..', 'instruments', 'federal', `${id}.json`);
    instruments.set(id, existsSync(file) ? InstrumentSchema.parse(JSON.parse(readFileSync(file, 'utf8'))) : null);
  }
  return instruments.get(id)!;
}
/** The store roll call a finding points to (findStoreVote: exact motion, else the one vote of that date). */
const storeVote = (f: any): Vote | null =>
  findStoreVote(instrument(String(f.instrument_id))?.votes ?? [], { date: String(f.date ?? ''), motion: String(f.motion ?? ''), note: String(f.note ?? '') });

const unmapped: Unmapped[] = [];
const hold = (u: Unmapped) => { unmapped.push(u); };
/** Every record act of a seated person on a page their row cites; `key` is set for a seated US- vote. */
const onPage: Array<Omit<PageAct, 'lined' | 'senate'> & { key: string | null }> = [];

const seated: SeatedVote[] = [];
let votesFound = 0;
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
    if (f.kind !== 'record' || !cited.includes(u)) continue;
    const base = { politician_id: id, full_name: name, instrument_id: String(f.instrument_id ?? ''), date: String(f.date ?? ''), motion: String(f.motion ?? ''), act: String(f.act ?? ''), cited_url: u };
    const vote = base.instrument_id.startsWith('US-') && ACTS.has(base.act);
    onPage.push({ full_name: name, page: u, act: base.act, instrument_id: base.instrument_id, key: vote ? voteKey(base) : null });
    if (!vote) continue;
    votesFound++;
    const v = storeVote(f);
    if (!v) { hold({ ...base, reason: 'no single store roll call for this finding (instrument, date, motion; or the one vote of that date)' }); continue; }
    seated.push({ ...base, last_name: lastOf(name), bioguide: null, topic_key: TOPIC, yes: v.yes, no: v.no });
  }
}

// Read only: bioguide ids, then the seated people's federal roll calls on the seated bills.
const ids = [...new Set(seated.map((s) => s.politician_id))];
const bills = [...new Map(seated.map((s) => instrumentBill(s.instrument_id)).filter((b) => b !== null).map((b) => [`${b.congress}|${b.bill_number}`, b])).values()];
let rolls: Awaited<ReturnType<typeof readTableRollCalls>> = [];
if (ids.length) {
  const { pool } = await import('../../src/lib/db.js');
  try {
    const bioguide = new Map<string, string>();
    const client = await pool.connect();
    try {
      await client.query('BEGIN READ ONLY');
      try {
        await client.query("SET LOCAL statement_timeout = '20s'");
        const res = await client.query(
          'SELECT id::text AS id, bioguide_id FROM essentials.politicians WHERE id = ANY($1::uuid[]) AND bioguide_id IS NOT NULL',
          [ids],
        );
        for (const x of res.rows) bioguide.set(x.id, x.bioguide_id);
      } finally {
        await client.query('ROLLBACK');
      }
    } finally {
      client.release();
    }
    for (const s of seated) s.bioguide = bioguide.get(s.politician_id) ?? null;
    const withId = ids.filter((i) => bioguide.has(i));
    // The table is read only for these seated people (it is indexed on politician_id alone). So a twin roll call
    // (same bill, date and totals within one) that none of them voted on is never read, and matchRollCall cannot
    // see the tie. The risk is low: a twin needs two recorded votes on one bill on one day with near-equal
    // totals, and a member recorded on one roll call of a day is almost always recorded on the other (the table
    // keeps not-voting rows too), so any one seated person on the twin brings it in and the match refuses both.
    if (withId.length && bills.length) rolls = await readTableRollCalls(pool, withId, bills);
  } finally {
    await pool.end();
  }
}

const plan = planCitations(seated, rolls);
for (const u of plan.unmapped) hold(u);

// House: one fetch per roll call; the line chosen by bioguide id.
const session = createVerificationFetchSession();
const xmls = new Map<string, string | null>();
const LINE_ACT: Record<string, string | null> = { Yea: 'yea', Aye: 'yea', Nay: 'nay', No: 'nay', Present: 'abstain', 'Not Voting': null };
const lines: Record<string, string>[] = [];
const lined = new Set<string>();
const xmlCross: Record<string, unknown>[] = [];
for (const h of plan.house) {
  if (!xmls.has(h.url)) xmls.set(h.url, await session.fetch(h.url).catch(() => null));
  const xml = xmls.get(h.url);
  const held = { politician_id: h.politician_id, full_name: h.full_name, instrument_id: h.instrument_id, date: h.date, motion: h.motion, act: h.act, cited_url: h.cited_url };
  if (!xml) { hold({ ...held, reason: `house xml: could not read ${h.url}` }); continue; }
  if (!houseRollCallIsFor(xml, h.bill_number, h.rc)) { hold({ ...held, reason: 'house xml: bill or roll number differs from the matched roll call' }); continue; }
  const line = houseRollCallLineFor(xml, h.url, h.bioguide!);
  if (!line) { hold({ ...held, reason: 'house line: member not on the roll call or line format refused' }); continue; }
  const got = parseRollCallLine(line)!.vote;
  const agree = LINE_ACT[got] === h.act;
  xmlCross.push({ name: h.full_name, official: h.cited_url, xml: h.url, line_vote: got, finding_act: h.act, agree });
  if (!agree) continue;
  lined.add(voteKey(h));
  if (!lines.some((l) => l.full_name === h.full_name && l.source_url === h.url)) lines.push({ full_name: h.full_name, topic_key: TOPIC, source_url: h.url, snippet: line });
}
await session.close();

// Senate: pairs for legiscan-evidence-lines.ts and needs for legiscan_merge.py, as legiscan_pairs.py writes them.
// Marks are positive: senate only for a vote that became a pair; anything held, at any stage, stays open.
const acts: PageAct[] = markActs(onPage, lined, new Set(plan.senateVotes.map(voteKey)));
const snippets = new Set(evidence.map((e) => `${e.full_name}\u0000${e.source_url}`));
const decided = pageDecisions(acts, snippets);
// A cited LegiScan roll-call page cannot carry a blocking entry: hold its Senate votes and write no pair for it.
const heldPage = new Map(decided.hold.map((h) => [`${h.full_name}\u0000${h.page}`, h.why]));
for (const v of plan.senateVotes) {
  const why = heldPage.get(`${v.full_name}\u0000${v.cited_url}`);
  if (why) hold({ politician_id: v.politician_id, full_name: v.full_name, instrument_id: v.instrument_id, date: v.date, motion: v.motion, act: v.act, cited_url: v.cited_url, reason: `senate: ${why}` });
}
const senate = plan.senate.filter((p) => !heldPage.has(`${p.full_name}\u0000${p.official}`));
const needs: Record<string, NeedsEntry[]> = {};
const need = (name: string, n: NeedsEntry) => {
  const list = (needs[name] ??= []);
  if (!list.some((x) => JSON.stringify(x) === JSON.stringify(n))) list.push(n);
};
for (const p of senate) need(p.full_name, { url: p.source_url, official: p.official, act: p.act, instrument: p.instrument_id });
for (const b of decided.blocking) need(b.full_name, b.entry);
const senateHolds = unmapped.filter((u) => u.reason.startsWith('senate')).map((u) => [u.full_name, u.cited_url, u.instrument_id, u.reason]);
const pairs = [...new Map(senate.map((p) => [`${p.full_name}\u0000${p.source_url}`, p])).values()]
  .map((p) => ({ full_name: p.full_name, last_name: p.last_name, topic_key: p.topic_key, source_url: p.source_url }));

// Merge: cite the XML, uncite a fully covered page with no Senate vote and no other snippet, re-index evidence.
const log: string[][] = [];
const uncite = new Set(decided.uncite.map((d) => `${d.full_name}\u0000${d.page}`));
const people = new Set(onPage.map((a) => a.full_name));
const lineKeys = new Set(lines.map((l) => `${l.full_name}\u0000${l.source_url}`));
for (const r of rows) {
  if (!people.has(r.full_name)) continue;
  let urls = urlCols().map((c) => r[c]).filter(Boolean);
  for (const l of lines.filter((x) => x.full_name === r.full_name)) {
    if (!urls.includes(l.source_url)) { urls.push(l.source_url); log.push([r.full_name, 'cite roll-call XML', l.source_url]); }
  }
  for (const off of [...urls]) {
    if (uncite.has(`${r.full_name}\u0000${off}`)) { urls = urls.filter((x) => x !== off); log.push([r.full_name, 'uncite (every act on it has a roll-call line)', off]); }
  }
  while (urls.length > urlCols().length) cols.push(`source_url_${urlCols().length + 1}`);
  urlCols().forEach((c, i) => { r[c] = urls[i] ?? ''; });
}
const cited = new Set(rows.flatMap((r) => urlCols().map((c) => `${r.full_name}\u0000${r[c]}`)));
const ev = [
  // An XML's old snippets are replaced by its line.
  ...evidence.filter((e) => cited.has(`${e.full_name}\u0000${e.source_url}`) && !lineKeys.has(`${e.full_name}\u0000${e.source_url}`)),
  ...lines.filter((l) => cited.has(`${l.full_name}\u0000${l.source_url}`)),
];
const idx = new Map<string, number>();
for (const e of ev) { const k = `${e.full_name}\u0000${e.topic_key}`; idx.set(k, (idx.get(k) ?? 0) + 1); e.snippet_index = String(idx.get(k)); }

const crosscheck = {
  table: plan.crosscheck,
  house_xml: { agree: xmlCross.filter((c) => c.agree).length, disagree: xmlCross.filter((c) => !c.agree) },
};
mkdirSync(join(B, 'federal'), { recursive: true });
mkdirSync(join(B, 'legiscan'), { recursive: true });
writeCsv(join(B, 'federal', 'lines.csv'), ['full_name', 'topic_key', 'source_url', 'snippet'], lines);
writeFileSync(join(B, 'federal', 'unmapped.json'), JSON.stringify(unmapped, null, 1));
writeFileSync(join(B, 'federal', 'crosscheck.json'), JSON.stringify(crosscheck, null, 1));
writeFileSync(join(B, 'federal-votes-log.json'), JSON.stringify(log, null, 1));
writeCsv(join(B, 'legiscan', 'pairs.csv'), ['full_name', 'last_name', 'topic_key', 'source_url'], pairs);
writeFileSync(join(B, 'legiscan', 'needs.json'), JSON.stringify(needs, null, 1));
writeFileSync(join(B, 'legiscan', 'unmapped.json'), JSON.stringify(senateHolds, null, 1));
writeCsv(join(B, 'research.csv'), cols, rows);
writeCsv(join(B, 'evidence.csv'), ['full_name', 'topic_key', 'source_url', 'snippet', 'snippet_index'], ev);

const dis = plan.crosscheck.disagree.length + crosscheck.house_xml.disagree.length;
console.info(`people ${people.size} · seated votes ${votesFound} · table roll calls ${rolls.length} · house lines ${lines.length} · senate pairs ${pairs.length} · unmapped ${unmapped.length} · table agree ${plan.crosscheck.agree} · disagree ${dis} · official uncited ${log.filter((l) => l[1].startsWith('uncite')).length}`);
for (const d of plan.crosscheck.disagree) console.info('DISAGREE', JSON.stringify(d));
for (const d of crosscheck.house_xml.disagree) console.info('DISAGREE', JSON.stringify(d));
for (const w of decided.warn) console.info(`WARN ${w.full_name}: ${w.why}, so needs.json blocks legiscan_merge.py from uncite: ${w.page}`);
if (pairs.length) console.info(`senate: ${pairs.length} pairs in legiscan/pairs.csv; next, legiscan-evidence-lines.ts then legiscan_merge.py`);
process.exit(dis ? 1 : 0);
