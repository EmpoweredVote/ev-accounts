/**
 * fec-burst-gaps-backfill.ts — one-time pass that brings rows stored before CA_0399 up to what fec-burst now keeps.
 *
 * For every FEC source and cycle fec-burst has completed, runs the two CA_0399 line passes with no load-date cursor:
 *   committee gifts  Schedule A lines 11B + 11C, no cap. Re-fetches every PAC and party gift. A stored row comes back
 *                    through ON CONFLICT with its JSON, so contributions_fill_typed fills src_contributor_committee_id
 *                    and fec_line_number on it (the giver id, matched by FEC's own row id). A gift the 50,000 cap had
 *                    dropped is inserted.
 *   refunds          Schedule B lines 20A-C, stored as negative rows (no FEC refund was ever stored before).
 * Then refreshes contribution_summary_agg for the pair, as runIngestion does after an ingest.
 *
 * Cost (measured 2026-11-19): 4,825 source-cycles over 1,672 sources; five single-line pulls per committee (FEC reads
 * only one line_number per request), so ~30,000 FEC calls, through the shared limiter (acquireFecSlot). Run it when fec-burst is not running (it starts
 * ~06:30 UTC) and nothing else is using the key. Writes: ~1M re-fetched committee rows rewritten in place (they were
 * already rewritten by every re-fetch for updated_at), plus the refund rows. Reads no big table whole.
 *
 * Resumable: each finished pair is appended to <PAC_CAREER_DIR>/fec-burst-gaps-done.txt and skipped next time.
 *
 * usage (from backend/):
 *   npx tsx scripts/fec-burst-gaps-backfill.ts [--limit N] [--only <politician_source_id>] [--dry-run] [--stop-at HH]
 *     --dry-run   fetch and normalize, write nothing (prints what it would store)
 *     --stop-at   stop before starting a pair once the UTC hour is HH (e.g. 6, so fec-burst has the key)
 */
import 'dotenv/config';
import { appendFileSync, existsSync, mkdirSync, readFileSync } from 'node:fs';
import { homedir } from 'node:os';
import { join } from 'node:path';
import { pool } from '../src/lib/db.js';
import type { PoliticianSource } from '../src/lib/campaignFinanceService.js';
import { refreshSummaryAgg } from '../src/lib/campaignFinanceService.js';
import {
  COMMITTEE_GIFTS_PASS, createFecAdapter, fetchFecLinePasses, REFUNDS_PASS,
} from '../src/lib/adapters/fecAdapter.js';

const WORK = process.env.PAC_CAREER_DIR ?? join(homedir(), 'Documents/GitHub/.fec-pac-career');
const DONE = join(WORK, 'fec-burst-gaps-done.txt');
const args = process.argv.slice(2);
const flag = (name: string) => { const i = args.indexOf(`--${name}`); return i >= 0 ? args[i + 1] : undefined; };
const DRY = args.includes('--dry-run');
const LIMIT = flag('limit') ? Number(flag('limit')) : Infinity;
const ONLY = flag('only');
const STOP_AT = flag('stop-at') !== undefined ? Number(flag('stop-at')) : null;

async function main(): Promise<void> {
  if (!process.env.FEC_API_KEY) throw new Error('FEC_API_KEY is not set');
  mkdirSync(WORK, { recursive: true });
  const done = new Set(existsSync(DONE) ? readFileSync(DONE, 'utf8').split('\n').filter(Boolean) : []);

  // Small tables only: ingestion_runs and politician_sources.
  const pairs = await pool.query<PoliticianSource & { election_cycle: string }>(
    `SELECT DISTINCT ps.id, ps.essentials_politician_id, ps.source_system, ps.external_id, ps.research_status,
            ps.notes, ps.created_at, ps.updated_at, ir.election_cycle
       FROM transparent_motivations.ingestion_runs ir
       JOIN transparent_motivations.politician_sources ps ON ps.id = ir.politician_source_id
      WHERE ir.adapter_name = 'fec' AND ir.status IN ('completed', 'completed_with_warning')
        AND ps.source_system LIKE 'fec%' AND ps.research_status = 'confirmed'
        AND ($1::uuid IS NULL OR ps.id = $1::uuid)
      ORDER BY ir.election_cycle DESC, ps.id`,
    [ONLY ?? null]
  );
  const todo = pairs.rows.filter((p) => !done.has(`${p.id}|${p.election_cycle}`));
  console.log(`[gaps] ${pairs.rows.length} source-cycles, ${pairs.rows.length - todo.length} already done, ${todo.length} to go${DRY ? ' (dry run)' : ''}`);

  const t0 = Date.now();
  let n = 0; let gifts = 0; let refunds = 0; let inserted = 0; let updated = 0; let errors = 0;
  for (const p of todo) {
    if (n >= LIMIT) break;
    if (STOP_AT !== null && new Date().getUTCHours() === STOP_AT) { console.log(`[gaps] ${STOP_AT}:00 UTC — stopping`); break; }
    const adapter = createFecAdapter(p.election_cycle);
    let pairGifts = 0; let pairRefunds = 0; let pairIns = 0; let pairUpd = 0; let pairErr = 0;
    try {
      const { committees } = await fetchFecLinePasses(p, p.election_cycle, async (batch) => {
        const norm = await adapter.normalize({ records: batch, totalExpected: batch.length, totalFetched: batch.length }, p);
        for (const c of norm.contributions) {
          if (c.amount < 0) pairRefunds++; else pairGifts++;
        }
        if (DRY) return;
        const up = await adapter.upsert(norm);
        pairIns += up.inserted; pairUpd += up.updated; pairErr += up.errors;
      }, [...COMMITTEE_GIFTS_PASS, ...REFUNDS_PASS]);
      if (!DRY && pairErr === 0) {
        await refreshSummaryAgg(p.id, p.election_cycle);
        appendFileSync(DONE, `${p.id}|${p.election_cycle}\n`);
      }
      console.log(`[gaps] ${++n}/${todo.length} ${p.external_id} ${p.election_cycle} committees=${committees} ` +
        `gifts=${pairGifts} refunds=${pairRefunds} inserted=${pairIns} refreshed=${pairUpd}` +
        `${pairErr ? ` ERRORS=${pairErr} (not marked done)` : ''} | ${Math.round((Date.now() - t0) / 1000)}s`);
    } catch (err) {
      n++; pairErr++;
      console.error(`[gaps] ${p.external_id} ${p.election_cycle} failed (not marked done): ${err instanceof Error ? err.message : String(err)}`);
    }
    gifts += pairGifts; refunds += pairRefunds; inserted += pairIns; updated += pairUpd; errors += pairErr;
  }
  console.log(`[gaps] done: ${n} pairs, committee gifts ${gifts}, refunds ${refunds}, inserted ${inserted}, ` +
    `refreshed ${updated}, errors ${errors}`);
}

main().then(() => pool.end()).catch(async (err) => {
  console.error(err);
  await pool.end().catch(() => {});
  process.exit(1);
});
