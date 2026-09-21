---
status: proposed
---

> **Draft, 2026-09-15.** Decided with Chris in a working session, out of the 2026-09-12→14
> Civic Spaces ↔ ev-accounts exchange
> (`civic-spaces/.planning/phases/15-tool-deep-links/ACCOUNTS-HANDOFF.md`).
>
> It states **two decided floors**. When written it also left the **unmask fork open** —
> that fork has since closed (escrowed break-glass, decision 0022, 2026-09-17); see §6, which
> also records that closing it did **not** close §4's staff-read exception. Read
> `PRIVACY-DATA-MODEL.md` first; this ADR sits under it and reuses its vocabulary (realms,
> the vault, `pseudonym_id`) without redefining it — though note §6's flag that its §8a text
> is now out of date.
>
> 🔴 The measurements in §2 were taken on 2026-09-14 against production and master
> `82b095db`. Treat them as a map to re-verify, not as gospel — particularly "every stance
> is private", which is the fact doing the most work here and the one most likely to stop
> being true.

# Privacy floors

## 1. Why this exists

`PRIVACY-DATA-MODEL.md` describes a **target** architecture: encrypt the point, publish the
categories, and eventually key behavior on a `pseudonym_id` so a breach of the behavior
realm yields pseudonyms rather than names.

It does not say **how fine is too fine**, and neither does anything else. Asked directly in
2026-09, ev-accounts searched and reported: *there is no documented privacy floor, no
minimum slice population, and no re-identification threshold anywhere in the codebase.*

That absence is the problem this ADR closes. A target architecture tells you what the walls
are made of; a floor tells you where they stand. Without one, the finest thing that happens
to exist becomes the de-facto policy — which is exactly what had happened:
`city_council_geo_id` is published in the clear and is routinely a few thousand people,
finer than most townships. Nobody chose that. It arrived.

## 2. What was measured, 2026-09-14

| Fact | Value |
|---|---|
| Geoid columns on `connect.connected_profiles`, in the clear | **10** — city, county, state, nation, congressional, state_house, state_senate, city_council, municipality, school_district |
| Finest of those, by population | `city_council_geo_id` — routinely a few thousand people |
| Civic Spaces slice tiers actually exposed | `city`, `county`, `state`, `federal` (+ `unified`, `volunteer`, which carry no geography) |
| `inform.compass_responses` rows | **230 — every one `private`** |
| `visibility = 'public'` / `'friends'` | **0 / 0** |
| Can staff reads be distinguished from API reads? | **No.** `ev_api` has `rolbypassrls`; `compass_change_history` audits *changes*, not reads, and is unused by the app |

Two of these matter more than the rest. **No stance in the system is public** — so the
stance floor can be written while the true answer is still "none", which is far easier than
writing it after the first public stance exists. And **`city_council_geo_id` already sits
below any floor anyone would have chosen**, which is why "ratify the status quo" was
rejected.

## 3. Decision — the location floor

> **The finest geography EV exposes about a member to other members is the slice tier:
> city, county, state, federal.**
>
> The finer geoids already stored — `city_council`, `school_district`, `congressional`,
> `state_house`, `state_senate`, `municipality` — are **server-side inputs for resolving
> that member's own representatives**. They are never returned *about another member*.

Decided by Chris, 2026-09-15.

The distinction is between *storing* and *exposing about a third party*. Resolving "who
represents this account" legitimately needs a council district. Answering "who else is
here" never does — Civic Spaces groups members by city, county, state and nation, and has
no finer tier. So this floor is one the platform **already meets**: it is a commitment not
to drift below where the product already sits, not a migration.

That is deliberate. A floor you already satisfy costs nothing to adopt and everything to
have written down, because the failure mode is incremental: a future feature adds a
"neighbours in your ward" list, and there is no rule saying no.

**Not chosen, and why.** A population threshold ("no published unit under N residents") is
more principled and layer-agnostic. It was rejected for now because it needs a number
nobody has justified and per-geoid population data the platform does not hold. Revisit it
if a layer is ever proposed between "city" and "council district"; see §6.

## 4. Decision — the stance floor

