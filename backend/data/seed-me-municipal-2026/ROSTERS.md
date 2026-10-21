# Maine municipalities — seating the flagged-vacant skeletons

**Augusta is done (`CC_0282`). This file is the pattern for the other 16 cities.**
Read it before touching any Maine municipal office.

---

## 🔴 R1. THE DEFECT: `is_vacant = true` WAS USED TO MEAN "NOT SEEDED YET"

Every Maine municipal and school office arrived flagged `is_vacant = true` with a **NULL
`vacant_since`** and **no `office_terms` row** — 138 offices across 17 cities, **100% of them**.
Augusta was 18 of 18. Westbrook is 15 of 15.

That is not 138 vacancies. It asserts to a voter that the seat is empty, and at the same time it
**keeps the rows out of the drift metric**, because `offices_missing_terms` counts only *unflagged*
rows as drift. The two effects together are why this sat unnoticed.

⚠ Contrast the legitimate use, which this must not be confused with: Florida's `FL` wave flags a
seat `is_vacant = true` **with a `vacant_since` date and a named departed incumbent** — a real,
documented vacancy. Only **13 of 194** flagged offices repo-wide have such a date.

---

## 🔴🔴 R2. SEAT AND UN-FLAG IN ONE MIGRATION. NEVER AS TWO STEPS.

Neither half is safe alone. This is the whole ruling.

| Order | What breaks |
| --- | --- |
| **Clear the flag first** | `check-address-reachability.mjs` defines `DEAD_GEOGRAPHY` as *"polygon and offices, but no active holder **and is not flagged vacant**"*, and fires on **any new bucket**. Un-flagging unseated offices creates a new `me\|LOCAL` bucket. 🔴 That gate runs on **master-push and cron, not PRs** — it reddens on the next merge and blames an innocent PR. |
| **Seat without clearing** | Nothing clears `is_vacant` on seating: there is **no trigger on `offices` or `office_terms` at all**, and `seat_officeholder`'s body never touches the column — only `vacate_office` sets it, and nothing unsets it. You get a seated office still flagged vacant, which is CLAUDE.md's **`is_vacant` trap** (a spurious all-NULL office row for that holder). |

🟢 **Repo-wide there are ZERO seated-and-flagged offices.** The invariant is clean; a careless
Maine wave would be the first thing to break it. `CC_0282` carries a gate asserting it is still
zero, and every city migration must keep it.

### The two gates that prove you did it right

```sql
-- no office in this city is still flagged
-- AND no office in this city is unflagged-and-unseated
```

Both are in `CC_0282`'s post-verify. **Copy them.** The second was watched failing first: deleting
the term insert produced
`18 Augusta office(s) are unflagged AND unseated - that is a new me|LOCAL DEAD_GEOGRAPHY bucket`.
⚠ On the first attempt an earlier gate ("expected 18 terms, found 0") **shadowed** it — a control
can pass for the wrong reason, so the shadowing gate had to be relaxed to prove the real one fires.

---

## 🟢 R3. THE BASELINE IS THE TELL

`offices_missing_terms` is `total / flagged / unflagged`, and **only unflagged is the baseline**
(CLAUDE.md). Flagged offices were never in the 239.

**A correct Maine city migration moves TOTAL down by its office count and leaves UNFLAGGED at 239.**

| | total | flagged | unflagged |
| --- | --- | --- | --- |
| before `CC_0282` | 433 | 194 | **239** |
| after | 415 | 176 | **239** |

🔴 **If unflagged moves, the migration is wrong.** Assert both numbers in post-verify.

---

## R4. Dates: `unknown`, deliberately — and NEVER write the published expiry

`term_start` is the start of **continuous occupancy**, so only a FIRST win dates anyone. Augusta's
certified returns carry **no incumbency markers**, so they cannot distinguish a first win from a
re-election, and a document must be controlled for the marker before its absence means anything.
Walking back through earlier returns until each name disappears would date them — ~5 documents per
city, ~85 across Maine.

