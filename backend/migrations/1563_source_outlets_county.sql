-- Source tier recalibration (on-the-record spec 2026-08-05): county-level
-- races need county source packs; make county coverage queryable.
-- Bare county name, e.g. 'Monroe' with state='IN'. Pack agents set it at
-- outlet registration; discovery code treats it as pass-through metadata.
ALTER TABLE essentials.source_outlets ADD COLUMN county text NULL;
