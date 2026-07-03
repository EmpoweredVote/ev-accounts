/**
 * Phase 160 — External_id Collision Audit (READ-ONLY)
 *
 * Audits the proposed Wave-3 negative external_id formula
 *   -(state_fips * 10000 + cd * 100 + seq)
 * against every LIVE negative external_id already in essentials.politicians, for
 * seq 1-99, across all 38 Wave-3 states / 178 districts.
 *
 * RESEARCH.md Critical Finding 6 (proven live this session): the negative-id space
 * has been reused with several mutually-inconsistent ad-hoc numbering schemes across
 * the project's history (state legislatures, state execs, county/city local races, an
 * early MA congressional-delegation scheme). The formula is NOT collision-free by
 * construction — 16/178 districts across KY/OR/OK/KS/NV/NM/NE/ME/NH/MT collide.
 * KY-CD1 and OK-CD1 are near-saturated and need an alternate sub-band (seq >= 200).
 *
 * SELECT-ONLY. The only query is `SELECT external_id FROM essentials.politicians WHERE
 * external_id < 0`. No write statements of any kind, ever. Never pass --commit.
 * Re-runnable / idempotent. Does NOT hard-fail on collisions found — they are expected
 * data, resolved at seeding time via a live pre-write check (documented safe_start_seq here).
 *
 * Run with:
 *   cd /c/EV-Accounts/backend && set -a && source .env && set +a \
 *     && node --import tsx scripts/diag-160-external-id-collision.ts
 */
