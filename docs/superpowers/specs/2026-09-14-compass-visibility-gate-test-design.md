# Compass stance visibility — the gate wants a test, not a doc

- **Date:** 2026-09-14
- **From:** Civic Spaces, relayed by Chris
- **Re:** the one item flagged out of the 2026-09-12→14 Civic Spaces ↔ ev-accounts exchange
- **Provenance:** `civic-spaces/.planning/phases/15-tool-deep-links/ACCOUNTS-HANDOFF.md`
  (full exchange, 632 lines). This file is the single actionable item from it.
- **Tracking:** none yet — please assign.

## Ask, in one line

**Add a test asserting that every service-role read of `inform.compass_responses` on a
non-owner path carries `visibility = 'public'`.** Nothing else in this note is a request.

## Why a test and not documentation

Because documentation does not fail a build, and this control is currently three remembered
predicates with nothing underneath them.

`visibility` is the **sole** access control on an unauthenticated read path:

- `src/lib/profileService.ts:265` reads an **arbitrary `:userId`'s** compass answers through
  `supabaseAdmin` — service role, RLS bypassed — and applies `visibility = 'public'` only
  when `publicOnly`. Its own comment states the stake: without the filter *"an
  unauthenticated caller reading an arbitrary `:userId` would see that user's
  private-visibility stances."*
- `src/lib/candidateService.ts:145` and `:223` are the other two readers.

And the backstop people assume is there, is not:

```
rolname       rolbypassrls
ev_api        TRUE
service_role  TRUE
```

Production authenticates as **`ev_api`**, which bypasses RLS; `inform.compass_responses`
also has `relforcerowsecurity = false`. So the owner-only policy `auth.uid() = user_id` is
correct and real **for a PostgREST or `authenticated` caller**, and constrains the Express
API not at all. `routes/compass.ts:428` already documents this correctly for its own path.

**The database is not the backstop here; the route predicate is.** A fourth public read path
that forgets the filter is a full exposure with nothing beneath it, and it would pass review
exactly as easily as the three correct ones did.

## Why `PRIVACY-DATA-MODEL.md` does not already cover this

§2 names the core problem as a single join key linking *who you are* to *what you think*,
and §4 answers it by keying behavior on a `pseudonym_id` so a breach of the behavior realm
yields pseudonyms rather than names.

**That architecture does not close this hole**, and we think the distinction is worth
recording:

| | §2's problem | This |
|---|---|---|
| Attacker | breach or insider with DB read | **anyone, unauthenticated, over HTTP** |
| Mechanism | join identity to behavior | an API endpoint that *is designed* to serve stances by user |
| Fixed by pseudonymisation? | yes | **no** — a public profile still has to resolve that user's stances to render them |

Pseudonymisation protects the join. It does not protect an endpoint whose job is to return
a named person's public stances, and which distinguishes public from private by one
predicate. The two defences are orthogonal, and the target model arriving would not retire
this test.

## What the test should assert

Behavioural, and closest to the real failure:

1. Seed a user with at least one `visibility = 'private'` stance (the default, so: any
   stance).
2. Call the public profile path unauthenticated for that `:userId`.
3. Assert the response contains **no** stance for that topic.
4. Repeat for the candidate paths behind `candidateService.ts:145` / `:223`.

A static guard is a reasonable addition but a weak substitute: any read of
`compass_responses` / `compass_responses_effective` outside an owner-scoped path must be
accompanied by a `visibility` predicate. It catches the forgotten-filter case at the point
it is written, which is cheaper than catching it in review.

Worth noting for whoever writes it: **the fixture must create the private stance
explicitly.** Asserting against current production data would pass vacuously — see below.

## Current state, measured 2026-09-14

| Measured | Value |
|---|---|
| `compass_responses` rows | **230 — every one `private`** |
| `visibility = 'public'` | **0** |
| `visibility = 'friends'` | **0** |
| `'friends'` in `src/` | **0 occurrences** |
| Function that flips visibility to `'public'` | **none found** |

Migration `026:107` says visibility is *"set to 'public' on empowerment (RPC)"*. That RPC
could not be found — only `public.run_empower_preflight`. So the public-profile stance path
is **live code gating an empty set**.

This is the strongest possible answer to *"is it safe today"* — no stance in the system is
public — and the weakest possible guarantee about tomorrow. It is also the cheapest moment
to add the test: it can be written and proven against a seeded fixture without touching
real data, and before the first genuinely public stance exists.

## Recorded, explicitly not requested

Raised in the same exchange, deliberately **not** flagged as urgent:

1. **Migration `026`'s empowerment RPC appears not to exist.** Either the flip happens
   somewhere we did not find, or a documented behaviour was never built. Worth knowing
   before anything relies on it.
2. **`'friends'` is free to drop today** — zero rows, zero code. It costs a migration and a
   decision later.
3. **Staff reads are unbounded and unlogged.** `compass_change_history` audits *changes*,
   not reads, and appears in `src/` only in generated types. Because `ev_api` bypasses RLS,
   a staff read and an ordinary API read are indistinguishable at the database. The
   effective boundary today is *"anyone with the API's database credential"*, not *"EV
   staff"* — `requireStaff` governs HTTP routes, not database access. **This is a policy
   decision for Chris, not a bug**, and it is the gap between his stated rule and what is
   enforced.

Chris's rule, in his words: *"It should be safe to have an informed account and keep the
email associated with that and the stances in that compass anonymous to all but the
stewards at EV."* Note "stewards" means EV staff — not the `steward` schema and
migration-slot CLI in this repo.

## Not Civic Spaces' work

Civic Spaces renders no stances; it links out to Compass. This is filed because the finding
came out of that exchange and belongs here, not because anything in Civic Spaces depends on
it. Nothing blocks on either side.
