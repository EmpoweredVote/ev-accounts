import 'dotenv/config';
import { pool } from '../src/lib/db.js';

// Check what columns exist in politician_sources
const { rows: cols } = await pool.query(`
  SELECT column_name, data_type
  FROM information_schema.columns
  WHERE table_schema = 'transparent_motivations'
    AND table_name = 'politician_sources'
  ORDER BY ordinal_position
`);
console.log('politician_sources columns:');
for (const c of cols) console.log(`  ${c.column_name}: ${c.data_type}`);

// Check contributions columns
const { rows: ccols } = await pool.query(`
  SELECT column_name, data_type
  FROM information_schema.columns
  WHERE table_schema = 'transparent_motivations'
    AND table_name = 'contributions'
  ORDER BY ordinal_position
`);
console.log('\ncontributions columns:');
for (const c of ccols) console.log(`  ${c.column_name}: ${c.data_type}`);

// Check offices columns
const { rows: ocols } = await pool.query(`
  SELECT column_name, data_type
  FROM information_schema.columns
  WHERE table_schema = 'essentials'
    AND table_name = 'offices'
  ORDER BY ordinal_position
`);
console.log('\noffices columns:');
for (const c of ocols) console.log(`  ${c.column_name}: ${c.data_type}`);

await pool.end();
