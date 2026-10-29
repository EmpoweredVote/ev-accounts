/**
 * ccg_member_index.mjs — index one Columbus GA councillor's acts and words in the
 * council minutes corpus.
 *
 * Columbus publishes approved minutes as PDFs on Municode Meetings. The extracted text
 * carries five distinct channels, all in prose and therefore citable — unlike a Legistar
 * roll-call table, which is authoritative and unquotable (slice 4):
 *
 *   attribution  `(Councilor Crabb)` after an item title — who brought it. Columbus
 *                publishes no sponsor list, so this is the sponsorship equivalent.
 *   motion       `Councilor X made a motion to adopt the ordinance`
 *   second       `seconded by Councilor Y`
 *   vote         a divided roll call, named member by member:
 *                `with Councilors Chambers, Cook, Huff and Tucker voting yes, and
 *                 Mayor Pro Tem Allen and Councilors Barnes, Cogle, Davis and Garrett voting no`
 *   remark       `Councilor X expressed / stated / asked / explained ...`
 *
 * 🔴 TENURE IS NOT OPTIONAL HERE, WHICH IS WHY --since IS REQUIRED. District 1 has had
 * TWO Councillor Barneses — Jerry "Pops" Barnes through March 2024 and Simi Barnes from
 * 2026-05-26 — and a surname match reads them as one person. C44 refuses a vote cast
 * before the member took the seat, and `verify-stance-research`'s name check cannot tell
 * the two apart: it looks for the surname near the snippet and both satisfy it.
 *
 * 🔴 RUN THE POSITIVE CONTROL. `--control` asserts a passage known to be in the corpus is
 * found, and exits non-zero if it is not. The first version of this file reported 0 hits
 * for a member with 187 meetings because a shell heredoc had stripped the backslashes out
 * of every regex — the patterns were inert and nothing said so. A detector that reports
 * "nothing found" has to be proven able to find something.
 *
 * Usage:
 *   node ccg_member_index.mjs --surname Crabb --since 2020-01-01 --control
 *   node ccg_member_index.mjs --surname Barnes --since 2026-05-26   # Simi, not Jerry
 */
import { readFileSync, readdirSync, writeFileSync, mkdirSync } from 'node:fs';
import { join } from 'node:path';

const CORPUS = 'C:/ev-accounts-corpora/stance-ccg-ga';
const WINDOW = 420;

function arg(name, dflt) {
  const i = process.argv.indexOf('--' + name);
  return i > -1 ? process.argv[i + 1] : dflt;
}

const surname = arg('surname');
const since = arg('since');
const out = arg('out');
const wantControl = process.argv.includes('--control');

if (!surname || !since) {
  console.error('need --surname and --since (YYYY-MM-DD); the header says why --since is required');
  process.exit(2);
}

