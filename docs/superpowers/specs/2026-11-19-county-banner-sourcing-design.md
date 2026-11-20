# County banner sourcing — the choose-and-crop method

**Date:** 2026-11-19
**Author:** Chris Cantrell, with Claude
**Status:** proposed, awaiting approval
**Scope:** image coverage for every county and parish in the United States (~3,222)

---

## Intent

Anyone in the country should be able to type an address into Civic Spaces or Treasury
Tracker and get a County Slice with a photograph of the place they actually live. Today
the county banner set holds 14 entries.

The work is almost entirely sourcing and judgement, not engineering. So the design
question is not "how do we fetch images" — it is **how do we spend the operator's
attention**. Every decision below exists to reduce the operator's job to looking at a
page of real options and choosing, state by state.

## Why now

A fully automated first pass over Nebraska was built, run, and measured. It did not hold
up. A second pass, where the operator chose from options and cropped each one by hand,
did. This document records the second method as the standing one, with the numbers that
decided it.

---

## Goals

- National coverage: an image for every county where an honest one exists.
- The operator's effort per county is **one look and one choice**, not a search.
- A county with no good image ships **blank**, visibly and deliberately.
- Every choice the operator makes is **stored and seen to be stored**.

## Non-goals

- Perfect coverage. Blanks are an expected output, not a failure.
- Automating the choice. The operator chooses; the machine narrows.
- Replacing city banners. Where a city banner exists it still wins for addresses inside
  that city; the county banner serves the rest of the county.

## Anti-goals — what would make this a failure even if it ran

- **Shipping a weak image because one was available.** A wrong or dull photo on a
  County Slice is worse than an empty band, because it asserts something about a place.
- **Shipping an image from the wrong county.** This already happened: a Colorado river
  photograph topped seven Nebraska counties in an early pass, because the source was
  found by category name rather than by location.
- **A pass that looks like it worked and did not.** See *Saving is reported, never
  assumed*, below. This cost 73 counties of operator cropping in one afternoon.

---

## Approaches considered

### A. One automated pass — rank candidates, ship the top one per county

Cheapest by far, and it is what was built first. **Rejected on measurement.** Across
Nebraska's keeps, where the operator had a real choice between two or more candidates,
they took the top-ranked option in 29 of 55 counties and moved to a lower-ranked one in
**26 of 55 — 47%**. An automated pass would therefore have shipped the wrong photograph
in close to half the counties where a choice existed, and nothing in the system would
have reported a problem.

### B. Choose-and-crop, state by state — **chosen**

Machine narrows to at most five verified candidates per county; operator picks one,
sets both crop levers, and marks the county *keep* or *needs another look*. Slower per
county than A and far faster than C. It is the only one of the three whose error rate
was actually measured rather than assumed.

The operator's own reason, 2026-11-19: *"I'd rather go at this speed, have options that
I can choose and crop and go state by state than to have our first pass."*

### C. Hand-source each county

Highest quality, and not survivable at 3,222 counties.

### D. A rendered cartographic base for counties with no photograph — **chosen as a second tier**

Where no photograph clears the bar, draw the banner from our own TIGER county geometry.
**Approved 2026-11-19, styled so nobody mistakes it for a photograph.** It is not AI
imagery and so falls outside decision D-09: nothing is invented, the shape rendered is
the boundary data we already hold. On Nebraska's rate this covers roughly 870 counties.

B and D compose. B is the first tier and always preferred; D is what a county gets
instead of nothing. A county still ships **blank** only if both fail, which should now
be rare.

---

## Constraints

### Banner geometry — two independent levers

The stored asset is **1700 × 540** (3.148:1). Two surfaces cut it differently:

| Surface | Renders | As a share of the asset |
| --- | --- | --- |
| Desktop | a 6:1 band | **52.5%** of asset height |
| Mobile | 13:4 (3.25:1) | **96.9%** of the asset |

So there are two crop decisions, and they are independent:

1. **Vertical anchor** — where the 3.148:1 asset is cut out of the full source
   photograph. Governs what mobile sees.
2. **`focus`** — a CSS `object-position` string such as `'50% 30%'`, which slides the
   6:1 band within the asset. Governs what desktop sees.

A frame that reads correctly on desktop can be wrong on mobile and the reverse.
**Certify on the band and on the asset.** (The Aberdeen "ROAD CLOSED" sign was invisible
in the desktop band and dominant on mobile.)

🔴 **`getBuildingImages` reads `focus`. The `focus` must be copied, not just the `src`.**
A pipeline that carries the filename and drops the focus string silently re-centres every
banner the operator cropped.

