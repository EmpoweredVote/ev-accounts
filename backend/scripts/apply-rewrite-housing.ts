import { readFileSync, readdirSync } from 'node:fs';
import { join } from 'node:path';
import { parse } from 'csv-parse/sync';
import { pool } from '../src/lib/db.js';

const REWRITE_ID = 'ddce6b80-84cc-47ec-a992-28f4ad7702d0';
const ACTOR_ID = '854fbc06-40fc-458d-b523-20ef8e5ad1b2';
const CSV_DIR = join(process.cwd(), 'data/stance-research');
const CSV_PREFIX = '2026-04-12-rewrite-housing-batch';

type Row = {
  full_name: string;
  politician_id: string;
  topic_key: string;
  value: string;
  reasoning: string;
  source_url_1: string;
  source_url_2: string;
  source_url_3: string;
};

const files = readdirSync(CSV_DIR).filter(f => f.startsWith(CSV_PREFIX) && f.endsWith('.csv')).sort();
console.log(`Reading ${files.length} CSV files`);

const allRows: Row[] = [];
for (const f of files) {
  const content = readFileSync(join(CSV_DIR, f), 'utf8');
  const rows = parse(content, { columns: true, skip_empty_lines: true, relax_column_count: true }) as Row[];
  allRows.push(...rows);
}

console.log(`Parsed ${allRows.length} total rows`);

let upserted = 0;
let approved = 0;
let rejected = 0;
const errors: string[] = [];

for (const r of allRows) {
  const isNull = !r.value || r.value.trim() === '' || r.value === 'null';

  if (isNull) {
    try {
      await pool.query(
        `SELECT inform.admin_reject_stance_proposal($1::uuid, $2::uuid, $3::uuid, $4::text)`,
        [REWRITE_ID, r.politician_id, ACTOR_ID,
         `Insufficient evidence under new scale: ${r.reasoning || 'agent returned null'}`]
      );
      rejected++;
      console.log(`REJECT ${r.full_name}`);
    } catch (e: any) {
      errors.push(`REJECT ${r.full_name}: ${e.message}`);
      console.error(`REJECT FAIL ${r.full_name}:`, e.message);
    }
    continue;
  }

  const value = Number(r.value);
  const sources = [r.source_url_1, r.source_url_2, r.source_url_3].map(s => s?.trim()).filter(Boolean);
  try {
    await pool.query(
      `SELECT inform.admin_upsert_stance_proposal($1::uuid, $2::uuid, $3::numeric, $4::text, $5::text[])`,
      [REWRITE_ID, r.politician_id, value, r.reasoning, sources]
    );
    upserted++;
    console.log(`UPSERT ${r.full_name} value=${value}`);
  } catch (e: any) {
    errors.push(`UPSERT ${r.full_name}: ${e.message}`);
    console.error(`UPSERT FAIL ${r.full_name}:`, e.message);
    continue;
  }
  try {
    await pool.query(
      `SELECT inform.admin_approve_stance_proposal($1::uuid, $2::uuid, $3::uuid, $4::text)`,
      [REWRITE_ID, r.politician_id, ACTOR_ID, 'auto-approved by research-stances rewrite mode']
    );
    approved++;
    console.log(`APPROVE ${r.full_name}`);
  } catch (e: any) {
    errors.push(`APPROVE ${r.full_name}: ${e.message}`);
    console.error(`APPROVE FAIL ${r.full_name}:`, e.message);
  }
}

console.log(`\nSUMMARY: upserted=${upserted} approved=${approved} rejected=${rejected} errors=${errors.length}`);
if (errors.length) {
  console.log('ERRORS:');
  errors.forEach(e => console.log('  ' + e));
  process.exitCode = 1;
}

await pool.end();
