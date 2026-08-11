#!/usr/bin/env node
/**
 * PASS 4 (Maryland single-source queue) -- NAMED-INSTRUMENT RESOLUTION.
 *
 * Passes 1-3 tested TOPIC VOCABULARY. This tests something sharper and different: many rows name a
 * SPECIFIC instrument ("Climate Solutions Now Act", "SB0528", "Blueprint for Maryland's Future").
 * The cited mgaleg member page carries only ONE session, so it can never confirm those -- but the
 * MGA session indexes can, exactly.
 *
 * 🔴 THIS PROPOSES NOTHING AND WRITES NOTHING TO THE DB. It emits a worklist for a human.
 * 🔴 COVERAGE BOUND: corpus is 2013RS-2026RS. 2012 and earlier parse to ZERO rows, so a miss on a
 *    pre-2013 instrument (e.g. the 2012 marriage referendum) is UNKNOWN, never absent.
 *
 *   node scripts/md-pass4-instrument-worklist.mjs --corpus <corpus.json> --out <worklist.json>
 */
import fs from 'node:fs';
import pg from 'pg';

const argv = process.argv.slice(2);
const flag = (n, d = null) => { const i = argv.indexOf(n); return i > -1 ? argv[i + 1] : d; };
const corpusPath = flag('--corpus');
const outPath = flag('--out');
if (!corpusPath || !outPath) { console.error('need --corpus and --out'); process.exit(2); }

const env = fs.readFileSync('C:/EV-Accounts/backend/.env', 'utf8');
const url = env.split(/\r?\n/).find((l) => /^DATABASE_URL=/.test(l)).replace(/^DATABASE_URL=/, '').trim();

