# `trivia/` — Civic Trivia Championships, folded into the engine

Engine consolidation, **Phase 1**. This directory is the Civic Trivia Championships
(CTC) backend, ported from `Civic-Trivia-Championships/backend/src` and mounted inside
`ev-accounts-api`. It runs **in parallel** with the still-live `civic-trivia-backend`
Render service until that service is retired (gate G6, a later phase).

## How it is mounted

`src/index.ts` mounts the six routers under **both** path shapes (`src/trivia/app.ts`):

| Router | `/ctc` alias (cutover) | tidy path (Phase 1c) |
|---|---|---|
| game | `/ctc/api/game` | `/api/trivia/game` |
| profile | `/ctc/api/users/profile` | `/api/trivia/users/profile` |
| admin | `/ctc/api/admin` | `/api/trivia/admin` |
| feedback | `/ctc/api/feedback` | `/api/trivia/feedback` |
| leaderboard | `/ctc/api/leaderboard` | `/api/trivia/leaderboard` |
| health | `/ctc/health` | `/api/trivia/health` |

The `/ctc/...` alias is byte-for-byte with the old service's paths, so the CTC frontend
cuts over with **one env var and a rebuild** — see below. The tidy `/api/trivia/...`
paths are adopted in Phase 1c after the old service is gone; the alias is then deleted.

These do not collide with the engine's existing `routes/trivia.ts` (`/api/trivia/collections`,
`/api/trivia/leaderboard-profiles`), which is left untouched during the parallel run.

## What is and is not folded

- **Folded:** the runtime import closure of the six routers (41 files) — routes, the
  services and quality-rules they reach, the drizzle models, CTC's own auth, its pg pool
  and supabase client, session storage. Traced statically; `scripts/`, the embeddings /
  OpenAI pipeline, and `services/generation/CollectionHierarchy|GapAnalyzer` are **not**
  reached by request handlers and are not folded.
- **NOT folded:** CTC's **cron scheduler** (expiration sweep, election detection,
  pipeline). The old `civic-trivia-backend` keeps running during the parallel window and
  owns those jobs; running them here too would double-execute them (double LLM spend,
  races). They transfer when the old service is retired (G6). `cron/electionDetection.ts`
  is present only because `routes/admin.ts` reads its `lastCronRun`; it schedules nothing.

## Data access

CTC keeps its **own** `pg` pool (`config/database.ts`, `search_path = trivia`, `max 5`)
and its **own** `supabaseAdmin` (PostgREST, `public` schema). The engine's pool and
clients are untouched, so DB behaviour is identical to the standalone service. drizzle
models are `pgSchema('trivia')` (schema-qualified), and the two raw `pool.query` strings
are trivial / fully `trivia.`-qualified.

## Changes made to the ported code (small, deliberate)

1. `config/database.ts` — dropped the process-wide `setDefaultResultOrder('ipv4first')`
   side effect (the engine governs DNS order for the whole process) and set `max: 5`.
2. `config/redis.ts` + `routes/health.ts` — read **`TRIVIA_REDIS_URL`**, not the engine's
   `REDIS_URL`. The engine's `REDIS_URL` is an Upstash **REST (https)** endpoint that
   node-redis cannot use. Unset ⇒ in-memory sessions (fine on one instance; reset on
   redeploy). Set it to a TCP `redis://` / `rediss://` URL for durable sessions.
3. `services/questionService.ts` + `data/questions.ts` — the emergency JSON fallback now
   loads an embedded TS module instead of `readFileSync(data/questions.json)`, because
   `npx tsc` (the Render build) does not copy `.json` data files into `dist/`. Same
   questions; the database remains the primary path.

The engine's `middleware/auth.ts` is **not** touched. CTC's own dual-issuer auth
(`middleware/auth.ts` here) is kept as-is; deleting the satellite copy is Phase 4.

## Founder actions on the `ev-accounts-api` Render service (do at deploy)

- **CORS:** add the CTC frontend origin(s) to `CORS_ORIGIN`.
- **`ANTHROPIC_API_KEY`:** must be set (admin question-generation endpoints). Already
  present for discovery.
- **`TRIVIA_REDIS_URL`** (optional): a TCP Redis URL for durable game sessions; omit for
  in-memory.
- **`TRIVIA_SERVICE_KEY`, `TRIVIA_GEMS_KEY`, `EMPOWERED_ACCOUNTS_URL`,
  `EMPOWERED_ACCOUNTS_API_URL`:** for CTC's outbound XP / gem / tier-check calls during
  the parallel run (Phase 4 makes these in-process). `SUPABASE_URL`,
  `SUPABASE_SERVICE_ROLE_KEY`, `DATABASE_URL` are already set and shared.

No new migration. No change to the Render **build command** (`npm install && npx tsc`).

## CTC frontend cutover (one env var, then rebuild — do NOT change code)

Set `VITE_API_URL=https://ev-accounts-api.onrender.com/ctc` (no trailing slash) on the
`civic-trivia-frontend` static site and redeploy. `src/services/api.ts` does
`fetch(API_URL + '/api/game/session')`, so this resolves to
`…/ctc/api/game/session`. Rollback is the same one env var back to
`https://civic-trivia-backend.onrender.com`.

## Parity smoke test

`node scripts/trivia-parity-smoke.mjs --old <oldBase> --engine <engineBase>` hits all 49
endpoints on both hosts and diffs the status codes (target 49/49). Safe against prod:
every request is unauthenticated, so the 40 auth-gated routes 401 before any handler.
`scripts/trivia-local-engine.mjs` boots the folded routers behind the engine's global
middleware locally for a pre-deploy check.
