#!/usr/bin/env node
/**
 * federal-pass-triage.mjs — how much of the research pass this leads file can actually settle.
 *
 * Joins the committed sponsorship leads to the worksheet's OWED rows and sorts every
 * (politician, topic) pair by whether the evidence in hand is on the axis its ladder
 * measures. Emits the settleable ones as a ready-to-fill worksheet.
 *
 *   triage.csv      every owed pair, its verdict, and its best on-axis lead
 *   settleable.csv  the subset with on-axis evidence, in the 8 columns
 *                   verify-reresearch-rows.mjs expects, values left EMPTY
 *   unsettleable.md the rest, grouped by why, so the gap is a worklist and not a silence
 *
 * ⚠ IT TAKES THE OWED SET AS A FILE AND DOES NOT RE-DERIVE IT. cohort-worksheet.mjs
 * already computes "owed" and carries the two corrections that were expensive to
 * learn — the ladder comes from the SEASON'S PINNED REVISION, and owed means "no
 * answer in ANY published season", which is the difference between 1,316 real rows
 * and a 3,240-row phantom. A second copy of that query here would be a third place
 * for those to drift, which is the defect office-tiers.mjs exists to prevent.
 *
 * 🔴 A VERDICT IS NOT A CHAIR, AND settleable IS NOT AN ANSWER. Every row in
 * settleable.csv still needs a person to open the bill, choose the rung and cite a
 * page whose raw HTML carries the claim. This narrows the queue; it does not work it.
 *
 * RUN:
 *   node scripts/cohort-worksheet.mjs --tier=federal --cohort=senate --topics=all out/
 *   node scripts/federal-pass-triage.mjs \
 *     --leads=data/federal-pass/2026-09-05-senate-leads.csv \
 *     --owed=out/rows.csv \
 *     --topics=gun-policy,israel-military-aid,border-security  out/
 *
 * Needs no database and no API key — both inputs are files, so this is reproducible
 * from the repo alone.
 */
import { readFileSync, writeFileSync, mkdirSync } from 'fs';
import path from 'node:path';
import { classifyLead, classifyPair } from './lib/lead-axis.mjs';

const args = process.argv.slice(2);
const outdir = args.find((a) => !a.startsWith('--'));
const flag = (name) => {
  const hit = args.find((a) => a.startsWith(`--${name}=`));
  return hit ? hit.slice(name.length + 3) : null;
};
const leadsPath = flag('leads');
const owedPath = flag('owed');
const topicFilter = flag('topics') ? flag('topics').split(',').map((s) => s.trim()).filter(Boolean) : null;

if (!outdir || !leadsPath || !owedPath) {
  console.error('usage: node scripts/federal-pass-triage.mjs --leads=<leads.csv> --owed=<rows.csv> [--topics=a,b,c] <outdir>');
  process.exit(1);
}

/** Same parser the verifier uses, and for the same reason: bill titles carry commas and quotes. */
function parseCsv(text) {
  const rows = [];
  let row = [], field = '', inQ = false;
  for (let i = 0; i < text.length; i++) {
    const c = text[i];
    if (inQ) {
      if (c === '"' && text[i + 1] === '"') { field += '"'; i++; }
      else if (c === '"') inQ = false;
      else field += c;
    } else if (c === '"') inQ = true;
    else if (c === ',') { row.push(field); field = ''; }
    else if (c === '\n') { row.push(field); if (row.some((f) => f.trim())) rows.push(row); row = []; field = ''; }
    else if (c !== '\r') field += c;
  }
  row.push(field);
  if (row.some((f) => f.trim())) rows.push(row);
  return rows;
}

function readTable(p) {
  const rows = parseCsv(readFileSync(p, 'utf8'));
  const header = rows.shift();
  return rows.map((r) => Object.fromEntries(header.map((h, i) => [h, r[i] ?? ''])));
}