const { bills } = JSON.parse(fs.readFileSync(corpusPath, 'utf8'));
const norm = (s) => s.toLowerCase().replace(/[‘’']/g, '').replace(/[^a-z0-9 ]+/g, ' ')
  .replace(/\bmarylands?\b/g, ' ').replace(/\bof \d{4}\b/g, ' ').replace(/\s+/g, ' ').trim();
const idx = bills.map((b) => ({ ...b, n: norm(b.title) }));

function lookupAct(act) {
  const a = norm(act);
  if (a.length < 6) return { verdict: 'TOO_SHORT', hits: [] };
  let hits = idx.filter((b) => b.n.includes(a));
  let verdict = hits.length ? 'FOUND' : null;
  if (!hits.length) {
    const toks = a.split(' ').filter((t) => t.length > 2);
    if (toks.length >= 2) { hits = idx.filter((b) => toks.every((t) => b.n.includes(t))); if (hits.length) verdict = 'FOUND_LOOSE'; }
  }
  if (!verdict) verdict = 'NOT_IN_CORPUS';
  const uniq = [...new Map(hits.map((h) => [h.number + h.session, h])).values()];
  return { verdict, hits: uniq.slice(0, 6) };
}

/**
 * Pull named instruments out of voter-facing reasoning. Deliberately generous; a human reads the output.
 *
 * ⚠ Two extractor bugs found by reading the first cut's 15 "unresolved" rows -- BOTH manufactured
 * fake defects, none of which were real:
 *  1. A leading verb rode along ("Sponsored ICE Breaker Act", "AND ICE Breaker Act"), so nothing matched.
 *  2. Requiring every word to be capitalised truncated names containing lowercase connectors:
 *     "Fair Districts for Maryland Act" collapsed to the useless stub "Maryland Act".
 * Never report an extractor artifact as a finding -- fix the extractor and re-measure.
 */
// ⚠ Round 2: stripping leading VERBS let leading CONNECTORS and vote words ride along instead
// ("for the Climate Solutions Now Act", "YES on the Abortion Care Access Act") -- the same real acts
// wearing new junk. Strip anything that cannot begin a statute's name.
const LEAD_NOISE = new Set(['sponsored', 'cosponsored', 'co', 'supported', 'backed', 'championed',
  'introduced', 'passed', 'voted', 'vote', 'votes', 'and', 'both', 'the', 'also', 'a', 'an',
  'his', 'her', 'their', 'yes', 'no', 'for', 'of', 'from', 'with', 'in', 'on', 'to', 'against']);
const CONNECTORS = 'for|from|of|the|and|in|to|on|with';

function extractInstruments(text) {
  const out = new Set();
  for (const m of text.matchAll(/\b([SH]B)\s*0*(\d{1,4})\b/gi)) out.add(`${m[1].toUpperCase()}${m[2].padStart(4, '0')}`);

  const word = `(?:[A-Z][A-Za-z’'()]+|${CONNECTORS})`;
  const re = new RegExp(`\\b(${word}(?:\\s+${word}){0,8}\\s+Act)\\b`, 'g');
  for (const m of text.matchAll(re)) {
    let toks = m[1].split(/\s+/);
    while (toks.length > 1 && LEAD_NOISE.has(toks[0].toLowerCase().replace(/[^a-z]/g, ''))) toks.shift();
    // A name that is now just a connector + "Act" carries no signal.
    const name = toks.join(' ');
    if (toks.length >= 2 && !new RegExp(`^(?:${CONNECTORS})\\s+Act$`, 'i').test(name)) out.add(name);
  }
  if (/blueprint for maryland/i.test(text)) out.add("Blueprint for Maryland's Future");
  return [...out];
}

const pool = new pg.Pool({ connectionString: url, ssl: { rejectUnauthorized: false } });
const { rows } = await pool.query(`
  WITH agg AS (
    SELECT c.politician_id, count(*) AS rows_ct,
           count(DISTINCT c.sources::text) AS distinct_srcs, min(c.sources::text) AS the_src
    FROM inform.politician_context c GROUP BY c.politician_id
  ), cohort AS (
    SELECT politician_id FROM agg
    WHERE distinct_srcs = 1 AND rows_ct >= 5 AND the_src ILIKE '%mgaleg%'
  )
  SELECT p.full_name, c.politician_id, c.topic_id, t.title AS topic, a.value, c.reasoning, c.sources
  FROM inform.politician_context c
  JOIN cohort co ON co.politician_id = c.politician_id
  JOIN essentials.politicians p ON p.id = c.politician_id
  LEFT JOIN inform.compass_topics t ON t.id = c.topic_id
  LEFT JOIN inform.politician_answers a ON a.politician_id = c.politician_id AND a.topic_id = c.topic_id
  ORDER BY p.full_name, t.title`);
await pool.end();

const work = rows.map((r) => {
  const instruments = extractInstruments(r.reasoning || '');
  const resolved = instruments.map((i) => {
    if (/^[SH]B\d{4}$/.test(i)) {
      const hits = [...new Map(idx.filter((b) => b.number.toUpperCase() === i).map((h) => [h.number + h.session, h])).values()];
      return { instrument: i, kind: 'bill_number', verdict: hits.length ? 'FOUND' : 'NOT_IN_CORPUS', hits: hits.slice(0, 6) };
    }
    return { instrument: i, kind: 'act_name', ...lookupAct(i) };
  });
  return {
    politician: r.full_name, politician_id: r.politician_id, topic: r.topic, topic_id: r.topic_id,
    value: r.value, sources: r.sources, reasoning: r.reasoning,
    instruments: resolved,
    has_instrument: resolved.length > 0,
    all_resolved: resolved.length > 0 && resolved.every((x) => x.verdict === 'FOUND' || x.verdict === 'FOUND_LOOSE'),
  };
});

const withInst = work.filter((w) => w.has_instrument);
const tally = {
  total_rows: work.length,
  rows_naming_an_instrument: withInst.length,
  rows_no_instrument: work.length - withInst.length,
  rows_all_instruments_resolved: withInst.filter((w) => w.all_resolved).length,
  rows_with_an_unresolved_instrument: withInst.filter((w) => !w.all_resolved).length,
};
fs.writeFileSync(outPath, JSON.stringify({
  pass: 'MD pass 4 - named instrument resolution',
  caveat: 'Corpus 2013RS-2026RS. A miss on a pre-2013 instrument is UNKNOWN, not absent. Nothing here is a delete list.',
  tally, rows: work,
}, null, 1));
console.log(JSON.stringify(tally, null, 2));
