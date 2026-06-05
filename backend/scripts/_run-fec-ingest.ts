import 'dotenv/config';
import { pool } from '../src/lib/db.js';
import { runAdapterForAll } from '../src/lib/campaignFinanceScheduler.js';

const result = await runAdapterForAll('fec');
console.log(JSON.stringify(result, null, 2));
await pool.end();
