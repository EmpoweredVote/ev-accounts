# Phase 41: VQ and Trivia Migration - Context

**Gathered:** 2026-03-22
**Status:** Ready for planning

<domain>
## Phase Boundary

Migrate the `validation_quests` and `trivia` schemas from EV-Backend's database into ev-accounts Supabase. Update VQ's `DATABASE_URL` to point at ev-accounts. Reconcile trivia's politician FKs against `essentials.politicians`. Enforce RLS on all migrated tables.

**No new capabilities in this phase.** The existing VQ confirmation flow (`POST /api/vq/confirm-stance`) must work end-to-end after cutover. Nothing else new is being built.

</domain>

<decisions>
## Implementation Decisions

### Cutover sequencing
- Single maintenance window — VQ and Trivia migrate together in one coordinated event
- VQ brief downtime (< 5 min): pg_dump both schemas from EV-Backend, restore into ev-accounts, update DATABASE_URL env var on Render, restart VQ
- One cutover event, not two separate ones

### Historical data scope
- Full historical migration — complete pg_dump + restore of all data in both schemas
- No data left behind: quest history, VR adjustments, gem award records, idempotency keys all migrate
- Idempotency key preservation is critical — without it, retry logic could double-award gems or VR after cutover

### Trivia FK reconciliation
- Pre-flight inspection required before migration: join trivia politician_ids against `public.politician_id_bridge` to count unmatched rows
- If gaps are small: add missing politicians to `essentials.politicians` before proceeding
- If gaps are large: null the FK on unmatched rows and log them for manual review — do not drop content
- Migration should not proceed until FK gaps are accounted for

### VQ connection model
- Dedicated `vq_service` Postgres role — USAGE on `validation_quests` schema + full DML (SELECT, INSERT, UPDATE, DELETE) on all `validation_quests` tables + EXECUTE on any RPCs VQ calls
- Role stays scoped to `validation_quests` only — no cross-schema access in this phase
- Direct connection (port 5432) — VQ is a persistent Render service, not serverless; pooler overhead unnecessary
- `search_path` set as role default: `ALTER ROLE vq_service SET search_path = validation_quests` — so VQ's unqualified table references work without code changes
- VQ's `DATABASE_URL` updated to use the `vq_service` credentials, not service role

### Claude's Discretion
- Exact pg_dump/restore tooling and flags
- RLS policy design for `validation_quests` and `trivia` tables (follow established patterns from Phase 34)
- Trivia connection model (investigate whether Trivia connects directly via DATABASE_URL or through ev-accounts API — design accordingly)
- Specific GRANT statements and role creation SQL

</decisions>

<specifics>
## Specific Ideas

- VQ is a persistent Render service — connection characteristics should be designed for that (not serverless)
- The `public.politician_id_bridge` table from Phase 35 is the lookup tool for trivia FK reconciliation
- Pre-flight row count verification pattern (established in Phase 34) should be applied here: capture counts in EV-Backend, verify counts match in ev-accounts after restore

</specifics>

<deferred>
## Deferred Ideas

**High Confidence → Essentials pipeline** — Future phase.
VQ's long-term purpose is as a grassroots data pipeline: when enough players confirm a civic fact (reaching "High Confidence"), that data populates `essentials.politicians`. This is new capability, not a migration concern. When this phase is built, VQ should call ev-accounts API endpoints (not write directly to essentials via DATABASE_URL) so all cross-schema writes go through ev-accounts' validation layer and the `vq_service` role stays cleanly scoped.

**Stance quests → Empowered Compass** — Future phase.
A planned extension of VQ allows players to find politician stances with sources. When a stance quest reaches High Confidence, it populates `inform.politician_answers` and flows into the Empowered Compass. This is the same grassroots pipeline pattern applied to the opinion layer. Requires API endpoints on ev-accounts for cross-schema writes from VQ.

**Trivia connection model** — Investigate before planning.
If Trivia connects directly via DATABASE_URL (same as VQ), it may need its own `trivia_service` role treatment. If Trivia calls the ev-accounts API instead, no direct DB connection is needed.

</deferred>

---

*Phase: 41-vq-and-trivia-migration*
*Context gathered: 2026-03-22*
