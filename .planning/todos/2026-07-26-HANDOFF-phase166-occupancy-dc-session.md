# HANDOFF — Phase 166 close-out, occupancy port, DC merge (session 2026-07-26)

Everything below is **committed and pushed**; `origin/master` is at `4c03d13f`, working tree clean.
Nothing is half-finished. This file exists so the next session does not have to re-derive context.

---

## What shipped

| | Commit(s) | State |
|---|---|---|
| **Phase 166** — consolidated 178-district gate, USHC3-06 CLOSED | `634729cc`…`3d36898a` (15) | ✅ 5/5 plans |
| **Occupancy port** — 4 evidence artifacts off the dropped column | `fd940d40` | ✅ |
| **`check:occupancy:all`** — full-repo inventory mode | `cafe9377` | ✅ |
| **DC merge** — migration 1479, applied to prod | `4d4b917a` | ✅ verified |
| **v2.15 gate repair** — `verify-phase-125-126.sql` green end to end | `8ad8e6af` | ✅ |
| **Remaining 13 gate-shaped scripts** ported | `4c03d13f` | ✅ GATE-SHAPED = 0 |

Phase-166 artifacts (all read-only, all green together against one prod snapshot):
`166-derive-pins.ts`, `166-pins.generated.sql`, `166-coordinate-smoke.ts`, `166-verify.sql`,
`166-verify-invariants.sql`, plus `166-mo-flip-runbook.md`.

---

## Open items — 1 of 3 RESOLVED; the 2 remaining are a trivial grant

All three trace to `backend/.env`'s `DATABASE_URL` being the least-privileged app role `ev_api`,
which has no access to schemas `auth` or `supabase_migrations`. **But do not treat them as one
decision — that framing invites solving both with the same GRANT:**

- **Items 2 and 3 need `SELECT` on `supabase_migrations.schema_migrations`** — a metadata table of
  applied migration versions. No secrets, no write, no escalation path. A nearly free grant.
- **Item 1 needs `INSERT INTO auth.users`** — the ability to MINT AUTHENTICATED IDENTITIES.
  Categorically different, and the reason the blanket "just grant ev_api access" answer is wrong.

**Why the current state is probably correct, not a regression.** An app role that can insert into
`auth.users` can create arbitrary logged-in users; combine that with any SQL injection or a leaked
`DATABASE_URL` and you have full impersonation. That is not hypothetical here — `backend/.env` was
one of the 12 files caught in the 2026-07-26 ANTHROPIC_API_KEY plaintext exposure, and it holds
`DATABASE_URL` too. Whoever narrowed `ev_api` did the right thing.

**The deeper signal:** the D-11 probe needs MORE privilege than the app it tests. The app never
creates auth users (Supabase Auth does, out of band) — it only ever READS
`resolve_congressional_2026(user_id)` for an existing user. A test needing powers its subject lacks
usually means the fixture is at the wrong layer, not that the subject is under-privileged.

**INVESTIGATED 2026-07-26 — three findings that kill most of the option list:**

1. **The FK is ENFORCED, not trigger-based:**
   `users_id_fkey FOREIGN KEY (id) REFERENCES auth.users(id) ON DELETE CASCADE`. You cannot seed
   `public.users` without an `auth.users` row.
2. **`ev_api` cannot EXECUTE either function.** Both `connect.upsert_user_location` and
   `connect.resolve_congressional_2026` are `SECURITY DEFINER` owned by `postgres` with no grant to
   `ev_api`. A direct call returns `ERROR: permission denied for function
   resolve_congressional_2026`. So the probe is blocked at every layer as this role, not just at
   the auth insert.
3. **This is NOT a production bug — verify the call site before assuming it is.** Prod's
   `DATABASE_URL` is also `ev_api`, which looks alarming, but the production path is
   `src/routes/essentials.ts:74` → `adminRpc(...)` → `supabaseAdmin` → **`SUPABASE_SERVICE_ROLE_KEY`
   via PostgREST**, never the `ev_api` pg pool. **D-11 works in production.**

Finding 3 reframes the problem: production invokes this through PostgREST as `service_role`, while
the probe invokes it through raw Postgres as the `.env` role. The smoke's "actual RPC code path"
claim was only half-true — same SQL function, different invocation. The privilege mismatch is a
symptom of the probe having drifted from how production actually calls this.

**Options, corrected:**
- **(a) BEST — invoke it the way production does.** `supabaseAdmin.auth.admin.createUser()` mints
  the sentinel (exactly what service_role is for), `adminRpc('resolve_congressional_2026', …)`
  exercises it on the real production path, `auth.admin.deleteUser()` cleans up with the
  `ON DELETE CASCADE` FKs. **No new grant, no new connection string, no `ev_api` change**, and
  MORE faithful to prod than the current probe. Trade-off: loses `BEGIN … ROLLBACK` safety for an
  explicit delete, so a crash mid-probe could strand a sentinel row — a real regression in cleanup
  guarantees, but far smaller than provisioning a privileged credential.
- **(b) A separate `ADMIN_DATABASE_URL`.** Works, but adds a high-privilege credential to the same
  `.env` that was already exposed once — solves the mechanics, worsens the posture.
