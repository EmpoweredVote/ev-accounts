import { readFileSync, readdirSync } from 'node:fs';
import { join } from 'node:path';
import { parse } from 'csv-parse/sync';
import { pool } from '../src/lib/db.js';

const REWRITE_ID = '722d9884-873f-4967-b1fb-0f18ac76b497';
const ACTOR_ID = '854fbc06-40fc-458d-b523-20ef8e5ad1b2';
const CSV_DIR = join(process.cwd(), 'data/stance-research');
const CSV_PREFIX = '2026-04-12-rewrite-ai-regulation-batch';

const SKIPPED: { id: string; name: string; reason: string }[] = [
  { id: '21c9e711-fb18-4afb-884f-08acd2b598ba', name: 'Karen Ruth Bass',
    reason: 'Insufficient evidence under new scale: only Executive Directive 10 (permit review AI adoption) found, no regulatory stance.' },
  { id: 'bb73793e-ad67-431a-bb03-663b765204d8', name: 'Linda T. Sanchez',
    reason: 'Insufficient evidence under new scale: no AI-specific bills, statements, or votes identified.' },
  { id: '822966a7-5f09-4151-ba43-630afbd676c2', name: 'Pete Aguilar',
    reason: 'Insufficient evidence under new scale: only AI workforce appropriations found, no regulatory position.' },
  { id: 'a2c6adc7-7689-49b9-964f-8f2aeb243a83', name: 'Sydney Kamlager-Dove',
    reason: 'Insufficient evidence under new scale: AI work is export controls and national competitiveness, no domestic deployment stance.' },
];

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
  if (!r.value || r.value.trim() === '' || r.value === 'null') {
    console.log(`SKIP (null value in CSV): ${r.full_name}`);
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
      [REWRITE_ID, r.politician_id, ACTOR_ID, 'auto-approved by research-stances rewrite mode (Plan D first run)']
    );
    approved++;
    console.log(`APPROVE ${r.full_name}`);
  } catch (e: any) {
    errors.push(`APPROVE ${r.full_name}: ${e.message}`);
    console.error(`APPROVE FAIL ${r.full_name}:`, e.message);
  }
}

console.log('\n--- Rejecting insufficient-evidence proposals ---');
for (const s of SKIPPED) {
  try {
    await pool.query(
      `SELECT inform.admin_reject_stance_proposal($1::uuid, $2::uuid, $3::uuid, $4::text)`,
      [REWRITE_ID, s.id, ACTOR_ID, s.reason]
    );
    rejected++;
    console.log(`REJECT ${s.name}`);
  } catch (e: any) {
    errors.push(`REJECT ${s.name}: ${e.message}`);
    console.error(`REJECT FAIL ${s.name}:`, e.message);
  }
}

console.log(`\nSUMMARY: upserted=${upserted} approved=${approved} rejected=${rejected} errors=${errors.length}`);
if (errors.length) {
  console.log('ERRORS:');
  errors.forEach(e => console.log('  ' + e));
  process.exitCode = 1;
}

await pool.end();
