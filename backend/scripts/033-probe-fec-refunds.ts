/**
 * 033-probe-fec-refunds.ts — settle empirically whether FEC transaction type 22Y
 * (contribution refund to an individual, F3 Schedule B line 20A) is retrievable from
 * the FEC API, and whether the two donors flagged over-limit in the 2026-07-28
 * exploration were refunded (quick-260729-0jn, EXPL-C1 / CON-07).
 *
 * SAFETY (CON-01): this script MUST NOT import `../src/lib/db.js` and never reads
 * `DATABASE_URL`. It touches only the FEC public API. `FEC_API_KEY` is read from
 * process.env (via dotenv) and is NEVER printed, logged, or written anywhere — every
 * URL is redacted (`api_key=REDACTED`) before it is logged.
 *
 * Rate-limit safety (T-0jn-04): `acquireFecSlot()` (the SAME shared limiter the 6-hour
 * FEC cron uses) is awaited before every outbound fetch, and a hard cap of 30 total
 * requests aborts the run past that budget — a 429 collision with the cron is a known
 * failure mode this guards against.
 *
 * Usage:
 *   tsx scripts/033-probe-fec-refunds.ts <committeeId> [<donorSurname1> <donorSurname2> ...]
 *
 * The committee ID must be resolved from data first (see the findings doc / Step A of
 * this task) — never hand this script a remembered/floated ID without confirming it.
 */

import 'dotenv/config';
import { acquireFecSlot } from '../src/lib/fecRateLimiter.js';

const MAX_REQUESTS = 30;
let requestCount = 0;

function redact(url: string, apiKey: string): string {
  return apiKey ? url.split(apiKey).join('REDACTED') : url;
}

async function fecFetch(url: string, apiKey: string): Promise<{ status: number; ok: boolean; body: unknown }> {
  requestCount++;
  if (requestCount > MAX_REQUESTS) {
    throw new Error(`[033-probe] request cap (${MAX_REQUESTS}) exceeded — aborting before firing another request (T-0jn-04)`);
  }
  await acquireFecSlot();
  console.log(`[033-probe][req ${requestCount}/${MAX_REQUESTS}] GET ${redact(url, apiKey)}`);
  const res = await fetch(url, { signal: AbortSignal.timeout(30_000) });
  let body: unknown = null;
  try {
    body = await res.json();
  } catch {
    body = null;
  }
  if (!res.ok) {
    console.log(`[033-probe] HTTP ${res.status} — body: ${JSON.stringify(body).slice(0, 500)}`);
  }
  return { status: res.status, ok: res.ok, body };
}

function buildUrl(base: string, params: Record<string, string>, apiKey: string): string {
  const usp = new URLSearchParams(params);
  usp.set('api_key', apiKey); // key added LAST, per T-0jn-02
  return `${base}?${usp.toString()}`;
}

interface ScheduleBRow {
  disbursement_date?: string;
  disbursement_amount?: number;
  recipient_name?: string;
  line_number?: string;
  disbursement_description?: string;
  disbursement_type?: string;
  memo_text?: string;
}

interface ScheduleBResponse {
  pagination?: { count?: number; pages?: number };
  results?: ScheduleBRow[];
}

interface ScheduleARow {
  contributor_name?: string;
  contribution_receipt_date?: string;
  contribution_receipt_amount?: number;
  election_type?: string;
  election_type_full?: string;
}

interface ScheduleAResponse {
  pagination?: { count?: number };
  results?: ScheduleARow[];
}

function printRows(label: string, rows: unknown[]): void {
  if (rows.length === 0) {
    console.log(`[033-probe] ${label}: no rows`);
    return;
  }
  console.log(`[033-probe] ${label}: ${rows.length} row(s) shown:`);
  for (const r of rows) console.log('  ', JSON.stringify(r));
}

