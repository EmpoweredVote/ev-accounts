/**
 * judicialCalAccessIngest — connective tissue between the
 * calAccessAdapter.ts parser and the new judicial.donations table.
 *
 * Reuses (verbatim, no forking):
 *   - src/lib/adapters/calAccessAdapter.ts's prepare()/fetch()/normalize() (via createCalAccessAdapter())
 *   - src/lib/adapters/normalizeDonorName.ts (LOCKED 7-step pipeline)
 *
 * 🔴 Reusing the adapter verbatim also reused its defect. Until PR #659 (2026-09-23) it matched
 * RCPT_CD.CMTE_ID — the CONTRIBUTOR's committee id — so all 226 rows of the first judicial run
 * were money each judge's own committee paid out (CA_0196 deleted them). Rows written since
 * carry raw_record FILER_ID, the recipient; rows without that key are from the old adapter.
 *
 * Does NOT reuse:
 *   - the adapter's contributions-table write path — that targets
 *     transparent_motivations.contributions (D-11). writeJudicialDonations()
 *     below is a judicial-specific parameterized write targeting
 *     judicial.donations instead.
 *   - the adapter's ETag-persistence method — targeted/partial runs never save
 *     the shared production Cal-Access ETag cache (mirrors
 *     campaignFinanceScheduler.ts's runAdapterForSources() —
 *     "ETag ownership belongs to the full scheduled run only").
 *
 * This module never edits calAccessAdapter.ts and never calls the adapter's
 * contributions-table write method.
 */

import { pool } from '../db.js';
import type { ContributionInsert } from '../adapters/adapterInterface.js';
import type { PoliticianSource } from '../campaignFinanceService.js';

// ---------------------------------------------------------------------------
// Fake-PoliticianSource builder (D-07/D-10) — drives the adapter
// ---------------------------------------------------------------------------

/**
 * buildFakePoliticianSource constructs an in-memory object satisfying the
 * PoliticianSource TS interface, using only the two fields fetch()/normalize()
 * actually read: `id` (becomes ContributionInsert.politician_source_id — the
 * judicial mapping fn below discards this, using judgeId directly instead) and
 * `external_id` (the recipient filer id: fetch() returns the receipts reported on
 * filings this filer made, RCPT_CD.FILING_ID -> FILER_FILINGS_CD.FILER_ID). The
 * remaining 6 fields are never read by the adapter — safe placeholders.
 */
export function buildFakePoliticianSource(judgeId: string, filerId: string): PoliticianSource {
  const now = new Date().toISOString();
  return {
    id: judgeId,
    essentials_politician_id: '',
    source_system: 'cal_access',
    external_id: filerId,
    research_status: 'confirmed',
    notes: '',
    created_at: now,
    updated_at: now,
  };
}

// ---------------------------------------------------------------------------
// Pure mapping fn: ContributionInsert -> judicial donation row shape
// ---------------------------------------------------------------------------

/** Static Cal-Access portal URL — per-filing deep link unavailable from RCPT_CD.TSV alone. */
const CAL_ACCESS_SOURCE_URL = 'https://cal-access.sos.ca.gov/Campaign/';

/** The judicial.donations row shape produced by the mapping fn, prior to insert. */
export interface JudicialDonationRow {
  judge_id: string;
  donor_name_raw: string;
  donor_name_normalized: string;
  donor_type: null;
  donor_employer_raw: string | null;
  donor_occupation_raw: string | null;
  amount: number;
  contribution_date: Date | null;
  data_source: string;
  source_transaction_id: string;
  source_url: string;
  confidence_level: 'HIGH' | 'MEDIUM' | 'ESTIMATED';
  raw_record: Record<string, unknown>;
}

