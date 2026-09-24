# Filed Report Summaries Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the false "being processed" banner for politicians whose filed report shows no itemized contributions with the report's own summary-sheet totals.

**Architecture:** A new `transparent_motivations.filed_report_summaries` table holds one row per filed summary sheet. `detectCoverageStatus` returns `'filed_reports'` (with the newest reports) when a confirmed own-fundraising link has one; Essentials renders a panel for it. Rows arrive only through reviewed CA_ migrations generated from an importer CSV.

**Tech Stack:** Postgres (Supabase), TypeScript/Express backend (vitest), `tsx` scripts, Anthropic SDK (Haiku 4.5 vision), React (essentials repo, vitest).

**Spec:** `docs/superpowers/specs/2026-09-24-filed-report-summaries-design.md`

## Global Constraints

- Money column is NULL when the sheet's line is blank; never coerce to 0. The UI renders NULL as "—".
- Only links matching `OWN_FUNDRAISING_SQL` (`ps.research_status = 'confirmed' AND ps.source_type = 'candidate_committee'`) count.
- API response fields come from an explicit whitelist; never spread DB rows; never expose `politician_source_id` or `source_pdf`.
- `filed_reports` is present on the summary response only when `coverage_status = 'filed_reports'`.
- Migration numbers come from `npm run steward --prefix backend -- slot CA --purpose "..."`. Never count.
- Migrations: idempotent, end with a `DO $$ … RAISE EXCEPTION` post-verify gate, dry-run on prod as `BEGIN; … ROLLBACK;` first.
- Commit with an explicit pathspec: `git commit -F msg -- <paths>`. Claim `county:18105` before any prod write.
- The importer writes NO summaries to the database; only migrations do.

## File Structure

| File | Responsibility |
|---|---|
| `backend/migrations/CA_NNNN_filed_report_summaries_table.sql` (create) | Table, constraints, RLS default-deny |
| `backend/src/lib/campaignFinanceService.ts` (modify) | `FiledReportResponse`, `getFiledReports()`, status rule, attach to summary |
| `backend/src/lib/campaignFinanceService.test.ts` (modify) | Status-rule + whitelist tests |
| `backend/scripts/lib/cfaSummarySheet.ts` (create) | Summary-sheet types, JSON validation, review rule, CSV row format, vision call |
| `backend/scripts/lib/cfaSummarySheet.test.ts` (create) | Pure-function tests |
| `backend/scripts/lib/cfaSummaryMigration.ts` (create) | CSV parse + migration SQL builder (pure) |
| `backend/scripts/lib/cfaSummaryMigration.test.ts` (create) | Builder tests |
| `backend/scripts/cfa-summaries-to-migration.ts` (create) | CLI wrapper for the builder |
| `backend/scripts/parse-local-cfa.ts` (modify) | Call the summary extractor on every PDF; write summaries CSV |
| `backend/migrations/CA_MMMM_filed_report_summaries_granger.sql` (create, generated) | First data row — positive control |
| essentials `src/components/CampaignFinance/FiledReportsPanel.jsx` (create) | Panel |
| essentials `src/components/CampaignFinance/FiledReportsPanel.test.jsx` (create) | Panel tests |
| essentials `src/components/CampaignFinance/CampaignFinanceSection.jsx` (modify) | New branch |

---

### Task 1: Schema migration

**Files:** Create `backend/migrations/CA_NNNN_filed_report_summaries_table.sql`

**Interfaces:** Produces table `transparent_motivations.filed_report_summaries` with the spec's columns.

- [ ] **Step 1: Reserve the slot**

Run: `npm run steward --prefix backend -- slot CA --purpose "create transparent_motivations.filed_report_summaries (CFA-4 summary-sheet totals)"` → note `CA_NNNN`.

- [ ] **Step 2: Write the migration**

