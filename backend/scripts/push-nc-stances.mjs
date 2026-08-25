// Push an approved NC-campaign stance CSV into inform.politician_answers + politician_context.
//
//   cd backend && node scripts/push-nc-stances.mjs --csv <path>            # DRY RUN (rolls back)
//   cd backend && node scripts/push-nc-stances.mjs --csv <path> --commit   # writes
//   cd backend && node scripts/push-nc-stances.mjs --csv <path> --written <out.json>
//
// Why a script and not the MCP: the Supabase MCP wraps every call in its own transaction, so
// `BEGIN … ROLLBACK` through it is not a dry run at all. A pg client over the pooler is the only way
// to see the real counts and then throw them away.
//
// Two guards that matter:
//   · politician_id is resolved through the SEAT (office_current_holder → offices → districts), never
//     by bare full_name. NC has 52 seats titled Senator and the corpus carries cross-state homonyms.
//   · The upsert carries the expected full_name beside each id and JOINS ON BOTH, so a wrong id drops
//     the row instead of quietly seating the wrong person.
//
// Plan: .planning/workstreams/nc-stance-campaign/PLAN.md (Task 5)
import fs from 'node:fs';
import pg from 'pg';
import { parse } from 'csv-parse/sync';

const argv = process.argv.slice(2);
const flag = (n, d = null) => { const i = argv.indexOf(n); return i > -1 ? argv[i + 1] : d; };
const CSV = flag('--csv');
const WRITTEN = flag('--written');
const COMMIT = argv.includes('--commit');
if (!CSV) { console.error('usage: --csv <path> [--commit] [--written <out.json>]'); process.exit(2); }

const url = fs.readFileSync('.env', 'utf8').split(/\r?\n/)
  .find((l) => /^DATABASE_URL=/.test(l)).replace(/^DATABASE_URL=/, '').trim();
const client = new pg.Client({ connectionString: url, ssl: { rejectUnauthorized: false } });
await client.connect();

const rows = parse(fs.readFileSync(CSV), { columns: true, skip_empty_lines: true })
  .filter((r) => String(r.value ?? '').trim() !== '');
if (!rows.length) { console.error('no valued rows in CSV'); process.exit(2); }

// --- resolve topics ---------------------------------------------------------
const keys = [...new Set(rows.map((r) => r.topic_key))];
const { rows: topics } = await client.query(
  `SELECT topic_key, id FROM inform.compass_topics WHERE topic_key = ANY($1::text[]) AND is_live`, [keys]);
const topicId = Object.fromEntries(topics.map((t) => [t.topic_key, t.id]));
const missingTopic = keys.filter((k) => !topicId[k]);
if (missingTopic.length) { console.error('unknown/not-live topic_key:', missingTopic.join(', ')); process.exit(1); }

// --- resolve people THROUGH THE SEAT ---------------------------------------
const names = [...new Set(rows.map((r) => r.full_name))];
const { rows: people } = await client.query(
  `SELECT DISTINCT p.id, p.full_name, o.title, d.label
     FROM essentials.office_current_holder och
     JOIN essentials.offices o   ON o.id = och.office_id
     JOIN essentials.districts d ON d.id = o.district_id
     JOIN essentials.politicians p ON p.id = och.politician_id
    WHERE lower(d.state) = 'nc' AND p.full_name = ANY($1::text[])`, [names]);
const byName = {};
for (const p of people) (byName[p.full_name] ||= []).push(p);
let held = 0;
for (const n of names) {
  const hits = byName[n] || [];
  // 0 hits or >1 distinct person is HELD, never guessed — report it and drop those rows.
  const distinct = [...new Set(hits.map((h) => h.id))];
  if (distinct.length !== 1) { console.error(`HELD ${n}: resolved to ${distinct.length} people, not 1`); held++; }
  else console.log(`  ${n} → ${distinct[0]}  (${hits.map((h) => `${h.title} / ${h.label}`).join(' | ')})`);
}
if (held) { console.error(`\n${held} name(s) held. Fix the roster, do not force the write.`); process.exit(1); }
const pid = Object.fromEntries(names.map((n) => [n, byName[n][0].id]));

