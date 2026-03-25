-- Treasury Transactions
-- Individual payment/purchase transactions linked to budget categories via link_key.
-- Vendors are normalized into their own table to avoid duplication across 300K+ rows.

-- Vendors table (normalized from transaction rows)
CREATE TABLE IF NOT EXISTS treasury.vendors (
  id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name          TEXT NOT NULL,
  external_id   TEXT,                    -- source system vendor ID (e.g., Vendor_Id from CSV)
  municipality_id UUID NOT NULL REFERENCES treasury.municipalities(id),
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),

  UNIQUE(municipality_id, name)          -- one vendor record per name per municipality
);

CREATE INDEX idx_vendor_municipality ON treasury.vendors(municipality_id);
CREATE INDEX idx_vendor_name ON treasury.vendors(name);

-- Transactions table
CREATE TABLE IF NOT EXISTS treasury.transactions (
  id                UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  budget_id         UUID NOT NULL REFERENCES treasury.budgets(id),
  vendor_id         UUID REFERENCES treasury.vendors(id),
  link_key          TEXT,                -- matches budget_categories.link_key for drill-down linkage
  amount            NUMERIC NOT NULL,
  description       TEXT,
  payment_date      DATE,
  fiscal_period     SMALLINT,            -- 1-12 fiscal period within the year
  payment_method    TEXT,                -- 'Check', 'EFT', etc.
  payment_number    TEXT,                -- check number or EFT reference
  invoice_number    TEXT,
  fund              TEXT,                -- fund name for cross-referencing
  expense_category  TEXT,                -- expense classification
  expense_account   TEXT,                -- GL account code
  priority          TEXT,                -- budget hierarchy level 1 (department/priority)
  service           TEXT,                -- budget hierarchy level 2
  department        TEXT,                -- budget hierarchy level 3 (if present)
  program           TEXT,                -- budget hierarchy level 4 (if present)
  division          TEXT,                -- budget hierarchy level 5 (if present)
  created_at        TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Primary query path: find transactions for a budget category via link_key
CREATE INDEX idx_transaction_budget_link ON treasury.transactions(budget_id, link_key);

-- Support queries by vendor across a budget
CREATE INDEX idx_transaction_vendor ON treasury.transactions(vendor_id);

-- Support date-range queries within a budget
CREATE INDEX idx_transaction_date ON treasury.transactions(budget_id, payment_date);

-- RLS: public read, service-role write (matches existing treasury tables)
ALTER TABLE treasury.vendors ENABLE ROW LEVEL SECURITY;
ALTER TABLE treasury.transactions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "vendors: public read" ON treasury.vendors
  FOR SELECT USING (true);

CREATE POLICY "transactions: public read" ON treasury.transactions
  FOR SELECT USING (true);
