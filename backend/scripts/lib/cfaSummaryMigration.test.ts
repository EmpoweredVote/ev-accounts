import { describe, it, expect } from 'vitest';
import { parseCsv, buildMigrationSql } from './cfaSummaryMigration.js';
import { SUMMARY_CSV_COLUMNS } from './cfaSummarySheet.js';

const GRANGER: Record<string, string> = {
  folder: 'Granger, Dorothy',
  pdf: 'CFA-4_Pre-Primary2026.pdf',
  politician_id: '11111111-2222-4333-8444-555555555555',
  politician_name: 'Dorothy Granger',
  form: 'CFA-4',
  report_type: 'pre_primary',
  is_amendment: 'no',
  period_start: '2026-01-01',
  period_end: '2026-04-10',
  filed_on: '2026-04-15',
  filed_with: 'Monroe Circuit Court Clerk',
  cash_start: '0.00',
  receipts_itemized: '',
  receipts_unitemized: '',
  receipts_total: '0.00',
  receipts_ytd: '0.00',
  expenditures_total: '',
  expenditures_ytd: '',
  cash_end: '0.00',
  debts_owed_by: '0.00',
  debts_owed_to: '0.00',
  total_available: '0.00',
  receipts_total_derived: 'no',
  expenditures_total_derived: 'no',
  low_confidence_fields: '',
  needs_review: 'no',
  review_reasons: '',
};

const OPTS = { slot: 'CA_0999', sourceSystem: 'IN_MONROE_COUNTY_LOCAL', date: '2026-09-24' };

describe('buildMigrationSql', () => {
  it('writes blanks as NULL, zeros as 0.00, and gates on the row count', () => {
    const sql = buildMigrationSql([GRANGER], OPTS);
    expect(sql).toMatch(/receipts_itemized[\s\S]*NULL/);
    expect(sql).toContain("'0.00'");
    expect(sql).toContain("ps.source_system = 'IN_MONROE_COUNTY_LOCAL'");
    expect(sql).toContain("ps.research_status = 'confirmed'");
    expect(sql).toMatch(/IF n <> 1 THEN RAISE EXCEPTION/);
    expect(sql).toContain('ON CONFLICT ON CONSTRAINT filed_report_summaries_uniq DO NOTHING');
  });

  it('refuses a row still flagged for review', () => {
    expect(() => buildMigrationSql([{ ...GRANGER, needs_review: 'yes' }], OPTS)).toThrow(/needs_review/);
  });

  it("doubles a quote in text", () => {
    const sql = buildMigrationSql([{ ...GRANGER, filed_with: "O'Brien County Clerk" }], OPTS);
    expect(sql).toContain("'O''Brien County Clerk'");
  });

  it('refuses a malformed politician id', () => {
    expect(() => buildMigrationSql([{ ...GRANGER, politician_id: "x'; DROP TABLE" }], OPTS)).toThrow(/politician_id/);
  });

  it('refuses an empty batch', () => {
    expect(() => buildMigrationSql([], OPTS)).toThrow(/no rows/);
  });
});

describe('buildMigrationSql — derived totals', () => {
  it('writes the derived flags and line 16', () => {
    const sql = buildMigrationSql([{ ...GRANGER, receipts_total_derived: 'yes', expenditures_total: '0.00', expenditures_total_derived: 'yes' }], OPTS);
    expect(sql).toContain('receipts_total_derived, expenditures_total_derived');
    expect(sql).toMatch(/total_available/);
    expect(sql).toMatch(/, true, true, 'internal|, true, true,/);
  });

  it('refuses a derived flag that is not yes/no', () => {
    expect(() => buildMigrationSql([{ ...GRANGER, receipts_total_derived: '' }], OPTS)).toThrow(/derived/);
  });
});

describe('parseCsv', () => {
  it('reads a quoted comma and a doubled quote', () => {
    const header = SUMMARY_CSV_COLUMNS.join(',');
    const values = SUMMARY_CSV_COLUMNS.map((c) => (c === 'folder' ? '"Granger, Dorothy"' : c === 'filed_with' ? '"say ""hi"""' : 'v'));
    const rows = parseCsv(`${header}\n${values.join(',')}\n`);
    expect(rows).toHaveLength(1);
    expect(rows[0].folder).toBe('Granger, Dorothy');
    expect(rows[0].filed_with).toBe('say "hi"');
  });
});
