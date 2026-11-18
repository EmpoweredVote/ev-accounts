# ME-02's declared write-in — Gregory A. Ward

**Status 2026-11-17: seeded and recorded `lost` / `called` (`CC_0451`).** Nothing is certified.
Nothing is seated.

`CC_0450` recorded seven losers across the five `CC_0447` races and reported exactly one AP ballot
line we held no row for: ME-02's Gregory Ward. A losers pass is not where a missing contender gets
seeded, so it created nothing and left the debt written down. This is that seed, and it records his
loss in the same file, because the only reason the row was owed is that AP's ballot names him in a
called race.

| | |
|---|---|
| Name, as the State registers it | **Gregory A. Ward** |
| Name, as AP prints it | `Gregory` / `Ward (write-in)` |
| Residence | Limestone |
| Party, per the State's register | Independent |
| Seat | ME-02 (`U.S. House ME-02`, district `2302`) |
| Status | `active`, `is_write_in = true`, `politician_id` NULL |
| Result | `lost` / `called` |

## 🔴 Why he was missing, and why it is the Galvan finding reflected

Every Maine pass we have run read a list he cannot be on.

| Pass | Source it read | Could it contain him? |
|---|---|---|
| June/July 2026 seeding | `maine.gov/sos/elections-voting/upcoming-elections`, Wikipedia | no |
| `CC_0414` | Maine SoS **"2026 General Candidate List – FINAL"** | no |
| `CC_0450` | AP's ballot | **yes — this is where he surfaced** |

Maine's General Candidate List names the candidates **printed on the ballot**. A declared write-in
is on a **separate register**, published 70 days before the election. No amount of re-reading the
first list produces him.

🔴 **This is `CC_0450`'s Luis Galvan finding reflected.** Galvan is a declared write-in our data
**holds** and AP's ballot **omits**. Ward is a declared write-in AP's ballot **holds** and our data
**omitted**. One cause, two directions:

> **A source that covers printed ballot lines and a source that covers write-ins are not the same
> source.** Which row goes missing depends only on which one you happened to read.

▶ Neither man is an error in the data that held him. Both are a gap between two registers.

## The candidacy source: the State's own register, read as a document

Maine Secretary of State, **"Declared Write-in Candidates for the November 3, 2026 General
Election"**, dated 8/25/26. Committed beside this file as `declared-writeins-nov2026.pdf`, so the
claim re-reads offline. One page, 16 rows. Row 7:

```
Office  District  County  Party        Name              Residence  Municipalities Affected
CG      2                 Independent  Gregory A. Ward   Limestone  Congressional District 2
```

⚠ **It was downloaded and read, not summarised by a fetch tool.** `WebFetch` fabricates names and
dates and formats them as quotations, and a name is exactly what this row is for.

🔴 **The State spells him with a middle initial and AP does not.** The register is the authority on
the candidacy, so `full_name` carries the State's spelling and the citation records AP's. This is
`CC_0450`'s Tessa Lynn Hodge rule — the longer, officially-sourced spelling wins — and assertion 2
compares the `LOSER=` token against the row's own `full_name`, so the two cannot drift apart.

### Why the register is what makes him a contender

**21-A M.R.S. §696(2)(E)**: a write-in vote for a person who has not filed a declaration under
§722-A **"may not be counted"**. So his votes are countable votes *precisely because* he is on that
register. Without it he would be ink.

## 🔴 His candidacy is why this race was tabulated by ranked choice at all

From the State's own **2026 Candidates Guide to Ballot Access**:

> The General Election on November 3, 2026 for U.S. Senate and U.S. Congress will also be decided
> by a system of ranked-choice voting if three or more candidates qualify for the office, **or if
> two candidates qualify for the ballot and there is a declared write-in candidate in the race.**

ME-02 printed exactly two names and had exactly one declared write-in — him — and the race did in
fact go to a ranked-choice tabulation. **A 125-vote candidate changed the method by which 341,256
ballots were counted.** That is a reason to hold the row, not a rounding error.

## 🔴 Two sources, the same votes, different granularity

| Source | Read | What it says |
|---|---|---|
| **AP** | 2026-11-17 14:26Z, 97.83% EEVP | `Gregory` / `Ward (write-in)` — **125** votes, 0.04%, eliminated with 0 in the final round |
| **Maine SoS**, release of 2026-11-12 | election night | **"123 first-choice votes (0.036%) for declared write-in candidates"** |