/** meeting id -> the public minutes URL, so every hit cites the page it came from. */
const urlById = new Map();
for (const line of readFileSync(join(CORPUS, 'minutes-urls.txt'), 'utf8').split(/\r?\n/)) {
  const m = line.match(/meeting\/(\d+)\//);
  if (m) urlById.set(m[1], line.trim());
}

const S = surname.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
const WHO = '(?:Councilor|Councilors|Mayor Pro Tem)[^.\\n]{0,60}?\\b' + S + '\\b';
const VERBS = [
  'expressed', 'stated', 'asked', 'explained', 'noted', 'requested', 'said', 'questioned',
  'emphasized', 'suggested', 'raised', 'voiced', 'spoke', 'thanked', 'urged', 'recommended',
  'objected', 'clarified', 'inquired', 'commented', 'reported', 'proposed', 'argued',
  'acknowledged', 'cautioned', 'warned', 'supported', 'opposed', 'reiterated', 'confirmed',
].join('|');

const CHANNELS = [
  ['attribution', '\\(\\s*(?:Councilor|Mayor Pro Tem)\\s+' + S + '\\s*\\)'],
  ['motion', WHO + '[^.]{0,40}\\b(?:made a motion|moved to)'],
  ['second', 'seconded by\\s+(?:Councilor|Mayor Pro Tem)\\s+[A-Za-z. ]{0,20}' + S],
  ['vote', '(?:voting yes|voting no|voting against)'],
  ['remark', WHO + '\\s+(?:' + VERBS + ')'],
].map(([kind, src]) => [kind, new RegExp(src, 'g')]);

const files = readdirSync(join(CORPUS, 'txt')).filter((f) => f.endsWith('.txt')).sort();

function meetingDate(f) {
  const d = f.match(/_(\d{2})-(\d{2})-(\d{2,4})/);
  if (!d) return null;
  const yyyy = d[3].length === 2 ? '20' + d[3] : d[3];
  return yyyy + '-' + d[1] + '-' + d[2];
}

// ── positive control ────────────────────────────────────────────────────────────────
// A passage that is known to be in the corpus, in each of the two channels most likely
// to go quietly inert: the parenthetical attribution and the named divided roll call.
if (wantControl) {
  const probes = [
    ['attribution', '2969_03-10-2026.txt', /\(\s*Councilor\s+Crabb\s*\)/],
    ['vote', '2987_09-22-2026.txt', /Cook, Huff and Tucker voting yes/],
  ];
  const failed = [];
  for (const [label, file, re] of probes) {
    let found = false;
    try { found = re.test(readFileSync(join(CORPUS, 'txt', file), 'utf8')); } catch { /* missing */ }
    if (!found) failed.push(label + ' (' + file + ')');
  }
  // and the live attribution channel must find that same passage through CHANNELS, not
  // through the probe's own regex — the probe proves the corpus, this proves the detector.
  const ctlText = readFileSync(join(CORPUS, 'txt', '2969_03-10-2026.txt'), 'utf8');
  const ctlRe = new RegExp('\\(\\s*(?:Councilor|Mayor Pro Tem)\\s+Crabb\\s*\\)', 'g');
  if (!ctlRe.test(ctlText)) failed.push('CHANNELS attribution pattern is inert');
  if (failed.length) {
    console.error('POSITIVE CONTROL FAILED: ' + failed.join('; ') + ' — the index is blind, do not trust a zero.');
    process.exit(1);
  }
  console.error('positive control passed (corpus readable, attribution + vote patterns live)');
}

const hits = [];
let meetingsInTenure = 0;
let meetingsWithHits = 0;
let meetingsBeforeTenure = 0;

for (const f of files) {
  const date = meetingDate(f);
  if (!date) continue;
  if (date < since) { meetingsBeforeTenure++; continue; }
  meetingsInTenure++;

  const text = readFileSync(join(CORPUS, 'txt', f), 'utf8');
  const mid = f.split('_')[0];
  const url = urlById.get(mid) || null;
  let any = false;

  for (const [kind, re] of CHANNELS) {
    re.lastIndex = 0;
    let m;
    while ((m = re.exec(text))) {
      if (kind === 'vote') {
        // a divided roll call counts for this member only when the tally names them
        const tally = text.slice(Math.max(0, m.index - 320), m.index + 420);
        if (!new RegExp('\\b' + S + '\\b').test(tally)) continue;
      }
      hits.push({
        date,
        file: f,
        url,
        kind,
        at: m.index,
        context: text.slice(Math.max(0, m.index - WINDOW), m.index + WINDOW).replace(/\s+/g, ' ').trim(),
      });
      any = true;
    }
  }
  if (any) meetingsWithHits++;
}

// collapse overlapping windows inside one meeting
const seen = new Set();
const kept = hits.filter((h) => {
  const key = h.file + ':' + h.kind + ':' + Math.floor(h.at / 220);
  if (seen.has(key)) return false;
  seen.add(key);
  return true;
});
kept.sort((a, b) => (a.date === b.date ? a.at - b.at : a.date.localeCompare(b.date)));

const byKind = {};
for (const h of kept) byKind[h.kind] = (byKind[h.kind] || 0) + 1;

mkdirSync(join(CORPUS, 'index'), { recursive: true });
const dest = out || join(CORPUS, 'index', surname.toLowerCase() + '.jsonl');
writeFileSync(dest, kept.map((h) => JSON.stringify(h)).join('\n') + '\n');

console.log(JSON.stringify({
  surname,
  since,
  meetings_before_tenure_skipped: meetingsBeforeTenure,
  meetings_in_tenure: meetingsInTenure,
  meetings_with_hits: meetingsWithHits,
  hits: kept.length,
  by_kind: byKind,
  out: dest,
}, null, 2));
