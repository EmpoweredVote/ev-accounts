import { describe, it, expect } from 'vitest';
import * as XLSX from 'xlsx';

/**
 * Guard on the ONE xlsx API path this repo uses, and on the reason the dependency does
 * not come from npm.
 *
 * `xlsx` is pinned to a SheetJS CDN tarball rather than a registry version, because npm's
 * newest published release is 0.18.5 and BOTH advisories against it are fixed only in
 * later versions SheetJS ships themselves:
 *
 *   GHSA-4r6h-8v6p-xvw6  prototype pollution  fixed 0.19.3
 *   GHSA-5pgg-2g8v-p4x9  ReDoS                fixed 0.20.2
 *
 * So `npm audit` reported `fixAvailable: false` and there was no in-registry upgrade.
 * A CDN URL dependency is the vendor's own documented route.
 *
 * The whole surface we depend on is two calls in scripts/discover-netfile-filers.ts:
 *
 *     XLSX.read(buffer, { type: 'buffer', cellDates: true })
 *     XLSX.utils.sheet_to_json(ws, { defval: '' })
 *
 * That script is hand-run and outside tsconfig's `include`, so nothing else in CI would
 * notice if a future version changed either call's behaviour. This test is what notices.
 * It asserts the two options that actually matter — cellDates giving Date objects, and
 * defval turning a blank cell into '' rather than dropping the key.
 */
describe('xlsx — the parse path discover-netfile-filers.ts depends on', () => {
  /** Build a workbook in memory and hand back the buffer, as the ZIP entry would. */
  function workbookBuffer(): Buffer {
    const ws = XLSX.utils.aoa_to_sheet([
      ['Filer Name', 'Filer ID', 'Filed Date', 'Note'],
      // 🔑 ROW SHORT BY ONE ON PURPOSE — no cell at all in the Note column. An empty
      // STRING cell would keep the key even without defval, which would make the defval
      // assertion below vacuous. Measured: a genuinely absent cell drops the key.
      ['Committee to Elect Someone', 'C-12345', new Date(Date.UTC(2026, 0, 15))],
      ['Another Committee', 'C-67890', new Date(Date.UTC(2026, 5, 30)), 'amended'],
    ]);
    const wb = XLSX.utils.book_new();
    XLSX.utils.book_append_sheet(wb, ws, 'Filers');
    return XLSX.write(wb, { type: 'buffer', bookType: 'xlsx' }) as Buffer;
  }

  it('reads a buffer and yields one object per data row', () => {
    const wb = XLSX.read(workbookBuffer(), { type: 'buffer', cellDates: true });
    const ws = wb.Sheets[wb.SheetNames[0]!]!;
    const rows = XLSX.utils.sheet_to_json<Record<string, unknown>>(ws, { defval: '' });

    expect(rows).toHaveLength(2);
    expect(rows[0]!['Filer Name']).toBe('Committee to Elect Someone');
    expect(rows[1]!['Filer ID']).toBe('C-67890');
  });

  it('honours cellDates, so a date cell arrives as a Date and not a serial number', () => {
    const wb = XLSX.read(workbookBuffer(), { type: 'buffer', cellDates: true });
    const ws = wb.Sheets[wb.SheetNames[0]!]!;
    const rows = XLSX.utils.sheet_to_json<Record<string, unknown>>(ws, { defval: '' });

    const filed = rows[0]!['Filed Date'];
    expect(filed).toBeInstanceOf(Date);
    expect((filed as Date).getUTCFullYear()).toBe(2026);
  });

  it('honours defval, so a blank cell is an empty string rather than a missing key', () => {
    // Verified rather than assumed: with the short row above, sheet_to_json without
    // defval returns keys ['Filer Name'] only; with defval it returns Note too. So this
    // assertion fails if the option stops working.
    const wb = XLSX.read(workbookBuffer(), { type: 'buffer', cellDates: true });
    const ws = wb.Sheets[wb.SheetNames[0]!]!;
    const rows = XLSX.utils.sheet_to_json<Record<string, unknown>>(ws, { defval: '' });

    expect(Object.keys(rows[0]!)).toContain('Note');
    expect(rows[0]!['Note']).toBe('');
  });
});
