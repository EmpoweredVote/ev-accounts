/**
 * cfaSummaryMigration.ts — turn a REVIEWED summaries CSV (from parse-local-cfa.ts) into a data migration
 * for transparent_motivations.filed_report_summaries.
 *
 * The CSV is reviewed by a person against the PDFs first; any row still carrying needs_review=yes is
 * refused, so an OCR guess cannot reach prod without a human flipping that flag.
 * Spec: docs/superpowers/specs/2026-09-24-filed-report-summaries-design.md
 */

import { MONEY_FIELDS, REPORT_TYPES } from './cfaSummarySheet.js';

/** RFC-4180 CSV → one object per data row, keyed by the header. */
export function parseCsv(text: string): Record<string, string>[] {
  const records: string[][] = [];
  let field = '';
  let record: string[] = [];
  let quoted = false;
  for (let i = 0; i < text.length; i++) {
    const ch = text[i];
    if (quoted) {
      if (ch === '"' && text[i + 1] === '"') {
        field += '"';
        i++;
      } else if (ch === '"') {
        quoted = false;
      } else {
        field += ch;
      }
    } else if (ch === '"') {
      quoted = true;
    } else if (ch === ',') {
      record.push(field);
      field = '';
    } else if (ch === '\n' || ch === '\r') {
      if (ch === '\r' && text[i + 1] === '\n') i++;
      record.push(field);
      field = '';
      if (record.some((f) => f !== '')) records.push(record);
      record = [];
    } else {
      field += ch;
    }
  }
  if (field !== '' || record.length > 0) {
    record.push(field);
    if (record.some((f) => f !== '')) records.push(record);
  }
  const [header, ...rows] = records;
  if (!header) return [];
  return rows.map((r) => Object.fromEntries(header.map((h, i) => [h, r[i] ?? ''])));
}

const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
const DATE_RE = /^\d{4}-\d{2}-\d{2}$/;
const MONEY_RE = /^\d+(\.\d{1,2})?$/;
const SLOT_RE = /^CA_\d{4}$/;

const q = (s: string) => `'${s.replace(/'/g, "''")}'`;

function fail(rowNo: number, msg: string): never {
  throw new Error(`row ${rowNo}: ${msg}`);
}

/** Builds the full migration text. Throws on the first bad row; nothing partial is produced. */
export function buildMigrationSql(
  rows: Record<string, string>[],
  opts: { slot: string; sourceSystem: string; date: string }
): string {
  if (!SLOT_RE.test(opts.slot)) throw new Error(`slot must look like CA_0000, got ${opts.slot}`);
  if (!/^[A-Za-z0-9_]+$/.test(opts.sourceSystem)) throw new Error(`bad source system ${opts.sourceSystem}`);
  if (rows.length === 0) throw new Error('no rows to write');

  let receiptsSum = 0;
  const inserts = rows.map((r, idx) => {
    const n = idx + 1;
    if (r.needs_review !== 'no') fail(n, `needs_review is "${r.needs_review}" — review it against the PDF first`);
    if (!UUID_RE.test(r.politician_id)) fail(n, `politician_id is not a uuid: ${r.politician_id}`);
    if (r.form !== 'CFA-4') fail(n, `form must be CFA-4, got ${r.form}`);
    if (!(REPORT_TYPES as readonly string[]).includes(r.report_type)) fail(n, `bad report_type ${r.report_type}`);
    if (r.is_amendment !== 'yes' && r.is_amendment !== 'no') fail(n, `is_amendment must be yes/no`);
    if (!DATE_RE.test(r.period_start) || !DATE_RE.test(r.period_end)) fail(n, 'period dates missing or malformed');
    if (r.filed_on !== '' && !DATE_RE.test(r.filed_on)) fail(n, 'filed_on malformed');
    if (r.filed_with.trim() === '') fail(n, 'filed_with missing');
    const money = MONEY_FIELDS.map((f) => {
      const v = (r[f] ?? '').trim();
      if (v === '') return 'NULL';
      if (!MONEY_RE.test(v)) fail(n, `${f} is not an amount: ${v}`);
      return q(v);
    });
    receiptsSum += r.receipts_total.trim() === '' ? 0 : Number(r.receipts_total);
    const sourcePdf = `${r.folder}/${r.pdf}`;
    return `-- ${n}. ${r.politician_name} — ${r.report_type} ${r.period_start}..${r.period_end} (${sourcePdf})
INSERT INTO transparent_motivations.filed_report_summaries
  (politician_source_id, form, report_type, is_amendment, period_start, period_end, filed_on, filed_with,
   ${MONEY_FIELDS.join(', ')}, source_pdf, source)
SELECT ps.id, 'CFA-4', ${q(r.report_type)}, ${r.is_amendment === 'yes'}, ${q(r.period_start)}, ${q(r.period_end)},
       ${r.filed_on === '' ? 'NULL' : q(r.filed_on)}, ${q(r.filed_with.trim())},
       ${money.join(', ')}, ${q(sourcePdf)}, ${q(opts.slot)}
  FROM transparent_motivations.politician_sources ps
 WHERE ps.essentials_politician_id = ${q(r.politician_id)}
   AND ps.source_system = ${q(opts.sourceSystem)}
   AND ps.research_status = 'confirmed'
   AND ps.source_type = 'candidate_committee'
ON CONFLICT ON CONSTRAINT filed_report_summaries_uniq DO NOTHING;`;
  });

  return `-- ${opts.slot}: filed CFA-4 summary sheets (${rows.length} report${rows.length === 1 ? '' : 's'}).
-- Generated ${opts.date} by scripts/cfa-summaries-to-migration.ts from a CSV reviewed against the PDFs.
-- Spec: docs/superpowers/specs/2026-09-24-filed-report-summaries-design.md
-- Each row attaches to the politician's ONE confirmed ${opts.sourceSystem} candidate committee. Zero or two
-- such links would write 0 or 2 rows, which the gate below refuses. NULL = the line was blank on the sheet.
-- IDEMPOTENT: ON CONFLICT DO NOTHING; a re-run writes nothing and the gate still passes.

${inserts.join('\n\n')}

DO $$
DECLARE n int; s numeric;
BEGIN
  SELECT count(*), COALESCE(sum(COALESCE(receipts_total, 0)), 0) INTO n, s
    FROM transparent_motivations.filed_report_summaries WHERE source = ${q(opts.slot)};
  IF n <> ${rows.length} THEN RAISE EXCEPTION '${opts.slot}: expected ${rows.length} rows, found %', n; END IF;
  IF s <> ${receiptsSum.toFixed(2)} THEN RAISE EXCEPTION '${opts.slot}: receipts_total sum % <> ${receiptsSum.toFixed(2)}', s; END IF;
END $$;
`;
}