```sql
-- CA_NNNN_filed_report_summaries_table.sql
-- Spec: docs/superpowers/specs/2026-09-24-filed-report-summaries-design.md
--
-- One row per filed campaign-finance summary sheet (Indiana CFA-4 first). It exists because a $0 report
-- leaves no contribution rows, so the only honest statement about such a politician -- "filed, $0 raised"
-- -- had nowhere to live, and Essentials told voters the filing was "being processed".
--
-- Money columns are NULL when the sheet's line is BLANK. Never coerce a blank to 0.
-- Rows are written only by reviewed migrations (scripts/cfa-summaries-to-migration.ts), never by the importer.
-- RLS default-deny (CTO decision 0015): reads go through pool.query.
-- ON DELETE RESTRICT: moving a link keeps its id; deleting a link that carries a report must fail loudly.

CREATE TABLE IF NOT EXISTS transparent_motivations.filed_report_summaries (
  id                    uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  politician_source_id  uuid NOT NULL REFERENCES transparent_motivations.politician_sources(id) ON DELETE RESTRICT,
  form                  text NOT NULL,
  report_type           text NOT NULL CHECK (report_type IN ('pre_primary','pre_election','annual','nomination','final','other')),
  is_amendment          boolean NOT NULL DEFAULT false,
  period_start          date NOT NULL,
  period_end            date NOT NULL,
  filed_on              date,
  filed_with            text NOT NULL,
  cash_start            numeric(14,2),
  receipts_itemized     numeric(14,2),
  receipts_unitemized   numeric(14,2),
  receipts_total        numeric(14,2),
  receipts_ytd          numeric(14,2),
  expenditures_total    numeric(14,2),
  expenditures_ytd      numeric(14,2),
  cash_end              numeric(14,2),
  debts_owed_by         numeric(14,2),
  debts_owed_to         numeric(14,2),
  source_pdf            text NOT NULL,
  source                text NOT NULL,
  created_at            timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT filed_report_summaries_period_chk CHECK (period_end >= period_start),
  CONSTRAINT filed_report_summaries_uniq UNIQUE (politician_source_id, form, report_type, period_start, period_end, is_amendment)
);

CREATE INDEX IF NOT EXISTS filed_report_summaries_source_idx
  ON transparent_motivations.filed_report_summaries (politician_source_id);

ALTER TABLE transparent_motivations.filed_report_summaries ENABLE ROW LEVEL SECURITY;

COMMENT ON TABLE transparent_motivations.filed_report_summaries IS
  'One row per filed campaign-finance summary sheet (CFA-4 first). NULL money = blank line on the sheet. Written only by reviewed migrations. CA_NNNN.';

DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM information_schema.columns
   WHERE table_schema = 'transparent_motivations' AND table_name = 'filed_report_summaries';
  IF n <> 22 THEN RAISE EXCEPTION 'CA_NNNN: expected 22 columns, found %', n; END IF;
  IF NOT (SELECT relrowsecurity FROM pg_class WHERE oid = 'transparent_motivations.filed_report_summaries'::regclass) THEN
    RAISE EXCEPTION 'CA_NNNN: RLS not enabled';
  END IF;
END $$;
```

- [ ] **Step 3: Dry-run on prod** — wrap body in `BEGIN; … ROLLBACK;`, run with `psql "$DATABASE_URL" -X -v ON_ERROR_STOP=1 -f`. Expected: no error. Then confirm `SELECT to_regclass('transparent_motivations.filed_report_summaries')` is NULL (rollback reverted).

- [ ] **Step 4: Apply** (claim `county:18105` first) — run the file unwrapped. Expected: no error; `to_regclass` now non-NULL.

- [ ] **Step 5: Commit** — `git commit -F msg -- backend/migrations/CA_NNNN_filed_report_summaries_table.sql`

### Task 2: Backend read path

**Files:** Modify `backend/src/lib/campaignFinanceService.ts` (`detectCoverageStatus` ~line 525, `SummaryResponse` ~line 200, zero-state return ~line 1105); modify `backend/src/lib/campaignFinanceService.test.ts`.

**Interfaces:**
- Produces `export interface FiledReportResponse { form: string; report_type: string; is_amendment: boolean; period_start: string; period_end: string; filed_on: string | null; filed_with: string; receipts_total: number | null; receipts_ytd: number | null; receipts_itemized: number | null; expenditures_total: number | null; expenditures_ytd: number | null; cash_end: number | null; debts_owed_by: number | null; }`
- Produces `SummaryResponse.filed_reports?: FiledReportResponse[]`
- Produces `export async function getFiledReports(politicianId: string): Promise<FiledReportResponse[]>`

