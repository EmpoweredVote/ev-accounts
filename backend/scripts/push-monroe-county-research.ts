/**
 * One-shot push script for 2026-04-10 Monroe County Commissioner research:
 * - Creates jail-capacity topic (live)
 * - Assigns Public Safety category
 * - Upserts 16 stances (politician_answers + politician_context)
 * - Inserts 40 quotes (minus one short quote flagged for removal) into essentials.quotes
 *
 * Safe to re-run: stance upserts use ON CONFLICT; quotes check for existence first.
 */
import { pool } from '../src/lib/db.js';
import { parse } from 'csv-parse/sync';
import { readFileSync } from 'fs';

const DATA_DIR = '/Users/chrisandrews/Documents/GitHub/ev-accounts/backend/data';
const STANCES_CSV = `${DATA_DIR}/stance-research/2026-04-10-monroe-county-commissioner.csv`;
const QUOTES_CSV = `${DATA_DIR}/stance-research/2026-04-10-monroe-county-commissioner-quotes.csv`;
const JAIL_DRAFT = `${DATA_DIR}/topic-drafts/2026-04-10-jail-capacity.json`;

const PUBLIC_SAFETY_CATEGORY_ID = '699a14d1-fc6d-48ac-b3dc-492f3f59ec6c';

const POLITICIAN_IDS: Record<string, string> = {
  'Trent Deckard': 'db4e6911-9dbb-430e-831c-08be094fd637',
  'David Henry': '0be7d42f-9363-40ad-bbc5-733c862f4395',
};

// Short quote flagged by researcher for removal
const QUOTES_TO_SKIP = new Set<string>(['This is the wrong approach.']);

