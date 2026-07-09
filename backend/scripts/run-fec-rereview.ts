/**
 * run-fec-rereview.ts — re-score existing needs_research FEC sources WITHOUT new
 * FEC API calls, using the candidate list already stored in each row's notes.
 *
 * Purpose: the original auto-match mis-parsed generational suffixes ("Begich III"
 * → last name "iii"), dropping easy matches into needs_research. With parseDbName
 * now suffix-aware, many re-score to a confident single match. This clears those
 * safely so humans only review the genuinely ambiguous tail.
 *
 * Safety (protects the no-double-count invariant):
 *   - Never auto-confirms a politician who already has a confirmed FEC source.
 *   - Never auto-confirms a politician with >1 needs_research FEC row (multi-chamber
 *     candidacy — which office is current is a human call).
 *   - Only auto-confirms a single unambiguous winner scoring >= 0.8.
 *
 * Dry-run by default. Pass --apply to write confirmations.
 *
 * Usage: tsx scripts/run-fec-rereview.ts [--apply]
 */

import 'dotenv/config';
import { pool } from '../src/lib/db.js';
import { parseDbName, scoreMatch, type FecCandidate } from '../src/lib/fecResearch.js';

const APPLY = process.argv.includes('--apply');

interface NrRow {
  source_id: string;
  politician_id: string;
  full_name: string;
  bioguide_id: string | null;
  source_system: 'fec_house' | 'fec_senate';
  representing_state: string;
  external_id: string;
  notes: string;
  nr_count: number;      // needs_research fec rows for this politician
  confirmed_count: number; // confirmed fec rows for this politician
}

interface NoteCandidate { candidate_id: string; name: string; party?: string; score?: number }

async function main() {
  const r = await pool.query<NrRow>(`
    WITH agg AS (
      SELECT essentials_politician_id,
             COUNT(*) FILTER (WHERE research_status='needs_research') AS nr_count,
             COUNT(*) FILTER (WHERE research_status='confirmed')      AS confirmed_count
      FROM transparent_motivations.politician_sources
      WHERE source_system LIKE 'fec%'
      GROUP BY essentials_politician_id
    )
    SELECT ps.id AS source_id, ps.essentials_politician_id AS politician_id,
           p.full_name, p.bioguide_id, ps.source_system, o.representing_state,
           ps.external_id, ps.notes,
           agg.nr_count::int AS nr_count, agg.confirmed_count::int AS confirmed_count
    FROM transparent_motivations.politician_sources ps
    JOIN essentials.politicians p ON p.id = ps.essentials_politician_id
    JOIN essentials.offices o ON o.politician_id = p.id
    JOIN agg ON agg.essentials_politician_id = ps.essentials_politician_id
    WHERE ps.source_system LIKE 'fec%' AND ps.research_status='needs_research'
    GROUP BY ps.id, p.full_name, p.bioguide_id, ps.source_system, o.representing_state,
             ps.external_id, ps.notes, agg.nr_count, agg.confirmed_count
    ORDER BY p.full_name
  `);

  const toConfirm: Array<{ row: NrRow; candidate: NoteCandidate; score: number }> = [];
  const skipped: Array<{ row: NrRow; reason: string }> = [];

  for (const row of r.rows) {
    let candidates: NoteCandidate[] = [];
    try {
      const parsed = JSON.parse(row.notes || '[]');
      if (Array.isArray(parsed)) candidates = parsed;
    } catch { /* notes not JSON (e.g. "No candidates found") */ }

    if (candidates.length === 0) { skipped.push({ row, reason: 'no candidates in notes' }); continue; }
    if (row.confirmed_count > 0) { skipped.push({ row, reason: 'politician already has a confirmed FEC source' }); continue; }
    if (row.nr_count > 1) { skipped.push({ row, reason: `multi-chamber (${row.nr_count} needs_research rows) — human call` }); continue; }

    // Re-score each candidate with the suffix-aware parser.
    const office: 'H' | 'S' = row.source_system === 'fec_senate' ? 'S' : 'H';
    const pol = {
      id: row.politician_id, full_name: row.full_name, bioguide_id: row.bioguide_id,
      fec_office: office, source_system: row.source_system, representing_state: row.representing_state,
    };
    const scored = candidates.map(c => {
      const fc: FecCandidate = {
        candidate_id: c.candidate_id, name: c.name, office, state: row.representing_state,
        party: c.party ?? '', bioguide_id: null,
      };
      return { candidate: c, score: scoreMatch(pol, fc) };
    }).sort((a, b) => b.score - a.score);

    const best = scored[0]!;
    const runnerUp = scored[1];
    const clearWinner = best.score >= 0.8 && (!runnerUp || runnerUp.score < best.score);

    if (clearWinner) {
      toConfirm.push({ row, candidate: best.candidate, score: best.score });
    } else {
      skipped.push({ row, reason: `no clear >=0.8 winner (best ${best.score} ${best.candidate.name})` });
    }
  }

  console.log(`\n=== FEC RE-REVIEW (${APPLY ? 'APPLY' : 'DRY-RUN'}) ===`);
  console.log(`needs_research rows examined: ${r.rows.length}`);
  console.log(`\n--- WOULD AUTO-CONFIRM (${toConfirm.length}) ---`);
  for (const t of toConfirm) {
    console.log(`  ${t.row.representing_state} ${t.row.full_name} [${t.row.source_system}] → ${t.candidate.candidate_id} (${t.candidate.name}, score ${t.score})`);
  }
  parseParseSkipSummary(skipped);

  if (APPLY && toConfirm.length > 0) {
    const client = await pool.connect();
    let n = 0;
    try {
      await client.query('BEGIN');
      for (const t of toConfirm) {
        await client.query(
          `UPDATE transparent_motivations.politician_sources
             SET external_id=$2, research_status='confirmed',
                 notes = COALESCE(NULLIF(notes,''),'') || ' | rereview 2026-07-08: suffix-aware auto-confirm score ' || $3,
                 updated_at=NOW()
           WHERE id=$1 AND research_status='needs_research'`,
          [t.row.source_id, t.candidate.candidate_id, String(t.score)]
        );
        n++;
      }
      await client.query('COMMIT');
      console.log(`\nApplied: ${n} rows confirmed.`);
    } catch (e) {
      await client.query('ROLLBACK');
      console.error('ROLLED BACK:', e);
      process.exitCode = 1;
    } finally { client.release(); }
  } else if (!APPLY) {
    console.log('\n(dry-run — re-run with --apply to confirm)');
  }

  await pool.end();
  process.exit(0);
}

function parseParseSkipSummary(skipped: Array<{ row: NrRow; reason: string }>): void {
  console.log(`\n--- LEFT FOR HUMAN REVIEW (${skipped.length}) ---`);
  const byReason = new Map<string, number>();
  for (const s of skipped) {
    const key = s.reason.replace(/\(.*?\)/g, '(…)').replace(/best [0-9.]+ .*/, 'best <0.8 …');
    byReason.set(key, (byReason.get(key) ?? 0) + 1);
  }
  for (const [reason, count] of [...byReason.entries()].sort((a, b) => b[1] - a[1])) {
    console.log(`  ${count}×  ${reason}`);
  }
}

main().catch(err => { console.error('[rereview] Fatal:', err); process.exit(1); });
