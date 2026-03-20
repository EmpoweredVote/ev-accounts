/**
 * treasuryService — city budget data lookups for the treasury schema.
 *
 * WHY THIS FILE EXISTS:
 * The treasury schema is NOT in the PostgREST exposed schema list
 * (`public, connect, empower, inform, graphql_public, validation_quests`).
 * `supabaseAnon.schema('treasury')` would fail at runtime.
 * ALL treasury reads AND writes must use pool.query() (direct postgres).
 *
 * Purpose: Satisfies CONS-08 — Treasury endpoints served by ev-accounts.
 *
 * All response objects are built from EXPLICIT field whitelists. DB rows are
 * NEVER spread into responses.
 *
 * Bigint note: The pg driver returns bigint columns as JavaScript strings.
 * Always call Number() on: population, fiscal_year, item_count, sort_order, depth.
 * Use `value !== null ? Number(value) : null` for nullable numerics.
 */

import { pool } from './db.js';

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

export interface TreasuryCity {
  id: string;
  name: string;
  state: string;
  population: number | null;
  createdAt: string;
  updatedAt: string;
}

export interface TreasuryBudget {
  id: string;
  cityId: string;
  fiscalYear: number;
  datasetType: string;
  totalBudget: number;
  dataSource: string | null;
  hierarchy: string[] | null;
  generatedAt: string | null;
  createdAt: string;
  updatedAt: string;
}

export interface TreasuryBudgetCategory {
  id: string;
  budgetId: string;
  parentId: string | null;
  name: string;
  amount: number;
  percentage: number | null;
  color: string | null;
  description: string | null;
  whyMatters: string | null;
  historicalChange: number | null;
  itemCount: number;
  sortOrder: number;
  depth: number;
  linkKey: string | null;
}

export interface TreasuryBudgetLineItem {
  id: string;
  categoryId: string;
  description: string;
  approvedAmount: number | null;
  actualAmount: number | null;
  basePay: number | null;
  benefits: number | null;
  overtime: number | null;
  other: number | null;
  startDate: string | null;
  vendor: string | null;
  date: string | null;
  paymentMethod: string | null;
  invoiceNumber: string | null;
  fund: string | null;
  expenseCategory: string | null;
}

// ---------------------------------------------------------------------------
// Row type helpers (pg query result shapes)
// ---------------------------------------------------------------------------

interface CityRow {
  id: string;
  name: string;
  state: string;
  population: string | null; // bigint returned as string by pg driver
  created_at: string;
  updated_at: string;
}

interface BudgetRow {
  id: string;
  city_id: string;
  fiscal_year: string; // bigint returned as string
  dataset_type: string;
  total_budget: string; // numeric returned as string
  data_source: string | null;
  hierarchy: string[] | null;
  generated_at: string | null;
  created_at: string;
  updated_at: string;
}

interface CategoryRow {
  id: string;
  budget_id: string;
  parent_id: string | null;
  name: string;
  amount: string; // numeric
  percentage: string | null; // numeric
  color: string | null;
  description: string | null;
  why_matters: string | null;
  historical_change: string | null; // numeric
  item_count: string | null; // bigint
  sort_order: string | null; // bigint
  depth: string | null; // bigint
  link_key: string | null;
}

interface LineItemRow {
  id: string;
  category_id: string;
  description: string;
  approved_amount: string | null; // numeric
  actual_amount: string | null; // numeric
  base_pay: string | null; // numeric
  benefits: string | null; // numeric
  overtime: string | null; // numeric
  other: string | null; // numeric
  start_date: string | null;
  vendor: string | null;
  date: string | null;
  payment_method: string | null;
  invoice_number: string | null;
  fund: string | null;
  expense_category: string | null;
}

// ---------------------------------------------------------------------------
// Mappers (explicit camelCase — NEVER spread rows)
// ---------------------------------------------------------------------------

function mapCity(row: CityRow): TreasuryCity {
  return {
    id: row.id,
    name: row.name,
    state: row.state,
    population: row.population !== null ? Number(row.population) : null,
    createdAt: row.created_at,
    updatedAt: row.updated_at,
  };
}

function mapBudget(row: BudgetRow): TreasuryBudget {
  return {
    id: row.id,
    cityId: row.city_id,
    fiscalYear: Number(row.fiscal_year),
    datasetType: row.dataset_type,
    totalBudget: Number(row.total_budget),
    dataSource: row.data_source,
    hierarchy: row.hierarchy,
    generatedAt: row.generated_at,
    createdAt: row.created_at,
    updatedAt: row.updated_at,
  };
}