async function main() {
  console.log('=== Monroe County Research Push ===\n');

  // 1. Create jail-capacity topic (live)
  const jailDraft = JSON.parse(readFileSync(JAIL_DRAFT, 'utf-8'));
  console.log(`[1/5] Creating topic: ${jailDraft.title}`);

  const { rows: [created] } = await pool.query(
    `SELECT public.admin_create_topic_with_stances($1::text, $2::text, $3::text, $4::boolean, $5::jsonb) as result`,
    [
      jailDraft.title,
      jailDraft.question_text,
      jailDraft.short_title,
      true, // is_live
      JSON.stringify(jailDraft.stances),
    ]
  );
  const jailTopicId = created.result.topic.id;
  console.log(`      Created: ${jailTopicId}`);

  // Set topic_key explicitly
  await pool.query(
    `UPDATE inform.compass_topics SET topic_key = $1 WHERE id = $2`,
    [jailDraft.topic_key, jailTopicId]
  );
  console.log(`      topic_key = ${jailDraft.topic_key}`);

  // 2. Assign Public Safety category
  console.log('[2/5] Assigning category: Public Safety and Law Enforcement');
  await pool.query(
    `INSERT INTO inform.compass_topic_categories (topic_id, category_id)
     VALUES ($1, $2) ON CONFLICT DO NOTHING`,
    [jailTopicId, PUBLIC_SAFETY_CATEGORY_ID]
  );

  // 3. Load all topic IDs (by topic_key) for stance upserts
  const { rows: topicRows } = await pool.query(
    `SELECT id, topic_key FROM inform.compass_topics WHERE is_live = true`
  );
  const topicIdByKey: Record<string, string> = {};
  for (const r of topicRows) topicIdByKey[r.topic_key] = r.id;

  // 4. Parse and upsert stances
  console.log('[3/5] Upserting stances...');
  const stanceCsv = readFileSync(STANCES_CSV, 'utf-8');
  const stanceRows = parse(stanceCsv, { columns: true, skip_empty_lines: true }) as Array<{
    full_name: string;
    topic_key: string;
    value: string;
    reasoning: string;
    source_url_1?: string;
    source_url_2?: string;
    source_url_3?: string;
  }>;

  let stanceCount = 0;
  let skippedStances: string[] = [];

  for (const row of stanceRows) {
    const politicianId = POLITICIAN_IDS[row.full_name];
    const topicId = topicIdByKey[row.topic_key];
    if (!politicianId) {
      skippedStances.push(`${row.full_name}/${row.topic_key} (no politician_id)`);
      continue;
    }
    if (!topicId) {
      skippedStances.push(`${row.full_name}/${row.topic_key} (no topic_id)`);
      continue;
    }

    await pool.query(
      `INSERT INTO inform.politician_answers (politician_id, topic_id, value)
       VALUES ($1, $2, $3)
       ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value`,
      [politicianId, topicId, parseInt(row.value, 10)]
    );

    const sources = [row.source_url_1, row.source_url_2, row.source_url_3].filter(
      (s): s is string => !!s && s.length > 0
    );

    await pool.query(
      `INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
       VALUES ($1, $2, $3, $4)
       ON CONFLICT (politician_id, topic_id) DO UPDATE
         SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources`,
      [politicianId, topicId, row.reasoning, sources]
    );

    stanceCount++;
  }
  console.log(`      Upserted ${stanceCount} stances`);
  if (skippedStances.length) console.log(`      Skipped: ${skippedStances.join(', ')}`);

  // 5. Parse and insert quotes
  console.log('[4/5] Inserting quotes...');
  const quoteCsv = readFileSync(QUOTES_CSV, 'utf-8');
  const quoteRows = parse(quoteCsv, { columns: true, skip_empty_lines: true }) as Array<{
    full_name: string;
    topic_key: string;
    quote_text: string;
    source_url: string;
    source_name: string;
  }>;

  let quoteCount = 0;
  let skippedQuotes: string[] = [];

  for (const row of quoteRows) {
    if (QUOTES_TO_SKIP.has(row.quote_text)) {
      skippedQuotes.push(`"${row.quote_text}" (flagged short)`);
      continue;
    }
    const politicianId = POLITICIAN_IDS[row.full_name];
    if (!politicianId) {
      skippedQuotes.push(`${row.full_name} (no politician_id)`);
      continue;
    }

    // Dedupe: skip if this exact quote already exists for this politician
    const { rows: existing } = await pool.query(
      `SELECT id FROM essentials.quotes
       WHERE politician_id = $1 AND quote_text = $2`,
      [politicianId, row.quote_text]
    );
    if (existing.length > 0) {
      skippedQuotes.push(`${row.full_name}/${row.topic_key} (duplicate)`);
      continue;
    }

    await pool.query(
      `INSERT INTO essentials.quotes (politician_id, topic_key, quote_text, source_url, source_name)
       VALUES ($1, $2, $3, $4, $5)`,
      [politicianId, row.topic_key, row.quote_text, row.source_url, row.source_name]
    );
    quoteCount++;
  }
  console.log(`      Inserted ${quoteCount} quotes`);
  if (skippedQuotes.length) console.log(`      Skipped: ${skippedQuotes.join(', ')}`);

  // 6. Verification query
  console.log('[5/5] Verifying...');
  const { rows: verifyStances } = await pool.query(
    `SELECT p.full_name, t.topic_key, pa.value
     FROM inform.politician_answers pa
     JOIN essentials.politicians p ON p.id = pa.politician_id
     JOIN inform.compass_topics t ON t.id = pa.topic_id
     WHERE pa.politician_id = ANY($1)
     ORDER BY p.full_name, t.topic_key`,
    [Object.values(POLITICIAN_IDS)]
  );
  const { rows: verifyQuotes } = await pool.query(
    `SELECT politician_id, COUNT(*)::int as n FROM essentials.quotes
     WHERE politician_id = ANY($1) GROUP BY politician_id`,
    [Object.values(POLITICIAN_IDS)]
  );

  console.log(`      ${verifyStances.length} stances in DB for these candidates`);
  for (const q of verifyQuotes) {
    const name = Object.entries(POLITICIAN_IDS).find(([, id]) => id === q.politician_id)?.[0];
    console.log(`      ${name}: ${q.n} quotes in DB`);
  }

  console.log('\n=== DONE ===');
  await pool.end();
}

main().catch((e) => {
  console.error('FATAL:', e);
  process.exit(1);
});