/**
 * mapContributionsToJudicialDonations turns ContributionInsert[] (returned by
 * the adapter's normalize()) into judicial.donations row shapes.
 *
 * - donor_name_raw reconstructed from raw_record CTRIB_NAML/CTRIB_NAMF (`.trim()`),
 *   exactly mirroring calAccessAdapter.ts's own reconstruction (line 663).
 * - source_transaction_id copied verbatim (idempotency key:
 *   `${filingID}_${amendID}_${lineItem}`, produced by normalize()).
 * - confidence_level and raw_record copied verbatim from the ContributionInsert.
 * - donor_employer_raw/donor_occupation_raw pulled from raw_record CTRIB_EMP/CTRIB_OCC
 *   (null when absent).
 * - donor_type left null (Discretion b — attorney/firm classification deferred to
 *   Phase 32/33, which needs State Bar resolution).
 * - judge_id attached from the caller-supplied judgeId (NOT from
 *   c.politician_source_id — that field is discarded here; it only exists to
 *   satisfy the adapter's PoliticianSource contract).
 */
export function mapContributionsToJudicialDonations(
  judgeId: string,
  contributions: ContributionInsert[]
): JudicialDonationRow[] {
  return contributions.map((c) => {
    const rec = c.raw_record as Record<string, unknown>;
    const ctribNameL = (rec['CTRIB_NAML'] as string | undefined) ?? '';
    const ctribNameF = (rec['CTRIB_NAMF'] as string | undefined) ?? '';
    const donorNameRaw = `${ctribNameL} ${ctribNameF}`.trim();

    return {
      judge_id: judgeId,
      donor_name_raw: donorNameRaw,
      donor_name_normalized: c.donor_name_normalized,
      donor_type: null,
      donor_employer_raw: (rec['CTRIB_EMP'] as string | undefined) ?? null,
      donor_occupation_raw: (rec['CTRIB_OCC'] as string | undefined) ?? null,
      amount: c.amount,
      contribution_date: c.contribution_date,
      data_source: c.data_source,
      source_transaction_id: c.source_transaction_id,
      source_url: CAL_ACCESS_SOURCE_URL,
      confidence_level: c.confidence_level,
      raw_record: c.raw_record,
    };
  });
}

// ---------------------------------------------------------------------------
// writeJudicialDonations — judicial-specific parameterized write
// ---------------------------------------------------------------------------

/**
 * writeJudicialDonations maps + writes ContributionInsert[] to judicial.donations.
 *
 * Copies the SHAPE of the adapter's upsertBatch() (parameterized $n placeholders,
 * ON CONFLICT (data_source, source_transaction_id) DO UPDATE, RETURNING (xmax = 0)
 * AS is_insert insert/skip counting) but targets judicial.donations with its own
 * column list. NEVER string-concatenates donor/employer/occupation free text into
 * SQL — parameterized $n only (V5 input validation; Cal-Access free-text fields
 * are attacker-influenceable).
 *
 * Does NOT call the adapter's own contributions-table write method (D-11) —
 * that writes transparent_motivations.contributions.
 *
 * ⚠ ON CONFLICT touches only updated_at: a stored row is never rewritten and never
 * removed, so a row from a wrong run stays until something deletes it. The ingest
 * script refuses to write beside rows from the pre-#659 adapter for that reason.
 */
export async function writeJudicialDonations(
  judgeId: string,
  contributions: ContributionInsert[]
): Promise<{ inserted: number; skipped: number }> {
  const rows = mapContributionsToJudicialDonations(judgeId, contributions);

  let inserted = 0;
  let skipped = 0;

  for (const row of rows) {
    const result = await pool.query<{ is_insert: boolean }>(
      `INSERT INTO judicial.donations
         (judge_id, donor_name_raw, donor_name_normalized, donor_type,
          donor_employer_raw, donor_occupation_raw, amount, contribution_date,
          data_source, source_transaction_id, source_url, confidence_level, raw_record)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13::jsonb)
       ON CONFLICT (data_source, source_transaction_id) DO UPDATE SET updated_at = NOW()
       RETURNING (xmax = 0) AS is_insert`,
      [
        row.judge_id,
        row.donor_name_raw,
        row.donor_name_normalized,
        row.donor_type,
        row.donor_employer_raw,
        row.donor_occupation_raw,
        row.amount,
        row.contribution_date,
        row.data_source,
        row.source_transaction_id,
        row.source_url,
        row.confidence_level,
        JSON.stringify(row.raw_record),
      ]
    );
    if (result.rows[0]?.is_insert) {
      inserted++;
    } else {
      skipped++;
    }
  }

  return { inserted, skipped };
}