async function main(): Promise<void> {
  const apiKey = process.env.FEC_API_KEY;
  if (!apiKey) {
    console.error('[033-probe] FEC_API_KEY not set in environment (.env) — aborting');
    process.exit(1);
  }

  const [, , committeeId, ...surnames] = process.argv;
  if (!committeeId) {
    console.error('usage: tsx scripts/033-probe-fec-refunds.ts <committeeId> [<donorSurname1> <donorSurname2> ...]');
    process.exit(1);
  }

  console.log(`[033-probe] === FEC 22Y refund probe: committee=${committeeId} cycle=2022 surnames=[${surnames.join(', ')}] ===`);

  // --- Probe 1: whole-committee schedule_b for the cycle -------------------
  const url1 = buildUrl('https://api.open.fec.gov/v1/schedules/schedule_b/', {
    committee_id: committeeId,
    two_year_transaction_period: '2022',
    per_page: '30',
  }, apiKey);
  const r1 = await fecFetch(url1, apiKey);
  const body1 = r1.body as ScheduleBResponse;
  console.log(`[033-probe] Probe 1 — pagination.count=${body1?.pagination?.count ?? 'N/A'}`);
  const lineNumbers = new Map<string, number>();
  const disbTypes = new Map<string, number>();
  for (const row of body1?.results ?? []) {
    lineNumbers.set(row.line_number ?? '(blank)', (lineNumbers.get(row.line_number ?? '(blank)') ?? 0) + 1);
    disbTypes.set(row.disbursement_type ?? '(blank)', (disbTypes.get(row.disbursement_type ?? '(blank)') ?? 0) + 1);
  }
  console.log(`[033-probe] Probe 1 — line_number distribution (this page): ${JSON.stringify([...lineNumbers.entries()])}`);
  console.log(`[033-probe] Probe 1 — disbursement_type distribution (this page): ${JSON.stringify([...disbTypes.entries()])}`);
  printRows('Probe 1 sample rows', (body1?.results ?? []).slice(0, 5).map((r) => ({
    date: r.disbursement_date, amount: r.disbursement_amount, recipient: r.recipient_name,
    line: r.line_number, type: r.disbursement_type, desc: r.disbursement_description,
  })));

  // --- Probe 2: narrowed to the F3 refund-to-individual line ---------------
  const url2 = buildUrl('https://api.open.fec.gov/v1/schedules/schedule_b/', {
    committee_id: committeeId,
    two_year_transaction_period: '2022',
    line_number: 'F3-20A',
    per_page: '30',
  }, apiKey);
  const r2 = await fecFetch(url2, apiKey);
  if (!r2.ok) {
    console.log(`[033-probe] Probe 2 — line_number=F3-20A REJECTED by the API (HTTP ${r2.status}). This rejection is itself a finding — see body above.`);
  } else {
    const body2 = r2.body as ScheduleBResponse;
    console.log(`[033-probe] Probe 2 — pagination.count=${body2?.pagination?.count ?? 'N/A'}`);
    printRows('Probe 2 sample rows (line_number=F3-20A)', (body2?.results ?? []).slice(0, 10).map((r) => ({
      date: r.disbursement_date, amount: r.disbursement_amount, recipient: r.recipient_name,
      line: r.line_number, desc: r.disbursement_description,
    })));
  }

  // Scan probe-1 + probe-2 rows for refund language in disbursement_description, regardless
  // of line_number filter success, as a second independent signal.
  const allRowsSoFar = [...(body1?.results ?? []), ...((r2.ok ? (r2.body as ScheduleBResponse)?.results : []) ?? [])];
  const refundLike = allRowsSoFar.filter((r) => /refund/i.test(r.disbursement_description ?? '') || /refund/i.test(r.memo_text ?? ''));
  console.log(`[033-probe] disbursement_description/memo_text refund-language scan: ${refundLike.length} matching row(s) out of ${allRowsSoFar.length} sampled`);
  printRows('refund-language matches', refundLike.slice(0, 10));

  // --- Probe 3: per-donor recipient_name search -----------------------------
  for (const surname of surnames) {
    const url3 = buildUrl('https://api.open.fec.gov/v1/schedules/schedule_b/', {
      committee_id: committeeId,
      two_year_transaction_period: '2022',
      recipient_name: surname,
      per_page: '100',
    }, apiKey);
    const r3 = await fecFetch(url3, apiKey);
    if (!r3.ok) {
      console.log(`[033-probe] Probe 3 (${surname}) — HTTP ${r3.status}, see body above`);
      continue;
    }
    const body3 = r3.body as ScheduleBResponse;
    const count = body3?.pagination?.count ?? 0;
    const rows = body3?.results ?? [];
    if (count === 0 || rows.length === 0) {
      console.log(`[033-probe] Probe 3 (${surname}) — no rows (pagination.count=${count}): this donor does NOT appear as a recipient_name in schedule_b for this committee/cycle`);
    } else {
      const sum = rows.reduce((acc, r) => acc + (r.disbursement_amount ?? 0), 0);
      const truncated = count > rows.length;
      console.log(`[033-probe] Probe 3 (${surname}) — pagination.count=${count}, sum of ${rows.length} returned row(s)=${sum.toFixed(2)}${truncated ? ` (NOTE: count exceeds rows returned on this page — sum is a LOWER BOUND, not the full total)` : ' (all rows on this page — sum is the FULL total for this donor/committee)'}`);
      printRows(`Probe 3 (${surname}) — recipient_name hits`, rows.map((r) => ({
        date: r.disbursement_date, amount: r.disbursement_amount, recipient: r.recipient_name, line: r.line_number,
      })));
    }
  }

  // --- Probe 4: one schedule_a record for the same committee — election_type format ---
  const url4 = buildUrl('https://api.open.fec.gov/v1/schedules/schedule_a/', {
    committee_id: committeeId,
    two_year_transaction_period: '2022',
    per_page: '1',
  }, apiKey);
  const r4 = await fecFetch(url4, apiKey);
  const body4 = r4.body as ScheduleAResponse;
  const sa = body4?.results?.[0];
  console.log(`[033-probe] Probe 4 — schedule_a sample: election_type=${sa?.election_type ?? '(absent)'} election_type_full=${sa?.election_type_full ?? '(absent)'} contributor=${sa?.contributor_name ?? '(absent)'}`);

  console.log(`[033-probe] === done — ${requestCount}/${MAX_REQUESTS} requests used ===`);
}

main().catch((err) => {
  console.error('[033-probe] Fatal:', err instanceof Error ? err.message : err);
  process.exit(1);
});
