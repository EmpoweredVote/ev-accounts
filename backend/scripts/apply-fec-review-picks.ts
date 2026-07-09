/**
 * apply-fec-review-picks.ts — apply the picks exported from the FEC review tool.
 *
 * Input: a TSV file, one pick per line: <source_id>\t<candidate_id>\t<full_name>
 * (candidate_id "__none__" => mark the source not_applicable). This is exactly the
 * format the review artifact's "Copy picks" button produces.
 *
 * For each pick (only rows currently needs_research, for safety):
 *   - real candidate_id  -> external_id=<id>, research_status='confirmed'
 *   - "__none__"          -> research_status='not_applicable'
 * A paper-trail note is appended. Dry-run by default; pass --apply to write.
 *
 * Usage: tsx scripts/apply-fec-review-picks.ts <picks.tsv> [--apply]
 */

import 'dotenv/config';
import { readFile } from 'node:fs/promises';
import { pool } from '../src/lib/db.js';

const FILE = process.argv[2];
const APPLY = process.argv.includes('--apply');

const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

async function main() {
  if (!FILE) { console.error('Usage: tsx scripts/apply-fec-review-picks.ts <picks.tsv> [--apply]'); process.exit(1); }
  const raw = await readFile(FILE, 'utf8');
  const picks = raw.split(/\r?\n/).map(l => l.trim()).filter(Boolean).map(line => {
    const [source_id, candidate_id, ...rest] = line.split('\t');
    return { source_id: (source_id ?? '').trim(), candidate_id: (candidate_id ?? '').trim(), name: rest.join(' ').trim() };
  });

  const bad = picks.filter(p => !UUID.test(p.source_id) || !p.candidate_id);
  if (bad.length) { console.error(`Refusing: ${bad.length} malformed line(s). First:`, bad[0]); process.exit(1); }

  console.log(`=== APPLY FEC REVIEW PICKS (${APPLY ? 'APPLY' : 'DRY-RUN'}) — ${picks.length} picks ===`);
  const confirms = picks.filter(p => p.candidate_id !== '__none__');
  const nones = picks.filter(p => p.candidate_id === '__none__');
  console.log(`  confirm: ${confirms.length}   not_applicable: ${nones.length}`);

  if (!APPLY) {
    for (const p of picks) {
      console.log(`  ${p.candidate_id === '__none__' ? 'N/A ' : 'OK  '} ${p.name || p.source_id} -> ${p.candidate_id}`);
    }
    console.log('\n(dry-run — re-run with --apply)');
    await pool.end(); process.exit(0);
  }

  const client = await pool.connect();
  let confirmed = 0, na = 0, skipped = 0;
  try {
    await client.query('BEGIN');
    for (const p of picks) {
      if (p.candidate_id === '__none__') {
        const r = await client.query(
          `UPDATE transparent_motivations.politician_sources
             SET research_status='not_applicable',
                 notes = COALESCE(NULLIF(notes,''),'') || ' | review 2026-07-08: no FEC match (operator)',
                 updated_at=NOW()
           WHERE id=$1 AND research_status='needs_research'`, [p.source_id]);
        if (r.rowCount) na++; else skipped++;
      } else {
        const note = ` | review 2026-07-08: operator-confirmed ${p.candidate_id}`;
        const r = await client.query(
          `UPDATE transparent_motivations.politician_sources
             SET external_id=$2, research_status='confirmed',
                 notes = COALESCE(NULLIF(notes,''),'') || $3,
                 updated_at=NOW()
           WHERE id=$1 AND research_status='needs_research'`, [p.source_id, p.candidate_id, note]);
        if (r.rowCount) confirmed++; else skipped++;
      }
    }
    await client.query('COMMIT');
  } catch (e) {
    await client.query('ROLLBACK');
    console.error('ROLLED BACK:', e); process.exitCode = 1;
  } finally { client.release(); }

  console.log(`\nApplied: confirmed=${confirmed} not_applicable=${na} skipped(not needs_research)=${skipped}`);
  const rem = await pool.query(`SELECT COUNT(*)::int n FROM transparent_motivations.politician_sources WHERE source_system LIKE 'fec%' AND research_status='needs_research'`);
  console.log(`needs_research FEC sources remaining: ${rem.rows[0].n}`);
  await pool.end(); process.exit(0);
}

main().catch(err => { console.error('Fatal:', err instanceof Error ? err.message : String(err)); process.exit(1); });
