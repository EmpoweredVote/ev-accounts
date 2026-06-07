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
// geo_id resolution — link treasury.municipalities to the TIGER geofence backbone
// ---------------------------------------------------------------------------
// treasury.municipalities.state is a 2-letter code (CA/IN); essentials.geofence_boundaries.state
// is FIPS (06/18). This mirrors the FIPS↔abbr maps in scripts/backfill-district-ocd.ts
// (FIPS_TO_ABBR) and scripts/coverage-init.ts (STATE_FIPS) — keep in sync when a new
// state is onboarded.
export const STATE_ABBR_TO_FIPS: Record<string, string> = {
  al: '01', ak: '02', az: '04', ar: '05', ca: '06', co: '08', ct: '09', de: '10',
  dc: '11', fl: '12', ga: '13', hi: '15', id: '16', il: '17', in: '18', ia: '19',
  ks: '20', ky: '21', la: '22', me: '23', md: '24', ma: '25', mi: '26', mn: '27',
  ms: '28', mo: '29', mt: '30', ne: '31', nv: '32', nh: '33', nj: '34', nm: '35',
  ny: '36', nc: '37', nd: '38', oh: '39', ok: '40', or: '41', pa: '42', ri: '44',
  sc: '45', sd: '46', tn: '47', tx: '48', ut: '49', vt: '50', va: '51', wa: '53',
  wv: '54', wi: '55', wy: '56',
};

// entity_type → TIGER MTFCC layer. ONLY these entity types map to a geofence;
// townships, libraries, special/nonprofit/conservancy districts have no TIGER place
// geometry, so their geo_id legitimately stays NULL.
export const TREASURY_ENTITY_MTFCC: Record<string, string> = {
  city: 'G4110',
  town: 'G4110',
  municipality: 'G4110',
  county: 'G4020',
  school_district: 'G5420',
};

function slugify(s: string): string {
  return s
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, "") // strip diacritics: accented letters -> ASCII (e.g. "La Cañada" -> "La Canada")
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '_')
    .replace(/^_+|_+$/g, '');
}

/**
 * Treasury-side name slug. Kept whole except counties strip a trailing " County".
 * Mirrors coverageService.treasurySlug() so geo_id parity is ≥ the old name-match
 * (e.g. "Culver City" stays "culver_city", not "culver").
 */
export function treasuryNameSlug(name: string, entityType: string): string {
  const cleaned = entityType === 'county' ? name.replace(/ county$/i, '') : name;
  return slugify(cleaned);
}

// Geofence-side: strip the TIGER layer suffix for the row's mtfcc before slugging.
const GEOFENCE_STRIP: Record<string, RegExp> = {
  G4110: / (city|town|village|borough|cdp|municipality)$/i,
  G4020: / county$/i,
  G5420: / school district$/i,
};

/** Geofence-side name slug for a given mtfcc (strips the TIGER suffix). */
export function geofenceNameSlug(name: string, mtfcc: string): string {
  return slugify(name.replace(GEOFENCE_STRIP[mtfcc] ?? /$/, ''));
}

/**
 * Resolve the TIGER geo_id for a treasury municipality by normalized name + state,
 * scoped to the mtfcc for its entity_type. Returns null for unmatched rows
 * (townships/libraries/special/nonprofit, or a genuine name mismatch) and for
 * ambiguous matches (>1 geofence with the same slug — conservative).
 *
 * Used by the budget importers (createCity, importCambridge, importBudgetHierarchy)
 * so new municipalities get a geo_id at insert time and future data pulls stay linked.
 */
export async function resolveTreasuryGeoId(
  name: string,
  state: string,
  entityType: string | null,
): Promise<string | null> {
  const mtfcc = entityType ? TREASURY_ENTITY_MTFCC[entityType] : undefined;
  if (!mtfcc) return null;
  const fips = STATE_ABBR_TO_FIPS[state.toLowerCase()];
  if (!fips) return null;
  const target = treasuryNameSlug(name, entityType!);
  const { rows } = await pool.query<{ geo_id: string; name: string }>(
    `SELECT geo_id, name FROM essentials.geofence_boundaries WHERE state = $1 AND mtfcc = $2`,
    [fips, mtfcc],
  );
  const matches = rows.filter((r) => geofenceNameSlug(r.name, mtfcc) === target);
  return matches.length === 1 ? matches[0].geo_id : null;
}

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