// --- value-change guard -----------------------------------------------------
const { rows: existing } = await client.query(
  `SELECT p.full_name, t.topic_key, a.value AS existing_value
     FROM inform.politician_answers a
     JOIN essentials.politicians p ON p.id = a.politician_id
     JOIN inform.compass_topics t  ON t.id = a.topic_id
    WHERE a.politician_id = ANY($1::uuid[])`, [Object.values(pid)]);
const existingBy = new Map(existing.map((e) => [`${e.full_name}|${e.topic_key}`, e.existing_value]));
const buckets = { NEW: [], unchanged: [], CHANGE: [] };
for (const r of rows) {
  const prev = existingBy.get(`${r.full_name}|${r.topic_key}`);
  if (prev === undefined) buckets.NEW.push(r);
  else if (Number(prev) === Number(r.value)) buckets.unchanged.push(r);
  else buckets.CHANGE.push({ ...r, existing_value: prev });
}
console.log(`\nvalue-change guard: NEW ${buckets.NEW.length} · unchanged ${buckets.unchanged.length} · CHANGE ${buckets.CHANGE.length}`);
for (const c of buckets.CHANGE) console.log(`  CHANGE ${c.full_name}/${c.topic_key}: ${c.existing_value} → ${c.value}`);
if (buckets.CHANGE.length) {
  // Never auto-push a value that overwrites a curated one.
  console.error('\nCHANGE rows present. Those need explicit per-row sign-off — rerun with only NEW rows.');
  process.exit(1);
}

// --- the write --------------------------------------------------------------
const push = buckets.NEW;
const cols = {
  pid: push.map((r) => pid[r.full_name]),
  name: push.map((r) => r.full_name),
  tid: push.map((r) => topicId[r.topic_key]),
  val: push.map((r) => Number(r.value)),
  reasoning: push.map((r) => r.reasoning),
  // sources travel as one delimited string per row and are split back into text[] in SQL
  sources: push.map((r) => [r.source_url_1, r.source_url_2, r.source_url_3].filter((s) => s && s.trim()).join('|')),
};

await client.query('BEGIN');
const { rows: res } = await client.query(
  `WITH v AS (
     SELECT * FROM unnest($1::uuid[], $2::text[], $3::uuid[], $4::numeric[], $5::text[], $6::text[])
              AS t(pid, expected_name, tid, val, reasoning, sources)
   ), ok AS (
     SELECT v.* FROM v
       JOIN essentials.politicians p ON p.id = v.pid AND p.full_name = v.expected_name
   ), ins_a AS (
     INSERT INTO inform.politician_answers (politician_id, topic_id, value)
     SELECT pid, tid, val FROM ok
     ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value
     RETURNING 1
   ), ins_c AS (
     INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
     SELECT pid, tid, reasoning, string_to_array(sources, '|') FROM ok
     ON CONFLICT (politician_id, topic_id)
     DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources
     RETURNING 1
   )
   SELECT (SELECT count(*) FROM ins_a) AS answers,
          (SELECT count(*) FROM ins_c) AS contexts,
          (SELECT count(*) FROM v)     AS expected`,
  [cols.pid, cols.name, cols.tid, cols.val, cols.reasoning, cols.sources]);

const { answers, contexts, expected } = res[0];
console.log(`\nanswers ${answers} · contexts ${contexts} · expected ${expected}`);
const agree = Number(answers) === Number(expected) && Number(contexts) === Number(expected);
if (!agree) {
  // answers < expected means a full_name did not match its id. Fix it; never force it.
  console.error('MISMATCH — a name did not match its id. Rolling back.');
  await client.query('ROLLBACK'); await client.end(); process.exit(1);
}

if (COMMIT) {
  await client.query('COMMIT');
  console.log('COMMITTED');
  if (WRITTEN) {
    // Shape it exactly as audit-chair-evidence.mjs --check reads it, so the ledger file doubles as
    // that gate's input. A bare array, or `value` instead of `chair_after`, yields a vacuous OK.
    const out = { rows: push.map((r) => ({
      politician_id: pid[r.full_name], full_name: r.full_name,
      topic_id: topicId[r.topic_key], topic_key: r.topic_key, chair_after: Number(r.value),
    })) };
    fs.writeFileSync(WRITTEN, JSON.stringify(out, null, 2) + '\n');
    console.log(`wrote ${WRITTEN}`);
  }
} else {
  await client.query('ROLLBACK');
  console.log('ROLLED BACK (dry run) — rerun with --commit to write');
}
await client.end();