> **A member's compass stances, and the link between those stances and the email on the
> account, are not readable by anyone other than the member — with a single, explicitly
> transitional exception for EV staff, which §5 requires be audited and which the target
> architecture is intended to remove.**
>
> Empowered accounts are the deliberate carve-out: public candidates consented
> (`legal_name_public`), and their stances are public by design.

Chris's words were *"it should be safe to have an informed account and keep the email
associated with that and the stances in that compass anonymous to all but the stewards at
EV."* ("Stewards" means **EV staff** — not the `steward` schema and migration-slot CLI in
this repo. That ambiguity has already misled one reader.)

**The exception is transitional and must be written down as such.** Chris's own in-progress
exploration commits to *building separation that will stop* staff reading beliefs, sealing
them against pseudonyms. So "all but EV staff" describes **today**, not the target. Recording
it without that qualifier would cement staff access as permanently acceptable, which is the
opposite of the direction of travel.

The concrete near-term consequence is already filed: `visibility` is the **sole** control on
an unauthenticated read path (`profileService.ts:265` reads an arbitrary `:userId` through
the service role), with no RLS beneath it because `ev_api` bypasses RLS. A fourth public
read path that forgets the predicate is a full exposure. See
`docs/superpowers/specs/2026-09-14-compass-visibility-gate-test-design.md` — that test is
this floor's only current enforcement.

## 5. Decision — a floor without an audit is not a floor

> **Staff reads of stance data must be distinguishable, after the fact, from ordinary API
> reads.**

Decided by Chris, 2026-09-15.

Today they are not. There is one database role for everything, it bypasses row security,
`auth.uid()` is not in play, and the only audit table records *changes* and is unused by the
application. So the effective boundary is **"anyone holding the API's database
credential"**, not "EV staff" — and no one could tell, afterwards, whether the floor in §4
had ever been crossed.

This ADR does not specify the mechanism. It specifies that **the mechanism is part of the
policy, not a follow-up to it**: a rule nobody can verify is a statement of intent, and §4
is meant to be a commitment.

The mechanism is designed in
`docs/superpowers/specs/2026-09-15-stance-read-audit-design.md`. Retention and review are
policy rather than design, so they are settled here.

**Scope, established 2026-09-17: this floor covers EV staff, and cannot cover Supabase.**
Measuring production showed that of the roles able to read every stance, `postgres` is the
only credential an EV human can obtain — and it is the one the mechanism logs. The remaining
unlogged roles (`supabase_admin`, `supabase_etl_admin`, `supabase_read_only_user`) are
**Supabase's own**, platform-operated, with no customer path to obtain them. Their access is
real and is **not** auditable from inside the database, because you cannot audit your cloud
provider using their own logs. That is a vendor-trust question whose instruments are
contractual, or encryption with keys the provider does not hold — not this ADR. §4's
guarantee should be read accordingly: it is a commitment about **EV's** conduct, not a claim
that no one at the hosting provider can read a stance.

### 5a. Retention — 7 days, and that is a ceiling rather than a judgement

> **Stance-read audit records are retained for 7 days.**

Decided by Chris, 2026-09-16.

The mechanism's first stage logs to **Postgres logs**, and this organisation is on the
Supabase **Pro** plan, whose observability window is **7 days** (Team is 28). So 7 days is
not a number anyone chose — it is the platform ceiling, and the policy states it as such so
that nobody later reads it as a considered trade-off.

It happens to be defensible on its own terms. Stances are **GDPR Art. 9 special-category
data** (§9 of `PRIVACY-DATA-MODEL.md`), so a record of *who read whose stances* is itself a
record about special-category data. Art. 5(1)(e) storage limitation argues for keeping such
records briefly, not indefinitely. A short window is the privacy-preserving answer as well
as the cheap one.

**What 7 days does not buy, stated plainly:** a read that nobody looks at within a week is
invisible permanently. That is the direct cost of this choice, and it is why §5b is not
optional.

Longer retention is possible and was **not** chosen now: it requires the deferred
in-database audit of the design's Stage 3, or a log drain, or a plan change. Revisit it
with Stage 3 rather than separately.

### 5b. Review — weekly, and by a named person

> **A named individual reviews stance-read records weekly.**

Decided by Chris, 2026-09-16.