export interface TreasuryDataset {
  fiscal_year: number;
  dataset_type: string;
}

export interface TreasuryCity {
  id: string;
  name: string;
  state: string;
  entity_type: string | null;
  population: number | null;
  population_year: number | null;
  county_id: string | null;
  hero_image_url: string | null;
  created_at: string;
  updated_at: string;
  available_datasets: TreasuryDataset[];
}

export interface TreasuryBudget {
  id: string;
  municipality_id: string;
  fiscal_year: number;
  dataset_type: string;
  total_budget: number;
  data_source: string | null;
  data_source_info: { displayName: string; url: string } | null;
  hierarchy: string[] | null;
  generated_at: string | null;
  created_at: string;
  updated_at: string;
}

export interface TreasuryBudgetCategory {
  id: string;
  budget_id: string;
  parent_id: string | null;
  name: string;
  amount: number;
  percentage: number | null;
  color: string | null;
  description: string | null;
  why_matters: string | null;
  historical_change: number | null;
  item_count: number;
  sort_order: number;
  depth: number;
  link_key: string | null;
}

export interface TreasuryBudgetLineItem {
  id: string;
  category_id: string;
  description: string;
  approved_amount: number | null;
  actual_amount: number | null;
  base_pay: number | null;
  benefits: number | null;
  overtime: number | null;
  other: number | null;
  start_date: string | null;
  vendor: string | null;
  date: string | null;
  payment_method: string | null;
  invoice_number: string | null;
  fund: string | null;
  expense_category: string | null;
}

export interface LinkedTransactionSummary {
  totalAmount: number;
  transactionCount: number;
  vendorCount: number;
  topVendors: Array<{ name: string; amount: number; count: number }>;
  transactions: Array<{
    description: string;
    amount: number;
    vendor: string;
    date: string;
    paymentMethod: string | null;
    invoiceNumber: string | null;
    fund: string;
    expenseCategory: string;
  }>;
  hasMore: boolean;
}

// ---------------------------------------------------------------------------
// Row type helpers (pg query result shapes)
// ---------------------------------------------------------------------------

interface CityRow {
  id: string;
  name: string;
  state: string;
  entity_type: string | null;
  population: string | null; // bigint returned as string by pg driver
  population_year: string | null; // INTEGER returned as string by node-postgres
  county_id: string | null;
  hero_image_url: string | null;
  created_at: string;
  updated_at: string;
  // Joined from budgets — aggregated as JSON array
  available_datasets: Array<{ fiscal_year: string; dataset_type: string }> | null;
}

