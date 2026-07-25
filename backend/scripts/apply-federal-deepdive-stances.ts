import 'dotenv/config';
import { parse } from 'csv-parse/sync';
import { readFileSync } from 'fs';
import pg from 'pg';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const pool = new pg.Pool({ connectionString: process.env.DATABASE_URL, ssl: { rejectUnauthorized: false } });

// --- CLI args: --csv <path> --politician-id <uuid> ---
function getArg(flag: string): string | undefined {
  const i = process.argv.indexOf(flag);
  return i >= 0 && i + 1 < process.argv.length ? process.argv[i + 1] : undefined;
}

function extractSource(notes: string): string | null {
  const match = (notes || '').match(/https?:\/\/\S+/);
  return match ? match[0] : null;
}

async function main() {
  const csvArg = getArg('--csv');
  const politicianId = getArg('--politician-id');
  if (!csvArg || !politicianId) {
    console.error('Usage: tsx apply-federal-deepdive-stances.ts --csv <path> --politician-id <uuid>');
    process.exit(1);
  }
  const csvPath = path.isAbsolute(csvArg) ? csvArg : path.join(process.cwd(), csvArg);
  const csv = readFileSync(csvPath, 'utf8');
  // D-11 columns: politician_id,topic_id,topic_key,value,notes
  // relax_quotes: notes fields carry verbatim excerpts that may contain literal double-quotes;
  // the D-11 contract forbids commas in fields (semicolons only), so quote-wrapping is never
  // needed and a mid-field " must be treated as a literal character, not a quote delimiter.
  const rows = parse(csv, { columns: true, skip_empty_lines: true, relax_quotes: true }) as Array<Record<string, string>>;

  // SAFETY (T-211-01): every row must belong to the target official. Abort on any mismatch
  // BEFORE any write, so a stray row can never widen the write/delete scope to another official.
  const mismatch = rows.find(r => (r.politician_id || '').trim() !== politicianId);
  if (mismatch) {
    console.error(`ABORT: CSV row politician_id '${mismatch.politician_id}' != --politician-id '${politicianId}'. No writes performed.`);
    process.exit(1);
  }

  let upserted = 0, skipped = 0;
  const researchedTopicIds: string[] = []; // non-blank researched topics — the reconcile keep-set
  for (const r of rows) {
    if (!r.value || r.value === 'null' || r.value === '') { skipped++; continue; }
    const value = parseInt(r.value); // D-12: value is the chair number 1-5, applied directly (no polarity conversion).
    await pool.query(
      `INSERT INTO inform.politician_answers (politician_id, topic_id, value)
       VALUES ($1, $2, $3)
       ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value`,
      [politicianId, r.topic_id, value]
    );
    const source = extractSource(r.notes);
    const sources = source ? [source] : [];
    await pool.query(
      `INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
       VALUES ($1, $2, $3, $4)
       ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources`,
      [politicianId, r.topic_id, r.notes, sources]
    );
    researchedTopicIds.push(r.topic_id);
    upserted++;
  }

  // RECONCILE-DELETE (D-05): remove every legacy answer/context row for a topic NOT in the
  // researched non-blank set, so nothing uncited survives (D-03). ALWAYS scoped by politician_id
  // (never a bare/unscoped DELETE — T-211-01). If researchedTopicIds is empty, `<> ALL('{}')` is
  // true for every row, which correctly deletes all of this official's rows.
  const delAnswers = await pool.query(
    `DELETE FROM inform.politician_answers WHERE politician_id = $1 AND topic_id <> ALL($2::uuid[])`,
    [politicianId, researchedTopicIds]
  );
  const delContext = await pool.query(
    `DELETE FROM inform.politician_context WHERE politician_id = $1 AND topic_id <> ALL($2::uuid[])`,
    [politicianId, researchedTopicIds]
  );

  const finalCount = await pool.query(
    `SELECT count(*)::int AS c FROM inform.politician_answers WHERE politician_id = $1`,
    [politicianId]
  );

  console.log(
    `Done for ${politicianId} — Upserted: ${upserted}, Skipped(blank): ${skipped}, ` +
    `Deleted answers: ${delAnswers.rowCount}, Deleted context: ${delContext.rowCount}, ` +
    `Final answer count: ${finalCount.rows[0].c}`
  );
  await pool.end();
}

main().catch(err => { console.error(err); process.exit(1); });
