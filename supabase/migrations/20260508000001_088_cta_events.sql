-- CTA event telemetry — lightweight click-tracking for the "Connect Account" CTA
-- and any future in-app CTAs. Queried via admin SQL only; no PostgREST exposure.
CREATE TABLE IF NOT EXISTS public.cta_events (
  id          BIGSERIAL    PRIMARY KEY,
  event_name  TEXT         NOT NULL,
  user_id     UUID         REFERENCES public.users(id) ON DELETE SET NULL,
  created_at  TIMESTAMPTZ  NOT NULL DEFAULT now()
);

CREATE INDEX ON public.cta_events (event_name);
CREATE INDEX ON public.cta_events (created_at);

-- RLS enabled; no user-facing policies — all reads/writes go through the backend pool
-- (raw pg driver, bypasses RLS). Service role has no policy either, ensuring only
-- backend code can insert records.
ALTER TABLE public.cta_events ENABLE ROW LEVEL SECURITY;
