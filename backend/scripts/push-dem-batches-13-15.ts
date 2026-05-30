import { pool } from '../src/lib/db.js';
import fs from 'fs';
import path from 'path';

const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

const UUID_FIX: Record<string, string> = {
  '448b1c9a-b6f3-42b8-8f39-d3bbb5bba9ee': '448b1c9a-b6f3-42b8-8f39-d3bbb5bfa9ee',
  '00b95a6a-75db-4521-b523-3326bba838de': '00b95a6a-75db-4521-b523-3326bba938de',
  'c5ab4eab-702f-49b8-9277-8ea53f3785c6': 'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
};

function parseCSV(content: string): string[][] {
  const rows: string[][] = [];
  const lines = content.split('\n');
  for (const line of lines) {
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

  const files = [
    'data/stance-research/2026-05-20-us-senate-batch13-dem-a.csv',
    'data/stance-research/2026-05-20-us-senate-batch14-dem-b.csv',
    'data/stance-research/2026-05-21-us-senate-batch15-dem-c.csv',
  ];

  let totalUpserted = 0;
  let totalSkipped = 0;

  for (const relPath of files) {
    const filePath = path.join(process.cwd(), relPath);
    const content = fs.readFileSync(filePath, 'utf-8');
    const rows = parseCSV(content);

    let fileUpserted = 0;
    let fileSkipped = 0;

    for (const cols of rows) {
      // Skip header
      if (cols[0] === 'politician_id') continue;
      if (cols.length < 4) continue;

      const politician_id = cols[0]?.trim();
      const raw_topic_id = cols[1]?.trim();
      const topic_key = cols[2]?.trim();
      const value = parseInt(cols[3]?.trim(), 10);
      const reasoning = cols[4]?.trim() || '';
      const src1 = cols[5]?.trim() || '';
      const src2 = cols[6]?.trim() || '';
      const src3 = cols[7]?.trim() || '';

      if (!UUID_RE.test(politician_id)) { fileSkipped++; continue; }
      if (!UUID_RE.test(raw_topic_id)) { fileSkipped++; continue; }
      if (isNaN(value) || value < 1 || value > 5) { fileSkipped++; continue; }

      const topic_id = UUID_FIX[raw_topic_id] || raw_topic_id;

      if (!validTopicIds.has(topic_id)) {
        console.log(`  SKIP invalid topic_id ${topic_id} (${topic_key})`);
        fileSkipped++;
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

      fileUpserted++;
    }

    console.log(`${path.basename(relPath)}: ${fileUpserted} upserted, ${fileSkipped} skipped`);
    totalUpserted += fileUpserted;
    totalSkipped += fileSkipped;
  }

  console.log(`\nTotal: ${totalUpserted} upserted, ${totalSkipped} skipped`);
  await pool.end();
}

main().catch(e => { console.error(e); process.exit(1); });
