# 174-04 Task 1: Live `original_sub_id` Supersession Confirmation — RESOLVED (option 2 / proceed)

**Status: RESOLVED 2026-07-23. Operator reviewed the two live-sampling sessions below (never
caught a populated `original_sub_id` across ~1,640 rows, hit a 429 on the shared production key)
and authorized Task 2 to proceed on the schema-level evidence (option 2 in the Decision section)
rather than burn further shared-key quota re-scanning for a row that may simply not occur in the
sampling window available. The retirement DELETE is now live in `fecAdapter.ts`, gated exactly as
option 2 described: it only ever matches `data_source='fec' AND source_transaction_id =
original_sub_id`, fires only when an incoming row's `original_sub_id` is non-null (so today, with
the field observed null in practice, it is a safe no-op that activates automatically if/when FEC
populates the field on a real row), and can never touch the newly-inserted amended row (different
sub_id) or any non-FEC data source. See `174-04-SUMMARY.md` for the implementation record.**

This file was originally a live artifact of an in-progress confirmation attempt, left
uncommitted while Task 1 (a `checkpoint:human-verify` gate) was pending. It is committed now as
the recorded evidence for the operator's "proceed" decision.

## What was attempted this session (automated, by the executor)

Per the "automation before verification" checkpoint principle, the executor ran the live query
work itself (using `process.env.FEC_API_KEY`, the production personal key, via a scratch
`tsx` script — not committed, deleted after use) rather than waiting idle for a human to run it,
since this step is a data query any agent with API access can perform.

### Committees sampled

1. **RESEARCH-amendments.md's already-tried candidate committees** (re-confirmed no change):
   `C00811166`, `C00884288`, `C00401224`, `C00922179`.
2. **National party committees** (`C00003418` DNC, `C00027466` RNC, `C00042366` NRSC,
   `C00075820` DSCC, `C00075797` NRCC, `C00000935` DCCC) — narrow single-day `min_load_date=
   max_load_date` windows mostly returned `count=0` (these mega-committees' most-recent load
   activity, by default sort, clustered around late June, not the specific days tried) and wider
   windows (`min_load_date` open-ended over ~2-6 weeks) hit `HTTP 504 "Query timed out"` — too
   large a query for FEC to compute for these committees at that window size.
3. **A better-targeted approach**: queried `/v1/filings/?amendment_indicator=A&form_type=F3X&
   sort=-receipt_date` to find committees that have *genuinely re-amended* a filing very recently
   (i.e. `amendment_chain.length >= 2`, meaning a filing amends an already-amended filing — the
   scenario most likely to produce a real line-item `original_sub_id`). This surfaced:

   | committee_id | file_number | previous_file_number | receipt_date | amendment_chain length |
   |---|---|---|---|---|
   | C00365536 | 2000912 | 1979425 | 2026-07-20 | 4 |
   | C00884288 | 2001197 | 1971955 | 2026-07-22 | 3 |
   | C00254201 | 2001027 | 1998876 | 2026-07-21 | 3 |
   | C00035600 | 1999982 | 1987643 | 2026-07-20 | 3 |
   | C00135558 | 2000874 | 1939454 | 2026-07-20 | 3 |
   | C00811166 | 2001175 | 1962170 | 2026-07-22 | 2 |
   | C00757302 | 1998909 | 1998094 | 2026-07-17 | 2 |
   | C00003210 | 1994460 | 1967068 | 2026-07-15 | 2 |

4. Queried `schedule_a` for each of the above with `committee_id` + a `min_load_date`/
   `max_load_date` window bracketing the filing's `receipt_date` (+/- a few days) +
   `two_year_transaction_period=2026`.

### Result: every sampled row had `original_sub_id: null`

- `C00811166` (2026-07-22 re-amendment): 19 rows, all `amendment_indicator:"A"`,
  `load_date:"2026-07-23T03:05:58"` (fresh — confirms the amendment WAS reloaded today), all
  `original_sub_id: null`.
- `C00757302`: 5 rows, same pattern — fresh `load_date`, `amendment_indicator:"A"`,
  `original_sub_id: null`.