### There is a third frame, and it currently throws the crop away

Measured 2026-11-19. The two-lever model above describes the **Essentials** banner only.
Civic Spaces — the surface this document's Intent names first — renders the County Slice
hero in `src/components/HeroBanner.tsx` as:

```
absolute inset-0 w-full h-full object-cover object-center
```

inside a box sized `min-h-40 sm:min-h-48 md:min-h-56 lg:min-h-64` with **no fixed aspect
ratio**. So:

- It **never reads `focus`.** The operator's desktop crop is discarded on that surface.
  🟢 **Decided 2026-11-19: Civic Spaces will be changed to read `focus`**, so one
  certification covers both products. That is cross-repo work and a prerequisite for
  this programme's output being worth anything on the surface the Intent names first.
- Its shape changes with window width and with how much text sits in the hero. On a
  narrow phone the box is *taller* than the 3.148:1 asset, so it crops the **sides**, not
  the top — a failure mode neither existing lever addresses.
- It does not read the Essentials registry at all. It builds
  `src/lib/banners.generated.ts` from two files Essentials publishes — `banners.json`
  for credits and `coverage.json` for geo ids — joined on the browse label.

⚠ **So shipping a county banner is three artifacts, not one:** the image, a parseable
credit line, and a coverage row whose browse label matches. A banner that reaches only
the first of those does not appear.

### Attribution is a hard gate, not a nicety

The Civic Spaces generator already enforces this and says so in its own header: *"a
banner we cannot credit is a banner we cannot show"* — assets published with no author
are dropped by design, and the generator reports which and why on every run. A candidate
whose author and licence cannot be read is therefore not a candidate. It must be
filtered out **before** the operator spends attention on it, not discovered afterwards.

### The county tier ships centred today

There are seven county banners in `buildingImages.js` — Dane, El Paso, Travis, Pima,
Riverside, King, Kitsap — and **not one of them carries a `focus`**. Against Nebraska's
rate, where the operator moved the crop off centre in 57 of 73 counties, that is the
single largest quality gap in the existing set.

### Geometry is the only trustworthy membership key

A candidate belongs to a county when its coordinates fall inside **our own** county
polygon:

```sql
ST_Contains(g.geometry, ST_SetSRID(ST_MakePoint(lon, lat), 4326))
  -- essentials.geofence_boundaries where mtfcc = 'G4020'
```

Commons category traversal is useful for **recall** — finding candidates at all — and is
not evidence of location. Categories nest, alias and mislead. Confirm every candidate
against the polygon before it reaches the operator.

### Saving is reported, never assumed

On 2026-11-19 the first crop editor's write path failed on its first call and every
subsequent save returned early in silence. The page looked correct the whole time. 73
counties of cropping were lost and recovered only because the page's state was still in
memory.

Any operator surface built from this design must therefore:

- show a **per-item save stamp** — this county is saved, with a time, or is NOT SAVED
  with the reason;
- show a **page-level line** saying whether saving is switched on at all, visible from
  load, not hidden until something breaks;
- treat a failed read as a reason to **stop the operator**, not to carry on;
- separate *loading* from *ready-to-write*, so one unreadable row cannot disable writing
  for everything else.

### House rules that apply

- Never create a table or view in `public`.
- `WebFetch` must never be the source of a name, date or count.
- Wikimedia 429s a generic User-Agent; send a named client string, never the operator's
  contact details.
- A detector reporting "nothing found" is untrusted until a control has been watched
  failing.

---

## The method

Six steps. One state at a time.

**1 — Recall: gather candidates.** Walk Commons categories for the county and its
places, **including its incorporated places and its county seat** (see *Subject rule*).
Over-collect; precision comes next.

**2 — Precision: filter.** Three filters, all applied before the operator sees anything:
coordinates inside our county polygon; source at least **1700px** on the long edge; and
a readable author and licence. Discard the rest without review.

**3 — Render the full source frame, uncropped.** Downscale to about 1100px on the long
edge and keep the whole frame. The vertical slack outside a 3.148:1 crop *is* the lever;
a pre-cropped file throws it away and the operator cannot set either anchor.

**4 — Build the state's review page.** Up to five options per county. Each option carries
both crop levers, live, with the 6:1 desktop band and the full asset shown together.

**5 — The operator chooses and crops.** For each county: pick an option, set the vertical
anchor, set the focus, and mark the county *keep* or *needs another look*.

**6 — Ship keeps. Everything else falls to the map tier.** Export `src` **and** `focus`
**and** `verticalAnchor` together, with the credit line and the coverage row.