- **(c) Move the probe to CI** with elevated creds, if a privileged string already exists there.
- ~~Permanent seeded test user~~ — DEAD, finding 2 (can't call either function as `ev_api`).
- ~~Seed only `public.users` + `connected_profiles`~~ — DEAD, finding 1 (enforced FK).
- ~~Grant `ev_api` narrowly~~ — REJECTED; the escalation is minting users, not the schema access.

**Why it changed (hypothesis, untested):** memory records role-level `statement_timeout=8s` set on
`ev_api` during the P1 finance incident (~2026-07-22) — right between 164.2 working (07-22) and now.
Plausible that `ev_api` was created or tightened then and `.env` switched to it.

1. ~~**D-11 sentinel probe**~~ — ✅ **RESOLVED 2026-07-26 (`344456e2`), option (a).** New shared
   helper `backend/scripts/d11-probe.ts` mints the sentinel with
   `supabaseAdmin.auth.admin.createUser()` and drives both RPCs through `adminRpc` — production's
   exact path — then deletes it. **No grant, no new credential, no `ev_api` change.** Both smokes
   now prove D-11: 9/9 states, no skips, no PARTIAL summary (TN 4707, AL 0107, LA 2205, UT 4903,
   FL 1209, CA 0602, NC 3701, OH 3909, TX 4815 — matching what 164.2-03-SUMMARY.md recorded).
   0 stranded sentinels verified after full runs. Trade-off accepted and documented in the helper:
   no `BEGIN/ROLLBACK`, so cleanup is an explicit delete plus a `reapSentinel()` on each run.
2. **`verify-phase-122.sql`** — reads `supabase_migrations.schema_migrations`.
3. **`verify-phase-120-124.sql`** — same; its assertions 1-8 (MAOF) all pass before it hits this.

**DO NOT fix by granting `ev_api` access to `auth`.** An application role able to mint auth users is
a security regression — that judgement is recorded in the flip-region comments and commit messages.
The fix is a *separate privileged connection string* used only by these probes, which is an operator
decision, not a code change.

Prior evidence these DID work: 164.1 (2026-07-07) and 164.2 (2026-07-22) both ran the D-11 probe
green, so the role or its grants changed between then and now.

**Also open, unrelated:** `verify-phase-120.sql` is SUPERSEDED by `verify-phase-120-124.sql` (Newton
17 vs 25 — Phase 123 re-linked 8 councillors to per-ward districts). Header says so. Do not lower
25 → 17.

---

## Facts a future session will otherwise re-derive the hard way

- **WI's field moved.** `WI 2026 Partisan Primary` (election row created **2026-07-25**, contest
  2026-08-11) now holds WI's House field — 32 active incl. 7 incumbents — while
  `WI 2026 Statewide General` holds 5 with **4 of its 8 races empty**. Phase 166's scope is
  therefore **43 elections, not 42**, and the 178 assertion counts **distinct `geo_id`**, not
  `race_id` (WI runs 3 races per district; 178 districts carry 194 races). IN and UT also have House
  primaries but theirs are PAST and hold only concluded contests — correctly excluded.
- **Two states are PROVISIONAL-split** and cannot take a whole-state assertion: WI 8m/16u,
  AL 4m/3u. `166-verify.sql` asserts a per-state `(marked, unmarked)` count pair instead.
- **Pin drift was large.** 566 frozen headshot pins → 51 live (517 acquired images). Stance pins
  held: 123 of 124 survive; 1 retired (Fillmore AZ-4, withdrawn).
- **Phase-167 queue is non-empty: 2 WI candidates** — `-550304` (Alexander Valiensi Kent, WI-3) and
  `-550708`. 0-stance with NO documented search trail, so deliberately NOT folded into the
  researched honest-skip set. Enumerated in `166-01-SUMMARY.md`.
- **12 cross-state band collisions** exist and are legitimate: 4 KS incumbents whose legacy ids sit
  in AK's band, 8 MA incumbents in KS's band. All entered via the `race_candidates` join.
- **DC now has ONE `NATIONAL_LOWER` district** (`1198`, 3 offices, 3 holders). `dc-national-lower`
  was deleted by migration 1479. National totals: 435 state districts + 1 DC = 436.
- **CA has 52 seats**, not 53 (2020 reapportionment). A stale 53 was corrected in the v2.15 gate.
- **The v2.15 batch is `external_id BETWEEN -56999 AND -1000 AND created_at < 2026-07-01`.** The raw
  band alone is polluted — it holds 372 now, 299 on 2026-06-16 plus 73 from later phases.

---

## Calendar-gated work, nearest first

| Date | Item |
|---|---|
| **≥ 2026-08-04** | Plan **164.1-07** — MO certification. **READ `phases/166-consolidated-verification-gate/166-mo-flip-runbook.md` FIRST.** Map-holds flips BOTH the 162 gate and the 166 pair; referendum-qualifies flips neither and the runbook says so explicitly. |
| **≥ 2026-08-05** | Phase 159 Waves 3-4 — MI/VA cull + the 24-district gate that closes v2.21 |
| **≥ 2026-08-10** | PA independents re-check |
| **≥ 2026-08-18** | Phase 153 — FL post-primary re-check |
| Aug–Sep | Phase 167 — post-primary reconciliation; consumes the 2-candidate stance queue above |

**No unblocked v2.22 forward step remains.** `STATE.md` says this explicitly now; the stale
`/gsd-plan-phase 166` instruction was removed.

---

## Two process notes worth keeping

- **A port is not done until the script RUNS.** The first "complete" occupancy sweep left two files
  broken — the guard's alias regex (`o|off|offices`) walked past `o2.` and `ox.`. Only executing
  them caught it. The guard is widened now (`o[0-9a-z]*`, with a 10-case regression test), but the
  lesson generalises.
- **Pre-seeding baseline gates cannot go green after their phase seeds.** `154-verify.sql` and
  `160-verify.sql` both stop at an A2 asserting "0 candidates seeded yet". That is the gate working
  on an expired premise, not a defect. Both carry a header saying so, and saying not to relax A2.