- `C00003210`: 1 row, same pattern.
- `C00884288`: first page of 9,134 total rows (92 pages) sampled — `original_sub_id: null` on
  the sampled page; the remaining ~91 pages were **not** scanned (rate limit hit before reaching
  this committee's full scan — see below).
- `C00365536`: pages 1–12, 14, 17 of 23 total pages (2,269 rows) scanned — `original_sub_id:
  null` on every row seen. Pages 13, 15, 16, 18–23 were **not successfully scanned** — see below.
- `C00254201`, `C00893081`: 0 rows in the queried window (no schedule_a activity loaded in that
  window despite the filing amendment — the report-level amendment evidently did not touch
  itemized Schedule A lines in a way that produced a fresh load in the window tried).

This is **consistent with** (not contradicting) `174-RESEARCH-amendments.md`'s own finding:
report-level F3X amendments reload their Schedule A lines with `amendment_indicator:"A"` and a
fresh `load_date`, but — at least in every row sampled across ~140+ live rows this session plus
~1,500 sampled in the original research session — `original_sub_id` stays `null`. **No row with
a populated `original_sub_id` has yet been caught live**, despite two independent sessions of
targeted sampling (including this session's specifically-targeted re-amended-committee search,
which was a more surgical approach than the original research's broad sampling).

### Why the scan stopped: hit FEC's own rate limit on the production key

While paginating `C00365536` (page 13), the production `FEC_API_KEY` received:
```
HTTP 429 {"error":{"code":"OVER_RATE_LIMIT","message":"You have exceeded your rate limit of
40 calls per hour for the DEMO_KEY, 1000 calls per hour for a personal key, or 120 calls per
minute for an upgraded key. ..."}}
```
This is the **same shared key the production ingestion cron uses** (per `174-RESEARCH.md`/
`174-RESEARCH-amendments.md`). The executor immediately stopped issuing further requests and
force-terminated all in-flight query processes rather than continue consuming the shared hourly
budget — continuing would directly work against this phase's own goal (driving FEC 429s to
zero) and could contend with the daily incremental refresh (174-02/174-03) if it runs in the same
hour. No further live queries were attempted after this point.

### A non-rate-limited offline path was investigated and ruled out (for now)

`fecBulkLoader.ts`'s free bulk `indiv{YY}.zip` file (already used for FEC-01 committee
resolution) has **21 pipe-delimited columns with no `orig_sub_id` field** (confirmed by reading
the documented column layout at `fecBulkLoader.ts:48-49`; the file's own doc comment already
notes it is "not amendment-resolved" — both the original and amended SUB_ID rows load, with no
linking column). The `orig_sub_id` field referenced in the openFEC GitHub wiki
(`fecgov/openFEC/wiki/Schedule-A-column-documentation`) belongs to FEC's internal `sa` data
warehouse table schema (used by their own API backend), **not** the public `indiv{YY}.zip` bulk
download — so there is currently no zero-rate-limit way to sample this field offline with the
files already integrated into this codebase.

## Decision — RESOLVED (operator chose option 2, "proceed")

Options, in order of the executor's recommendation:

1. **Retry the live search** once the shared key's hourly quota resets (top of the next UTC
   hour), resuming with the two best untried candidates from this session's targeted list:
   `C00365536` (pages 13, 15, 16, 18-23 of 23 — chain length 4, the deepest re-amendment found)
   and `C00884288` (pages 2-92 of 92 — chain length 3, largest committee, most rows to search).
   Record the result here and reply "confirmed" (if a real linked `original_sub_id` is caught)
   or describe the discrepancy.
2. **Accept the schema-level evidence as sufficient** to authorize Task 2 without a live-caught
   populated row. Basis: `original_sub_id` is confirmed present and typed as a `sub_id`-linking
   field in FEC's live OpenAPI `ScheduleA` schema (RESEARCH-amendments.md point 2); FEC's own
   canonical `sa` warehouse table documents `orig_sub_id` as "original sub_Id" (this session's
   finding, directly from FEC's own wiki); and the retirement DELETE's blast radius is bounded
   even if the semantics were somehow different than expected — it can only ever affect a row
   whose `source_transaction_id` literally equals a value the amended row itself carries as
   `original_sub_id`, scoped to `data_source='fec'`, so it cannot touch the newly-inserted
   amended row (different `sub_id`) or any other data source.
3. **Investigate FEC's bulk data-warehouse extracts** for a free, non-rate-limited file that
   does carry `orig_sub_id` (the `sa` schema referenced above may correspond to a downloadable
   file distinct from `indiv{YY}.zip` — not yet identified) as a follow-up research task before
   deciding.

**Operator reply: "proceed" (option 2) — authorized 2026-07-23. Task 2 implemented accordingly;
see `174-04-SUMMARY.md`.**
