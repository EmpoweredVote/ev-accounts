-- Widen election_cycle from VARCHAR(4) to VARCHAR(10) to support quarterly keys like '2024-Q1'
ALTER TABLE transparent_motivations.ingestion_runs
  ALTER COLUMN election_cycle TYPE VARCHAR(10);