function mapCategory(row: CategoryRow): TreasuryBudgetCategory {
  return {
    id: row.id,
    budgetId: row.budget_id,
    parentId: row.parent_id,
    name: row.name,
    amount: Number(row.amount),
    percentage: row.percentage !== null ? Number(row.percentage) : null,
    color: row.color,
    description: row.description,
    whyMatters: row.why_matters,
    historicalChange: row.historical_change !== null ? Number(row.historical_change) : null,
    itemCount: row.item_count !== null ? Number(row.item_count) : 0,
    sortOrder: row.sort_order !== null ? Number(row.sort_order) : 0,
    depth: row.depth !== null ? Number(row.depth) : 0,
    linkKey: row.link_key,
  };
}

function mapLineItem(row: LineItemRow): TreasuryBudgetLineItem {
  return {
    id: row.id,
    categoryId: row.category_id,
    description: row.description,
    approvedAmount: row.approved_amount !== null ? Number(row.approved_amount) : null,
    actualAmount: row.actual_amount !== null ? Number(row.actual_amount) : null,
    basePay: row.base_pay !== null ? Number(row.base_pay) : null,
    benefits: row.benefits !== null ? Number(row.benefits) : null,
    overtime: row.overtime !== null ? Number(row.overtime) : null,
    other: row.other !== null ? Number(row.other) : null,
    startDate: row.start_date,
    vendor: row.vendor,
    date: row.date,
    paymentMethod: row.payment_method,
    invoiceNumber: row.invoice_number,
    fund: row.fund,
    expenseCategory: row.expense_category,
  };
}

// ---------------------------------------------------------------------------
// Public read functions
// ---------------------------------------------------------------------------

/**
 * Fetch all cities ordered by name.
 */
export async function getCities(): Promise<TreasuryCity[]> {
  const { rows } = await pool.query<CityRow>(
    `SELECT id, name, state, population, created_at, updated_at
     FROM treasury.cities
     ORDER BY name`
  );
  return rows.map(mapCity);
}

/**
 * Fetch a single city by UUID. Returns null if not found.
 */
export async function getCityById(id: string): Promise<TreasuryCity | null> {
  const { rows } = await pool.query<CityRow>(
    `SELECT id, name, state, population, created_at, updated_at
     FROM treasury.cities
     WHERE id = $1`,
    [id]
  );
  return rows.length > 0 ? mapCity(rows[0]) : null;
}

/**
 * Fetch budgets for a city, optionally filtered by fiscal year.
 */
export async function getBudgetsByCityId(
  cityId: string,
  fiscalYear?: number
): Promise<TreasuryBudget[]> {
  if (fiscalYear !== undefined) {
    const { rows } = await pool.query<BudgetRow>(
      `SELECT id, city_id, fiscal_year, dataset_type, total_budget,
              data_source, hierarchy, generated_at, created_at, updated_at
       FROM treasury.budgets
       WHERE city_id = $1 AND fiscal_year = $2
       ORDER BY fiscal_year DESC`,
      [cityId, fiscalYear]
    );
    return rows.map(mapBudget);
  }

  const { rows } = await pool.query<BudgetRow>(
    `SELECT id, city_id, fiscal_year, dataset_type, total_budget,
            data_source, hierarchy, generated_at, created_at, updated_at
     FROM treasury.budgets
     WHERE city_id = $1
     ORDER BY fiscal_year DESC`,
    [cityId]
  );
  return rows.map(mapBudget);
}

/**
 * Fetch a budget by UUID with its flat sorted categories.
 * Returns null if not found.
 */
export async function getBudgetById(
  id: string
): Promise<(TreasuryBudget & { categories: TreasuryBudgetCategory[] }) | null> {
  const { rows: budgetRows } = await pool.query<BudgetRow>(
    `SELECT id, city_id, fiscal_year, dataset_type, total_budget,
            data_source, hierarchy, generated_at, created_at, updated_at
     FROM treasury.budgets
     WHERE id = $1`,
    [id]
  );

  if (budgetRows.length === 0) return null;

  const budget = mapBudget(budgetRows[0]);

  const { rows: categoryRows } = await pool.query<CategoryRow>(
    `SELECT id, budget_id, parent_id, name, amount, percentage, color,
            description, why_matters, historical_change, item_count, sort_order, depth, link_key
     FROM treasury.budget_categories
     WHERE budget_id = $1
     ORDER BY depth, sort_order`,
    [id]
  );

  return {
    ...budget,
    categories: categoryRows.map(mapCategory),
  };
}

/**
 * Fetch all line items for a budget (via budget_categories join).
 */
