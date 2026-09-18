/**
 * Treasury routes — city budget data for the EV-Accounts API.
 *
 * Purpose: Satisfies CONS-08 — Treasury endpoints served by ev-accounts.
 * The Go server is no longer the authoritative source for treasury data.
 *
 * Public reads: no auth required (optionalAuth)
 * Admin writes: requireAuth + requireAdmin
 *
 * Architecture rules enforced here:
 *   - Service-role client is NOT used — all DB access via treasuryService (pool.query)
 *   - Treasury schema is NOT PostgREST-exposed; direct pool.query() only
 *   - Explicit UUID validation before any DB lookup
 *   - Zod validation on all write request bodies
 */

import { Router } from 'express';
import { optionalAuth, requireAuth } from '../middleware/auth.js';
import { requireAdmin } from '../middleware/requireAdmin.js';
import type { Request, Response } from 'express';
import { z } from 'zod';
import {
  getCities,
  getEntityAliases,
  getCityById,
  getBudgetsByCityId,
  getBudgetById,
  getLineItemsByBudgetId,
  getLinkedTransactions,
  searchCategories,
  createCity,
  createBudget,
  createBudgetCategory,
  createBudgetLineItem,
  getEnrichmentQueueStatus,
  getFederalContext,
  getOrgFinancialSummary,
} from '../lib/treasuryService.js';

const router = Router();

const UUID_REGEX = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

// ---------------------------------------------------------------------------
// Public read routes (optionalAuth — works unauthenticated)
// ---------------------------------------------------------------------------

// GET /api/treasury/cities
// ⚠ `?datasets=summary` replaces the per-budget-row `available_datasets` array
// with a compact `{ years, dataset_types }`. See getCities() for why. Any other
// value — including none — returns the default response byte-for-byte unchanged,
// because this endpoint is a cross-app contract and trimming it by default would
// be a silent breaking change.
router.get('/cities', optionalAuth, async (req: Request, res: Response): Promise<void> => {
  try {
    const cities = await getCities(req.query['datasets'] === 'summary' ? 'summary' : 'full');
    res.status(200).json(cities);
  } catch (err) {
    console.error('[GET /treasury/cities] error:', err);
    res.status(500).json({ code: 'INTERNAL_ERROR', message: 'An unexpected error occurred' });
  }
});

// GET /api/treasury/aliases
// Names entities used to be published under, so Treasury Tracker can resolve a
// `?entity=` link whose slug was retired by a publisher rename. Static path, no
// input, no auth beyond the optional pass — the same public read as /cities.
// NOTE: registered before /cities/:id-style params.
router.get('/aliases', optionalAuth, async (_req: Request, res: Response): Promise<void> => {
  try {
    const aliases = await getEntityAliases();
    res.status(200).json(aliases);
  } catch (err) {
    console.error('[GET /treasury/aliases] error:', err);
    res.status(500).json({ code: 'INTERNAL_ERROR', message: 'An unexpected error occurred' });
  }
});

// GET /api/treasury/federal/context
// Federal landing data (Phase 45): 64-year annual summary (receipts/outlays/
// deficit + BEA split) + keyed context metrics (FYTD, debt, interest, exclusion
// disclosures). Every row carries its source columns — the always-sourced rule.
// NOTE: registered before /cities/:id-style params; static path, no input.
router.get('/federal/context', optionalAuth, async (_req: Request, res: Response): Promise<void> => {
  try {
    const context = await getFederalContext();
    res.status(200).json(context);
  } catch (err) {
    console.error('[GET /treasury/federal/context] error:', err);
    res.status(500).json({ code: 'INTERNAL_ERROR', message: 'An unexpected error occurred' });
  }
});

// GET /api/treasury/cities/:id
router.get('/cities/:id', optionalAuth, async (req: Request, res: Response): Promise<void> => {
  const id = req.params.id as string;
  if (!UUID_REGEX.test(id)) {
    res.status(422).json({ code: 'INVALID_ID', message: 'Invalid UUID format' });
    return;
  }

  try {
    const city = await getCityById(id);
    if (!city) {
      res.status(404).json({ code: 'NOT_FOUND', message: 'City not found' });
      return;
    }
    res.status(200).json(city);
  } catch (err) {
    console.error('[GET /treasury/cities/:id] error:', err);
    res.status(500).json({ code: 'INTERNAL_ERROR', message: 'An unexpected error occurred' });
  }
});