Weekly is not a preference; it is forced by §5a. A cadence longer than the 7-day window
means evidence expires before anyone sees it, and the audit becomes decorative.

**The reviewer is a person, never a team.** A duty assigned to "engineering" is a duty
nobody performs. **Reviewer: Chris, until explicitly delegated in this ADR** — reassignment
is an edit here, not an informal handover.

Expected volume is near zero: on 2026-09-14 no stance in the system was public and no
staff-read path existed, so most weeks should find nothing. **That is the failure mode to
design against** — a routine that is empty every week is a routine that stops being
performed. Implementations should prefer a scheduled query that alerts only on a non-empty
result over a checklist item a human is trusted to remember.

### 5c. Erasure — pseudonymise, keep the record

> **When a user is erased under GDPR Art. 17, audit records naming them are pseudonymised,
> not deleted: the subject's id is replaced with an irreversible token.**

Decided by Chris, 2026-09-16.

The audit still shows that a read occurred and who performed it; it no longer says whose
stances were read. This mirrors the approach `PRIVACY-DATA-MODEL.md` §9 proposes for
`connect.invite_chains` (tension 1) — reduce the personal element to a non-personal token
rather than destroy the accountability record.

The alternative was rejected for a specific reason: full deletion would let a person erase
the evidence of who accessed their data, **including in precisely the case where that
evidence is what mattered**. Erasure should remove the personal data, not the trace of its
misuse.

At a 7-day window this rarely bites — records usually expire before an erasure request
completes. It is settled now anyway, because Stage 3 would make it live and it is far
cheaper to decide while the answer is still hypothetical.

## 6. Explicitly open — do not read this ADR as settling any of it

- ✅ **Can EV ever unmask? — CLOSED 2026-09-17. Escrowed break-glass, not pure double-blind.**
  When this ADR was written the fork was open and §4 was deliberately phrased so either
  outcome stayed available. It has since been decided in
  `ev-cto/knowledge/decisions/0022-connected-identity-vault.md` (accepted 2026-09-17) and
  **built** — `docs/superpowers/specs/2026-09-17-connected-identity-vault-design.md`, shipped
  in PR #528: a Connect member's real name and raw street address are readable only by **two
  of four board members acting together, offline**, via a CLI that requires a `--reason` and
  appends to an append-only log.

  🔴 **This does NOT close §4's transitional exception, and the distinction matters.** Decision
  0022 seals **identity** — name and address. It does not seal **stances**. So "EV staff can
  read a member's beliefs" is still true, still transitional, and still waiting on the
  separation Chris's own exploration committed to. Do not read "the vault shipped" as "§4 is
  finished".

- ⚠ **`PRIVACY-DATA-MODEL.md` has not caught up.** As of 2026-09-18 its §8a is still headed
  *"(OPEN, pivotal)"* and still says *"Status: open — Chris to decide"*, and §11 still lists
  the question as open — while the decision is accepted and the code is merged. That is
  documentation drift in the platform's canonical privacy document, and it is not this ADR's
  to fix: raised for whoever owns that file.

- **The re-identification threshold.** Unspecified.
- **The minimum slice population.** Unspecified — see §3's rejected alternative.
- **Governance of the split-control group.** Partly specified now: 2-of-4 across four board
  members (0022 §Founder choices, D2), with no backup share. What remains unspecified is the
  surrounding procedure — who the four are, how a share is rotated or replaced, and what
  constitutes a valid reason to break glass. The vault spec also records that **cryptographic
  threshold decryption is still open** (D3), with procedural isolation as the base.

§4 and §5 are floors on *current* behavior. They constrain how low things may go; they do
not describe the destination.

## 7. Consequences

- **ev-accounts** owns both floors. §5 is new work; its scope is a decision, not a design,
  and it is not specified here.
- **Civic Spaces** already satisfies §3 — its slice types are `federal | state | county |
  city | unified | volunteer` with no finer tier, and it renders no stances at all. The
  practical effect is a constraint on future features, not a change.
- **Compass** owns the §4 surface in practice, since it is where stances are read and
  written.
- A proposal to publish a geography finer than the slice tier — a township MCD tier, a ward
  tier, a "neighbours near you" feature — now has a rule to be checked against, and §3's
  rejected population-threshold alternative is the natural place to reopen.