**AP publishes the name. The State publishes an aggregate.** CD-2's register carries exactly one
name and §696(2)(E) counts nobody else, so that aggregate *is* him — but the two documents are
making different claims, and a later pass must not read them as disagreeing about a person.

⚠ **The gap is a timestamp, not a contradiction.** Every AP line on this race sits slightly above
the State's election-night figures, in the same direction:

| Line | AP | Maine SoS | Δ |
|---|---:|---:|---:|
| Paul LePage (first choice) | 170,265 | 170,263 | +2 |
| Matthew Dunlap (first choice) | 164,845 | 164,845 | 0 |
| Blank votes | 6,021 | 6,017 | +4 |
| Write-in | 125 | 123 | +2 |
| Total ballots | 341,256 | 341,248 | +8 |

AP read later. **Neither is certified.** The final ranked-choice figures agree exactly across both
sources (LePage 170,890, Dunlap 165,432), and the State notes the final round does not break out
write-ins at all.

### ⚠ A claimed 5% reporting rule does not exist

A search summary stated that Maine reports a declared write-in's total by name only above 5% of the
vote, and otherwise groups it under "others". **It is not in the statute, and the State's own guide
says the opposite:**

> **Minimum Number of Write-in Votes Needed in General Election** — In the general election, a
> candidate needs to receive at least one vote.

The 4,000 / 2,000 / 200 / 50-vote thresholds in that guide are **primary** write-in *nomination*
thresholds and have nothing to do with general-election reporting. The rule was nearly written into
a migration header as fact.
▶ **A search summary is a lead. Open the page.**

## ▶ 2026-11-23 — the dated follow-up

The State's release ends:

> Results are unofficial until the official tabulation of the votes cast is communicated to
> Governor Janet Mills. **Official results will be available and posted on the Election Results
> page within 20 days after the election.**

Twenty days from 2026-11-03 is **2026-11-23**. Read them, then certify this row and the other
twelve in the five races. `CC_0451`'s assertion 6 fails if anything claims `certified` before then.

⚠ This is a *different* follow-up from Luis Galvan's. Colorado's abstract (on or after 2026-11-25)
decides **whether Galvan has a recordable total at all**. Maine's official tabulation decides only
**whether a total we already hold becomes certified**.

## What this deliberately does not do