- [ ] **Step 1: Write failing tests** — extend the fake pool with a `filed_report_summaries` branch placed FIRST (the existing branch also matches `politician_sources … candidate_committee`):

```ts
// Each report belongs to links[linkIndex]; the fake applies the query's own research_status predicate.
let reports: ({ linkIndex: number } & Record<string, unknown>)[] = [];

// inside query(), before the existing politician_sources branch:
if (sql.includes('transparent_motivations.filed_report_summaries')) {
  const admitted = admittedStatuses(sql);
  return {
    rows: reports
      .filter((r) => admitted === null || admitted.includes(links[r.linkIndex].research_status))
      .map(({ linkIndex, ...row }) => row),
  };
}
```

Reset `reports = []` in `beforeEach`. Tests:

```ts
const GRANGER_ROW = {
  form: 'CFA-4', report_type: 'pre_primary', is_amendment: false,
  period_start: '2026-01-01', period_end: '2026-04-10', filed_on: '2026-04-15',
  filed_with: 'Monroe Circuit Court Clerk', receipts_total: '0.00', receipts_ytd: '0.00',
  receipts_itemized: null, expenditures_total: null, expenditures_ytd: null, cash_end: '0.00',
  debts_owed_by: '0.00', politician_source_id: 'secret', source_pdf: 'secret.pdf',
};

describe('getSummary coverage_status — filed report summaries', () => {
  it("reports 'filed_reports' for a confirmed link whose report is on file, even with no run", async () => {
    links = [{ research_status: 'confirmed' }];
    reports = [{ linkIndex: 0, ...GRANGER_ROW }];
    const { summary } = await getSummary(POLITICIAN);
    expect(summary.coverage_status).toBe('filed_reports');
    expect(summary.filed_reports).toHaveLength(1);
  });

  it('whitelists fields: numbers are numbers, blanks stay null, internal ids never leave', async () => {
    links = [{ research_status: 'confirmed' }];
    reports = [{ linkIndex: 0, ...GRANGER_ROW }];
    const { summary } = await getSummary(POLITICIAN);
    const r = summary.filed_reports![0];
    expect(r.receipts_total).toBe(0);
    expect(r.receipts_itemized).toBeNull();
    expect(r).not.toHaveProperty('politician_source_id');
    expect(r).not.toHaveProperty('source_pdf');
  });

  it("ignores a report on a disputed link", async () => {
    links = [{ research_status: 'disputed' }];
    reports = [{ linkIndex: 0, ...GRANGER_ROW }];
    const { summary } = await getSummary(POLITICIAN);
    expect(summary.coverage_status).toBe('no_data');
    expect(summary.filed_reports).toBeUndefined();
  });

  it("keeps 'data_pending' for a confirmed, never-run link with no report", async () => {
    links = [{ research_status: 'confirmed' }];
    const { summary } = await getSummary(POLITICIAN);
    expect(summary.coverage_status).toBe('data_pending');
    expect(summary.filed_reports).toBeUndefined();
  });
});
```

- [ ] **Step 2: Run** `npx vitest run src/lib/campaignFinanceService.test.ts` (in `backend/`). Expected: the 3 new report tests FAIL (status is `data_pending`/`filed_reports` undefined); the data_pending one passes.

- [ ] **Step 3: Implement**