// GET /api/treasury/cities/:cityId/budgets
// Optional query: ?fiscal_year=2024
router.get(
  '/cities/:cityId/budgets',
  optionalAuth,
  async (req: Request, res: Response): Promise<void> => {
    const cityId = req.params.cityId as string;
    if (!UUID_REGEX.test(cityId)) {
      res.status(422).json({ code: 'INVALID_ID', message: 'Invalid UUID format' });
      return;
    }

    const fiscalYearRaw = req.query.fiscal_year as string | undefined;
    let fiscalYear: number | undefined;
    if (fiscalYearRaw !== undefined) {
      const parsed = Number(fiscalYearRaw);
      if (!Number.isInteger(parsed) || parsed < 1900 || parsed > 2100) {
        res.status(422).json({ code: 'VALIDATION_ERROR', message: 'Invalid fiscal_year' });
        return;
      }
      fiscalYear = parsed;
    }

    try {
      const budgets = await getBudgetsByCityId(cityId, fiscalYear);
      res.status(200).json(budgets);
    } catch (err) {
      console.error('[GET /treasury/cities/:cityId/budgets] error:', err);
      res.status(500).json({ code: 'INTERNAL_ERROR', message: 'An unexpected error occurred' });
    }
  }
);

// GET /api/treasury/orgs/:id/financial-summary
// Optional query: ?fiscal_year=2026 (latest available FY if omitted)
// Cross-team request (Treasury Tracker, 2026-06-20): reconciled per-org financial
// summary (treasury.org_financial_summary) for the donor-facing transparency view.
// Always-sourced, public read. NOTE: /orgs/ is its own namespace — no static-path-
// before-:id collision with /cities or /federal. Service uses SELECT * so the
// goal_amount/goal_label columns (Treasury Tracker Phase 76 migration) serve forward-safely.
router.get(
  '/orgs/:id/financial-summary',
  optionalAuth,
  async (req: Request, res: Response): Promise<void> => {
    const id = req.params.id as string;
    if (!UUID_REGEX.test(id)) {
      res.status(422).json({ code: 'INVALID_ID', message: 'Invalid UUID format' });
      return;
    }

    const fiscalYearRaw = req.query.fiscal_year as string | undefined;
    let fiscalYear: number | undefined;
    if (fiscalYearRaw !== undefined) {
      const parsed = Number(fiscalYearRaw);
      if (!Number.isInteger(parsed) || parsed < 1900 || parsed > 2100) {
        res.status(422).json({ code: 'VALIDATION_ERROR', message: 'Invalid fiscal_year' });
        return;
      }
      fiscalYear = parsed;
    }

    try {
      const summary = await getOrgFinancialSummary(id, fiscalYear);
      if (!summary) {
        res.status(404).json({ code: 'NOT_FOUND', message: 'Org financial summary not found' });
        return;
      }
      res.status(200).json(summary);
    } catch (err) {
      console.error('[GET /treasury/orgs/:id/financial-summary] error:', err);
      res.status(500).json({ code: 'INTERNAL_ERROR', message: 'An unexpected error occurred' });
    }
  }
);

// GET /api/treasury/budgets/:id
router.get('/budgets/:id', optionalAuth, async (req: Request, res: Response): Promise<void> => {
  const id = req.params.id as string;
  if (!UUID_REGEX.test(id)) {
    res.status(422).json({ code: 'INVALID_ID', message: 'Invalid UUID format' });
    return;
  }

  try {
    const budget = await getBudgetById(id);
    if (!budget) {
      res.status(404).json({ code: 'NOT_FOUND', message: 'Budget not found' });
      return;
    }
    res.status(200).json(budget);
  } catch (err) {
    console.error('[GET /treasury/budgets/:id] error:', err);
    res.status(500).json({ code: 'INTERNAL_ERROR', message: 'An unexpected error occurred' });
  }
});

// GET /api/treasury/budgets/:id/categories
router.get(
  '/budgets/:id/categories',
  optionalAuth,
  async (req: Request, res: Response): Promise<void> => {
    const id = req.params.id as string;
    if (!UUID_REGEX.test(id)) {
      res.status(422).json({ code: 'INVALID_ID', message: 'Invalid UUID format' });
      return;
    }

    try {
      const budget = await getBudgetById(id);
      if (!budget) {
        res.status(404).json({ code: 'NOT_FOUND', message: 'Budget not found' });
        return;
      }
      res.status(200).json(budget.categories);
    } catch (err) {
      console.error('[GET /treasury/budgets/:id/categories] error:', err);
      res.status(500).json({ code: 'INTERNAL_ERROR', message: 'An unexpected error occurred' });
    }
  }
);

// GET /api/treasury/budgets/:id/line-items
router.get(
  '/budgets/:id/line-items',
  optionalAuth,
  async (req: Request, res: Response): Promise<void> => {
    const id = req.params.id as string;
    if (!UUID_REGEX.test(id)) {
      res.status(422).json({ code: 'INVALID_ID', message: 'Invalid UUID format' });
      return;
    }

    try {
      const lineItems = await getLineItemsByBudgetId(id);
      res.status(200).json(lineItems);
    } catch (err) {
      console.error('[GET /treasury/budgets/:id/line-items] error:', err);
      res.status(500).json({ code: 'INTERNAL_ERROR', message: 'An unexpected error occurred' });
    }
  }
);

