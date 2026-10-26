# Maine municipalities — seating the flagged-vacant skeletons

**Done: Augusta (`CC_0282`, 18) · Westbrook (`CC_0283`, 15) · Bath (`CC_0291`, 9) ·
and the nine all-at-large cities in one wave, `CC_0292`, 57 offices —
Brewer 5 · Calais 7 · Caribou 7 · Eastport 5 · Ellsworth 7 · Old Town 7 · Presque Isle 7 ·
Rockland 5 · Sanford 7.
5 cities and 38 offices left: Belfast 6 · Gardiner 8 · Hallowell 8 · Saco 8 · Waterville 8.**
Read this before touching any Maine municipal office.

| | total | flagged | unflagged |
| --- | --- | --- | --- |
| before Augusta | 433 | 194 | **239** |
| after Augusta | 415 | 176 | **239** |
| after Westbrook | 400 | 161 | **239** |
| after Bath | 391 | 152 | **239** |
| after the nine (`CC_0292`) | 335 | 96 | **239** |

🟢 **Flagged has fallen 194 → 96 and not one of the 98 was cleared by moving a baseline.** Of the
96 still flagged, **14 carry a `vacant_since` date** — up from 13, because Brewer's is the first
real, documented vacancy this programme has produced rather than removed.

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

## 🔴🔴 R4b. A PUBLISHED DATE IS AN OCCUPANCY START **ONLY IF SOMETHING BROKE CONTINUITY BEFORE IT**

Westbrook's City Clerk publishes a **Date Elected** and **Next Election** for all 15 seats
(`/200/Elected-Officials`). It looks like the dating problem solved. **13 of the 15 are unusable.**

The two columns are always exactly one term apart, so the table is a **TERM schedule**. A
re-election never opens a new `office_terms` row, so for anyone re-elected "Date Elected" is their
LATEST win and writing it publishes a false start.

🟢 **The two that ARE usable are usable because the seat was demonstrably EMPTY the day before:**

| Seat | Date | Why it is safe |
| --- | --- | --- |
| School At-Large (Allison Brunette) | 2025-10-29 `day` `appointed` | Brittany Barr resigned 2025-10-08; committee filled the vacancy |
| School At-Large (Flynn Ross) | 2025-12-18 `day` `appointed` | seat vacant 2025-12-01, no qualified candidate on the ballot; committee filled it |

A vacancy breaks continuity, so a new occupancy provably began on the fill date — true even if the
appointee had sat on the committee before. ▶ **`how_started = 'appointed'`, not 'elected'.**

▶ **ASK WHAT HAPPENED IMMEDIATELY BEFORE THE DATE, NOT HOW AUTHORITATIVE THE PAGE IS.**
`CC_0283` gates this: exactly 2 dated seats, and every dated seat must be an appointment.
⚠ Expect other Maine clerks to publish the same kind of table. It will look like free data
every time.

---

## 🟢 R5. CHECK WHETHER THE CHAIR IS A REAL SEAT — IN AUGUSTA IT IS, IN WESTBROOK IT IS NOT