interface BudgetRow {
  id: string;
  municipality_id: string;
  fiscal_year: string; // bigint returned as string
  dataset_type: string;
  total_budget: string; // numeric returned as string
  data_source: string | null;
  ds_display_name: string | null;
  ds_url: string | null;
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
  actual_amount: string | null; // numeric
  percentage: string | null; // numeric
  color: string | null;
  description: string | null;
  why_matters: string | null;
  historical_change: string | null; // numeric
  item_count: string | null; // bigint
  sort_order: string | null; // bigint
  depth: string | null; // bigint
  link_key: string | null;
  // Joined from category_enrichment (may be null if no enrichment found)
  enrich_plain_name: string | null;
  enrich_short_description: string | null;
  enrich_description: string | null;
  enrich_tags: string[] | null;
  enrich_source: string | null;
  enrich_source_label: string | null;
  enrich_source_url: string | null;
  enrich_confidence: string | null;
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

interface TransactionRow {
  id: string;
  amount: string; // numeric
  description: string | null;
  payment_date: string | null;
  payment_method: string | null;
  invoice_number: string | null;
  fund: string | null;
  expense_category: string | null;
  vendor_name: string | null; // joined from vendors table
}

// ---------------------------------------------------------------------------
// Mappers (explicit camelCase — NEVER spread rows)
// ---------------------------------------------------------------------------

function mapCity(row: CityRow): TreasuryCity {
  return {
    id: row.id,
    name: row.name,
    state: row.state,
    entity_type: row.entity_type,
    population: row.population !== null ? Number(row.population) : null,
    population_year: row.population_year !== null ? Number(row.population_year) : null,
    county_id: row.county_id ?? null,
    hero_image_url: row.hero_image_url,
    created_at: row.created_at,
    updated_at: row.updated_at,
    available_datasets: (row.available_datasets ?? []).map((d) => ({
      fiscal_year: Number(d.fiscal_year),
      dataset_type: d.dataset_type,
    })),
  };
}

function mapBudget(row: BudgetRow): TreasuryBudget {
  return {
    id: row.id,
    municipality_id: row.municipality_id,
    fiscal_year: Number(row.fiscal_year),
    dataset_type: row.dataset_type,
    total_budget: Number(row.total_budget),
    data_source: row.data_source,
    data_source_info: row.ds_display_name && row.ds_url ? {
      displayName: row.ds_display_name,
      url: row.ds_url,
    } : null,
    hierarchy: row.hierarchy,
    generated_at: row.generated_at,
    created_at: row.created_at,
    updated_at: row.updated_at,
  };
}

function mapCategory(row: CategoryRow): TreasuryBudgetCategory {
  return {
    id: row.id,
    budget_id: row.budget_id,
    parent_id: row.parent_id,
    name: row.name,
    amount: Number(row.amount),
    percentage: row.percentage !== null ? Number(row.percentage) : null,
    color: row.color,
    description: row.description,
    why_matters: row.why_matters,
    historical_change: row.historical_change !== null ? Number(row.historical_change) : null,
    item_count: row.item_count !== null ? Number(row.item_count) : 0,
    sort_order: row.sort_order !== null ? Number(row.sort_order) : 0,
    depth: row.depth !== null ? Number(row.depth) : 0,
    link_key: row.link_key,
  };
}

function mapLineItem(row: LineItemRow): TreasuryBudgetLineItem {
  return {
    id: row.id,
    category_id: row.category_id,
    description: row.description,
    approved_amount: row.approved_amount !== null ? Number(row.approved_amount) : null,
    actual_amount: row.actual_amount !== null ? Number(row.actual_amount) : null,
    base_pay: row.base_pay !== null ? Number(row.base_pay) : null,
    benefits: row.benefits !== null ? Number(row.benefits) : null,
    overtime: row.overtime !== null ? Number(row.overtime) : null,
    other: row.other !== null ? Number(row.other) : null,
    start_date: row.start_date,
    vendor: row.vendor,
    date: row.date,
    payment_method: row.payment_method,
    invoice_number: row.invoice_number,
    fund: row.fund,
    expense_category: row.expense_category,
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
    `SELECT m.id, m.name, m.state, m.entity_type, m.population, m.population_year, m.county_id, m.hero_image_url,
            m.created_at, m.updated_at,
            COALESCE(
              json_agg(
                json_build_object('fiscal_year', b.fiscal_year, 'dataset_type', b.dataset_type)
                ORDER BY b.fiscal_year DESC
              ) FILTER (WHERE b.id IS NOT NULL),
              '[]'
            ) AS available_datasets
     FROM treasury.municipalities m
     LEFT JOIN treasury.budgets b ON b.municipality_id = m.id
     GROUP BY m.id
     HAVING COUNT(b.id) > 0
     ORDER BY m.name`
  );
  return rows.map(mapCity);
}

/**
 * Fetch a single city by UUID. Returns null if not found OR if the municipality
 * has no associated budgets.
 *
 * CONTRACT: matches getCities() — only returns municipalities with at least one
 * budget (HAVING COUNT(b.id) > 0). If the municipality exists in the DB but has
 * no budget rows, this returns null rather than an entity with an empty
 * available_datasets array. This prevents URL-based navigation from resolving to
 * an entity that the EntitySwitcher would hide (its available_datasets guard)
 * while the budget load silently fails.
 */
export async function getCityById(id: string): Promise<TreasuryCity | null> {
  const { rows } = await pool.query<CityRow>(
    `SELECT m.id, m.name, m.state, m.entity_type, m.population, m.population_year, m.county_id, m.hero_image_url,
            m.created_at, m.updated_at,
            COALESCE(
              json_agg(
                json_build_object('fiscal_year', b.fiscal_year, 'dataset_type', b.dataset_type)
                ORDER BY b.fiscal_year DESC
              ) FILTER (WHERE b.id IS NOT NULL),
              '[]'
            ) AS available_datasets
     FROM treasury.municipalities m
     LEFT JOIN treasury.budgets b ON b.municipality_id = m.id
     WHERE m.id = $1
     GROUP BY m.id
     HAVING COUNT(b.id) > 0`,
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
      `SELECT b.id, b.municipality_id, b.fiscal_year, b.dataset_type, b.total_budget,
              b.data_source, sr.display_name AS ds_display_name, sr.url AS ds_url,
              b.hierarchy, b.generated_at, b.created_at, b.updated_at
       FROM treasury.budgets b
       LEFT JOIN treasury.source_registry sr ON sr.id = b.data_source_id
       WHERE b.municipality_id = $1 AND b.fiscal_year = $2
       ORDER BY b.fiscal_year DESC`,
      [cityId, fiscalYear]
    );
    return rows.map(mapBudget);
  }

