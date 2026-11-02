# `src/focused_communities/` — Focused Communities backend (folded in)

**Canonical.** This is a **vendored copy** (ev-cto decision 0013) of the standalone
`EmpoweredVote/focused-communities` backend (`src/`), folded into the engine the same way
`src/civic_spaces/` was (ev-cto decision 0018). Once the cutover below is done, production is
served from here and the standalone backend is frozen (`FROZEN.md` in that repo). Its **frontend
stays in that repo** and becomes a free static site that calls this module.

## What it is
The Focused Communities read and write API: communities, stance cards, threads, replies, public
edit history, a member's own post history, and the **argument tree** (below). Every route is
request/reply — no timers, no queue, no files — so nothing here goes in `jobs/registry.ts`, and
all of it is served under `EV_ROLE=api`. Mounted at **`/fc/api`** (byte-for-byte alias of the old
paths) and **`/api/fc`** (tidy) in `src/index.ts`; the seam is `app.ts`.

## The argument tree
A Kialo-style tree of claims under each community's question, added by migrations
**CA_0342 – CA_0346**. Three routers, mounted in `app.ts` in this order, all under the same
prefixes as the rest of the module:

| Router | Routes |
| --- | --- |
| `routes/claims.ts` (read) | `GET /communities/:id/claims/root`, `GET /communities/:id/claims/shape`, `GET /claims/:id` |
| `routes/claimWrites.ts` | `POST /claims/:parentId/children`, `PUT /claims/:id/rating`, `PATCH /claims/:id`, `GET /claims/:id/edits`, `DELETE /claims/:id` → 405 |
| `routes/claimCuration.ts` (maven **or** admin) | `POST /claims/:id/move`, `POST /claims/:id/merge`, `POST /claims/:id/hide` |

- **Grants:** `connect.claims` and `connect.claim_ratings` read/insert/update,
  `connect.claim_edits` read only, all on the same `focused_communities_app` role — see the
  privacy-wall paragraph in `config/database.ts`, which lists all eight tables.
- **Every community has a root claim**, seeded from its name by
  `trg_communities_seed_root_claim`. A root has no author, no side and no parent, and **nothing
  curates, edits or rates one** — four separate routes refuse it.
- **Position is derived, never sent.** `path` and `depth` come from
  `trg_claims_derive_position`; a move or a merge rewrites the whole subtree in one sweep.
  `impact` is `GENERATED ALWAYS` from the rating aggregate (CA_0346) and is never written.
- **Nothing is deleted and nothing is folded.** A hidden claim becomes a tombstone (empty body,
  no pseudonym, counts intact); a merged claim keeps its id, URL, body and history and gains a
  `mergedInto` pointer that a client follows a hop at a time.
- **Caching:** the shape map and the default node pages are hand-cached for 30s;
  `middleware/claimInvalidation.ts` drops them on any 2xx write under `/claims/`, and
  `middleware/claimsTouched.ts` is how a curation route names the other rows it moved. A
  credentialed response is never cached, because `myRating` is per-caller.

## How it differs from the standalone (deliberately)
- **Database:** `config/database.ts` is a dedicated pg pool that connects as
  **`focused_communities_app`** (migration **CA_0323**): SELECT on `connect.communities`;
  SELECT/INSERT/UPDATE on `connect.threads` and `connect.posts`; SELECT on the two edit tables;
  EXECUTE on `connect.get_stances_for_community`. Nothing else — in particular NOT
  `connect.connected_profiles` or the gem/XP/invite tables that share the schema. The standalone
  used the broad `service_role` key. Set via `FOCUSED_COMMUNITIES_DATABASE_URL` (founder secret).
  **No BYPASSRLS:** CA_0323 adds permissive policies scoped to this role instead.
- **Queries:** supabase-js (PostgREST) ported to parameterised SQL. Timestamps are selected with
  `ts()` (`lib/sql.ts`) so responses and pagination cursors keep PostgREST's microsecond text —
  a JS `Date` would truncate to milliseconds and break cursors.
- **Auth:** the engine's single dual-issuer `requireAuth`, then `getAccountMe` in-process (was
  `GET /api/account/me` over HTTP). The standalone's own verifier is **not** vendored. The engine
  also enforces revocation, deletion and suspension, which the standalone did not. One shim keeps
  the frontend's suspended notice working: a suspended account's 403 gets `reason: 'suspended'`.
- **Cache:** the engine's shared `cache` (`src/lib/cache.ts`) instead of a second Upstash client.
  Keys keep the `fc:` prefix and shape. The post rate limit (`lib/rateLimit.ts`, 5 per hour per
  user, prefix `fc:rl`) is unchanged and still uses `@upstash/ratelimit`.
- **Reply count:** a reply bumps `threads.reply_count` with `reply_count + 1` in the UPDATE
  instead of read-then-write, so two simultaneous replies no longer lose one.
- **No HTML:** the standalone also served the React build. The frontend is now a static site.

## Preserved behaviours
- Hidden or missing threads/posts answer **404**, never revealing existence; non-authors editing
  get **404**, not 403.
- **No deletes** (Memory over Moderation): DELETE answers 405 with `Allow: GET, PATCH`, and the
  role has no DELETE grant at all.
- Edit history is written by the SECURITY DEFINER triggers `log_thread_edit` / `log_post_edit`;
  author pseudonyms by `snapshot_author_display_name`. Neither needs a grant on this role.
- Thread creation and replies share one 5-per-hour bucket; edits are not rate limited.
- `/users/:id/posts` is self-only and never cached.

## Cutover (founder steps — nothing here changes production until they are done)
1. Apply `migrations/CA_0323_focused_communities_scoped_role.sql`, then set the role's password
   live (`ALTER ROLE focused_communities_app WITH PASSWORD '…'`).
2. On `ev-accounts-api` in Render: set `FOCUSED_COMMUNITIES_DATABASE_URL` (session pooler, port
   5432) and add `https://fc.empowered.vote` to `CORS_ORIGIN`. Deploy. Check
   `GET /fc/api/health` and `GET /fc/api/communities`.
3. Create the static site from the focused-communities repo (see that repo's cutover notes),
   built with `VITE_API_BASE_URL=https://accounts-api.empowered.vote/fc`, and move the
   `fc.empowered.vote` custom domain to it.
4. Suspend the old `focused-communities` web service (saves $7/month).

Rollback: point `fc.empowered.vote` back at the old service and resume it.
