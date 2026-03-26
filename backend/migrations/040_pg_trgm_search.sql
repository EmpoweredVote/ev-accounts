-- Migration 040: pg_trgm search support for politician name search
-- Enables fuzzy name search via word_similarity() with accent folding
-- SRCH-01: GIN index for sub-100ms politician name search at any scale

-- 1. Enable pg_trgm extension (trigram similarity functions and operators)
CREATE EXTENSION IF NOT EXISTS pg_trgm WITH SCHEMA extensions;

-- 2. Enable unaccent extension (removes diacritics for accent-insensitive search)
CREATE EXTENSION IF NOT EXISTS unaccent WITH SCHEMA extensions;

-- 3. Create IMMUTABLE wrapper for unaccent
-- Required because unaccent() is STABLE and cannot be used directly in a GIN index expression.
-- An IMMUTABLE function guarantees same output for same input across transactions,
-- which PostgreSQL requires for functional index expressions.
CREATE OR REPLACE FUNCTION public.f_unaccent(text) RETURNS text
  LANGUAGE sql IMMUTABLE PARALLEL SAFE STRICT AS $$
  SELECT extensions.unaccent('extensions.unaccent', $1);
$$;

-- 4. Create GIN trigram index on essentials.politicians.full_name
-- Uses f_unaccent(lower(full_name)) so queries with/without accents hit the index.
-- WHERE clause in queries must use EXACT same expression: public.f_unaccent(lower(full_name))
CREATE INDEX IF NOT EXISTS idx_politicians_full_name_trgm
  ON essentials.politicians
  USING GIN (public.f_unaccent(lower(full_name)) extensions.gin_trgm_ops);