The house rule says a **rotating role** (vice chair, mayor pro tem) is a parenthetical on a seat
title and never its own office. Applied blindly it would have deleted Augusta's `School Board
Chair` office.

**It does not apply here.** The board's own page lists the Chair as a ninth row with **her own term
expiry** and no ward or at-large label, alongside 4 ward + 4 at-large seats. Augusta elects its
school board chair citywide.

**Westbrook is the opposite, and also correct.** Its council President and Vice President are
rotating roles — the city says *"The City Council President is elected by a majority of the City
Council"* — so they are **not** offices, and our schema correctly has none. Jennifer Munro (Ward 5)
is President and Michael Shaughnessy (At-Large) is Vice President; both are recorded here as
parentheticals, not seats.

▶ **Check each city before applying the general rule.** Two cities, opposite answers, both from
reading the city's own words. A correct general rule can still do damage to a specific place.

### 🔴 R5b. And check whether the Mayor sits ON the council

Augusta: *"nine elected citizens, **including the Mayor**"* → 9 council offices.
Westbrook: *"**seven** elected members, one from each of the five wards, plus two at-large"*, with
the Mayor separate → 8 offices (7 + Mayor).
Our schema was already right in both. **It still needed checking**, and the office count is the
cheapest place to catch a city whose structure you have assumed.

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

## 🔴🔴 R8. THE OFFICE TITLES THEMSELVES CAN BE THE DEFECT — COUNT THE WARDS BEFORE YOU SEAT

Bath, 2026-10-25. Our schema held nine offices named `Council Member (At-Large 1..9)`. The city's
own council page says:

> "The Bath City Council is composed of nine members, one member from each of the City's seven
> wards and two at-large members."

**Seven of the nine were ward seats, and we were telling a Bath voter they elect all nine at
large.**

🔴 **NOTHING WOULD EVER HAVE CAUGHT THIS.** The office count was right. The chamber was right. The
district was right. Reachability does not read a title, `offices_missing_terms` does not read a
title, and no gate in the repo compares a seat's name to the body's own description of itself. It
surfaced only because seating a city forces you to match a *person* to a *seat*, and the roster had
seven ward councillors and nowhere to put them.

⚠ **R6 IS NOT A DEFENCE HERE.** R6 says at-large seat numbers are ours and carry no meaning — true,
and irrelevant, because these were not at-large seats. R6 applies *after* you have established that
a seat is at-large. Bath is the case where that premise was false.

✅ **THE NINE WERE CHECKED (`CC_0292`, 2026-10-25) AND NOT ONE HAS A WARD SEAT.** Brewer, Calais,
Caribou, Eastport, Ellsworth, Old Town, Presque Isle, Rockland and Sanford all elect their whole
council at large, and our At-Large titles were right. 🔴 **The check still paid for itself six
times over** — see R9. Running it is what found the phantom Mayor offices.

🟢 **The fix is a RETITLE, not a remodel.** Four Maine cities already carry ward titles on one
citywide district — Belfast, Hallowell, Saco, Waterville — so Bath simply joined them. **R7 is
untouched**: an address still returns every seat in the city, including wards that voter does not
elect, and that still needs one Maine-wide decision rather than fifteen local ones.

### 🔴 R8b. A COUNCILLOR LISTED BY A ROTATING ROLE — THE CONTACT ADDRESS SAYS WHICH SEAT

Bath's page labels two of its nine by their rotating role and shows **no ward** for either:

| page label | actual seat | what proved it |
| --- | --- | --- |
| Roo Dunn, "City Council Chairperson" | **Ward 4** | `ward4@cityofbathmaine.gov` |
| Caitlin McCorkle, "City Council Vice Chair" | **Ward 6** | `ward6@cityofbathmaine.gov` |

Wards 4 and 6 appear nowhere else on the page. **Seating from the visible labels would have created
a `Chairperson` office and a `Vice Chair` office and left two real ward seats empty** — R5's
rotating-role trap wearing a new disguise, and worse than the Westbrook case because here the role
*replaces* the seat name instead of sitting beside it.

🟢 Same source settles something R6 says is ours to choose: Bath numbers its own at-large seats,
`atlarge1@` (Ambrosino) and `atlarge2@` (Mansfield-Pryor). **For Bath those numbers are the city's.
Do not "correct" them.**

⚠ **Bath has no Mayor and that is correct** — council–manager city, chair chosen from the council.
Eight of the nine cities that followed held a `Mayor` office and **six of those eight were wrong**;
see R9. `CC_0291` gates that Bath still has none.

### Bath dates, and the election eight days later

Bath publishes **no** election dates — only "Councilors serve three-year terms". So all nine are
`start_precision => 'unknown'`, and R4b's trap cannot even arise. ⚠ A Maine municipal election falls
on **2026-11-03**, and Bath's terms are staggered three-year. **Some of these nine will change; a
re-check is owed in December.** That is not a reason to have waited — the alternative was to keep
asserting that all nine Bath seats are empty, which was false the whole time.

---

## 🔴🔴 R9. "DOES THIS CITY HAVE A MAYOR?" IS A QUESTION ABOUT HOW THE CHAIR IS CHOSEN

`CC_0292`, 2026-10-25, the nine all-at-large cities. R8 said to count the wards. **Not one of the
nine had a ward seat — and six of them carried a `Mayor` office that is not an office.**

▶ **A VERIFICATION PASS FINDS WHAT IS THERE, NOT WHAT YOU WENT LOOKING FOR.** Scoped to "count the
wards", nine cities would have come back green and six phantom offices would have survived the
audit meant to catch them. Read the whole page, not the field you came for.

A rotating chair modelled as an office does **two** things, and the second is the quiet one:

1. it tells a voter their city elects a Mayor when it does not; and
2. it **eats the seat its holder actually occupies**, so the council comes out one short and the
   shortfall looks like an ordinary vacancy.

| city | we held | the city's own words | fix |
| --- | --- | --- | --- |
| Brewer | 4 AL + Mayor | charter §2 *"five (5) members … elected at large"*; §3 the chairman is *"styled as Mayor"* | Mayor → At-Large 5 |
| Caribou | 6 AL + Mayor | §2.01(a) *"seven (7) members elected … at large"*; §2.03 *"The Council shall elect from among its members"* the Mayor | Mayor → At-Large 7 |
| Eastport | 4 AL + Mayor | P&S 1935 c.66 §2 *"5 members elected at large"*; §3 council elects *"1 of its members as president"* | Mayor → At-Large 5 |
| Ellsworth | 6 AL + Mayor | *"Seven City Council members are elected"*; the 2026 ballot carries **City Council — two seats** and no mayor | Mayor → At-Large 7 |
| Presque Isle | 6 AL + Mayor | *"seven individuals elected at-large"*; *"Each year, the City Council elects a Council Chair"* | Mayor → At-Large 7 |
| Rockland | 4 AL + Mayor | *"The voters elect the five City Councilors. The Mayor is chosen by the Council for a 1-year term."* | Mayor → At-Large 5 |

🟢 **Three were right, and the difference is three words long:**
* **Calais** — *"City Councilors are elected at large by the citizens of Calais, **as is the
  Mayor**."* A real, directly elected office. Keep it.
* **Sanford** — the clerk's 2026 filings list four qualified candidates **"for Mayor"** beside
  "City Council" filings that carry no ward. A real office. Keep it.
* **Old Town** — *"seven elected councilors, including one Council President"*, and we modelled no
  mayoral office. Nothing to change.

🔴 **NEVER INFER THIS FROM WHETHER THE CITY USES THE WORD.** Caribou's own page says "Mayor
Courtney Boma" in the same breath as a charter giving it seven councillors and no mayoralty.
▶ Find the sentence that says who **elects** the presiding officer. *"The Mayor is chosen by the
Council"* and *"elected at large by the citizens, as is the Mayor"* look alike and mean opposites.

### ⚠ R9b. WARDS EXIST IN THESE CITIES — AS VOTING WARDS, NOT COUNCIL DISTRICTS

Brewer's charter divides the city into wards **and** elects the council at large, in the same
document. Eastport's 1935 charter does the same with four wards. Ellsworth ran a 2024 proposal to
consolidate four wards into one for election-day administration. A session that greps a Maine
charter for "ward" and ward-titles the seats would invert Bath's defect and tell a voter they
elect a councillor they do not. ▶ **The test is the sentence about how COUNCILLORS ARE ELECTED,
never the presence of the word "ward".**

### 🔴 R9c. THE DEDUPE IS A GATE, NOT A PRE-FLIGHT NOTE

Two of the 56 names collided with existing rows and they resolved **opposite** ways. Bath's
resolver matched on `(first_name, last_name) + is_active` and would have got one of them wrong in
silence. `CC_0292` therefore makes every roster row declare its disposition and **refuses an
undeclared collision**:

| name | disposition | why |
| --- | --- | --- |
| Dani O'Halloran, Brewer | **reuse**, pinned by UUID | already present as Maine House District 20, residence Brewer. She holds **both** seats. |
| Nancy Smith, Ellsworth | **new-despite-namesake** | an active Nancy Smith sits on Palmdale Elementary, California (`CA_0158`). A different person 3,000 miles away. |
| the other 54 | **new**, gated on zero namesakes | the zero was controlled: the same predicate returned Emanuel Cleaver and Jared Golden. |

⚠ **A SOURCE CAN BE AUTHORITATIVE FOR ONE FIELD AND STALE FOR ANOTHER.** The Maine Legislature's
member profile is the authority for O'Halloran's district and residence, and its biography calls
her *"Former … Brewer City Council"* — while Brewer's council page lists her today and the 11
August 2026 minutes record her present at the meeting.

⚠ The repo's `DUPLICATE_POLITICIAN_NAME` guard fired on Nancy Smith and was **right to**. The
exemption (`essentials.allow_duplicate_name`) is opened for that one insert and closed again, so
the other 55 stay under the guard. Never open it for a whole migration.

### 🔴 R9d. BREWER HAS THE FIRST REAL VACANCY THIS PROGRAMME HAS PRODUCED

Four of Brewer's five seats are filled. The fifth is genuinely empty and, unlike the undated
skeleton flags, it has a document behind it — City Council Minutes, 11 August 2026, Resolve
2026-B029: Councillor **William Kimball**'s resignation letter is dated **2026-07-29**, the council
accepted it on **2026-08-11** and declared the vacancy, to be filled at the 2026-11-03 election for
the unexpired term ending **2027-11-16**.

▶ `vacant_since = 2026-08-12` — **the day after the council accepted it**, not the date on the
letter. The same minutes' roll call records "Councilor Kimball-absent", so he was still a member of
record when that meeting opened. No `office_terms` vacancy span is written: he was never seeded, so
there is no term to close.

### ⚠ R9e. A DECLARED VACANCY RENDERS AS A NAMELESS ROW IN ADDRESS SEARCH — PRE-EXISTING

`/api/essentials/address-search` returns a politician object with `id: null` and an empty
`full_name` for every flagged-vacant office. **This is not new and `CC_0292` did not cause it**:
measured the same day, a South Portland address returns the identical blank row for that district's
April 2026 vacancy, which predates this wave. `office_current_holder` LEFT JOINs from `offices`, so
a vacancy is a NULL `politician_id` and the read path emits it anyway.

🔴 It is still a live defect, and the Maine skeleton makes it worse than it looks: **every one of
the 38 offices still queued is rendering as a blank row to a voter in that city today.** Finishing
Maine removes 38 of them. Fixing the read path is a separate change and is not a seating
migration's job.

### Dates for all 56: unknown, and two tempting columns refused

Every one of the nine publishes a **"Term Expires"** year, and Caribou publishes **"First elected
YYYY"** for all seven. 🔴 **Neither dates anyone.** An expiry is the end of a TERM, not of an
occupancy — R4's trap, and writing it would silently un-seat people on 1 January. "First elected"
is a label about how someone **arrived** and cannot exclude a gap and a later return. All 56 are
`start_precision => 'unknown'`, and `CC_0292` gates that none is dated.

The published figures are kept here as a dating lead for whoever wants one, not as data:

| city | what it publishes |
| --- | --- |
| Brewer · Eastport · Old Town · Rockland · Sanford · Ellsworth | term-expiry year per seat |
| Caribou | term-expiry year **and** "First elected YYYY" per seat |
| Presque Isle | term-expiry date (`12/31/YYYY`) per seat |
| Calais | term-expiry year per seat |

⚠ Caribou's council photo caption names **Joan Theriault**, who is not in the contact list of seven;
Lori Knight Phair (first elected 2025) replaced her. **The caption is older than the list.**

### ▶ December re-check, owed for all twelve seated cities

A Maine municipal election falls on **2026-11-03**, nine days after this wave. Every one of these
councils is staggered, so some of the 56 will change — and Brewer's vacancy is explicitly on that
ballot. Seating now was still right: the alternative was to keep asserting to voters in nine cities
that all 57 seats are empty.

---

## The queue — 5 cities, 38 offices

**Re-measured against prod after `CC_0292`, 2026-10-25, and it reconciles exactly**: 95 queued
before this wave, minus the 57 it took, leaves 38 — which is what `offices_missing_terms` now
reports for Maine municipalities, plus the `State of Maine` tribal seat noted below.

🟢 **ALL FIVE THAT REMAIN ALREADY CARRY WARD OR DISTRICT TITLES**, so R8's question is settled for
them — but R9's is not. Each still holds a `Mayor` office that nobody has checked.

| City | offices | modelled as | ▶ what to check |
| --- | --- | --- | --- |
| Gardiner | 8 | 4 districts + 3 at-large + mayor | is the Mayor elected, or the council's chair? |
| Hallowell | 8 | 4 wards + 3 at-large + mayor | same |
| Saco | 8 | 7 wards + mayor | same |
| Waterville | 8 | 7 wards + mayor | same |
| Belfast | 6 | 5 wards + mayor | same |
| **total** | **38** | | |

Every city uses **one citywide district**, including the five that name wards — so R7 is a
pre-existing Maine-wide condition, not something a retitle introduces.

⚠ **An elected office we do not model:** Westbrook elects a `Portland Water District Rep.`
(Malory Shaughnessy) and we hold no office for it. Creating one means modelling a regional water
district spanning several municipalities — out of scope for a seating migration. Expect other
Maine cities to elect similar regional seats, and do not invent an office to hold them.

~~Bath 9~~ — **done 2026-10-25, `CC_0291`.**

**Two singletons are NOT part of this pattern:**
* `State of Maine` — 1 flagged seat, a **Tribal Representative**. Maine seats three non-voting
  tribal representatives (ADR 0003), and a tribe may genuinely have withdrawn its seat. That could
  be a real vacancy. Do not seat it from a roster without checking. **Still open.**
* 🟢 `South Portland Public Schools` — **RESOLVED 2026-10-25, and it is NOT skeleton work.** The
  tracker guessed "likely a genuine single vacancy". Measured: it was then the **only** flagged
  Maine municipal office carrying a `vacant_since` DATE, out of 105. That date is the signature of
  a real, documented vacancy — the thing the flag is actually for. Leave it flagged.
  ⚠ It is no longer the only one: Brewer's At-Large 5 joined it on 2026-10-25 (R9d). Two dated
  Maine vacancies now, and both are real.

### Per-city recipe

1. Read the council/committee roster from the **body's own page** — not a news article.
2. **Read the city's own description of its council structure**, in this order: the charter if the
   site carries it, else the clerk's nomination-paper notice or candidate filings, which enumerate
   exactly the offices on the ballot. Both answer R8 (wards?) and R9 (mayor?) at once.
3. Run the dedupe pass on `(first_name, last_name)` **and** on a normalised `full_name`, **with a
   control that fires**. Declare every collision in the roster as `reuse` or
   `new-despite-namesake`; make the migration refuse an undeclared one (R9c).
4. Seat every filled seat; leave genuinely vacant seats flagged, and give them a real
   `vacant_since` if the date is known (R9d).
5. Clear `is_vacant` on exactly the seats filled, in the **same transaction**.
6. Post-verify: the term count · none still flagged · none unflagged-and-unseated · zero
   seated-and-flagged repo-wide · **unflagged still 239** · total down by the city's count ·
   **the surviving mayoral offices named explicitly** · no rotating role became a seat.
7. Probe an address point in the city and confirm the holders come back, **with a control city
   that already works** — a uniform zero across nine cities was a parser bug, not a data defect.
