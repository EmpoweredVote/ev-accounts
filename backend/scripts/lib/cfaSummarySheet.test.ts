import { describe, it, expect } from 'vitest';
import {
  parseSummarySheetJson,
  reviewReasons,
  summaryCsvRow,
  SUMMARY_CSV_COLUMNS,
} from './cfaSummarySheet.js';

// Dorothy Granger's CFA-4 pre-primary 2026 as the vision model should return it: 15a, 15b and 17 are
// blank on the sheet (null), 15c and 18 read 0.
const GRANGER = {
  report_type: 'pre_primary',
  is_amendment: false,
  period_start: '2026-01-01',
  period_end: '2026-04-10',
  filed_on: '2026-04-15',
  filed_with: 'Monroe Circuit Court Clerk',
  cash_start: 0,
  receipts_itemized: null,
  receipts_unitemized: null,
  receipts_total: 0,
  receipts_ytd: 0,
  expenditures_total: null,
  expenditures_ytd: null,
  cash_end: 0,
  debts_owed_by: 0,
  debts_owed_to: 0,
  low_confidence_fields: [],
};

const CTX = { folder: 'Granger, Dorothy', pdf: 'CFA-4_Pre-Primary2026.pdf', politician_id: 'p-1', politician_name: 'Dorothy Granger' };

describe('parseSummarySheetJson', () => {
  it('keeps a blank line null and a written zero as 0', () => {
    const s = parseSummarySheetJson(GRANGER)!;
    expect(s.money.receipts_itemized).toBeNull();
    expect(s.money.receipts_total).toBe(0);
    expect(s.form).toBe('CFA-4');
    expect(reviewReasons(s)).toEqual([]);
  });

  it('reads numeric strings, and flags an unreadable amount instead of guessing', () => {
    const s = parseSummarySheetJson({ ...GRANGER, cash_end: '12.5', debts_owed_by: 'abc' })!;
    expect(s.money.cash_end).toBe(12.5);
    expect(s.money.debts_owed_by).toBeNull();
    expect(s.low_confidence_fields).toContain('debts_owed_by');
    expect(reviewReasons(s).length).toBeGreaterThan(0);
  });

  it('rejects an unknown report type', () => {
    expect(parseSummarySheetJson({ ...GRANGER, report_type: 'quarterly' })).toBeNull();
  });
});

describe('reviewReasons', () => {
  it('flags 15c that is not 15a + 15b', () => {
    const s = parseSummarySheetJson({ ...GRANGER, receipts_itemized: 100, receipts_unitemized: 50, receipts_total: 200 })!;
    expect(reviewReasons(s).join(' ')).toMatch(/15c/);
  });

  it('flags a missing period', () => {
    const s = parseSummarySheetJson({ ...GRANGER, period_end: null })!;
    expect(reviewReasons(s).join(' ')).toMatch(/period/);
  });
});

describe('summaryCsvRow', () => {
  it('renders null as empty, zero as 0.00, and matches the header length', () => {
    const row = summaryCsvRow(CTX, parseSummarySheetJson(GRANGER)!);
    expect(row).toHaveLength(SUMMARY_CSV_COLUMNS.length);
    const cell = (name: string) => row[SUMMARY_CSV_COLUMNS.indexOf(name)];
    expect(cell('receipts_itemized')).toBe('');
    expect(cell('receipts_total')).toBe('0.00');
    expect(cell('needs_review')).toBe('no');
  });
});

// Granger's sheet exactly as written: 15c and 17c BLANK, lines 13, 16 and 18 show 0.
const GRANGER_AS_WRITTEN = {
  ...GRANGER,
  receipts_total: null,
  receipts_ytd: null,
  total_available: 0,
};

describe('derived totals — a blank 15c / 17c filled from the sheet\'s own arithmetic', () => {
  it('derives raised = 16 − 13 and spent = 16 − 18, and says so', () => {
    const s = parseSummarySheetJson(GRANGER_AS_WRITTEN)!;
    expect(s.money.receipts_total).toBe(0);
    expect(s.money.expenditures_total).toBe(0);
    expect(s.derived).toEqual({ receipts_total: true, expenditures_total: true });
    expect(reviewReasons(s)).toEqual([]);
  });

  it('never marks a written 15c as derived', () => {
    const s = parseSummarySheetJson({ ...GRANGER_AS_WRITTEN, receipts_total: 0 })!;
    expect(s.derived.receipts_total).toBe(false);
  });

  it('does not derive without line 16, and leaves the blank blank', () => {
    const s = parseSummarySheetJson({ ...GRANGER_AS_WRITTEN, total_available: null })!;
    expect(s.money.receipts_total).toBeNull();
    expect(s.derived.receipts_total).toBe(false);
  });

  it('refuses a negative derivation and sends the sheet to review', () => {
    const s = parseSummarySheetJson({ ...GRANGER_AS_WRITTEN, cash_start: 50, total_available: 20 })!;
    expect(s.money.receipts_total).toBeNull();
    expect(reviewReasons(s).join(' ')).toMatch(/line 16/);
  });

  it('flags a sheet whose written 15c does not add up to line 16', () => {
    const s = parseSummarySheetJson({ ...GRANGER_AS_WRITTEN, receipts_total: 100, cash_start: 0, total_available: 90 })!;
    expect(reviewReasons(s).join(' ')).toMatch(/line 16/);
  });

  it('carries the derived flags into the CSV', () => {
    const row = summaryCsvRow(CTX, parseSummarySheetJson(GRANGER_AS_WRITTEN)!);
    expect(row[SUMMARY_CSV_COLUMNS.indexOf('receipts_total_derived')]).toBe('yes');
    expect(row[SUMMARY_CSV_COLUMNS.indexOf('total_available')]).toBe('0.00');
  });
});
