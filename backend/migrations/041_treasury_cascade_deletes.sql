-- 041_treasury_cascade_deletes.sql
-- Add ON DELETE CASCADE to treasury hierarchy FKs so deleting a budget row
-- automatically cleans up categories, line_items, and enrichment_queue.
-- transactions.budget_id intentionally stays NO ACTION to preserve tx data across rebuilds.

-- budget_categories.budget_id → budgets.id
ALTER TABLE treasury.budget_categories
  DROP CONSTRAINT fk_treasury_budgets_categories,
  ADD CONSTRAINT fk_treasury_budgets_categories
    FOREIGN KEY (budget_id) REFERENCES treasury.budgets(id) ON DELETE CASCADE;

-- budget_categories.parent_id → budget_categories.id (self-referential)
ALTER TABLE treasury.budget_categories
  DROP CONSTRAINT fk_treasury_budget_categories_subcategories,
  ADD CONSTRAINT fk_treasury_budget_categories_subcategories
    FOREIGN KEY (parent_id) REFERENCES treasury.budget_categories(id) ON DELETE CASCADE;

-- budget_line_items.category_id → budget_categories.id
ALTER TABLE treasury.budget_line_items
  DROP CONSTRAINT fk_treasury_budget_categories_line_items,
  ADD CONSTRAINT fk_treasury_budget_categories_line_items
    FOREIGN KEY (category_id) REFERENCES treasury.budget_categories(id) ON DELETE CASCADE;

-- enrichment_queue.budget_id → budgets.id
ALTER TABLE treasury.enrichment_queue
  DROP CONSTRAINT enrichment_queue_budget_id_fkey,
  ADD CONSTRAINT enrichment_queue_budget_id_fkey
    FOREIGN KEY (budget_id) REFERENCES treasury.budgets(id) ON DELETE CASCADE;
