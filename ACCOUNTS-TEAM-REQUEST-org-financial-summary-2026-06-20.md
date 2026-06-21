# ACCOUNTS-TEAM REQUEST — expose `treasury.org_financial_summary` via the API

**From:** Treasury Tracker (treasury-tracker repo) — Chris / Claude
**Date:** 2026-06-20
**Priority:** Blocks Treasury Tracker **Phase 76 (Donor-Facing Transparency View)** — the frontend has no other read path to this data.
**Pattern to copy:** the existing **`GET /api/treasury/federal/context`** endpoint (Phase 45). Same shape of work: a sourced summary table → one read-only, always-sourced endpoint.

---

## What we need

Treasury Tracker now writes a reconciled per-org financial summary into a new table, `treasury.org_financial_summary` (one row per `municipality_id` + `fiscal_year`). The donor-facing EV page needs to read it through `ev-accounts-api`. We read **all** EV data via this API (`API_BASE` → `ev-accounts-api`), never raw Postgres, so without an endpoint there is nothing to render.

### The table (already migrated by treasury-tracker)

`treasury.org_financial_summary` — see migration `20260620000000_create_org_financial_summary.sql` (treasury-tracker repo). Columns:

| Column | Type | Meaning |
|---|---|---|
| `municipality_id` | uuid FK | EV = `ee6f34f7-bd85-4387-8d71-4c2ed8cb8fdf` |
| `fiscal_year` | smallint | e.g. 2026 |
| `balance` | numeric | bank-authoritative cash on hand (dollars) |
| `balance_as_of` | date | as-of date for balance |
| `monthly_burn` | numeric | trailing-N-month avg burn |
| `burn_window_months` | smallint | N (default 3) |
| `runway_months` | numeric \| null | balance ÷ burn (**stored but NOT displayed** — still return it) |
| `income_gross` | numeric | total donated before fees |
| `income_fees` | numeric | platform fees |
| `income_net` | numeric | what reached EV (gross − fees) |
| `income_by_source` | jsonb | `[{source,gross,fee,net}]` per platform |
| `recon_variance` | numeric \| null | platform-net vs. bank-deposit Δ |
| `recon_explanation` | text \| null | human explanation of the variance |
| `recon_by_source` | jsonb | `[{source,platform_net,bank_deposits,variance}]` |
| `unmatched_deposits` | jsonb | `[{date,amount,description}]` |
| `source_name` / `source_url` / `source_date` | text/text/date | the always-sourced standard |

### ⚠️ Two NEW columns are being added by treasury-tracker (Phase 76)

A follow-up migration will add:

| Column | Type | Meaning |
|---|---|---|
| `goal_amount` | numeric \| null | active fundraising goal (manual value) |
| `goal_label` | text \| null | label for the goal |

**Please `SELECT *` / include these in the query** so they're served once the migration lands. (Coordinate on timing if you want — they'll exist before Phase 76 ships. Selecting them is forward-safe; if you build before the migration, just add them to the select then.)

---

## Suggested endpoint (your call on the exact shape)

Mirrors `/cities/:id/budgets` (parametric, keyed by id + `fiscal_year`):

```
GET /api/treasury/orgs/:id/financial-summary?fiscal_year=2026
```

- `optionalAuth` (public read — same as the other treasury GETs; Inform/unauthenticated get full read access).
- Validate `:id` against `UUID_REGEX`; validate `fiscal_year` like the budgets route (integer 1900–2100).
- If `fiscal_year` omitted, return the latest available FY row.
- 404 if no row for that org/FY.
- Register the static/`:id` route in the correct order in `routes/treasury.ts` (the file already notes the federal/context static-path ordering caveat).

A static EV-only alias (like `federal/context`) is also fine if you prefer — but the table is keyed by `municipality_id`, so the parametric route generalizes to any future org.

### Service layer (`lib/treasuryService.ts`)

Same pattern as `getFederalContext()` — a `pool.query` against `treasury.org_financial_summary`, mapped to a typed interface. Numeric coercion via your existing `num()` helper; pass jsonb columns straight through.

### Response interface (what the treasury-tracker frontend will consume)

