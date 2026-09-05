# `vq/` — Validation Quests, folded into the engine

> ✅ **CANONICAL — this is the source of truth for the Validation Quests backend.** Engine
> consolidation is complete: the standalone `empowered-validation-quests` Render service is
> **retired** (suspended 2026-09-04) and the `empowered-validation-quests` repo backend is
> **FROZEN** (see that repo's `backend/FROZEN.md`). Production `/vq` + `/api/vq` traffic is
> served from **here**. Make Validation Quests backend changes in this directory.
> See **ev-cto decision 0013** (freeze folded backends; engine canonical).

## What this is

Engine consolidation, **Phase 2**. This directory is the Validation Quests (VQ) backend, ported
from `empowered-validation-quests/backend/src` and mounted inside `ev-accounts-api`. It was a copy
of that repo's runtime code; that repo's backend is now frozen, so this is the only maintained copy.

## How it is mounted

`src/index.ts` mounts `validationQuestsRouter` (from `src/vq/app.ts`) under **both** path shapes,
`['/vq/api', '/api/vq']` — the `/vq/...` alias is byte-for-byte with the old service's paths (so the
VQ frontend cut over with one env var), and `/api/vq/...` is the tidy path. `app.ts` reproduces VQ's
load-bearing mount order (transparency after quests; notifications/preferences before notifications)
and VQ's own JSON error handler, scoped to VQ. The engine's pre-existing `routes/vq.ts`
(`/confirm-stance`, `/adjust-vr`) stays mounted ahead of this router and keeps precedence.

## Crons

VQ's consensus (every 5 min) and quest rotation (daily 04:00 UTC) run here, started by
`startVqCrons()` from `src/index.ts`, **gated behind `VQ_CRONS_ENABLED`** (set `true` in production
2026-09-04 when the old service was suspended). Off by default so a folded cron never double-runs
against a still-live old service.

## Database

VQ uses `@supabase/supabase-js` (PostgREST) only — no pg pool and no DB-role grant were needed
(contrast `trivia/`, which needed the `ev_api` grant `CA_0102`). The service_role / anon keys reach
`validation_quests`, `connect` and `empower`.