▶ **Trade made for the pattern: seat now with `start_precision => 'unknown'` and
`how_started => 'unknown'`; date later.** The holder is what makes the office visible at all. The
returns are online (`augustamaine.gov/195/Elections` and each city's equivalent) and are the source
for a dating pass whenever someone wants one.

⚠ `seat_officeholder` **refuses a NULL `term_start`** by design, so an unknown-start term uses its
own column list verbatim: `(office_id, politician_id, term_start, start_precision, how_started,
source)`. Safe only because these offices have no predecessor to close.

### 🔴🔴 DO NOT WRITE THE PUBLISHED "Term Expires" DATE TO `term_end`

Augusta's school board publishes an expiry for all nine seats, and it looks like free data. **It
is a trap.** In this schema a re-election never opens a new `office_terms` row, so `term_end` is
the end of the person's **occupancy**, not of their current term. Writing `2026-12-31` for Witham,
Parks and Hicks would **silently un-seat three sitting officials on 1 January 2027** — the view
would just stop returning them, with nothing erroring.

Record expiries here as a re-check schedule instead:

| Augusta Board of Education seat | holder | term expires |
| --- | --- | --- |
| Chair | Martha Witham | 2026-12-31 |
| Ward 2 | Susan Parks | 2026-12-31 |
| At-Large 4 | Charles Hicks | 2026-12-31 |
| Ward 3 | James Orr | 2027-12-31 |
| At-Large 1 | Jonathan Reynolds | 2027-12-31 |
| At-Large 2 | Gabrielle Bérubé Pierce | 2027-12-31 |
| Ward 1 | Samuel Baker | 2028-12-31 |
| Ward 4 | Bobby Jo Bechard | 2028-12-31 |
| At-Large 3 | Rita Pello | 2028-12-31 |

---

## 🟢 R5. CHECK WHETHER THE CHAIR IS A REAL SEAT — IN AUGUSTA IT IS

The house rule says a **rotating role** (vice chair, mayor pro tem) is a parenthetical on a seat
title and never its own office. Applied blindly it would have deleted Augusta's `School Board
Chair` office.

**It does not apply here.** The board's own page lists the Chair as a ninth row with **her own term
expiry** and no ward or at-large label, alongside 4 ward + 4 at-large seats. Augusta elects its
school board chair citywide.

▶ **Check each city before applying the general rule.** A correct general rule can still do damage
to a specific place.

---

## R6. At-large seat numbers are OURS, not the city's

Neither Augusta body numbers its at-large seats; our schema has `At-Large 1..4`. Assignment follows
each body's own listed order and **carries no meaning** — all at-large members represent the whole
city identically. Do not read `At-Large 2` as a fact about anyone, and do not "correct" an
assignment.

---

## ⚠ R7. Open modelling question, NOT fixed here

All nine Augusta council seats and all nine school seats hang off **one citywide district**, so an
Augusta address returns all 18 — including the three ward councillors that voter does **not**
elect. Augusta's ward seats are ward-elected.

This is the same question El Paso raises from the other direction (see
`backend/data/seed-co-counties-2026/ROSTERS.md` R1). Restructuring is not a seating migration's
job. 🔴 **Do not fix it city-by-city** — decide it once for Maine and apply it uniformly, or the
cities will disagree with each other.

---

## The queue — 16 cities, 120 offices

| City | offices | | City | offices |
| --- | --- | --- | --- | --- |
| Westbrook | 15 | | Presque Isle | 7 |
| Bath | 9 | | Old Town | 7 |
| Saco | 8 | | Belfast | 6 |
| Gardiner | 8 | | Brewer | 5 |
| Waterville | 8 | | Eastport | 5 |
| Hallowell | 8 | | Rockland | 5 |
| Calais | 7 | | Ellsworth | 7 |
| Sanford | 7 | | Caribou | 7 |

**Two singletons are NOT part of this pattern and need their own look:**
* `State of Maine` — 1 flagged seat, a **Tribal Representative**. Maine seats three non-voting
  tribal representatives (ADR 0003), and a tribe may genuinely have withdrawn its seat. That could
  be a real vacancy. Do not seat it from a roster without checking.
* `South Portland Public Schools` — 1 flagged seat out of 7, i.e. that district is otherwise
  seated. Likely a genuine single vacancy, not the Maine skeleton shape.

### Per-city recipe

1. Read the council/committee roster from the **body's own page** — not a news article.
2. Run the dedupe pass on `(first_name, last_name)` **with a control that fires**.
3. Seat every filled seat; leave genuinely vacant seats flagged, and give them a real
   `vacant_since` if the date is known.
4. Clear `is_vacant` on exactly the seats filled, in the **same transaction**.
5. Post-verify: 18-style term count · none still flagged · none unflagged-and-unseated ·
   zero seated-and-flagged repo-wide · **unflagged still 239** · total down by the city's count.
6. Probe an address point in the city and confirm the holders come back.
