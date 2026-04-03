-- 047: Add actual_amount to budget_categories for budgeted-vs-actual display
ALTER TABLE treasury.budget_categories
  ADD COLUMN actual_amount NUMERIC DEFAULT 0;

COMMENT ON COLUMN treasury.budget_categories.actual_amount
  IS 'Sum of actual_amount from line items — used for past-year "spent" display';