- 🔴 **It creates no `essentials.politicians` row, and `politician_id` stays NULL.** A
  `race_candidates` row is a claim about a ballot; a politicians row is a claim about a person's
  identity, and this repo has shipped three namesake errors into production (Mark Harris as NC-8;
  the late President of Yemen as Bell CA's Ali Saleh; a New York talk-show host as Manhattan
  Beach's Joe Franklin). The recent AP seeding passes — `CC_0413`, `CC_0415`, `CC_0416` — all leave
  `politician_id` NULL for the same reason. ⚠ ME-02's other two rows **do** carry one, so his is
  the only row in the race without it. Nothing breaks: `find-headshots` creates a person on demand
  when one is wanted.
- 🔴 **It records no party on the row.** Party is antipartisan here by design and lives on
  `races.primary_party`. "Independent" appears only inside the citation, as what the register says.
- It does not touch LePage's or Dunlap's rows. Assertion 11 fails if it does.

### 🟢 The mirror trigger was read, not assumed

`essentials.race_candidates` carries an `AFTER INSERT OR UPDATE OF politician_id, photo_url,
website_url` trigger, `trg_race_candidate_mirror_data`, which can write a `politician_images` row
and overwrite `politicians.photo_custom_url` and `.urls`. Its function returns immediately when
`politician_id IS NULL`, which is this row. **Assertion 9 pins that reading** by comparing the
`politicians` and `politician_images` counts against baselines captured in the same transaction —
and controls I and N were each watched making it fire.

## Controls — fourteen tampers, each watched going red

Every assertion in the file, and the pre-check, has been watched failing.

| Control | What it changes | Gate that caught it |
|---|---|---|
| A | the pin points at CA-04, not ME-02 | ✅ pre-check — `expected exactly 1 winner row in ME-02 citing AP race 20261103ME20645, found 0` |
| B | the citation names **Matthew Dunlap** on Ward's row | ✅ 2 — `a result_source that does not name the candidate it is attached to` |
| C | the citation cites **NC-07's** AP race id, name and seat label correct | ✅ 3 — `cite an AP race id their own race's winner does not cite` |
| D | the citation carries **(ME-12)**, name and AP race id correct | ✅ 4 — `a seat label that is not the seat the row sits in` |
| E | Ward is recorded as the **winner** | ⚠ 1 — **not 5. See below.** |
| F | the row claims **`certified`** | ✅ 6 — `do not carry certainty called with the canvass caveat` |
| G | a CA-04 row is given this migration's **marker** | ✅ 7 — `2 row(s) repo-wide carry this migration's marker, expected exactly 1` |
| H | a second row is created **in CA-04, with no marker** | ✅ 8 — `repo-wide row delta 2 does not equal the ME-02 delta 1` |
| I | a **politicians** row is created | ✅ 9 — `politicians count moved from 91881 to 91882` |
| J | the row is attached to **Dunlap's `politician_id`** | ✅ 1 — the `politician_id IS NULL` arm |
| K | **Dunlap is flipped to a write-in** (no row counts move) | ✅ 10 — `1 other write-in row(s) in ME-02` |
| L | **Dunlap's certainty** is altered | ✅ 11 — `CC_0450's Dunlap row is no longer intact` |
| M | **Dunlap is made a second winner** | ✅ 5 — `ME-02 must hold exactly one winner, found 2` |
| N | a **politician_images** row appears | ✅ 9 — `politician_images count moved from 9839 to 9840` |

### 🔴 The gate must not read its expectation out of the migration

Fifth migration running on the same house rule. `CC_0447`–`CC_0450` each lost a control to one
defect: a check comparing a row against the migration's **own declared** value is satisfied by any
pin edited consistently, so it tests a vocabulary instead of a pairing. B, C and D are three
different ways to break a pairing, and each is caught by a gate whose expectation comes from
somewhere a tamper on this file cannot reach:

| Assertion | Expectation taken from |
|---|---|
| 2 — the citation names its own person | `rc.full_name`, read from the table |
| 3 — the citation names its own race | **the winner's `result_source`**, written to production by `CC_0447` |
| 4 — the citation names its own seat | `d.state` and `substr(d.geo_id, 3, 2)` — the row's own geography |
| 11 — the neighbours are untouched | the read-markers `CC_0447` (`03:00Z`) and `CC_0450` (`14:26Z`) left on their own rows |

**B, C and D are deliberately layered.** B breaks the name only; C keeps the name and breaks the
race; D keeps the name *and* the race id and breaks only the seat label. Without D, assertion 4
would never have been watched failing on its own.

### ⚠ Control E fired on the wrong assertion, and it is recorded rather than tidied away

E was built for assertion 5 — *he is not the winner*. **Assertion 1 caught it first**, because
assertion 1 requires `result = 'lost'` on his row, so a winner-tamper makes it match zero rows and
raise before 5 is ever reached. M makes **Dunlap** the second winner instead, leaving Ward's row
exactly right so that 1, 2, 3 and 4 all pass — and then 5 fires.

▶ **An earlier gate catching the fault is not evidence that the later one works.** This is the
third migration running where a control had to be rebuilt for that reason (`CC_0449`, `CC_0450`,
now this), which is why the suite is built to reach *every* assertion rather than to go red once.

## Files beside this one

| File | What it is |
|---|---|
| `declared-writeins-nov2026.pdf` | the State's register, 8/25/26 — the candidacy source, committed so it re-reads offline |
| `sos-rcv-release-2026-11-12.txt` | the Secretary of State's ranked-choice result release, the source of the 123-vote aggregate and the 20-day deadline |

AP's ballot for this race is already committed, at
`backend/data/house-2026-late-losers/ap-ballots-2026-11-17.json`.

## What is still open on ME-02

| Item | Shape |
|---|---|
| `certified` | Read Maine's official tabulation on or after **2026-11-23**, then certify all three rows |
| Seating | LePage takes office **2027-01-03**. Nothing here seats anybody |
| ~~⚠ `CC_0447`'s winner citation~~ | ✅ **CLOSED 2026-11-17 by `CC_0452`.** It said LePage won "defeating incumbent Jared Golden". Golden announced on 2025-11-05 that he would not seek re-election and is on no 2026 ballot line — the Maine SoS's final candidate list prints two names for CD-2 and neither is his, and AP names him as the race's incumbent while putting him on no ballot line. LePage won an **open** seat. 🔴 The defect generalises: **AP's `incumbent` is an attribute of the SEAT, not a ballot line**, so "winner ≠ incumbent" does not mean "the winner beat the incumbent". Write-up: `backend/data/me02-open-seat-2026/OPEN-SEAT.md` |
