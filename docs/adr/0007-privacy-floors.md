---
status: proposed
---

> **Draft, 2026-09-15.** Decided with Chris in a working session, out of the 2026-09-12→14
> Civic Spaces ↔ ev-accounts exchange
> (`civic-spaces/.planning/phases/15-tool-deep-links/ACCOUNTS-HANDOFF.md`).
>
> It states **two decided floors** and leaves the **unmask fork explicitly open** — Chris is
> actively exploring that separately, and nothing here should be read as resolving
> `PRIVACY-DATA-MODEL.md` §8a. Read `PRIVACY-DATA-MODEL.md` first; this ADR sits under it
> and reuses its vocabulary (realms, the vault, `pseudonym_id`) without redefining it.
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

## 6. Explicitly open — do not read this ADR as settling any of it

- **Can EV ever unmask?** `PRIVACY-DATA-MODEL.md` §8a. **Chris is actively exploring this
  separately**, and the current direction is a tiered break-glass under split control rather
  than pure double-blind — but it is **not decided**, and §4's transitional exception is
  deliberately written so that either outcome remains available. Nothing here forecloses it.
- **The re-identification threshold.** Unspecified.
- **The minimum slice population.** Unspecified — see §3's rejected alternative.
- **Governance of any split-control group.** Unspecified.

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
