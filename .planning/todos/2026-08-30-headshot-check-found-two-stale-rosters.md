# Two stale rosters, found by a headshot repair — Monterey Park CA and Lawrence County IN

**Found:** 2026-08-30, while repairing 10 officials whose photo was missing from our own bucket.
**Status:** open. Neither is a photo problem; both are occupancy/modelling problems.
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

**Do not fix by relabelling.** Districts 1–5 need real geography or the address path still cannot
reach them, and a rotating mayoralty must not become a dated `office_terms` row that implies a
four-year tenure.

---

## What was repaired

9 of the 10 headshots were re-imported (`--replace`): 7 Massachusetts legislators whose bucket
object returned `NoSuchKey`, plus Henry Lo and David E. Argudo, who pointed at placeholder
`default.*` files of 205–1658 bytes. Lytton was deliberately left alone.

⚠ **A missing object in our own bucket answers HTTP 400, not 404** — Supabase returns 400 with a
JSON body that itself says `{"statusCode":"404","code":"NoSuchKey"}`.

Tool: `node backend/scripts/verify-rendered-photo-urls.mjs --all`