**7 — Render a map for every county that produced no keep.** Approach D, above.

### The blank ruling

🔴 **A county the operator marks "needs another look" does NOT ship with the best
available option.** Standing ruling, Chris Cantrell, 2026-11-19: *"those choices I would
rather have blank than to use the provided options."*

This is the rule that makes the whole method honest. The machine is allowed to find
nothing. It is not allowed to settle. The map tier gives those counties something
truthful instead of a weak photograph — it does not soften the bar for photographs, and
a rejected photograph is still rejected.

### Subject rule

**A county banner may show a city, including its county seat.** Decided 2026-11-19.
The existing set contradicted itself here — Dane County and El Paso County deliberately
avoided the city, Racine County is its seat's downtown — and for most counties the seat
is the only well-photographed place. Non-city subjects remain preferred where one clears
the bar; the seat is not a last resort, but it is not the default either.

### Eligibility

**Every county and parish is eligible, including counties that contain a bannered city.**
Decided 2026-11-19, superseding the earlier ruling that limited county banners to
counties with no city half. The reason that ruling existed — not wanting a county photo
to stand in for a city that has its own — is handled by precedence instead: **a city
banner wins for addresses inside that city, and the county banner serves the rest of the
county.** Before this, a resident of an unbannered town in such a county fell through to
the *state* photograph.

A consequence worth stating: nothing is retired. A county banner shipped today does not
come down when a city inside it ships one later, so this is a sweep rather than standing
maintenance.

---

## What Nebraska measured

93 counties. 410 candidates survived the polygon filter across 73 of them; 20 counties
produced no verified candidate at all.

| | count |
| --- | --- |
| Counties with at least one verified candidate | 73 |
| Counties with no verified candidate | 20 |
| Marked **keep** | 68 |
| Marked **needs another look** | 5 |
| Left unmarked | 0 |
| **Ships with a banner** | **68 of 93 (73%)** |
| **Ships blank** | **25 of 93 (27%)** |

Options actually offered per county: 29 counties got five, 8 got four, 13 got three,
9 got two, and 14 counties had only a single candidate.

Where the keep had a real choice (55 counties):

| | counties | share |
| --- | --- | --- |
| Operator took the first-listed option | 29 | 53% |
| Operator moved to a lower-ranked option | **26** | **47%** |

Cropping was not incidental: the operator moved a crop off centre in **57 of 73**
counties, across 71 individual options. A pipeline that ships centred crops ships the
wrong frame in roughly four counties out of five.

The five still open: Custer, Frontier, Greeley, Harlan, Saunders. Most are exhausted on
Commons and need a source outside it.

⚠ **Nebraska is rural and is not a national sample.** Its 73% keep rate is a floor to
reason from, not a projection. Urban and coastal counties should do better on recall;
other states may be worse on licence. Measure the second state before extrapolating.

⚠ **These numbers were produced under rules that have since changed, and are not a
forecast of the next state.** Nebraska was sourced before the subject rule admitted
county seats and before the map tier existed. Under today's rules its 20 empty counties
would each have had the seat's photographs to draw on, and its 25 non-keeps would now
receive maps rather than nothing. The 47% figure — how often the operator moved off the
top-ranked option — is the one number here that should carry forward, because it is
about the ranking, not about Nebraska.

---

## Calls made during review

These came out of a builder's read of the draft. They are my decisions, not the
operator's — flagged here so they can be overturned on sight.

- **Filter on resolution before the operator looks.** The shipped asset is 1700 × 540,
  and review renders downscale to ~1100px, so a source narrower than 1700px can be
  chosen and cropped and then cannot be built without upscaling. **Minimum 1700px on the
  long edge**, applied in step 2 beside the polygon test. The Racine notes already apply
  a floor of exactly this value by hand.
- **Read the licence before the operator looks, for the same reason.** A non-free file
  must not be able to consume a choice and a crop and then be thrown away. Licence and
  author are capture-time filters, not post-selection paperwork — and per *Attribution
  is a hard gate* above, an unattributable file is not a candidate.
- **Cap the options at five, and say what the ranking is.** Nebraska averaged 5.6
  candidates per county. Cook, Los Angeles and Maricopa will have hundreds. Where
  candidates are abundant the ranking decides what the operator ever sees — and ranking
  is the component measured wrong 47% of the time. So: show five, by a **written,
  reviewable ranking**, and give the operator a way to ask for the next five rather than
  pretending five was the whole set.
