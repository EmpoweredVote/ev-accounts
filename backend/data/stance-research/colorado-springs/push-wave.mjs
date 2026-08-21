#!/usr/bin/env node
/**
 * Push the Colorado Springs stance wave to prod.
 *
 * Writes `inform.politician_answers` (the value) and `inform.politician_context`
 * (reasoning + sources) TOGETHER, in one transaction. That coupling is deliberate:
 * `reasoning` is the public "Why this position?" text on the Essentials profile, so it must
 * never lag or contradict the value it explains.
 *
 * Refuses to touch a (politician, topic) that already has an answer. This wave was verified
 * greenfield — all 35 people had zero rows — so ANY collision means something changed under
 * us and is a stop-and-look, not something to silently overwrite.
 *
 * Usage:
 *   node push-wave.mjs --dry-run     BEGIN ... ROLLBACK, prints what it would do
 *   node push-wave.mjs --commit
 */
import { readFile, readdir } from 'node:fs/promises';
import path from 'node:path';
import { parse } from 'csv-parse/sync';
import pg from 'pg';

const HERE = path.dirname(new URL(import.meta.url).pathname.replace(/^\/([A-Za-z]:)/, '$1'));
const COMMIT = process.argv.includes('--commit');
const DRY = process.argv.includes('--dry-run') || !COMMIT;

const cohort = JSON.parse(await readFile(path.join(HERE, 'cohort.json'), 'utf8'));
const byName = new Map(cohort.map((c) => [c.full_name, c]));

const files = (await readdir(HERE)).filter((f) => /^out-.*\.csv$/.test(f)).sort();
const rows = [];
for (const f of files) {
  const parsed = parse(await readFile(path.join(HERE, f), 'utf8'), {
    columns: true, skip_empty_lines: true, bom: true,
  });
  for (const r of parsed) rows.push({ ...r, _file: f });
}

const pool = new pg.Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: { rejectUnauthorized: false },
});

// Resolve topic_key -> topic_id once, from prod, for live topics only.
const { rows: topics } = await pool.query(
  'SELECT id::text, topic_key FROM inform.compass_topics WHERE is_live = true'
);
const topicId = new Map(topics.map((t) => [t.topic_key, t.id]));

const planned = [];
const refused = [];
for (const r of rows) {
  const person = byName.get((r.full_name || '').trim());
  const tid = topicId.get((r.topic_key || '').trim());
  if (!person) { refused.push(`${r._file}: "${r.full_name}" not in cohort`); continue; }
  if (!tid) { refused.push(`${r._file}: topic "${r.topic_key}" not live`); continue; }
  const v = Number(r.value);
  if (!Number.isInteger(v) || v < 1 || v > 5) { refused.push(`${r._file}: ${r.full_name}/${r.topic_key} bad value "${r.value}"`); continue; }
  const reasoning = (r.reasoning || '').trim();
  if (reasoning.length < 40) { refused.push(`${r._file}: ${r.full_name}/${r.topic_key} reasoning too short — it is public text`); continue; }
  planned.push({
    pid: person.id, tid, v, reasoning,
    sources: [r.source_url_1, r.source_url_2, r.source_url_3].map((s) => (s || '').trim()).filter(Boolean),
    who: person.full_name, topic: r.topic_key,
  });
}

if (refused.length) {
  console.log('REFUSED ROWS:');
  for (const x of refused) console.log('  ' + x);
}

const client = await pool.connect();
let wrote = 0;
const collisions = [];
try {
  await client.query('BEGIN');
  for (const p of planned) {
    const { rows: existing } = await client.query(
      'SELECT value FROM inform.politician_answers WHERE politician_id=$1 AND topic_id=$2',
      [p.pid, p.tid]
    );
    if (existing.length) {
      collisions.push(`${p.who}/${p.topic}: already has value ${existing[0].value}, proposed ${p.v} — NOT written`);
      continue;
    }
    await client.query(
      'INSERT INTO inform.politician_answers (politician_id, topic_id, value) VALUES ($1,$2,$3)',
      [p.pid, p.tid, p.v]
    );
    await client.query(
      `INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
       VALUES ($1,$2,$3,$4)
       ON CONFLICT (politician_id, topic_id)
       DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources`,
      [p.pid, p.tid, p.reasoning, p.sources]
    );
    wrote++;
  }

  // Post-verify inside the transaction, house style.
  const { rows: check } = await client.query(
    `SELECT count(*)::int AS n FROM inform.politician_answers a
     JOIN inform.politician_context c USING (politician_id, topic_id)
     WHERE a.politician_id = ANY($1::uuid[])`,
    [[...new Set(planned.map((p) => p.pid))]]
  );
  console.log(`\nanswers+context paired for this cohort after write: ${check[0].n}`);

  if (DRY) {
    await client.query('ROLLBACK');
    console.log(`\nDRY RUN — rolled back. Would have written ${wrote} answer+context pairs.`);
  } else {
    await client.query('COMMIT');
    console.log(`\nCOMMITTED ${wrote} answer+context pairs.`);
  }
} catch (e) {
  await client.query('ROLLBACK');
  console.error('ROLLED BACK:', e.message);
  process.exitCode = 1;
} finally {
  client.release();
  await pool.end();
}

if (collisions.length) {
  console.log('\n🔴 COLLISIONS (existing values left untouched — investigate before re-running):');
  for (const c of collisions) console.log('  ' + c);
}
console.log(`\nfiles=${files.length} parsed=${rows.length} planned=${planned.length} refused=${refused.length}`);