export async function getLineItemsByBudgetId(
  budgetId: string
): Promise<TreasuryBudgetLineItem[]> {
  const { rows } = await pool.query<LineItemRow>(
    `SELECT id, category_id, description, approved_amount, actual_amount,
            base_pay, benefits, overtime, other, start_date, vendor, date,
            payment_method, invoice_number, fund, expense_category
     FROM treasury.budget_line_items
     WHERE category_id IN (
       SELECT id FROM treasury.budget_categories WHERE budget_id = $1
     )`,
    [budgetId]
  );
  return rows.map(mapLineItem);
}

// ---------------------------------------------------------------------------
// Admin write functions
// ---------------------------------------------------------------------------

/**
 * Create a new city.
 */
export async function createCity(data: {
  name: string;
  state: string;
  population?: number | null;
}): Promise<TreasuryCity> {
  const { rows } = await pool.query<CityRow>(
    `INSERT INTO treasury.cities (name, state, population)
     VALUES ($1, $2, $3)
     RETURNING id, name, state, population, created_at, updated_at`,
    [data.name, data.state, data.population ?? null]
  );
  return mapCity(rows[0]);
}

/**
 * Create a new budget for a city.
 */
export async function createBudget(data: {
  cityId: string;
  fiscalYear: number;
  datasetType: string;
  totalBudget: number;
  dataSource?: string | null;
  hierarchy?: string[] | null;
}): Promise<TreasuryBudget> {
  const { rows } = await pool.query<BudgetRow>(
    `INSERT INTO treasury.budgets (city_id, fiscal_year, dataset_type, total_budget, data_source, hierarchy)
     VALUES ($1, $2, $3, $4, $5, $6)
     RETURNING id, city_id, fiscal_year, dataset_type, total_budget, data_source, hierarchy, generated_at, created_at, updated_at`,
    [data.cityId, data.fiscalYear, data.datasetType, data.totalBudget, data.dataSource ?? null, data.hierarchy ?? null]
  );
  return mapBudget(rows[0]);
}

/**
 * Create a budget category.
 */
export async function createBudgetCategory(
  budgetId: string,
  data: {
    parentId?: string | null;
    name: string;
    amount: number;
    percentage?: number | null;
    color?: string | null;
    description?: string | null;
    whyMatters?: string | null;
    historicalChange?: number | null;
    itemCount?: number | null;
    sortOrder?: number | null;
    depth?: number | null;
    linkKey?: string | null;
  }
): Promise<TreasuryBudgetCategory> {
  const { rows } = await pool.query<CategoryRow>(
    `INSERT INTO treasury.budget_categories
       (budget_id, parent_id, name, amount, percentage, color, description,
        why_matters, historical_change, item_count, sort_order, depth, link_key)
     VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13)
     RETURNING id, budget_id, parent_id, name, amount, percentage, color,
               description, why_matters, historical_change, item_count, sort_order, depth, link_key`,
    [
      budgetId,
      data.parentId ?? null,
      data.name,
      data.amount,
      data.percentage ?? null,
      data.color ?? null,
      data.description ?? null,
      data.whyMatters ?? null,
      data.historicalChange ?? null,
      data.itemCount ?? null,
      data.sortOrder ?? null,
      data.depth ?? null,
      data.linkKey ?? null,
    ]
  );
  return mapCategory(rows[0]);
}

/**
 * Create a budget line item under a category.
 */
export async function createBudgetLineItem(
  categoryId: string,
  data: {
    description: string;
    approvedAmount?: number | null;
    actualAmount?: number | null;
    basePay?: number | null;
    benefits?: number | null;
    overtime?: number | null;
    other?: number | null;
    startDate?: string | null;
    vendor?: string | null;
    date?: string | null;
    paymentMethod?: string | null;
    invoiceNumber?: string | null;
    fund?: string | null;
    expenseCategory?: string | null;
  }
): Promise<TreasuryBudgetLineItem> {
  const { rows } = await pool.query<LineItemRow>(
    `INSERT INTO treasury.budget_line_items
       (category_id, description, approved_amount, actual_amount, base_pay,
        benefits, overtime, other, start_date, vendor, date, payment_method,
        invoice_number, fund, expense_category)
     VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15)
     RETURNING id, category_id, description, approved_amount, actual_amount,
               base_pay, benefits, overtime, other, start_date, vendor, date,
               payment_method, invoice_number, fund, expense_category`,
    [
      categoryId,
      data.description,
      data.approvedAmount ?? null,
      data.actualAmount ?? null,
      data.basePay ?? null,
      data.benefits ?? null,
      data.overtime ?? null,
      data.other ?? null,
      data.startDate ?? null,
      data.vendor ?? null,
      data.date ?? null,
      data.paymentMethod ?? null,
      data.invoiceNumber ?? null,
      data.fund ?? null,
      data.expenseCategory ?? null,
    ]
  );
  return mapLineItem(rows[0]);
}