import 'dotenv/config';
import { writeFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { pool } from '../src/lib/db.js';

// --- constants ------------------------------------------------------------
const FIPS: Record<string, number> = {
  WA: 53, AZ: 4, TN: 47, MA: 25, IN: 18, MD: 24, MN: 27, MO: 29, WI: 55, CO: 8,
  AL: 1, SC: 45, LA: 22, KY: 21, OR: 41, CT: 9, OK: 40, AR: 5, IA: 19, KS: 20,
  MS: 28, NV: 32, UT: 49, NM: 35, NE: 31, WV: 54, ID: 16, HI: 15, ME: 23, NH: 33,
  RI: 44, MT: 30, AK: 2, DE: 10, ND: 38, SD: 46, VT: 50, WY: 56,
};
const DELEG: Record<string, number> = {
  WA: 10, AZ: 9, TN: 9, MA: 9, IN: 9, MD: 8, MN: 8, MO: 8, WI: 8, CO: 8,
  AL: 7, SC: 7, LA: 6, KY: 6, OR: 6, CT: 5, OK: 5, AR: 4, IA: 4, KS: 4,
  MS: 4, NV: 4, UT: 4, NM: 3, NE: 3, WV: 2, ID: 2, HI: 2, ME: 2, NH: 2,
  RI: 2, MT: 2, AK: 1, DE: 1, ND: 1, SD: 1, VT: 1, WY: 1,
};
const MAX_SEQ = 99;
const ALTERNATE_SUB_BAND_START = 200;

const CSV_PATH = resolve(
  process.cwd(),
  '..',
  '.planning',
  'phases',
  '160-field-resolution-stance-gap-diagnostic',
  '160-negative-id-audit.csv',
);

function csvField(value: unknown): string {
  if (value === null || value === undefined) return '';
  const s = String(value);
  // RFC-4180: quote any field containing comma, quote, CR, or LF.
  if (/[",\r\n]/.test(s)) {
    return `"${s.replace(/"/g, '""')}"`;
  }
  return s;
}

interface DistrictAudit {
  state: string;
  cd: number;
  geo_id: string;
  fips: number;
  collision_count: number;
  colliding_seqs: number[];
  max_seq: number;
  free_slots_remaining: number;
  safe_start_seq: number;
}

async function main(): Promise<void> {
  console.log('=== Phase 160 / external_id collision audit (READ-ONLY, 38 states / 178 districts) ===\n');

  // -----------------------------------------------------------------------
  // Load all live negative external_ids once.
  // -----------------------------------------------------------------------
  const { rows } = await pool.query<{ external_id: number }>(
    'SELECT external_id FROM essentials.politicians WHERE external_id < 0',
  );
  const negIds = new Set(rows.map((r) => Number(r.external_id)));
  console.log(`Loaded ${negIds.size} live negative external_ids from essentials.politicians.\n`);

  // -----------------------------------------------------------------------
  // Per-district collision loop: for each of the 38 states x its district count,
  // test seq 1-99 of -(fips*10000 + cd*100 + seq).
  // -----------------------------------------------------------------------
  const audits: DistrictAudit[] = [];
  for (const [st, fips] of Object.entries(FIPS)) {
    const numDistricts = DELEG[st];
    for (let cd = 1; cd <= numDistricts; cd++) {
      const collisions: number[] = [];
      for (let seq = 1; seq <= MAX_SEQ; seq++) {
        const candidate = -(fips * 10000 + cd * 100 + seq);
        if (negIds.has(candidate)) collisions.push(seq);
      }
      if (collisions.length > 0) {
        const maxSeq = Math.max(...collisions);
        const collidingSet = new Set(collisions);
        const freeSlotsRemaining = MAX_SEQ - collisions.length;
        // safe_start_seq = lowest seq >= 1 with a contiguous free run to MAX_SEQ,
        // i.e. the first free seq at or after the highest collision.
        // KY-CD1 and OK-CD1 are explicitly flagged (RESEARCH.md Critical Finding 6)
        // for an alternate 200+ sub-band regardless of the computed free-slot count,
        // since KY-CD1's band is near-saturated (98/99) and OK-CD1 is the other
        // district the research session called out for the same treatment.
        let safeStartSeq: number;
        const isAlternateBandDistrict = (st === 'KY' && cd === 1) || (st === 'OK' && cd === 1);
        if (isAlternateBandDistrict || collisions.length >= 90 || freeSlotsRemaining < 2) {
          safeStartSeq = ALTERNATE_SUB_BAND_START;
        } else {
          let candidateSeq = maxSeq + 1;
          while (candidateSeq <= MAX_SEQ && collidingSet.has(candidateSeq)) candidateSeq++;
          safeStartSeq = candidateSeq <= MAX_SEQ ? candidateSeq : ALTERNATE_SUB_BAND_START;
        }
        audits.push({
          state: st,
          cd,
          geo_id: `${fips.toString().padStart(2, '0')}${cd.toString().padStart(2, '0')}`,
          fips,
          collision_count: collisions.length,
          colliding_seqs: collisions,
          max_seq: maxSeq,
          free_slots_remaining: freeSlotsRemaining,
          safe_start_seq: safeStartSeq,
        });
        console.log(`${st}-CD${cd}: ${collisions.length} collisions, max seq ${maxSeq}, safe_start_seq ${safeStartSeq}`);
      }
    }
  }

  console.log(`\nTotal colliding districts: ${audits.length} (expected 16)\n`);

  // -----------------------------------------------------------------------
  // ALTERNATE SUB-BAND REQUIRED warning for near-saturated districts.
  // -----------------------------------------------------------------------
  const altBandDistricts = audits.filter((a) => a.safe_start_seq >= ALTERNATE_SUB_BAND_START);
  if (altBandDistricts.length > 0) {
    console.warn(
      `\nWARNING: ALTERNATE SUB-BAND REQUIRED for ${altBandDistricts.length} district(s) — standard seq 1-99 band is ` +
        'near-saturated; use seq >= 200 for these districts:',
    );
    for (const a of altBandDistricts) {
      console.warn(
        `  ${a.state}-CD${a.cd} (geo_id ${a.geo_id}): ${a.collision_count}/${MAX_SEQ} slots taken, ` +
          `free_slots_remaining=${a.free_slots_remaining}, safe_start_seq=${a.safe_start_seq}`,
      );
    }
  }

  // -----------------------------------------------------------------------
  // Emit 160-negative-id-audit.csv
  // -----------------------------------------------------------------------
  const header = [
    'state',
    'cd',
    'geo_id',
    'fips',
    'collision_count',
    'colliding_seqs',
    'max_seq',
    'free_slots_remaining',
    'safe_start_seq',
  ];
  const lines = [header.join(',')];
  for (const a of audits) {
    const collidingSeqsStr =
      a.colliding_seqs.length > 1 && isContiguous(a.colliding_seqs)
        ? `${a.colliding_seqs[0]}-${a.colliding_seqs[a.colliding_seqs.length - 1]}`
        : a.colliding_seqs.join(',');
    lines.push(
      [
        csvField(a.state),
        csvField(a.cd),
        csvField(a.geo_id),
        csvField(a.fips),
        csvField(a.collision_count),
        csvField(collidingSeqsStr),
        csvField(a.max_seq),
        csvField(a.free_slots_remaining),
        csvField(a.safe_start_seq),
      ].join(','),
    );
  }
  const csvContent = lines.join('\n') + '\n';
  writeFileSync(CSV_PATH, csvContent, 'utf8');
  console.log(`Wrote ${CSV_PATH}`);
  console.log(`  data rows: ${audits.length}  (header + data = ${lines.length} lines)`);

  const unresolvedCount = audits.filter((a) => !a.safe_start_seq || a.safe_start_seq < 1).length;
  console.log(`  UNRESOLVED collisions (no safe_start_seq computed): ${unresolvedCount} (expected 0)`);

  console.log('\nDiagnostic complete (read-only; the only write was the git-tracked CSV artifact).');
  await pool.end();
}

function isContiguous(seqs: number[]): boolean {
  for (let i = 1; i < seqs.length; i++) {
    if (seqs[i] !== seqs[i - 1] + 1) return false;
  }
  return true;
}

main().catch(async (err) => {
  console.error('Diagnostic failed:', err);
  try {
    await pool.end();
  } catch {
    /* noop */
  }
  process.exit(1);
});
