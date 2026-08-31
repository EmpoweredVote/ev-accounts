# Two stale rosters, found by a headshot repair — Monterey Park CA and Lawrence County IN

**Found:** 2026-08-30, while repairing 10 officials whose photo was missing from our own bucket.
**Status:** Monterey Park ✅ FIXED by `CC_0020` + `CC_0023` (boundaries). Lawrence County ✅ RESOLVED by `CC_0024` — see the 2026-08-31 update below; it turned out to be TWO seats, not one.
Neither was a photo problem; both are occupancy/modelling problems.
**Why it surfaced here:** going to a body's own roster for a portrait forces a read of who that body
says is sitting. The headshot pass is a redundancy check on occupancy, and it caught two bodies.

---

## 1. Lawrence County, IN — District 4 has the wrong person

We hold **Jeffrey Lytton** (`b67611e0-a274-4db6-80ae-281563f36a13`, `external_id` 380698) in
County Council District 4.

The county's own roster says **Larry Arnold**:

> Amy Redman, District 1 · Phil Inman, District 2 · Janie Craig Chenault, District 3 ·
> **Larry Arnold, District 4** · Rick Butterfield, At Large · Julie Hewetson, At Large ·
> Dustin Gabhart, At Large
> — <https://lawrencecounty.in.gov/183/County-Council>, read 2026-08-30

⚠ **A web search said Lytton still held the seat.** The body's own roster said otherwise. Same rule
as Open States: a third-party index is a DETECTOR, not an ORACLE.

**No headshot was uploaded for Lytton.** Putting a portrait on a wrong officeholder would have
made the error look more authoritative, not less.

### DECISION 2026-08-30 (Cantrell): WRITE NOTHING YET.

🔴 **The roster is not enough, and the first read of it was too confident.** Further evidence:

- Larry Arnold **filed 2026-01-16** and **won the Republican primary 2026-05-05** for District 4
  (57.37%, 331 votes) over Brian Prince. **A primary win seats nobody** — the general is Nov 2026.
- **Jeffrey Lytton ran in the DISTRICT 3 primary in 2026** and lost to David Holmes (52.84%).
- No source says Arnold was appointed, or when. WBIW's primary-results article marks no incumbents.
  (The only 2026 council caucus WBIW reports is an **At-Large** vacancy after Scott Smith died
  2025-12-28 — a different seat.)

So there are two readings and the evidence does not separate them:
1. Arnold was caucused into D4 at some point and the roster is current — supported by Lytton
   running in **D3** rather than D4.
2. The county updated its Members list early to show the primary winner, and **Lytton holds the
   seat until 2026-12-31**.

🔴 **WHY THAT BLOCKS THE WRITE.** Closing Lytton's term needs a `term_end`, and
`office_terms` has `start_precision` but **NO `end_precision`** — so any date written here is an
unqualified claim a later reader will take as fact. Seating Arnold from a placeholder would
assert Lytton left on 2026-08-29, which no source supports.

**The one question to settle:** did Arnold take District 4 by caucus, and on what date? The county
clerk can answer it directly; council minutes would show the meeting he first attended. Failing
that, the **November 2026 general resolves it**, and the winner can be seated from a real
**2027-01-01**.

⚠ Until then Lytton stays on display and is probably wrong. That was chosen deliberately over
inventing a date.

Note the county publishes **no member photos at all**, so this body has no portrait source.

### UPDATE 2026-08-31 (Cantrell): RESOLVED. Reading 1 was right. Written by `CC_0024`.

The blocking question was "did Arnold take District 4 by caucus, and on what date". Both halves
are now answered, and the answer did NOT come from minutes.

🔴 **THE COUNTY PUBLISHES NO COUNCIL MINUTES.** Its AgendaCenter holds County Council
documents for 2024 and 2025 only — one file in total — and none for 2026. The Archive Center is
empty. Commissioners' agendas ARE posted for all of 2026, so the gap is this body, not the site.
Council meetings exist only as video on the county's YouTube channel. Do not go looking again.

What settled it instead:

- **Lytton RESIGNED.** WBIW, 2026-01-08: he "resigned his post after moving his primary residence
  to a different council district, rendering him ineligible to represent District 4." That single
  fact kills reading 2 — the seat could not have stayed with him until 2026-12-31.
- **A caucus was called to fill the remainder of his term, for Thursday 2026-01-22.**
- **A second caucus, 2026-01-30**, filled Scott Smith's at-large seat.
- **The Internet Archive brackets the roster change**, and it happened BEFORE the May primary:
  2025-02-26 Lytton / Blackwell-Chase → 2026-01-05 Lytton / Scott Smith → today Arnold / Gabhart.
  The county's search index dates that page edit to 2026-02-10 — after both caucuses, three
  months before the primary.

⚠ **STILL INFERRED, AND SAID PLAINLY IN THE MIGRATION HEADER:** no source reports who WON either
caucus. The roster names them, and a party caucus is the only route into either seat before
2027-01-01. To close that gap properly, ask the clerk for the two **CAN-12** filings.