  const { rows } = await pool.query<BudgetRow>(
    `SELECT b.id, b.municipality_id, b.fiscal_year, b.dataset_type, b.total_budget,
            b.data_source, sr.display_name AS ds_display_name, sr.url AS ds_url,
            b.hierarchy, b.generated_at, b.created_at, b.updated_at
     FROM treasury.budgets b
     LEFT JOIN treasury.source_registry sr ON sr.id = b.data_source_id
     WHERE b.municipality_id = $1
     ORDER BY b.fiscal_year DESC`,
    [cityId]
  );
  return rows.map(mapBudget);
}

// Enrichment: plain-language context for opaque fund/category names
export interface CategoryEnrichment {
  plainName: string;
  shortDescription: string;
  description: string;
  tags: string[];
  source: string;        // 'official' | 'hybrid' | 'ai'
  sourceLabel: string | null;
  sourceUrl: string | null;
  confidence: string;    // 'high' | 'medium' | 'low'
}

// Nested category with subcategories and lineItems for the frontend (camelCase)
export interface NestedCategory {
  name: string;
  amount: number;
  actualAmount?: number;
  percentage: number;
  color: string;
  description?: string;
  whyMatters?: string;
  historicalChange?: number | null;
  items: number;
  linkKey?: string;
  enrichment?: CategoryEnrichment | null;
  subcategories?: NestedCategory[];
  lineItems?: Array<{
    description: string;
    approvedAmount: number;
    actualAmount: number;
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
  }>;
}

/**
 * Fetch a budget by UUID with nested category tree + lineItems.
 * Returns null if not found.
 */
