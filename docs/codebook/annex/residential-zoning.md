# residential-zoning — served revision 6b5a3504-9e90-455a-9dd5-07e5376399af (Season 2)

**Status:** draft (2026-10-01). Lines marked _(proposed)_ are a drafter's reading, not yet ruled;
lines marked `_owed:_` need a ruling before this file is merged. The season pin is an older revision
(`ef2a5e59-…`); coders code the served text below.

**Question:** "What should guide decisions about housing density and neighborhood character in your
community?"

**Orientation:** off-axis (CLAUDE.md lists it). Read it as one scale of **how much housing density
zoning permits in residential areas**: rung 1 permits no increase, rung 5 permits any housing type on
any lot. It is **not** a government-action scale. Rung 5 removes zoning rules, and it is also the
rung that permits the most housing; rung 1 keeps the most rules. A "more government" reading and a
"less regulation" reading point in opposite directions here, and placements have been inverted both
ways before. Place a person only by the density their act or words permit.

**Levels with a role:** local (`compass_topic_roles`). The lever is the city or county zoning code,
rezonings, and the general or comprehensive plan. State laws that override local zoning are state
acts; this topic has no state role (see hard cases).

**Synonyms:** "single-family zoning" (R-1), "upzoning", "downzoning", "accessory dwelling unit"
(ADU, granny flat, backyard cottage), "duplex", "triplex", "fourplex", "missing middle", "lot split",
"multifamily", "mixed-use", "transit-oriented development", "corridor plan", "by right" (no
discretionary approval), "conditional use", "neighbourhood character", "historic district", "density
bonus".

1. **"Protect existing single-family neighborhoods; oppose density increases."**
   - Means: keep single-family areas as they are and allow no added density.
   - Operative clauses: [a] protect existing single-family neighbourhoods; [b] oppose density
     increases.
   - Establishing evidence looks like: own words against density increases in general; a vote
     against a citywide ADU, duplex or upzoning ordinance **plus** own words that density, not the
     details, is the objection.
   - Levels that hold a lever: local.
   - Known chair-shaped instruments: _(none on file)_.
   - A No on **one** project rezoning may rest on the project (traffic, height, design) →
     `direction-only` _(proposed)_.

2. **"Allow modest density increases, like duplexes and accessory units, in single-family
   neighborhoods"**
   - Means: allow small additions such as duplexes and ADUs inside single-family areas.
   - Operative clauses: [a] modest density increases (duplexes, accessory units); [b] in
     single-family neighbourhoods.
   - Establishing evidence looks like: authoring or a final-passage vote on an ADU or duplex
     ordinance for single-family zones; own words supporting it.
   - Levels that hold a lever: local.
   - Known chair-shaped instruments: _(none on file)_.
   - `_owed:_` An ADU-only or duplex-only ordinance, with nothing else on record: rung 2 (V4.2
     "Broader than the instrument": seat the narrower rung), or `direction-only` (it does not
     exclude rungs 3–5)?
   - Commonly confused with rung 5 because allowing duplexes on every lot **ends single-family-only
     zoning**. It does not allow "any housing type on any lot", so it is not rung 5; code the density
     it allows _(proposed)_.

3. **"Allow multifamily and mixed-use near commercial corridors while protecting most residential
   zones"**
   - Means: add apartments and mixed-use buildings along commercial streets, and leave most
     residential areas as they are.
   - Operative clauses: [a] allow multifamily and mixed-use near commercial corridors; [b] protect
     most residential zones.
   - Establishing evidence looks like: a corridor or transit-area rezoning whose text limits the new
     density to those areas; own words for both parts. Compound: one side only → `compound-partial`
     (V4.2). A corridor rezoning whose map leaves the other residential zones unchanged meets [b] by
     its scope _(proposed)_.
   - Levels that hold a lever: local.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 4 because a large corridor plan can reach many neighbourhoods. Code
     4 only when the passage shows multifamily by right in **most** neighbourhoods.

4. **"Upzone broadly to allow multifamily housing by right in most neighborhoods"**
   - Means: change zoning across most of the community so apartment buildings are allowed without
     special approval.
   - Operative clauses: [a] upzone broadly, in most neighbourhoods; [b] multifamily; [c] by right.
   - Establishing evidence looks like: a citywide zoning change that allows multifamily buildings by
     right in most residential zones.
   - Levels that hold a lever: local.
   - Known chair-shaped instruments: _(none on file)_.
   - `_owed:_` Triplexes and fourplexes allowed by right in most zones: rung 4 (multifamily) or rung 2
     (modest density)?
   - An upzoning that still needs a discretionary permit for each project does not meet [c] →
     `compound-partial` _(proposed)_.
   - Commonly confused with rung 5: see rung 5.

5. **"Eliminate single-family-only zoning; allow any housing type on any lot communitywide"**
   - Means: no zone is reserved for single-family homes, and every housing type is allowed on every
     lot.
   - Operative clauses: [a] eliminate single-family-only zoning; [b] allow **any** housing type on
     **any** lot, communitywide.
   - Establishing evidence looks like: own words or an ordinance that allows every housing type on
     every residential lot. Compound: one side only → `compound-partial` (V4.2). [b] is a universal
     clause: the text must say "any" or list no limit, and silence does not meet it (V4.2 "Silence is
     not a clause").
   - Levels that hold a lever: local.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 4 because a broad upzoning reaches most lots. Rung 4 is "most
     neighbourhoods"; rung 5 is every lot and every type.
   - Commonly confused with rung 2: see rung 2.

**Hard cases:**
- **State laws that override local zoning** (statewide ADU, duplex or lot-split rights). This topic
  has no state role, so a state legislator's act → BLANK `scope-unavailable` _(proposed)_. Such a
  law removes the very limits a rung names, so for a level that does hold the lever it would be
  `on-question` but `direction-only` (codebook V2, "Refined 2026-09-26").
- **A local official implementing a state mandate** (adopting the ordinance the state requires) is
  not their own position → `direction-only` at most _(proposed)_.
- **Parking minimums, design review and permit streamlining** are not density → `adjacent`
  _(proposed)_.
- **Historic districts and downzonings** that stop added density point toward rung 1 →
  `direction-only` unless own words generalize them _(proposed)_.
- **Inclusionary and affordability requirements** are about who can afford the units, not density →
  `adjacent` (the `housing` topic).
- **General and comprehensive plans** → V4 `multi-subject`.