// GET /api/treasury/budgets/:id/transactions?link_key=fire|main&limit=20
// Returns a LinkedTransactionSummary for transactions matching the link_key prefix.
// Prefix matching: link_key=fire matches fire|main|general|supplies etc.
router.get(
  '/budgets/:id/transactions',
  optionalAuth,
  async (req: Request, res: Response): Promise<void> => {
    const id = req.params.id as string;
    if (!UUID_REGEX.test(id)) {
      res.status(422).json({ code: 'INVALID_ID', message: 'Invalid UUID format' });
      return;
    }

    const linkKey = req.query.link_key as string | undefined;
    if (!linkKey) {
      res.status(422).json({ code: 'MISSING_PARAM', message: 'link_key query parameter is required' });
      return;
    }

    const limit = Math.min(parseInt(req.query.limit as string) || 20, 100);

    try {
      const summary = await getLinkedTransactions(id, linkKey, limit);
      if (!summary) {
        res.status(200).json(null);
        return;
      }
      res.status(200).json(summary);
    } catch (err) {
      console.error('[GET /treasury/budgets/:id/transactions] error:', err);
      res.status(500).json({ code: 'INTERNAL_ERROR', message: 'An unexpected error occurred' });
    }
  }
);

// GET /api/treasury/search?q=roads&city_id=uuid&year=2025&limit=20
// Natural language search across enriched category names, descriptions, and tags.
router.get('/search', optionalAuth, async (req: Request, res: Response): Promise<void> => {
  const q = req.query.q as string | undefined;
  if (!q || q.trim().length < 2) {
    res.status(422).json({ code: 'MISSING_PARAM', message: 'q (query) must be at least 2 characters' });
    return;
  }

  const cityId = req.query.city_id as string | undefined;
  if (cityId && !UUID_REGEX.test(cityId)) {
    res.status(422).json({ code: 'INVALID_ID', message: 'city_id must be a valid UUID' });
    return;
  }

  const fiscalYearRaw = req.query.year as string | undefined;
  let fiscalYear: number | undefined;
  if (fiscalYearRaw !== undefined) {
    const parsed = Number(fiscalYearRaw);
    if (!Number.isInteger(parsed) || parsed < 1900 || parsed > 2100) {
      res.status(422).json({ code: 'VALIDATION_ERROR', message: 'Invalid year' });
      return;
    }
    fiscalYear = parsed;
  }

  const limit = Math.min(parseInt(req.query.limit as string) || 20, 50);

  try {
    const results = await searchCategories(q.trim(), cityId, fiscalYear, limit);
    res.status(200).json(results);
  } catch (err) {
    console.error('[GET /treasury/search] error:', err);
    res.status(500).json({ code: 'INTERNAL_ERROR', message: 'An unexpected error occurred' });
  }
});

// ---------------------------------------------------------------------------
// Admin read routes (requireAuth + requireAdmin)
// ---------------------------------------------------------------------------

// GET /api/treasury/enrichment-queue/status
router.get(
  '/enrichment-queue/status',
  requireAuth,
  requireAdmin,
  async (_req: Request, res: Response): Promise<void> => {
    try {
      const status = await getEnrichmentQueueStatus();
      // Compute next scheduled run: next 2am UTC
      const now = new Date();
      const next = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate(), 2, 0, 0));
      if (next <= now) next.setUTCDate(next.getUTCDate() + 1);
      res.status(200).json({ ...status, next_scheduled: next.toISOString() });
    } catch (err) {
      console.error('[GET /treasury/enrichment-queue/status] error:', err);
      res.status(500).json({ code: 'INTERNAL_ERROR', message: 'An unexpected error occurred' });
    }
  }
);

// ---------------------------------------------------------------------------
// Admin write routes (requireAuth + requireAdmin)
// ---------------------------------------------------------------------------

// POST /api/treasury/cities
const createCitySchema = z.object({
  name: z.string().min(1),
  state: z.string().min(1),
  population: z.number().int().positive().optional().nullable(),
  entityType: z.string().min(1).optional().nullable(), // enables TIGER geo_id resolution at insert
});