```ts
export interface FiledReportResponse { /* as in Interfaces */ }

const num = (v: string | null): number | null => (v == null ? null : Number(v));

/**
 * getFiledReports returns the newest filed summary sheets (max 4) on the politician's confirmed
 * own-fundraising committees. An amendment replaces its original for the same report and period.
 * Explicit whitelist: politician_source_id and source_pdf never leave this function.
 */
export async function getFiledReports(politicianId: string): Promise<FiledReportResponse[]> {
  const r = await pool.query<Record<string, string | boolean | null>>(
    `SELECT * FROM (
       SELECT DISTINCT ON (ps.id, f.form, f.report_type, f.period_start, f.period_end)
              f.form, f.report_type, f.is_amendment,
              to_char(f.period_start, 'YYYY-MM-DD') AS period_start,
              to_char(f.period_end, 'YYYY-MM-DD')   AS period_end,
              to_char(f.filed_on, 'YYYY-MM-DD')     AS filed_on,
              f.filed_with, f.receipts_total, f.receipts_ytd, f.receipts_itemized,
              f.expenditures_total, f.expenditures_ytd, f.cash_end, f.debts_owed_by
         FROM transparent_motivations.filed_report_summaries f
         JOIN transparent_motivations.politician_sources ps ON ps.id = f.politician_source_id
        WHERE ps.essentials_politician_id = $1
          AND ${OWN_FUNDRAISING_SQL}
        ORDER BY ps.id, f.form, f.report_type, f.period_start, f.period_end, f.is_amendment DESC, f.created_at DESC
     ) latest
     ORDER BY period_end DESC
     LIMIT 4`,
    [politicianId]
  );
  return r.rows.map((row) => ({
    form: String(row.form), report_type: String(row.report_type), is_amendment: row.is_amendment === true,
    period_start: String(row.period_start), period_end: String(row.period_end),
    filed_on: row.filed_on == null ? null : String(row.filed_on), filed_with: String(row.filed_with),
    receipts_total: num(row.receipts_total as string | null), receipts_ytd: num(row.receipts_ytd as string | null),
    receipts_itemized: num(row.receipts_itemized as string | null),
    expenditures_total: num(row.expenditures_total as string | null),
    expenditures_ytd: num(row.expenditures_ytd as string | null),
    cash_end: num(row.cash_end as string | null), debts_owed_by: num(row.debts_owed_by as string | null),
  }));
}
```

Change `detectCoverageStatus` to return `{ status: string; filedReports?: FiledReportResponse[] }`; first statement:

```ts
  // A report we hold is a finished fact, not a pending one -- it precedes the run-owed rule below.
  // (Spec 2026-09-24-filed-report-summaries: a $0 CFA-4 leaves no contribution rows and no run.)
  const filedReports = await getFiledReports(politicianId);
  if (filedReports.length > 0) return { status: 'filed_reports', filedReports };
```

Every other `return 'x'` becomes `return { status: 'x' }`. In `getSummary`'s zero-state branch: `const [coverage, outsideSpending] = …; coverage_status: coverage.status, ...(coverage.filedReports ? { filed_reports: coverage.filedReports } : {})`. Add `filed_reports?: FiledReportResponse[]` to `SummaryResponse`. Update the doc comment's status list.

- [ ] **Step 4: Run** the test file, then `npx vitest run src` and `npx tsc --noEmit -p .` Expected: all pass (pre-existing missing-package failures excepted, named in the report).

- [ ] **Step 5: Commit** both files with explicit pathspec.

### Task 3: Summary-sheet module (types, validation, review rule, CSV row, vision call)

**Files:** Create `backend/scripts/lib/cfaSummarySheet.ts`, `backend/scripts/lib/cfaSummarySheet.test.ts`.

**Interfaces — produces:**
```ts
export const MONEY_FIELDS = ['cash_start','receipts_itemized','receipts_unitemized','receipts_total','receipts_ytd',
  'expenditures_total','expenditures_ytd','cash_end','debts_owed_by','debts_owed_to'] as const;
export type MoneyField = typeof MONEY_FIELDS[number];
export const REPORT_TYPES = ['pre_primary','pre_election','annual','nomination','final','other'] as const;
export interface SummarySheet {
  form: 'CFA-4'; report_type: typeof REPORT_TYPES[number]; is_amendment: boolean;
  period_start: string | null; period_end: string | null; filed_on: string | null; filed_with: string | null;
  money: Record<MoneyField, number | null>;
  low_confidence_fields: string[];
}
export function parseSummarySheetJson(raw: unknown): SummarySheet | null;
export function reviewReasons(s: SummarySheet): string[];       // [] = clean
export const SUMMARY_CSV_COLUMNS: readonly string[];
export function summaryCsvRow(ctx: { folder: string; pdf: string; politician_id: string; politician_name: string }, s: SummarySheet): string[];
export async function extractSummarySheet(imagePath: string, jurisdictionHint: string): Promise<{ sheet: SummarySheet | null; costUsd: number; warning?: string }>;
```