```ts
export interface OrgFinancialSummary {
  municipality_id: string;
  fiscal_year: number;
  balance: number;
  balance_as_of: string;
  monthly_burn: number;
  burn_window_months: number;
  runway_months: number | null;
  income_gross: number;
  income_fees: number;
  income_net: number;
  income_by_source: { source: string; gross: number; fee: number; net: number }[];
  recon_variance: number | null;
  recon_explanation: string | null;
  recon_by_source: { source: string; platform_net: number; bank_deposits: number; variance: number }[];
  unmatched_deposits: { date: string; amount: number; description: string }[];
  goal_amount: number | null;   // NEW (Phase 76 migration)
  goal_label: string | null;    // NEW (Phase 76 migration)
  source_name: string;
  source_url: string | null;
  source_date: string;
}
```

(Treasury-tracker will add the matching type in `src/types/budget.ts` and a `getOrgFinancialSummary()` fetch in `src/data/dataLoader.ts`.)

---

## Grants / access

The table already grants `SELECT` to `anon, authenticated` (mirrors `federal_context_metrics`). The anon/authenticated read path you already use for `/federal/context` should work unchanged — no new RLS/grants needed.

## What treasury-tracker owns (so we don't collide)

- The `org_financial_summary` table + the goal-columns migration.
- Writing/refreshing the data (`scripts/reconcileEV.js`).
- Frontend rendering + the `dataLoader.ts` fetch + TS type.

## What we're asking EV-Accounts to own

- The one GET endpoint above (route + service fn + response type), returning every column incl. the two new goal fields.

Ping back here (or reply in `ACCOUNTS-COORDINATION.md`) with the final endpoint path + response shape once built, and we'll wire the frontend to it. Thanks! 🙏

---

## ✅ EV-Accounts reply (2026-06-21) — built

**Final endpoint (matches your suggested shape exactly):**

```
GET /api/treasury/orgs/:id/financial-summary?fiscal_year=2026
```

- **Path is parametric** (keyed by `municipality_id`), as you preferred — generalizes to any future org, not an EV-only alias. EV's id `ee6f34f7-bd85-4387-8d71-4c2ed8cb8fdf`.
- `optionalAuth` (public read; Inform/unauthenticated get full read access) — same path as `/federal/context`.
- `:id` validated against `UUID_REGEX` → **422** `{code:"INVALID_ID"}` on bad UUID.
- `fiscal_year` validated as integer 1900–2100 → **422** `{code:"VALIDATION_ERROR"}` on bad value.
- `fiscal_year` **omitted → latest available FY row** (`ORDER BY fiscal_year DESC LIMIT 1`).
- **404** `{code:"NOT_FOUND"}` if no row for that org/FY.
- Registered in the `/orgs/` namespace — no static-path-before-`:id` collision with `/cities` or `/federal`.

**Response shape:** exactly your `OrgFinancialSummary` interface (all columns), numeric coercion via the standard `num()` helper, jsonb columns (`income_by_source`, `recon_by_source`, `unmatched_deposits`) passed straight through.

**Forward-safe goal columns:** the service uses `SELECT *` and maps `goal_amount`/`goal_label` with `?? null`, so:
- **today** (columns not yet migrated): both serve as `null`, no error;
- **after your Phase 76 migration lands**: they serve automatically with **no EV-Accounts code change required**.

Verified against prod (`kxsdzaojfaibhuzmclfq`): table `treasury.org_financial_summary` present with all listed columns; `goal_amount`/`goal_label` not yet present (expected). Backend typechecks clean.

**Implementation (EV-Accounts owns):**
- Route: `backend/src/routes/treasury.ts` → `GET /orgs/:id/financial-summary`
- Service: `backend/src/lib/treasuryService.ts` → `getOrgFinancialSummary(municipalityId, fiscalYear?)` + exported `OrgFinancialSummary` interface

**Live when:** ships with the next `ev-accounts-api` backend deploy (code merged; no migration owed by us).

One nit on your interface for the frontend type: the live row also carries `id` (uuid) and `updated_at` (timestamptz) columns — we intentionally do **not** return them (not in the agreed shape). If you want `updated_at` surfaced for a "last reconciled" timestamp, say so and we'll add it.
