import { pool } from '../src/lib/db.js';
import fs from 'fs';
import path from 'path';

const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

function parseCSV(content: string): string[][] {
  const rows: string[][] = [];
  for (const line of content.split('\n')) {
    if (!line.trim()) continue;
    const cols: string[] = [];
    let cur = '';
    let inQuote = false;
    for (let i = 0; i < line.length; i++) {
      const ch = line[i];
      if (ch === '"') {
        if (inQuote && line[i + 1] === '"') { cur += '"'; i++; }
        else inQuote = !inQuote;
      } else if (ch === ',' && !inQuote) {
        cols.push(cur); cur = '';
      } else {
        cur += ch;
      }
    }
    cols.push(cur);
    rows.push(cols);
  }
  return rows;
}

async function main() {
  const { rows: topicRows } = await pool.query(
    'SELECT id FROM inform.compass_topics WHERE is_live = true'
  );
  const validTopicIds = new Set(topicRows.map((r: any) => r.id));

  const filePath = path.join(process.cwd(), 'data/stance-research/2026-05-21-us-senate-armstrong-ok.csv');
  const rows = parseCSV(fs.readFileSync(filePath, 'utf-8'));

  let upserted = 0;
  let skipped = 0;

  for (const cols of rows) {
    if (cols[0] === 'politician_id') continue;
    if (cols.length < 4) continue;

    const politician_id = cols[0]?.trim();
    const topic_id      = cols[1]?.trim();
    const value         = parseInt(cols[3]?.trim(), 10);
    const reasoning     = cols[4]?.trim() || '';
    const src1          = cols[5]?.trim() || '';
    const src2          = cols[6]?.trim() || '';
    const src3          = cols[7]?.trim() || '';

    if (!UUID_RE.test(politician_id)) { skipped++; continue; }
    if (!UUID_RE.test(topic_id))      { skipped++; continue; }
    if (isNaN(value) || value < 1 || value > 5) { skipped++; continue; }
    if (!validTopicIds.has(topic_id)) {
      console.log(`  SKIP invalid topic_id ${topic_id}`);
      skipped++;
      continue;
    }

    await pool.query(
      `INSERT INTO inform.politician_answers (politician_id, topic_id, value)
       VALUES ($1, $2, $3)
       ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value`,
      [politician_id, topic_id, value]
    );

    const sources = [src1, src2, src3].filter(Boolean);
    await pool.query(
      `INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
       VALUES ($1, $2, $3, $4)
       ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources`,
      [politician_id, topic_id, reasoning, sources]
    );

    upserted++;
  }

  console.log(`armstrong-ok.csv: ${upserted} upserted, ${skipped} skipped`);
  await pool.end();
}

main().catch(e => { console.error(e); process.exit(1); });