`SUMMARY_CSV_COLUMNS` = `folder, pdf, politician_id, politician_name, form, report_type, is_amendment, period_start, period_end, filed_on, filed_with, <10 money fields>, low_confidence_fields, needs_review, review_reasons`. Money cells: `''` for null, else `toFixed(2)`. `needs_review` = `'yes'|'no'`.

`reviewReasons` returns reasons for: any `low_confidence_fields`; `period_start`/`period_end`/`filed_with` null; `receipts_total` not equal to `(receipts_itemized ?? 0) + (receipts_unitemized ?? 0)` when both parts are non-null; `period_end < period_start`.

- [ ] **Step 1: Write failing tests** (`cfaSummarySheet.test.ts`): (a) Granger-shaped JSON → sheet with `receipts_itemized: null`, `receipts_total: 0`, `reviewReasons` = []; (b) `"12.5"` string money → 12.5; an unreadable money value such as `"abc"` → that field is null AND is added to `low_confidence_fields`; (c) unknown `report_type` → null; (d) 15c ≠ 15a+15b → a reason containing `15c`; (e) `summaryCsvRow` renders null as `''`, 0 as `'0.00'`, and its length equals `SUMMARY_CSV_COLUMNS.length`.
- [ ] **Step 2: Run** `npx vitest run scripts/lib/cfaSummarySheet.test.ts` → FAIL (module missing).
- [ ] **Step 3: Implement** the pure functions, and `extractSummarySheet` using `new Anthropic()` with model `claude-haiku-4-5-20251001`, `max_tokens: 1024`, one image block + a prompt naming each CFA-4 line (11, 12, 13A, 15a/15b/15c A and B, 17c A and B, 18A, 19, 20, amendment box, clerk stamp) and requiring `null` for a BLANK line and a `low_confidence_fields` array. Parse with a code-fence strip, then `parseSummarySheetJson`.
- [ ] **Step 4: Run** the tests → PASS.
- [ ] **Step 5: Commit** both files.

### Task 4: Migration generator

**Files:** Create `backend/scripts/lib/cfaSummaryMigration.ts`, `backend/scripts/lib/cfaSummaryMigration.test.ts`, `backend/scripts/cfa-summaries-to-migration.ts`.

**Interfaces — consumes** `SUMMARY_CSV_COLUMNS`, `MONEY_FIELDS` (Task 3). **Produces:**
```ts
export function parseCsv(text: string): Record<string, string>[];                 // RFC-4180 quotes
export function buildMigrationSql(rows: Record<string, string>[], opts: { slot: string; sourceSystem: string; date: string }): string; // throws on needs_review=yes or bad row
```

Generated SQL per row: `INSERT … SELECT ps.id, … FROM transparent_motivations.politician_sources ps WHERE ps.essentials_politician_id = '<uuid>' AND ps.source_system = '<sourceSystem>' AND ps.research_status = 'confirmed' AND ps.source_type = 'candidate_committee' ON CONFLICT ON CONSTRAINT filed_report_summaries_uniq DO NOTHING;` Money `''` → `NULL`. Values escaped (`'` → `''`); uuid and dates validated by regex before emitting. Ends with a `DO $$` gate: count of rows with `source = '<slot>'` equals N, and `SUM(COALESCE(receipts_total,0))` equals the CSV sum, and each expected politician has exactly one confirmed link (else `RAISE EXCEPTION`).

- [ ] **Step 1: Failing tests:** (a) a clean Granger row → SQL contains `NULL` for itemized and `0.00` for receipts_total and the gate count `= 1`; (b) a row with `needs_review=yes` → throws `/needs_review/`; (c) a quote in `filed_with` is doubled; (d) a malformed uuid → throws; (e) `parseCsv` handles a quoted comma.
- [ ] **Step 2: Run** → FAIL.
- [ ] **Step 3: Implement**; CLI reads `--csv`, `--slot`, `--source-system` (default `IN_MONROE_COUNTY_LOCAL`), writes `backend/migrations/<slot>_filed_report_summaries_<suffix>.sql` with `--suffix`.
- [ ] **Step 4: Run** → PASS.
- [ ] **Step 5: Commit** the three files.