🔴 **IT WAS TWO SEATS, NOT ONE.** The third at-large seat
(`5dcf1678-1996-448e-8933-39094ebe9326`) held NO ONE in our data: Scott Smith's term was already
closed correctly (`term_end` 2025-12-28, `how_ended` 'died') and nobody replaced him. Reading one
roster line carefully surfaced the seat next to it.

🔴 **THE `end_precision` PROBLEM DID NOT GO AWAY — IT WAS DOCUMENTED INSTEAD.**
`seat_officeholder` closes the predecessor the day before the successor starts, so Lytton's
`term_end` reads 2026-01-21. His real last day is an unknown day before 2026-01-08. There is no
column for that, so the migration header carries it, and `how_ended` is set to `'resigned'` — the
part that IS known. A vacancy span was rejected: it needs a first vacant day we do not have.


---

## 2. Monterey Park, CA — the council is modelled wrongly, and one member is missing

Henry Lo's headshot was correct, so it was imported. His **seat** is not.

What the city publishes (<https://www.montereypark.ca.gov/917/City-Council>, read 2026-08-30):

| Person | Role | Seat |
| --- | --- | --- |
| Henry Lo | **Mayor** | District 4 |
| Jose Sanchez | Mayor Pro Tem | District 3 |
| Thomas Wong | Council Member | District 1 |
| Vinh T. Ngo | Council Member | District 5 |
| Elizabeth Yang | Council Member | District 2 |

> "Council Members are elected by districts for four-year, overlapping terms of office. The Mayor,
> who is selected during each Council reorganization **every nine and half months**, presides over
> all Council meetings and is the ceremonial head of the City."

What we hold:

| Person | Our title | Our label |
| --- | --- | --- |
| Henry Lo | Council Member | At-Large |
| Jose Sanchez | Council Member | At-Large |
| Thomas Wong | Council Member | At-Large |
| Vinh Ngo | **Mayor** (`LOCAL_EXEC`) | Monterey Park Mayor |
| *(absent)* | — | — |

Four defects:

1. 🔴 **Elizabeth Yang (District 2) is missing entirely.** A District 2 resident gets no council
   member from an address search.
2. 🔴 **Mayor is modelled as a standing OFFICE, and it is a ROLE that rotates every ~9.5 months.**
   We seat **Vinh T. Ngo** in it; the city says the mayor is **Henry Lo** and that Ngo is the
   District 5 council member. So the office is wrong AND its occupant is stale. This is the
   Buncombe/Durham lesson again: *chair is an OFFICE in one body and a ROLE in another* — see
   `.planning` notes for the NC wave.
3. 🔴 **All seats are recorded `At-Large` although the city elects by district.** Five district
   seats exist; we hold three At-Large ones.
4. Only 4 of 5 seats exist at all.

### ✅ FIXED by `CC_0020` (applied 2026-08-30)

District 1 Thomas Wong · District 2 **Elizabeth Yang** (new) · District 3 Jose Sanchez
**(Mayor Pro Tem)** · District 4 Henry Lo **(Mayor)** · District 5 Vinh Ngo.

- The mayoralty is now a **parenthetical on the seat title**, the corpus's existing shape for a
  role (`Council Member (Vice Mayor)`, `Commissioner (Chair)`). A role that turns over every ~9.5
  months must never become a dated `office_terms` row implying a four-year tenure.
- The four existing offices were **REPOINTED**, not recreated, so `office_id` never changed and
  every open-ended `start_precision 'unknown'` term rode along. **No date was invented.**
- 🔴 **The five district rows carry the PLACE `geo_id` 0648914, not council-district polygons.**
  That is the house pattern, not a shortcut — Long Beach holds nine `District N` LOCAL rows on one
  place `geo_id`, as do ≥5 other CA cities. District rows WITHOUT geometry would make every seat
  **unreachable from an address**, strictly worse than the status quo. Verified after applying: a
  Monterey Park point returns all five, and the geofence polygon for 0648914 is present.
- ✅ **BOUNDARIES LOADED by `CC_0023` (2026-08-31).** Source: the city's own ArcGIS Hub, reached
  through the `operationalLayers` of its published *City Council Districts* web map (item
  `d694e535a8d64fe395e2a7c5eff2afa2`) — the Hub item is a **Web Map, not a feature layer**, so its
  `/data?f=json` has to be read to get the FeatureServer URL. Five polygons, populations
  12,084–12,432. An interior point in each district now returns **exactly one** council member.
  🔴 The layer's `CityCouncilMember` field **independently confirmed `CC_0020`'s seating** —
  1 Wong, 2 Yang, 3 Sanchez, 4 Lo, 5 Ngo — against the council web page, a different source.
  Recorded in `backend/data/arcgis_sources.json` (the file's first CA entry).

---

## What was repaired

9 of the 10 headshots were re-imported (`--replace`): 7 Massachusetts legislators whose bucket
object returned `NoSuchKey`, plus Henry Lo and David E. Argudo, who pointed at placeholder
`default.*` files of 205–1658 bytes. Lytton was deliberately left alone.

⚠ **A missing object in our own bucket answers HTTP 400, not 404** — Supabase returns 400 with a
JSON body that itself says `{"statusCode":"404","code":"NoSuchKey"}`.

Tool: `node backend/scripts/verify-rendered-photo-urls.mjs --all`
