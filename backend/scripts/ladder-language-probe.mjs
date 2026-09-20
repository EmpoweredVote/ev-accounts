#!/usr/bin/env node
/**
 * SCALE PROBE: does the rung text a row quotes actually exist on the topic it is filed under?
 *
 * This is the detector that would have caught the LD 427 misfile in one pass: 82 Residential Zoning
 * rows were quoting Transportation Priorities rung text.
 *
 * Method — no guessing at writing convention:
 *   1. Collect every rung text across every topic revision.
 *   2. Cut them into word n-grams. Keep only n-grams that belong to EXACTLY ONE topic — those are
 *      discriminating: seeing one is evidence about which ladder the author was reading.
 *   3. For each context row, find discriminating n-grams in its reasoning. Any that belong to a
 *      topic OTHER than the row's own topic is a borrowed-ladder hit.
 *
 * Reads only. Emits a ranked worklist; first cuts over-fire, so this is a READING QUEUE.
 *
 * Complements scripts/instrument-topic-affinity.mjs: this one's ground truth is LADDER TEXT, written
 * independently of the corpus, so it can find a large uniform misfile that a corpus-consensus
 * detector cannot. That is how the 82-row LD 427 misfile (migration 1882) was found.
 */
import fs from 'node:fs';
import pg from 'pg';

const OUT = process.argv[2];
const NGRAM_MIN = 5;          // shorter phrases are generic policy English, not ladder text
const NGRAM_MAX = 8;

const env = fs.readFileSync('C:/EV-Accounts/backend/.env', 'utf8');
const url = env.split(/\r?\n/).find((l) => /^DATABASE_URL=/.test(l)).replace(/^DATABASE_URL=/, '').trim();
const pool = new pg.Pool({ connectionString: url, ssl: { rejectUnauthorized: false } });

const { rows: rungs } = await pool.query(`
  SELECT r.topic_id, t.title AS topic, sr.value, sr.text
  FROM inform.compass_stance_revisions sr
  JOIN inform.compass_topic_revisions r ON r.id = sr.topic_revision_id
  JOIN inform.compass_topics t ON t.id = r.topic_id`);

const { rows: ctx } = await pool.query(`
  SELECT c.politician_id, c.topic_id, c.season_id, s.name AS season,
         t.title AS topic, p.full_name, c.reasoning, a.value::int AS chair
  FROM inform.politician_context c
  JOIN inform.compass_topics t ON t.id = c.topic_id
  JOIN inform.seasons s ON s.id = c.season_id
  JOIN essentials.politicians p ON p.id = c.politician_id
  LEFT JOIN inform.politician_answers a
    ON a.politician_id=c.politician_id AND a.topic_id=c.topic_id AND a.season_id=c.season_id
  WHERE c.reasoning IS NOT NULL AND length(c.reasoning) > 40`);
await pool.end();
console.log(`${rungs.length} rung texts across ${new Set(rungs.map((r) => r.topic_id)).size} topics; ${ctx.length} context rows`);

const norm = (s) => s.toLowerCase().replace(/[^a-z0-9 ]+/g, ' ').replace(/\s+/g, ' ').trim();
const grams = (s) => {
  const w = norm(s).split(' ');
  const out = [];
  for (let n = NGRAM_MIN; n <= NGRAM_MAX; n++)
    for (let i = 0; i + n <= w.length; i++) out.push(w.slice(i, i + n).join(' '));
  return out;
};

// n-gram -> set of topic_ids
const owners = new Map();
const gramTopicRung = new Map();
for (const r of rungs) {
  for (const g of grams(r.text)) {
    if (!owners.has(g)) owners.set(g, new Set());
    owners.get(g).add(r.topic_id);
    if (!gramTopicRung.has(g)) gramTopicRung.set(g, `${r.topic}#${r.value}`);
  }
}
const discriminating = new Map(); // gram -> topic_id (unique owner)
for (const [g, set] of owners) if (set.size === 1) discriminating.set(g, [...set][0]);
console.log(`${owners.size} rung n-grams, ${discriminating.size} discriminating (owned by exactly one topic)`);

// index discriminating grams by first word for a cheap scan
const byFirst = new Map();
for (const [g, tid] of discriminating) {
  const f = g.slice(0, g.indexOf(' '));
  if (!byFirst.has(f)) byFirst.set(f, []);
  byFirst.get(f).push([g, tid]);
}

const hits = [];
for (const row of ctx) {
  const words = norm(row.reasoning).split(' ');
  const seen = new Map(); // foreign topic_id -> longest gram
  for (let i = 0; i < words.length; i++) {
    const cand = byFirst.get(words[i]);
    if (!cand) continue;
    const tail = words.slice(i, i + NGRAM_MAX).join(' ');
    for (const [g, tid] of cand) {
      if (tid === row.topic_id) continue;
      if (tail.startsWith(g)) {
        const prev = seen.get(tid);
        if (!prev || g.length > prev.length) seen.set(tid, g);
      }
    }
  }
  if (seen.size) {
    for (const g of seen.values()) {
      hits.push({
        full_name: row.full_name, season: row.season, filed_under: row.topic, chair: row.chair,
        borrowed_from: gramTopicRung.get(g), phrase: g, phrase_words: g.split(' ').length,
        politician_id: row.politician_id, topic_id: row.topic_id,
      });
    }
  }
}

hits.sort((a, b) => b.phrase_words - a.phrase_words);
console.log(`\n${hits.length} borrowed-ladder hits across ${new Set(hits.map((h) => h.politician_id + h.topic_id)).size} rows\n`);

const byPair = new Map();
for (const h of hits) {
  const k = `${h.filed_under}  <-quotes-  ${h.borrowed_from.split('#')[0]}`;
  if (!byPair.has(k)) byPair.set(k, []);
  byPair.get(k).push(h);
}
console.log('BY TOPIC PAIR (filed under <-quotes- ladder it borrowed from):');
for (const [k, v] of [...byPair].sort((a, b) => b[1].length - a[1].length)) {
  const maxLen = Math.max(...v.map((x) => x.phrase_words));
  console.log(`  ${String(v.length).padStart(4)}  ${k}   [longest phrase ${maxLen}w]`);
}
if (OUT) fs.writeFileSync(OUT, JSON.stringify(hits, null, 1));