export async function getBudgetById(
  id: string
): Promise<(TreasuryBudget & { categories: NestedCategory[] }) | null> {
  const { rows: budgetRows } = await pool.query<BudgetRow>(
    `SELECT b.id, b.municipality_id, b.fiscal_year, b.dataset_type, b.total_budget,
            b.data_source, sr.display_name AS ds_display_name, sr.url AS ds_url,
            b.hierarchy, b.generated_at, b.created_at, b.updated_at
     FROM treasury.budgets b
     LEFT JOIN treasury.source_registry sr ON sr.id = b.data_source_id
     WHERE b.id = $1`,
    [id]
  );

  if (budgetRows.length === 0) return null;

  const budget = mapBudget(budgetRows[0]);

  // Fetch all categories, LEFT JOIN enrichment (municipality-specific preferred over universal)
  const { rows: categoryRows } = await pool.query<CategoryRow>(
    `SELECT bc.id, bc.budget_id, bc.parent_id, bc.name, bc.amount, bc.actual_amount, bc.percentage, bc.color,
            bc.description, bc.why_matters, bc.historical_change, bc.item_count, bc.sort_order,
            bc.depth, bc.link_key,
            -- Enrichment: prefer municipality-specific over universal (NULL municipality_id)
            COALESCE(e_city.plain_name,     e_univ.plain_name)     AS enrich_plain_name,
            COALESCE(e_city.short_description, e_univ.short_description) AS enrich_short_description,
            COALESCE(e_city.description,    e_univ.description)    AS enrich_description,
            COALESCE(e_city.tags,           e_univ.tags)           AS enrich_tags,
            COALESCE(e_city.source,         e_univ.source)         AS enrich_source,
            COALESCE(e_city.source_label,   e_univ.source_label)   AS enrich_source_label,
            COALESCE(e_city.source_url,     e_univ.source_url)     AS enrich_source_url,
            COALESCE(e_city.confidence,     e_univ.confidence)     AS enrich_confidence
     FROM treasury.budget_categories bc
     JOIN treasury.budgets b ON b.id = bc.budget_id
     LEFT JOIN treasury.budget_categories bc_parent ON bc_parent.id = bc.parent_id
     -- Municipality-specific enrichment (composite key for subcategories: "parent|name")
     LEFT JOIN treasury.category_enrichment e_city
       ON e_city.name_key = CASE
            WHEN bc.parent_id IS NOT NULL THEN LOWER(TRIM(bc_parent.name)) || '|' || LOWER(TRIM(bc.name))
            ELSE LOWER(TRIM(bc.name))
          END
      AND e_city.municipality_id = b.municipality_id
     -- Universal enrichment fallback (simple name key only, for top-level)
     LEFT JOIN treasury.category_enrichment e_univ
       ON e_univ.name_key = LOWER(TRIM(bc.name))
      AND e_univ.municipality_id IS NULL
     WHERE bc.budget_id = $1
     ORDER BY bc.depth, bc.sort_order`,
    [id]
  );

  // Fetch all line items for this budget in one query
  const { rows: lineItemRows } = await pool.query<LineItemRow>(
    `SELECT id, category_id, description, approved_amount, actual_amount,
            base_pay, benefits, overtime, other, start_date, vendor, date,
            payment_method, invoice_number, fund, expense_category
     FROM treasury.budget_line_items
     WHERE category_id IN (
       SELECT id FROM treasury.budget_categories WHERE budget_id = $1
     )`,
    [id]
  );

  // Group line items by category_id
  const lineItemsByCategory = new Map<string, typeof lineItemRows>();
  for (const li of lineItemRows) {
    const arr = lineItemsByCategory.get(li.category_id) ?? [];
    arr.push(li);
    lineItemsByCategory.set(li.category_id, arr);
  }

  // Build nested tree
  const nodeMap = new Map<string, NestedCategory & { _id: string; _parentId: string | null }>();
  const childrenMap = new Map<string, string[]>();
  const rootIds: string[] = [];

  for (const row of categoryRows) {
    const catLineItems = lineItemsByCategory.get(row.id);
    const node = {
      _id: row.id,
      _parentId: row.parent_id,
      name: row.name,
      amount: Number(row.amount),
      actualAmount: row.actual_amount !== null ? Number(row.actual_amount) : 0,
      percentage: row.percentage !== null ? Number(row.percentage) : 0,
      color: row.color ?? '',
      description: row.description ?? undefined,
      whyMatters: row.why_matters ?? undefined,
      historicalChange: row.historical_change !== null ? Number(row.historical_change) : null,
      items: row.item_count !== null ? Number(row.item_count) : 0,
      linkKey: row.link_key ?? undefined,
      enrichment: row.enrich_plain_name ? {
        plainName: row.enrich_plain_name,
        shortDescription: row.enrich_short_description ?? '',
        description: row.enrich_description ?? '',
        tags: row.enrich_tags ?? [],
        source: row.enrich_source ?? 'ai',
        sourceLabel: row.enrich_source_label,
        sourceUrl: row.enrich_source_url,
        confidence: row.enrich_confidence ?? 'medium',
      } : null,
      subcategories: [] as NestedCategory[],
      lineItems: catLineItems?.map(li => ({
        description: li.description,
        approvedAmount: li.approved_amount !== null ? Number(li.approved_amount) : 0,
        actualAmount: li.actual_amount !== null ? Number(li.actual_amount) : 0,
        basePay: li.base_pay !== null ? Number(li.base_pay) : null,
        benefits: li.benefits !== null ? Number(li.benefits) : null,
        overtime: li.overtime !== null ? Number(li.overtime) : null,
        other: li.other !== null ? Number(li.other) : null,
        startDate: li.start_date,
        vendor: li.vendor,
        date: li.date,
        paymentMethod: li.payment_method,
        invoiceNumber: li.invoice_number,
        fund: li.fund,
        expenseCategory: li.expense_category,
      })),
    };
    nodeMap.set(row.id, node);

    if (row.parent_id === null) {
      rootIds.push(row.id);
    } else {
      const siblings = childrenMap.get(row.parent_id) ?? [];
      siblings.push(row.id);
      childrenMap.set(row.parent_id, siblings);
    }
  }

  // Recursive tree builder
  function buildTree(id: string): NestedCategory {
    const node = nodeMap.get(id)!;
    const childIds = childrenMap.get(id) ?? [];
    const subcategories = childIds.map(buildTree);
    const result: NestedCategory = {
      name: node.name,
      amount: node.amount,
      actualAmount: node.actualAmount,
      percentage: node.percentage,
      color: node.color,
      items: node.items,
    };
    if (node.description) result.description = node.description;
    if (node.whyMatters) result.whyMatters = node.whyMatters;
    if (node.historicalChange !== null) result.historicalChange = node.historicalChange;
    if (node.linkKey) result.linkKey = node.linkKey;
    if (node.enrichment) result.enrichment = node.enrichment;
    if (subcategories.length > 0) result.subcategories = subcategories;
    if (node.lineItems && node.lineItems.length > 0) result.lineItems = node.lineItems;
    return result;
  }

  return {
    ...budget,
    categories: rootIds.map(buildTree),
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

/**
 * Fetch linked transactions for a single category in a budget by link_key prefix.
 * Uses prefix matching so "fire" matches "fire|main|general|supplies" etc.
 * Returns a LinkedTransactionSummary with top vendors and a preview of transactions.
 */
export async function getLinkedTransactions(
  budgetId: string,
  linkKey: string,
  limit: number = 20
): Promise<LinkedTransactionSummary | null> {
  // Match transactions using a 3-tier strategy:
  // 1. Exact link_key prefix match (same data source format)
  // 2. department_aliases table lookup (Gateway→Socrata name mapping)
  // 3. No match → return null

  // Resolve the municipality_id for alias lookups
  const { rows: budgetRows } = await pool.query(
    `SELECT municipality_id FROM treasury.budgets WHERE id = $1`, [budgetId]
  );
  const municipalityId = budgetRows[0]?.municipality_id;

  // Extract the department segment from the category link_key.
  // For pipe-delimited keys like "general|police department (town marshall)|personal services",
  // the last segment is the most specific; the second segment is the department.
  const segments = linkKey.split('|');
  const deptSegment = segments.length >= 2 ? segments[1] : segments[0];

  // Try to resolve via alias table first (most reliable for cross-source matching)
  let txDeptName: string | null = null;
  if (municipalityId) {
    const { rows: aliasRows } = await pool.query(
      `SELECT transaction_name FROM treasury.department_aliases
       WHERE municipality_id = $1 AND budget_name = $2`,
      [municipalityId, deptSegment]
    );
    if (aliasRows.length > 0) {
      txDeptName = aliasRows[0].transaction_name;
    }
  }

  // Build WHERE clause
  let matchWhere: string;
  let matchParams: (string | number)[];

  if (txDeptName) {
    // Alias-based match: match transactions where first segment = alias transaction_name
    // and optionally filter deeper segments for more specific categories
    if (segments.length > 2) {
      // Deep category (e.g. fund|dept|class) — match dept + expense_category
      // Use ILIKE substring match because Gateway classes like "Services and Charges"
      // map to checkbook categories like "Other Services and Charges"
      const classSegment = segments[segments.length - 1];
      matchWhere = `t.budget_id = $1 AND SPLIT_PART(LOWER(t.link_key), '|', 1) = $2
        AND LOWER(t.expense_category) ILIKE '%' || $3 || '%'`;
      matchParams = [budgetId, txDeptName, classSegment];
    } else {
      // Department-level — match all transactions for this department
      matchWhere = `t.budget_id = $1 AND SPLIT_PART(LOWER(t.link_key), '|', 1) = $2`;
      matchParams = [budgetId, txDeptName];
    }
  } else {
    // No alias — match exact link_key or any child key (pipe-delimited prefix)
    // Use explicit LIKE rather than a range bound to avoid capturing keys with
    // characters above '|' (ASCII 124) such as '}' (125) or '~' (126).
    matchWhere = `t.budget_id = $1 AND (LOWER(t.link_key) = $2 OR LOWER(t.link_key) LIKE $2 || '|%')`;
    matchParams = [budgetId, linkKey.toLowerCase()];
  }

  // Run all three queries inside a single READ COMMITTED snapshot transaction so
  // that summary.transaction_count, the top-vendors list, and the preview rows
  // are all computed against the same point-in-time view of the table. Without
  // the transaction a concurrent INSERT/DELETE between queries could produce a
  // count that disagrees with the rows actually returned (confusing "Showing 20
  // of 0 transactions" UI) or a wrong hasMore value.
  const client = await pool.connect();
  let summaryRows: Array<{ transaction_count: number; total_amount: string; vendor_count: number }>;
  let vendorRows: Array<{ name: string; amount: string; count: number }>;
  let txRows: TransactionRow[];
  try {
    await client.query('BEGIN');

    // Count + aggregate
    const summaryResult = await client.query(
      `SELECT
         COUNT(*)::int AS transaction_count,
         COALESCE(SUM(t.amount), 0) AS total_amount,
         COUNT(DISTINCT t.vendor_id)::int AS vendor_count
       FROM treasury.transactions t
       WHERE ${matchWhere}`,
      matchParams
    );
    summaryRows = summaryResult.rows;

    const summary = summaryRows[0];
    if (!summary || summary.transaction_count === 0) {
      await client.query('COMMIT');
      return null;
    }

    // Top 5 vendors by total amount
    const vendorResult = await client.query(
      `SELECT v.name, SUM(t.amount) AS amount, COUNT(*)::int AS count
       FROM treasury.transactions t
       JOIN treasury.vendors v ON v.id = t.vendor_id
       WHERE ${matchWhere}
       GROUP BY v.name
       ORDER BY SUM(t.amount) DESC
       LIMIT 5`,
      matchParams
    );
    vendorRows = vendorResult.rows;

    // Preview transactions (most recent first)
    const txResult = await client.query<TransactionRow>(
      `SELECT t.amount, t.description, t.payment_date, t.payment_method,
              t.invoice_number, t.fund, t.expense_category,
              v.name AS vendor_name
       FROM treasury.transactions t
       LEFT JOIN treasury.vendors v ON v.id = t.vendor_id
       WHERE ${matchWhere}
       ORDER BY t.payment_date DESC
       LIMIT $${matchParams.length + 1}`,
      [...matchParams, limit]
    );
    txRows = txResult.rows;

    await client.query('COMMIT');
  } catch (err) {
    await client.query('ROLLBACK');
    throw err;
  } finally {
    client.release();
  }

  const summary = summaryRows[0];

  return {
    totalAmount: Number(summary.total_amount),
    transactionCount: summary.transaction_count,
    vendorCount: summary.vendor_count,
    topVendors: vendorRows.map(r => ({
      name: r.name,
      amount: Number(r.amount),
      count: r.count,
    })),
    transactions: txRows.map(tx => ({
      description: tx.description || 'No description',
      amount: Number(tx.amount) || 0,
      vendor: tx.vendor_name || 'Unknown',
      date: tx.payment_date || '',
      paymentMethod: tx.payment_method,
      invoiceNumber: tx.invoice_number,
      fund: tx.fund || '',
      expenseCategory: tx.expense_category || '',
    })),
    hasMore: summary.transaction_count > limit,
  };
}

// ---------------------------------------------------------------------------
// Search
// ---------------------------------------------------------------------------

export interface SearchResult {
  categoryId: string;
  budgetId: string;
  categoryName: string;
  plainName: string;
  shortDescription: string;
  amount: number;
  percentage: number;
  datasetType: string;
  fiscalYear: number;
  cityName: string;
  cityState: string;
  tags: string[];
  source: string;
  confidence: string;
}

/**
 * Search budget categories by keyword across enriched names and descriptions.
 * Optionally scoped to a specific city and/or fiscal year.
 */
export async function searchCategories(
  query: string,
  cityId?: string,
  fiscalYear?: number,
  limit: number = 20
): Promise<SearchResult[]> {
  const terms = query.trim().toLowerCase().split(/\s+/).filter(Boolean);
  if (terms.length === 0) return [];

  // Build a LIKE condition for each term against name_key, plain_name, description, tags
  const conditions = terms.map(
    (_, i) => `(
      LOWER(bc.name) LIKE $${i + 1}
      OR LOWER(COALESCE(e_city.plain_name, e_univ.plain_name, '')) LIKE $${i + 1}
      OR LOWER(COALESCE(e_city.short_description, e_univ.short_description, '')) LIKE $${i + 1}
      OR LOWER(COALESCE(e_city.description, e_univ.description, '')) LIKE $${i + 1}
      OR EXISTS (
        SELECT 1 FROM unnest(COALESCE(e_city.tags, e_univ.tags, '{}')) tag
        WHERE LOWER(tag) LIKE $${i + 1}
      )
    )`
  );
  const likeParams = terms.map(t => `%${t}%`);

  let paramOffset = terms.length;
  const extraConditions: string[] = [];
  const extraParams: (string | number)[] = [];

  if (cityId) {
    paramOffset++;
    extraConditions.push(`m.id = $${paramOffset}`);
    extraParams.push(cityId);
  }
  if (fiscalYear) {
    paramOffset++;
    extraConditions.push(`b.fiscal_year = $${paramOffset}`);
    extraParams.push(fiscalYear);
  }

  paramOffset++;
  const limitParam = `$${paramOffset}`;
  extraParams.push(limit);

  const whereClause = [
    `bc.parent_id IS NULL`, // top-level categories only
    ...conditions,
    ...extraConditions,
  ].join(' AND ');

  const sql = `
    SELECT
      bc.id AS category_id,
      bc.budget_id,
      bc.name AS category_name,
      COALESCE(e_city.plain_name, e_univ.plain_name, bc.name) AS plain_name,
      COALESCE(e_city.short_description, e_univ.short_description, '') AS short_description,
      bc.amount,
      bc.percentage,
      b.dataset_type,
      b.fiscal_year,
      m.name AS city_name,
      m.state AS city_state,
      COALESCE(e_city.tags, e_univ.tags, '{}') AS tags,
      COALESCE(e_city.source, e_univ.source, 'unknown') AS source,
      COALESCE(e_city.confidence, e_univ.confidence, 'low') AS confidence
    FROM treasury.budget_categories bc
    JOIN treasury.budgets b ON b.id = bc.budget_id
    JOIN treasury.municipalities m ON m.id = b.municipality_id
    LEFT JOIN treasury.category_enrichment e_city
      ON e_city.name_key = LOWER(TRIM(bc.name))
     AND e_city.municipality_id = m.id
    LEFT JOIN treasury.category_enrichment e_univ
      ON e_univ.name_key = LOWER(TRIM(bc.name))
     AND e_univ.municipality_id IS NULL
    WHERE ${whereClause}
    ORDER BY bc.amount DESC
    LIMIT ${limitParam}
  `;

  const { rows } = await pool.query(sql, [...likeParams, ...extraParams]);

  return rows.map(r => ({
    categoryId: r.category_id,
    budgetId: r.budget_id,
    categoryName: r.category_name,
    plainName: r.plain_name,
    shortDescription: r.short_description,
    amount: Number(r.amount),
    percentage: r.percentage !== null ? Number(r.percentage) : 0,
    datasetType: r.dataset_type,
    fiscalYear: Number(r.fiscal_year),
    cityName: r.city_name,
    cityState: r.city_state,
    tags: r.tags ?? [],
    source: r.source,
    confidence: r.confidence,
  }));
}

// ---------------------------------------------------------------------------
// Enrichment queue
// ---------------------------------------------------------------------------

export interface EnrichmentQueueStatus {
  pending: number;
  processing: number;
  done: number;
  failed: number;
  skipped: number;
}

/**
 * Returns a count breakdown of the enrichment_queue by status.
 */
export async function getEnrichmentQueueStatus(): Promise<EnrichmentQueueStatus> {
  const { rows } = await pool.query<{ status: string; count: string }>(
    `SELECT status, COUNT(*)::int AS count
     FROM treasury.enrichment_queue
     GROUP BY status`
  );

  const counts: Record<string, number> = {
    pending: 0,
    processing: 0,
    done: 0,
    failed: 0,
    skipped: 0,
  };

  for (const row of rows) {
    if (row.status in counts) {
      counts[row.status] = Number(row.count);
    }
  }

  return counts as unknown as EnrichmentQueueStatus;
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
  entityType?: string | null;
}): Promise<TreasuryCity> {
  // Resolve the TIGER geo_id at insert time so the row links to the geofence
  // backbone (coverage join) without a later backfill. Null for unmappable types.
  const geoId = await resolveTreasuryGeoId(data.name, data.state, data.entityType ?? null);
  const { rows } = await pool.query<CityRow>(
    `INSERT INTO treasury.municipalities (name, state, population, entity_type, geo_id)
     VALUES ($1, $2, $3, $4, $5)
     RETURNING id, name, state, entity_type, population, hero_image_url, created_at, updated_at`,
    [data.name, data.state, data.population ?? null, data.entityType ?? null, geoId]
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
    `INSERT INTO treasury.budgets (municipality_id, fiscal_year, dataset_type, total_budget, data_source, hierarchy)
     VALUES ($1, $2, $3, $4, $5, $6)
     RETURNING id, municipality_id, fiscal_year, dataset_type, total_budget, data_source, hierarchy, generated_at, created_at, updated_at`,
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
