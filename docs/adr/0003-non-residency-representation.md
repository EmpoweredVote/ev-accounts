---
status: accepted
---

# Representation that is not based on residency

Every seat we model assumes the same two things: that a constituency is *a place*, and that a
representative *votes*. Both assumptions are wrong often enough to matter, and where they are wrong
we currently represent nothing at all. We decided to split those assumptions into two independent
fields — **`districts.representation_basis`** and **`offices.voting_powers`** — rather than add a
per-case exception, and to adopt a hard rule that **membership in a polity is never inferred from an
address**.

## Why now

Maine's House seats **three non-voting tribal representatives**: one each for the Penobscot Nation,
the Passamaquoddy Tribe, and the Houlton Band of Maliseet Indians. They may introduce bills, sit on
committees and vote *in committee*, but not on the floor. As of 2026-08-12 two are filled — **Aaron
Dana** (Passamaquoddy, serving through September 2026) and **Brian Reynolds** (Houlton Band of
Maliseet, seated May 2025 through October 2026) — and the **Penobscot seat is vacant because the
Penobscot Nation has not sent a representative**. The tribes withdrew their representatives in 2015;
the Maliseet seat sat empty for seven years before being reclaimed in May 2025.

We have none of them. `backend/scripts/roster-diff.mjs` reports Maine's House as **151 seats against
153 members** and flags Dana and Reynolds as people we do not hold — which is how this surfaced.

The Penobscot vacancy is the part that settles the question. A nation declining to seat a
representative is a **political act**, and a model that cannot hold the seat cannot record the
choice. Omitting these seats does not leave a neutral gap; it erases an exercise of sovereignty. That
is a stronger reason to build this than the two filled seats are.

The same shape is coming for the territories. Puerto Rico, the U.S. Virgin Islands, Guam, American
Samoa, the Northern Mariana Islands and the District of Columbia all send representatives to Congress
who cannot vote on final passage. Those are jurisdictions **within the United States but not wholly
governed by it**, and serving them is a deliberate priority rather than an edge case.

## The two axes, and why one flag will not do

The tempting move is a single `is_special` or `is_non_voting` flag. It collapses two things that
behave differently:

| | Constituency basis | Powers |
|---|---|---|
| Maine state representative | residency | full |
| PR Resident Commissioner, DC/Guam/USVI/AS/CNMI delegates | **residency** | **non-voting** |
| Maine tribal representative | **membership** | **committee-only** |

Puerto Rico's Resident Commissioner has a perfectly ordinary geographic constituency — every resident
of Puerto Rico — and a real polygon. What is unusual is the *powers*. A Maine tribal representative
differs on *both* axes. A single flag would either force PR into a "no real district" bucket, which
is false and insulting, or force tribal seats into a "residency" bucket, which drives the wrong
address behaviour. So:

- **`districts.representation_basis`** — `'residency'` (default) | `'membership'`
- **`offices.voting_powers`** — `'full'` (default) | `'committee_only'` | `'non_voting'`

Both get defaults matching today's behaviour, so every existing row keeps its current meaning and
nothing needs backfilling to stay correct.

## The rule that keeps it honest

**Membership is never inferred from an address.** We cannot know from a street address whether someone
is an enrolled member of the Passamaquoddy Tribe, and we must never guess. This has three
consequences that are binding, not advisory:

1. **A `membership`-basis district never drives assignment.** The existing address chain
   (`districts.geo_id` → `ST_Covers` → office → `office_terms`) answers "who represents this
   address". A membership seat is not an answer to that question.
2. **Geometry on a membership district is DISCOVERY-ONLY.** Census publishes AIANNH boundaries
   (American Indian / Alaska Native / Native Hawaiian areas) in TIGER with their own MTFCC codes, and
   `essentials.districts` already has `mtfcc` and `geo_id` to hold them. Storing that geometry is
   useful for surfacing the seat to people likely to care about it. It must not be wired into
   `ST_Covers` assignment. If a future query joins a membership district into the address path, that
   is a bug.
3. **Membership representation is ADDITIVE, never substitutive.** A Passamaquoddy member living in
   Millinocket is represented by **both** Nancy J. Theriault (House District 29) **and** Aaron Dana.
   Showing Dana in place of Theriault would be wrong; so would showing Theriault alone.

So the presentation is *available and explained*, not *assigned*. For an address inside a relevant
boundary we surface the seat with an explanation of who it represents and how a person comes to be
represented by it — and we let the reader decide whether it applies to them.

## "Broadly understood" is a schema constraint, not a hope

A tribal representative rendered on a profile card with no explanation misleads in both directions: a
non-member may believe they are represented, and a member may believe this replaces their district
representative. So the explanation is **required**, and its absence fails closed:

- `offices.representation_note` (text) is **NOT NULL for any office** where
  `representation_basis <> 'residency'` OR `voting_powers <> 'full'`.
- The Essentials read path **must not render** such a seat when the note is missing.

Fail-closed, the same posture as `requireRole`'s `essentials_data_editor`. An unexplained seat is
worse than an absent one, which is the opposite of the usual trade-off and the reason to encode it.

Note also that these seats carry **real `term_end` dates** — Dana through September 2026, Reynolds
through October 2026. They are a live reminder that `term_end IS NULL` is not a test for "current";
date containment via `essentials.current_office_holders` is.

## Considered options

- **A per-case exception for Maine.** Rejected. It is the third such request (tribal seats,
  territories, and the non-voting DC delegate) and each exception would be shaped by its one case.
  The two axes fall out of comparing the cases rather than any of them alone.
- **A single `is_special_representation` flag.** Rejected — collapses constituency and powers, as
  above.
- **Model tribal seats as ordinary districts with a polygon.** Rejected. It would make the address
  chain assign a tribal representative to every resident inside a reservation boundary regardless of
  enrollment, including non-members, and would silently substitute for the district representative.
- **Leave them out.** Rejected. It erases the Penobscot Nation's decision not to seat anyone, and
  keeps Maine permanently 2 seats short in every roster check.

## Consequences

- `roster-diff.mjs` goes from **151 v 153** to **153 v 153** for the Maine House once the three seats
  exist, and stops reporting Dana and Reynolds. It gains the ability to detect a tribal seat going
  unfilled — including, correctly, the Penobscot seat as a real vacancy.
- **`npm run check:reachability` must learn the difference.** It asserts that a point returns a
  representative. A membership seat must *not* be expected to resolve from an address, so the gate
  needs to exclude `representation_basis = 'membership'` from address expectations, or it will start
  failing for a correct reason and get muted.
- The Essentials read path needs a second class of representation on the profile/address response
  ("also represented by", with the note). That is a real frontend change, not just a schema one.
- `offices.is_vacant` alone cannot distinguish "nobody has been seated because the polity chose not
  to" from "the incumbent died". The Penobscot seat is the first case where the *reason* carries
  meaning. **Open question:** whether that belongs in `representation_note`, a new `vacancy_reason`,
  or `office_terms.how_ended` on a closed term. Not resolved here; do not paper over it by writing
  the Penobscot seat as an ordinary vacancy with no explanation.
- Federal territory delegates are then a **powers-only** change: real polygons,
  `voting_powers = 'non_voting'`, plus the required note. No new geography concepts.

## Not in scope

Foreign sovereign states. The service models jurisdictions with a U.S. electoral relationship; a
sovereign country with its own elections is a different product, not a representation basis.
