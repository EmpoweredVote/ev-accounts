/**
 * cfaSummarySheet.ts — read an Indiana CFA-4 summary sheet (page 1 of every CFA-4 report).
 *
 * WHY: a $0 report has no Schedule A rows, so the contribution extractor writes nothing for it and
 * Essentials had no honest thing to say ("being processed"). The summary sheet carries the report's own
 * totals, which are the fact a voter needs: "Pre-Primary report, Jan 1 – Apr 10: $0 raised".
 *
 * This module only extracts and formats. It never writes to the database: rows reach
 * transparent_motivations.filed_report_summaries only through a reviewed migration
 * (scripts/cfa-summaries-to-migration.ts). Spec: docs/superpowers/specs/2026-09-24-filed-report-summaries-design.md
 *
 * 🔴 A BLANK line is null, never 0. The sheet distinguishes "wrote 0" from "left blank"; so do we.
 */

import * as fs from 'fs';
import Anthropic from '@anthropic-ai/sdk';

export const MONEY_FIELDS = [
  'cash_start',
  'receipts_itemized',
  'receipts_unitemized',
  'receipts_total',
  'receipts_ytd',
  'expenditures_total',
  'expenditures_ytd',
  'cash_end',
  'debts_owed_by',
  'debts_owed_to',
] as const;
export type MoneyField = (typeof MONEY_FIELDS)[number];

export const REPORT_TYPES = ['pre_primary', 'pre_election', 'annual', 'nomination', 'final', 'other'] as const;
export type ReportType = (typeof REPORT_TYPES)[number];

export interface SummarySheet {
  form: 'CFA-4';
  report_type: ReportType;
  is_amendment: boolean;
  period_start: string | null;
  period_end: string | null;
  filed_on: string | null;
  filed_with: string | null;
  money: Record<MoneyField, number | null>;
  /** Fields the model was unsure of, plus any it returned in an unreadable form. */
  low_confidence_fields: string[];
}

const DATE_RE = /^\d{4}-\d{2}-\d{2}$/;

function asDate(v: unknown): string | null {
  return typeof v === 'string' && DATE_RE.test(v) ? v : null;
}

function asText(v: unknown): string | null {
  return typeof v === 'string' && v.trim() !== '' ? v.trim() : null;
}

/**
 * Validates the model's JSON. Returns null only when the report type is unusable; an unreadable
 * amount becomes null AND is added to low_confidence_fields, so review catches it instead of a guess.
 */
export function parseSummarySheetJson(raw: unknown): SummarySheet | null {
  if (!raw || typeof raw !== 'object') return null;
  const o = raw as Record<string, unknown>;
  if (!REPORT_TYPES.includes(o.report_type as ReportType)) return null;

  const low = new Set<string>(
    Array.isArray(o.low_confidence_fields) ? o.low_confidence_fields.filter((x): x is string => typeof x === 'string') : []
  );

  const money = {} as Record<MoneyField, number | null>;
  for (const f of MONEY_FIELDS) {
    const v = o[f];
    if (v === null || v === undefined || v === '') {
      money[f] = null;
    } else {
      const n = typeof v === 'number' ? v : Number(String(v).replace(/[$,\s]/g, ''));
      if (Number.isFinite(n) && n >= 0) {
        money[f] = Math.round(n * 100) / 100;
      } else {
        money[f] = null;
        low.add(f);
      }
    }
  }

  return {
    form: 'CFA-4',
    report_type: o.report_type as ReportType,
    is_amendment: o.is_amendment === true,
    period_start: asDate(o.period_start),
    period_end: asDate(o.period_end),
    filed_on: asDate(o.filed_on),
    filed_with: asText(o.filed_with),
    money,
    low_confidence_fields: [...low],
  };
}

/** Why a person must look at this sheet before it can reach a migration. [] means clean. */
export function reviewReasons(s: SummarySheet): string[] {
  const reasons: string[] = [];
  if (s.low_confidence_fields.length > 0) reasons.push(`low confidence: ${s.low_confidence_fields.join(' ')}`);
  if (!s.period_start || !s.period_end) reasons.push('period missing (line 12)');
  if (s.period_start && s.period_end && s.period_end < s.period_start) reasons.push('period ends before it starts');
  if (!s.filed_with) reasons.push('filed_with missing (clerk stamp)');
  const { receipts_itemized: a, receipts_unitemized: b, receipts_total: c } = s.money;
  if (a !== null && b !== null && c !== null && Math.abs(a + b - c) > 0.005) {
    reasons.push(`15c (${c}) is not 15a + 15b (${a} + ${b})`);
  }
  return reasons;
}

export const SUMMARY_CSV_COLUMNS: readonly string[] = [
  'folder',
  'pdf',
  'politician_id',
  'politician_name',
  'form',
  'report_type',
  'is_amendment',
  'period_start',
  'period_end',
  'filed_on',
  'filed_with',
  ...MONEY_FIELDS,
  'low_confidence_fields',
  'needs_review',
  'review_reasons',
];

