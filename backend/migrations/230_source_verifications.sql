-- 230_source_verifications.sql
-- Per-URL verification tracking for compass stance sources and read-rank quote sources.
-- Shared audit trail table; feeds both the verify-sources skill and the admin review UI.

CREATE TABLE IF NOT EXISTS public.source_verifications (
  id                uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  entity_type      text NOT NULL CHECK (entity_type IN ('compass_stance', 'readrank_quote')),

  -- Entity references (nullable; populated based on entity_type)
  politician_id    uuid NOT NULL,
  topic_id         uuid NULL,            -- compass only
  quote_id         uuid NULL,            -- readrank only
  url_index        int  NOT NULL DEFAULT 0, -- position in sources[] array; 0 for readrank

  url              text NOT NULL,

  status           text NOT NULL DEFAULT 'unverified'
                     CHECK (status IN ('unverified','verified','needs_review')),
  verified_at      timestamptz NULL,
  verified_by      text NULL,            -- 'auto' or a user uuid as text
  notes            text NULL,
  replacement_url  text NULL,
  original_url     text NULL,
  http_status      int  NULL,
  unfixable        boolean NOT NULL DEFAULT false,

  created_at       timestamptz NOT NULL DEFAULT now(),
  updated_at       timestamptz NOT NULL DEFAULT now(),

  -- Integrity: ensure the right foreign-key column is populated for each type
  CONSTRAINT source_verifications_entity_shape CHECK (
    (entity_type = 'compass_stance' AND topic_id IS NOT NULL AND quote_id IS NULL)
    OR
    (entity_type = 'readrank_quote' AND quote_id IS NOT NULL AND topic_id IS NULL)
  )
);

-- One verification row per (entity, url position).
-- For compass: (politician_id, topic_id, url_index) uniquely identifies a source slot.
-- For readrank: (quote_id, url_index) — url_index is always 0 but included for uniformity.
CREATE UNIQUE INDEX IF NOT EXISTS source_verifications_compass_uniq
  ON public.source_verifications (politician_id, topic_id, url_index)
  WHERE entity_type = 'compass_stance';

CREATE UNIQUE INDEX IF NOT EXISTS source_verifications_readrank_uniq
  ON public.source_verifications (quote_id, url_index)
  WHERE entity_type = 'readrank_quote';

CREATE INDEX IF NOT EXISTS source_verifications_status_idx
  ON public.source_verifications (status, created_at);

CREATE INDEX IF NOT EXISTS source_verifications_url_idx
  ON public.source_verifications (url);

-- updated_at trigger
CREATE OR REPLACE FUNCTION public.touch_source_verifications_updated_at()
RETURNS trigger AS $$
BEGIN
  NEW.updated_at := now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_touch_source_verifications ON public.source_verifications;
CREATE TRIGGER trg_touch_source_verifications
  BEFORE UPDATE ON public.source_verifications
  FOR EACH ROW
  EXECUTE FUNCTION public.touch_source_verifications_updated_at();