const esc = (v) => {
  const s = String(v ?? '');
  return /[",\n]/.test(s) ? `"${s.replace(/"/g, '""')}"` : s;
};

// ── Inputs ───────────────────────────────────────────────────────────────────
const leadRows = readTable(leadsPath);
const owedRows = readTable(owedPath).filter((r) => !topicFilter || topicFilter.includes(r.topic_key));

// A member with no hits is written as a sentinel row carrying no topic, so that
// --resume does not re-sweep them. It is not a lead and must not be counted as one.
const leads = leadRows.filter((r) => r.topic_key);
const sentinels = leadRows.length - leads.length;

/** politician_id|topic_key → its leads. */
const byPair = new Map();
for (const l of leads) {
  if (topicFilter && !topicFilter.includes(l.topic_key)) continue;
  const key = `${l.politician_id}|${l.topic_key}`;
  if (!byPair.has(key)) byPair.set(key, []);
  byPair.get(key).push(l);
}

// ── Triage ───────────────────────────────────────────────────────────────────
const triaged = owedRows.map((row) => {
  const mine = byPair.get(`${row.politician_id}|${row.topic_key}`) ?? [];
  if (!mine.length) {
    return { row, verdict: 'no-lead', counts: { 'on-axis': 0, 'off-axis': 0, 'non-operative': 0 }, best: null };
  }
  const { verdict, counts } = classifyPair(mine);
  // The best lead to open first: an on-axis one the member SPONSORED outranks one
  // they cosponsored, because a sponsor chose the text and a cosponsor signed it.
  const onAxis = mine.filter((l) => classifyLead(l) === 'on-axis');
  const best = onAxis.sort((a, b) =>
    (a.role === 'sponsor' ? 0 : 1) - (b.role === 'sponsor' ? 0 : 1)
    || String(b.introduced).localeCompare(String(a.introduced)))[0] ?? null;
  return { row, verdict, counts, best };
});

// ── Output ───────────────────────────────────────────────────────────────────
mkdirSync(outdir, { recursive: true });

const TRIAGE_COLS = ['politician_id', 'full_name', 'topic_key', 'verdict', 'on_axis', 'off_axis', 'non_operative', 'best_role', 'best_bill', 'best_introduced', 'best_title'];
const triageCsv = [TRIAGE_COLS.join(',')];
for (const t of triaged) {
  triageCsv.push([
    t.row.politician_id, t.row.full_name, t.row.topic_key, t.verdict,
    t.counts['on-axis'], t.counts['off-axis'], t.counts['non-operative'],
    t.best?.role ?? '', t.best?.bill ?? '', t.best?.introduced ?? '', t.best?.title ?? '',
  ].map(esc).join(','));
}
writeFileSync(path.join(outdir, 'triage.csv'), `${triageCsv.join('\n')}\n`, 'utf8');

// The settleable subset, in the worksheet's own shape so it drops straight into the
// verifier without a reformatting step in between.
const WORKSHEET_COLS = ['politician_id', 'full_name', 'topic_key', 'value', 'reasoning', 'source_url_1', 'source_url_2', 'source_url_3'];
const settleable = triaged.filter((t) => t.verdict === 'settleable');
const settleCsv = [WORKSHEET_COLS.join(',')];
for (const t of settleable) {
  settleCsv.push([t.row.politician_id, t.row.full_name, t.row.topic_key, '', '', '', '', ''].map(esc).join(','));
}
writeFileSync(path.join(outdir, 'settleable.csv'), `${settleCsv.join('\n')}\n`, 'utf8');

const REASON = {
  'off-axis-only': 'Operative bills, none on this ladder\'s axis. Needs a different instrument — a roll-call vote, a floor statement or an issues page.',
  'non-operative-only': 'Only commemorative or condemnatory resolutions, which make no law and cannot separate the rungs.',
  'no-lead': 'No sponsorship lead at all in this sweep. Silence is not a position; it needs another instrument.',
};
const md = ['# Unsettleable from this leads file', ''];
md.push('Every pair below is still OWED an answer. None of them can be settled from bill');
md.push('sponsorship as swept on 2026-09-05, and each needs a different instrument.', '');
for (const verdict of ['off-axis-only', 'non-operative-only', 'no-lead']) {
  const group = triaged.filter((t) => t.verdict === verdict);
  if (!group.length) continue;
  md.push(`## ${verdict} — ${group.length} pair(s)`, '', REASON[verdict], '');
  for (const t of group.sort((a, b) => a.row.topic_key.localeCompare(b.row.topic_key) || a.row.full_name.localeCompare(b.row.full_name))) {
    md.push(`- \`${t.row.topic_key}\` **${t.row.full_name}** — ${t.counts['off-axis']} off-axis, ${t.counts['non-operative']} non-operative`);
  }
  md.push('');
}
writeFileSync(path.join(outdir, 'unsettleable.md'), `${md.join('\n')}\n`, 'utf8');

// ── Summary ──────────────────────────────────────────────────────────────────
const topics = [...new Set(triaged.map((t) => t.row.topic_key))].sort();
const pad = (s, n) => String(s).padEnd(n);
console.log(`\nfederal-pass-triage — ${triaged.length} owed pair(s) over ${topics.length} topic(s)`);
console.log(`  leads read: ${leads.length}${sentinels ? ` (+${sentinels} no-hit sentinel row(s), not leads)` : ''}\n`);
console.log(`  ${pad('topic', 24)} ${'owed'.padStart(5)} ${'settleable'.padStart(11)} ${'off-axis'.padStart(9)} ${'non-op'.padStart(7)} ${'no lead'.padStart(8)}`);
for (const topic of topics) {
  const g = triaged.filter((t) => t.row.topic_key === topic);
  const n = (v) => String(g.filter((t) => t.verdict === v).length).padStart(v === 'settleable' ? 11 : v === 'off-axis-only' ? 9 : v === 'non-operative-only' ? 7 : 8);
  console.log(`  ${pad(topic, 24)} ${String(g.length).padStart(5)} ${n('settleable')} ${n('off-axis-only')} ${n('non-operative-only')} ${n('no-lead')}`);
}
const tot = (v) => triaged.filter((t) => t.verdict === v).length;
console.log(`  ${pad('TOTAL', 24)} ${String(triaged.length).padStart(5)} ${String(tot('settleable')).padStart(11)} ${String(tot('off-axis-only')).padStart(9)} ${String(tot('non-operative-only')).padStart(7)} ${String(tot('no-lead')).padStart(8)}`);
console.log(`\n  → ${path.join(outdir, 'triage.csv')}`);
console.log(`  → ${path.join(outdir, 'settleable.csv')}   ${settleable.length} row(s) to research`);
console.log(`  → ${path.join(outdir, 'unsettleable.md')}  ${triaged.length - settleable.length} row(s) needing another instrument`);
console.log('\n🔴 settleable means the lead is worth OPENING, never that a chair is decided.');
console.log('   Fill value / reasoning / source_url_* by hand, then run verify-reresearch-rows.mjs.');