### Task 5: Importer writes the summaries CSV

**Files:** Modify `backend/scripts/parse-local-cfa.ts`.

**Interfaces — consumes** `extractSummarySheet`, `summaryCsvRow`, `SUMMARY_CSV_COLUMNS`, `reviewReasons` (Task 3).

- [ ] **Step 1:** In the per-PDF loop, after `pdfToPageImages`, call `extractSummarySheet(pagePaths[0], jurisdictionHint)` (page 1 is the CFA-4 summary sheet); add its cost; push `summaryCsvRow(...)` into `summaryRows` (or a review-only row with `needs_review=yes, review_reasons=extraction failed` when `sheet` is null). This runs in dry-run and for PDFs with zero contribution rows.
- [ ] **Step 2:** After the review CSV, write `local-cfa-summaries-<ts>.csv` with `escapeCsvCell` and print its path in FINAL SUMMARY. No DB write.
- [ ] **Step 3: Run** on the one PDF in hand, dry-run: `npx tsx scripts/parse-local-cfa.ts --folder <dir containing "Granger, Dorothy"> --candidate Granger` (cost ≈ $0.002). Expected: summaries CSV with one row; compare every field against the PDF by eye.
- [ ] **Step 4:** `npx tsc --noEmit -p .`, `npx eslint scripts/parse-local-cfa.ts scripts/lib/cfaSummarySheet.ts scripts/lib/cfaSummaryMigration.ts scripts/cfa-summaries-to-migration.ts`.
- [ ] **Step 5: Commit.** Then open the backend PR (Tasks 1–5), CI green, merge, confirm Render deploy live.

### Task 6: Granger data migration (end-to-end positive control)

- [ ] **Step 1:** Reserve a slot: `steward slot CA --purpose "first filed_report_summaries row: Dorothy Granger CFA-4 pre-primary 2026 ($0)"`.
- [ ] **Step 2:** Copy the Task 5 CSV, set `needs_review=no` only after checking each field against the PDF; generate with `npx tsx scripts/cfa-summaries-to-migration.ts --csv <file> --slot CA_MMMM --suffix granger`.
- [ ] **Step 3:** Dry-run `BEGIN; … ROLLBACK;` on prod; confirm 0 rows remain. Apply. Expected gate passes.
- [ ] **Step 4:** Live check: `curl https://accounts-api.empowered.vote/api/campaign-finance/politician/<granger id>/summary` → `coverage_status: "filed_reports"`, one report, `receipts_total: 0`. Also re-check one other Monroe `data_pending` politician still reads `data_pending` (control).
- [ ] **Step 5:** Commit the migration + PR + merge.

### Task 7: Essentials panel

**Repo:** `~/Documents/GitHub/essentials`, in a new worktree off `origin/main`-equivalent default branch.

**Files:** Create `FiledReportsPanel.jsx` + test; modify `CampaignFinanceSection.jsx`.

**Interfaces — consumes** `summary.filed_reports: FiledReportResponse[]` (Task 2).

- [ ] **Step 1: Failing test** (vitest + Testing Library, matching the repo's existing test setup): renders "Pre-Primary report", "Jan 1 – Apr 10, 2026", "filed Apr 15, 2026 with the Monroe Circuit Court Clerk", "Raised $0", a NULL `expenditures_total` as "—", and "Itemized donor list not yet available." only when `receipts_itemized > 0`.
- [ ] **Step 2: Run** → FAIL.
- [ ] **Step 3: Implement** the panel (labels: pre_primary→"Pre-Primary", pre_election→"Pre-Election", annual→"Annual", nomination→"Nomination", final→"Final", other→"Other"; "(amended)" suffix; dates formatted with `toLocaleDateString('en-US', { month:'short', day:'numeric', year:'numeric', timeZone:'UTC' })` — UTC so a date column never shifts a day). Add the `'filed_reports'` branch to `CampaignFinanceSection` beside `local_unavailable`, with `OutsideSpendingSection` when committees exist.
- [ ] **Step 4: Run** tests + build → PASS.
- [ ] **Step 5:** Commit, PR, merge; check Granger's profile page in the browser pane.
