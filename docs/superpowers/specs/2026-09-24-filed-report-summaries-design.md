# Filed report summaries ("filed, $0 raised") — design

Date: 2026-09-24 · Author: Chris Andrews (with Claude) · Status: approved in conversation, awaiting spec review

## Problem

18 active Monroe County, IN politicians show the Essentials banner "Campaign finance filings for this
candidate have been sourced and are being processed. Check back soon" (`coverage_status = 'data_pending'`).
It is false. Their CFA-4 pre-primary reports (period 2026-01-01 – 2026-04-10) were read in April; most
report **$0** (Dorothy Granger's sheet: every line 0, filed 2026-04-15). `parse-local-cfa.ts` writes only
itemized contribution rows, so a $0 report leaves no data — only free-text notes on the link — and the
importer writes no `ingestion_runs`, so #681's "run still owed" rule never clears them either.

The true fact is "filed a report showing $0 raised". The UI has no state for it. The same gap will recur
with the pre-election reports (period ends 2026-10-09, due noon 2026-10-16; general election 2026-11-03).

## Decisions (operator, 2026-09-23/24)

1. Show filed-report facts, not hide the section.
2. Store the **full summary-sheet totals**, not only receipts.
3. **v1 changes only politicians with a filed report and no itemized contributions.** The 15 Monroe
   politicians who already show donors display exactly as today. Using the report's year-to-date receipts
   as the headline (as `getAuthoritativeFecTotal` does for FEC) is a named follow-up.
4. Data entry: **importer extracts → review CSV → CA_ migration with post-verify gate.**
5. PDFs come from the county (election@co.monroe.in.us, per the county's Candidate Filings page).

## 1. Data model

New table `transparent_motivations.filed_report_summaries` — one row per filed summary sheet.

| Column | Type | CFA-4 line / meaning |
|---|---|---|
| `id` | uuid PK default `gen_random_uuid()` | |
| `politician_source_id` | uuid NOT NULL → `politician_sources(id)` ON DELETE RESTRICT | committee link that filed it |
| `form` | text NOT NULL | `'CFA-4'` |
| `report_type` | text NOT NULL, CHECK in (`pre_primary`,`pre_election`,`annual`,`nomination`,`final`,`other`) | line 11 |
| `is_amendment` | boolean NOT NULL default false | header box |
| `period_start`, `period_end` | date NOT NULL, CHECK `period_end >= period_start` | line 12 |
| `filed_on` | date NULL | clerk's stamp |
| `filed_with` | text NOT NULL | e.g. `Monroe Circuit Court Clerk` |
| `cash_start` | numeric(14,2) NULL | 13A |
| `receipts_itemized` | numeric(14,2) NULL | 15a A |
| `receipts_unitemized` | numeric(14,2) NULL | 15b A |
| `receipts_total` | numeric(14,2) NULL | 15c A |
| `receipts_ytd` | numeric(14,2) NULL | 15c B |
| `expenditures_total` | numeric(14,2) NULL | 17c A |
| `expenditures_ytd` | numeric(14,2) NULL | 17c B |
| `cash_end` | numeric(14,2) NULL | 18A |
| `debts_owed_by` | numeric(14,2) NULL | 19 |
| `debts_owed_to` | numeric(14,2) NULL | 20 |
| `source_pdf` | text NOT NULL | file that was read (folder/filename) |
| `source` | text NOT NULL | migration slot that wrote the row, e.g. `CA_0250` |
| `created_at` | timestamptz NOT NULL default now() | |

- A money column is **NULL when the line is blank on the sheet**, never coerced to 0. Store what the sheet says.
- UNIQUE (`politician_source_id`, `form`, `report_type`, `period_start`, `period_end`, `is_amendment`).
  An amendment sits beside its original; the read path prefers it.
- RLS enabled, no policies (default-deny, CTO decision 0015), like `fec_candidate_totals`. Reads go through `pool.query`.
- ON DELETE RESTRICT: link *moves* (e.g. CA_0182 duplicate merges) keep the link `id`, so rows follow it;
  deleting a link that has a report fails loudly instead of orphaning it.

## 2. Read path, API, Essentials

**Status rule** — in `detectCoverageStatus` (only reached when the politician has no confirmed contributions):

1. **New, first:** a link matching `OWN_FUNDRAISING_SQL` (confirmed, candidate committee) has ≥1
   `filed_report_summaries` row → `'filed_reports'`. It precedes #681's run-owed rule: a report we hold is a
   finished fact.
2. Otherwise unchanged: `data_pending` (run owed) → `local_unavailable` → `no_data`.

A report on a disputed / not_applicable / needs_research link never counts.

**API** — only when `coverage_status = 'filed_reports'`, `SummaryResponse.filed_reports` carries the newest 4
reports (by `period_end` desc; an amendment replaces its original for the same period). Explicit field
whitelist: `form, report_type, is_amendment, period_start, period_end, filed_on, filed_with, receipts_total,
receipts_ytd, receipts_itemized, expenditures_total, expenditures_ytd, cash_end, debts_owed_by`.
`politician_source_id` and `source_pdf` are never exposed. No other response changes.

**Essentials** (`CampaignFinanceSection.jsx`) — one new branch for `'filed_reports'`: a "Filed reports" panel,
plus `OutsideSpendingSection` when committees exist (as the `local_unavailable` branch does). Per report:

> **Pre-Primary report** · Jan 1 – Apr 10, 2026 · filed Apr 15, 2026 with the Monroe Circuit Court Clerk
> Raised **$0** · Spent **$0** · Cash on hand **$0**

- NULL renders as "—", never "$0".
- `receipts_itemized > 0` with no donor rows loaded → add "Itemized donor list not yet available."
- Rollout order backend → frontend. An old frontend falls through to "no data → hide section": harmless.

## 3. Data entry, tests, rollout

**Importer** — `scripts/lib/pdfOcrPipeline.ts` gains `extractSummarySheet(pageImage)` returning the fields
above with a per-field confidence. `parse-local-cfa.ts` runs it on every PDF (dry-run too, **including $0
reports**) and writes `local-cfa-summaries-<ts>.csv`: one row per report, with folder, PDF, resolved
politician id, every field, confidences, and a `needs_review` flag (any low confidence, period missing,
or 15c ≠ 15a + 15b). It writes **no summaries to the database**.

**Generator** — `scripts/cfa-summaries-to-migration.ts --csv <reviewed.csv> --slot CA_NNNN` emits the data
migration: resolves each link by (politician id, `source_system`, confirmed), `INSERT … ON CONFLICT DO
NOTHING`, and a `DO $$` post-verify gate asserting row count, every link confirmed, and per-column sums equal
to the CSV. It refuses a CSV row still flagged `needs_review`. Slots come from `steward slot CA`.

**Tests**
- Backend unit (fake pool, as in `campaignFinanceService.test.ts`): confirmed link + report → `filed_reports`
  with whitelisted fields only; disputed link + report → not `filed_reports`; confirmed link, no report →
  unchanged #681 behaviour; amendment preferred over original.
- Generator unit test: CSV → SQL, NULL stays NULL, `needs_review` row refused.
- CSV writer unit test (pure function).
- Essentials component test: panel renders, NULL → "—", itemized-not-loaded line.

**Rollout**
1. Schema migration (CA_ slot) + backend PR. Dry-run `BEGIN … ROLLBACK` on prod first.
2. Granger-only data migration (her PDF is in hand) — the end-to-end positive control; verify the live API.
3. Essentials PR; verify the profile page.
4. County reply → OCR the April set → review CSV → data migration.
5. Same for the 2026-10-16 pre-election set.

Claim `county:18105` with the steward before any write.

## Derived totals (operator ruling 2026-09-24, CA_0257)

Filers often leave 15c ("raised") and 17c ("spent") **blank** on a $0 report while writing 0 on lines 13, 16
and 18 (Granger). Strict NULL would show "Raised — · Spent —" for a report that says $0. The sheet's own
arithmetic answers it, so a blank is filled from lines the filer wrote — never guessed — and the row says so:

- `total_available` = line 16, column A, as written.
- 15c blank, 13 and 16 written, 16 − 13 ≥ 0 → `receipts_total = 16 − 13`, `receipts_total_derived = true`.
- 17c blank, 16 and 18 written, 16 − 18 ≥ 0 → `expenditures_total = 16 − 18`, `expenditures_total_derived = true`.
- A negative result, or a written 15c/17c that does not reconcile with 16/18, sends the sheet to review.
- CHECK constraints refuse a derived flag without the lines it came from. YTD columns are never derived.
- The API passes both flags through; the panel notes when a figure was calculated from the report's totals.

## Out of scope / follow-ups

- Report-total headline for politicians who also have itemized rows (decision 3).
- Other forms (CFA-11 large-contribution reports) and other counties — the table is form-agnostic, the importer is not yet.
- Two Monroe records both carry Clerk-candidate finance notes (Joe Davis / Joseph Bradley Davis) — possible duplicate; check against CA_0182.
- `pdfOcrPipeline.ts` fallback model `claude-3-5-haiku-latest` is likely retired; primary is `claude-haiku-4-5-20251001`.