/** One CSV row, in SUMMARY_CSV_COLUMNS order. Money: '' for blank, else two decimals. */
export function summaryCsvRow(
  ctx: { folder: string; pdf: string; politician_id: string; politician_name: string },
  s: SummarySheet
): string[] {
  const reasons = reviewReasons(s);
  return [
    ctx.folder,
    ctx.pdf,
    ctx.politician_id,
    ctx.politician_name,
    s.form,
    s.report_type,
    s.is_amendment ? 'yes' : 'no',
    s.period_start ?? '',
    s.period_end ?? '',
    s.filed_on ?? '',
    s.filed_with ?? '',
    ...MONEY_FIELDS.map((f) => (s.money[f] === null ? '' : s.money[f]!.toFixed(2))),
    s.low_confidence_fields.join(' '),
    reasons.length > 0 ? 'yes' : 'no',
    reasons.join('; '),
  ];
}

// ---------------------------------------------------------------------------
// Vision call
// ---------------------------------------------------------------------------

const MODEL = 'claude-haiku-4-5-20251001';
const COST_PER_INPUT_TOKEN = 1.0 / 1_000_000;
const COST_PER_OUTPUT_TOKEN = 5.0 / 1_000_000;

const SYSTEM_PROMPT = `You read the summary sheet (page 1) of an Indiana CFA-4 campaign finance report.
Return ONLY a JSON object, no markdown. Use null for any line that is BLANK on the sheet — a blank is not 0.
Write 0 only where the sheet shows a 0. Amounts are plain numbers in dollars.
List in low_confidence_fields the key of every value you are not sure you read correctly.

{
  "report_type": "pre_primary | pre_election | annual | nomination | final | other",   // line 11 checkbox; "Final / Disbands" = final
  "is_amendment": true | false,                         // "IS THIS AN AMENDMENT?" box
  "period_start": "YYYY-MM-DD", "period_end": "YYYY-MM-DD",   // line 12 From / Through
  "filed_on": "YYYY-MM-DD or null",                     // the clerk's FILED stamp date
  "filed_with": "string or null",                       // the office on the FILED stamp, e.g. "Monroe Circuit Court Clerk"
  "cash_start": number|null,            // line 13, column A
  "receipts_itemized": number|null,     // line 15a, column A
  "receipts_unitemized": number|null,   // line 15b, column A
  "receipts_total": number|null,        // line 15c, column A
  "receipts_ytd": number|null,          // line 15c, column B
  "expenditures_total": number|null,    // line 17c, column A
  "expenditures_ytd": number|null,      // line 17c, column B
  "cash_end": number|null,              // line 18, column A
  "debts_owed_by": number|null,         // line 19
  "debts_owed_to": number|null,         // line 20
  "low_confidence_fields": ["key", ...]
}`;

function stripCodeFences(raw: string): string {
  return raw.trim().replace(/^```(?:json)?\s*/i, '').replace(/\s*```$/, '');
}

/** Reads one page image. Never throws: a failure returns sheet=null with a warning, for the review CSV. */
export async function extractSummarySheet(
  imagePath: string,
  jurisdictionHint: string
): Promise<{ sheet: SummarySheet | null; costUsd: number; warning?: string }> {
  const client = new Anthropic({ apiKey: process.env.ANTHROPIC_API_KEY });
  try {
    const data = fs.readFileSync(imagePath).toString('base64');
    const response = await client.messages.create({
      model: MODEL,
      max_tokens: 1024,
      system: SYSTEM_PROMPT,
      messages: [
        {
          role: 'user',
          content: [
            { type: 'image', source: { type: 'base64', media_type: 'image/png', data } },
            { type: 'text', text: `Jurisdiction: ${jurisdictionHint}. Read the CFA-4 summary sheet on this page.` },
          ],
        },
      ],
    });
    const costUsd =
      (response.usage?.input_tokens ?? 0) * COST_PER_INPUT_TOKEN +
      (response.usage?.output_tokens ?? 0) * COST_PER_OUTPUT_TOKEN;
    const text = response.content
      .filter((b) => b.type === 'text')
      .map((b) => (b as { type: 'text'; text: string }).text)
      .join('');
    let parsed: unknown;
    try {
      parsed = JSON.parse(stripCodeFences(text));
    } catch {
      return { sheet: null, costUsd, warning: `summary sheet: model returned non-JSON: ${text.slice(0, 120)}` };
    }
    const sheet = parseSummarySheetJson(parsed);
    return sheet
      ? { sheet, costUsd }
      : { sheet: null, costUsd, warning: 'summary sheet: unusable report_type (not a CFA-4 summary page?)' };
  } catch (err: unknown) {
    return { sheet: null, costUsd: 0, warning: `summary sheet: ${err instanceof Error ? err.message : String(err)}` };
  }
}