- **Flag the forced choices rather than re-bar them.** 14 Nebraska counties offered
  exactly one candidate and 13 were kept. A single option is not a choice, so mark those
  rows as such in the review page and let the operator see the flag. This replaces the
  draft's second open question; it changes a validation rule, not the shape of the work.
- **The operator is one person and the review surface stays private.** No
  authentication work is in scope unless that changes.

## The cost, stated plainly

Nebraska was 93 counties in one working session. At that pace the full set is roughly
**35 comparable sessions** of one person's undivided attention. That number is the
reason the ranking, the resolution filter and the licence filter all moved *ahead* of
the operator in this design: every candidate that reaches the page and should not have
is paid for in the scarcest resource the programme has.

If 35 sessions is not acceptable, the leverage has to be bought somewhere — a narrower
priority list, a better ranking, or a different review interaction — and that is a
decision to take before building, not after.

## What is left to the builder

- **Where review state lives at national scale.** 73 rows in an artifact database is
  fine; 3,222 is not. It needs a real table — in an EV schema, never `public`, with
  explicit grants and RLS in the same migration that creates it.
- **Batch size and ordering.** State by state is settled. Whether a state is one page or
  several, and in what order states are worked, is open.
- **The round-2 path** for counties Commons exhausts: state historical societies, USGS,
  NPS, Library of Congress, county and city sites. Licence is read, never inferred from
  the host.
- **Delivery into the essentials repo.** County banners live in `buildingImages.js` in
  the essentials repo, not in `treasury.municipalities`. The hand-off needs a shape, and
  it must carry three artifacts per county, not one: image, credit line, coverage row.
- **Carrying `focus` into Civic Spaces.** `HeroBanner.tsx` must apply it as
  `object-position`, `banners.generated.ts` must hold it, and `generate-banners.mjs`
  must read it out of whatever Essentials publishes. The shape of that published field
  is the builder's call.
- **The map tier.** Rendering, styling and its own certification question — a map crops
  nothing like a photograph, so the two-lever model does not transfer to it unexamined.
- **Precedence between a city banner and a county banner** for an address inside a
  bannered city. The rule is decided; where it is enforced is not.
- **Licence capture.** Each shipped banner must carry the file description page it was
  licensed from, not the raw upload URL.

---

## Decisions taken 2026-11-19

A builder's read of the draft raised four things that could not be settled from the code
or from the Nebraska run. All four were put to the operator and all four are now closed.

| Question | Decision |
| --- | --- |
| May a county banner show a city or its county seat? | **Yes**, with non-city subjects still preferred where one clears the bar |
| Civic Spaces discards `focus` — fix it, or certify a third frame? | **Fix Civic Spaces to read `focus`** |
| Is a county with a bannered city inside it eligible? | **Yes** — both exist, the city banner wins inside the city |
| May the blanks be rendered as maps from our own TIGER geometry? | **Yes**, styled so nobody mistakes one for a photograph |

Together these change the shape of the programme: the eligible set goes from "counties
with no city half" to **all ~3,222**, the expected blank rate falls from Nebraska's 27%
to near zero because the map tier catches what photographs miss, and one crop
certification now covers both products instead of being discarded by the one the Intent
names first.

⚠ One claim in that review was checked and was **false**: it reported that Marin and
Santa Cruz counties already carry banners knowingly breaking the city-half rule. No such
entries exist — there are seven county banners in total and none breaks a rule. The
reviewer had read the California *state* banner's notes, which mention the Marin
headlands. The question was worth asking; that evidence for it was not. Recorded here
because the question looked much more settled than it was.

### One proposed rather than asked

**What replaces the polygon test in round 2?** Every round-2 source named below — state
historical societies, USGS, NPS, Library of Congress, county sites — publishes images
with no coordinates, so round 2 as drafted cannot satisfy the one rule this design calls
non-negotiable. The same gap bites round 1: a correct, uncoordinated Commons photograph
of a county courthouse is discarded today, and some of Nebraska's 20 empty counties are
probably that rather than genuine absence.

Proposed, and overturnable: where coordinates are absent, location may be established by
**a published caption naming the place, confirmed against a second independent source,
plus the operator's own sight of it** — and the row is marked as located by caption
rather than by geometry, so the two are never counted together. Coordinates remain
preferred wherever they exist.

---

## Provenance

Every number in this document was measured on 2026-11-19 from the live Nebraska review
rows, not carried forward from an earlier estimate. An earlier figure in conversation
put the operator's agreement with the machine ranking at 40%; that was computed against
the first pass's different option ordering and against the wrong denominator. The figures
here supersede it.