router.post(
  '/cities',
  requireAuth,
  requireAdmin,
  async (req: Request, res: Response): Promise<void> => {
    const parsed = createCitySchema.safeParse(req.body);
    if (!parsed.success) {
      res.status(422).json({ code: 'VALIDATION_ERROR', message: parsed.error.message });
      return;
    }

    try {
      const city = await createCity(parsed.data);
      res.status(201).json(city);
    } catch (err) {
      console.error('[POST /treasury/cities] error:', err);
      res.status(500).json({ code: 'INTERNAL_ERROR', message: 'An unexpected error occurred' });
    }
  }
);

// POST /api/treasury/budgets
const createBudgetSchema = z.object({
  cityId: z.string().uuid(),
  fiscalYear: z.number().int(),
  datasetType: z.string().min(1),
  totalBudget: z.number(),
  dataSource: z.string().optional().nullable(),
  hierarchy: z.array(z.string()).optional().nullable(),
});

router.post(
  '/budgets',
  requireAuth,
  requireAdmin,
  async (req: Request, res: Response): Promise<void> => {
    const parsed = createBudgetSchema.safeParse(req.body);
    if (!parsed.success) {
      res.status(422).json({ code: 'VALIDATION_ERROR', message: parsed.error.message });
      return;
    }

    try {
      const budget = await createBudget(parsed.data);
      res.status(201).json(budget);
    } catch (err) {
      console.error('[POST /treasury/budgets] error:', err);
      res.status(500).json({ code: 'INTERNAL_ERROR', message: 'An unexpected error occurred' });
    }
  }
);

// POST /api/treasury/budgets/:id/categories
const createBudgetCategorySchema = z.object({
  parentId: z.string().uuid().optional().nullable(),
  name: z.string().min(1),
  amount: z.number(),
  percentage: z.number().optional().nullable(),
  color: z.string().optional().nullable(),
  description: z.string().optional().nullable(),
  whyMatters: z.string().optional().nullable(),
  historicalChange: z.number().optional().nullable(),
  itemCount: z.number().int().optional().nullable(),
  sortOrder: z.number().int().optional().nullable(),
  depth: z.number().int().optional().nullable(),
  linkKey: z.string().optional().nullable(),
});

router.post(
  '/budgets/:id/categories',
  requireAuth,
  requireAdmin,
  async (req: Request, res: Response): Promise<void> => {
    const id = req.params.id as string;
    if (!UUID_REGEX.test(id)) {
      res.status(422).json({ code: 'INVALID_ID', message: 'Invalid UUID format' });
      return;
    }

    const parsed = createBudgetCategorySchema.safeParse(req.body);
    if (!parsed.success) {
      res.status(422).json({ code: 'VALIDATION_ERROR', message: parsed.error.message });
      return;
    }

    try {
      const category = await createBudgetCategory(id, parsed.data);
      res.status(201).json(category);
    } catch (err) {
      console.error('[POST /treasury/budgets/:id/categories] error:', err);
      res.status(500).json({ code: 'INTERNAL_ERROR', message: 'An unexpected error occurred' });
    }
  }
);

// POST /api/treasury/budgets/:id/line-items
// Route :id is the budget UUID; categoryId must be supplied in the request body
// as a valid budget_categories.id for the FK constraint to succeed.
const createBudgetLineItemSchema = z.object({
  categoryId: z.string().uuid(),  // required — must be a valid budget_categories.id
  description: z.string().min(1),
  approvedAmount: z.number().optional().nullable(),
  actualAmount: z.number().optional().nullable(),
  basePay: z.number().optional().nullable(),
  benefits: z.number().optional().nullable(),
  overtime: z.number().optional().nullable(),
  other: z.number().optional().nullable(),
  startDate: z.string().optional().nullable(),
  vendor: z.string().optional().nullable(),
  date: z.string().optional().nullable(),
  paymentMethod: z.string().optional().nullable(),
  invoiceNumber: z.string().optional().nullable(),
  fund: z.string().optional().nullable(),
  expenseCategory: z.string().optional().nullable(),
});

router.post(
  '/budgets/:id/line-items',
  requireAuth,
  requireAdmin,
  async (req: Request, res: Response): Promise<void> => {
    const id = req.params.id as string;
    if (!UUID_REGEX.test(id)) {
      res.status(422).json({ code: 'INVALID_ID', message: 'Invalid UUID format' });
      return;
    }

    const parsed = createBudgetLineItemSchema.safeParse(req.body);
    if (!parsed.success) {
      res.status(422).json({ code: 'VALIDATION_ERROR', message: parsed.error.message });
      return;
    }

    try {
      const lineItem = await createBudgetLineItem(parsed.data.categoryId, parsed.data);
      res.status(201).json(lineItem);
    } catch (err) {
      console.error('[POST /treasury/budgets/:id/line-items] error:', err);
      res.status(500).json({ code: 'INTERNAL_ERROR', message: 'An unexpected error occurred' });
    }
  }
);

export default router;
